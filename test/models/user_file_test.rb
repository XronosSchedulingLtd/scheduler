require 'test_helper'

class DummyFileInfo
  def original_filename
    "banana.png"
  end

  def read
    "Here is some data"
  end

  def size
    17
  end

end

class UserFileTest < ActiveSupport::TestCase
  setup do
    @user = FactoryBot.create(:user)
    @file_info = DummyFileInfo.new
    @valid_params = {
      owner: @user,
      file_info: @file_info
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

  test 'can create a user file' do
    user_file = UserFile.create(@valid_params)
    assert user_file.valid?
  end

  test 'must have an owner' do
    user_file = UserFile.create(@valid_params.except(:owner))
    assert_not user_file.valid?
  end

  test 'must have file info' do
    user_file = UserFile.create(@valid_params.except(:file_info))
    assert_not user_file.valid?
  end
end
