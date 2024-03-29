IMPORT_DIR = 'import'
ISAMS_IMPORT_DIR = 'import/isams/Current'

class MIS_Loader

  class ISAMS_Data < Hash
    attr_reader :xml, :loader

    #
    #  The order of these is perhaps slightly surprising.  At present
    #  I'm using the Event => Group link from the iSAMS d/b, but there
    #  is also a Group => Event link.  I may well switch to the latter,
    #  in which case events will need to be loaded before groups.
    #
    ACTIVITIES_TO_SLURP = [
      ISAMS_ActivityGroup,
      ISAMS_ActivityGroupPupilLink,
      ISAMS_ActivityEvent,
      ISAMS_ActivityEventOccurrence,
      ISAMS_ActivityEventTeacherLink
    ]
    COVER_TO_SLURP = [
      ISAMS_Cover
    ]

    def initialize(loader, options)
      super()
      @loader = loader
      @options = options
      full_dir_path = Rails.root.join(ISAMS_IMPORT_DIR)
      @xml =
        Nokogiri::XML(File.open(File.expand_path("data.xml", full_dir_path)))
      if options.activities
        ACTIVITIES_TO_SLURP.each do |is_type|
          unless is_type.construct(self, full_dir_path)
            puts "Failed to load #{is_type}"
          end
        end
      end
      if options.cover
        COVER_TO_SLURP.each do |is_type|
          unless is_type.construct(self, full_dir_path)
            puts "Failed to load #{is_type}"
          end
        end
      end
      if loader.options.verbose
        self.each do |key, data|
          puts "Got #{data.count} records with index #{key}."
        end
      end
    end

  end

  attr_reader :secondary_staff_hash,
              :secondary_location_hash,
              :tegs_by_code_hash,
              :pupils_by_school_id_hash,
              :subjects_by_name_hash,
              :teaching_forms_by_timetable_code_hash,
              :tugs_by_name_hash


  def prepare(options)
    ISAMS_Data.new(self, options)
  end

  def mis_specific_preparation(whatever)
    @pupils_by_school_id_hash = Hash.new
    @pupils.each do |pupil|
      @pupils_by_school_id_hash[pupil.school_id] = pupil
    end
    @secondary_staff_hash = Hash.new
    @staff.each do |staff|
      #
      #  iSAMS's API is a bit brain-dead, in that sometimes they refer
      #  to staff by their ID, and sometimes by what they call a UserCode
      #
      #  The UserCode seems to be being phased out (marked as legacy on
      #  form records), but on lessons at least it is currently the
      #  only way to find the relevant staff member.
      #
      @secondary_staff_hash[staff.secondary_key] = staff
    end
    @secondary_location_hash = Hash.new
    @locations.each do |location|
      @secondary_location_hash[location.name] = location
    end
    @tegs_by_code_hash = Hash.new
    @teachinggroups.each do |teg|
      @tegs_by_code_hash[teg.set_code] = teg
    end
    #
    #  Also need to be able to read in the TeachingForm records.
    #
    @teaching_forms = MIS_TeachingForm.construct(self, whatever)
    @teaching_forms_by_timetable_code_hash = Hash.new
    @teaching_forms.each do |tf|
      @teaching_forms_by_timetable_code_hash[tf.isams_timetable_code] = tf
    end
    @tugs_by_name_hash = Hash.new
    @tutorgroups.each do |tg|
      @tugs_by_name_hash[tg.name] = tg
    end
    @subjects_by_name_hash = Hash.new
    @subjects.each do |subject|
      @subjects_by_name_hash[subject.name] = subject
    end
    if @options.activities
      #
      #  Only now can we populate the other half groups.
      #
      MIS_Otherhalfgroup.populate(self)
    end
  end
end
