require 'test_helper'

#
#  A slightly odd test module in that it doesn't relate to a single
#  model, but to how a collection of them sort.  All the relevant code
#  however is still contained within the models, so it makes sense to
#  test at this level.
#
#  Note that sorting within an entity type is tested at the entity
#  level.  We merely test that they sort correctly between types.
#
class SortingTest < ActiveSupport::TestCase
  setup do
    #
    #  Build an array in the order in which they should be sorted.
    #
    @entities = Array.new
    Element::SORT_ORDER_HASH.each do |key, value|
      @entities << FactoryBot.create(key.downcase.to_sym)
    end
    assert_equal Element::SORT_ORDER_HASH.size, @entities.size
    @shuffled = @entities.shuffle
  end

  test "it should be possible to sort mixed elements" do
    pupils = Pupil.all.to_a
    staff = Staff.all.to_a
    everything = pupils + staff
    assert_nothing_raised do
      everything.sort
    end
  end

  test "can sort all entity types" do
    sorted = @shuffled.sort
    @entities.each_with_index do |entity, i|
      assert_equal entity, sorted[i]
    end
  end

end

