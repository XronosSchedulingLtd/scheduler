class User < ActiveRecord::Base

  has_many :ownerships, :dependent => :destroy

  after_save :find_matching_resources

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
    end
  end

end
