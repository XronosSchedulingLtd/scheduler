# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2015 John Winters
# See COPYING and LICENCE in the root directory of the application
# for more information.

class Concern < ActiveRecord::Base
  belongs_to :user
  belongs_to :element
  has_one    :itemreport, :dependent => :destroy

  validates :user,    :presence => true
  validates :element, :presence => true
  validates :element_id, uniqueness: { scope: :user_id }

  scope :me, -> {where(equality: true)}
  scope :not_me, -> {where.not(equality: true)}
  scope :owned, -> {where(owns: true)}
  scope :not_owned, -> {where.not(owns: true)}
  scope :skip_permissions, -> {where(skip_permissions: true)}
  scope :seek_permission, -> {where(seek_permission: true)}
  scope :controlling, -> {where(controls: true)}
  scope :not_controlling, -> {where.not(controls: true)}
  #
  #  ActiveRecord scopes are not good at OR conditions, so resort to SQL.
  #
  scope :can_commit, -> {where("(owns = ? OR skip_permissions = ?) AND seek_permission = ?", true, true, false)}

  scope :visible, -> { where(visible: true) }

  scope :between, ->(user, element) {where(user_id: user.id, element_id: element.id)}

  scope :auto_add, -> { where(auto_add: true) }

  after_save :update_after_save
  after_destroy :update_after_destroy

  #
  #  This isn't a real field in the d/b.  It exists to allow a name
  #  to be typed in the dialogue for creating a concern record,
  #  expressing interest in an element.
  #
  attr_accessor :name

  #
  #  Likewise, this isn't in the database either.  It is used for
  #  displaying faked concerns to non-logged-in users.
  #
  attr_accessor :fake_id

  def id_or_fake
    @fake_id ? @fake_id : self.id
  end

  #
  #  Concerns are sorted so that identities come first, then ownerships,
  #  then the rest.
  #
  def <=>(other)
    if self.equality
      if other.equality
        if self.owns
          if other.owns
            self.element <=> other.element
          else
            -1
          end
        else
          if other.owns
            1
          else
            self.element <=> other.element
          end
        end
      else
        -1
      end
    else
      if other.equality
        1
      else
        if self.owns
          if other.owns
            self.element <=> other.element
          else
            -1
          end
        else
          if other.owns
            1
          else
            self.element <=> other.element
          end
        end
      end
    end
  end

  #
  #  Can the relevant user delete this concern?
  #
  def user_can_delete?
    !(self.equality || self.owns || self.controls || self.skip_permissions)
  end

  #
  #  How many permissions are pending for the element pointed to by
  #  this concern?
  #
  def permissions_pending
    unless @permissions_pending
      if self.owns
        @permissions_pending = self.element.permissions_pending
      else
        @permissions_pending = 0
      end
    end
    @permissions_pending
  end

  #
  #  A maintenance method to clear up some unwanted ownership bits.
  #
  def self.tidy_ownerships
    messages = Array.new
    Concern.all.each do |concern|
      if concern.owns
        if concern.element.entity_type == "Staff" ||
           concern.element.entity_type == "Pupil"
          messages << "Removing ownership of #{concern.element.name} by #{concern.user.name}."
          concern.owns = false
          concern.save
        end
      end
    end
    #
    # Need to take the calendar away from Nick
    #
    u = User.find_by(name: "Nick Lloyd")
    e = Element.find_by(name: "Calendar")
    if u && e
      c = Concern.where(user_id: u.id).where(element_id: e.id).take
      if c
        if c.owns || c.controls
          c.owns = false
          c.controls = false
          c.save
          messages << "Removed Nick's control of the Calendar."
        else
          messages << "Already removed Nick's connection to the Calendar."
        end
      else
        messages << "Couldn't find concern connecting Nick to the Calendar."
      end
    else
      messages << "Couldn't find Nick Lloyd and/or Calendar."
    end
    Concern.owned.each do |concern|
      #
      #  Do a dummy save to cause the element and user to be updated
      #  as being owned/owners.
      #
      concern.save
    end
    Concern.owned.controlling.each do |concern|
      messages << "#{concern.user.name} owns and controls #{concern.element.name}."
    end
    Concern.owned.not_controlling.each do |concern|
      messages << "#{concern.user.name} owns #{concern.element.name}."
    end
    Concern.not_owned.controlling.each do |concern|
      messages << "#{concern.user.name} controls #{concern.element.name}."
    end
    messages.each do |message|
      puts message
    end
    nil
  end

  #
  #  Copy all the existing interest and ownership records as new
  #  concern records.
  #
#  def self.initial_creation
#    ownerships_copied = 0
#    ownerships_not_copied = 0
#    Ownership.all.each do |o|
#      existing = Concern.find_by(user_id: o.user_id, element_id: o.element_id)
#      if existing
#        puts "Not copying Ownership of #{o.user.name} in #{o.element.name}"
#        if o.equality && !existing.equality
#          existing.equality = true
#          existing.save!
#        end
#        ownerships_not_copied += 1
#      else
#        puts "Copying Ownership of #{o.user.name} in #{o.element.name}"
#        c = Concern.new
#        c.user     = o.user
#        c.element  = o.element
#        c.equality = o.equality
#        c.owns     = true
#        c.colour   = o.colour
#        c.visible  = true
#        c.save!
#        ownerships_copied += 1
#      end
#    end
#    interests_copied = 0
#    interests_not_copied = 0
#    Interest.all.each do |i|
#      existing = Concern.find_by(user_id: i.user_id, element_id: i.element_id)
#      if existing
#        puts "Not copying Interest of #{i.user.name} in #{i.element.name}"
#        interests_not_copied += 1
#      else
#        puts "Copying Interest of #{i.user.name} in #{i.element.name}"
#        c = Concern.new
#        c.user     = i.user
#        c.element  = i.element
#        c.equality = false
#        c.owns     = false
#        c.colour   = i.colour
#        c.visible  = i.visible
#        c.save!
#        interests_copied += 1
#      end
#    end
#    puts "Copied #{interests_copied} interests and #{ownerships_copied} ownerships."
#    puts "Didn't copy #{interests_not_copied} interests and #{ownerships_not_copied} ownerships."
#    nil
#  end

  protected

  def update_after_destroy
    if self.element
      self.element.update_ownedness(false)
    end
    if self.user
      self.user.update_owningness(false)
    end
  end

  def update_after_save
    if self.element
      self.element.update_ownedness(self.owns)
    end
    if self.user
      self.user.update_owningness(self.owns)
    end
  end

end
