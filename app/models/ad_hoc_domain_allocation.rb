#
# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2021 John Winters
# See COPYING and LICENCE in the root directory of the application
# for more information.
#

class AdHocDomainAllocation < ApplicationRecord

  belongs_to :ad_hoc_domain_cycle

  validates :name, presence: true

  serialize :allocations, Hash

  def as_json(options = {})
    result = {
      id:   self.id,
      name: self.name,
      starts: ad_hoc_domain_cycle.starts_on.iso8601,
      ends: ad_hoc_domain_cycle.exclusive_end_date.iso8601
    }
    if options[:ad_hoc_domain_staff_id] &&
      staff = AdHocDomainStaff.find_by(id: options[:ad_hoc_domain_staff_id])
      pupils = []
      staff.ad_hoc_domain_pupil_courses.each do |pupil_course|
        pupil = {
          id: pupil_course.id,
          mins: pupil_course.minutes,
          name: pupil_course.pupil_name,
          subject: pupil_course.ad_hoc_domain_subject.subject_name
        }
        pupils << pupil
      end
      #
      #  When is this member of staff available?
      #
      availables = []
      if staff.rota_template
        #
        #  Provide an array of skeletal events to provide background
        #  info.  Each needs just day of week, start time, end time.
        #
        0.upto(6) do |i|
          staff.rota_template.slots_for(i) do |rs|
            slot = Hash.new
            slot[:wday] = i
            slot[:starts_at] = rs.starts_at
            slot[:ends_at]   = rs.ends_at
            availables << slot
          end
        end
      end
      result[:availables] = availables
      result[:pupils] = pupils
      result[:allocated] = self.allocations[staff.id] || []
    end
    result
  end
end
