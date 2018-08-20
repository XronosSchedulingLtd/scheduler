# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2016 John Winters
# See COPYING and LICENCE in the root directory of the application
# for more information.

class Location < ActiveRecord::Base

  validates :name, presence: true

  has_many :locationaliases, :dependent => :nullify

  include Elemental

  self.per_page = 15

  scope :active, -> { where(active: true) }
  scope :current, -> { where(current: true) }

  scope :owned, -> { joins(:element).where("elements.owned = ?", true) }

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

  def description_line
    if locationaliases.size > 0
      "A location, also known as:<ul>#{locationaliases.collect {|la| la.name}.sort.uniq.collect {|n| "<li>#{n}</li>"}.join }</ul>".html_safe
    else
      "A location"
    end
  end

  def other_alias_names
    locationaliases.where(display: false).collect {|oa| oa.name}
  end

  def display_name
    self.element_name
  end

  #
  #  Where to find a partial to display general information about this
  #  elemental item.
  #
  def general_partial
    "locations/general"
  end

  def owned?
    self.element && self.element.owned?
  end

  def friendly_name
    friendly_alias = locationaliases.detect {|la| la.friendly}
    if friendly_alias
      friendly_alias.name
    else
      self.name
    end
  end

  def <=>(other)
    self.name <=> other.name
  end

  def can_destroy?
    !self.active || (self.element.commitments.count == 0)
  end

  #
  #  Locations are sometimes presented to users with a compound name.
  #  For instance, we have "GICT", which has an alias of "Greening
  #  Wing ICT", and is presented as "GICT / Greening Wing ICT".
  #
  #  Users not unreasonably expect to be able to give any of those names
  #  when asking for a room.  The GUI avoids the problem by providing
  #  lists / autocompletion, but sometimes they need to be expressed in
  #  files.
  #
  def self.find_generously(name)
    #
    #  Go for the actual location name first.
    #
    location = Location.find_by(name: name)
    unless location
      #
      #  How about an alias?
      #
      la = Locationalias.find_by(name: name)
      if la && la.location
        location = la.location
      else
        #
        #  OK - compound name, but it must be a location.
        #
        le = Element.find_by(name: name, entity_type: "Location")
        if le
          location = le.entity
        end
      end
    end
    location
  end

  #
  #  A maintenance method (although one might make it available through
  #  the web interface) to merge two locations.  The one on which it is
  #  called absorbs the other, which means it takes over the other's:
  #
  #  * Aliases
  #  * Commitments
  #
  #  And then the other one is deleted.  You can pass either a location,
  #  or the name of a location.
  #
  def absorb(other)
    messages = Array.new
    if other.instance_of?(String)
      other_location = Location.find_by(name: other)
      if other_location
        other = other_location
      else
        messages << "Can't find location #{other}."
      end
    end
    if other.instance_of?(Location)
      if other.id == self.id
        messages << "A location can't absorb itself."
      else
        #
        #  Go for it.
        #
        other_element = other.element
        own_element   = self.element
        commitments_taken = 0
        aliases_taken     = 0
        other_element.commitments.each do |commitment|
          #
          #  It's just possible that both locations are committed to the
          #  same event.
          #
          if own_element.commitments.detect {|c| c.event_id == commitment.event_id}
            messages << "Both committed to same event.  Dropping other commitment."
            commitment.destroy
          else
            commitment.element = self.element
            commitment.save!
            commitments_taken += 1
            own_element.reload
          end
        end
        other.locationaliases.each do |la|
          la.location = self
          la.save!
          aliases_taken += 1
        end
        messages << "Absorbed #{commitments_taken} commitments and #{aliases_taken} aliases."
        other.reload
        if other.locationaliases.size == 0 &&
           other.element.commitments.size == 0
           messages << "Deleting #{other.name}"
          other.destroy
        else
          messages << "Odd - #{other.name} still has #{other.locationaliases.size} location aliases, and #{other.element.commitments.size} commitments."
        end
      end
    else
      messages << "Must pass another location to absorb."
    end
    messages.each do |message|
      puts message
    end
    nil
  end

end
