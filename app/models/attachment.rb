#
# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2019 John Winters
# See COPYING and LICENCE in the root directory of the application
# for more information.
#

class Attachment < ApplicationRecord
  belongs_to :parent, polymorphic: true
  belongs_to :user_file

  #
  #  Note that the Note class has dependent: :delete_all on its connection
  #  to attachments.  This is specifically so the following callback won't
  #  fire.
  #
  #  If you add any more callbacks to this model, you might need to take
  #  that into account.
  #
  before_destroy :adjust_note_contents

  def name
    if user_file
      user_file.original_file_name
    else
      "<None>"
    end
  end

  def shortened_name
    candidate = name
    if candidate.size > 18
      candidate = candidate[0, 15] + '...'
    end
    candidate
  end

  private

  #
  #  If we're being destroyed, then we'd prefer not to leave behind any
  #  broken links.
  #
  def adjust_note_contents
    if user_file && parent && parent.respond_to?(:userfile_going)
      parent.userfile_going(self.user_file.nanoid)
    end
    #
    #  Must return true or we cancel our destruction.
    #
    return true
  end

end
