class ConcernsController < ApplicationController
  include DisplaySettings

  before_action :set_concern, only: [:edit, :update]

  # POST /concerns
  # POST /concerns.json
  def create
    @reload_concerns = false
    @concern = Concern.new(concern_params)
    @concern.user = current_user
    if @concern.element &&
       @concern.element.preferred_colour
      @concern.colour = @concern.element.preferred_colour
    else
      @concern.colour = current_user.free_colour
    end

    #
    #  Does the user already have a concern for this element?
    #  If so, then don't attempt to create a new one.  Just turn
    #  this one on and reload.
    #
    #  If it's already on, then do nothing but prepare for more input.
    #
    existing_concern = Concern.find_by(user_id: @concern.user_id,
                                       element_id: @concern.element_id)
    if existing_concern
      @concern = Concern.new
      @element_id = nil
      unless existing_concern.visible
        existing_concern.visible = true
        existing_concern.save
        @reload_concerns = true
      end
      respond_to do |format|
        format.js
      end
    else
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
        else
          #
          #  Failure to save indicates it wasn't a valid thing to add.
          #
          @element_id = nil
        end
        setvars_for_lhs(current_user)
        @concern = Concern.new
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
    if @concern && current_user.can_delete?(@concern)
      @concern_id = @concern.id
      @concern.destroy
    else
      #
      #  So that the front end can destroy its erroneous record.
      #
      @concern_id = params[:id]
    end
    @concern = Concern.new
    #
    #  We're now going to re-render the user's column, so need to
    #  set up some parameters.
    #
    setvars_for_lhs(current_user)
  end

  def edit
    if current_user.can_edit?(@concern)
      session[:return_to] = request.referer
      if @concern.itemreport
        @item_report = @concern.itemreport
      else
        @item_report = Itemreport.new
        @item_report.concern = @concern
      end
      @element = @concern.element
      #
      #  A reduced form of this page is used when an administrator
      #  is editing a concern on behalf of a user - generally in order
      #  to give said user more (or fewer) permissions in relation
      #  to the corresponding element.
      #
      #  Note that the name is slightly odd, in that although the page
      #  as a whole is greatly reduced, the number of flags within
      #  the actual concern which can be edited is increased.
      #
      @reduced = params.has_key?(:reduced) && current_user.admin
      #
      #  There's quite a bit of thinking about what flags to show, so
      #  do it here rather than in the view.
      #
      @options_flags = [
        {field: :visible,
         annotation: "Should this resource's events be visible currently?"}]
      if current_user.editor || current_user.admin
        @options_flags <<
          {field: :auto_add,
           annotation: "When creating a new event, should this resource be added automatically?"}
      end
      #
      #  If we are doing the "reduced" version, then this field appears
      #  later.
      #
      if @concern.equality && !@reduced
        @options_flags <<
          {field: :owns,
           prompt: "Approve events",
           annotation: "Do you want to approve events as you are added to them?"}
      end
      if @concern.owns || @concern.skip_permissions || @reduced
        @options_flags <<
          {field: :seek_permission,
           annotation: "Although you can add this resource without permission, would you like to go through the permissions process anyway?"}
      end
      #
      #  And now some more which only an administrator can change.
      #  This incidentally is where an admin gets access to the "owns" flag.
      #  Note the slightly confusing names of the underlying flags.
      #  The "controls" flag, gives the owner additional control - the
      #  means to edit any event involving the resource.
      #
      #  Note that the @reduced flag is set only if the user is an admin,
      #  so these flags won't ever be displayed to non-admins, even if
      #  they put ?reduced on their URL.
      #
      if @reduced
        @options_flags <<
          {field: :equality,
           annotation: "Is this user the same thing as the corresponding element? Generally used to link users to staff or pupil records."}
        @options_flags <<
          {field: :owns,
           prompt: "Controls",
           annotation: "Does this user control this element and approve requests for its use?"}
        @options_flags <<
          {field: :controls,
           prompt: "Edit any",
           annotation: "Should this user be able to edit any event which uses this resource?"}
        @options_flags <<
          {field: :skip_permissions,
           annotation: "Should this user be able to skip the permissions process when adding this resource to an event?"}
      end
    else
      redirect_to :root
    end
  end

  def update
    if current_user.can_edit?(@concern)
      respond_to do |format|
        if @concern.update(concern_params)
          format.html { redirect_to session[:return_to] || :root }
        else
          format.html { render :edit }
        end
      end
    else
      redirect_to :back
    end
  end


  def flipped
    #
    #  Special case until the calendar is an element.
    #  If the user asks to change to the state which we're already in
    #  then we just refresh his display.  This can happen if a user is
    #  logged in on two different terminals.
    #
    id_param = params[:id]
    new_state = params[:state] == "on" ? true : false
    @status = :ok
    if current_user && current_user.known?
      #
      #  May be being asked to turn the user's own events on and off.
      #  This isn't a real Concern.
      #
      if id_param == "owned"
        if current_user.show_owned != new_state
          current_user.show_owned = new_state
          current_user.save
        end
      else
        @concern = Concern.find_by(id: id_param)
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
    else
      if id_param =~ /^E\d+$/
        #
        #  And this one is a deliberate fake ID.  Done using values stored
        #  in the session.  N.B.  If the relevant value is not already there
        #  then it counts as true.
        #
        Rails.logger.debug("Setting flag for #{id_param} to #{new_state}.")
        session[id_param] = new_state
      end
    end
    respond_to do |format|
      format.json { render :show, status: @status }
    end
  end

  #
  #  Re-supply the sidebar of concerns for the current user if any.
  #
  def sidebar
    setvars_for_lhs(current_user)
    @concern = Concern.new
    render :layout => false
  end

  def authorized?(action = action_name, resource = nil)
    (logged_in? && current_user.known?) ||
      action == 'sidebar' ||
      action == 'flipped'
  end

  private

  def set_concern
    @concern = Concern.find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def concern_params
    if current_user.admin
      params.require(:concern).
             permit(:element_id,
                    :name,
                    :visible,
                    :colour,
                    :auto_add,
                    :owns,
                    :seek_permission,
                    :equality,
                    :controls,
                    :skip_permissions)
    else
      params.require(:concern).
             permit(:element_id,
                    :name,
                    :visible,
                    :colour,
                    :auto_add,
                    :owns,
                    :seek_permission)
    end
  end
end
