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

class XMLDepartmentSubjectLink
  FILE_NAME = 'TblTeachingManagerSubjectDepartmentsSubjectLinks.csv'
  REQUIRED_COLUMNS = [
    Column['TblTeachingManagerSubjectDepartmentsSubjectLinksID',
                                            :id,            :integer],
    Column['intDepartment',                 :department_id, :integer],
    Column['intSubject',                    :subject_id,    :integer]
  ]
  include Slurper

  #
  #  We get a chance to adjust our events before they are added to
  #  the array which is returned.
  #
  def adjust(accumulator)
  end

  #
  #  And we can stop them from being put in the array if we like.
  #
  def wanted?
    true
  end

  def link_up(departments_by_id, subjects_by_id)
    department = departments_by_id[self.department_id]
    subject    = subjects_by_id[self.subject_id]
    if subject && department
      department.note_subject(subject)
    end
  end

  def self.construct(accumulator, import_dir)
    records, message = self.slurp(accumulator, import_dir, false)
    if records
      #
      #  We don't actually keep our records - just use them to
      #  link subjects to departments.
      #
      departments_by_id = accumulator[:departments_by_id]
      subjects_by_id    = accumulator[:subjects_by_id]
      records.each do |record|
        record.link_up(departments_by_id, subjects_by_id)
      end
      true
    else
      puts message
      false
    end
  end

end
