require 'test_helper'

class AttachmentTest < ActiveSupport::TestCase
  setup do
    UserProfile.ensure_basic_profiles
    @user = FactoryBot.create(:user)
    @file_info = DummyFileInfo.new
    @existing_file = FactoryBot.create(:user_file, owner: @user)
    @existing_note = FactoryBot.create(:note)
    @valid_params = {
      parent: @existing_note,
      user_file: @existing_file
    }

  end

  teardown do
    #
    #  Delete all directories within our UserFiles directory.
    #
    Pathname.new(UserFile.user_files_dir_path).children.each do |p|
      #
      #  Don't delete the .gitignore file.
      #
      if p.directory?
        p.rmtree
      end
    end
  end

  test 'can create an attachment' do
    assert_difference('Attachment.count') do
      attachment = Attachment.create(@valid_params)
      assert attachment.valid?
    end
  end

  test 'parent is needed' do
    attachment = Attachment.create(@valid_params.except(:parent))
    assert_not attachment.valid?
  end


  test 'user_file is needed' do
    attachment = Attachment.create(@valid_params.except(:user_file))
    assert_not attachment.valid?
  end


end
