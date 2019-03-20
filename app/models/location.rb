# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2020 John Winters
# See COPYING and LICENCE in the root directory of the application
# for more information.

class SubsidiaryValidator < ActiveModel::Validator

  def validate(record)
    #
    #  Can't have a circular hierarchy of subsidiaries.
    #
    if record.subsidiary_to
      if record.subsidiary_to == record
        record.errors[:subsidiary_to] << "can't be subsidiary to itself" 
      elsif record.superiors.include?(record)
        record.errors[:subsidiary_to] << "creates a subsidiary loop" 
      end
    end
  end

end

class Location < ApplicationRecord

  has_many :locationaliases, :dependent => :nullify

  #
  #  Locations can have a hierarchy of subsidiaries.
  #
  has_many :subsidiaries,
           foreign_key: :subsidiary_to_id,
           class_name: :Location,
           dependent: :nullify
  belongs_to :subsidiary_to, class_name: :Location

  validates :name, presence: true
  validates :num_invigilators, presence: true
  validates :weighting, presence: true
  validates :weighting, numericality: true
  validates_with SubsidiaryValidator

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
    displayaliases = locationaliases.with_display.sort
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

  def display_aliases
    locationaliases.with_display
  end

  def other_aliases
    locationaliases.non_display
  end

  def other_alias_names
    locationaliases.non_display.collect {|oa| oa.name}
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

  def subsidiary?
    !!self.subsidiary_to
  end

  def subsidiary_to_name
    if self.subsidiary_to
      self.subsidiary_to.element_name
    else
      ""
    end
  end

  def subsidiary_to_name=(name)
    #
    #  Ignore
    #
  end

  #
  #  Assemble a list of locations superior to this one.
  #
  #  Note that, although we don't allow loops, this method
  #  is used in the validation code to check for loops so it
  #  must cope with temporary loops.
  #
  #  Clients are not expected to pass in a parameter.  That's
  #  there for recursion purposes.
  #
  #  Note that Ruby passes arrays by reference, so modifications
  #  within a recursive call still get back to the caller.
  #  That means that our "seen" parameter may have been changed
  #  when we return from a recursive call, but that doesn't matter
  #  as we consult it only before the call.
  #
  #  If we ever modify this code to allow more than one subsidiary_to,
  #  then some use of dup will be required to rewind the changes.
  #
  def superiors(seen = [])
    result = []
    unless seen.include?(self)
      seen << self
      if self.subsidiary_to
        result << self.subsidiary_to
        result += self.subsidiary_to.superiors(seen)
      end
    end
    result
  end

end
