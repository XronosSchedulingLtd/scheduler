class Eventsource < ActiveRecord::Base

   validates :name, presence: true
   validates :name, uniqueness: true

   has_many :events, dependent: :destroy

   def <=>(other)
     self.name <=> other.name
   end
end
