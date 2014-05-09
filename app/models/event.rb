class Event < ActiveRecord::Base

  belongs_to :eventcategory
  belongs_to :eventsource

end
