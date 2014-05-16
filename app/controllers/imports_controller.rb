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
  REQUIRED_COLUMNS = [["Subject",       :subject],
                      ["Start Date",    :start_date],
                      ["Start Time",    :start_time],
                      ["End Date",      :end_date],
                      ["End Time",      :end_time],
                      ["All day event", :all_day]]

  def initialize(description, start_date, start_time, end_date, end_time, all_day)
    @description = description
    @all_day = (all_day == "True")
    if @all_day
      @starts_at = DateTime.parse("#{start_date}")
      @ends_at   = DateTime.parse("#{end_date.empty? ?
                                     start_date :
                                     end_date}")
    else
      @starts_at = DateTime.parse("#{start_date} #{start_time}")
      @ends_at   = DateTime.parse("#{end_date.empty? ?
                                     start_date :
                                     end_date} #{end_time}")
    end
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
    eventcategory = Eventcategory.find_by_name("Calendar")
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
          entries.each do |entry|
            event = Event.new
            event.starts_at = entry.starts_at
            event.ends_at   = entry.ends_at
            event.body      = entry.description
            event.eventcategory = eventcategory
            event.eventsource   = eventsource
            event.save!
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
end
