require 'yaml'
require 'date'

class RecurringEvent

  KNOWN_KEYS = [
    "category",
    "title",
    "starts",
    "ends",
    "day",
    "staff",
    "group",
    "location",
    "property",
    "start_date",
    "end_date",
    "week",
    "greyed",
    "occurrence",
    "note",
    "organiser"
  ]

  KNOWN_OCCURRENCES = [
    :first,
    :second,
    :third,
    :fourth,
    :fifth,     # It can happen
    :last,
    :penultimate,
    :antepenultimate,
    :all
  ]


  class CriteriaSet
    #
    #  These can be specified only once.
    #
    attr_accessor :category,
                  :title,
                  :ends,
                  :day,
                  :start_date,
                  :end_date,
                  :week,
                  :greyed,
                  :occurrence,
                  :note,
                  :organiser
    #
    #  These can be specified more than once.
    #
    attr_reader   :staff,
                  :starts,
                  :groups,
                  :locations,
                  :properties,
                  :eventcategory,
                  :resource_ids,
                  :all_day

    #
    #  This is a calculated one.
    #
    attr_reader   :organiser_element

    def initialize
      @staff       = Array.new
      @groups      = Array.new
      @locations   = Array.new
      @properties  = Array.new
      @week        = "AB"
      @greyed      = false
      @occurrence  = :all
      @all_day     = false
    end

    def deep_clone
      Marshal.load(Marshal.dump(self))
    end

    def staff=(initials)
      @staff << initials
    end

    def property=(property)
      @properties << property
    end

    def group=(group)
      @groups << group
    end

    def location=(location)
      @locations << location
    end

    def occurrence=(occurrence)
      symbol = occurrence.downcase.to_sym
      if KNOWN_OCCURRENCES.include?(symbol)
        @occurrence = symbol
      else
        raise "Don't know how to handle an occurrence specified as \"#{occurrence}\"."
      end
    end

    def starts=(starttime)
      if starttime == :all_day
        @all_day = true
      else
        @starts = starttime
        if @ends == nil
          @ends = starttime
        end
      end
    end

    def complete?
      if @category.blank? ||
         @title.blank? ||
         (@starts.blank? && !@all_day) ||
         @day.blank? ||
         (@staff.size == 0 &&
          @groups.size == 0 &&
          @locations.size == 0 &&
          @properties.size == 0)
        false
      else
        true
      end
    end

    def active_on?(date)
      #
      #  This event is active on the specified date if
      #    it has no start date, or its start date <= the date
      #    and
      #    it has no end date, or its end date >= the date
      #
      #  There is then a further check to see whether it is the right
      #  occurrence.
      #
      if (@start_date == nil || @start_date <= date) &&
         (@end_date == nil   || @end_date >= date)
        monlen = date.days_in_month
        delta = monlen - date.day
        case @occurrence
        when :first
          date.day <= 7

        when :second
          date.day > 7 && date.day <= 14

        when :third
          date.day > 14 && date.day <= 21

        when :fourth
          date.day > 21 && date.day <= 28

        when :fifth     # It can happen
          date.day > 28

        when :last
          delta < 7

        when :penultimate
          delta >= 7 && delta < 14

        when :antepenultimate
          delta >= 14 && delta < 21

        when :all
          true

        else
          #
          #  If we can't make any sense of it then default to allowing
          #  it.
          #
          true

        end
      else
        false
      end
    end

    def known_details
      bits = [
        @title.blank? ? nil : "Title: #{@title}",
        @category.blank? ? nil : "Category: #{@category}",
        @starts.blank? ? nil : "Starts: #{@starts}",
        @day.blank? ? nil : "Day: #{@day}"
      ].compact
      "Event: #{bits.join(" / ")}"
    end

    def deficiencies
      result = Array.new
      result << known_details
      if @category.blank?
        result << "  No category specified"
      end
      if @title.blank?
        result << "  No title specified"
      end
      if @starts.blank? && !@all_day
        result << "  No start time specified"
      end
      if @day.blank?
        result << "  No day specified"
      end
      if @staff.size == 0 &&
         @groups.size == 0 &&
         @locations.size == 0 &&
         @properties.size == 0
        result << "  No resources specified."
      end

      result.join("\n")
    end

    #
    #  Find the resources needed by this event in the d/b.
    #  Return true if all found, false otherwise.
    #
    def find_resources
      success = true
      @eventcategory = Eventcategory.find_by(name: @category)
      unless @eventcategory
        puts "Failed to find event category #{@category} for #{@title}."
        success = false
      end
      @resource_ids = Array.new
      @staff.each do |s|
        rec = Staff.current.find_by(initials: s)
        if rec
          @resource_ids << rec.element.id
        else
          puts "Can't find staff record #{s} for #{@title}."
          success = false
        end
      end
      @groups.each do |g|
        rec = Group.current.find_by(name: g)
        if rec
          @resource_ids << rec.element.id
        else
          puts "Can't find group #{g} for #{@title}."
          success = false
        end
      end
      @locations.each do |l|
        rec = Location.find_generously(l)
        if rec
          @resource_ids << rec.element.id
        else
          puts "Can't find location #{l} for #{@title}."
          success = false
        end
      end
      @properties.each do |p|
        rec = Property.find_by(name: p)
        if rec
          @resource_ids << rec.element.id
        else
          puts "Can't find property #{p} for #{@title}."
          success = false
        end
      end
      if @organiser
        staff = Staff.current.find_by(initials: @organiser)
        if staff
          @organiser_element = staff.element
        else
          puts "Can't find staff record #{s} as organiser for #{@title}."
          success = false
        end
      end
      success
    end

    def dump
      #
      #  Print out this criteria set in a reasonable form.
      #
      puts "Repeating event:"
      puts "  Category: #{@category}"
      puts "  Title:    #{@title}"
      puts "  Day:      #{@day}"
      if @all_day
        puts "  All day"
      else
        puts "  Starts:   #{@starts}"
        if @ends
          puts "  Ends:     #{@ends}"
        end
      end
      puts "  Week:     #{@week}"
      if @start_date
        puts "  Starts on #{@start_date}"
      end
      if @end_date
        puts "  Ends on   #{@end_date}"
      end
      if @greyed
        puts "  Greyed out"
      end
      if @staff.size > 0
        puts "  Staff:    #{@staff.join(",")}"
      end
      if @groups.size > 0
        puts "  Groups:   #{@groups.join(",")}"
      end
      if @locations.size > 0
        puts "  Location: #{@locations.join(",")}"
      end
      if @properties.size > 0
        puts "  Property: #{@properties.join(",")}"
      end
    end

  end

  def self.process(contents, cs = CriteriaSet.new)
    if contents.instance_of?(Hash)
      #
      #  Each time we find a hash we do a save (after processing all
      #  its entries) unless we found an array within it.  If we did
      #  then that array should have been an array of hashes, and each
      #  of them then takes over responsibility for the cloning.
      #
      do_save = true
      contents.each do |key, data|
        if KNOWN_KEYS.include?(key)
          if data.respond_to?(:each)
            data.each do |datum|
              cs.send("#{key}=", datum)
            end
          else
            cs.send("#{key}=", data)
          end
        else
          #
          #  Should be an embedded array.
          #
          do_save = false
          if data.instance_of?(Array)
            process(data, cs)
          else
            raise "The data following hash key: \"#{key}\" should be an array."
          end
        end
      end
      if do_save
        if cs.complete?
