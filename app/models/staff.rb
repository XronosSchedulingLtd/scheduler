class Staff < ActiveRecord::Base

  validates :name, presence: true

  has_one :element, :as => :entity, :dependent => :destroy

  def element_name
    #
    #  A constructed name to pass to our element record.
    #
    "#{self.name} (Staff)"
  end

end
