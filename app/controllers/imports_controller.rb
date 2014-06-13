require 'csv'
require 'charlock_holmes'

class CalendarEntry

  attr_reader :starts_at, :ends_at, :description, :all_day

  #
  #  The Subject field in the calendar export file actually seems to contain
  #  the description of the event.
  #
  #  Apart from these, the current file contains:
  #
  #    Location    - generally empty
  #    Description - generally empty, but sometimes used for ancillary
  #                  information.
  #
  #
  #  Note that the import file claims to contain zone information, but it's
  #  lying.  We need to assume all text will be for what we think the
  #  zone is.
  #
  REQUIRED_COLUMNS = [["Subject",       :subject],
                      ["Start Date",    :start_date],
                      ["Start Time",    :start_time],
                      ["End Date",      :end_date],
                      ["End Time",      :end_time],
                      ["All day event", :all_day]]

  def initialize(description, start_date, start_time, end_date, end_time, all_day)
    @description = description.encode("utf-8",
                                      "binary",
                                      :invalid => :replace,
                                      :undef => :replace,
                                      :replace => "")
    @all_day = (all_day == "True")
    if @all_day
      @starts_at = Time.zone.parse("#{start_date}")
      @ends_at   = Time.zone.parse("#{end_date.empty? ?
                                     start_date :
                                     end_date}")
    else
      @starts_at = Time.zone.parse("#{start_date} #{start_time}")
      @ends_at   = Time.zone.parse("#{end_date.empty? ?
                                     start_date :
                                     end_date} #{end_time}")
      #
      #  A little frig is needed to cope with an error in the program
      #  generating our input file.  Where an event finishes on the same
      #  day as it starts, the generator leaves the end_date field empty
      #  and simply provides an end time.  *But*, if the event finishes
      #  at midnight it provides a time field of "12:00:00 AM", which
      #  of course parses as being midnight at the *start* of the same day
      #  It should provide a date in this particular circumstance.
      #
      if end_date.empty? && end_time == "12:00:00 AM"
        @ends_at += 1.day
      end
    end
    #
    #  Now - do we need to adjust the end date and description?
    #
#    Rails.logger.info "Checking \"#{@description}\""
    newdescription, inner = check_end_date(@description)
    if inner
#      Rails.logger.info "Adjusting \"#{@description}\""
      orgdate = @ends_at ? @ends_at : @starts_at
#      Rails.logger.info "orgdate = #{orgdate}"

      begin
        parseddate = Date.parse(inner)
        if parseddate
          
          newdate = Time.zone.parse("#{orgdate.year}-#{parseddate.month}-#{parseddate.day} #{orgdate.hour}:#{orgdate.min}:#{orgdate.sec}")
#          newdate = DateTime.new(orgdate.year,
#                                 parseddate.month,
#                                 parseddate.day,
#                                 orgdate.hour,
#                                 orgdate.min,
#                                 orgdate.sec)
        end
#        Rails.logger.info "New date is #{newdate} (#{newdate.class})"
        if newdate < @starts_at
#          puts "Negative duration detected for #{eventoccurence.summary}."
          #
          #  Need to advance by a year.
          #
#          puts "Newdate starts as #{newdate.to_s}"
          newdate = newdate + 1.year
