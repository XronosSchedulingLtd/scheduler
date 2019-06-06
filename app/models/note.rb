# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2019 John Winters
# See COPYING and LICENCE in the root directory of the application
# for more information.
#
class Note < ActiveRecord::Base
  belongs_to :parent, polymorphic: true
#  belongs_to :commitments, -> { where( notes: { parent_type: 'Commitment' } ).includes(:notes) }, foreign_key: 'parent_id'
  belongs_to :owner, class_name: :User
  belongs_to :promptnote
  has_many :attachments, as: :parent, dependent: :destroy
  has_many :user_files, through: :attachments

  validates :parent, presence: true

  scope :visible_guest, -> { where(visible_guest: true) }

  enum note_type: [ :ordinary, :clashes, :yaml ]

  before_save :format_contents

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
            #  Note that we need a LEFT JOIN rather than an INNER JOIN
            #  here, because we want the notes to be returned even when
            #  there is no matching commitments record.
            #
            joins("LEFT JOIN `commitments` ON `notes`.`parent_id` = `commitments`.`id`" ).
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

  def any_attachments?
    !self.attachments.empty?
  end

  #
  #  This used to be a database field, but it's now calculated
  #  dynamically.  To be read only, we need to have a prompt
  #  note and that prompt note needs to have the read only
  #  flag set.
  #
  def read_only
    self.promptnote && self.promptnote.read_only
  end

  def format_contents
    if self.contents.blank?
      self.formatted_contents = "<p></p>"
    else
      renderer = Redcarpet::Render::HTML.new(
        filter_html: true,
        hard_wrap: true,
        link_attributes: {
          target: '_blank',
          rel: 'noopener'
        }
      )
      original_html =
        Redcarpet::Markdown.new(renderer,
                                autolink: true, lax_spacing: true).
                                render(self.contents)
      #
      #  Want to make any links open a new page.
      #  This was my original way of doing it, but I think
      #  Redcarpet can do it all for me.
      #
#      doc = Nokogiri::HTML::DocumentFragment.parse(original_html)
#      doc.css('a').each do |link|
#        link['target'] = '_blank'
#        link['rel'] = 'noopener'
#      end
#      self.formatted_contents = doc.to_s
      self.formatted_contents = original_html
    end
  end

  def self.format_all_contents
    Note.all.each do |note|
      note.save
    end
  end

  def self.format_missing_contents
    Note.where(formatted_contents: nil).each do |note|
      note.save
    end
  end
end
