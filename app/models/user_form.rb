class UserForm < ActiveRecord::Base

  belongs_to :created_by_user, class_name: :User
  belongs_to :edited_by_user, class_name: :User

  has_many :user_form_responses, dependent: :destroy

  validates :name, presence: true

  self.per_page = 15

  #
  #  Is it safe to destroy this form?
  #  Once we have UserFormData records then we won't want to destroy
  #  their parent.
  #
  def can_destroy?
    self.user_form_responses.count == 0
  end
end
