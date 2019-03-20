# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2016 John Winters
# See COPYING and LICENCE in the root directory of the application
# for more information.
#
class Promptnote < ApplicationRecord
  belongs_to :element
  has_many   :notes, :dependent => :nullify

  validates :element, presence: true

end
