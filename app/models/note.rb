class Note < ActiveRecord::Base
  belongs_to :parent, :polymorphic => true
#  belongs_to :commitments, -> { where( notes: { parent_type: 'Commitment' } ).includes(:notes) }, foreign_key: 'parent_id'
  belongs_to :owner, :class_name => :User
  belongs_to :promptnote

  validates :parent, presence: true

  #
  #  Visibility values
  #
  VISIBLE_TO_ALL = 0

  def self.visible_to(user)
    if user && user.known?
      if user.staff?
        if user.element_owner
          #
          #  This is more complex, because an element owner can see
          #  notes attached to commitments relating to his element(s)
          #  even if they are not otherwise visible to staff.
          #
          owned_element_ids = user.concerns.owned.collect {|c| c.element_id}
          if owned_element_ids.empty?
            #
            #  Fall back to normal staff processing.
            #
            where("visible_staff = ? OR owner_id = ?", true, user.id)
          else
            #
            #  Alas, there seems to be no neat way of executing an OR
            #  condition in ActiveRecord.  I've tried all sorts of ways
            #  of expressing it, but been forced to fall back to SQL.
            #
            joins("INNER JOIN `commitments` ON `notes`.`parent_id` = `commitments`.`id`" ).
            where("(`notes`.`parent_type` = 'Commitment' AND `commitments`.`element_id` IN (?)) OR `notes`.`visible_staff` = ? OR `notes`.`owner_id` = ?",
                  owned_element_ids,
                  true,
                  user.id)
#            (joins("INNER JOIN `commitments` ON `notes`.`parent_id` = `commitments`.`id`" ).
#             where( :notes => { parent_type: 'Commitment' } ).
#             where( :commitments => { element_id: owned_element_ids } ).to_a +
#             where("visible_staff = ? OR owner_id = ?", true, user.id).to_a).uniq
          end
        else
          where("visible_staff = ? OR owner_id = ?", true, user.id)
        end
      else
        where("visible_pupil = ? OR owner_id = ?", true, user.id)
      end
    else
      where(visible_guest: true)
    end
  end

  def contents
    if read_attribute(:contents).blank? && self.promptnote
      self.promptnote.default_contents
    else
      read_attribute(:contents)
    end
  end
end
