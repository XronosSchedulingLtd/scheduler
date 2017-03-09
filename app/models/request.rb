class Request < ActiveRecord::Base

  class Candidate
    attr_reader :element_id,
                :name,
                :has_suspended,
                :today_count,
                :this_week_count

    def initialize(element_id, name)
      @element_id      = element_id
      @name            = name
      @has_suspended   = false
      @today_count     = 0
      @this_week_count = 0
    end

    def suspended
      @has_suspended = true
    end

    def one_today
      @today_count += 1
    end

    def one_this_week
      @this_week_count += 1
    end

  end

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
      candidate_hash = Hash.new
      ff.free_elements.each do |fe|
        candidate_hash[fe.id] = Candidate.new(fe.id, fe.name)
      end
      #
      #  Now, need to find all cases where someone has a suspended lesson.
      #  Work by finding all commitments to suspended lessons, then checking
      #  them against our elements.  Note that this will pick up only
      #  *direct* commitments (not via a group) but that's all we need.
      #
      suspended_commitments =
        Commitment.commitments_during(
          start_time:        self.event.starts_at,
          end_time:          self.event.ends_at,
          eventcategory:     "Lesson",
          only_nonexistent:  true)
      suspended_commitments.each do |sc|
        if candidate_hash[sc.element_id]
          candidate_hash[sc.element_id].suspended
        end
      end
      #
      #  How many invigilation slots does each of our candidates
      #  have already:
      #
      #  * Today
      #  * This week
      #
      this_day = self.event.starts_at.to_date
      invigilation_commitments_today = 
        Commitment.commitments_on(
          startdate: this_day,
          eventcategory: "Invigilation")
      invigilation_commitments_today.each do |ict|
        if candidate_hash[ict.element_id]
          candidate_hash[ict.element_id].one_today
        end
      end
      sunday = this_day - this_day.wday
      saturday = sunday + 6.days
      invigilation_commitments_this_week = 
        Commitment.commitments_on(
          startdate: sunday,
          enddate: saturday,
          eventcategory: "Invigilation")
      invigilation_commitments_this_week.each do |ictw|
        if candidate_hash[ictw.element_id]
          candidate_hash[ictw.element_id].one_this_week
        end
      end
      #
      #  And return our results.
      #
      candidate_hash.values
    else
      ["Able", "Baker", "Charlie"]
    end
  end

  def nominees
    self.commitments.collect{|c| Candidate.new(c.element_id, c.element.name)}
  end

  #
  #  Takes an element and makes it at least partly fulfill this request.
  #  Returns the new commitment record, which may be flagged with errors.
  #
  def fulfill(element)
    self.commitments.create({
      event:   self.event,
      element: element})
  end
end
