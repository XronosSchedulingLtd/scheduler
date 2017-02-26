require 'yaml'

#
#  A basic set of event category properties, from which we will do
#  some modifications.  It's the modifications which are interesting.
#
class ECH < Hash
  def initialize(values)
    super()
    self[:schoolwide]  = false
    self[:publish]     = true
    self[:unimportant] = false
    self[:can_merge]   = false
    self[:can_borrow]  = false
    self[:compactable] = true
    self[:deprecated]  = false
    self[:privileged]  = false
    self[:visible]     = true
    self.merge!(values)
  end
end

class Seeder

  class SeedProperty
    def initialize(name, make_public = false)
      @dbrecord = Property.create!({
        name:        name,
        make_public: make_public
      })
      @dbrecord.reload
    end

    def element_id
      @dbrecord.element.id
    end

    def set_preferred_colour(colour)
      @dbrecord.element.preferred_colour = colour
      @dbrecord.element.save
      self
    end
  end


  class SeedStaff
    attr_reader :dbrecord, :initials

    def initialize(title, forename, surname, initials, email = nil)
      @initials = initials
      unless email
        email = "#{forename.downcase}.#{surname.downcase}@xronos.org"
      end
      @dbrecord = Staff.create!({
        name:     "#{forename} #{surname}",
        initials: initials,
        surname:  surname,
        title:    title,
        forename: forename,
        email:    email,
        active:   true,
        current:  true
      })
      #
      #  Should have acquired an element, so re-load
      #
      @dbrecord.reload
    end

    def element_id
      @dbrecord.element.id
    end

    def teaches(subject)
      @dbrecord.subjects << subject.dbrecord
      self
    end
  end


  class SeedEvent
    attr_reader :event

    def initialize(eventcategory, eventsource, body, starts_at, ends_at, more = {})
      params = {
        body:             body,
        eventcategory_id: eventcategory.id,
        eventsource_id:   eventsource.id,
        starts_at:        starts_at,
        ends_at:          ends_at
      }
      params.merge!(more)
      @event = Event.create!(params)
    end

    #
    #  Add an attendee to an event.  Must respond to element_id()
    #
    def <<(thing)
      @event.commitments.create!({ element_id: thing.element_id })
    end

    #
    #  Add a collection of things to an event.
    #
    def involving(*params)
      params.each do |p|
        @event.commitments.create!({ element_id: p.element_id })
      end
      self
    end

    def add_note(title, contents, more = {})
      params = {
        title:    title,
        contents: contents,
        visible_guest: false,
        visible_staff: true,
        visible_pupil: false
      }
      params.merge!(more)
      @event.notes.create!(params)
    end
  end


  class SeedPeriod
    attr_reader :start_time, :end_time

    def initialize(start_time, end_time)
      @start_time = start_time
      @end_time = end_time
    end
  end


  class SeedLocation

    attr_reader :dbrecord, :aliasrec

    def initialize(name, aliasname = nil, display = true, friendly = true)
      @dbrecord =
        Location.create!({
          name:    name,
          active:  true,
          current: true})
      @dbrecord.reload
      if aliasname
        @aliasrec =
          Locationalias.create!({
            name:          aliasname,
            location_id:   @dbrecord.id,
            display:       display,
            friendly:      friendly})
      else
        @aliasrec = nil
      end
    end

    def element_id
      @dbrecord.element.id
    end

  end


  class SeedSubject
    attr_reader :dbrecord

    def initialize(name)
      @dbrecord = Subject.create!({name: name, current: true})
      @dbrecord.reload

    end

    def element_id
      @dbrecord.element.id
    end

  end


  class SeedGroup

    attr_reader :dbrecord, :subject, :name

    def initialize(name, era, type = "Vanilla", more = {})
      @name      = name
      @starts_on = era.starts_on
      case type
      when "Teaching"
        baseclass = Teachinggroup
      when "Tutor"
        baseclass = Tutorgroup
      else
        baseclass = Vanillagroup
      end
      params = {
        name:       name,
        starts_on:  era.starts_on,
        era_id:     era.id,
        current:    true
      }
      params.merge!(more)
      @dbrecord = baseclass.create!(params)
      @dbrecord.reload
    end

    def element_id
      @dbrecord.element.id
    end

    def <<(new_member)
      @dbrecord.add_member(new_member.dbrecord, @starts_on)
    end

    #
    #  Allow a member to be added to the group with specific start
    #  and end dates.
    #
    def add_special(new_member, start_date, end_date = nil)
      @dbrecord.add_member(new_member.dbrecord, start_date)
      if end_date
        #
        #  The method provided by the Group model expects to be called
        #  with a date when the member is no longer to be in the group.
        #  We have the last date on which we do want him to be a member
        #  so add 1 to it.
        #
        @dbrecord.remove_member(new_member.dbrecord, end_date + 1.day)
      end
    end

    #
    #  Add a whole lot of members in one go.
    #
    def members(*params)
      params.each do |p|
        @dbrecord.add_member(p.dbrecord, @starts_on)
      end
      self
    end

  end

  class SeedTeachingGroup < SeedGroup
    def initialize(name, era, subject)
      @subject   = subject
      super(name, era, "Teaching", {subject_id: subject.dbrecord.id})
    end

    def taught_by(staff)
      @dbrecord.staffs << staff.dbrecord
      self
    end
  end

  class SeedTutorGroup < SeedGroup
    def initialize(yeargroup, era, staff, house)
      name = "#{yeargroup}/#{staff.initials}"
      start_year = era.starts_on.year - yeargroup + 1
      super(name, era, "Tutor", {house: house,
                                 staff_id: staff.dbrecord.id,
                                 start_year: start_year})
    end

    def <<(new_member)
      super
      #
      #  Adding a pupil to a tutor group effectively changes his or her
      #  element name.  Force a save to ensure it is updated.
      #
      new_member.force_save
    end
  end

  class SeedPupil

    attr_reader :dbrecord

    @surnames =
      YAML.load(File.open(File.join(File.dirname(__FILE__), "surnames.yml")))
    @forenames =
      YAML.load(File.open(File.join(File.dirname(__FILE__), "forenames.yml")))

    def self.surnames
      @surnames
    end

    def self.forenames
      @forenames
    end

    def surnames
      self.class.surnames
    end

    def forenames
      self.class.forenames
    end

    def unique_names
      loop do
        forename = forenames.sample
        surname = surnames.sample
        existing = Pupil.find_by(name: "#{forename} #{surname}")
        return forename, surname unless existing
      end
    end

    def initialize(era, yeargroup, forename = nil, surname = nil)
      unless forename && surname
        forename, surname = unique_names
      end
      start_year = era.starts_on.year - yeargroup + 1
      @dbrecord = Pupil.create!({
        name:     "#{forename} #{surname}",
        surname:  surname,
        forename: forename,
        known_as: forename,
        email:    "#{forename.downcase}.#{surname.downcase}@pupils.xronos.uk",
        start_year: start_year,
        current:    true
      })
      @dbrecord.reload
    end

    def element_id
      @dbrecord.element.id
    end

    def force_save
      @dbrecord.save
    end
  end


  class SeedLesson < SeedEvent


    def self.lessoncategory
      unless @lessoncategory
        @lessoncategory = Eventcategory.find_by(name: "Lesson")
        unless @lessoncategory
          raise "Can't find the lesson event category."
        end
      end
      @lessoncategory
    end

    def lessoncategory
      self.class.lessoncategory
    end

    #
    #  All parameters should themselves be Seed<Something> objects.
    #  We get the subject for the lesson from the group.
    #
    def initialize(eventsource, staff, group, location, day, period, more = {})
      #
      #  First let's create the event itself.
      #
      starts_at = Time.zone.parse("#{day.to_s} #{period.start_time}")
      ends_at   = Time.zone.parse("#{day.to_s} #{period.end_time}")
      super(lessoncategory, eventsource, group.name, starts_at, ends_at, more)
      #
      #  Needs:
      #
      #    Member of staff
      #    Group
      #    Location
      #    Subject
      #
      self << staff
      self << group
      self << location
      if group.subject
        self << group.subject
      end
      @event.reload
    end

    def covered_by(staff)
      commitment = @event.commitments.first
      @event.commitments.create!({ element_id: staff.element_id,
                                   covering_id: commitment.id })
      self
    end

  end


  class SeedMeeting < SeedEvent

    def self.meetingcategory
      unless @meetingcategory
        @meetingcategory = Eventcategory.find_by(name: "Meeting")
        unless @meetingcategory
          raise "Can't find the meeting event category."
        end
      end
      @meetingcategory
    end

    def meetingcategory
      self.class.meetingcategory
    end

    #
    #  All parameters should themselves be Seed<Something> objects.
    #  We get the subject for the lesson from the group.
    #
    def initialize(eventsource, title, staff, location, day, period)
      #
      #  First let's create the event itself.
      #
      starts_at = Time.zone.parse("#{day.to_s} #{period.start_time}")
      ends_at   = Time.zone.parse("#{day.to_s} #{period.end_time}")
      super(meetingcategory, eventsource, title, starts_at, ends_at)
      if staff.respond_to?(:each)
        staff.each do |s|
          self << s
        end
      else
        self << staff
      end
      self << location
      @event.reload
    end

  end

  #
  #  And here is the code for the seeder itself.
  #

  attr_reader :eras,
              :era_start_date,
              :eventcategories,
              :eventsources,
              :groups,
              :locations,
              :periods,
              :properties,
              :staff,
              :subjects,
              :weekdates

  def initialize(auth_type = 1)
    #
    #  Always set everything to the current week.
    #
    Date.beginning_of_week = :sunday
    @weekdates = Hash.new
    sunday = Date.today.at_beginning_of_week
    @weekdates[:sunday]    = sunday
    @weekdates[:monday]    = sunday + 1.day
    @weekdates[:tuesday]   = sunday + 2.days
    @weekdates[:wednesday] = sunday + 3.days
    @weekdates[:thursday]  = sunday + 4.days
    @weekdates[:friday]    = sunday + 5.days
    @weekdates[:saturday]  = sunday + 6.days

    #
    #  What academic year are we notionally in?
    #
    today = Date.today
    current_year = today.year
    @era_start_date = Date.parse("#{current_year}-08-15")
    if @era_start_date > today
      @era_start_date = @era_start_date - 1.year
    end
    @era_end_date = @era_start_date + 1.year - 1.day
    @era_short_name = "#{@era_start_date.strftime("%Y")}/#{@era_end_date.strftime("%y")}"
    @era_name = "Academic Year #{@era_short_name}"

    #
    #  Now, if the required eras don't already exist we will create them.
    #  Likewise for a basic settings record.
    #
    @eras = Hash.new
    current_era = Era.find_by(name: @era_name)
    if current_era
      @eras[:current_era] = current_era
    else
      @eras[:current_era] = Era.create!({
        name:       @era_name,
        starts_on:  @era_start_date,
        ends_on:    @era_end_date,
        short_name: @era_short_name
      })
    end
    perpetual_era = Era.find_by(name: "Perpetual")
    if perpetual_era
      @eras[:perpetual_era] = perpetual_era
    else
      @eras[:perpetual_era] = Era.create!({
        name:       "Perpetual",
        starts_on:  @era_start_date,
        ends_on:    nil,
        short_name: "Perpetual"
      })
    end
    @settings = Setting.first
    unless @settings
      @settings = Setting.create({
        current_era_id: @eras[:current_era].id,
        perpetual_era_id: @eras[:perpetual_era].id,
        enforce_permissions: true,
        auth_type: auth_type
      })
    end
    #
    #  And some space to record stuff which comes later.
    #
    @eventcategories = Hash.new
    @properties = Hash.new
    @groups = Hash.new
    @eventsources = Hash.new
    @subjects = Hash.new
    @staff = Hash.new
    @periods = Array.new
    @locations = Hash.new
  end

  def create_essentials
    #
    #  Event categories
    #
    @eventcategories[:lesson] =
      Eventcategory.create!(ECH.new({name: "Lesson",
                                     clashcheck: true}))
    @eventcategories[:weekletter] =
      Eventcategory.create!(ECH.new({name: "Week letter",
                                     schoolwide: true,
                                     privileged: true }))
    @eventcategories[:duty] =
      Eventcategory.create!(ECH.new({name: "Duty", privileged: true}))
    @eventcategories[:weekletter] =
      Eventcategory.create!(ECH.new({name: "Invigilation", privileged: true}))

    #
    #  Properties
    #
    @properties[:calendarproperty] =
      SeedProperty.new("Calendar", true).set_preferred_colour("#1f94bc")
    @properties[:gapproperty] =
      SeedProperty.new("Gap")
    @properties[:suspensionproperty] =
      SeedProperty.new("Suspension")
    #
    # Sources
    #
    @eventsources[:thisfile] = Eventsource.create!({ name: "Seedfile" })
    @eventsources[:manual]   = Eventsource.create!({ name: "Manual" })
  end

  Usefuls = [
    {id: :datecrucial,
     ech: ECH.new({name: "Date - crucial",
                   schoolwide: true,
                   privileged: true })},
    {id: :hidden,
     ech: ECH.new({name: "Hidden",
                   publish: false,
                   visible: false,
                   privileged: true})},
    {id: :parentsevening,
     ech: ECH.new({name: "Parents' evening", privileged: true})},
    {id: :reportdeadline,
     ech: ECH.new({name: "Reporting deadline", privileged: true})},
    {id: :tutorperiod,
     ech: ECH.new({name: "Tutor period", privileged: true})},
    {id: :assembly,
     ech: ECH.new({name: "Assembly", privileged: true})},
    {id: :sportsfixture,
     ech: ECH.new({name: "Sports fixture"})},
    {id: :trip,
     ech: ECH.new({name: "Trip"})},
    {id: :inset,
     ech: ECH.new({name: "INSET / Training"})},
    {id: :interview,
     ech: ECH.new({name: "Interview / Audition"})},
    {id: :practice,
     ech: ECH.new({name: "Practice / Rehearsal"})},
    {id: :performance,
     ech: ECH.new({name: "Performance"})},
    {id: :service,
     ech: ECH.new({name: "Religious service"})},
    {id: :dateother,
     ech: ECH.new({name: "Date - other", unimportant: true})},
    {id: :setup,
     ech: ECH.new({name: "Event set-up"})},
    {id: :meeting,
     ech: ECH.new({name: "Meeting"})}
  ]


  def create_usefuls
    Usefuls.each do |useful|
      @eventcategories[useful[:id]] =
        Eventcategory.create!(useful[:ech])
    end
  end

  def new_group(key, name, era, staff_ids = [])
    members = staff_ids.collect {|sid| @staff[sid]}
    @groups[key] = SeedGroup.new(name, @eras[era]).members(*members)
  end

  def teaching_group(groupid, name, subject)
    #
    #  Subject can be passed either as an actual SeedSubject, or as
    #  the id of one.
    #
    unless subject.instance_of?(SeedSubject)
      key = subject
      subject = @subjects[key]
      unless subject
        raise "Can't find subject #{key}"
      end
    end
    @groups[groupid] = SeedTeachingGroup.new(name, @eras[:current_era], subject)
  end

  #
  #  timing can be either an array like this:
  #
  #  ["10:00", "12:00"]
  #
  #  or
  #
  #  :all_day
  #
  #  Anything else will result in undefined behaviour.
  #
  def event(
    eventcategory,      # Either an actual event category, or an id.
    title,
    day,
    timing,
    organiser = nil,
    modifiers = {})

    unless eventcategory.instance_of?(Eventcategory)
      #
      #  We assume it must be an ID.
      #
      id = eventcategory
      eventcategory = @eventcategories[id]
      unless eventcategory
        raise "Eventcategory #{id} not found."
      end
    end
    extra = Hash.new
    if organiser
      unless organiser.instance_of?(SeedStaff)
        key = organiser
        organiser = @staff[key]
        unless organiser
          "Can't find organiser staff with id #{key}"
        end
      end
      extra[:organiser_id] = organiser.element_id
    end
    if timing == :all_day
      starts = Time.zone.parse(@weekdates[day].to_s)
      ends = Time.zone.parse((@weekdates[day] + 1.day).to_s)
      extra[:all_day] = true
    else
      starts = Time.zone.parse("#{@weekdates[day].to_s} #{timing[0]}")
      ends   = Time.zone.parse("#{@weekdates[day].to_s} #{timing[1]}")
    end
    event = SeedEvent.new(
      eventcategory,
      @eventsources[:thisfile],
      title,
      starts,
      ends,
      extra)
    modifiers.each do |key, data|
      if data.instance_of?(Array)
        event.send(key, *data)
      else
        event.send(key, data)
      end
    end
    event
  end

  def subject(id, name)
    @subjects[id] = SeedSubject.new(name)
  end

  def new_staff(
    title,
    forename,
    surname,
    initials,
    subject_ids,
    email = nil)

    key = initials.downcase.to_sym
    rec = SeedStaff.new(title, forename, surname, initials, email)
    subject_ids.each do |sid|
      subject = @subjects[sid]
      unless subject
        raise "Can't find subject with id #{sid}"
      end
      rec.teaches(subject)
    end
    @staff[key] = rec
    rec
  end

  #
  #  Should be passed an array of arrays, like this:
  #
  #  [
  #    ["09:00", "09:25"],      # Period 0
  #    ["09:30", "10:00"],      # Period 1
  #    etc.
  #  ]
  #
  def configure_periods(period_times)
    period_times.each do |pt|
      @periods << SeedPeriod.new(*pt)
    end
  end

  def location(id, name, aliasname = nil, display = true, friendly = true)
    @locations[id] = SeedLocation.new(name, aliasname, display, friendly)
  end

  def lesson(staffid, groupid, roomid, dayid, period, more = {})
    SeedLesson.new(@eventsources[:thisfile],
                   @staff[staffid],
                   @groups[groupid],
                   @locations[roomid],
                   @weekdates[dayid],
                   @periods[period],
                   more)
  end


  def meeting(title, staffids, roomid, dayid, period)
    SeedMeeting.new(@eventsources[:thisfile],
                    title,
                    staffids.collect {|sid| @staff[sid]},
                    @locations[roomid],
                    @weekdates[dayid],
                    @periods[period])
  end

  def pupil(yeargroup, forename = nil, surname = nil)
    SeedPupil.new(@eras[:current_era], yeargroup, forename, surname)
  end

  def add_to(g, pupil)
    if g.kind_of?(SeedGroup)
      g << pupil
    else
      #
      #  Assume it must be a key.
      #
      group = @groups[g]
      if group
        group << pupil
      else
        raise "Couldn't find group from key #{g}"
      end
    end
  end

  def add_special(g, pupil, start_date, end_date = nil)
    if g.kind_of?(SeedGroup)
      g.add_special(pupil, start_date, end_date)
    else
      #
      #  Assume it must be a key.
      #
      group = @groups[g]
      if group
        group.add_special(pupil, start_date, end_date)
      else
        raise "Couldn't find group from key #{g}"
      end
    end
  end

  #
  #  A helper method to populate one or more groups.
  #
  def populate(group, yeargroup, howmany)
    howmany.times do
      newpupil = self.pupil(yeargroup)
      if group.respond_to?(:each)
        group.each do |g|
          if g.respond_to?(:each)
            #
            #  Still an array!
            #
            add_to(g.sample, newpupil)
          else
            add_to(g, newpupil)
          end
        end
      else
        add_to(group, newpupil)
      end
    end
  end
end