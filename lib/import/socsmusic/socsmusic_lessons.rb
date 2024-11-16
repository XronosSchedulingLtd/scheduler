# app/models/music_fixture.rb
class MusicFixture
  attr_reader :lesson_id, :instrument, :title, :starts_at, :ends_at, :location, :staff_id, :pupil_id, :attendance
  def initialize(xml_node)
    @lesson_id = xml_node.at_xpath('lessonid').text
    start_date = xml_node.at_xpath('startdate').text
    start_time = xml_node.at_xpath('starttime').text
    end_time = xml_node.at_xpath('endtime').text
    @instrument = xml_node.at_xpath('instrument').text
    @title = xml_node.at_xpath('title').text
    @starts_at = Time.parse("#{start_date} #{start_time}")
    @ends_at = Time.parse("#{start_date} #{end_time}")
    @location = xml_node.at_xpath('location').text
    @staff_id = xml_node.at_xpath('staffid').text
    @pupil_id = xml_node.at_xpath('pupilid').text
    @attendance = xml_node.at_xpath('attendance').text
  end
  def home_location
    @location
  end
  def away?
    # If there's a need to define "away" logic, it can be based on location or other attributes
    false
  end
end
# app/models/music_fixture_set.rb
class MusicFixtureSet
  attr_reader :fixtures
  def initialize(xml, options = {})
    @fixtures = xml.xpath('//lesson').map { |node| MusicFixture.new(node) }
    @options = options
  end
  def empty?
    @fixtures.empty?
  end
  def fixtures_on(date)
    @fixtures.select { |f| f.starts_at.to_date == date }
  end
  def last_date
    @fixtures.map(&:starts_at).max.to_date
  end
  def instruments
    @fixtures.map(&:instrument).uniq
  end
  def home_locations
    @fixtures.map(&:home_location).uniq
  end
end