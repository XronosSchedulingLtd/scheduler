# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2016 John Winters
# See COPYING and LICENCE in the root directory of the application
# for more information.
#
require 'csv'

#
#  This isn't an ActiveRecord and doesn't exist in the database.  They
#  are constructed in memory when required, and then used.
#
class Day

  class EventDetails

    Period = Struct.new(:start_time, :end_time, :period_no)

    MonFriPeriods = [
      Period["09:00", "09:50", 1],
      Period["09:55", "10:45", 2],
      Period["11:10", "12:05", 3],
      Period["12:10", "13:05", 4],
      Period["14:00", "14:55", 6],
      Period["15:00", "15:55", 7]
    ]
    TueThuPeriods = [
      Period["09:00", "09:50", 1],
      Period["09:55", "10:45", 2],
      Period["11:10", "12:05", 3],
      Period["12:10", "13:05", 4],
      Period["13:45", "14:40", 6],
      Period["14:45", "15:40", 7]
    ]
    WedPeriods = [
      Period["09:00", "09:50", 1],
      Period["09:55", "10:45", 2],
      Period["11:10", "12:05", 3],
      Period["12:10", "13:05", 4],
      Period["13:30", "14:25", 6],
      Period["13:00", "13:55", 6]   # For lower school
    ]
    PeriodTables = [nil,            # Sunday
                    MonFriPeriods,  # Monday
                    TueThuPeriods,  # Tuesday
                    WedPeriods,     # Wednesday
                    TueThuPeriods,  # Thursday
                    MonFriPeriods,  # Friday
                    nil]            # Saturday

    attr_reader :csv_text, :table_text, :note_contents

    #
    #  Try to identify the period number for a given event.
    #  Returns nil if we can't identify it.
    #
    def period_no(event)
      table = PeriodTables[event.starts_at.wday]
      if table
        start_time = event.starts_at.strftime("%H:%M")
        end_time   = event.ends_at.strftime("%H:%M")
        entry = table.detect {|p| p.start_time == start_time &&
                                  p.end_time == end_time }
        if entry
          entry.period_no
        else
          nil
        end
      else
        nil
      end
    end

    def initialize(event, day, current_user)
      @locations_string =
        event.locations.collect {|l| l.friendly_name}.join(", ")
      @staff_string =
        event.staff(true).collect {|s| s.short_name}.join(", ")
      @pupil_string =
        event.pupils(true).collect {|s| s.short_name}.join(", ")
      @period_no = period_no(event)
#      Rails.logger.debug("@period_no = #{@period_no}")
      @note_contents = Array.new
      if event.all_day
        #
        #  If:
        #
        #    We have been asked to add a duration, and
        #    This event last more than one day, and
        #    This event extends beyond the end of the current day
        #
        if day.options[:add_duration] &&
           (event.ends_at > event.starts_at + 1.day) &&
           (event.ends_at > day.ends_at) &&
           event.compactable?
          @table_text =
            "#{event.tidied_body(false)} (to #{event.short_end_date_str})."
        elsif day.options[:mark_end] &&
              (event.ends_at > event.starts_at + 1.day) &&
              (event.ends_at == day.ends_at) &&
              event.compactable?
          @table_text =
            "#{event.tidied_body(false)} - ends."
        else
          @table_text = event.tidied_body(true)
        end
        @csv_text = @table_text
        @duration_string = ""
      else
        if day.options[:by_period] && @period_no
          @duration_string = "Period #{@period_no}"
        else
          @duration_string =
            event.duration_string(day.options[:clock_format],
                                  day.options[:end_times] ||
                                  !event.compactable?,
                                  day.options[:no_space])
        end
        @table_text =
          "#{@duration_string} #{event.tidied_body(true)}"
        @csv_text = event.tidied_body(true)
      end
      if day.options[:add_staff] && !@staff_string.empty?
        @table_text =
          @table_text.chomp(".") + " - " + @staff_string + "."
      end
      if day.options[:add_pupils] && !@pupil_string.empty?
        @table_text =
          @table_text.chomp(".") + " - " + @pupil_string + "."
      end
      if day.options[:add_locations] && !@locations_string.empty?
        @table_text =
          @table_text.chomp(".") + " - " + @locations_string + "."
      end
      #
      #  This is a cludgy way to do it, but...
      #
      unless day.options[:full_stop]
        @table_text.chomp!(".")
        @csv_text.chomp!(".")
      end
      unless day.options[:show_notes].empty?
        #
        #  Need to accumulate the notes suitable for the current user,
        #  who may not be logged in.  Non logged in users get just
        #  public notes.  We therefore need to know who the user is.
        #
        #  Three flag letters M, O and G.
        #  M for notes connected to the current item
        #  O for notes connected to other items
        #  G for general notes, not specific to an item.
        #
        selector = day.options[:show_notes]
        event.all_notes_for(current_user).each do |n|
          unless n.contents.blank?
            #
            #  Now need to decide what category it falls into, and
            #  thus whether to include it.
            #
            if n.parent_type == "Commitment"
              if n.parent.element_id == day.element.id
                if selector.include?("M")
                  @note_contents << n.contents
                end
              else
                if selector.include?("O")
                  @note_contents << n.contents
                end
              end
            else
              if selector.include?("G")
                @note_contents << n.contents
              end
            end
          end
        end
      end
      @csv_data = [@duration_string, @csv_text]
      if day.options[:add_staff]
        @csv_data << @staff_string
      end
      if day.options[:add_pupils]
        @csv_data << @pupil_string
      end
      if day.options[:add_locations]
        @csv_data << @locations_string
      end
      if day.options[:show_notes]
        @note_contents.each do |note|
          #
          #  Some spreadsheets seem to struggle with line feeds
          #  embedded in fields.  Strip them out.
          #
          @csv_data << note.gsub(/\r\n?/, " ")
        end
      end
    end

    def any_notes?
      !@note_contents.empty?
    end

    def to_csv
      @csv_data.to_csv
    end

  end

  attr_reader :date,
              :element,
              :all_day_events,
              :timed_events,
              :starts_at,
              :ends_at,
              :options

  def initialize(date, options, user, element)
    @date = date
    @element = element
    @starts_at = Time.zone.parse(date.strftime("%Y-%m-%d"))
    @ends_at   = Time.zone.parse((date + 1.day).strftime("%Y-%m-%d"))
    @options   = options
    @user      = user
    @all_day_events = []
    @timed_events   = []
  end

  def <<(event)
    if event.all_day
      @all_day_events << EventDetails.new(event, self, @user)
    else
      @timed_events << EventDetails.new(event, self, @user)
    end
  end

  def to_partial_path
    "day"
  end

  def date_text
    self.date.strftime("%a #{self.date.day.ordinalize} %b")
  end

  def events_texts_for_table
    self.all_day_events.each { |e| yield e.table_text, e.note_contents }
    self.timed_events.each { |e| yield e.table_text, e.note_contents }
  end

  def to_csv
    result = ["#{self.date.strftime("%A #{self.date.day.ordinalize} %B, %Y")}"].to_csv
    self.all_day_events.each do |e|
      result += e.to_csv
    end
    self.timed_events.each do |e|
      result += e.to_csv
    end
    result
  end

  def do_breaks?
    @options[:do_breaks]
  end

  def suppress?
    @options[:suppress_empties] &&
    @all_day_events.empty? &&
    @timed_events.empty?
  end

end
