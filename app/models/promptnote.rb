class Promptnote < ActiveRecord::Base
  belongs_to :element
  has_many   :notes, :dependent => :nullify

  validates :element, presence: true

end
