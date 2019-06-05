require 'digest'

class UserFile < ActiveRecord::Base

  before_destroy :remove_file_on_disk
  before_create  :add_uuid
  after_create   :copy_to_disk

  belongs_to :owner, class_name: :User

  validates :file_info, presence: true
  validates :owner, presence: true

  validates :uuid, uniqueness: true

  def file_info=(incoming_data)
    self.original_file_name = incoming_data.original_filename
    self.file_size = incoming_data.size
    @incoming_file_info = incoming_data
  end

  def file_info
    @incoming_file_info
  end

  def uuid=(value)
    #
    #  Client code is not allowed to modify the uuid.
    #
  end

  def file_full_path_name
    Rails.root.join(Setting.user_files_dir,
                    "#{self.owner_id}",
                    "#{self.id}.dat")
  end

  def thumbnail_full_path_name
    Rails.root.join(Setting.user_files_dir,
                    "#{self.owner_id}",
                    "#{self.id}.png")
  end

  #
  #  Used by the test suite to tidy up.
  #
  def self.user_files_dir_path
    Rails.root.join(Setting.user_files_dir)
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
  end

  def add_uuid
    #
    #  In theory we shouldn't get here if the record isn't valid, but...
    #
    if self.valid?
      generate_initial_uuid
      #
      #  This seems really stupid, but surely we should have some
      #  code to cope with the possibility of a clash?
      #
      #  I don't want a loop in case of a coding error which means
      #  it turns into an endless loop.
      #
      #  If after a second attempt our record is still invalid
      #  (meaning the uuid is still clashing with one already in
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
        #  At this point we have a uuid but there is a problem with it.
        #  Force an overwrite by calling generate_uuid directly.
        #
        generate_uuid
      end
    end
  end

  def generate_initial_uuid
    if self.uuid.blank?
      generate_uuid
    end
  end

  def generate_uuid
    #
    #  Need to use write_attribute, because our setter method
    #  is overridden to do nothing.
    #
    write_attribute(:uuid, SecureRandom.uuid)
  end


end
