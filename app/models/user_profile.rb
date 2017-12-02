class UserProfile < ActiveRecord::Base

  include Permissions

  has_many :users
  serialize :permissions, PermissionFlags

  validates :name, presence: true

  after_save :update_users

  self.per_page = 20

  #
  #  You can't delete the three fundamental ones, and you can't
  #  delete any which are in use.
  #
  def can_destroy?
    !(self.name == "Staff" ||
      self.name == "Pupil" ||
      self.name == "Guest" ||
      self.users.count > 0)
  end

  def can_rename?
    !(self.name == "Staff" ||
      self.name == "Pupil" ||
      self.name == "Guest")
  end

  def do_clone
    new_user_profile = self.dup
    new_user_profile.name = "Copy of #{self.name}"
    new_user_profile.save!
    new_user_profile.reload
    new_user_profile
  end

  def update_users
    self.class.purge_cache
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

  def self.purge_cache
    @staff_profile = nil
    @pupil_profile = nil
    @guest_profile = nil
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
      name: "Pupil"
    })
    self.create!({
      name: "Guest"
    })
  end
end
