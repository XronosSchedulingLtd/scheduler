# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2021 John Winters
# See COPYING and LICENCE in the root directory of the application
# for more information.

require 'csv'

module Elemental
  extend ActiveSupport::Concern

  included do
    has_one :element, :as => :entity, :dependent => :destroy

    after_save :update_element

    #
    #  Solely for the demo environment, we allow the specification
    #  of a pre-selected UUID.
    #
    attr_writer :preferred_uuid

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

    #
    #  An entity may have a database field called "multicover" which leads
    #  to the creation of a method multicover?  We need to make sure we
    #  don't override it.
    #
    #  Other similar items further down this file (like can_have_requests)
    #  don't need to be defined in such a convoluted way because they
    #  don't refer to database columns.
    #
    unless self.column_names.include?("multicover")
      def multicover?
        false
      end
    end

  end

  module ClassMethods
    def a_person?
      false
    end
  end

  def a_person?
    self.class.a_person?
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
        if instance_variable_defined?(:@new_force_colour)
          self.element.force_colour = @new_force_colour
          do_save = true
        end
        if instance_variable_defined?(:@new_force_weight)
          self.element.force_weight = @new_force_weight
          do_save = true
        end
        if instance_variable_defined?(:@new_viewable)
          self.element.viewable = @new_viewable
          do_save = true
        end
        if do_save
          self.element.save!
        end
      else
        #
        #  An inactive entity shouldn't have an element.
        #
        self.element.destroy
        #
        #  There is still a copy of the element in memory, and it's
        #  just possible that we might, for instance, try to create
        #  a membership record with it later.  Disconnect from
        #  it.
        #
        self.element = nil
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
        if instance_variable_defined?(:@new_force_colour)
          creation_hash[:force_colour] = @new_force_colour
        end
        if instance_variable_defined?(:@new_force_weight)
          creation_hash[:force_weight] = @new_force_weight
        end
        if @preferred_uuid
          creation_hash[:preferred_uuid] = @preferred_uuid
        end
        if instance_variable_defined?(:@new_viewable)
          creation_hash[:viewable] = @new_viewable
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
    true
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
  #  Overridden in entities which can in fact have requests.
  #
  def can_have_requests?
    false
  end

  #
  #  Most entities don't effect locking, but ones which might should
  #  override this.
  #
  def can_lock?
    false
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
      if result == 0
        result = self.id <=> other.id
      end
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
    element_preferred_colour.blank? ? "" : element_preferred_colour
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

  def force_colour
    element_force_colour
  end

  def force_colour=(new_value)
    @new_force_colour = new_value
  end

  def force_weight
    element_force_weight
  end

  def force_weight=(new_value)
    @new_force_weight = new_value
  end

  def edit_viewable
    element_viewable
  end

  def edit_viewable=(new_value)
    #
    #  We are being given an explicit value for the viewable
    #  field in our element.
    #
    #  Generally we are given nothing, so it defaults to "true".
    #
    @new_viewable = new_value
  end

  def scan_for_clashes?
    false
  end

  private

  def element_preferred_colour
    if self.element
      self.element.preferred_colour
    else
      nil
    end
  end

  def element_force_colour
    self.element ? self.element.force_colour : false
  end

  def element_force_weight
    self.element ? self.element.force_weight : 0
  end

  def element_viewable
    self.element ?  self.element.viewable : true
  end

  def colours_effectively_the_same(a, b)
    (a.blank? && b.blank?) || (a == b)
  end
end
