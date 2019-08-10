#
# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2019 John Winters
# See COPYING and LICENCE in the root directory of the application
# for more information.


class XMLCustomGroup
  FILE_NAME = 'TblPupilManagementSelections.csv'
  REQUIRED_COLUMNS = [
    Column['TblPupilManagementSelectionsID', :id,             :integer],
    Column['txtName',                        :name,           :string],
    Column['intCategory',                    :category_id,    :integer],
    Column['intShared',                      :shared,         :integer],
    Column['dtExpiryDate',                   :expiry_date,    :date],
    Column['blnExpiryDisable',               :expiry_disable, :boolean],
    Column['txtSubmitBy',                    :author,         :string],
    Column['intDeleted',                     :deleted,        :integer]
  ]
  include Slurper

  #
  #  We get a chance to adjust our events before they are added to
  #  the array which is returned.
  #
  def adjust(accumulator)
    #
    #  We need the ID number of the associated user if possible.
    #
    user = accumulator[:users_by_code][self.author]
    if user
      @user_id = user.id
    else
      @user_id = 0
    end
  end

  #
  #  And we can stop them from being put in the array if we like.
  #
  def wanted?
    true
  end

  def generate_entry(xml)
    xml.CustomPupilGroup(Id: self.id, AuthorID: @user_id) do
      xml.Name          self.name
      xml.CategoryId    self.category_id
      xml.Shared        self.shared
      xml.ExpiryDate    self.expiry_date
      xml.ExpiryDisable self.expiry_disable ? 1 : 0
      xml.Author(self.author, Legacy: 'True') 
      if self.deleted == 1
        xml.Deleted       self.deleted
      end
    end
  end

  def self.construct(accumulator, import_dir)
    records, message = self.slurp(accumulator, import_dir, false)
    if records
      @@custom_groups = records
      true
    else
      puts message
      false
    end
  end

  def self.generate_xml(xml)
    @@custom_groups.each do |cg|
      cg.generate_entry(xml)
    end
  end

end
