require 'test_helper'

class ConcernTest < ActiveSupport::TestCase

  setup do
    @user1 = FactoryBot.create(:user, email: 'user1@myschool.org.uk')
    @user2 = FactoryBot.create(:user, email: 'user2@myschool.org.uk')
    #
    #  Note deliberately non-matching email addresses.
    #
    @staff = FactoryBot.create(:staff, email: 'staff@myschool.org.uk')
    @pupil = FactoryBot.create(:pupil, email: 'pupil@myschool.org.uk')
    @element1 = FactoryBot.create(:element)
    @element2 = FactoryBot.create(:element)
    @extra_set = FactoryBot.create(:concern_set, owner: @user1)
  end

  test "Can create a concern" do
    c = Concern.create({
      element: @element1,
      user:    @user1,
      colour:  "red"
    })
    assert c.valid?
  end

  test "Each concern must belong to a user" do
    c = Concern.create({
      element: @element1,
      colour:  "red"
    })
    assert_not c.valid?
  end

  test "Each concern must have an element" do
    c = Concern.create({
      user:    @user1,
      colour:  "red"
    })
    assert_not c.valid?
  end

  test "Each concern must have a colour" do
    c = Concern.create({
      element: @element1,
      user:    @user1
    })
    assert_not c.valid?
  end

  test "Can't create two identical concerns in the default set" do
    c1 = Concern.create({
      element: @element1,
      user:    @user1,
      colour:  "red"
    })
    c2 = Concern.create({
      element: @element1,
      user:    @user1,
      colour:  "red"
    })
    assert c1.valid?
    assert_not c2.valid?
  end

  test "Can create two identical concerns in different sets" do
    c1 = Concern.create({
      element: @element1,
      user:    @user1,
      colour:  "red"
    })
    c2 = Concern.create({
      element: @element1,
      user:    @user1,
      colour:  "red",
      concern_set: @extra_set
    })
    assert c1.valid?
    assert c2.valid?
  end

  test "Each concern has an assistant_to flag" do
    c = Concern.create({
      element: @element1,
      user:    @user1,
      colour:  "red"
    })
    assert c.respond_to?(:assistant_to?)
  end

  test "Assistant_to defaults to false" do
    c = Concern.create({
      element: @element1,
      user:    @user1,
      colour:  "red"
    })
    assert_not c.assistant_to?
  end

  #
  #  And now to do with logins.
  #
  test "Creating equality concern for staff member creates link" do
    assert_equal UserProfile.guest_profile, @user1.user_profile
    c = Concern.create({
      user: @user1,
      element: @staff.element,
      colour: 'red',
      equality: true
    })
    assert_equal @staff, @user1.corresponding_staff
    @staff.reload
    assert_equal @user1, @staff.corresponding_user
    assert @user1.staff?
    #
    #  Note that the auto callbacks do not set the profile.
    #  It's done in find_matching_resources, or manually by
    #  the system admin.
    #
    assert_equal UserProfile.guest_profile, @user1.user_profile
  end

  test "But a general staff concern does not" do
    c = Concern.create({
      user: @user1,
      element: @staff.element,
      colour: 'red'
    })
    assert_nil @user1.corresponding_staff
    @staff.reload
    assert_nil @staff.corresponding_user
    assert_not @user1.staff?
  end

  test "Setting equality flag adds link" do
    c = Concern.create({
      user: @user1,
      element: @staff.element,
      colour: 'red'
    })
    assert_nil @user1.corresponding_staff
    @staff.reload
    assert_nil @staff.corresponding_user
    assert_not @user1.staff?
    c.equality = true
    c.save!
    assert_equal @staff, @user1.corresponding_staff
    @staff.reload
    assert_equal @user1, @staff.corresponding_user
    assert @user1.staff?
  end

  test "Removing equality flag removes link" do
    assert_equal UserProfile.guest_profile, @user1.user_profile
    c = Concern.create({
      user: @user1,
      element: @staff.element,
      colour: 'red',
      equality: true
    })
    assert_equal @staff, @user1.corresponding_staff
    @staff.reload
    assert_equal @user1, @staff.corresponding_user
    assert @user1.staff?
    c.equality = false
    c.save!
    assert_nil @user1.corresponding_staff
    @staff.reload
    assert_nil @staff.corresponding_user
    assert_not @user1.staff?

  end

  test "Creating equality concern for pupil creates link" do
    assert_equal UserProfile.guest_profile, @user1.user_profile
    c = Concern.create({
      user: @user1,
      element: @pupil.element,
      colour: 'red',
      equality: true
    })
    assert @user1.pupil?
    assert_equal UserProfile.guest_profile, @user1.user_profile
  end

  test "But a general pupil concern does not" do
    assert_equal UserProfile.guest_profile, @user1.user_profile
    c = Concern.create({
      user: @user1,
      element: @pupil.element,
      colour: 'red'
    })
    assert_not @user1.pupil?
    assert_equal UserProfile.guest_profile, @user1.user_profile
  end

  test "Removing pupil equality flag removes link" do
    assert_equal UserProfile.guest_profile, @user1.user_profile
    c = Concern.create({
      user: @user1,
      element: @pupil.element,
      colour: 'red',
      equality: true
    })
    assert @user1.pupil?
    c.equality = false
    c.save!
    assert_not @user1.pupil?
  end

  test "Two users can link to same staff" do
    staff = FactoryBot.create(:staff, email: "same@myschool.org.uk")
    user1 = FactoryBot.create(:user, email: "same@myschool.org.uk")
    user2 = FactoryBot.create(:user, email: "same@myschool.org.uk")
    assert user1.staff?
    assert user2.staff?
    assert_equal UserProfile.staff_profile, user1.user_profile
    assert_equal UserProfile.staff_profile, user2.user_profile
    assert_equal staff, user1.corresponding_staff
    assert_equal staff, user2.corresponding_staff
    staff.reload
    assert_equal user1, staff.corresponding_user
    user1.destroy
    staff.reload
    assert_equal user2, staff.corresponding_user
  end

  test "Creating an owning concern sets user as an owner" do
    assert_not @user1.element_owner?
    c = Concern.create({
      element: @element1,
      user:    @user1,
      colour:  "red",
      owns: true
    })
    assert c.valid?
    assert @user1.element_owner?
  end

  test "Creating an owning concern sets element as owned" do
    assert_not @element1.owned?
    c = Concern.create({
      element: @element1,
      user:    @user1,
      colour:  "red",
      owns: true
    })
    assert c.valid?
    assert @element1.owned?
  end

  test "Deleting last owning concern sets user as not owner" do
    assert_not @user1.element_owner?
    c = Concern.create({
      element: @element1,
      user:    @user1,
      colour:  "red",
      owns: true
    })
    assert c.valid?
    assert @user1.element_owner?
    c.destroy
    assert_not @user1.element_owner?
  end

  test "Deleting last owning concern sets element as not owned" do
    assert_not @element1.owned?
    c = Concern.create({
      element: @element1,
      user:    @user1,
      colour:  "red",
      owns: true
    })
    assert c.valid?
    assert @element1.owned?
    c.destroy
    assert_not @element1.owned?
  end

  test "Delete not-last owning concern leaves user as owner" do
    assert_not @user1.element_owner?
    c1 = Concern.create({
      element: @element1,
      user:    @user1,
      colour:  "red",
      owns: true
    })
    assert c1.valid?
    c2 = Concern.create({
      element: @element2,
      user:    @user1,
      colour:  "red",
      owns: true
    })
    assert c2.valid?
    assert @user1.element_owner?
    c1.destroy
    assert @user1.element_owner?
    c2.destroy
    assert_not @user1.element_owner?
  end

  test "Delete not-last owning concern leaves element as owned" do
    assert_not @element1.owned?
    c1 = Concern.create({
      element: @element1,
      user:    @user1,
      colour:  "red",
      owns: true
    })
    assert c1.valid?
    c2 = Concern.create({
      element: @element1,
      user:    @user2,
      colour:  "red",
      owns: true
    })
    assert c2.valid?
    assert @element1.owned?
    c1.destroy
    assert @element1.owned?
    c2.destroy
    assert_not @element1.owned?
  end

end
