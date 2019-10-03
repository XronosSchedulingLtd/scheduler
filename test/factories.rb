FactoryBot.define do
  factory :attachment do
    parent_id { 1 }
    parent_type { "MyString" }
    user_file_id { 1 }
  end

  factory :era do
    sequence(:name) { |n| "Era number #{n}" }
    starts_on       { Date.today }
    ends_on         { Date.today + 1.year }
  end

  factory :property do
    sequence(:name) { |n| "Property number #{n}" }
  end

#
#  If you try to create an element on its own, it will get a Property
#  as its entity.
#
  factory :element do
    sequence(:name) { |n| "Element number #{n}" }
    association :entity, factory: :property
  end

#
#  Note that we don't need to specify Element records within our
#  entities.  They will be added automatically when the entity is
#  saved to the database.
#
#  Here FactoryBot differs from fixtures.  With fixtures you need
#  to create the link explicitly because they go around the back of
#  the models and shove stuff in the database directly.
#
  factory :group do
    sequence(:name) { |n| "Group number #{n}" }
    era
    #
    #  I would really like to be able to pass the group's name to the
    #  element so it can have the same name, but this seems to be one
    #  of those things that is damn near impossible with FactoryBot -
    #  or maybe it's just not documented.
    #
    starts_on     { Date.today }
    add_attribute(:persona_class) { 'Vanillagrouppersona' }
    current { true }
  end

  factory :location do
    sequence(:name) { |n| "Location number #{n}" }
    active { true }
  end

  factory :staff do
    sequence(:name) { |n| "Staff member #{n}" }
    sequence(:initials) { |n| "SM#{n}" }
    active { true }
    current { true }
    teaches { true }
  end

  factory :pupil do
    sequence(:name) { |n| "Pupil #{n}" }
    current { true }
  end

  factory :service do
    sequence(:name) { |n| "Resource / Service #{n}" }
  end

  factory :subject do
    sequence(:name) { |n| "Subject #{n}" }
  end

  factory :user_profile do
    sequence(:name) { |n| "User profile #{n}" }
  end

  factory :user do
    sequence(:name) { |n| "User number #{n}" }
    sequence(:email) { |n| "user#{n}@myschool.org.uk" }
    #
    #  We have to be quite clever to allow privilege flags to be set
    #  via traits individually.  They all need to end up in the same
    #  hash.
    #
    #  First we create some transient variables with default values.
    #
    transient do
      permissions_admin      { false }
      permissions_editor     { false }
      permissions_privileged { false }
      permissions_api        { false }
      permissions_noter      { false }
      permissions_files      { false }
      permissions_su         { false }
    end

    #
    #  Then traits to allow us to change those values
    #
    trait :admin do
      permissions_admin { true }
    end

    trait :editor do
      permissions_editor { true }
    end

    trait :privileged do
      permissions_privileged { true }
    end

    trait :api do
      permissions_api { true }
    end

    trait :noter do
      permissions_noter { true }
    end

    trait :files do
      permissions_files { true }
    end

    trait :su do
      permissions_su { true }
    end

    firstday { 0 }
    user_profile { UserProfile.guest_profile }

    permissions do
      #
      #  And now use those transient values to build our
      #  permissions hash, all in one go.
      #
      hash = {}
      if permissions_admin
        hash[:admin] = true
      end
      if permissions_editor
        hash[:editor] = true
      end
      if permissions_privileged
        hash[:privileged] = true
      end
      if permissions_api
        hash[:can_api] = true
      end
      if permissions_noter
        hash[:can_add_notes] = true
      end
      if permissions_files
        hash[:can_has_files] = true
      end
      if permissions_su
        hash[:can_su] = true
      end
      hash
    end

    factory :admin_user, traits: [:admin]
    #
    #  In order to behave like the session controller when creating
    #  a new user record we need to call find_matching_resources too.
    #
    after(:create) do |u|
      u.find_matching_resources
    end
  end

  factory :concern_set do
    association :owner, factory: :user
    sequence(:name) { |n| "Concern set #{n}" }
  end

  factory :concern do
    user
    element
    colour { 'blue' }
  end

  factory :eventcategory do
    sequence(:name) { |n| "Event category #{n}" }
    pecking_order   { 10 }
    #
    #  And some sensible ordinary defaults
    #
    schoolwide             { false }
    publish                { true }
    unimportant            { false }
    #
    #  The rest have defaults in the d/b anyway.
    #
  end

  factory :eventsource do
    sequence(:name) { |n| "Event source #{n}" }
  end

  factory :event do
    sequence(:body) { |n| "Event #{n}" }
    eventcategory
    eventsource
    starts_at { Time.now }
    ends_at   { Time.now + 1.hour }
  end

  factory :note do
    association :parent, factory: :event
    contents { "Some random text in a note" }
  end

  factory :resourcegrouppersona do
  end

  factory :resourcegroup do
    sequence(:name) { |n| "Resource group #{n}" }
    era
    starts_on { Date.today }
    association :persona, factory: :resourcegrouppersona
  end

  factory :user_form do
    sequence(:name) { |n| "User form #{n}" }
  end

  factory :commitment do
    event
    element
  end

  factory :user_form_response do
    user_form
    association :parent, factory: :commitment
  end

  factory :comment do
    user
    association :parent, factory: :user_form_response
    body { "Hello there - I'm a comment" }
  end

  factory :request do
    element
    event
    quantity { 1 }
  end

  factory :user_file do
    association :owner, factory: :user
    file_info { DummyFileInfo.new }
  end

end

