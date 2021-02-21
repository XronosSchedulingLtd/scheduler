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
      root.ad_hoc_domain_subjects.new
      #
      #  Each existing staff member gets a blank for creating a new subject
      #  plus we get a blank for creating a new staff member.
      #
      root.ad_hoc_domain_staffs.each do |ahdstaff|
        generate_blanks(ahdstaff)
      end
      root.ad_hoc_domain_staffs.new
    when AdHocDomainSubject
      if parent
        root.ad_hoc_domain_pupil_courses.new({
          ad_hoc_domain_staff: parent
        })
      else
        root.ad_hoc_domain_staffs.each do |ahdstaff|
          generate_blanks(ahdstaff, root)
        end
        root.ad_hoc_domain_staffs.new({
          ad_hoc_domain_cycle: root.ad_hoc_domain_cycle,
          peer_id: root.id
        })
      end
    when AdHocDomainStaff
      if parent
        root.ad_hoc_domain_pupil_courses.new({
          ad_hoc_domain_subject: parent
        })
      else
        root.ad_hoc_domain_subjects.each do |ahdsubject|
          generate_blanks(ahdsubject, root)
        end
        root.ad_hoc_domain_subjects.new({
          ad_hoc_domain_cycle: root.ad_hoc_domain_cycle,
          peer_id: root.id
        })
      end
    end
  end

#    @ad_hoc_domain.ad_hoc_domain_subjects.each do |ahdsubject|
#      ahdsubject.ad_hoc_domain_staffs.each do |ahdstaff|
#        ahdstaff.ad_hoc_domain_pupil_courses.new
#      end
#      ahdsubject.ad_hoc_domain_staffs.new
#    end
#    @ad_hoc_domain.ad_hoc_domain_subjects.new
  
end
