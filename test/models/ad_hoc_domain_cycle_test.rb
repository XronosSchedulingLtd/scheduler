require 'test_helper'

class AdHocDomainCycleTest < ActiveSupport::TestCase
  setup do
    @ad_hoc_domain_cycle = FactoryBot.create(:ad_hoc_domain_cycle)
  end

  test "must have a name" do
    @ad_hoc_domain_cycle.name = ""
    assert_not @ad_hoc_domain_cycle.valid?
  end

  test "must have a start date" do
    @ad_hoc_domain_cycle.starts_on = nil
    assert_not @ad_hoc_domain_cycle.valid?
  end

  test "must have an end date" do
    @ad_hoc_domain_cycle.exclusive_end_date = nil
    assert_not @ad_hoc_domain_cycle.valid?
  end

  test "end date can be assigned inclusively" do
    @ad_hoc_domain_cycle.ends_on = nil
    assert_not @ad_hoc_domain_cycle.valid?
    new_ends_on = Date.today + 14.days
    @ad_hoc_domain_cycle.ends_on = new_ends_on
    assert_equal new_ends_on + 1.day, @ad_hoc_domain_cycle.exclusive_end_date
  end

  test "duration must be non-negative" do
    ahdc = FactoryBot.build(
      :ad_hoc_domain_cycle,
      starts_on: Date.today,
      exclusive_end_date: Date.yesterday)
    assert_not ahdc.valid?
  end

  test "duration must be strictly positive" do
    ahdc = FactoryBot.build(
      :ad_hoc_domain_cycle,
      starts_on: Date.today,
      exclusive_end_date: Date.today)
    assert_not ahdc.valid?
  end

  test "must belong to a domain" do
    @ad_hoc_domain_cycle.ad_hoc_domain = nil
    assert_not @ad_hoc_domain_cycle.valid?
  end

  test "deleting cycle nullifies default setting in parent" do
    ahd = FactoryBot.create(:ad_hoc_domain)
    ahdc = FactoryBot.create(:ad_hoc_domain_cycle, ad_hoc_domain: ahd)
    ahd.default_cycle = ahdc
    ahd.save
    assert_equal ahdc, ahd.default_cycle
    ahdc.destroy
    ahd.reload
    assert_nil ahd.default_cycle
  end

  test "deleting the parent domain deletes the cycle" do
    ahd = FactoryBot.create(:ad_hoc_domain)
    ahdc = FactoryBot.create(:ad_hoc_domain_cycle, ad_hoc_domain: ahd)
    assert_difference('AdHocDomainCycle.count', -1) do
      ahd.destroy
    end
  end

  test "can have subjects" do
    ahds = FactoryBot.create(
      :ad_hoc_domain_subject,
      ad_hoc_domain_cycle: @ad_hoc_domain_cycle)
    assert ahds.valid?
  end

  test "deleting cycle deletes the subject records" do
    ahdc = FactoryBot.create(:ad_hoc_domain_cycle)
    ahds = FactoryBot.create(
      :ad_hoc_domain_subject,
      ad_hoc_domain_cycle: ahdc)
    assert ahds.valid?
    assert_difference('AdHocDomainSubject.count', -1) do
      ahdc.destroy
    end
  end

  test "can be linked to multiple subjects" do
    subject1 = FactoryBot.create(:subject)
    subject2 = FactoryBot.create(:subject)
    #
    #  Something intriguing which I discovered entirely by accident.
    #  I originally had a HABTM relationship between AdHocDomain and
    #  Subject Element, then changed it to an explicit intermediate
    #  model.  Nonetheless, the trick of <<ing a new element still
    #  seems to work.  Clever.
    #
    @ad_hoc_domain_cycle.subjects << subject1
    @ad_hoc_domain_cycle.subjects << subject2
    assert_equal 2, @ad_hoc_domain_cycle.subjects.count
    assert_equal 2, @ad_hoc_domain_cycle.ad_hoc_domain_subjects.count
    assert subject1.ad_hoc_domain_cycles.include?(@ad_hoc_domain_cycle)
    #
    #  Deleting the AdHocDomainCycle deletes its AdHocDomainSubjects but not
    #  the subjects.
    #
    assert_difference('AdHocDomainSubject.count', -2) do
      @ad_hoc_domain_cycle.destroy
      subject1.reload
      subject2.reload
      assert_not_nil subject1.element
      assert_not_nil subject2.element
    end
  end

  test "implements position of" do
    assert @ad_hoc_domain_cycle.respond_to? :position_of
  end

  test "cycles sort by date" do
    base_date = Date.today
    c1 = FactoryBot.create(
      :ad_hoc_domain_cycle,
      starts_on: base_date,
      ends_on: base_date + 5.days)
    c2 = FactoryBot.create(
      :ad_hoc_domain_cycle,
      starts_on: base_date + 30.days,
      ends_on: base_date + 35.days)
    c3 = FactoryBot.create(
      :ad_hoc_domain_cycle,
      starts_on: base_date + 20.days,
      ends_on: base_date + 25.days)
    c4 = FactoryBot.create(
      :ad_hoc_domain_cycle,
      starts_on: base_date + 30.days,
      ends_on: base_date + 34.days)

    original = [c1, c2, c3, c4]
    sorted = [c1, c3, c4, c2]
    assert_equal sorted, original.sort
    original = [c4, c3, c2, c1]
    assert_equal sorted, original.sort
  end

  test "can populate new cycle record from old one" do
    2.times do
      ahdsubj = FactoryBot.create(
        :ad_hoc_domain_subject,
        ad_hoc_domain_cycle: @ad_hoc_domain_cycle)
      3.times do
        ahdstaff = FactoryBot.create(
          :ad_hoc_domain_staff,
          ad_hoc_domain_cycle: @ad_hoc_domain_cycle,
          ad_hoc_domain_subjects: [ahdsubj])
        4.times do
          FactoryBot.create(
            :ad_hoc_domain_pupil_course,
            ad_hoc_domain_staff: ahdstaff,
            ad_hoc_domain_subject: ahdsubj)
        end
      end
    end
    assert_equal 2, @ad_hoc_domain_cycle.ad_hoc_domain_subjects.count
    assert_equal 6, @ad_hoc_domain_cycle.ad_hoc_domain_staffs.count
    assert_equal 24, @ad_hoc_domain_cycle.ad_hoc_domain_pupil_courses.count
    @ad_hoc_domain_cycle.reload
    ahdc = FactoryBot.create(:ad_hoc_domain_cycle)
    assert_equal 0, ahdc.num_real_subjects
    assert_equal 0, ahdc.num_real_staff
    assert_equal 0, ahdc.num_real_pupils
    ahdc.copy_what = "0"
    ahdc.populate_from(@ad_hoc_domain_cycle)
    assert_equal 0, ahdc.num_real_subjects
    assert_equal 0, ahdc.num_real_staff
    assert_equal 0, ahdc.num_real_pupils
    ahdc.copy_what = "1"
    ahdc.populate_from(@ad_hoc_domain_cycle)
    assert_equal 2, ahdc.num_real_subjects
    assert_equal 0, ahdc.num_real_staff
    assert_equal 0, ahdc.num_real_pupils
    ahdc = FactoryBot.create(:ad_hoc_domain_cycle)
    ahdc.copy_what = "2"
    ahdc.populate_from(@ad_hoc_domain_cycle)
    assert_equal 2, ahdc.num_real_subjects
    assert_equal 6, ahdc.num_real_staff
    assert_equal 0, ahdc.num_real_pupils
    ahdc = FactoryBot.create(:ad_hoc_domain_cycle)
    ahdc.copy_what = "3"
    ahdc.populate_from(@ad_hoc_domain_cycle)
    assert_equal 2, ahdc.num_real_subjects
    assert_equal 6, ahdc.num_real_staff
    assert_equal 24, ahdc.num_real_pupils
  end

end
