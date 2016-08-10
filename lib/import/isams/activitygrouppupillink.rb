#
#  Class for ISAMS Activity Manager Group Pupil Link records.
#
#  Copyright (C) 2016 John Winters
#

class ISAMS_ActivityGroupPupilLink
  FILE_NAME = "TblActivityManagerGroupPupilLink.csv"
  REQUIRED_COLUMNS = [
    Column["TblActivityManagerGroupPupilLinkId",
                                           :ident,       :integer],
    Column["txtSchoolID",                  :pupil_id,    :string],
    Column["intGroup",                     :group_id,    :integer],
    Column["dteStartDate",                 :start_date,  :date],
    Column["dteEndDate",                   :end_date,    :date]
  ]

  #
  #  This record links in two different ways.  We resolve the connection
  #  to groups here, but the connection to pupils needs to wait until
  #  we are dealing also with the XML data and the database.
  #
  DEPENDENCIES = [
    #          Accumulator key  Record ident   Our attribute  Required
    Dependency[:groups,         :group_id,     :group,        true]
  ]
  include Slurper
  include Depender

  attr_accessor :timeslot

  attr_reader :teacher_ids

  def adjust(accumulator)
    @complete = find_dependencies(accumulator, DEPENDENCIES)
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
      accumulator[:grouppupillinks] = records.collect {|r| [r.ident, r]}.to_h
      true
    else
      puts message
      false
    end
  end
end
