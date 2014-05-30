class Tutorgroup < ActiveRecord::Base

  validates :name,  presence: true
  validates :house, presence: true
  validates :staff, presence: true
  validates :era,   presence: true

  belongs_to :staff
  belongs_to :era

  has_one :element, :as => :entity, :dependent => :destroy

  include Grouping

  self.per_page = 15
  def active
    true
  end

  def element_name
    name
  end
end
