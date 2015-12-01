class Attachment < ActiveRecord::Base
  belongs_to :parent, :polymorphic => true

  validates :note, :presence => true
  validates :original_file_name, :presence => true
end
