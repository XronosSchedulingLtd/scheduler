class Location < ActiveRecord::Base

  validates :name, presence: true
  validates :short_name, presence: true

  has_one :element, :as => :entity, :dependent => :destroy

  self.per_page = 15

  def element_name
    #
    #  A constructed name to pass to our element record.
    #
    if self.name == self.short_name
      "#{self.name}"
    else
      "#{self.name} (#{self.short_name})"
    end
  end

end
