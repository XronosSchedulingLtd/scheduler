class NotesController < ApplicationController

  #
  #  Needs to be called in the context of a parent - currently just an
  #  event.
  #
  def new
    @event = Event.find(params[:event_id])
    @note = Note.new
    @note.parent = @event
    @note.owner = current_user
    respond_to do |format|
      format.js
    end
  end

  def create
    @event = Event.find(params[:event_id])
    @note = Note.new(note_params)
    respond_to do |format|
      if @note.save
        @note.reload
        if @note.parent.instance_of?(Commitment)
          @event.journal_note_created(@note, current_user)
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
        @event.journal_note_updated(@note, current_user)
        if @note.parent.rejected || @note.parent.constraining
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

  def authorized?(action = action_name, resource = nil)
    (logged_in? && current_user.staff?)
  end

  def note_params
    params.require(:note).permit(:title, :contents, :parent_id, :parent_type, :owner_id, :visible_guest, :visible_staff, :visible_pupil, :note_type)
  end

end
