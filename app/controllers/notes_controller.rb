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
        @notes = @event.notes.visible_to(current_user)
        format.js
      else
        @notes = @event.notes.visible_to(current_user)
        format.js
      end
    end
  end

  def edit
    @note = Note.find(params[:id])
    respond_to do |format|
      format.js
    end
  end

  def update
    @note = Note.find(params[:id])
    @event = @note.parent
    respond_to do |format|
      if @note.update(note_params)
        @notes = @event.notes.visible_to(current_user)
        format.js
      else
        @notes = @event.notes.visible_to(current_user)
        format.js
      end
    end
  end

  def destroy
    @note = Note.find(params[:id])
    @event = @note.parent
    if current_user.can_edit?(@note)
      @note.destroy
    end
    @notes = @event.notes.visible_to(current_user)
    respond_to do |format|
      format.js
    end
  end

  private

  def authorized?(action = action_name, resource = nil)
    (logged_in? && current_user.known?)
  end

  def note_params
    params.require(:note).permit(:title, :contents, :parent_id, :parent_type, :owner_id, :visible_guest, :visible_staff, :visible_pupil, :note_type)
  end

end
