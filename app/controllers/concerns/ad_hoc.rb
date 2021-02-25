#
# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2020 John Winters
# See COPYING and LICENCE in the root directory of the application
# for more information.
#

#
#  Code used by all the AdHocXxxx controllers.
#
module AdHoc

  #
  #  Works recursively to generate all the blanks needed for
  #  the input forms.
  #
  #  Note that the parent here is not really a parent - in database
  #  structure terms they are peers - but it's a parent in the sense
  #  of how the user is viewing them.  If the user is viewing the
  #  "by_subject" tab then staff appear under subjects, and vice versa.
  #
  def generate_blanks(root, parent = nil)
    case root
    when AdHocDomainCycle
      #
      #  Each existing subject gets a blank for creating a new staff
      #  member, plus we get a blank for creating a new subject.
      #
      root.ad_hoc_domain_subjects.each do |ahdsubject|
        generate_blanks(ahdsubject)
      end
      Rails.logger.debug("Adding blank subject to cycle #{root.id}")
      root.ad_hoc_domain_subjects.new
      #
      #  Each existing staff member gets a blank for creating a new subject
      #  plus we get a blank for creating a new staff member.
      #
      root.ad_hoc_domain_staffs.each do |ahdstaff|
        generate_blanks(ahdstaff)
      end
      Rails.logger.debug("Adding blank staff to cycle #{root.id}")
      root.ad_hoc_domain_staffs.new
    when AdHocDomainSubject
      if parent
        #
        #  We are the nested one.  Can we set up a blank for
        #  the pupil course?
        #
        #  N.B.  We expect all relevant records to be already in memory
        #  so use Ruby functions rather than explicit d/b hits.
        #
        habtm =
          root.ad_hoc_domain_subject_staffs.find { |ahdss|
            ahdss.ad_hoc_domain_staff_id == parent.id }
        if habtm
          Rails.logger.debug("Adding blank pupil course to habtm #{habtm.id}")
          habtm.ad_hoc_domain_pupil_courses.new
        end
      else
        root.ad_hoc_domain_staffs.each do |ahdstaff|
          generate_blanks(ahdstaff, root)
        end
        Rails.logger.debug("Adding blank staff to subject #{root.id}")
        root.ad_hoc_domain_staffs.new({
          ad_hoc_domain_cycle: root.ad_hoc_domain_cycle
        })
      end
    when AdHocDomainStaff
      if parent
        habtm =
          root.ad_hoc_domain_subject_staffs.find { |ahdss|
            ahdss.ad_hoc_domain_subject_id == parent.id }
        if habtm
          Rails.logger.debug("Adding blank pupil course to habtm #{habtm.id}")
          habtm.ad_hoc_domain_pupil_courses.new
        end
      else
        root.ad_hoc_domain_subjects.each do |ahdsubject|
          generate_blanks(ahdsubject, root)
        end
        Rails.logger.debug("Adding blank subject to staff #{root.id}")
        root.ad_hoc_domain_subjects.new({
          ad_hoc_domain_cycle: root.ad_hoc_domain_cycle
        })
      end
    end
  end

end
