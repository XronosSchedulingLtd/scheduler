class ConcernsController < ApplicationController
#  before_action :set_concern, only: [:flipped]

  # POST /concerns
  # POST /concerns.json
  def create
    @concern = Concern.new(concern_params)
    @concern.user = current_user
    @concern.colour = current_user.free_colour

    unless @concern.valid?
      #
      #  We work on the principle that if it isn't valid then the one
      #  and only parameter which we processed (element_id) wasn't good.
      #  This can happen if the user hits return without selecting an
      #  entry from the list presented.
      #
      #  See if we can find a unique element using the contents of
      #  the name field.
      #
      unless @concern.name.blank?
        @elements = Element.current.where("name like ?", "%#{@concern.name}%")
        if @elements.size == 1
          @concern.element = @elements[0]
        end
      end
    end

    respond_to do |format|
      if @concern.save
        current_user.reload
        @element_id = @concern.element_id
        @concern = Concern.new
        format.js
      else
        #
        #  Failure to save indicates it wasn't a valid thing to add.
        #
        @concern = Concern.new
        @element_id = nil
        format.js
      end
    end
  end

  def destroy
    #
    #  This code should surely check that the concern relates to the
    #  current user?
    #
    @concern = Concern.find(params[:id])
    @element_id = @concern.element_id
    @concern.destroy
    @concern = Concern.new
  end

  def flipped
    #
    #  We could do with some permission checks here.  User's should
    #  be able to flip only their own concerns.
    #
    #  Special case until the calendar is an element.
    #
    if params[:id] == "calendar"
      current_user.show_calendar = (!current_user.show_calendar)
      current_user.save
    elsif params[:id] == "owned"
      current_user.show_owned = (!current_user.show_owned)
      current_user.save
    else
      @concern = Concern.find(params[:id])
      if @concern
        @concern.visible = !@concern.visible
        @concern.save
      end
    end
    respond_to do |format|
      format.json { render :show, status: :ok }
    end
  end

  def authorized?(action = action_name, resource = nil)
    logged_in? && current_user.known?
  end

  private

  def set_concern
    @concern = Concern.find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def concern_params
    params.require(:concern).permit(:element_id, :name)
  end
end
