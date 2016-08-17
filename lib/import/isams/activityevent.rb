#
#  Class for ISAMS Activity Manager Event records.
#
#  Copyright (C) 2016 John Winters
#

class ISAMS_ActivityEvent
  FILE_NAME = "TblActivityManagerEvent.csv"
  REQUIRED_COLUMNS = [
    Column["TblActivityManagerEventId",    :ident,       :integer],
    Column["txtSubject",                   :subject,     :string],
    Column["txtLocation",                  :location,    :string],
    Column["dteStartDate",                 :start_date,  :time],
    Column["dteEndDate",                   :end_date,    :time],
    Column["blnAllDayEvent",               :all_day,     :boolean],
    Column["intGroup",                     :group_id,    :integer],
    Column["intActivity",                  :activity_id, :integer]
  ]

  DEPENDENCIES = [
    #          Accumulator key  Record ident   Our attribute  Required
    Dependency[:groups,         :group_id,     :group,        false]
  ]

  include Slurper
  include Depender

  attr_accessor :timeslot

  attr_reader :teacher_ids

  def adjust(accumulator)
    #
    #  Can't drop events just because their end_date is in the past.
    #  iSAMS stores the wrong value there.  The end_date is generally
    #  the same as the start date, and the real end date is actually
    #  stored in the repeat information field.  I can't be bothered
    #  to parse it out of there for now, and as we we don't copy the
    #  events into our d/b, it shouldn't be a problem.
    #
#    if @end_date && @end_date < accumulator.loader.start_date
#      @complete = false
#    else
      @complete = find_dependencies(accumulator, DEPENDENCIES, false)
      if @complete
        @teacher_ids = Array.new
        @timeslot = nil
      end
#    end
  end

  def wanted?
    @complete
  end

  def note_teacher(teacher_link)
    @teacher_ids << teacher_link.teacher_id
#    puts "Event #{@subject} (#{@ident}) has #{@teacher_ids.size} teachers."
  end

  def start_time
    @start_date.strftime("%H:%M")
  end

  def end_time
    @end_date.strftime("%H:%M")
  end

  #
  #  Set ourselves up and add ourselves to the accumulator.
  #
  def self.construct(accumulator, import_dir)
    records, message = self.slurp(accumulator, import_dir, false)
    if records
      accumulator[:events] = records.collect {|r| [r.ident, r]}.to_h
      true
    else
      puts message
      false
    end
  end
end