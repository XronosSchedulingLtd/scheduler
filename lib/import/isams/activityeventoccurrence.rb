#
#  Class for ISAMS Activity Manager Event Occurrence records.
#
#  Copyright (C) 2016 John Winters
#

class ISAMS_ActivityEventOccurrence
  FILE_NAME = "TblActivityManagerEventOccurrence.csv"
  REQUIRED_COLUMNS = [
    Column["TblActivityManagerEventOccurrenceId", :ident,     :integer],
    Column["intEventId",                          :event_id,  :integer],
    Column["dteOccurrenceDate",                   :datetime,  :time],
    Column["blnCancelled",                        :cancelled, :boolean]
  ]

  DEPENDENCIES = [
    #          Accumulator key  Record ident   Our attribute  Required
    Dependency[:events,         :event_id,     :event,        true]
  ]

  include Slurper
  include Depender

  def adjust(accumulator)
    if @datetime && @datetime < accumulator.loader.start_date
      @complete = false
    else
      @complete = find_dependencies(accumulator, DEPENDENCIES)
      if @complete
        if self.start_time != @event.start_time
          puts "Other half oddity - start times are not the same."
          puts "Event #{@event.subject}"
          puts "Event has #{@event.start_date}"
          puts "Event occurenct has #{@datetime}"
        end
      end
    end
  end

  def wanted?
    @complete
  end

  def start_time
    @datetime.strftime("%H:%M")
  end

  #
  #  Set ourselves up and add ourselves to the accumulator.
  #
  def self.construct(accumulator, import_dir)
    records, message = self.slurp(accumulator, import_dir, false)
    if records
      accumulator[:eventoccurrences] = records.collect {|r| [r.ident, r]}.to_h
      true
    else
      puts message
      false
    end
  end
end
