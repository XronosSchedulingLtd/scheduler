# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2019 John Winters
# See COPYING and LICENCE in the root directory of the application
# for more information.
#

class Attachment < ActiveRecord::Base
  belongs_to :parent, polymorphic: true
  belongs_to :user_file

  validates :parent, presence: true
  validates :user_file, presence: true
end
