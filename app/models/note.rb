# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2019 John Winters
# See COPYING and LICENCE in the root directory of the application
# for more information.
#
require 'uri'

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
  after_save :check_for_attachments, if: :contents_changed?

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

  def check_for_attachments
    #
    #  If we're in the middle of dealing with an attachment telling
    #  us that a userfile is going away, don't try to recreate our
    #  attachment set.
    #
    unless @userfile_going
      #
      #  An array of UserFiles to which we should be linked.
      #
      should_link_to = Array.new
      unless self.formatted_contents.blank?
        doc = Nokogiri::HTML::DocumentFragment.parse(self.formatted_contents)
        doc.css('a').each do |link|
          #
          #  Is this a link to a file within our system?  If so, then
          #  we need to create a corresponding attachment record.
          #
          uri = URI.parse(link[:href])
          #
          #  Is it on our host?
          #
          if uri.relative? || uri.host == Setting.dns_domain_name
            #
            #  Seems to be our host at least.
            #  Is it a link to a user file?
            #
            if uri.path =~ /^\/user_files\//
              #
              #  Looking hopeful.  Now need to extract the last part.
              #
              leaf = Pathname.new(uri.path).basename.to_s
              #
              #  And does that match one of our files?
              #
              user_file = UserFile.find_by(nanoid: leaf)
              if user_file
                should_link_to << user_file
              end
            end
          end
        end
      end
      #
      #  Now have a list of what we *should* be linked to.  Compare
      #  with reality, and adjust reality.
      #
      current_attachments = self.attachments.all.to_a # Force d/b hit
      current_attachments.each do |attachment|
        if should_link_to.include?(attachment.user_file)
          #
          #  This next line merely removes the user_file from the array.
          #
          should_link_to.delete(attachment.user_file)
        else
          attachment.destroy
        end
      end
      #
      #  And anything left in the should_link_to array needs to
      #  be added.
      #
      should_link_to.each do |user_file|
        self.attachments.create(user_file: user_file)
      end
    end
  end

  #
  #  Called to let us know that a UserFile is going away.  We should
  #  check our body text for references to either the file itself
  #  ("/user_files/<nanoid>") or its thumbnail ("/thumbnails/<nanoid>.png").
  #
  #  Thumbnail references are simply expunged.  References to the file
  #  are turned back from links to plain text with "(deleted)" added.
  #
  def userfile_going(nanoid)
    #
    #  Need to set a flag so that if we save ourselves we don't
    #  trigger the processing in the check_for_attachments method.
    #
    @userfile_going = true
    working = self.contents
    #
    #  First expunge any reference to the thumbnail.  This will be of
    #  the form:
    #
    #    [Thumbnail](/thumbnails/<nanoid>.png...)
    #
    #  There may or may not be text replacing the ellipsis. It is
    #  important that we actually match against our individual nanoid,
    #  because there could be more than one link in our text.
    #
    #  There is an interesting bijou bugette here, in that if there
    #  are any blank thumbnails in our text they will go, even if they
    #  don't relate to the file for which we are looking.
    #
    #  It's quite an edge case.  It requires two or more files linked
    #  within the note, where one has been set up with
    #  a thumbnail, even though it has no thumbnail.  What we lose
    #  is a blank thumbnail.  Arguably it should never have been
    #  there.  I'll live with it.
    #
    matcher1 = /!\[Thumbnail\]\(\/thumbnails\/(#{nanoid}|blank48)\.png.*?\)/
    working = working.gsub(matcher1, '')
    #
    #  And now the actual file link
    #
    #  This should be of the form
    #
    #    [Some text](/user_files/<nanoid>)
    #
    #  and we want to keep "Some text" for later use.
    #
    #  Note the danger of having two such file links on the same line
    #  and searching for the second one.  We would match the initial
    #  '[' from the first one, and then the end of the second one.
    #  For that reason, our non-greedy matcher needs to exclude ']'
    #  as an acceptable character.
    #
    #    [^\]]*?  means "zero or more instances of any character
    #                    other than ], in a non-greedy way"
    #
    matcher2 = /\[([^\]]*?)\]\(\/user_files\/#{nanoid}\)/
    working = working.sub(matcher2, '\1 (File deleted)')
    if working != self.contents
      self.contents = working
      self.save
    end
    @userfile_going = false
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
