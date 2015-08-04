class ConcernsController < ApplicationController
#  before_action :set_concern, only: [:flipped]

  # POST /concerns
  # POST /concerns.json
  def create
    @concern = Concern.new(concern_params)
    @concern.user = current_user
    if @concern.element &&
       @concern.element.preferred_colour
      @concern.colour = @concern.element.preferred_colour
    else
      @concern.colour = current_user.free_colour
    end

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
        #
        #  Need a new concern record in order to render the user's
        #  side panel again, but also need the new concern_id
        #  so save that first.
        #
        @concern_id = @concern.id
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
    #  If the user makes a request to destroy a non-existent
    #  concern then it probably means that things have got out of step.
    #  He may well have logged on twice and be looking at an out-of-date
    #  screen.  We should respond by causing his screen to be refreshed.
    #
    #  Use find_by rather than find so we don't raise an error if not
    #  found.  If the front end asks to remove a concern which isn't
    #  here then we assume that the front end is out of step and tell
    #  it to update itself.
    #
    @concern = Concern.find_by(id: params[:id])
    if @concern &&
       @concern.user_id == current_user.id &&
       @concern.user_can_delete?
      @concern_id = @concern.id
      @concern.destroy
    else
      #
      #  So that the front end can destroy its erroneous record.
      #
      @concern_id = params[:id]
    end
    @concern = Concern.new
  end

  def flipped
    #
    #  Special case until the calendar is an element.
    #  If the user asks to change to the state which we're already in
    #  then we just refresh his display.  This can happen if a user is
    #  logged in on two different terminals.
    #
    new_state = params[:state] == "on" ? true : false
    @status = :ok
    if params[:id] == "owned"
      if current_user.show_owned != new_state
        current_user.show_owned = new_state
        current_user.save
      end
    else
      @concern = Concern.find_by(id: params[:id])
      if @concern && @concern.user_id == current_user.id
        if @concern.visible != new_state
          @concern.visible = new_state
          @concern.save
        end
      else
        #
        #  By setting this to failed, we will cause the front end to
        #  refresh its view entirely.
        #
        @status = :failed
      end
    end
    respond_to do |format|
      format.json { render :show, status: @status }
    end
  end

  #
  #  Re-supply the sidebar of concerns for the current user.
  #
  def sidebar
    @concern = Concern.new
    render :layout => false
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
