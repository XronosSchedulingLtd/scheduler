# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2014 John Winters
# See COPYING and LICENCE in the root directory of the application
# for more information.

require 'csv'

module Elemental
  extend ActiveSupport::Concern

  included do
    has_one :element, :as => :entity, :dependent => :destroy

    after_save :update_element

    #
    #  An entity which wants to change the display columns for itself
    #  can either define DISPLAY_COLUMNS before including elemental,
    #  or it can override the display_columns() method below.
    #
    #  The symbols used here must match up with the ones expected
    #  by the methods in helpers/elements_helper.rb
    #
    #
    #  Arguably this stuff has no business being in the model, since it
    #  relates to display rather than to business logic, but it seems
    #  terribly natural to ask each elemental item what it would like
    #  displayed.
    #
    #  Note that none of the actual display code is provided here, just
    #  a list of what's wanted.
    #
    unless defined?(DISPLAY_COLUMNS)
      DISPLAY_COLUMNS = [:direct_groups, :indirect_groups, :dummy]
    end
  end

  module ClassMethods
  end

  #
  #  This method makes sure we keep our element record.
  #
  def update_element
    if self.element
      if self.active
        do_save = false
        if self.element.name != self.element_name ||
           self.element.current != self.current ||
           self.element.owner_id != self.entitys_owner_id ||
           self.element.add_directly? != self.add_directly?
          self.element.name         = self.element_name
          self.element.current      = self.current
          self.element.owner_id     = self.entitys_owner_id
          self.element.add_directly = self.add_directly?
          do_save = true
        end
        if @new_preferred_colour
          #
          #  Someone has explicitly requested a change.
          #
          unless colours_effectively_the_same(@new_preferred_colour,
                                              self.element.preferred_colour)
            if @new_preferred_colour.blank?
              self.element.preferred_colour = nil
            else
              self.element.preferred_colour = @new_preferred_colour
            end
            do_save = true
          end
        end
        if do_save
          self.element.save!
        end
      else
        #
        #  An inactive entity shouldn't have an element.
        #
        self.element.destroy
      end
    else
      if self.active
        creation_hash = {
          name:         self.element_name,
          current:      self.current,
          add_directly: self.add_directly?
        }
        if self.respond_to?(:entitys_owner_id)
          creation_hash[:owner_id] = self.entitys_owner_id
        end
        if @new_preferred_colour
          creation_hash[:preferred_colour] = @new_preferred_colour
        end
        self.adjust_element_creation_hash(creation_hash)
        begin
          self.create_element!(creation_hash)
        rescue ActiveRecord::RecordNotUnique => e
          Rails.logger.error("Failed to create element for #{self.class}")
          #
          #  Unfortunately we still need to raise an error, because it's
          #  the only way now to stop our parent entity record being
          #  created.
          #
          #  There is a long standing bug in ActiveRecord which comes
          #  and goes, but can result in the record having an id, even
          #  though we raise an error and thus cause a rollback.
          #
          #  Set it back to nil ourselves.
          #
          self.id = nil
          raise "Couldn't create Element."
        end
      end
    end
  end

  def display_columns
    self.class::DISPLAY_COLUMNS
  end

  #
  #  A method to assist in the sorting of mixed entity types.
  #
  def sort_by_entity_type(other)
    own_name = self.class.name
    other_name = other.class.name
    Element::SORT_ORDER_HASH[own_name] <=> Element::SORT_ORDER_HASH[other_name]
  end

  #
  #  An entity may well want to override these.
  #
  def show_historic_panels?
    true
  end

  #
  #  If an entity overrides this to true, then it needs to provide
  #  an extra_panels method to generate the panels as well.
  #
  def extra_panels?
    false
  end

  def add_directly?
    true
  end

  def display_name
    self.name
  end

  def short_name
    self.name
  end

  def more_type_info
    ""
  end

  def tabulate_name(columns)
    "<tr><td colspan='#{columns}'>#{self.element_name}</td></tr>".html_safe
  end

  def csv_name
    [self.element_name].to_csv
  end

  def adjust_element_creation_hash(creation_hash)
  end

  #
  #  Provide the name of the partial to use to render general information
  #  about this entity.  Usually this will be in the directory of the
  #  entity - e.g. "locations/general", but this one isn't.
  #
  def general_partial
    "empty"
  end

  #
  #  Give this method a slightly different name to avoid accidentally
  #  overriding ActiveRecord's method.
  #
  #  Entities which *do* have an owner id should then override this
  #  method.
  #
  def entitys_owner_id
    nil
  end

  #
  #  Default to sorting by entity type and then by name.
  #
  def <=>(other)
    result = sort_by_entity_type(other)
    if result == 0
      result = self.name <=> other.name
    end
    result
  end

  #
  #  Default description.
  #
  def description
    self.class.to_s
  end

  #
  #  And shims to provide access to the instance methods in Element
  #
  def groups(given_date = nil, recurse = true)
    if self.element
      self.element.groups(given_date, recurse)
    else
      Group.none
    end
  end

  def commitments_on(**args)
    if self.element
      self.element.commitments_on(args)
    else
      Commitment.none
    end
  end

  def commitments_during(**args)
    if self.element
      self.element.commitments_during(args)
    else
      Commitment.none
    end
  end

  def edit_preferred_colour
    element_preferred_colour
  end

  def edit_preferred_colour=(value)
    #
    #  Slight bit of jiggery-pokery here.
    #
    #  The element record uses a value of nil to indicate there is
    #  no preferred colour.  We however need to keep track of two
    #  similar-sounding but different cases.
    #
    #  * No preferred colour has been assigned.  I.e. this method
    #    has never been called.  The obvious thing to use for that is
    #    nil, since that's the effective default value of an instance
    #    variable.
    #
    #  * User has explicitly asked to remove the preferred colour.
    #    This will result in us receiving nil or "", but we store it
    #    as "", to indicate that we have an explicit change.
    #
    #  We set @new_preferred_colour only if we see an active change.
    #
    current_value = element_preferred_colour
    if current_value.blank?
      unless value.blank?
        @new_preferred_colour = value
      end
    else
      if value.blank?
        @new_preferred_colour = ""
      elsif current_value != value
        @new_preferred_colour = value
      end
    end
  end

  private

  def element_preferred_colour
    if self.element
      self.element.preferred_colour
    else
      nil
    end
  end

  def colours_effectively_the_same(a, b)
    (a.blank? && b.blank?) || (a == b)
  end
end
