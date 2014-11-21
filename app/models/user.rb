# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2014 John Winters
# See COPYING and LICENCE in the root directory of the application
# for more information.

class User < ActiveRecord::Base

  DECENT_COLOURS = ["#B8860B",      # DarkGoldenRed (brown)
                    "#556B2F",      # DarkOliveGreen
                    "#483D8B",      # DarkSlateBlue
                    "#2F4F4F",      # DarkSlateGray
                    "#CD5C5C",      # IndianRed
                    "#3CB371",      # MediumSeaGreen
                    "#7B68EE",      # MediumSlateBlue
                    "#808000",      # Olive
                    "#6B8E23",      # OliveDrab
                    "#DB7093",      # PaleVioletRed
                    "#2E8B57",      # SeaGreen
                    "#A0522D",      # Sienna
                    "#008080",      # Teal
                    "#FF6347"]      # Tomato

  has_many :ownerships, :dependent => :destroy
  has_many :interests,  :dependent => :destroy

  has_many :events,   foreign_key: :owner_id

  #
  #  The only elements we can actually own currently are groups.  By creating
  #  a group with us as the owner, its corresponding element will also be
  #  marked as having us as the owner.  Should this user ever be deleted
  #  the owned groups will also be deleted, and thus the elements will go
  #  too.
  #
  has_many :elements, foreign_key: :owner_id
  has_many :groups,   foreign_key: :owner_id, :dependent => :destroy

  scope :arranges_cover, lambda { where("arranges_cover = true") }

  after_save :find_matching_resources

  def known?
    @known ||= self.ownerships.me.size > 0
  end

  def own_element
    @own_element ||= self.ownerships.me[0].element
  end

  #
  #  Could be made more efficient with an explicit d/b hit, but probably
  #  not worth it as each user is likely to own only a small number
  #  of elements.
  #
  def owns?(element)
    !!ownerships.detect {|o| o.element_id == element.id}
  end

  def free_colour
    available = DECENT_COLOURS - self.interests.collect {|i| i.colour}
    if available.size > 0
      available[0]
    else
      "Gray"
    end
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
  #  Can this user edit the indicated item?
  #
  def can_edit?(item)
    if item.instance_of?(Event)
      self.admin || (self.create_events? && item.owner_id == self.id)
    else
      false
    end
  end

  def events_on(start_date = nil,
                end_date = nil,
                eventcategory = nil,
                eventsource = nil,
                and_by_group = true,
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
    if self.email
      staff = Staff.find_by_email(self.email)
      if staff
        #
        #  This could be made a lot more efficient with scopes and a
        #  direct d/b query, but since each user is liable to own at most
        #  about 5 resources, and usually only 1, it isn't really worth it.
        #
        unless ownerships.detect {|o| o.element_id == staff.element.id}
          Ownership.create! do |ownership|
            ownership.user_id    = self.id
            ownership.element_id = staff.element.id
            ownership.equality   = true
          end
        end
      end
      pupil = Pupil.find_by_email(self.email)
      if pupil
        #
        #  This could be made a lot more efficient with scopes and a
        #  direct d/b query, but since each user is liable to own at most
        #  about 5 resources, and usually only 1, it isn't really worth it.
        #
        unless ownerships.detect {|o| o.element_id == pupil.element.id}
          Ownership.create! do |ownership|
            ownership.user_id    = self.id
            ownership.element_id = pupil.element.id
            ownership.equality   = true
          end
        end
      end
    end
  end

end
