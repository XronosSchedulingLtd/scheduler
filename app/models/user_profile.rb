class UserProfile < ActiveRecord::Base
  include PermissionBits

  validates :name, presence: true

  self.per_page = 20

  def can_destroy?
    false
  end
end
