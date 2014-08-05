class InterestsController < ApplicationController

  def index
    @interests = current_user.interests
  end

  # POST /interests
  # POST /interests.json
  def create
    @interest = Interest.new(interest_params)
    @interest.user = current_user
    @interest.colour = current_user.free_colour

    respond_to do |format|
      if @interest.save
        current_user.reload
        @element_id = @interest.element_id
        @interest = Interest.new
        format.js
      else
        #
        #  Failure to save indicates it wasn't a valid thing to add.
        #
        @interest = Interest.new
        @element_id = nil
        format.js
      end
    end
  end

  def destroy
    @interest = Interest.find(params[:id])
    @element_id = @interest.element_id
    @interest.destroy
    @interest = Interest.new
  end

  def authorized?(action = action_name, resource = nil)
    logged_in? && current_user.known?
  end

  private

  # Never trust parameters from the scary internet, only allow the white list through.
  def interest_params
    params.require(:interest).permit(:element_id)
  end
end
