require 'test_helper'

class AdHocDomainAllocationTest < ActiveSupport::TestCase
  setup do
    @ad_hoc_domain_cycle = FactoryBot.create(:ad_hoc_domain_cycle)
    @valid_params = {
      name: "Banana"
    }
  end

  test "can create for cycle" do
    new_allocation =
      @ad_hoc_domain_cycle.ad_hoc_domain_allocations.new(@valid_params)
    assert new_allocation.instance_of? AdHocDomainAllocation
    assert new_allocation.valid?
  end

  test "must have a name" do
    ahda = AdHocDomainAllocation.new(@valid_params.except(:name))
    assert_not ahda.valid?
  end

  test "deleting cycle deletes allocation" do
    assert_difference("AdHocDomainAllocation.count") do
      new_allocation =
        @ad_hoc_domain_cycle.ad_hoc_domain_allocations.create(@valid_params)
      assert new_allocation.valid?
    end
    assert_difference("AdHocDomainAllocation.count", -1) do
      @ad_hoc_domain_cycle.destroy
    end
  end

end
