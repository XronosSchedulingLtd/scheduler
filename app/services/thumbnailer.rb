#
# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2019 John Winters
# See COPYING and LICENCE in the root directory of the application
# for more information.

require 'rmagick'

class Thumbnailer
  include Magick

  def self.create(inputname, outputname)
    begin
      org = ImageList.new(inputname)
      thumbnail = org.thumbnail(48, 48)
      thumbnail.write(outputname)
      return true
    rescue
      #
      #  Fairly dumb error handling.  If anything fails then we tell
      #  the calling code that we did not succeed.
      #
      return false
    end
  end
end

