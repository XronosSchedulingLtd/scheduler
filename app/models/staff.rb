class Staff < ActiveRecord::Base

  validates :name, presence: true

  has_one :element, :as => :entity, :dependent => :destroy
  has_one :tutorgroup 

  self.per_page = 15

  def element_name
    #
    #  A constructed name to pass to our element record.
    #
    "#{self.name} (Staff)"
  end

end
