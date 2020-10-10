#
# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2020 John Winters
# See COPYING and LICENCE in the root directory of the application
# for more information.
#

#
#  Support code to allow utilities to manipulate UserFiles.
#

class UserFiling

  #
  #  Note that we have no particular requirements for the file name
  #  except that it is not blank.  We don't use it to store the file.
  #  We simply store it as a string for later reference.
  #
  def initialize(user, file_name)
    unless user.can_has_files?
      raise ArgumentError.new("User #{user.name} cannot have files.")
    end
    if file_name.blank?
      raise NameError.new("File name cannot be blank.")
    end
    @user = user
    @file_name = file_name
    @temp_file = Tempfile.new("scheduler")
  end

  def puts(line)
    @temp_file.puts(line)
  end

  def print(line)
    @temp_file.print(line)
  end

  def read
    @temp_file.read
  end

  def size
    @temp_file.size
  end

  def original_filename
    @file_name
  end

  def close
    @temp_file.rewind
    @user.user_files.create({file_info: self})
    @temp_file.close
    @temp_file.unlink
  end

end
