class FakeActiveRecord < ActiveRecord::Base

  def self.columns
    @columns ||= [];
  end

  def self.column(name, sql_type = nil, default = nil, null = true)
    @columns ||= [];
    @columns << ActiveRecord::ConnectionAdapters::Column.new(name.to_s, default, sql_type.to_s, null)
  end

  def save(validate = true)
    validate ? valid? : true
  end
end

class NotifierValidator < ActiveModel::Validator
  def validate(record)
    if record[:start_date] && record[:end_date]
      if record[:end_date] < record[:start_date]
        record.errors[:end_date] << "can't be before the start date"
      end
    end
  end
end

class Notifier < FakeActiveRecord

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

  column :start_date,         :date
  column :end_date,           :date
  column :modified_since,     :date
  column :extra_text,         :text
  column :check_clashes,      :boolean, false
  #
  #  This next one exists in the model purely to allow there to be
  #  a field in the form.  It's still up to the client code to check
  #  this flag and trigger e-mails if it wants them.
  #
  column :send_notifications, :boolean, true

  validates :start_date, :presence => true
  validates_with NotifierValidator

  attr_reader :clashes

  def staff_entries
    if @staff_entry_hash
      @staff_entry_hash.values
    else
      []
    end
  end

  def start_date_text
    self.start_date ? self.start_date.to_formatted_s(:dmy) : ""
  end

  #
  #  We're given a text string which we try to make sense of.
  #
  def start_date_text=(new_value)
    self.start_date = Date.safe_parse(new_value)
  end

  def end_date_text
    self.end_date ? self.end_date.to_formatted_s(:dmy) : ""
  end

  def end_date_text=(new_value)
    self.end_date = Date.safe_parse(new_value)
  end

  def modified_since_text
    self.modified_since ? self.modified_since.to_formatted_s(:dmy) : ""
  end

  def modified_since_text=(new_value)
    self.modified_since = Date.safe_parse(new_value)
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
      Rails.logger.debug("Got #{commitments.count} commitments.")
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

  def do_send(which_flag)
    if @executed
      @staff_entry_hash.values.sort.each do |record|
        if record.notify?(which_flag)
          StaffMailer.upcoming_invigilation_email(record.staff,
                                                  record.instances,
                                                  self.extra_text).deliver
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
          UserMailer.invigilation_clash_email(u, @clashes).deliver
        end
      end
    else
      raise "Must execute the notifier first."
    end
  end

end
