class MIS_Tutorgroup
  SELECTOR = "SchoolManager Forms Form"
  REQUIRED_FIELDS = [
    IsamsField["Id",        :isams_id, :attribute, :string],
    IsamsField["TutorId",   :tutor_id, :attribute, :integer],
    IsamsField["YearId",    :year_id,  :attribute, :integer],
    IsamsField["Form",      :name,     :data,      :string]
  ]

  include Creator

  attr_reader :datasource_id

  def initialize(entry)
    @pupils = Array.new
    @staff = nil
    #
    super
  end

  def adjust
  end

  def wanted
    @year_id && @year_id < 20
  end

  def self.construct(loader, isams_data)
    tgs = self.slurp(isams_data)
    tgs_hash = Hash.new
    tgs.each do |tg|
      tgs_hash[tg.isams_id] = tg
      staff = loader.staff_hash[tg.tutor_id]
      if staff
        tg.note_staff(staff)
      end
    end
    #
    #  Now - can I populate them?
    #
    loader.pupils.each do |pupil|
      tg = tgs_hash[pupil.form_name]
      if tg
        tg.add_pupil(pupil)
      else
        puts "Can't find tutor group \"#{pupil.form_name}\" for #{pupil.name}."
      end
    end
    tgs.each do |tg|
      puts "Tutor group #{tg.constructed_name} (#{tg.isams_id}) has #{tg.size} pupils."
      tg.finalize
    end
    tgs
  end

end


