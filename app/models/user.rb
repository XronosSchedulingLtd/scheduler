# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2014 John Winters
# Portions Copyright (C) 2014 Abindon School
# See COPYING and LICENCE in the root directory of the application
# for more information.

class User < ActiveRecord::Base

  has_many :ownerships, :dependent => :destroy
  has_many :interests,  :dependent => :destroy

  after_save :find_matching_resources

  def known?
    self.ownerships.me.size > 0
  end

  def own_element
    self.ownerships.me[0]
  end

  #
  #  Could be made more efficient with an explicit d/b hit, but probably
  #  not worth it as each user is likely to own only a small number
  #  of elements.
  #
  def owns?(element)
    !!ownerships.detect {|o| o.element_id == element.id}
  end

  def groups
    ownerships.select {|o| o.element.entity_type == "Group"}.collect {|o| o.element.entity}
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
      user.email    = auth["info"]["email"]
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
          end
        end
      end
    end
  end

end