#          puts "Newdate finishes as #{newdate.to_s}"
        end
        #
        #  Let's keep this sane.  We may have got it hopelessly wrong.
        #
        if newdate - @starts_at < 2.months
          @ends_at     = newdate
          @description = newdescription
          #
          #  I used to preserve the provided times, but for a multi-day
          #  event they were almost always wrong.  Force any such
          #  multi-day event to be also an all-day event.
          #
          @all_day     = true
        end

      rescue Exception
        Rails.logger.info "\"#{inner}\" can't be understood as a date - #{$!}"
      end
    end
  end

  #
  #  If this entry describes a week then return A or B.  If not, return nil.
  #
  def week_letter
    if self.description =~ /^WEEK\b/
      weekletter = self.description.split(" ")[1]
      if weekletter && (weekletter == "A" || weekletter == "B")
        weekletter
      else
        nil
      end
    else
      nil
    end
  end

  def <=>(other)
    self.starts_at <=> other.starts_at
  end

  def self.array_from_csv_data(csv_data)
    #
    #  Do we have the required columns?
    #
    missing = false
    column_hash = {}
    REQUIRED_COLUMNS.each do |column|
      index = csv_data[0].find_index(column[0])
      if index
        column_hash[column[1]] = index
      else
        missing = true
      end
    end
    if missing
      return nil, "One or more required column(s) missing."
    else
      entries = []
      csv_data.each_with_index do |parsed_line, i|
        if i != 0
          entries << CalendarEntry.new(parsed_line[column_hash[:subject]],
                                       parsed_line[column_hash[:start_date]],
                                       parsed_line[column_hash[:start_time]],
                                       parsed_line[column_hash[:end_date]],
                                       parsed_line[column_hash[:end_time]],
                                       parsed_line[column_hash[:all_day]])
        end
      end
      return entries, ""
    end
  end

  private

  #
  #  Check an event summary to see whether it contains an embedded end
  #  date.
  #
  def check_end_date(description)
    #
    #  Regexes are powerful, but it's very hard to see what the code
    #  is doing.  Here we are checking for an embedded occurence of
    #  "(until <date>)".  If found, we strip it out of the summary string
    #  and return both the modified summary and the "<date>" bit.
    #
    if description =~ /\(until.*?\)/
#      puts "Found #{$&}"
      newdescription = "#{$`}#{$'}"
      inner = $&.sub(/^\(until\s*/, '').sub(/\)$/, '')
#      puts "inner = \"#{inner}\""
      [newdescription, inner]
    else
      [description, nil]
    end
  end


end

class ImportsController < ApplicationController

  IMPORT_DIR = 'staging'

  #
  #  Provide an index of the stuff currently uploaded and the option
  #  to upload something else.
  #
  def index
    @files = Dir.entries(Rails.root.join(IMPORT_DIR)) - [".", ".."]
  end

  #
  #  Receive an incoming file.
  #
  def upload
    uploaded_io = params[:incoming]
    if uploaded_io
      File.open(Rails.root.join(IMPORT_DIR,
                                uploaded_io.original_filename), 'wb') do |file|
        file.write(uploaded_io.read)
      end
    end
    redirect_to imports_index_path
  end

  #
  #  Delete an individual file.
  #
  def delete
#    raise params.inspect
    name = params[:name]
    #
    #  Although we only provide links to valid files, it's possible someone
    #  could spoof a request to include directory navigation.  Strip the
    #  name down to its leaf part only.
    #
    if name
      name = File.basename(name)
      File.unlink(Rails.root.join(IMPORT_DIR, name))
    end
    redirect_to imports_index_path
  end

  def check_csv
    name = params[:name]
    if name
      @name = File.basename(name)
      #
      #  For now we can process only CSV files.
      #  The CSV library is strangely fragile, in that it will simply
      #  error out if it encounters a character which it doesn't think
      #  should be there, even though it doesn't affect the structure
      #  of the file.  I therefore need to pre-process to avoid run-time
      #  errors.
      #
      if File.extname(@name).downcase == '.csv'
        contents = File.read(Rails.root.join(IMPORT_DIR, @name))
        detection = CharlockHolmes::EncodingDetector.detect(contents)
        utf8_encoded_contents =
          CharlockHolmes::Converter.convert(contents,
                                            detection[:encoding],
                                            'UTF-8')
        parsed = CSV.parse(utf8_encoded_contents)
        entries, message = CalendarEntry.array_from_csv_data(parsed)
        if entries
          @earliest_date = nil
          @latest_date   = nil
          entries.each do |entry|
            if @earliest_date == nil ||
               entry.starts_at < @earliest_date
              @earliest_date = entry.starts_at
            end
            if @latest_date == nil ||
               entry.ends_at > @latest_date
              @latest_date = entry.ends_at
            end
          end
          @entries = entries.size
        else
          redirect_to imports_index_path, message
        end
      else
        redirect_to imports_index_path,
                    notice: 'Currently we can process only CSV files.'
      end
    end
  end

  def commit_csv
