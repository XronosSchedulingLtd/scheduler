require 'test_helper'

class UserFileTest < ActiveSupport::TestCase
  setup do
    @user = FactoryBot.create(:user)
    @file_info = DummyFileInfo.new
    @valid_params = {
      owner: @user,
      file_info: @file_info
    }
    @existing_file = FactoryBot.create(:user_file, owner: @user)
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

  test 'can create a user file' do
    assert_difference('UserFile.count') do
      user_file = UserFile.create(@valid_params)
      assert user_file.valid?
      assert File.exist?(user_file.file_full_path_name)
    end
  end

  test 'must have an owner' do
    user_file = UserFile.create(@valid_params.except(:owner))
    assert_not user_file.valid?
  end

  test 'must have file info' do
    user_file = UserFile.create(@valid_params.except(:file_info))
    assert_not user_file.valid?
  end

  test 'system_created defaults to false' do
    user_file = UserFile.create(@valid_params)
    assert_not user_file.system_created?
  end

  test 'system_created can be true' do
    user_file = UserFile.create(@valid_params.merge(system_created: true))
    assert user_file.system_created?
  end

  test 'can delete file' do
    assert @existing_file.valid?
    assert File.exist?(@existing_file.file_full_path_name)
    assert_difference('UserFile.count', -1) do
      @existing_file.destroy
    end
    assert_not File.exist?(@existing_file.file_full_path_name)
  end

end
