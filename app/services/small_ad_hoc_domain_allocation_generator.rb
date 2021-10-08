#
# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2021 John Winters
# See COPYING and LICENCE in the root directory of the application
# for more information.
#

#
#  This class exists solely as a wrapper to allow generation jobs to
#  be queued for later.  The main object is too big to be serialized
#  into a database record so this one gets saved instead.
#
class SmallAdHocDomainAllocationGenerator

  def initialize(ad_hoc_domain_allocation)
    @id = ad_hoc_domain_allocation.id
  end

  def generate
    #
    #  It's possible but unlikely that since our job was queued our
    #  linked AdHocDomainAllocation has been deleted.  What is an appropriate
    #  thing to do in that case?
    #
    AdHocDomainAllocationGenerator.new(
      AdHocDomainAllocation.find(@id)
    ).generate
  end

end
