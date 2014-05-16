class Event < ActiveRecord::Base

  belongs_to :eventcategory
  belongs_to :eventsource

  validates :body, presence: true
  validates :eventcategory_id, presence: true
  validates :eventsource_id, presence: true

  #
  #  These may look slightly surprising.  We use them to specify
  #  events FROM date UNTIL date, and it seems at first sight that
  #  we're using the wrong date fields.  Think about it the other
  #  way around though - we *don't* want events that end before our
  #  start date, or start after our end date.  All others we want.
  #
  scope :beginning, lambda {|date| where("ends_at >= ?", date) }
  scope :until, lambda {|date| where("starts_at < ?", date) }
  scope :source_id, lambda {|id| where("eventsource_id == ?", id) }
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
      :end       => starts_at == ends_at ? nil : ends_at.rfc822,
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
