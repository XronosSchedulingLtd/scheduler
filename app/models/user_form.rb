class UserForm < ActiveRecord::Base

  belongs_to :created_by_user, class_name: :User
  belongs_to :edited_by_user, class_name: :User

  validates :name, presence: true
end
