class ConcernSet < ActiveRecord::Base

  DefaultViewName = 'Default'

  has_many :concerns, dependent: :destroy
  has_one  :user_as_current,
           class_name: "User",
           foreign_key: :current_concern_set_id,
           dependent: :nullify

  belongs_to :owner, class_name: "User"

  validates_presence_of :name
  validates_presence_of :owner

  attribute :copy_concerns, Type::Boolean.new, default: true
  attribute :and_hide,      Type::Boolean.new, default: false

  #
  #  This exists as a method because it needs to be able to work out
  #  the number for the default set - where its id is 0.
  #
  def num_concerns
    if self.id == 0
      if self.owner
        self.owner.concerns.default_view.count
      else
        0
      end
    else
      self.concerns.count
    end
  end

end
