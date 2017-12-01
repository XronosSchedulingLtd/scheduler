class UserProfile < ActiveRecord::Base

  include Permissions

  has_many :users
  serialize :permissions, PermissionFlags

  validates :name, presence: true

  after_save :update_users

  self.per_page = 20

  def can_destroy?
    false
  end

  def update_users
    self.users.each do |u|
      u.user_profile_updated
    end
  end

  def self.staff_profile
    @staff_profile ||= UserProfile.find_by(name: "Staff")
  end

  def self.pupil_profile
    @pupil_profile ||= UserProfile.find_by(name: "Pupil")
  end

  def self.guest_profile
    @guest_profile ||= UserProfile.find_by(name: "Guest")
  end

  def self.ensure_basic_profiles
    #
    #  The system requires a minimum of 3 user profiles.
    #  Staff, Pupil and Guest.
    #
    #  Because we send these down to the browser as strings,
    #  we store them as strings too.  "0" means no, "1" means yes.
    #
    #  Anything which we don't set will default to "0".
    #
    self.create!({
      name: "Staff",
      permissions: {
        editor:            "1",
        can_add_resources: "1",
        can_add_notes:     "1",
        can_has_groups:    "1",
        public_groups:     "1",
        can_find_free:     "1",
        can_add_concerns:  "1",
        can_roam:          "1"
      }
    })
    self.create!({
      name: "Pupil",
      permissions: {
        editor:            "1",
        can_find_free:     "1"
      }
    })
    self.create!({
      name: "Guest"
    })
  end
end
