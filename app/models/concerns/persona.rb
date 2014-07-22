# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2014 John Winters
# Portions Copyright (C) 2014 Abindon School
# See COPYING and LICENCE in the root directory of the application
# for more information.

module Persona
  extend ActiveSupport::Concern

  included do
    has_one :group, :as => :persona

    after_initialize :set_flags
    after_save       :update_group
    #
    #  Note that there is little if any point in reading this next item.
    #  It exists purely to allow the value to be passed through when
    #  the record is created.
    #
#    attr_accessor :starts_on, :ends_on

  end

  module ClassMethods
  end

  #
  #  Keep track of whether we need to save our group record.
  #
  def set_flags
    @group_needs_saving = false
  end

  #
  #  This method makes sure we keep our group record.
  #
  def update_group
    if self.group
      if @group_needs_saving
        begin
          self.group.save!
          @group_needs_saving = false
        rescue
          errors[:base] << "Group: #{$!.to_s}"
          raise $!
        end
      end
    else
      #
      #  Use the bang version, so if creation of the Group fails
      #  then the error will propagate back up.
      #
      #  There is a problem in that I'm not sure how to propagate
      #  the error message back up too.
      #
      begin
        group = Group.create!(:visible_group => self,
                              :starts_on => self.starts_on,
                              :ends_on   => self.ends_on)
      rescue
        errors[:base] << "Group: #{$!.to_s}"
        raise $!
      end
    end
  end

  #
  #  And some instance methods to make it look like we actually have
  #  members.  All are shims to the real methods in the Group model.
  #
  def add_member(item, as_of = nil)
    group.add_member(item, as_of)
  end

  def remove_member(item, as_of = nil)
    group.remove_member(item, as_of)
  end

  def add_outcast(item, as_of = nil)
    group.add_outcast(item, as_of)
  end

  def remove_outcast(item, as_of = nil)
    group.remove_outcast(item, as_of)
  end

  def members(given_date = nil, recurse = true, exclude_groups = false)
    group.members(given_date, recurse, exclude_groups)
  end

  def final_members(given_date = nil, recurse = true, exclude_groups = false)
    group.final_members(given_date, recurse, exclude_groups)
  end

  def outcasts(given_date = nil, recurse = true)
    group.outcasts(given_date, recurse)
  end

  def member?(item, given_date = nil, recurse = true)
    group.member?(item, given_date, recurse)
  end

  def outcast?(item, given_date = nil, recurse = true)
    group.outcast?(item, given_date, recurse)
  end

  def active_on(date)
    group.active_on(date)
  end

  def ceases_existence(date)
    group.ceases_existence(date)
  end

  #
  #  We need to be able to set the value of starts_on and ends_on before
  #  the group record is created.  Once it exists, we go straight to
  #  the group record.
  #
  #  Note that we are trying to make the behaviour as much like it
  #  would be if these were a single record as possible.  Changing
  #  an instance variable does not in itself change the underlying
  #  database record.  Only if the client code then saves the record
  #  should the change persist.
  #
  def starts_on
    if group
      group.starts_on
    else
      @starts_on
    end
  end

  def starts_on=(value)
    if group
      if group.starts_on != value
        group.starts_on = value
        @group_needs_saving = true
      end
    else
      @starts_on = value
    end
  end

  def ends_on
    if group
      group.ends_on
    else
      @ends_on
    end
  end

  def ends_on=(value)
    if group
      if group.ends_on != value
        group.ends_on = value
        @group_needs_saving = true
      end
    else
      @ends_on = value
    end
  end

end
