# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2016 John Winters
# See COPYING and LICENCE in the root directory of the application
# for more information.
#
require 'csv'

#
#  A class which does the work of finding free resources of
#  a specified type.
#
#  Although this item has a database table (which defines its
#  fields) we don't actually ever save it to the database at
#  present.
#
#  Each freefinder is linked to an element, which should be a
#  group.  The group lists the candidates for us to find free
#  ones of.
#
class Freefinder < ActiveRecord::Base

  belongs_to :element

  attr_reader :free_elements, :done_search, :original_membership_size

  def element_name
    self.element ? self.element.name : ""
  end

  def element_name=(value)
    # Not interested
  end

  def start_time_text
    if self.start_time
      self.start_time.strftime("%H:%M")
    else
      ""
    end
  end

  def start_time_text=(value)
    self.start_time = Time.zone.parse(value)
  end

  def end_time_text
    if self.end_time
      self.end_time.strftime("%H:%M")
    else
      ""
    end
  end

  def end_time_text=(value)
    self.end_time = Time.zone.parse(value)
  end

  def on_text
    self.on ?
    self.on.strftime("%a #{self.on.day.ordinalize} %B, %Y") :
    "date not given"
  end

  def do_find(except_event = nil)
    #
    #  The very minimum which we need in order to do our work is a
    #  group with which to start.  If date and time aren't specified
    #  then each defaults to "now".
    #
    if self.element && self.element.entity.instance_of?(Group)
      target_group = self.element.entity
      #
      #  Need to convert separately specified dates and times (or possibly
      #  not specified) into two unified delimiters.
      #
      self.on ||= Date.today
      if self.start_time
        start_string = self.start_time.strftime("%H:%M:00")
      else
        start_string = Time.zone.now.strftime("%H:%M:00")
      end
      self.start_time = Time.zone.parse(start_string)
      if self.end_time
        end_string = self.end_time.strftime("%H:%M:00")
      else
        end_string = (self.start_time + 1.minute).strftime("%H:%M:00")
      end
      self.end_time = Time.zone.parse(end_string)
      if self.end_time <= self.start_time
        self.end_time = self.start_time + 1.minute
        end_string = self.end_time.strftime("%H:%M:00")
      end
      starts_at = Time.zone.parse(start_string, self.on)
      ends_at = Time.zone.parse(end_string, self.on)
      #
      #  Now - I need to have a list of all the all the atomic elements
      #  which were members of this group on the specified date.
      #
      member_elements =
        target_group.members(self.on, true, true).collect {|e| e.element}
      @original_membership_size = member_elements.size
      #
      #  And a list of all the events occuring at the specified time,
      #  from which we construct a list of all the elements committed to
      #  those events.
      #
      #  Note that, although the commitments_on method allows a list
      #  of resources to be specified, it only checks for commitments
      #  directly involving those resources.  Generally ours will be
      #  involved by way of a group membership, so we need to be
      #  slightly more long-winded.
      #
      overlapping_commitments =
        Commitment.commitments_during(
          start_time: starts_at,
          end_time: ends_at,
          excluded_category: Eventcategory.where(busy: false).to_a)
      if except_event
        overlapping_commitments =
          overlapping_commitments.where.not(event_id: except_event.id)
      end
      #
      #  Now I need a list of all the non-group entities referenced through
      #  these commitments.
      #
      committed_elements = Array.new
      overlapping_commitments.each do |oc|
        if oc.element.entity.instance_of?(Group)
          committed_elements += 
            oc.element.entity.members(self.on,
                                      true,
                                      true).collect {|e| e.element}
        else
          committed_elements << oc.element
        end
      end
      committed_elements = committed_elements.uniq
      #
      #  And now subtract
      #
      @free_elements = member_elements - committed_elements
      @done_search = true
    else
      errors.add(:element_name,
                 "The name of an existing group must be specified.")
    end
  end

  def to_csv
    if @done_search
      result = ["Checked #{self.element_name} for free resources"].to_csv
      result += ["On #{
                   self.on_text
                 } between #{
                   self.start_time_text
                 } and #{
                   self.end_time_text
                 }"].to_csv
      if @free_elements.size > 0
        @free_elements.sort.each do |element|
          result += element.csv_name
        end
      else
        result += "None found".to_csv
      end
      result
    else
      "Not searched yet".to_csv
    end
  end

  #
  #  Create a new group from this search, and return its id.
  #  Returns nil if we haven't created one.
  #
  def create_group(user)
    if @done_search && @free_elements.size > 0
      new_group = Vanillagroup.new
      new_group.starts_on = Date.today
      new_group.name = "Members of \"#{self.element_name}\" free on #{self.on_text} between #{self.start_time_text} and #{self.end_time_text}"
      new_group.era = Setting.current_era
      new_group.current = true
      new_group.owner = user
      new_group.save!
      new_group.reload
      @free_elements.each do |fe|
        new_group.add_member(fe)
      end
      new_group.id
    else
      errors.add(:overall, "Must find some results to create a group")
      nil
    end
  end

end
