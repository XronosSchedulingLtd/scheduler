class EventCollection < ActiveRecord::Base
  class DaysOfWeek < Array
    class DayOfWeek
      attr_accessor :enabled, :symbol

      def initialize(symbol, ordinal, enabled)
        @symbol  = symbol
        @ordinal = ordinal
        @enabled = enabled
      end

      def name
        @symbol.to_s.capitalize
      end
    end

    def initialize(make_enabled = nil)
      super()
      self << DayOfWeek.new(:sun, 0, false)
      self << DayOfWeek.new(:mon, 1, false)
      self << DayOfWeek.new(:tue, 2, false)
      self << DayOfWeek.new(:wed, 3, false)
      self << DayOfWeek.new(:thu, 4, false)
      self << DayOfWeek.new(:fri, 5, false)
      self << DayOfWeek.new(:sat, 6, false)
      @by_sym = Hash.new
      self.each do |dow|
        @by_sym[dow.symbol] = dow
      end
      if make_enabled
        #
        #  Can be either one symbol, or an array.
        #
        if make_enabled.respond_to?(:each)
          make_enabled.each do |sym|
            self.turn_on(sym)
          end
        else
          self.turn_on(make_enabled)
        end
      end
    end

    def by_sym(symbol)
      @by_sym[symbol]
    end

    def turn_on(symbol)
      entry = @by_sym[symbol]
      if entry
        entry.enabled = true
      end
    end

    def turn_off(symbol)
      entry = @by_sym[symbol]
      if entry
        entry.enabled = false
      end
    end

    #
    #  Return an array of the days currently turned on.
    #
    def enabled_days
      self.select {|d| d.enabled}.collect {|d| d.symbol}
    end

    #
    #  We expect a list of strings, the last one being a blank.
    #
    def enabled_days=(list)
      self.each do |d|
        d.enabled = false
      end
      list.each do |le|
        turn_on(le.to_sym)
      end
    end
  end

  belongs_to :era
  has_many :events, dependent: :destroy

  validates :repetition_start_date, presence: true
  validates :repetition_end_date, presence: true
  validates :era, presence: true

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

  serialize :days_of_week, DaysOfWeek

  after_initialize :set_up_days_of_week

  delegate :enabled_days, :enabled_days=, to: :days_of_week

  private

  def set_up_days_of_week
    unless self.days_of_week
      @days_of_week = DaysOfWeek.new
    end
  end
end

