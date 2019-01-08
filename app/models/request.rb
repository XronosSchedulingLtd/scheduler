class Request < ActiveRecord::Base

  class Candidate
    attr_reader :element_id,
                :name,
                :has_suspended,
                :today_count,
                :this_week_count

    def initialize(element_id, name, today_count = 0, this_week_count = 0)
      @element_id      = element_id
      @name            = name
      @has_suspended   = false
      @today_count     = today_count
      @this_week_count = this_week_count
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
  has_one :user_form_response, as: :parent, dependent: :destroy

  validates :element, :presence => true
  validates :event,   :presence => true

  #
  #  Note that this expects an *exclusive* end date.  Trying to move
  #  to this method of working everywhere.  Sadly it's not how groups
  #  are implemented.
  #
  scope :during, lambda {|start_date, end_date|
    joins(:event).merge(Event.during(start_date, end_date))
  }
  scope :standalone, -> { where(proto_request_id: nil) }
  scope :prototyped, -> { where.not(proto_request_id: nil) }

  #
  #  Normally this won't be defined and so calls to this method will
  #  return nil.
  #
  attr_reader :updated_nominee

  #
  #  Call-backs.
  #
  after_save    :update_corresponding_event
  after_destroy :update_corresponding_event
  after_create  :check_for_forms

  def element_name
    self.element.name
  end

  #
  #  Dummy method to allow mass assignment.
  #
  def element_name=(name)
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
    #
    #  We pass in our own event as an exception, because we don't want
    #  it to count as making people busy.  We will handle those involved
    #  in this event separately later.
    #
    ff.do_find(self.event)
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
    do_save = false
    current_colour = self.colour
    new_commitment = self.commitments.create({
      event:   self.event,
      element: element})
    if new_commitment.valid?
      num_commitments = self.commitments.count
      if num_commitments > self.quantity
        self.quantity = num_commitments
        do_save = true
      end
      if self.colour != current_colour
        do_save = true
      end
      if do_save
        self.save
      end
    end
    new_commitment
  end

  def unfulfill(element_id)
    current_colour = self.colour
    current_commitment =
      self.commitments.detect {|c| c.element_id == element_id}
    if current_commitment
      element = current_commitment.element
      current_commitment.destroy
      self.reload
      if self.colour != current_colour
        self.save
      end
      #
      #  And now re-calculate this element's loading.
      #
      this_day = self.event.starts_at.to_date
      invigilation_commitments_today = 
        Commitment.commitments_on(
          startdate:     this_day,
          eventcategory: "Invigilation",
          resource:      element).count
      sunday = this_day - this_day.wday
      saturday = sunday + 6.days
      invigilation_commitments_this_week = 
        Commitment.commitments_on(
          startdate:     sunday,
          enddate:       saturday,
          eventcategory: "Invigilation",
          resource:      element).count
      @updated_nominee =
        Candidate.new(
          element.id,
          element.name, 
          invigilation_commitments_today,
          invigilation_commitments_this_week)
    end
  end

  def colour
    if self.commitments.count >= self.quantity
      "g"
    elsif self.commitments.count > 0
      "y"
    else
      "r"
    end
  end

  def pending?
    num_outstanding > 0
  end

  #
  #  How many outstanding requests do we have?
  #
  #  quantity - number of linked commitments
  #
  #  Guard against returning a negative value if we are currently
  #  over-committed.  This can happen if a user reduces the
  #  requirement after resources have been committed.
  #
  def num_outstanding
    value = self.quantity - self.commitments.count
    if value < 0
      value = 0
    end
    value
  end

  def clone_and_save(modifiers)
    new_self = self.dup
    modifiers.each do |key, value|
      new_self.send("#{key}=", value)
    end
    #
    #  Give the calling code the chance to make further adjustments.
    #
    if block_given?
      yield new_self
    end
    new_self.note_progenitor(self)
    new_self.save!
    new_self
  end

  def note_progenitor(progenitor)
    @progenitor = progenitor
  end

  def form_status
    if self.user_form_response
      #
      #  Currently cope with only one.
      #
      ufr = self.user_form_response
      if self.commitments.empty?
        if ufr.complete?
          "Complete"
        elsif ufr.partial?
          "Partial"
        else
          "To fill in"
        end
      else
        "Locked"
      end
    else
      "None"
    end
  end

  def corresponding_form
    self.user_form_response
  end

  def incomplete_ufr_count
    if self.user_form_response && !self.user_form_response.complete?
      1
    else
      0
    end
  end

  #
  #  Some methods just to make requests behave quite like commitments for
  #  display purposes.
  #
  def covered; false end
  def rejected?; false end
  def requested?; false end
  def noted?; false end
  def constraining?; false end
  def covering; false end

  def name_with_quantity
    "#{ActionController::Base.helpers.pluralize(self.quantity, self.element.name)}"
  end

  private

  def update_corresponding_event
    if self.event
      self.event.update_flag_colour
    end
  end

  def check_for_forms
    if self.event.owner && self.event.owner != 0
      if self.element.user_form
        user_form_response_params = {
          user_form: self.element.user_form,
          user:      self.event.owner
        }
        if @progenitor && donor = @progenitor.user_form_response
          #
          #  It is just possible (although extremeley unlikely) that
          #  the configured form for the requested element has changed between
          #  when the original event was created (and its form filled in)
          #  and now.  We don't want to go copying the user form response
          #  data from one form to a response for a different one.
          #
          #  Just check.
          #
          if donor.user_form_id == self.element.user_form_id
            user_form_response_params[:form_data] = donor.form_data
            user_form_response_params[:status]    = donor.status
          end
        end
        self.create_user_form_response(user_form_response_params)
      end
    end
  end

end
