IMPORT_DIR = 'import'

class MIS_Loader

  attr_reader :secondary_staff_hash,
              :tegs_by_name_hash,
              :tugs_by_name_hash

  def prepare(options)
    Nokogiri::XML(File.open(Rails.root.join(IMPORT_DIR, "data.xml")))
  end

  def mis_specific_preparation
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
    #
    #  Likewise, the schedule records are a bit broken, in that they
    #  provide no means to link the relevant sets.  For now we're
    #  frigging it a bit and using names.
    #
    @tegs_by_name_hash = Hash.new
    @teachinggroups.each do |teg|
      @tegs_by_name_hash[teg.name] = teg
    end
    @tugs_by_name_hash = Hash.new
    @tutorgroups.each do |tug|
      @tugs_by_name_hash[tug.name] = tug
    end
  end
end
