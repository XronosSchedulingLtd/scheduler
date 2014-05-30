class Teachinggroup < ActiveRecord::Base

  validates :name,  presence: true
  validates :era,   presence: true

  belongs_to :era

  include Elemental
  include Grouping

  self.per_page = 15
  def active
    true
  end

  def element_name
    name
  end

end
