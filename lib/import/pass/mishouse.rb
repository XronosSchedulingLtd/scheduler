# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2018 John Winters
# See COPYING and LICENCE in the root directory of the application
# for more information.

class MIS_House

  def initialize(pupil)
    @name = pupil.academic_house_description
    @tugs = Array.new
    @pupils = Array.new
    @housemaster = nil
  end

  def note_pupil(pupil)
    @pupils << pupil
  end

  def self.construct(loader, mis_data)
    @namehash = Hash.new
    mis_data[:pupils_by_id].each do |pupil_id, pupil|
      @namehash[pupil.academic_house_description] ||= MIS_House.new(pupil)
    end
    @namehash.values
  end

  def self.by_name(name)
    #
    #  Find a house record, given its name.
    #
    @namehash[name]
  end

end


