#
#  Class for ISAMS Activity Manager Event Teacher Link records.
#
#  Copyright (C) 2016 John Winters
#

class ISAMS_ActivityEventTeacherLink
  FILE_NAME = "TblActivityManagerEventTeacherLink.csv"
  REQUIRED_COLUMNS = [
    Column["TblEventTeacherLinkId",        :ident,       :integer],
    Column["intEventId",                   :event_id,    :integer],
    Column["txtTeacherId",                 :teacher_id,  :string]
  ]

  DEPENDENCIES = [
    #          Accumulator key  Record ident   Our attribute  Required
    Dependency[:events,         :event_id,     :event,        true]
  ]

  include Slurper
  include Depender

  def adjust(accumulator)
    @complete = find_dependencies(accumulator, DEPENDENCIES)
    if @complete
      @event.note_teacher(self)
    end
  end

  def wanted?
    @complete
  end

  #
  #  Set ourselves up and add ourselves to the accumulator.
  #
  def self.construct(accumulator, import_dir)
    records, message = self.slurp(accumulator, import_dir, false)
    if records
      accumulator[:eventteacherlinks] = records.collect {|r| [r.ident, r]}.to_h
      true
    else
      puts message
      false
    end
  end
end
