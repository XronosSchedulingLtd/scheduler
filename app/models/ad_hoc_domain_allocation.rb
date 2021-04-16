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
          pupil_id: pupil_course.pupil_id,
          mins: pupil_course.minutes,
          name: pupil_course.pupil.name,
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
      result[:weeks] =
        WeekIdentifier.new(ad_hoc_domain_cycle.starts_on,
                           ad_hoc_domain_cycle.ends_on).dates
      result[:pupils] = pupils
      result[:allocated] = self.allocations[staff.id] || []
      #
      #  Need to get the timetable for each pupil.
      #
      lesson_category = Eventcategory.cached_category("Lesson")
      timetables = Hash.new
      subjects = Hash.new
      pupil_ids = staff.ad_hoc_domain_pupil_courses.collect(&:pupil_id)
      pupils = Pupil.includes(:element).where(id: pupil_ids)
      pupils.each do |pupil|
        ea = Timetable::EventAssembler.new(pupil.element, Date.today, true)
        timetable = Hash.new
        ea.events_by_day do |week, day_no, event|
          if event.eventcategory_id == lesson_category.id
            timetable[week] ||= Array.new
            timetable[week][day_no] ||= Array.new
            subject = event.subject
            if subject
              subjects[subject.id] ||= subject.name
              subject_id = subject.id
            else
              subject_id = 0
            end
            timetable[week][day_no] << {
              b: event.starts_at.to_s(:hhmm),
              e: event.ends_at.to_s(:hhmm),
              s: subject_id
            }
          end
        end
        timetables[pupil.id] = timetable
      end
      result[:timetables] = timetables
      result[:subjects] = subjects
      result[:current] = 0
    end
    result
  end
end
