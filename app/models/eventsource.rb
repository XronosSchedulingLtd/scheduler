# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2014 John Winters
# See COPYING and LICENCE in the root directory of the application
# for more information.

class Eventsource < ActiveRecord::Base

   validates :name, presence: true
   validates :name, uniqueness: true

   has_many :events, dependent: :destroy

   def <=>(other)
     self.name <=> other.name
   end

   def can_destroy?
     self.events.count == 0
   end

end
