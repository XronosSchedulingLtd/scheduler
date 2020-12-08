#
# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2020 John Winters
# See COPYING and LICENCE in the root directory of the application
# for more information.
#

class NotifierValidator < ActiveModel::Validator
  def validate(record)
    if record.start_date && record.end_date
      if record.end_date < record.start_date
        record.errors[:end_date] << "can't be before the start date"
      end
    end
  end
end

class Notifier

  include ActiveModel::Model
  include ActiveModel::Validations

  class ClashEntry
    attr_reader :cover_commitment, :clashing_commitment

    def initialize(cover_commitment, clashing_commitment)
      @cover_commitment    = cover_commitment
      @clashing_commitment = clashing_commitment
    end

    def to_partial_path
      "clash"
    end

    #
    #  We sort by the corresponding cover events.
    #
    def <=>(other)
      if self.cover_commitment.event && other.cover_commitment.event
        self.cover_commitment.event <=> other.cover_commitment.event
      else
        0
      end
    end
  end

  class StaffEntry
    attr_reader :staff, :instances

    def initialize(staff)
      @staff = staff
      @instances = Array.new
    end

    def note_instance(event)
      @instances << event
    end

    def <=>(other)
      self.staff <=> other.staff
    end

    def to_partial_path
      "staff_entry"
    end

    def notify?(which_flag)
      (which_flag == :regardless) ||
      ((which_flag == :weekly) && @staff.invig_weekly_notifications?) ||
      ((which_flag == :daily) && @staff.invig_daily_notifications?)
    end

  end

  attr_accessor :modified_since,
                :extra_text
  attr_reader   :check_clashes,
                :send_notifications,
                :start_date,
                :end_date

  validates :start_date, :presence => true
  validates_with NotifierValidator

  attr_reader :clashes

  def initialize(attributes = {})
    super
    #
    #  Note that the usual ||= trick is not good enough here.
    #
    @check_clashes      = false if @check_clashes.nil?
    @send_notifications = true if @send_notifications.nil?
  end

  def staff_entries
    if @staff_entry_hash
      @staff_entry_hash.values
    else
      []
    end
  end

  def check_clashes=(new_value)
    #
    #  I want this to be a boolean, but I might be passed a string.
    #
    @check_clashes = to_bool(new_value)
  end

  def send_notifications=(new_value)
    @send_notifications = to_bool(new_value)
  end

  #
  #  We are not a real active model, so we need to provide some help
  #  with assignment.  If a real active model date field receives
  #  an empty string it is set to nil.  Our class has no way of knowing
  #  what type @start_date is, so we need to help a bit.
  #
  def start_date=(value)
    @start_date = Date.safe_parse(value)
  end

  def end_date=(value)
    @end_date = Date.safe_parse(value)
  end

  def save
    self.valid?
  end

  def execute
    if self.valid?
      property = Property.find_by(name: "Invigilation")
      @staff_entry_hash = Hash.new
      @clashes = Array.new
      commitments = Commitment.commitments_on(
        startdate: self.start_date,
        enddate: self.end_date ? self.end_date : :never,
        resource:  property
      ).preload(:element)
      commitments.collect {|c| c.event }.sort.each do |event|
        #
        #  Need to iterate through the actual commitments to the event
        #  because we are potentially interested in when it was
        #  last modified.
        #
        #  I was late adding the updated_at field to the commitments
        #  record, so allow for the possibility that it is nil, in
        #  which case it is definitely in the past.
        #
        event.commitments.preload(:element).each do |c|
          if c.element.entity_type == "Staff"
            #
            #  Do we need to send a notification to the staff member?
            #
            if (self.modified_since == nil) ||
               (c.updated_at && c.updated_at >= self.modified_since)
              staff = c.element.entity
              staff_entry = (@staff_entry_hash[staff.id] ||= StaffEntry.new(staff))
              staff_entry.note_instance(event)
            end
            #
            #  Should we check this one for clashes?
            #
            if self.check_clashes
              clashing_commitments =
                c.element.commitments_during(
                  start_time:   event.starts_at,
                  end_time:     event.ends_at,
                  excluded_category: Eventcategory.non_busy_categories,
                  and_by_group: false).preload(:event) - [c]
              if clashing_commitments.size > 0
                clashing_commitments.each do |cc|
                  @clashes << ClashEntry.new(c, cc)
                end
              end
            end
          end
        end
      end
      @executed = true
      true
    else
      false
    end
  end

  def do_send(which_flag, user = nil)
    if @executed
      unless user
        #
        #  If a specific user is specified, then only he goes into
        #  the reply-to field.  Otherwise all exam people get it.
        #
        user = User.exams.to_a
      end
      @staff_entry_hash.values.sort.each do |record|
        if record.notify?(which_flag)
          StaffMailer.upcoming_invigilation_email(record.staff,
                                                  record.instances,
                                                  self.extra_text,
                                                  user).deliver_now
        end
      end
    else
      raise "Must execute the notifier first."
    end
  end

  def notify_clashes
    if @executed
      if @clashes.size > 0
        User.exams.each do |u|
          UserMailer.invigilation_clash_email(u, @clashes).deliver_now
        end
      end
    else
      raise "Must execute the notifier first."
    end
  end

  private

  def to_bool(value)
    if value.instance_of?(String)
      if value == "0"
        false
      else
        true
      end
    else
      value
    end
  end

end
