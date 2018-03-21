class RepeatDatesValidator < ActiveModel::Validator

  def validate(event_collection)
    #
    #  Check that the two dates exist first.  If they don't the
    #  record will already have failed validation and we don't
    #  need to do more.
    #
    if event_collection.repetition_start_date &&
       event_collection.repetition_end_date
      if event_collection.repetition_end_date < event_collection.repetition_start_date
        event_collection.errors[:repetition_end_date] << "can't be before start date"
      elsif event_collection.repetition_end_date > event_collection.repetition_start_date + 1.year
        event_collection.errors[:repetition_end_date] << "can't be more than a year after start date"

      end
    end
  end

end

class EventCollection < ActiveRecord::Base

  class DaynameWithIndex
    attr_reader :name, :index

    def initialize(name, index)
      @name = name
      @index = index
    end

  end

  class WeekWithKey
    attr_reader :label, :key

    def initialize(label, key)
      @label = label
      @key = key
    end

  end

  belongs_to :era
  has_many :events, dependent: :destroy

  validates :repetition_start_date, presence: true
  validates :repetition_end_date, presence: true
  validates :era, presence: true
  validates_with RepeatDatesValidator

  #
  #  These names may look excessively long, but they're like this
  #  to avoid clashing with in-built ActiveRecord names.
  #
  enum when_in_month: [
    :every_time,
    :first_time,
    :second_time,
    :third_time,
    :fourth_time,
    :fifth_time,
    :last_time,
    :penultimate_time,
    :antepenultimate_time
  ]

  #
  #  Days of week is an array of integers - 0 to 7
  #
  serialize :days_of_week
  #
  #  Weeks is an array of single character strings - "A", "B", " "
  #
  serialize :weeks

  after_initialize :set_up_days_and_weeks

  attr_reader :daynames_with_index, :weeks_with_keys

  #
  #  This will be passed an array of strings, but we want values.
  #  The last string is always empty.
  #
  def days_of_week=(strings)
    self[:days_of_week] = []
    strings.each do |string|
      unless string.empty?
        value = string.to_i
        enable_day(value)
      end
    end
  end

  def weeks=(strings)
    self[:weeks] = []
    strings.each do |string|
      unless string.empty?
        self.weeks << string
      end
    end
  end

  def enable_day(value)
    if value >=0 && value < Date::ABBR_DAYNAMES.size
      Rails.logger.debug("days_of_week = #{self.days_of_week.inspect}")
      Rails.logger.debug("value = #{value} (#{value.class})")
      unless self.days_of_week.include?(value)
        self.days_of_week << value
      end
    end
  end

  def pre_select=(value)
    unless self.days_of_week
      self[:days_of_week] = []
    end
    enable_day(value)
  end

  def starts_on_text
    repetition_start_date ? repetition_start_date.strftime("%d/%m/%Y") : ""
  end

  def starts_on_text=(value)
    old_repetition_start_date = self.repetition_start_date
    self.repetition_start_date = value
    if (self.repetition_start_date != old_repetition_start_date) &&
      !self.new_record?
      #
      #  A genuine change.
      #
      @timing_changed = true
    end
  end

  def ends_on_text
    repetition_end_date ? repetition_end_date.strftime("%d/%m/%Y") : ""
  end

  def ends_on_text=(value)
    old_repetition_end_date = self.repetition_end_date
    self.repetition_end_date = value
    if (self.repetition_end_date != old_repetition_end_date) &&
      !self.new_record?
      #
      #  A genuine change.
      #
      @timing_changed = true
    end
  end

  private

  #
  #  Days of week should be an array of integers.
  #  Note that this method is called only *after* any values which
  #  were passed into the EventCollection.new have been assigned
  #  to their variables.  We therefore need to make sure that all
  #  which is necessary for assignment is already there.
  #
  #  The default value in the database for days_of_week is nil,
  #  but it may already have been set up by an assignment.  We
  #  set it up only if it hasn't been.
  #
  def set_up_days_and_weeks
    @daynames_with_index = []
    Date::ABBR_DAYNAMES.each_with_index do |dn, i|
      @daynames_with_index << DaynameWithIndex.new(dn, i)
    end
    @weeks_with_keys = [
      WeekWithKey.new("Week A", "A"),
      WeekWithKey.new("Week B", "B"),
      WeekWithKey.new("Holidays", " ")
    ]

    unless self.days_of_week
      self[:days_of_week] = []
    end
    unless self.weeks
      self[:weeks] = []
    end
  end
end

