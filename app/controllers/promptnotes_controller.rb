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
    respond_to do |format|
      if @promptnote.update(promptnote_params)
        format.js
      else
        format.js
      end
    end
  end

  def destroy
    @promptnote = Promptnote.find(params[:id])
    if current_user.can_edit?(@promptnote)
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
