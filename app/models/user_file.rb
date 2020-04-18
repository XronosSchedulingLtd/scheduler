#
# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2020 John Winters
# See COPYING and LICENCE in the root directory of the application
# for more information.
#

require 'digest'

class UserFile < ActiveRecord::Base

  before_destroy :remove_file_on_disk
  before_create  :add_nanoid
  after_create   :copy_to_disk

  belongs_to :owner, class_name: :User

  has_many :attachments, dependent: :destroy

  validates :file_info, presence: true

  validates :nanoid, uniqueness: true

  MAX_SHORT_FILENAME_LEN = 10

  def file_info=(incoming_data)
    self.original_file_name = incoming_data.original_filename
    self.file_size = incoming_data.size
    @incoming_file_info = incoming_data
  end

  def file_info
    @incoming_file_info
  end

  def nanoid=(value)
    #
    #  Client code is not allowed to modify the nanoid.
    #
  end

  #
  #  These next two are for when we want to access the files/thumbnails
  #  from within our code.  Here we need the full absolute path.
  #
  def file_full_path_name
    Rails.root.join(Setting.user_files_dir,
                    "#{self.owner_id}",
                    "#{self.id}.dat")
  end

  def thumbnail_full_path_name
    Rails.root.join('public/thumbnails',
                    "#{self.nanoid}.png")
  end

  #
  #  It's just possible that our underlying file might disappear from
  #  the filing system for one reason or another.
  #
  def file_exists?
    File.exists?(file_full_path_name)
  end

  def thumbnail_exists?
    File.exists?(thumbnail_full_path_name)
  end

  #
  #  And these next two give the relative path for referring to a thumbnail
  #  within a web page.  The path given will be sent to the web server
  #  to retrieve the required item.
  #
  #  This is where the thumbnail *would* be, if it exists.
  #  Calling code is responsible for checking that it does.
  #
  def thumbnail_relative_path_name
    "/thumbnails/#{self.nanoid}.png"
  end

  #
  #  For use in a JSON response
  #  We give the path to a thumbnail if it exists, or to a default
  #  blank if it doesn't.
  #
  def thumbnail_path
    if thumbnail_exists?
      thumbnail_relative_path_name
    else
      '/thumbnails/blank48.png'
    end
  end

  def short_name
    if original_file_name.size > MAX_SHORT_FILENAME_LEN
      "#{original_file_name[0, MAX_SHORT_FILENAME_LEN - 3]}..."
    else
      original_file_name
    end
  end

  #
  #  Used by the test suite to tidy up.
  #
  def self.user_files_dir_path
    Rails.root.join(Setting.user_files_dir)
  end

  #
  #  Invoked by a cron job to check for instances of our underlying
  #  files going away.  If any like that are found, the corresponding
  #  database record needs to be removed too.
  #
  #  We deliberately generate output if we find one which has.
  #
  def self.check_for_missing
    to_delete = Array.new
    UserFile.find_each do |uf|
      unless uf.file_exists?
        to_delete << uf
      end
    end
    unless to_delete.empty?
      puts "Found #{to_delete.count} UserFiles missing their underlying files"
      to_delete.each do |uf|
        puts "  #{uf.original_file_name} belonging to #{uf.owner.name}."
        uf.destroy
      end
    end
  end

  private

  def ensure_directory
    path = Rails.root.join(Setting.user_files_dir, "#{self.owner_id}")
    unless File.directory?(path)
      Dir.mkdir(path)
    end
  end

  def unlink_if_exists(path_name)
    File.unlink(path_name) if File.exists?(path_name)
  end

  def remove_file_on_disk
    unlink_if_exists(file_full_path_name)
    unlink_if_exists(thumbnail_full_path_name)
  end

  def copy_to_disk
    ensure_directory
    File.open(file_full_path_name, 'wb') do |file|
      file.write(file_info.read)
    end
    #
    #  And can we add a thumbnail?  May not succeed.
    #
    unless Thumbnailer.create(file_full_path_name, thumbnail_full_path_name)
      #
      #  Might have got as far as creating the thumbnail file.
      #
      unlink_if_exists(thumbnail_full_path_name)
    end
  end

  def add_nanoid
    #
    #  In theory we shouldn't get here if the record isn't valid, but...
    #
    if self.valid?
      generate_initial_nanoid
      #
      #  This seems really stupid, but surely we should have some
      #  code to cope with the possibility of a clash?
      #
      #  I don't want a loop in case of a coding error which means
      #  it turns into an endless loop.
      #
      #  If after a second attempt our record is still invalid
      #  (meaning the nanoid is still clashing with one already in
      #  the database) then the create!() (invoked from elemental.rb)
      #  will throw an error and the creation of the underlying
      #  element will be rolled back.  On the other hand, if you're
      #  that unlucky you're not going to live much longer anyway.
      #
      #  Note that by this point, the automatic Rails record validation
      #  has already been performed, and won't be performed again.
      #  The only thing which is going to stop the save succeeding
      #  is an actual constraint on the database - which is there.
      #
      #  This will also cope with the case where a caller has passed
      #  in an initial UUID, but it's not unique.  We will go on
      #  and generate a unique one.
      #
      unless self.valid?
        #
        #  At this point we have a nanoid but there is a problem with it.
        #  Force an overwrite by calling generate_nanoid directly.
        #
        generate_nanoid
      end
    end
  end

  def generate_initial_nanoid
    if self.nanoid.blank?
      generate_nanoid
    end
  end

  def generate_nanoid
    #
    #  Need to use write_attribute, because our setter method
    #  is overridden to do nothing.
    #
    write_attribute(:nanoid, Nanoid.generate(size: 12))
  end


end
