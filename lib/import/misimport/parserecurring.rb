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
    "greyed"
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
                  :greyed
    #
    #  These can be specified more than once.
    #
    attr_reader   :staff,
                  :starts,
                  :groups,
                  :locations,
                  :properties,
                  :eventcategory,
                  :resource_ids

    def initialize
      @staff      = Array.new
      @groups     = Array.new
      @locations  = Array.new
      @properties = Array.new
      @week       = "AB"
      @greyed     = false
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

    def starts=(starttime)
      @starts = starttime
      if @ends == nil
        @ends = starttime
      end
    end

    def complete?
      if @category.empty? ||
         @title.empty? ||
         @starts.empty? ||
         @day.empty? ||
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
      (@start_date == nil || @start_date <= date) &&
      (@end_date == nil   || @end_date >= date)
    end

    def known_details
      bits = [
        @title.empty? ? nil : "Title: #{@title}",
        @category.empty? ? nil : "Category: #{@category}",
        @starts.empty? ? nil : "Starts: #{@starts}",
        @day.empty? ? nil : "Day: #{@day}"
      ].compact
      "Event: #{bits.join(" / ")}"
    end

    def deficiencies
      result = Array.new
      result << known_details
      if @category.empty?
        result << "  No category specified"
      end
      if @title.empty?
        result << "  No title specified"
      end
      if @starts.empty?
        result << "  No start time specified"
      end
      if @day.empty?
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
        rec = Staff.find_by(initials: s)
        if rec
          @resource_ids << rec.element.id
        else
          puts "Can't find staff record #{s} for #{@title}."
          success = false
        end
      end
      @groups.each do |g|
        rec = Group.find_by(name: g)
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
      puts "  Starts:   #{@starts}"
      if @ends
        puts "  Ends:     #{@ends}"
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
            raise "Data for key #{key} should be an array."
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

  def events_on(date, week)
    events = []
    weekday = date.strftime("%A")
#    puts "#{date} is a #{weekday}"
    weekset = @weeks[week]
    if weekset
      events = weekset[weekday]
      if events
        #
        #  These now want filtering to only those valid on the specified
        #  date
        #
        events = events.select {|e| e.active_on?(date) }
#      else
#        puts "No events on #{weekday}s in week #{week}."
      end
#    else
#      puts "No events in week #{week}."
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
