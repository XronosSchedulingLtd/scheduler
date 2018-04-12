class RepeatDatesValidator < ActiveModel::Validator

  def validate(event_collection)
    #
    #  Check that the two dates exist first.  If they don't the
    #  record will already have failed validation and we don't
    #  need to do more.
    #
    if event_collection.repetition_start_date &&
       event_collection.repetition_end_date
      if event_collection.repetition_end_date < event_collection.repetition_start_date
        event_collection.errors[:repetition_end_date] << "can't be before start date"
      elsif event_collection.repetition_end_date > event_collection.repetition_start_date + 1.year
        event_collection.errors[:repetition_end_date] << "can't be more than a year after start date"

      end
    end
    #
    #  Are the update timings in a self-consistent state?  There are
    #  three of them:
    #
    #  update_requested_at
    #  update_started_at
    #  update_finished_at
    #
    #  By default they are all nil (which is valid, obviously) and then
    #  other valid combinations are such that they are set in order.
    #  We can have the first one set, or the first two, or all three.
    #  Any that are set must increase monotonically ( >= , although
    #  we do the actual tests the other way around).
    #
    if event_collection.update_requested_at
      if event_collection.update_started_at
        if event_collection.update_started_at < event_collection.update_requested_at
          event_collection.errors[:update_started_at] <<
            "can't be before update_requested_at"
        else
          if event_collection.update_finished_at &&
            event_collection.update_finished_at < event_collection.update_started_at
            event_collection.errors[:update_finished_at] <<
              "can't be before update_started_at"
          end
        end
      else
        if event_collection.update_finished_at
          event_collection.errors[:update_started_at] <<
            "can't be nil if update_finished_at is set"
        end
      end
    else
      if event_collection.update_started_at ||
         event_collection.update_finished_at
        event_collection.errors[:update_requested_at] <<
          "can't be nil if other timings are set"
      end
    end
  end

end

