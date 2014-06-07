class Location < ActiveRecord::Base

  validates :name, presence: true

  has_many :locationaliases, :dependent => :nullify

  include Elemental

  self.per_page = 15

  scope :active, -> { where(active: true) }

  def element_name
    #
    #  A constructed name to pass to our element record.
    #
    #  We use the name which we have (should be a short name), plus any
    #  aliases flagged as of type "display", with any flagged as "friendly"
    #  last.
    #
    displayaliases = locationaliases.where(display: true).sort
    if displayaliases.size > 0
      ([self.name] + displayaliases.collect {|da| da.name}).join(" / ")
    else
      self.name
    end
  end

  def <=>(other)
    self.name <=> other.name
  end

end
