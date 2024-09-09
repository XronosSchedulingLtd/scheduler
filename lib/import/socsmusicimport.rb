require_relative '../../config/environment'

require_relative 'common/xmlimport'
require_relative 'socs/element_engine'
require_relative 'socs/location_engine'
require_relative 'socs/property_engine'
require_relative 'socsmusic/options'
require_relative 'socsmusic/socsmusic_lessons'

MUSIC_IMPORT_DIR = 'import/socsmusic/Current'

# Initialize engines and options
element_engine = ElementEngine.new
location_engine = LocationEngine.new
property_engine = PropertyEngine.new
options = Options.new
DUMMY_SOURCE_ID_VALUE = 111111

# Function to fetch email (for pupil or staff) from API
def get_email(id)
  base_url = "https://my.abingdon.org.uk/ma-api/scheduler-api/getEmail/486f74"
  url = URI("#{base_url}/#{id}")

  response = Net::HTTP.get_response(url)
  if response.is_a?(Net::HTTPSuccess)
    json_response = JSON.parse(response.body)
    return json_response['email'] # Assuming API returns email in this format
  else
    puts "Failed to fetch email for id #{id}"
    return nil
  end
end

# Find event source for Music
eventsource = Eventsource.find_by(name: "SOCS MUSIC")
unless eventsource
  puts "Eventsource Music not found"
  exit 1
end

# Find event category
eventcategory = Eventcategory.find_by(name: options.event_category_name)
unless eventcategory
  puts "Eventcategory #{options.event_category_name} not found."
  exit 2
end

# Load XML
full_dir_path = Rails.root.join(MUSIC_IMPORT_DIR)
xml_file_path = File.expand_path("data.xml", full_dir_path)

# Ensure the file exists
unless File.exist?(xml_file_path)
  puts "XML file not found at #{xml_file_path}"
  exit 3
end

xml = Nokogiri::XML(File.open(xml_file_path))

fixture_set = MusicFixtureSet.new(xml, options)

if fixture_set.empty?
  puts "No music fixtures found."
