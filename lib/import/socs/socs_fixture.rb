#
# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2019 John Winters
# See COPYING and LICENCE in the root directory of the application
# for more information.
#

class SocsFixture

  #
  #  Given an array of team names, produce a neat bit of summary text.
  #
  module TeamNameSummarizer
    TeamNameTypes = [
      :ordinal,               # 1st, 2nd
      :ordinal_soccer,        # 1st XI, 2nd XI
      :ordinal_rugby,         # 1st XV, 2nd XV
      :age_group,             # Junior/Inter/Senior Boys
      :underNNX,              # U18A, U13B, Mixed-U13A, Boys-U12A etc.
      :other
    ]

    def self.format_age_group_teams(teams)
      #
      #  Teams are all "Junior Boys", "Inter Boys"
      #
      "#{teams.join("/")} Boys"
    end

    def self.format_soccer(teams)
      "#{teams.join(", ")} XI"
    end

    def self.format_rugby(teams)
      "#{teams.join(", ")} XV"
    end

    def self.format_underNN(teams)
      grouped = Hash.new
      teams.sort.each do |team|
        m = team.match(/^(U\d+) ([A-Z])$/)
        if m
          (grouped[m[1]] ||= Array.new) << m[2]
        end
      end
      output = []
      grouped.each do |key, suffixes|
        output << "#{key} #{suffixes.join("/")}"
      end
      output.join(", ")
    end

    #
    #  Passed an array of team names (straight from SOCS), sort them
    #  into types and then pass back some summary text.
    #
    def self.summary_text(teams)
      #
      #  Start by sorting all the team names into types.
      #
      sorted_teams = Hash.new
      teams.each do |team|
        if m = team.match(/^(Junior|Inter|Senior) Boys/)
          (sorted_teams[:age_group] ||= Array.new) << m[1]
        elsif m = team.match(/^(1st|2nd|3rd|\dth) XI/)
          (sorted_teams[:ordinal_soccer] ||= Array.new) << m[1]
        elsif m = team.match(/^(1st|2nd|3rd|\dth) XV/)
          (sorted_teams[:ordinal_rugby] ||= Array.new) << m[1]
        elsif m = team.match(/^(U\d\d)\s?([A-Z])/)
          #
          #  Pass through a regularized version
          #
          (sorted_teams[:underNNX] ||= Array.new) << "#{m[1]} #{m[2]}"
        elsif m = team.match(/^(Boys|Mixed)-(U\d\d)([A-Z])/)
          #
          #  Pass through a regularized version
          #
          (sorted_teams[:underNNX] ||= Array.new) << "#{m[2]} #{m[3]}"
        else
          (sorted_teams[:other] ||= Array.new) << team
        end
      end
      chunks = Array.new
      sorted_teams.each do |key, teams|
        case key
        when :age_group
          chunks << format_age_group_teams(teams)
        when :ordinal_soccer
          chunks << format_soccer(teams)
        when :ordinal_rugby
          chunks << format_rugby(teams)
        when :underNNX
          chunks << format_underNN(teams)
        else          # :other (and indeed, :ordinal)
          chunks += teams
        end
      end
      chunks.join(", ")
    end
  end

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
    if @location.match(/^Home/)
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
    @teams     = [@team]
    @team_urls = []
    unless @team.blank? || @url.blank?
      @team_urls << "[#{@team}](#{@url})"
    end
    #
    #  SOCS sends at least some fields double-encoded.  They need to
    #  be encoded to pass through XML, but SOCS does it twice.
    #
    #  Thus "&" gets turned into not "&amp;" as it should be but
    #  into "&amp;amp;".  The XML library which we're using copes
    #  with the first level, but quite correctly does not attempt
    #  to recurse.
    #
    #  I suspect it's because they have encoded the text for display
    #  as HTML, then forgotten it was like that before sending it
    #  out on the feed.
    #
    #  In any case, try to decode it.
    #
    unless @opposition.blank?
      @opposition = Nokogiri::HTML.parse(@opposition).text
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
    TeamNameSummarizer.summary_text(@teams)
  end

  def old_melded_team_text
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

