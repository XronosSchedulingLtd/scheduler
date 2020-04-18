#
# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2020 John Winters
# See COPYING and LICENCE in the root directory of the application
# for more information.
#

require 'test_helper'

class NoteTest < ActiveSupport::TestCase
  setup do
    @event = FactoryBot.create(:event)
    @commitment = FactoryBot.create(:commitment)
    @user = FactoryBot.create(:user)
    @promptnote =
      FactoryBot.create(:promptnote, default_contents: "From a promptnote")
    @user_file = FactoryBot.create(:user_file)
    @valid_parameters = {
      parent: @event,
      contents: "#Heading\nHello world"
    }
    @staff = FactoryBot.create(:staff, email: "staff@myschool.org.uk")
    @staff_user = FactoryBot.create(:user, email: "staff@myschool.org.uk")
    @pupil = FactoryBot.create(:pupil, email: "pupil@myschool.org.uk")
    @pupil_user = FactoryBot.create(:user, email: "pupil@myschool.org.uk")
    @guest_user = FactoryBot.create(:user, email: "guest@myschool.org.uk")
  end

  test 'can create note' do
    note = Note.create(@valid_parameters)
    assert note.valid?
  end

  test 'note must have a parent' do
    note = Note.create(@valid_parameters.except(:parent))
    assert_not note.valid?
  end

  test 'parent could be a commitment' do
    note = Note.create(@valid_parameters.merge({parent: @commitment}))
    assert note.valid?
  end

  test 'can have an owner' do
    note = Note.create(@valid_parameters.merge({owner: @user}))
    assert note.valid?
  end

  test 'can link to a promptnote' do
    note = Note.create(@valid_parameters.merge({promptnote: @promptnote}))
    assert note.valid?
  end

  test 'can have attachments' do
    note = Note.create(@valid_parameters)
    attachment = note.attachments.create(user_file: @user_file)
    assert attachment.valid?
    assert_equal 1, note.attachments.count
    assert_equal 1, note.user_files.count
    assert note.any_attachments?
  end

  test 'contents get formatted' do
    note = Note.create(@valid_parameters)
    assert_equal "<h1>Heading</h1>\n\n<p>Hello world</p>\n",
      note.formatted_contents
  end

  test 'blank notes still get formatted contents' do
    note = Note.create({
      parent: @event,
      contents: nil
    })
    assert note.valid?
    assert_equal "<p></p>", note.formatted_contents
  end

  test 'file link in body text causes attachment' do
    note = Note.create(@valid_parameters.merge({
      contents: "[A file](/user_files/#{@user_file.nanoid})"
    }))
    assert_equal 1, note.attachments.count
    assert_equal @user_file, note.attachments[0].user_file
    assert note.any_attachments?
  end

  test 'visibility of notes' do
    #
    #  By default should be visible only to staff.
    #
    note = Note.create(@valid_parameters)
    assert     note.visible_staff?
    assert_not note.visible_pupil?
    assert_not note.visible_guest?
  end

  test 'can select by visibility' do
    num_pre_existing = Note.count
    note = Note.create(@valid_parameters)
    assert_equal num_pre_existing + 1, Note.visible_to(@staff_user).count
    assert_equal num_pre_existing, Note.visible_to(@pupil_user).count
    assert_equal num_pre_existing, Note.visible_to(@guest_user).count
  end

  test 'promptnote provides default contents' do
    note = @promptnote.notes.create(@valid_parameters.except(:contents))
    assert note.read_attribute(:contents).blank?
    assert_equal @promptnote.default_contents, note.contents
  end

  test 'can be read only' do
    note = Note.create(@valid_parameters)
    assert_not note.read_only
    @promptnote.read_only = true
    @promptnote.save
    note = @promptnote.notes.create(@valid_parameters)
    assert note.read_only
  end

  test 'deleting a linked user file modifies the note' do
    note = Note.create(@valid_parameters.merge({
      contents: "[A file](/user_files/#{@user_file.nanoid})"
    }))
    assert_equal 1, note.attachments.count
    assert_equal @user_file, note.attachments[0].user_file
    assert note.any_attachments?
    @user_file.destroy
    note.reload
    assert_equal 0, note.attachments.count
    assert_not note.any_attachments?
    assert_equal "A file (File deleted)", note.contents
    assert_equal "<p>A file (File deleted)</p>\n", note.formatted_contents
  end

end