else
  puts "Got #{fixture_set.fixtures.count} fixtures" if options.verbose

  start_date = options.start_date
  end_date = options.end_date || fixture_set.last_date

  if end_date < start_date
    puts "End date (#{end_date}) is less than start date (#{start_date}) - aborting."
    exit 4
  end

  events_created = 0
  events_deleted = 0

  (start_date..end_date).each do |date|
    puts "Processing #{date.to_s(:dmy)}" if options.verbose

    # Fetch existing events
    existing_events = Event.events_on(date, nil, nil, eventsource, nil, nil, true)
                           .includes(:commitments).to_a

    # Determine desired events
    wanted = fixture_set.fixtures_on(date)

    wanted.each do |fixture|
      property_element = property_engine.find(fixture.home_location)

      # Calculate owner based on options and property ownership
      calculated_owner = 2

      # Find existing event by source ID (lesson_id)
      existing_event = existing_events.detect { |e| e.source_id == fixture.lesson_id }

      if existing_event
        # Update existing event
        do_save = false

        if existing_event.body != fixture.title
          puts "Changing \"#{existing_event.body}\" to \"#{fixture.title}\"" if options.verbose
          existing_event.body = fixture.title
          do_save = true
        end

        if existing_event.eventcategory != eventcategory
          existing_event.eventcategory = eventcategory
          do_save = true
        end

        if existing_event.starts_at != fixture.starts_at
          existing_event.starts_at = fixture.starts_at
          do_save = true
        end

        if existing_event.ends_at != fixture.ends_at
          existing_event.ends_at = fixture.ends_at
          do_save = true
        end

        if existing_event.all_day != fixture.away?
          existing_event.all_day = fixture.away?
          do_save = true
        end

        if existing_event.owner != calculated_owner
          existing_event.owner = calculated_owner
          do_save = true
        end

        existing_event.save! if do_save
        existing_events.delete(existing_event)
      else
        # Create new event
        new_event = Event.create!(
          body: fixture.title,
          eventcategory: eventcategory,
          eventsource: eventsource,
          starts_at: fixture.starts_at,
          ends_at: fixture.ends_at,
          all_day: fixture.away?,
          source_id: fixture.lesson_id
        )
        puts "Created Event ID: #{new_event.id}"
        events_created += 1
        existing_event = new_event
      end

      # Fetch pupil email and handle pupil element
      pupil_email = get_email(fixture.pupil_id)
      next unless pupil_email

      pupil = Pupil.find_by(email: pupil_email)
      unless pupil
        puts "Pupil with email #{pupil_email} not found, skipping."
        next
      end

      pupil_element = pupil.element  # Assuming each pupil has an associated element record
      unless pupil_element
        pupil_element = Element.create!(entity: pupil)
        puts "Created Element for Pupil #{pupil.name}"
      end

      # Fetch staff email and handle staff element
      staff_email = get_email(fixture.staff_id)
      next unless staff_email

      staff = Staff.find_by(email: staff_email)
      unless staff
        puts "Staff with email #{staff_email} not found, skipping."
        next
      end

      staff_element = staff.element  # Assuming each staff has an associated element record
      unless staff_element
        staff_element = Element.create!(entity: staff)
        puts "Created Element for Staff #{staff.name}"
      end

      # Handle subject element
      instrument_name = fixture.instrument.strip.downcase

      # Special case: If the instrument name is Violin/Viola, we should map it to Violin
     if instrument_name == 'violin/viola'
      instrument_name = 'violin'
     end

      subject = Subject.find_by('LOWER(name) = ?', instrument_name)
      unless subject
        puts "Subject with name '#{instrument_name}' not found, skipping subject association."
        next
      end

      subject_element = subject.element  # Assuming each subject has an associated element record
      unless subject_element
        subject_element = Element.create!(entity: subject)
        puts "Created Element for Subject #{subject.name}"
      end

      # *** Begin Property Integration ***
      # Assuming "Music lesson" is the property you want to assign to all events
      property = Property.find_by(name: 'Music lesson')
      unless property
        puts "Property 'Music lesson' not found, skipping."
        next
      end

      property_element = property.element  # Assuming each property has an associated element record
      unless property_element
        property_element = Element.create!(entity: property)
        puts "Created Element for Property #{property.name}"
      end
      # *** End Property Integration ***

      # Collect element IDs for pupil, staff, subject, and property
      element_ids = [pupil_element.id, staff_element.id, subject_element.id, property_element.id]

      # Identify commitments to destroy
      commitments_to_destroy = []
      existing_event.commitments.each do |commitment|
        if (commitment.source_id == DUMMY_SOURCE_ID_VALUE) &&
           !element_ids.include?(commitment.element_id)
          commitments_to_destroy << commitment
        end
      end

      # Add new commitments
      element_ids.each do |element_id|
        unless existing_event.commitments.detect { |commitment| commitment.element_id == element_id }
          new_commitment = existing_event.commitments.new({
            element_id: element_id,
            source_id: DUMMY_SOURCE_ID_VALUE
          })
          # If needed, set approval status or other attributes here
          new_commitment.save!
          puts "Created new Commitment for Element ID #{element_id} and Event ID #{existing_event.id}"
        end
      end

      # Destroy invalid commitments
      commitments_to_destroy.each do |commitment|
        puts "Destroying Commitment ID #{commitment.id} for Element ID #{commitment.element_id}"
        commitment.destroy
      end
    end

    # Delete surplus events
    if existing_events.any?
      puts "Deleting #{existing_events.count} events on #{date.to_s(:dmy)}" if options.verbose
      events_deleted += existing_events.count
      existing_events.each(&:destroy)
    end
  end

  puts "#{events_created} events created and #{events_deleted} events deleted." if options.verbose
  # location_engine.list_missing if options.list_missing
end

exit 0