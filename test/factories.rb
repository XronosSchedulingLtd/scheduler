FactoryBot.define do
  factory :era do
    sequence(:name) { |n| "Era number #{n}" }
    starts_on       { Date.today }
    ends_on         { Date.today + 1.year }
  end
end

FactoryBot.define do
  factory :property do
    sequence(:name) { |n| "Property number #{n}" }
  end
end

#
#  If you try to create an element on its own, it will get a Property
#  as its entity.
#
FactoryBot.define do
  factory :element do
    sequence(:name) { |n| "Element number #{n}" }
    association :entity, factory: :property
  end
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
FactoryBot.define do
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
  end
end

FactoryBot.define do
  factory :location do
    sequence(:name) { |n| "Location number #{n}" }
    active { true }
  end
end

FactoryBot.define do
  factory :staff do
    sequence(:name) { |n| "Staff member #{n}" }
    sequence(:initials) { |n| "SM#{n}" }
    active { true }
    current { true }
    teaches { true }
  end
end

FactoryBot.define do
  factory :pupil do
    sequence(:name) { |n| "Pupil #{n}" }
  end
end

FactoryBot.define do
  factory :service do
    sequence(:name) { |n| "Resource / Service #{n}" }
  end
end

FactoryBot.define do
  factory :user_profile do
    sequence(:name) { |n| "User profile #{n}" }
  end
end

FactoryBot.define do
  factory :user do
    firstday { 0 }
    user_profile
  end
end

FactoryBot.define do
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
end

FactoryBot.define do
  factory :eventsource do
    sequence(:name) { |n| "Event source #{n}" }
  end
end

FactoryBot.define do
  factory :event do
    sequence(:body) { |n| "Event #{n}" }
    eventcategory
    eventsource
    starts_at { Time.now }
    ends_at   { Time.now + 1.hour }
  end
end

FactoryBot.define do
  factory :resourcegrouppersona do
  end
end

FactoryBot.define do
  factory :resourcegroup do
    sequence(:name) { |n| "Resource group #{n}" }
    era
    starts_on { Date.today }
    association :persona, factory: :resourcegrouppersona
  end
end

FactoryBot.define do
  factory :user_form do
    sequence(:name) { |n| "User form #{n}" }
  end
end

FactoryBot.define do
  factory :commitment do
    event
    element
  end
end

FactoryBot.define do
  factory :user_form_response do
    user_form
    association :parent, factory: :commitment
  end
end

FactoryBot.define do
  factory :comment do
    user
    association :parent, factory: :user_form_response
    body { "Hello there - I'm a comment" }
  end
end

