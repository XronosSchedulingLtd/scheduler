# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2014 John Winters
# See COPYING and LICENCE in the root directory of the application
# for more information.

class Interest < ActiveRecord::Base
  belongs_to :user
  belongs_to :element

  validates :user,    :presence => true
  validates :element, :presence => true

  #
  #  This isn't a real field in the d/b.  It exists to allow a name
  #  to be typed in the dialogue for creating an interest record.
  #
  def name
    @name 
  end

  def name=(n)
    @name = n
  end

end
