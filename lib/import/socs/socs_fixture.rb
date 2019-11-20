#
# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2019 John Winters
# See COPYING and LICENCE in the root directory of the application
# for more information.
#

class SocsFixture
  SELECTOR = "fixtures fixture"
  REQUIRED_FIELDS = [
    XmlField["eventid",        :socs_id,          :data, :integer],
    XmlField["sport",          :sport,            :data, :string],
    XmlField["date",           :date_text,        :data, :string],
    XmlField["startdatefull",  :starts_at_text,   :data, :string],
    XmlField["enddatefull",    :ends_at_text,     :data, :string],
    XmlField["team",           :team,             :data, :string],
    XmlField["opposition",     :opposition,       :data, :string],
    XmlField["oppositionteam", :opposition_team,  :data, :string],
    XmlField["location",       :location,         :data, :string],
    XmlField["url",            :url,              :data, :string]
  ]

  include XMLImport

  attr_reader :teams,
              :team_urls,
              :home_locations,
              :all_day,
              :starts_at,
              :ends_at

  def initialize(entry)
  end

  def adjust
    if @location.match(/^Home:/)
      @home = true
    else
      @home = false
    end
    if m = @opposition_team.match(/(^Boys-)(.*)/)
      #
      #  Take just the second chunk
      #
      @opposition_team = m[2]
    end
    if m = @location.match(/(^Home:)(.*$)/)
      #
      #  m[2] contains the rest of our string.
      #
      @home_locations = m[2].strip.split(/ *& */)
    else
      #
      #  Not a home fixture.
      #
      @home_locations = []
    end
    @teams     = [@opposition_team]
    @team_urls = []
    unless @opposition_team.blank? || @url.blank?
      @team_urls << "[#{@opposition_team}](#{@url})"
    end
    #
    #  Let's sort out the timing as best we can from the texts which
    #  we've been given.  Currently they are just text, but we want
    #  TimeWithZone objects.
    #
    @wanted    = true
    @all_day   = false
    if @starts_at_text.blank?
      if @@options.allow_timeless
        if @date_text.blank?
          #
          #  Can't cope without any date at all.
          #
          @wanted = false
        else
          @all_day = true
          @starts_at = Time.zone.parse(@date_text)
          @ends_at   = @starts_at + 1.day
        end
      else
        @wanted = false
      end
    else
      @starts_at = Time.zone.parse(@starts_at_text)
      if @ends_at_text.blank?
        @ends_at = @starts_at + @@options.default_duration.minutes
      else
        @ends_at = Time.zone.parse(@ends_at_text)
      end
    end
  end

  #
  #  Do we want this record at all?
  #
  def wanted?
    @wanted
  end

  #
  #  Try to take a long list of teams and format it sensibly, removing
  #  common parts.
  #
  #  Thus from:
  #
  #  U16A
  #  U16B
  #  U16C
  #  U17A
  #  U17B
  #  U18A
  #  U18B
  #
  #  we get:
  #
  #  U16 A,B,C, U17 A,B, U18 A,B
  #
  #  Actually - not sure I want this.  Leave for now.
  #
  def melded_team_text
    grouped = Hash.new
    others = Array.new
    @teams.sort.each do |team|
      m = team.match(/^(U\d+)(.*)$/)
      if m
        key = m[1]
        grouped[key] ||= Array.new
        grouped[key] << m[2]
      else
        others << team
      end
    end
    output = []
    grouped.each do |key, suffixes|
      output << "#{key}#{suffixes.join("/")}"
    end
    others.each do |other|
      output << other
    end
    output.join(", ")
  end

  def event_body
#    "#{@sport}: #{@opposition} - #{@teams.sort.join(", ")}"
    "#{@sport}: #{@opposition} - #{melded_team_text} (#{ @home ? "Home" : "Away"})"
  end

  def note_text
    "#####Fixture details\n#{@team_urls.join(", ")}"
  end

  def home?
    @home
  end

  def away?
    !@home
  end

  #
  #  Does this fixture match another one well enough to be absorbed.
  #
  def matches?(other)
    self.starts_at == other.starts_at &&
      self.ends_at == other.ends_at &&
      self.sport == other.sport &&
      self.opposition == other.opposition &&
      self.home? == other.home?
  end

  #
  #  Is this suitable for merging.
  #
  def suitable?(merge_type)
    (merge_type == :both) ||
     ((merge_type == :home) && (@home)) ||
     ((merge_type == :away) && (!@home))
  end

  #
  #  Absorb another fixture into this one.
  #
  def absorb(other)
    if @socs_id > other.socs_id
      @socs_id = other.socs_id
    end
    @home_locations = (@home_locations + other.home_locations).uniq
    @teams = (@teams + other.teams).uniq
    @team_urls  = (@team_urls + other.team_urls).uniq
  end

  def self.merge(fixtures, merge_type)
    new_set = Array.new
    while current = fixtures.shift
      if current.suitable?(merge_type)
        existing = new_set.detect { |f| f.matches?(current) }
        if existing
          existing.absorb(current)
        else
          new_set << current
        end
      else
        #
        #  Just passes through unchanged.
        #
        new_set << current
      end
    end
    new_set
  end

  def self.construct(data, options)
    @@options = options
    self.slurp(data)
  end

end

class SocsFixtureSet

  attr_reader :fixtures,
              :fixtures_by_date,
              :sports,
              :home_locations,
              :first_date,
              :last_date

  def initialize(data, options)
    @fixtures = SocsFixture.construct(data, options)
    #
    #  Put together a list of sports
    #
    @sports = Array.new
    @home_locations = Array.new
    @fixtures.each do |fixture|
      unless @sports.include?(fixture.sport)
        @sports << fixture.sport
      end
      fixture.home_locations.each do |hl|
        unless @home_locations.include?(hl)
          @home_locations << hl
        end
      end
    end
    #
    #  Is there any merging to be done?
    #
    if options.merge_type
      #
      #  Should be one of :home, :away, :both
      #
      @fixtures = SocsFixture.merge(@fixtures, options.merge_type)
    end
    #
    #  And sort them by date.
    #
    @fixtures_by_date = Hash.new
    @first_date = nil
    @last_date = nil
    @fixtures.each do |fixture|
      fixture_date = fixture.starts_at.to_date
      (@fixtures_by_date[fixture_date] ||= Array.new) << fixture
      if @first_date.nil? || (fixture_date < @first_date)
        @first_date = fixture_date
      end
      if @last_date.nil? || (fixture_date > @last_date)
        @last_date = fixture_date
      end
    end
  end

  def fixtures_on(date)
    fixtures = @fixtures_by_date[date]
    if fixtures
      return fixtures
    else
      return []
    end
  end

  def empty?
    @fixtures.empty?
  end
end

