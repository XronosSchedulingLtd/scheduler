class Event < ActiveRecord::Base

  belongs_to :eventcategory
  belongs_to :eventsource

  def starts_at_text
    starts_at ? starts_at.strftime("%d/%m/%Y %H:%M") : ""
  end

  def ends_at_text
    ends_at ? ends_at.strftime("%d/%m/%Y %H:%M") : ""
  end
end
