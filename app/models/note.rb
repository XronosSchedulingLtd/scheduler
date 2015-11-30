class Note < ActiveRecord::Base
  belongs_to :parent, :polymorphic => true
  belongs_to :owner, :class_name => :User

  has_many :attachments, :dependent => :destroy

  validates :parent, presence: true
  validates :owner_id, uniqueness: { scope: [:parent_id, :parent_type] }
end
