class NotesController < ApplicationController

  def create
    @note = Note.new(note_params)
    respond_to do |format|
      if @note.save
        format.js
      else
        format.js
      end
    end
  end

  def update
    @note = Note.find(params[:id])
    respond_to do |format|
      if @note.update(note_params)
        format.js
      else
        format.js
      end
    end
  end

  private

  def authorized?(action = action_name, resource = nil)
    (logged_in? && current_user.known?)
  end

  def note_params
    params.require(:note).permit(:title, :contents, :parent_id, :parent_type, :owner_id, :visibility, :note_type)
  end

end
