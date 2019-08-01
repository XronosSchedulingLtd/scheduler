#
# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2019 John Winters
# See COPYING and LICENCE in the root directory of the application
# for more information.


class XMLCustomCategory
  FILE_NAME = 'TblUsefulLists.csv'
  REQUIRED_COLUMNS = [
    Column['TblUsefulListsID', :id,        :integer],
    Column['ListType',         :list_type, :string],
    Column['Name',             :name,      :string]
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
    self.list_type == 'SelectionCategory'
  end

  def generate_entry(xml)
    xml.Category(Id: self.id) do
      xml.Name self.name
    end
  end

  def self.construct(accumulator, import_dir)
    records, message = self.slurp(accumulator, import_dir, false)
    if records
      @@custom_categories = records
      true
    else
      puts message
      false
    end
  end

  def self.generate_xml(xml)
    @@custom_categories.each do |cc|
      cc.generate_entry(xml)
    end
  end

end
