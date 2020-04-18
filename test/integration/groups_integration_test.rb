require 'test_helper'

class GroupsIntegrationTest < ActionDispatch::IntegrationTest
  setup do
    @ordinary_user =
      FactoryBot.create(
        :user, :editor, :noter, :files, :memberships,
        user_profile: UserProfile.staff_profile)
    @staff1 = FactoryBot.create(:staff)
    @staff2 = FactoryBot.create(:staff)
    @staff3 = FactoryBot.create(:staff)
    @owned_group = FactoryBot.create(:group, owner: @ordinary_user)
    @owned_group.add_member(@staff1)
    @owned_group.add_member(@staff2)
    @owned_group.add_member(@staff3)
    @other_owned_group = FactoryBot.create(:group, owner: @ordinary_user)
  end

  test 'we have a group with three members' do
    assert_equal 3, @owned_group.members.count
  end

  test 'must login first' do
    get groups_path
    assert_redirected_to sessions_new_path
  end

  test 'can list our own groups' do
    do_valid_login
    get groups_path
    assert_response :success
    assert_select '.zftable' do
      assert_select 'tbody' do
        #
        #  It's tempting to write just:
        #
        #  assert_select 'tr', 2 do
        #    assert_select 'td', 9
        #
        #  but the second line selects all instances of a td within
        #  a tr, so results in 18.
        #
        #  We want to examine each row separately, so need the
        #  longer-winded version.
        #
        show_url = /\A\/groups\/\d+\Z/
        edit_url = /\A\/groups\/\d+\/edit\Z/
        memberships_url = /\A\/groups\/\d+\/memberships\?and_save=true\Z/

        assert_select 'tr', 2 do |rows|
          rows.each do |row|
            assert_select row, 'td', 9
            assert_select row, 'td:nth-child(5)' do
              assert_select "a:match('href', ?)",
                            show_url,
                            { count: 1, text: 'Show' }
            end
            assert_select row, 'td:nth-child(6)' do
              assert_select "a:match('href', ?)",
                            edit_url,
                            { count: 1, text: 'Edit' }
            end
            assert_select row, 'td:nth-child(7)' do
              assert_select "a:match('href', ?)",
                            memberships_url,
                            { count: 1, text: 'Memberships' }
            end
          end
        end
      end
    end
  end

  test 'can go from listing to editing memberships' do
    do_valid_login
    get groups_path
    assert_response :success
    get group_memberships_path(@owned_group, and_save: true),
        headers: { 'HTTP_REFERER' => groups_path }
    assert_response :success
    assert_select '.zftable' do
      assert_select 'tbody' do
        assert_select 'tr', 3 do |rows|
        end
      end
    end
    listing_url = /\A\/groups\Z/
    assert_select "a:match('href', ?)",
                  listing_url,
                  { count: 1, text: 'Back to group listing' }
  end

  test 'deleting a membership takes us back to the listing' do
    do_valid_login
    #
    #  Not just back to the listing of memberships, but with a link to
    #  get back to our group listing.
    #
    #  Need to get the memberships listing first in order
    #  to prime the session with where we are to go back to.
    #
    get group_memberships_path(@owned_group, and_save: true),
        headers: { 'HTTP_REFERER' => groups_path(mine: true) }
    assert_response :success
    membership1 = @owned_group.memberships[0]
    delete membership_path(membership1),
      headers: { 'HTTP_REFERER' => group_memberships_path(@owned_group, and_save: true) }
    #
    #  Note that we expect our redirect not to have the and_save bit
    #  on it.  This is quite important because otherwise we will end
    #  up in a loop.
    #
    assert_redirected_to group_memberships_path(@owned_group)
    follow_redirect!
    assert_response :success
    assert_select "div.row" do
      assert_select "h1", text: /\AMembership records for/
#      assert_select "a", 8 do |links|
#        puts links.last['href']
#        puts links.last.text
#      end
      #
      #  Note that the "mine" bit should have been preserved from
      #  the start of this test.
      #
      #  assert_select seems to be a bit odd.  If I ask NokoGiri
      #  directly for the href (as commented out above) it returns
      #  the full href with options - "/groups?mine=true", but
      #  the assert_select matcher matches only the base URL.
      #
      #  I need to check the options for myself.
      #
      assert_select "a:match('href', ?)",
                    groups_path,
                    { count: 1, text: 'Back to group listing' } do |links|
        assert_equal '/groups?mine=true',  links.first['href']
      end
    end
  end

  test 'cloning a group takes us to editing then back to listing' do
    do_valid_login
    #
    #  This initial get should prime our session with where to go back
    #  to.
    #
    get edit_group_path(@owned_group),
        headers: { 'HTTP_REFERER' => groups_path(mine: true) }
    assert_response :success
    #
    #  Should be a link to clone it.
    #
    assert_select "a:match('href', ?)",
                  do_clone_group_path(@owned_group),
                  { count: 1, text: 'Clone' }
    #
    #  So try actually cloning it.
    #
    post do_clone_group_path(@owned_group)
    assert_redirected_to edit_group_path(Group.last, just_created: true)
    follow_redirect!
    #
    #  And now, submitting the form should go back to our group listing,
    #  not back to editing the other group.
    #
    put group_path(Group.last), params: { group: { name: "My clone" } }
    assert_redirected_to groups_path(mine: true)
  end

  private 

  #
  #  Note that we're using a test-specific path to login - not available
  #  in development or production mode.  We're not testing the login
  #  functionality; we just need a really easy way to get to a state
  #  of "logged in" so we can do our other testing.
  #
  def do_valid_login(user = @ordinary_user)
    put test_login_path(user_id: user.id)
    assert_redirected_to '/'
  end

end

