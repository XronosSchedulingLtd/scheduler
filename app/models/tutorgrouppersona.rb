# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2014 John Winters
# See COPYING and LICENCE in the root directory of the application
# for more information.

class Tutorgrouppersona < ActiveRecord::Base

  validates :house, presence: true
  validates :staff, presence: true

  belongs_to :staff
  has_one    :group

  include Persona

  #
  #  Maintenance method to fix a tutor group's pupil names.
  #
  def fix_pupil_names
    fixed_count = 0
    group.members(nil, false, true).select {|member|
      member.class == Pupil
    }.each do |pupil|
      if pupil.element_name != pupil.element.name
        pupil.save
        fixed_count += 1
      end
    end
    puts "Fixed #{fixed_count} pupils' names."
    nil
  end

  #
  #  Returns a string like "3JHW"
  #  No it doesn't - this method is broken.  Can't think what I was
  #  thinking, but it doesn't seem to be used anway.
  #
#  def tutorgroup_name
#    current_era = Setting.current_era
#    if current_era
#      year_group = (self.start_year - current_era.starts_on.year + 7).to_s
#    else
#      year_group = ""
#    end
#    "#{year_group}#{staff.initials}"
#  end

  self.per_page = 15
  def active
    true
  end

end
