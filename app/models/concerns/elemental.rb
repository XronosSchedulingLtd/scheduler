# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2014 John Winters
# Portions Copyright (C) 2014 Abindon School
# See COPYING and LICENCE in the root directory of the application
# for more information.

require 'csv'

module Elemental
  extend ActiveSupport::Concern

  included do
    has_one :element, :as => :entity, :dependent => :destroy

    after_save :update_element

  end

  module ClassMethods
  end

  #
  #  This method makes sure we keep our element record.
  #
  def update_element
    if self.element
      if self.active
        if self.element.name != self.element_name ||
           self.element.current != self.current ||
           self.element.owner_id != self.entitys_owner_id
          self.element.name     = self.element_name
          self.element.current  = self.current
          self.element.owner_id = self.entitys_owner_id
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
        creation_hash = { :name => self.element_name,
                          :current => self.current,
                          :entity => self }
        if self.respond_to?(:owner_id)
          creation_hash[:owner_id] = self.owner_id
        end
        self.adjust_element_creation_hash(creation_hash)
        Element.create!(creation_hash)
      end
    end
  end

  #
  #  An entity may well want to override these.
  #
  def display_name
    self.name
  end

  def short_name
    self.name
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
  #  Default to sorting by name.
  #
  def <=>(other)
    self.name <=> other.name
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
end
