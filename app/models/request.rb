#
# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2020 John Winters
# See COPYING and LICENCE in the root directory of the application
# for more information.
#

class Request < ApplicationRecord

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
  belongs_to :proto_request, optional: true

  has_many :commitments, :dependent => :destroy
  has_one :user_form_response, as: :parent, dependent: :destroy

  validates :element_id, uniqueness: { scope: :event_id }

  include WithForms

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
  scope :future, -> { joins(:event).merge(Event.beginning(Date.today))}
  scope :until, lambda { |datetime| joins(:event).merge(Event.until(datetime)) }

  #
  #  Tentative means we haven't yet been allocated all our resources.
  #
  scope :tentative, -> { where(tentative: true) }
  scope :firm, -> { where(tentative: false) }

  scope :constraining, -> { where(constraining: true) }

  scope :reconfirmed, -> { where(reconfirmed: true) }
  scope :awaiting_reconfirmation, -> { where(reconfirmed: false) }

  scope :with_incomplete_form, -> { joins(:user_form_response).merge(UserFormResponse.incomplete) }

  scope :none_allocated, -> { includes(:commitments).where(commitments: {request_id: nil}) }

  scope :owned_by, lambda {|user|
    joins(:event).merge(Event.owned_by(user))
  }

  scope :owned_or_organised_by, lambda {|user|
    joins(:event).merge(Event.owned_or_organised_by(user))
  }
  #
  #  Normally this won't be defined and so calls to this method will
  #  return nil.
  #
  attr_reader :updated_nominee

  #
  #  When asked to do a change to our quantity, we keep track of the
  #  previous quantity.  Note, this does not get saved to the database.
  #  It is valid only whilst in memory and only after getting back
  #  true from one of the quantity adjustment methods.
  #
  attr_reader :previous_quantity

  #
  #  Call-backs.
  #
  after_save    :update_corresponding_event
  after_destroy :update_corresponding_event
  after_create  :check_for_forms

  self.per_page = 12

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
  #  It's tempting at this point to attempt to trigger a database write
  #  in order for our after_save method then to update the event.
  #
  #  However, the fact that we're creating a commitment will do the
  #  necessary.
  #
  def fulfill(element)
    do_save = false
    #
    #  If our calculated colour changes then we need to force
    #  a save of ourselves in order to cause the corresponding event
    #  to be updated.  It caches a copy of the flag colour.
    #
    current_colour   = self.colour
    new_commitment = self.commitments.create({
      event:   self.event,
      element: element})
    if new_commitment.valid?
      num_commitments = self.commitments.size
      if num_commitments > self.quantity
        self.quantity = num_commitments
        do_save = true
      end
      if self.colour != current_colour
        do_save = true
      end
      set_status_flags(do_save)
    end
    new_commitment
  end

  def unfulfill(element_id)
    current_commitment =
      self.commitments.detect {|c| c.element_id == element_id}
    if current_commitment
      current_colour   = self.colour
      element = current_commitment.element
      current_commitment.destroy
      self.reload
      set_status_flags(self.colour != current_colour)
      if self.proto_request
        #
        #  This is an invigilation case, so re-calculate the element's
        #  loading.
        #
        this_day = self.event.starts_at.to_date
        invigilation_commitments_today = 
          Commitment.commitments_on(
            startdate:     this_day,
            eventcategory: "Invigilation",
            resource:      element).size
        sunday = this_day - this_day.wday
        saturday = sunday + 6.days
        invigilation_commitments_this_week = 
          Commitment.commitments_on(
            startdate:     sunday,
            enddate:       saturday,
            eventcategory: "Invigilation",
            resource:      element).size
        @updated_nominee =
          Candidate.new(
            element.id,
            element.name, 
            invigilation_commitments_today,
            invigilation_commitments_this_week)
      end
    end
  end

  def increment_and_save
    if self.quantity < max_quantity
      @previous_quantity = self.quantity
      self.quantity += 1
      set_status_flags(true)
      true
    else
      false
    end
  end

  def decrement_and_save
    if self.quantity > 1
      @previous_quantity = self.quantity
      self.quantity -= 1
      set_status_flags(true)
      true
    else
      false
    end
  end

  def set_quantity_and_save(new_quantity)
    if new_quantity > 0 &&
        new_quantity <= max_quantity &&
        new_quantity != self.quantity
      @previous_quantity = self.quantity
      self.quantity = new_quantity
      set_status_flags(true)
      true
    else
      false
    end
  end

  def colour
    if self.commitments.size >= self.quantity
      "g"
    elsif self.commitments.size > 0
      "y"
    else
      "r"
    end
  end

  def pending?
    num_outstanding > 0
  end

  def reconfirmable?
    if self.event &&
       self.element &&
       self.element.entity &&
       self.element.entity.respond_to?(:confirmation_days)
      confirmation_days = self.element.entity.confirmation_days
      if confirmation_days > 0
        start_date = Date.today
        end_date = start_date + confirmation_days
        self.event.exists_during?(start_date, end_date)
      else
        false
      end
    else
      false
    end
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
    unless @num_outstanding
      @num_outstanding = self.quantity - self.num_allocated
      if @num_outstanding < 0
        @num_outstanding = 0
      end
    end
    @num_outstanding
  end

  def num_allocated
    unless @num_allocated
      @num_allocated = self.commitments.size
    end
    @num_allocated
  end

  def clone_and_save(modifiers)
    new_self = self.dup
    #
    #  Each request record contains a cached count of attached commitments.
    #  Since we now have no commitments, we need to zero that count.
    #
    #  ActiveRecord will take over looking after it as and when we
    #  start acquiring our own commitments.
    #
    new_self.commitments_count = 0
    modifiers.each do |key, value|
      new_self.send("#{key}=", value)
    end
    #
    #  Give the calling code the chance to make further adjustments.
    #
    if block_given?
      yield new_self
    end
    new_self.set_status_flags
    new_self.note_progenitor(self)
    new_self.save!
    new_self
  end

  def note_progenitor(progenitor)
    @progenitor = progenitor
  end

  def form_status
    if ufr = self.user_form_response
      #
      #  Currently cope with only one.
      #
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

  def allocated_resource_elements
    self.commitments.collect {|c| c.element}
  end

  def allocation_status
    if self.num_allocated == 0
      #
      #  Is there a form, and if so how is it?
      #
      if ufr = self.user_form_response
        if ufr.complete?
          "form completed - awaiting allocation"
        elsif ufr.partial?
          "form partially completed"
        else
          "form neeeds filling in"
        end
      else
        "awaiting allocation"
      end
    else
      if self.num_outstanding == 0
        #
        #  All is hunky.
        #
        "allocated, #{
          self.allocated_resource_elements.
               collect { |re| re.name }.
               join(",")
         }"
      else
        #
        #  Some, but not all, have been allocated.
        #
        "#{self.num_allocated} allocated, #{
          self.allocated_resource_elements.
               collect { |re| re.name }.
               join(",")
         }"
        
      end
    end
  end

  def allocation_score
    if self.num_allocated == 0
      #
      #  Is there a form, and if so how is it?
      #
      if ufr = self.user_form_response
        if ufr.complete?
          2
        elsif ufr.partial?
          1
        else
          0
        end
      else
        2
      end
    else
      2 + self.num_allocated
    end
  end

  def max_allocation_score
    2 + self.quantity
  end

  #
  #  We count as confirmed if all have been allocated.
  #
  def confirmed?
    self.num_outstanding == 0
  end

  #
  #  Some methods just to make requests behave quite like commitments for
  #  display purposes.
  #
  def covered; false end
  def rejected?; false end
  def requested?; false end
  def noted?; false end
  def covering; false end

  def name_with_quantity
    "#{ActionController::Base.helpers.pluralize(self.quantity, self.element.name)}"
  end

  def set_status_flags(force_save = false)
    do_save = force_save
    if self.num_outstanding > 0
      unless self.tentative?
        self.tentative = true
        do_save = true
      end
    else
      if self.tentative?
        self.tentative = false
        do_save = true
      end
    end
    if self.num_allocated > 0
      unless self.constraining?
        self.constraining = true
        do_save = true
      end
    else
      if self.constraining?
        self.constraining = false
        do_save = true
      end
    end
    if do_save
      self.save!
    end
    return do_save
  end

  def self.set_initial_flags
    num_processed = 0
    num_changed = 0
    #
    #  Note that these flags are meaningful only for user-entered
    #  requests.  We don't bother with them for system-generated
    #  ones.
    #
    Request.standalone.each do |request|
      num_processed += 1
      if request.set_status_flags
        num_changed += 1
      end
    end
    puts "Modified #{num_changed} records out of #{num_processed}"
  end

  def <=>(other)
    if other.instance_of?(Request)
      if self.event
        if other.event
          self.event <=> other.event
        else
          1
        end
      else
        if other.event
          -1
        else
          0
        end
      end
    else
      nil
    end
  end

  def self.count_invalid
    count = 0
    Request.all.each do |request|
      unless request.valid?
        count += 1
      end
    end
    puts "Count = #{count}"
    nil
  end

  def self.set_initial_counts
    Request.all.each do |request|
      Request.reset_counters(request.id, :commitments)
    end
  end

  private

  def update_corresponding_event
    if self.event
      self.event.update_flag_colour
      if self.destroyed?
        self.event.update_from_contributors(false, false)
      else
        self.event.update_from_contributors(self.tentative?, self.constraining?)
      end
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
