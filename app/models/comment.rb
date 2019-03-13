# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2019 John Winters
# See COPYING and LICENCE in the root directory of the application
# for more information.

class Comment < ActiveRecord::Base
  belongs_to :parent, polymorphic: true
  belongs_to :user

  validates :user,   presence: true
  validates :body,   presence: true
  #
  #  In an ideal world, this next one would validate "parent" rather
  #  than "parent_id", but I seem to be tickling a weird bug in the
  #  Rails test environment.  If I set this test to "parent" then all
  #  my tests on comments fail saying, "parent can't be blank", even
  #  though it isn't blank - the linked record exists in the database.
  #
  #  The same problem does not occur in the development environment.
  #  Weird or what?
  #
  validates :parent_id, presence: true
end
