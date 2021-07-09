require "application_system_test_case"

class AdHocDomainsTest < ApplicationSystemTestCase
  setup do
    @ad_hoc_domain = ad_hoc_domains(:one)
  end

  test "visiting the index" do
    visit ad_hoc_domains_url
    assert_selector "h1", text: "Ad Hoc Domains"
  end

  test "creating a Ad hoc domain" do
    visit ad_hoc_domains_url
    click_on "New Ad Hoc Domain"

    fill_in "Name", with: @ad_hoc_domain.name
    click_on "Create Ad hoc domain"

    assert_text "Ad hoc domain was successfully created"
    click_on "Back"
  end

  test "updating a Ad hoc domain" do
    visit ad_hoc_domains_url
    click_on "Edit", match: :first

    fill_in "Name", with: @ad_hoc_domain.name
    click_on "Update Ad hoc domain"

    assert_text "Ad hoc domain was successfully updated"
    click_on "Back"
  end

  test "destroying a Ad hoc domain" do
    visit ad_hoc_domains_url
    page.accept_confirm do
      click_on "Destroy", match: :first
    end

    assert_text "Ad hoc domain was successfully destroyed"
  end
end
