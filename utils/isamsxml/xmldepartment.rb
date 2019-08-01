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

class XMLDepartment
  FILE_NAME = 'TblTeachingManagerSubjectDepartments.csv'
  REQUIRED_COLUMNS = [
    Column['TblTeachingManagerSubjectDepartmentsID', :id,   :integer],
    Column['txtDepartmentName',                      :name, :string]
  ]
  include Slurper

  #
  #  We get a chance to adjust our events before they are added to
  #  the array which is returned.
  #
  def adjust(accumulator)
    @subjects = []
  end

  #
  #  And we can stop them from being put in the array if we like.
  #
  def wanted?
    true
  end

  def note_subject(subject)
    @subjects << subject
  end

  def generate_entry(xml)
    xml.Department(Id: self.id) do
      xml.Name self.name
      unless @subjects.empty?
        xml.Subjects do
          @subjects.each do |subject|
            subject.generate_entry(xml)
          end
        end
      end
    end
  end

  def self.construct(accumulator, import_dir)
    records, message = self.slurp(accumulator, import_dir, false)
    if records
      accumulator[:departments_by_id] =
        records.collect {|r| [r.id, r]}.to_h
      @@departments = records
      true
    else
      puts message
      false
    end
  end

  def self.generate_xml(xml)
    @@departments.each do |department|
      department.generate_entry(xml)
    end
  end

end
