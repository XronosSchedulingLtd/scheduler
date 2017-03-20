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
      ((which_flag == :daily) && @staff.invig_daily_notificiations?)
    end

  end

  column :start_date,     :date
  column :end_date,       :date
  column :modified_since, :date
  column :extra_text,     :text

  validates :start_date, :presence => true
  validates_with NotifierValidator

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

  def execute(which_flag = :regardless)
    if self.valid?
      property = Property.find_by(name: "Invigilation")
      @staff_entry_hash = Hash.new
      commitments = Commitment.commitments_on(
        startdate: self.start_date,
        enddate: self.end_date ? self.end_date : :never,
        resource:  property
      ).preload(:element)
      Rails.logger.debug("Got #{commitments.count} commitments.")
      commitments.each do |commitment|
        puts "#{commitment.event.starts_at_text}"
        commitment.event.staff.each do |staff|
          staff_entry = (@staff_entry_hash[staff.id] ||= StaffEntry.new(staff))
          staff_entry.note_instance(commitment.event)
        end
      end
      @staff_entry_hash.values.sort.each do |record|
        if record.notify?(which_flag)
          StaffMailer.upcoming_invigilation_email(record.staff,
                                                  record.instances,
                                                  self.extra_text).deliver
        end
      end
      true
    else
      false
    end
  end

end
