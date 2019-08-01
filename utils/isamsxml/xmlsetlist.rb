#
# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2019 John Winters
# See COPYING and LICENCE in the root directory of the application
# for more information.

#
#  This one is slightly unusual because, despite the name, it doesn't
#  actually produce any XML at the moment.  Instead it provides a lookup
#  table for other modules to use.
#

class XMLSetList
  FILE_NAME = 'TblTeachingManagerSetLists.csv'
  REQUIRED_COLUMNS = [
    Column['TblTeachingManagerSetListsID', :id,              :integer],
    Column['intSetID',                     :set_id,          :integer],
    Column['txtSchoolID',                  :pupil_school_id, :string]
  ]
  include Slurper

  #
  #  We get a chance to adjust our events before they are added to
  #  the array which is returned.
  #
  def adjust(accumulator)
    pupil = accumulator[:pupils_by_school_id][self.pupil_school_id]
    if pupil
      @pupil_id = pupil.id
    else
      @pupil_id = nil
    end
  end

  #
  #  And we can stop them from being put in the array if we like.
  #
  def wanted?
    @pupil_id != nil
  end

  def generate_entry(xml)
    xml.SetList(Id: self.id, SetId: self.set_id, PupilId: @pupil_id)
  end

  def self.construct(accumulator, import_dir)
    records, message = self.slurp(accumulator, import_dir, false)
    if records
      @@setlists = records
      true
    else
      puts message
      false
    end
  end

  def self.generate_xml(xml)
    @@setlists.each do |setlist|
      setlist.generate_entry(xml)
    end
  end

end
