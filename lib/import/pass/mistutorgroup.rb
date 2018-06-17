# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2018 John Winters
# See COPYING and LICENCE in the root directory of the application
# for more information.

class MIS_Tutorgroup
  attr_reader :datasource_id, :current, :name

  def initialize(sample_pupil)
    @pupils = Array.new
    @staff = nil
    @current = true
    @datasource_id = @@primary_datasource_id
    #
    super
    @name             = local_form_name(sample_pupil)
    @form_code        = sample_pupil.form_code
    @form_description = sample_pupil.form_description
    @tutor_name       = sample_pupil.tutor_name
    @year_id          = translate_year_group(sample_pupil.form_year)
    tutor = MIS_Staff.by_name(sample_pupil.tutor_name)
    if tutor
      self.note_tutor(tutor)
    end
  end

  def source_id_str
    @form_code
  end

  def start_year
    local_effective_start_year(self.era, @year_id, 0)
  end

  #
  #  Return the yeargroup of this tutor group, in the form that Scheduler
  #  expects.  This is configurable, but generally corresponds to the
  #  years which the school naturally uses.  Thus for Abingdon we
  #  have:
  #
  #    1        NC 7
  #    2        NC 8
  #    3        NC 9
  #    4        NC 10
  #    5        NC 11
  #    6        NC 12
  #    7        NC 13
  #
  def yeargroup
    local_yeargroup(@year_id)
  end

  #
  #  Slightly messy, in that in Pass, tutor groups aren't directly
  #  linked to houses.  Have to get it from one of the pupil records.
  #
  #  This thus means that if a tutor group is empty, we have no way
  #  of knowing what house it belongs to.
  #
  def house
    if @pupils.empty?
      "Don't know"
    else
#      puts "Calculating house."
#      puts "First pupil is #{@pupils.first.name}"
#      puts "House is #{@pupils.first.house}"
      @pupils.first.house_name
    end
  end

  def link_to_house
    unless @pupils.empty?
      @house_rec = MIS_House.by_name(self.house)
      if @house_rec
        @house_rec.note_tutorgroup(self)
      else
        puts "Tutor group #{self.name} can't find house #{self.house}."
      end
    end
  end

  def self.construct(loader, mis_data)
    super
    tgs = Array.new
    tgs_hash = Hash.new
    mis_data[:pupils_by_form].each do |form_code, pupils|
      #
      #  Not sure how we'd get an entry if there were no pupils, but...
      #
      unless pupils.empty?
        tg = MIS_Tutorgroup.new(pupils[0])
        tgs << tg
        tgs_hash[form_code] = tg
      end
    end
    #
    #  Now - can I populate them?
    #
    loader.pupils.each do |pupil|
      tg = tgs_hash[pupil.form_code]
      if tg
        tg.add_pupil(pupil)
      else
        puts "Can't find tutor group \"#{pupil.form_code}\" for #{pupil.name}."
      end
    end
    tgs.each do |tg|
      puts "Tutor group #{tg.name} has #{tg.size} pupils." if loader.options.verbose
      tg.finalize
    end
    without_tutor, with_tutor = tgs.partition {|tg| tg.staff == nil}
    without_tutor.each do |tg|
      puts "Dropping #{Setting.tutorgroups_name} \"#{tg.name}\" because it has no tutor."
    end
    #
    #  And link them to houses?
    #
    if Setting.tutorgroups_by_house?
      with_tutor.each do |tug|
        tug.link_to_house
      end
    end
    with_tutor
  end

end


