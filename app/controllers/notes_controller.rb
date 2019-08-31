class NotesController < ApplicationController

  before_action :find_event, only: [:new, :create]

  #
  #  Needs to be called in the context of a parent - currently just an
  #  event.
  #
  def new
    @note = Note.new
    @note.parent = @event
    @note.owner = current_user
    @file_only = (params[:file_only] == 'true')
    respond_to do |format|
      format.js
    end
  end

  def create
    #
    #  Should this not be:
    #
    #  @note = @event.notes.new(note_params)?
    #
    #  How does the not get linked to its parent event?
    #
    #  It seems that the necessary info is in hidden fields within
    #  the note.  Is this a good idea?
    #
    @note = Note.new(note_params)
    respond_to do |format|
      if @note.save
        @note.reload
        if @note.parent.instance_of?(Commitment)
          @event.journal_note_created(@note, @note.parent, current_user)
        end
        @notes = @event.all_notes_for(current_user)
        format.js
      else
        @notes = @event.all_notes_for(current_user)
        format.js
      end
    end
  end

  def edit
    @note = Note.find(params[:id])
    @go_ahead = current_user.can_edit?(@note)
    parent = @note.parent
    if parent.instance_of?(Event)
      @event = parent
    else
      @event = parent.event
    end
    respond_to do |format|
      format.js
    end
  end

  def update
    @commitment_updated = false
    @note = Note.find(params[:id])
    parent = @note.parent
    if parent.instance_of?(Event)
      @event = parent
    else
      @event = parent.event
    end
    #
    #  If the user doesn't have permission to edit the note then
    #  I'm not quite sure how we got here.  He has somehow
    #  got himself into the edit dialogue, so try to get him
    #  out again.
    #
    if current_user.can_edit?(@note)
      @note.update(note_params)
      if @note.parent.instance_of?(Commitment)
        #
        #  Notes attached to commitments are part of the contract
        #  between user and approver.
        #
        @event.journal_note_updated(@note, @note.parent, current_user)
        if @note.parent.rejected? || @note.parent.constraining?
          @note.parent.revert_and_save!
          @event.journal_commitment_reset(@note.parent, current_user)
          @visible_commitments, @approvable_commitments =
            @event.commitments_for(current_user)
          @commitment_updated = true
        end
      end
    end
    @notes = @event.all_notes_for(current_user)
    respond_to do |format|
      format.js
    end
  end

  def destroy
    @note = Note.find(params[:id])
    parent = @note.parent
    if parent.instance_of?(Event)
      @event = parent
    else
      @event = parent.event
    end
    if current_user.can_delete?(@note)
      @note.destroy
    end
    @notes = @event.all_notes_for(current_user)
    respond_to do |format|
      format.js
    end
  end

  private

  def find_event
    @event = Event.find(params[:event_id])
  end

  def authorized?(action = action_name, resource = nil)
    #
    #  Any logged in user can have a go at updating a note (although
    #  the update method will apply further more detailed checks).
    #
    logged_in? &&
    (action == "update" ||
     action == "edit" ||
     current_user.can_add_notes?)
  end

  def note_params
    params.require(:note).permit(:title, :contents, :parent_id, :parent_type, :owner_id, :visible_guest, :visible_staff, :visible_pupil, :note_type)
  end

end
