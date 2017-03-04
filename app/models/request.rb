class Request < ActiveRecord::Base
  belongs_to :element
  belongs_to :event
  belongs_to :proto_request

  has_many :commitments, :dependent => :destroy

  validates :element, :presence => true
  validates :event,   :presence => true

  def element_name
    self.element.name
  end

  def max_quantity
    8
  end

  def candidates
    #
    #  The freefinder as currently implemented won't deal with periods
    #  spanning more than one day.  It wants a date, and two times.
    #
    #  Re-work needed if we start doing requests for multi-day events.
    #
    #  We are also currently making an implicit assumption that
    #  our element is a group.  The whole processing of requests
    #  makes sense only for groups.
    #
    ff = Freefinder.new({
      element:    self.element,
      on:         self.event.starts_at.to_date,
      start_time: self.event.starts_at,
      end_time:   self.event.ends_at
    })
    ff.do_find
    if ff.done_search
      ff.free_elements.collect {|fe| fe.name}
    else
      ["Able", "Baker", "Charlie"]
    end
  end

end
