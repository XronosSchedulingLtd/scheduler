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
  def generate_blanks(root)
    case root
    when AdHocDomainCycle
      root.ad_hoc_domain_subjects.each do |ahdsubject|
        generate_blanks(ahdsubject)
      end
      root.ad_hoc_domain_subjects.new
    when AdHocDomainSubject
      root.ad_hoc_domain_staffs.each do |ahdstaff|
        generate_blanks(ahdstaff)
      end
      root.ad_hoc_domain_staffs.new
    when AdHocDomainStaff
      root.ad_hoc_domain_pupil_courses.new
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
