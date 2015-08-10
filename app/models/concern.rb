class Concern < ActiveRecord::Base
  belongs_to :user
  belongs_to :element

  validates :user,    :presence => true
  validates :element, :presence => true
  validates :element_id, uniqueness: { scope: :user_id }

  scope :me, -> {where(equality: true)}
  scope :not_me, -> {where.not(equality: true)}
  scope :owned, -> {where(owns: true)}
  scope :not_owned, -> {where.not(owns: true)}
  scope :controlling, -> {where(controls: true)}

  scope :visible, -> { where(visible: true) }

  scope :between, ->(user, element) {where(user_id: user.id, element_id: element.id)}

  scope :auto_add, -> { where(auto_add: true) }

  #
  #  This isn't a real field in the d/b.  It exists to allow a name
  #  to be typed in the dialogue for creating a concern record,
  #  expressing interest in an element.
  #
  def name
    @name 
  end

  def name=(n)
    @name = n
  end

  #
  #  Ownerships are sorted so that identities come first, then ownerships,
  #  then the rest.
  #
  def <=>(other)
    if self.equality
      if other.equality
        if self.owns
          if other.owns
            self.element.name <=> other.element.name
          else
            -1
          end
        else
          if other.ownership
            1
          else
            self.element.name <=> other.element.name
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
            self.element.name <=> other.element.name
          else
            -1
          end
        else
          if other.owns
            1
          else
            self.element.name <=> other.element.name
          end
        end
      end
    end
  end

  #
  #  Can the relevant user delete this concern?
  def user_can_delete?
    !(self.owns || self.controls)
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

end
