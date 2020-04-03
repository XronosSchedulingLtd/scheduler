#
# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2019 John Winters
# See COPYING and LICENCE in the root directory of the application
# for more information.

class Comment < ApplicationRecord
  belongs_to :parent, polymorphic: true
  belongs_to :user

  validates :body, presence: true
end
