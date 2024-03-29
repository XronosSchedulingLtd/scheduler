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

class XMLUser
  FILE_NAME = 'TbliSAMSManagerUsers.csv'
  REQUIRED_COLUMNS = [
    Column['TbliSAMSManagerUsersID', :id,        :integer],
    Column['txtUserCode',            :user_code, :string]
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

  def self.construct(accumulator, import_dir)
    records, message = self.slurp(accumulator, import_dir, false)
    if records
      accumulator[:users_by_code] = records.collect {|r| [r.user_code, r]}.to_h
      true
    else
      puts message
      false
    end
  end

end
