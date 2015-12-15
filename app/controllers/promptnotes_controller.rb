class PromptnotesController < ApplicationController

  #
  #  Needs to be called in the context of a parent - an element.
  #
  def new
    @element = Element.find(params[:element_id])
    @promptnote = Promptnote.new
    @promptnote.element = @element
    respond_to do |format|
      format.js
    end
  end

  def create
    @promptnote = Promptnote.new(promptnote_params)
    respond_to do |format|
      if @promptnote.save
        format.js
      else
        format.js
      end
    end
  end

  def edit
    @promptnote = Promptnote.find(params[:id])
    respond_to do |format|
      format.js
    end
  end

  def update
    @promptnote = Promptnote.find(params[:id])
    if current_user.can_edit?(@promptnote)
      @promptnote.update(promptnote_params)
    end
    respond_to do |format|
      format.js
    end
  end

  def destroy
    Rails.logger.debug("Asked to delete promptnote")
    @promptnote = Promptnote.find(params[:id])
    @element = @promptnote.element
    if current_user.can_edit?(@promptnote)
      Rails.logger.debug("Doing the actual delete")
      @promptnote.destroy
    end
    respond_to do |format|
      format.js
    end
  end

  private

  def authorized?(action = action_name, resource = nil)
    (logged_in? && current_user.known?)
  end

  def promptnote_params
    params.require(:promptnote).permit(:title, :prompt, :default_contents, :element_id, :read_only)
  end

end