class EventCollection < ActiveRecord::Base

  class DaynameWithIndex
    attr_reader :name, :index

    def initialize(name, index)
      @name = name
      @index = index
    end

  end

  class WeekWithKey
    attr_reader :label, :key

    def initialize(label, key)
      @label = label
      @key = key
    end

  end

  belongs_to :era
  has_many :events, dependent: :destroy
  belongs_to :requesting_user, class_name: :User

  validates :repetition_start_date, presence: true
  validates :repetition_end_date, presence: true
  validates :era, presence: true
  validates_with RepeatDatesValidator

  #
  #  These names may look excessively long, but they're like this
  #  to avoid clashing with in-built ActiveRecord names.
  #
  enum when_in_month: [
    :every_time,
    :first_time,
    :second_time,
    :third_time,
    :fourth_time,
    :fifth_time,
    :last_time,
    :penultimate_time,
    :antepenultimate_time
  ]

  #
  #  Days of week is an array of integers - 0 to 7
  #
  serialize :days_of_week
  #
  #  Weeks is an array of single character strings - "A", "B", " "
  #
  serialize :weeks

  after_initialize :set_up_days_and_weeks

  attr_reader :daynames_with_index, :weeks_with_keys

  #
  #  This will be passed an array of strings, but we want values.
  #  The last string is always empty.
  #
  def days_of_week=(strings)
    self[:days_of_week] = []
    strings.each do |string|
      unless string.empty?
        value = string.to_i
        enable_day(value)
      end
    end
  end

  def weeks=(strings)
    self[:weeks] = []
    strings.each do |string|
      unless string.empty?
        self.weeks << string
      end
    end
  end

  def enable_day(value)
    if value >=0 && value < Date::ABBR_DAYNAMES.size
      Rails.logger.debug("days_of_week = #{self.days_of_week.inspect}")
      Rails.logger.debug("value = #{value} (#{value.class})")
      unless self.days_of_week.include?(value)
        self.days_of_week << value
      end
    end
  end

  def pre_select=(value)
    unless self.days_of_week
      self[:days_of_week] = []
    end
    enable_day(value)
  end

  def starts_on_text
    repetition_start_date ? repetition_start_date.strftime("%d/%m/%Y") : ""
  end

  def starts_on_text=(value)
    old_repetition_start_date = self.repetition_start_date
    self.repetition_start_date = value
    if (self.repetition_start_date != old_repetition_start_date) &&
      !self.new_record?
      #
      #  A genuine change.
      #
      @timing_changed = true
    end
  end

  def ends_on_text
    repetition_end_date ? repetition_end_date.strftime("%d/%m/%Y") : ""
  end

  def ends_on_text=(value)
    old_repetition_end_date = self.repetition_end_date
    self.repetition_end_date = value
    if (self.repetition_end_date != old_repetition_end_date) &&
      !self.new_record?
      #
      #  A genuine change.
      #
      @timing_changed = true
    end
  end

  #
  #  The published interface to ActiveRecord's update() method breaks
  #  down a little if you have optimistic locking in place.  Most errors
  #  result in it returning false, but a locking error results in an
  #  exception.  To simplify client code, we provide this to smooth
  #  things out.
  #
  def safe_update(params)
    begin
      result = self.update(params)
    rescue ActiveRecord::StaleObjectError
      self.errors[:locking] = "record has been updated"
      result = false
    end
    result
  end

  #
  #  Three methods to allow the service code to record how it's getting on
  #  with updates.  Modify our own internal fields and save ourselves to
  #  the database.
  #
  #  Return true if we think all is OK, and false otherwise.
  #
  #  We can start an update if all the current datetime values are nil,
  #  or they're all filled in.
  #
  def note_update_requested(user, and_start = false)
    result = false
    if ok_to_update?
      #
      #  We may still fail if our record turns out to be stale.
      #
      time_now = Time.zone.now
      old_ura = self.update_requested_at
      old_usa = self.update_started_at
      old_ufa = self.update_finished_at
      old_requesting_user = self.requesting_user
      self.update_requested_at = time_now
      self.update_started_at   = and_start ? time_now : nil
      self.update_finished_at  = nil
      self.requesting_user     = user
      #
      #  The save may throw an exception.
      #
      begin
        self.save
        result = true
      rescue ActiveRecord::StaleObjectError
        #
        #  Someone else got in first.
        #
        self.update_requested_at = old_ura
        self.update_started_at   = old_usa
        self.update_finished_at  = old_ufa
        self.requesting_user     = old_requesting_user
      end
    end
    result
  end

  def note_starting_update
    result = false
    if ok_to_start_update?
      #
      #  We may still fail if our record turns out to be stale.
      #
      time_now = Time.zone.now
      old_usa = self.update_started_at
      self.update_started_at   = time_now
      #
      #  The save may throw an exception.
      #
      begin
        self.save
        result = true
      rescue ActiveRecord::StaleObjectError
        #
        #  Someone else got in first.
        #
        self.update_started_at = old_usa
      end
    end
    result
  end

  def note_finished_update
    result = false
    if ok_to_finish_update?
      #
      #  We may still fail if our record turns out to be stale.
      #
      time_now = Time.zone.now
      old_ufa = self.update_finished_at
      self.update_finished_at   = time_now
      #
      #  The save may throw an exception.
      #
      begin
        self.save
        result = true
      rescue ActiveRecord::StaleObjectError
        #
        #  Someone else got in first.
        #
        self.update_finished_at = old_ufa
      end
    end
    result
  end

  #
  #  We make this one public so that client code can check it and
  #  not offer the relevant links if it can't do an update.  Of course,
  #  a call on this which returns true does not guarantee that a
  #  subsequent attempt will succeed, but it will stop 99% of
  #  impossible requests.
  #
  def ok_to_update?
    self.valid? &&
    ((self.update_requested_at.nil? &&
      self.update_started_at.nil? &&
      self.update_finished_at.nil?) ||
     !self.update_finished_at.nil?)
  end

  #
  #  Does our collection of events happen on the indicated date in the
  #  indicated week?
  #
  def happens_on?(date, week_letter)
    date >= self.repetition_start_date &&
    date <= self.repetition_end_date &&
    self.days_of_week.include?(date.wday) &&
    self.weeks.include?(week_letter) &&
    right_time_of_the_month?(date)
  end

  def body_text
    find_base_event ? @base_event.body : "<no events>"
  end

  def base_event_starts_at_text
    find_base_event ? @base_event.starts_at_text : ""
  end

  def base_event_ends_at_text
    find_base_event ? @base_event.ends_at_text : ""
  end

  def base_event_category_text
    find_base_event ? @base_event.eventcategory.name : ""
  end

  def base_event_source_text
    find_base_event ? @base_event.eventsource.name : ""
  end

  def base_event_owner_text
    find_base_event ? @base_event.owners_name : ""
  end

  def base_event_organiser_text
    find_base_event ? @base_event.organiser_name : ""
  end

  def base_event_created_text
    find_base_event ? @base_event.created_at_text : ""
  end

  def base_event_updated_text
    find_base_event ? @base_event.updated_at_text : ""
  end

  def base_event_resource_list
    if find_base_event
      @base_event.resources.collect { |entity|
        entity.name
      }.join(", ")
    else
      ""
    end
  end

  def requesting_user_name
    self.requesting_user ? self.requesting_user.name : "<none>"
  end

  def status_text
    if self.valid?
      if self.update_requested_at.nil?
        "unused"
      elsif self.update_started_at.nil?
        "update requested"
      elsif self.update_finished_at.nil?
        "update in progress"
      else
        "up to date"
      end
    else
      "<invalid>"
    end
  end

  def start_date_text
    self.repetition_start_date.strftime("%d/%m/%Y")
  end

  def end_date_text
    self.repetition_end_date.strftime("%d/%m/%Y")
  end

  def first_event_date_text
    find_base_event ? @base_event.starts_at.strftime("%d/%m/%Y") : "<none>"
  end

  def week_days_text
    self.days_of_week.collect {|dow| Date::DAYNAMES[dow]}.join(", ")
  end

  def which_weeks_text
    self.weeks.collect {|w| w == " " ? "Holidays" : w }.join(", ")
  end

  def update_requested_at_text
    if self.update_requested_at
      self.update_requested_at.strftime("%H:%M:%S %d/%m/%Y")
    else
      "<none>"
    end
  end

  def update_started_at_text
    if self.update_started_at
      self.update_started_at.strftime("%H:%M:%S %d/%m/%Y")
    else
      "<none>"
    end
  end

  def update_finished_at_text
    if self.update_finished_at
      self.update_finished_at.strftime("%H:%M:%S %d/%m/%Y")
    else
      "<none>"
    end
  end

  def have_base_event?
    find_base_event
  end

  private

  def find_base_event
    (@base_event ||= self.events.first) != nil
  end

  def right_time_of_the_month?(date)
    monlen = date.days_in_month
    delta = monlen - date.day
    case self.when_in_month.to_sym
    when :every_time
      true

    when :first_time
      date.day <= 7

    when :second_time
      date.day > 7 && date.day <= 14

    when :third_time
      date.day > 14 && date.day <= 21

    when :fourth_time
      date.day > 21 && date.day <= 28

    when :fifth_time
      date.day > 28

    when :last_time
      delta < 7

    when :penultimate_time
      delta >= 7 && delta < 14

    when :antepenultimate_time
      delta >= 14 && delta < 21

    else
      false
    end
  end

  def ok_to_start_update?
    self.valid? &&
    !self.update_requested_at.nil? &&
    self.update_started_at.nil? &&
    self.update_finished_at.nil?
  end

  def ok_to_finish_update?
    self.valid? &&
    !self.update_requested_at.nil? &&
    !self.update_started_at.nil? &&
    self.update_finished_at.nil?
  end

  #
  #  Days of week should be an array of integers.
  #  Note that this method is called only *after* any values which
  #  were passed into the EventCollection.new have been assigned
  #  to their variables.  We therefore need to make sure that all
  #  which is necessary for assignment is already there.
  #
  #  The default value in the database for days_of_week is nil,
  #  but it may already have been set up by an assignment.  We
  #  set it up only if it hasn't been.
  #
  def set_up_days_and_weeks
    @daynames_with_index = []
    Date::ABBR_DAYNAMES.each_with_index do |dn, i|
      @daynames_with_index << DaynameWithIndex.new(dn, i)
    end
    @weeks_with_keys = [
      WeekWithKey.new("Week A", "A"),
      WeekWithKey.new("Week B", "B"),
      WeekWithKey.new("Holidays", " ")
    ]

    unless self.days_of_week
      self[:days_of_week] = []
    end
    unless self.weeks
      self[:weeks] = []
    end
  end
end

