#
# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2020 John Winters
# See COPYING and LICENCE in the root directory of the application
# for more information.
#

#
#  Support code to allow utilities to manipulate UserFiles.
#

class UserFiling < Tempfile

  #
  #  Note that we have no particular requirements for the file name
  #  except that it is not blank.  We don't use it to store the file.
  #  We simply store it as a string for later reference.
  #
  def initialize(user, file_name, encoding="utf-8")
    unless user.can_has_files?
      raise ArgumentError.new("User #{user.name} cannot have files.")
    end
    if file_name.blank?
      raise NameError.new("File name cannot be blank.")
    end
    @user = user
    @file_name = file_name
    @encoding = encoding
    super("scheduler", encoding: encoding)
  end

  def original_filename
    @file_name
  end

  def close
    self.rewind
    #
    #  Now, if this is a re-run, we simply want to replace the contents
    #  of the existing user file - not create a new one.
    #
    existing = @user.user_files.find_by({
      original_file_name: @file_name,
      system_created: true
    })
    if existing
      existing.encoding = @encoding
      existing.replace_contents(self)
    else
      @user.user_files.create({
        file_info: self,
        system_created: true,
        encoding: @encoding
      })
    end
    super
    self.unlink
  end

end
