# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2014 John Winters
# See COPYING and LICENCE in the root directory of the application
# for more information.

require 'csv'
require 'charlock_holmes'
require 'chronic_duration'

class Locator
  #
  #  A class which tries to identify the locations used by an event.
  #

  def initialize
    #
    #  We need to get a list of all location aliases in the database
    #  which point to an active location, and put them in a lookup table.
    #
    #  If there are two location aliases with the same name, we can handle
    #  only one of them.  Raise an error message for the other.
    #
    @location_hash = {}
    Locationalias.where("location_id IS NOT NULL").each do |la|
      if la.location && la.location.active
        @location_hash[la.name.downcase] = la
      end
    end
  end

  def check_for_locations(description)
    #
    #  Some summaries end with "(tbc)" or "(TBC)" which interferes
    #  with location identification.  Strip it off if present and put
    #  it back later.
    #
    orgdescription = description
    if description =~ /\s*\((TBC|tbc)\)\s*$/
      description = $`
      tbc = true
    else
      tbc = false
    end
    #
    #  Split the description at commas, ignoring white space either side
    #  of the commas.
    #
    found_something = false
    unused = Array.new
    locations = Array.new
    broken = description.split(/\s*,\s*/)
    broken.each do |chunk|
      location = @location_hash[chunk.downcase.chomp(".")]
      if location
        found_something = true
#        Rails.logger.info "Found #{location.name} in \"#{description}\"."
        locations << location
      else
        #
        #  Sometimes a chunk contains more than one location,
        #  joined/separated by "/", "and", "&" or "then".  There is
        #  a limit to what we can process, but have a go.
        #
        sublocations = try_to_split(chunk)
        if sublocations.size > 0
          found_something = true
          locations += sublocations
        else
          unused << chunk
        end
      end
    end
    if found_something
#     Rails.logger.info("LOC: \"#{orgdescription}\" yields:")
#     locations.each do |la|
#       Rails.logger.info("LOC:    #{la.name}")
#     end
      ["#{unused.join(", ")}#{tbc ? " (tbc)" : ""}",
       locations.collect {|la| la.location}]
    else
#     Rails.logger.info("LOC: No locations: \"#{orgdescription}\"")
      [orgdescription, []]
    end
  end

  private

  #
  #  See whether a chunk can be split up into more than one location.
  #
  def try_to_split(chunk)
#      puts "Trying to split \"#{chunk}\"."
    subchunks =
      chunk.split(/\s*(\/|&|then|and)\s*/) - ["/", "&", "then", "and"]
#      puts "Turned into \"#{subchunks.join("\", \"")}\"."
    if subchunks.size > 1
      #
      #  All must be identifiable locations for us to accept it.
      #
      failed_any = false
      locations = []
      subchunks.each do |sc|
        #
        #  Someone has started putting trailing full stops onto location
        #  names.  Never used to happen.
        #
#        Rails.logger.info "Testing \"#{sc.downcase.chomp(".")}\"."
        location = @location_hash[sc.downcase.chomp(".")]
        if location
#            puts "Found #{location.name}"
          locations << location
        else
#            puts "\"#{sc}\" couldn't be identified."
          failed_any = true
        end
      end
      if failed_any
        []
      else
        locations
      end
    else
#        puts "Too few subchunks to work."
      []
    end
  end

end

class CalendarEntry
  attr_reader :starts_at, :ends_at, :description, :all_day

  def initialize(description, starts_at, ends_at, all_day)
    @description = description
    @starts_at   = starts_at
    @ends_at     = ends_at
    @all_day     = all_day
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

end

class CalendarEntryCSV < CalendarEntry

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

  ALTERNATIVE_COLUMNS = [["Subject",         :subject],
                         ["Start Date/Time", :start_datetime],
                         ["End Date/Time",   :end_datetime],
                         ["All day event",   :all_day],
                         ["Duration",        :duration]]

  def initialize(description,
                 start_date,
                 start_time,
                 end_date,
                 end_time,
                 all_day)
    description = description.encode("utf-8",
                                     "binary",
                                     :invalid => :replace,
                                     :undef => :replace,
                                     :replace => "")
    all_day = (all_day == "True")
    if all_day
      starts_at = Time.zone.parse("#{start_date}")
      ends_at   = Time.zone.parse("#{end_date.empty? ?
                                    start_date :
                                    end_date}") + 1.day
    else
      starts_at = Time.zone.parse("#{start_date} #{start_time}")
      ends_at   = Time.zone.parse("#{end_date.empty? ?
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
        ends_at += 1.day
      end
    end
    #
    #  Now - do we need to adjust the end date and description?
    #
#    Rails.logger.info "Checking \"#{@description}\""
    newdescription, inner = check_end_date(@description)
    if inner
#      Rails.logger.info "Adjusting \"#{@description}\""
      orgdate = ends_at ? ends_at : starts_at
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
        if newdate < starts_at
#          puts "Negative duration detected for #{eventoccurrence.summary}."
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
        if newdate - starts_at < 2.months
          ends_at     = newdate + 1.day
          description = newdescription
          #
          #  I used to preserve the provided times, but for a multi-day
          #  event they were almost always wrong.  Force any such
          #  multi-day event to be also an all-day event.
          #
          all_day     = true
        end

      rescue Exception
        Rails.logger.info "\"#{inner}\" can't be understood as a date - #{$!}"
      end
    end
    super(description, starts_at, ends_at, all_day)
  end

  #
  #  This method takes data removed in a pretty raw form from the Calendar
  #  database, and massages it to suit the above "initialise" method.
  #
  def self.construct(description,
                     start_datetime,
                     end_datetime,
                     all_day,
                     duration)
    starts_at = Time.zone.parse(start_datetime)
    start_date = starts_at.strftime("%Y-%m-%d")
    start_time = starts_at.strftime("%H:%M:%S")
    durationsecs  = ChronicDuration.parse(duration, :keep_zero => true)
    if end_datetime == "1970-01-01 00:00:00"
      if durationsecs > 0
        ends_at = starts_at + durationsecs.seconds
        end_date = ends_at.strftime("%Y-%m-%d")
        end_time = ends_at.strftime("%H:%M:%S")
      else
        end_date = ""
        end_time = start_time
      end
    else
      ends_at  = Time.zone.parse(end_datetime)
      end_date = ends_at.strftime("%Y-%m-%d")
      end_time = ends_at.strftime("%H:%M:%S")
    end
    #Rails.logger.info "Event \"#{description}\" from #{starts_at} to #{ends_at} lasting #{durationsecs ? durationsecs : "nil"}."
    self.new(description,
             start_date,
             start_time,
             end_date,
             end_time,
             all_day == "1" ? "True" : "False")
  end

  def self.array_from_data(csv_data)
    #
    #  Do we have the required columns?
    #
    missing = false
    column_hash = {}
    entries = []
    REQUIRED_COLUMNS.each do |column|
      index = csv_data[0].find_index(column[0])
      if index
        column_hash[column[1]] = index
      else
        missing = true
      end
    end
    if missing
      #
      #  Have another go with an alternative set of columns.
      #
      missing = false
      column_hash = {}
      ALTERNATIVE_COLUMNS.each do |column|
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
        #
        #  The alternative columns seem to be there, but slightly
        #  more processing will thus be needed.
        #
        csv_data.each_with_index do |parsed_line, i|
          if i != 0
            entries << CalendarEntryCSV.construct(
                         parsed_line[column_hash[:subject]],
                         parsed_line[column_hash[:start_datetime]],
                         parsed_line[column_hash[:end_datetime]],
                         parsed_line[column_hash[:all_day]],
                         parsed_line[column_hash[:duration]])
          end
        end
        return entries, ""
      end
    else
      csv_data.each_with_index do |parsed_line, i|
        if i != 0
          entries << CalendarEntryCSV.new(parsed_line[column_hash[:subject]],
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
    #  is doing.  Here we are checking for an embedded occurrence of
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

class CalendarEntryICS < CalendarEntry

  def self.array_from_data(ics_data)
    entries = []
    ics_data.events.each do |event|
      if event.bounded?
        event.occurrences.each do |occurrence|
          start_time = occurrence.dtstart.strftime("%H:%M:%S")
          if occurrence.dtend
            end_time = occurrence.dtend.strftime("%H:%M:%S")
          else
            end_time = start_time
          end
          all_day = (start_time == "00:00:00" && end_time == "00:00:00")
          #
          #  If no dtend has been provided then all day events last one
          #  day, whilst timed events have zero duration.
          #
          if occurrence.dtend
            dtend = occurrence.dtend
          else
            if all_day
              dtend = occurrence.dtstart + 1.day
            else
              dtend = occurrence.dtstart
            end
          end
          entries <<
            CalendarEntryICS.new(occurrence.summary,
                                 occurrence.dtstart,
                                 dtend,
                                 all_day)
        end
      else
        Rails.logger.info("Unbounded event - #{event.summary}")
      end
    end
    return entries, ""
  end
end

class ImportsController < ApplicationController

  IMPORT_DIR = 'staging'

  #
  #  Provide an index of the stuff currently uploaded and the option
  #  to upload something else.
  #
  def index
    @files = Dir.entries(Rails.root.join(IMPORT_DIR)) - [".", "..", ".keep"]
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

  def check_file
    name = params[:name]
    if name
      @name = File.basename(name)
      #
      #  For now we can process only CSV and ICS files.
      #
      #  The CSV library is strangely fragile, in that it will simply
      #  error out if it encounters a character which it doesn't think
      #  should be there, even though it doesn't affect the structure
      #  of the file.  I therefore need to pre-process to avoid run-time
      #  errors.
      #
      extension = File.extname(@name).downcase
      if extension == '.csv'
        contents = File.read(Rails.root.join(IMPORT_DIR, @name))
        detection = CharlockHolmes::EncodingDetector.detect(contents)
        utf8_encoded_contents =
          CharlockHolmes::Converter.convert(contents,
                                            detection[:encoding],
                                            'UTF-8')
        parsed = CSV.parse(utf8_encoded_contents)
        entries, message = CalendarEntryCSV.array_from_data(parsed)
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
      elsif extension == '.ics'
        File.open(Rails.root.join(IMPORT_DIR, @name), "r") do |file|
          contents = RiCal.parse(file)
        end
        calendar = contents.first
        entries, message = CalendarEntryICS.array_from_data(calendar)
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
                    notice: 'Currently we can process only CSV or ICS files.'
      end
    end
  end

  def add_event(starts_at,
                ends_at,
                all_day,
                body,
                category,
                source,
                resources = nil)
    event = Event.new
    event.starts_at     = starts_at
    event.ends_at       = ends_at
    event.all_day       = all_day
    event.body          = body
    event.eventcategory = category
    event.eventsource   = source
    if event.save
      event.reload
      if resources
        resources.each do |resource|
          c = Commitment.new
          c.event = event
          c.element = resource.element
          c.save
        end
      end
      true
    else
      false
    end
  end

  def find_relevant_staff(description, known_staff)
    #
    #  Check for the key word "and" in the description.  If it's there
    #  then we expect two staff, otherwise just one.
    #
    if description =~ /\band\b/
      expecting = 2
    else
      expecting = 1
    end
    #
    #  Do an initial selection *just* by surname.
    #
    candidates = known_staff.select {|ks|
      description =~ Regexp.new("\\b#{ks.surname}\\b", "i")
    }
    #
    #  Can't just check we have the right number.  We might have a
    #  description containing "Mr J Taylor and Mr Fred Bloggs" and
    #  have found both Mr Taylors in the database, but no Fred Bloggs.
    #
    if candidates.size == expecting &&
       candidates.collect {|c| c.surname}.uniq.size == expecting
      #
      #  Good enough
      #
      candidates
    else
      if candidates.size >= expecting
        #
        #  Too many (or just enough, but not unique surnames).
        #  Surprisingly often the description goes "Mr J Taylor and Mr R Taylor"
        #  which will have failed the previous test but is still good.
        #
        #  Tests are as follows:
        #
        #    Count how many candidates have a surname containing this
        #    candidates surname.  If the total is 1 (i.e. himself) then
        #    he stays in the running.
        #
        #    For, for instance, "Fred Bloggs", if "F Bloggs" occurs in
        #    the description then he stays in.
        #
        #    Likewise, if "Mr Bloggs" is there he stays in.
        #
        filtered_candidates = candidates.select do |c|
          (candidates.count {|ic| ic.surname =~ Regexp.new("\\b#{c.surname}\\b")} == 1) ||
          (description =~ Regexp.new("\\b#{c.forename[0]}\\s#{c.surname}\\b")) ||
          (description =~ Regexp.new("\\b#{c.title}\\s#{c.surname}\\b"))
        end
        #
        #  Do I now have the right number?
        #
        if filtered_candidates.size == expecting
          filtered_candidates
        else
          @failures << "Giving up on \"#{description}\""
          @failures <<
            "Have #{filtered_candidates.collect {|fc| fc.name}.join(",")}"
          @failures <<
            "Out of #{candidates.collect {|fc| fc.name}.join(",")}"
          nil
        end
      else
        #
        #  Too few.  We have no way of making our selection criteria
        #  any less strict, so we have failed.
        #
        @failures << "Couldn't identify staff \"#{description}\""
        if candidates.size > 0
          @failures << "Found: #{candidates[0].name}"
        end
        if candidates.size > 0
          candidates
        else
          nil
        end
      end
    end
  end

  def commit_file
    #raise params.inspect
    eventsource = Eventsource.find(params[:eventsource])
    maincategory = Eventcategory.find(params[:event_category])
    weeklettercategory = Eventcategory.find_by_name("Week letter")
    dutycategory = Eventcategory.find_by_name("Duty")
    property_element = Element.find_by(id: params[:property_element_id])
    property = property_element ? property_element.entity : nil
    known_staff = Staff.active.current.teaching
    if maincategory && weeklettercategory && dutycategory && property
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
        Event.beginning(start_date).
              until(end_date).
              eventsource_id(eventsource.id).
              destroy_all
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
            entries, message = CalendarEntryCSV.array_from_data(parsed)
          elsif File.extname(@name).downcase == '.ics'
            File.open(Rails.root.join(IMPORT_DIR, @name), "r") do |file|
              contents = RiCal.parse(file)
            end
            calendar = contents.first
            entries, message = CalendarEntryICS.array_from_data(calendar)
          else
            entries = nil
            message = 'Currently we can process only CSV or ICS files.'
          end
          if entries
            weekletterentries = []
            locator = Locator.new
            entries.select { |entry|
                             entry.ends_at >= start_date &&
                             entry.starts_at < end_date
                           }.each do |entry|
              if entry.week_letter
                #
                #  We save these up and process them at the end.
                #
                weekletterentries << entry
              elsif entry.description =~ /^Duty Masters/ ||
                    entry.description =~ /^Detention.*aster/i ||
                    entry.description =~ /^Detention.*uty/i
                relevant_staff = find_relevant_staff(entry.description,
                                                     known_staff)
                unless add_event(entry.starts_at,
                                 entry.ends_at,
                                 entry.all_day,
                                 entry.description,
                                 dutycategory,
                                 eventsource,
                                 relevant_staff)
                  @failures << "Event #{entry.description} was invalid."
                end
              else
                description, locations =
                  locator.check_for_locations(entry.description)
                unless add_event(entry.starts_at,
                                 entry.ends_at,
                                 entry.all_day,
                                 description,
                                 maincategory,
                                 eventsource,
                                 locations + [property])
                  @failures << "Event #{entry.description} was invalid."
                end
              end
            end
            if weekletterentries.size > 0
              currentweekletter = nil
              currentweekstart  = nil
              currentweekend    = nil
              weekletterentries.sort.each do |wle|
#                Rails.logger.debug "WL: Processing WEEK #{
#                                    wle.week_letter
#                                  } from #{
#                                    wle.starts_at.to_formatted_s(:dmy)
#                                  } to #{
#                                    wle.ends_at.to_formatted_s(:dmy)
#                                  }"
                if wle.week_letter == currentweekletter
#                  Rails.logger.debug("WL: Continuation")
                  #
                  #  The week continues
                  #
                  currentweekend = wle.ends_at
                else
#                  Rails.logger.debug("WL: Change of week letter")
                  if currentweekletter
                    #
                    #  Need to flush this one to the d/b.
                    #
#                    Rails.logger.debug "WL: Trying to save #{
#                            currentweekstart.to_formatted_s(:dmy)
#                          } to #{
#                            currentweekend.to_formatted_s(:dmy)
#                          }"
                    unless add_event(currentweekstart,
                                     currentweekend,
                                     true,
                                     "WEEK #{currentweekletter}",
                                     weeklettercategory,
                                     eventsource)
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
#                Rails.logger.debug("WL: Flushing final one")
                unless add_event(currentweekstart,
                                 currentweekend,
                                 true,
                                 "WEEK #{currentweekletter}",
                                 weeklettercategory,
                                 eventsource)
                  @failures << "Event #{entry.description} was invalid."
                end
              end
            
            end
          else
            redirect_to imports_index_path, message
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
