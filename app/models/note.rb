class Note < ActiveRecord::Base
  belongs_to :parent, :polymorphic => true
  belongs_to :owner, :class_name => :User

  validates :parent, presence: true

  #
  #  Visibility values
  #
  VISIBLE_TO_ALL = 0

  def self.visible_to(user)
    if user && user.known?
      if user.staff?
        where("visible_staff = ? OR owner_id = ?", true, user.id)
      else
        where("visible_pupil = ? OR owner_id = ?", true, user.id)
      end
    else
      where(visible_guest: true)
    end
  end
end
