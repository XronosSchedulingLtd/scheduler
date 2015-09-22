# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2014 John Winters
# See COPYING and LICENCE in the root directory of the application
# for more information.

class User < ActiveRecord::Base

  DWI = Struct.new(:id, :name)
  DaysOfWeek = [DWI.new(0, "Sunday"),
                DWI.new(1, "Monday"),
                DWI.new(2, "Tuesday"),
                DWI.new(3, "Wednesday"),
                DWI.new(4, "Thursday"),
                DWI.new(5, "Friday"),
                DWI.new(6, "Saturday")]

  DECENT_COLOURS = [
                    "#483D8B",      # DarkSlateBlue
                    "#CD5C5C",      # IndianRed
                    "#B8860B",      # DarkGoldenRed (brown)
                    "#7B68EE",      # MediumSlateBlue
                    "#808000",      # Olive
                    "#6B8E23",      # OliveDrab
                    "#DB7093",      # PaleVioletRed
                    "#2E8B57",      # SeaGreen
                    "#A0522D",      # Sienna
                    "#008080",      # Teal
                    "#3CB371",      # MediumSeaGreen
                    "#2F4F4F",      # DarkSlateGray
                    "#556B2F",      # DarkOliveGreen
                    "#FF6347"]      # Tomato

  has_many :ownerships, :dependent => :destroy
  has_many :interests,  :dependent => :destroy
  has_many :concerns,   :dependent => :destroy

  has_many :events,   foreign_key: :owner_id

  belongs_to :preferred_event_category, class_name: Eventcategory

  #
  #  The only elements we can actually own currently are groups.  By creating
  #  a group with us as the owner, its corresponding element will also be
  #  marked as having us as the owner.  Should this user ever be deleted
  #  the owned groups will also be deleted, and thus the elements will go
  #  too.
  #
  has_many :elements, foreign_key: :owner_id
  has_many :groups,   foreign_key: :owner_id, :dependent => :destroy

  validates :firstday, :presence => true
  validates :firstday, :numericality => true

  scope :arranges_cover, lambda { where("arranges_cover = true") }

  after_save :find_matching_resources

  def known?
    @known ||= (self.own_element != nil)
  end

  def own_element
    unless @own_element
      my_own_concern = self.concerns.me[0]
      if my_own_concern
        @own_element = my_own_concern.element
      end
    end
    @own_element
  end

  def concern_with(element)
    possibles = Concern.between(self, element)
    if possibles.size == 1
      possibles[0]
    else
      nil
    end
  end

  #
  #  Could be made more efficient with an explicit d/b hit, but probably
  #  not worth it as each user is likely to own only a small number
  #  of elements.
  #
  def owns?(element)
    !!concerns.detect {|c| (c.element_id == element.id) && c.owns}
  end

  def free_colour
    available = DECENT_COLOURS - self.concerns.collect {|i| i.colour}
    if available.size > 0
      available[0]
    else
      "Gray"
    end
  end

  def list_days
    DaysOfWeek
  end

  def create_events?
    self.editor || self.admin
  end

  def create_groups?
    self.editor || self.admin
  end

  def can_trigger_cover_check?
    self.arranges_cover
  end

  #
  #  What elements do we control?  This information is cached because
  #  we may need it many times during the course of rendering one page.
  #
  def controlled_elements
    unless @controlled_elements
      @controlled_elements = self.concerns.controlling.collect {|c| c.element}
    end
    @controlled_elements
  end

  #
  #  Can this user edit the indicated item?
  #
  def can_edit?(item)
    if item.instance_of?(Event)
      self.admin ||
      (self.create_events? && item.owner_id == self.id) ||
      (self.create_events? && item.involves_any?(self.controlled_elements))
    else
      false
    end
  end

  def events_on(start_date = nil,
                end_date = nil,
                eventcategory = nil,
                eventsource = nil,
                include_nonexistent = false)
    Event.events_on(start_date,
                    end_date,
                    eventcategory,
                    eventsource,
                    nil,
                    self,
                    include_nonexistent)
  end
  #
  #  Create a new user record to match an omniauth authentication.
  #
  #  Anyone can have a user record, but only people with known Abingdon
  #  school e-mail addresses get any further than that.
  #
  def self.create_from_omniauth(auth)
    create! do |user|
      user.provider = auth["provider"]
      user.uid      = auth["uid"]
      user.name     = auth["info"]["name"]
      user.email    = auth["info"]["email"].downcase
    end
  end

  def find_matching_resources
    if self.email && !self.known?
      got_something = false
      staff = Staff.find_by_email(self.email)
      if staff
        got_something = true
        concern = self.concern_with(staff.element)
        if concern
          unless concern.owns
            concern.owns = true
            concern.save!
          end
        else
          Concern.create! do |concern|
            concern.user_id    = self.id
            concern.element_id = staff.element.id
            concern.equality   = true
            concern.owns       = true
            concern.visible    = true
            concern.colour     = "#225599"
          end
        end
      end
      pupil = Pupil.find_by_email(self.email)
      if pupil
        got_something = true
        concern = self.concern_with(pupil.element)
        if concern
          unless concern.owns
            concern.owns = true
            concern.save!
          end
        else
          Concern.create! do |concern|
            concern.user_id    = self.id
            concern.element_id = pupil.element.id
            concern.equality   = true
            concern.owns       = true
            concern.visible    = true
            concern.colour     = "#225599"
          end
        end
      end
      if got_something
        calendar_element = Element.find_by(name: "Calendar")
        if calendar_element
          unless self.concern_with(calendar_element)
            Concern.create! do |concern|
              concern.user_id    = self.id
              concern.element_id = calendar_element.id
              concern.equality   = false
              concern.owns       = false
              concern.visible    = true
              concern.colour     = calendar_element.preferred_colour || "green"
            end
          end
        end
      end
    end
  end

  def corresponding_staff
    if self.email
      Staff.find_by_email(self.email)
    else
      nil
    end
  end

  def initials
    if self.corresponding_staff
      self.corresponding_staff.initials
    else
      "UNK"
    end
  end

  #
  #  Retrieve our firstday value, coercing it to be meaningful.
  #
  def safe_firstday
    if self.firstday >=0 && self.firstday <= 6
      self.firstday
    else
      0
    end
  end

  #
  #  Maintenance method.  Set up a new concern record giving this user
  #  control of the indicated element.
  #
  def to_control(element_or_name, auto_add = false)
    if element_or_name.instance_of?(Element)
      element = element_or_name
    else
      element = Element.find_by(name: element_or_name)
    end
    if element
      concern = self.concern_with(element)
      if concern
        if concern.owns &&
           concern.controls &&
           concern.auto_add == auto_add
          "User #{self.name} already controlling #{element.name}."
        else
          concern.owns     = true
          concern.controls = true
          concern.auto_add = auto_add
          concern.save!
          "User #{self.name} promoted to controlling #{element.name}."
        end
      else
        concern = Concern.new
        concern.user    = self
        concern.element = element
        concern.equality = false
        concern.owns     = true
        concern.visible  = true
        concern.colour   = element.preferred_colour || self.free_colour
        concern.auto_add = auto_add
        concern.controls = true
        concern.save!
        "User #{self.name} now controlling #{element.name}."
      end
    else
      "Can't find element #{element_or_name} for #{self.name} to control."
    end
  end

  #
  #  Similar, but only a general interest.
  #
  def to_view(element_or_name, visible = false)
    if element_or_name.instance_of?(Element)
      element = element_or_name
    else
      element = Element.find_by(name: element_or_name)
    end
    if element
      concern = self.concern_with(element)
      if concern
        #
        #  Already has a concern.  Just make sure the colour is right.
        #
        if element.preferred_colour &&
           concern.colour != element.preferred_colour
          concern.colour = element.preferred_colour
          concern.save!
          "Adjusted colour of #{element.name} for #{self.name}."
        else
          ""
        end
      else
        concern = Concern.new
        concern.user    = self
        concern.element = element
        concern.equality = false
        concern.owns     = false
        concern.visible  = visible
        concern.colour   = element.preferred_colour || self.free_colour
        concern.auto_add = false
        concern.controls = false
        concern.save!
        "User #{self.name} now viewing #{element.name}."
      end
    else
      "Can't find element #{element_or_name} for #{self.name} to view."
    end
  end
end
