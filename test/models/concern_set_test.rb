require 'test_helper'

class ConcernSetTest < ActiveSupport::TestCase
  setup do
    @user   = FactoryBot.create(:user)
    @valid_params = {
      name: 'Banana',
      owner: @user
    }
  end

  test 'can create a concern set' do
    cs = ConcernSet.create(@valid_params)
    assert cs.valid?
  end

  test 'concern set must have an owner' do
    cs = ConcernSet.create(@valid_params.except(:owner))
    assert_not cs.valid?
  end

  test 'concern set must have a name' do
    cs = ConcernSet.create(@valid_params.except(:name))
    assert_not cs.valid?
  end

  test 'can add concerns to set' do
    cs = ConcernSet.create(@valid_params)
    cs.concerns << FactoryBot.create(:concern)
    cs.concerns << FactoryBot.create(:concern)
    assert_equal 2, cs.concerns.count
    assert_equal 2, cs.num_concerns
    assert cs.concerns[0].valid?
    assert cs.concerns[1].valid?
  end

  test 'deleting set deletes concerns' do
    cs = ConcernSet.create(@valid_params)
    cs.concerns << FactoryBot.create(:concern)
    cs.concerns << FactoryBot.create(:concern)
    c0 = cs.concerns[0]
    c1 = cs.concerns[1]
    cs.destroy
    assert c0.destroyed?
    assert c1.destroyed?
  end

  test 'parentless concerns appear in the default set' do
    cs = ConcernSet.new(@valid_params.merge({ id: 0 }))
    #
    #  Note that because this one has not been saved to the database,
    #  it will have an id of 0, and thus appear to be the default concern
    #  set.  This is used in the main application when providing an
    #  index of concern sets.  A dummy one is created to provide a
    #  listing of those concerns which don't belong to a set.
    #
    assert_equal 0, cs.num_concerns
    FactoryBot.create(:concern, user: @user)
    FactoryBot.create(:concern, user: @user)
    assert_equal 2, cs.num_concerns
  end

  test 'concern sets sort by name' do
    cs0 = ConcernSet.create(@valid_params.merge({name: "Zebedee"}))
    cs1 = ConcernSet.create(@valid_params.merge({name: "Able"}))
    cs2 = ConcernSet.create(@valid_params.merge({name: "Monkey"}))
    sets = [cs0, cs1, cs2]
    sorted = sets.sort
    assert_equal cs0, sorted[2]
    assert_equal cs1, sorted[0]
    assert_equal cs2, sorted[1]
  end

  test 'dummy attributes work' do
    cs = ConcernSet.create(@valid_params)
    assert     cs.copy_concerns?
    assert_not cs.and_hide?
    cs.copy_concerns = false
    cs.and_hide      = true
    assert_not cs.copy_concerns?
    assert     cs.and_hide?
  end

end