#    raise params.inspect
    eventsource = Eventsource.find(params[:eventsource])
    calendarcategory = Eventcategory.find_by_name("Calendar")
    weeklettercategory = Eventcategory.find_by_name("Week letter")
    dutycategory = Eventcategory.find_by_name("Duty")
    if calendarcategory && weeklettercategory && dutycategory
      start_date = Time.zone.parse(params[:first_date])
      #
      #  Since we are purging events, we want all events up to midnight at
      #  the start of the day *after* the indicated day.
      #
      end_date   = Time.zone.parse(params[:last_date]) + 1.day
      do_purge   = (params[:do_purge] == 'yes')
      do_load    = (params[:do_load] == 'yes')
      @failures  = []
      #
      #  Should do some validation of the input parameters here.
      #
  #    raise do_purge.inspect
      if do_purge
        #
        #  Need to purge all events for the indicated interval from this
        #  event source.  Want to purge anything with a presence within this
        #  period.  This is the same philosophy as we use when loading - anything
        #  which has any part of its duration within the indicated period
        #  gets loaded.
        #
        Event.beginning(start_date).until(end_date).eventsource_id(eventsource.id).destroy_all
      end
      if do_load
        name = params[:name]
        if name
          @name = File.basename(name)
          #
          #  For now we can process only CSV files.
          #  The CSV library is strangely fragile, in that it will simply
          #  error out if it encounters a character which it doesn't think
          #  should be there, even though it doesn't affect the structure
          #  of the file.  I therefore need to pre-process to avoid run-time
          #  errors.
          #
          if File.extname(@name).downcase == '.csv'
            contents = File.read(Rails.root.join(IMPORT_DIR, @name))
            detection = CharlockHolmes::EncodingDetector.detect(contents)
            utf8_encoded_contents =
              CharlockHolmes::Converter.convert(contents,
                                                detection[:encoding],
                                                'UTF-8')
            parsed = CSV.parse(utf8_encoded_contents)
            entries, message = CalendarEntry.array_from_csv_data(parsed)
            if entries
              weekletterentries = []
              entries.each do |entry|
                if entry.week_letter
                  #
                  #  We save these up and process them at the end.
                  #
                  weekletterentries << entry
                else
                  event = Event.new
                  event.starts_at = entry.starts_at
                  event.ends_at   = entry.ends_at
                  event.all_day   = entry.all_day
                  event.body      = entry.description
                  event.eventcategory = calendarcategory
                  event.eventsource   = eventsource
                  unless event.save
                    @failures << "Event #{entry.description} was invalid."
                  end
                end
              end
              if weekletterentries.size > 0
                currentweekletter = nil
                currentweekstart  = nil
                currentweekend    = nil
                weekletterentries.sort.each do |wle|
      #            puts "Processing WEEK #{
      #                                wle.weekletter
      #                              } on #{
      #                                wle.dtstart.to_formatted_s(:dmy)}"
                  if wle.week_letter == currentweekletter
                    #
                    #  The week continues
                    #
                    currentweekend = wle.ends_at
                  else
                    if currentweekletter
                      #
                      #  Need to flush this one to the d/b.
                      #
      #                puts "Trying to save #{
      #                        currentweekstart.to_formatted_s(:dmy)
      #                      } to #{
      #                        currentweekend.to_formatted_s(:dmy)
      #                      }"
                      event = Event.new
                      event.starts_at = currentweekstart
                      event.ends_at   = currentweekend
                      event.all_day   = true
                      event.body      = "WEEK #{currentweekletter}"
                      event.eventcategory = weeklettercategory
                      event.eventsource   = eventsource
                      unless event.save
                        @failures << "Event #{entry.description} was invalid."
                      end
                    end
                    currentweekletter = wle.week_letter
                    currentweekstart  = wle.starts_at
                    currentweekend    = wle.ends_at
                  end
                end # Looping through week letters.
                if currentweekletter
                  #
                  #  Need to flush this final one to the d/b.
                  #
                  event = Event.new
                  event.starts_at = currentweekstart
                  event.ends_at   = currentweekend
                  event.all_day   = true
                  event.body      = "WEEK #{currentweekletter}"
                  event.eventcategory = weeklettercategory
                  event.eventsource   = eventsource
                  unless event.save
                    @failures << "Event #{entry.description} was invalid."
                  end
                end
              
              end
            else
              redirect_to import_index_path, message
            end
          else
            redirect_to imports_index_path,
                        notice: 'Currently we can process only CSV files.'
          end
        else
          redirect_to imports_index_path
        end
      end
    else
      redirect_to imports_index_path,
                  notice: "Can't find necessary event categories." 
    end
  end
end