#          cs.dump
          @events << cs
        else
          raise cs.deficiencies
        end
      end
    elsif contents.instance_of?(Array)
      contents.each do |item|
        process(item, cs.deep_clone)
      end
    else
      raise "Hit #{contents.class}"
    end
  end

  #
  #  N.B.  If the file contains a structural error (invalid YAML)
  #  then this method will throw an exception.  Calling code should
  #  catch and report it before moving on to another file.
  #
  def self.readfile(filename)
    contents = YAML.load_file(filename)
    @events = Array.new
    process(contents)
    @events
  end

end


class RecurringEventStore
  #
  #  The job of this class is to take one or more batches of recurring
  #  events and sort them so that at a later date it can answer the
  #  question:
  #
  #    Give me an array of all recurring events on this date in week A/B.
  #
  #  It would be feasible to pass in just a date, but then this class
  #  would need to access the database to find out the week letter, breaking
  #  encapsulation.  The calling code already has that information so it
  #  can do it.
  #
  #  We don't know in advance the range of dates which our client will
  #  use, but we do know what range some of our events apply to.
  #
  #  We store our events, sorted by day of the week, and week letter.
  #
  #  Note that you can define any week letter you like in the input
  #  file, and indeed call your weekdays anything you like.  However,
  #  they won't then be found unless you ask for them by those names.

  def initialize
    @weeks = Hash.new
  end

  def note_event(event)
    event.week.each_char do |c|
      @weeks[c] ||= Hash.new
      @weeks[c][event.day] ||= Array.new
      @weeks[c][event.day] << event
    end
  end

  def note_events(events)
    events.each do |e|
      note_event(e)
    end
  end

  #
  #  Note that week may be passed as "nil", meaning there is no week
  #  letter currently in effect.  We turn that into a space internally,
  #  and serve events explicitly specified as happening when there is
  #  no week in effect - i.e. outside term.
  #
  def events_on(date, week)
    events = []
    weekday = date.strftime("%A")
    unless week
      week = " "
    end
    weekset = @weeks[week]
    if weekset
      events = weekset[weekday]
      if events
        #
        #  These now want filtering to only those valid on the specified
        #  date
        #
        events = events.select {|e| e.active_on?(date) }
      else
        #
        #  It's important to return an empty array rather than nil,
        #  because the day still needs to be processed.  It might be
        #  that there used to be events and now there aren't.  The old
        #  ones need to be deleted.
        #
        events = []
      end
    end
    events
  end

end

#begin
#  res = RecurringEventStore.new
#  res.note_events(RecurringEvent.readfile("Recurring.yml"))
#  1.upto(5) do |adj|
#    events = res.events_on(Date.today + adj, "B")
#    puts "Got #{events.count} events."
#    events.each do |e|
#      e.dump
#    end
#  end
#rescue Exception => e
#  puts "Error processing Recurring.yml"
#  puts e
#end
