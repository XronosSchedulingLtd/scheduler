class Event < ActiveRecord::Base

  belongs_to :eventcategory
  belongs_to :eventsource

  validates :body, presence: true
  validates :eventcategory_id, presence: true
  validates :eventsource_id, presence: true

  def starts_at_text
    starts_at ? starts_at.strftime("%d/%m/%Y %H:%M") : ""
  end

  def ends_at_text
    ends_at ? ends_at.strftime("%d/%m/%Y %H:%M") : ""
  end

  def as_json(options = {})
    {
      :id        => "Event #{id}",
      :title     => body,
      :start     => starts_at.rfc822,
      :end       => ends_at.rfc822,
      :allDay    => all_day,
      :recurring => false,
      :editable  => false
    }
  end

  def all_day
    starts_at.hour == 0 &&
    starts_at.min == 0 &&
    ends_at.hour == 0 &&
    ends_at.min == 0
  end
end
