# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2018 John Winters
# See COPYING and LICENCE in the root directory of the application
# for more information.

class ConcernsController < ApplicationController
  include DisplaySettings

  JOURNAL_ENTRIES_TO_SHOW = 10

  class IcalUrl
    attr_reader :title, :url, :linkid

    def initialize(title, element, id, options = nil)
      @title = title
      if element
        @url = "#{Setting.protocol_prefix}://#{Setting.dns_domain_name}#{Setting.port_no}/ical/UUE-#{element.uuid}"
        if options
          options_array = []
          options.each do |key, element|
            case key
            when :cover
              if element
                options_array << "cover"
              else
                options_array << "!cover"
              end
            when :categories
              options_array << "categories=#{element}"
            when :everything
              options_array << "everything"
            end
          end
          unless options_array.empty?
            @url = @url + "?#{options_array.join("&")}"
          end
        end
      else
        @url = "#{Setting.protocol_prefix}://#{Setting.dns_domain_name}#{Setting.port_no}/ical/0"
      end
      @linkid = id.to_s
    end

    def to_partial_path
      "ical_url"
    end

  end

  class IcalUrlSet < Array
    attr_reader :heading

    def initialize(heading)
      @heading = heading
    end

    def to_partial_path
      "ical_url_set"
    end

  end

  before_action :set_concern, only: [:edit, :update]

  # POST /concerns
  # POST /concerns.json
  #
  #   This method can create concerns in two different circumstances.
  #
  #   1. The user adds it to his or her current display
  #   2. An admin adds it to a user
  #
  # TODO  This method is currently horrible and needs re-factoring.
  #
  def create
    user_id = params[:user_id]
    if user_id
      #
      #  A request to create a concern on behalf of a user, rather
      #  than for the current user.  Requires admin privilege.
      #
      @user = User.find_by(id: user_id)
      if admin_user? && @user
        @concern = @user.concerns.new(concern_params)
        @concern.list_teachers = @user.list_teachers
        if @concern.element && @concern.element.preferred_colour
          @concern.colour = @concern.element.preferred_colour
        else
          @concern.colour = @user.free_colour
        end
        #
        #  If we fail to save it then it must be a duplicate
        #  In either case, we're just going to render the list again.
        #
        @concern.save
        @user.reload
      end
      respond_to do |format|
        format.js { render "create_for_user" }
      end
    else
      @reload_concerns = false
      @concern = current_user.concerns.new(concern_params)
      @concern.concern_set = current_user.current_concern_set
      @concern.list_teachers = current_user.list_teachers
      if @concern.element &&
         @concern.element.preferred_colour
        @concern.colour = @concern.element.preferred_colour
      else
        if current_user.current_concern_set
          selector = current_user.current_concern_set.concerns
        else
          selector = current_user.concerns.default_view
        end
        @concern.colour = current_user.free_colour(selector)
      end

      #
      #  Does the user already have a concern for this element?
      #  If so, then don't attempt to create a new one.  Just turn
      #  this one on and reload.
      #
      #  If it's already on, then do nothing but prepare for more input.
      #
      existing_concern =
        current_user.concerns.find_by({
          element_id: @concern.element_id,
          concern_set: current_user.current_concern_set
        })
      if existing_concern
        @concern = Concern.new
        @element_id = nil
        unless existing_concern.visible
          existing_concern.visible = true
          existing_concern.save
          @reload_concerns = true
        end
        setvars_for_lhs(current_user)
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
    user_id = params[:user_id]
    if user_id
      #
      #  Only an admin is allowed to do this.
      #
      if admin_user? && @user = User.find_by(id: user_id)
        if @concern.user_id == @user.id
          @concern.destroy
        end
        @user.reload
      end
      respond_to do |format|
        format.js { render 'destroy_for_user' }
      end
    else
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
      respond_to do |format|
        format.js
      end
    end
  end

  def edit
    if current_user.can_edit?(@concern)
      #
      #  If we are editing in the context of a user, then we go back
      #  to the user edit page, otherwise back to where we came from.
      #
      @user = User.find_by(id: params[:user_id])
      if @user
        session[:return_to] = edit_user_path(@user, edited_concern: true)
      else
        session[:return_to] = request.referer
      end
      #
      #  If the user has generated a report for this concern's element
      #  before then we will have saved the options used on that occasion.
      #  If not, then create a new one with some default values.
      #
      if @concern.itemreport
        @item_report = @concern.itemreport
      else
        @item_report = Itemreport.new
        @item_report.concern = @concern
      end
      @element = @concern.element
      if @element.user_form && current_user.can_view_forms_for?(@element)
        @form_report = FormReport.new
      end
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
      if @reduced
        @title = "#{@concern.user.name}'s concern with #{@concern.element.name}"
      else
        @title = "#{@concern.element.name}"
      end
      #
      #  There's quite a bit of thinking about what flags to show, so
      #  do it here rather than in the view.
      #
      @options_flags = construct_options_flags
      #
      #  And URLs for getting ical feeds.
      #
      if @concern.element.uuid.blank?
        @urls = nil
      else
        @urls = construct_urls
      end
      @proforma = @concern.owns && !@concern.equality
      @message = ""
      #
      #  Can we show the journal?
      #
      if current_user.can_view_journal_for?(@element)
        @journal_entries =
          @element.journal_entries.order('created_at').
                   last(JOURNAL_ENTRIES_TO_SHOW).to_a
        if @journal_entries.empty?
          #
          #  No point in showing an empty journal.
          #
          @journal_entries = nil
        else
          @journal_link_text = "Full journal"
          total_entries = @element.journal_entries.count
          if total_entries > JOURNAL_ENTRIES_TO_SHOW
            @journal_link_text +=
              " (#{total_entries - JOURNAL_ENTRIES_TO_SHOW} more entries)"
          end
        end
      else
        @journal_entries = nil
      end
      #
      #  And the timetable?
      #
      date = Date.today
      @timetable =
        Timetable::Contents.new(@element, date, current_user.day_shape)
      @embed_css = @timetable.periods_css
      @view_member_timetables =
        (@element.entity_type == 'Group' && !@element.entity.membership_empty?)
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
    known_user? ||
    action == 'sidebar' ||
    action == 'flipped'
  end

  private

  #
  #  Set up the options flags which the user will be able to manipulate
  #  on the concern.
  #
  def construct_options_flags
    options_flags = [
      {field: :visible,
       annotation: "Should this resource's events be visible currently?"},
      {field: :list_teachers,
       annotation: "Do you want teachers' initials listed with the event title?"}]
    if (current_user.editor? && current_user.can_add_resources?) ||
       current_user.admin
      options_flags <<
        {field: :auto_add,
         annotation: "When creating a new event, should this resource be added automatically?"}
    end
    #
    #  If we are doing the "reduced" version, then this field appears
    #  later.
    #
    if @concern.equality && !@reduced
      options_flags <<
        {field: :owns,
         prompt: "Approve events",
         annotation: "Do you want to approve events as you are added to them?"}
    end
    if @concern.owns || @concern.skip_permissions || @reduced
      options_flags <<
        {field: :seek_permission,
         annotation: "Although you can add this resource without permission, would you like to go through the permissions process anyway?"}
    end
    #
    #  And now some more which only an administrator can change.
    #  This incidentally is where an admin gets access to the "owns" flag.
    #  Note the now slightly less confusing names of the underlying flags.
    #  The "edit_any" flag, gives the owner additional control - the
    #  means to edit any event involving the resource.
    #
    #  Note that the @reduced flag is set only if the user is an admin,
    #  so these flags won't ever be displayed to non-admins, even if
    #  they put ?reduced on their URL.
    #
    if @reduced
      options_flags <<
        {field: :equality,
         annotation: "Is this user the same thing as the corresponding element? Generally used to link users to staff or pupil records."}
      options_flags <<
        {field: :owns,
         prompt: "Controls",
         annotation: "Does this user control this element and approve requests for its use?"}
      options_flags <<
        {field: :edit_any,
         prompt: "Edit any",
         annotation: "Should this user be able to edit any event which uses this resource?"}
      options_flags <<
        {field: :subedit_any,
         prompt: "Sub-edit any",
         annotation: "Should this user be able to sub-edit any event which uses this resource?"}
      options_flags <<
        {field: :skip_permissions,
         annotation: "Should this user be able to skip the permissions process when adding this resource to an event?"}
    end
    options_flags
  end

  def construct_urls
    #
    #  Just the one set to start with.
    #
    result = []
    entity_type = @concern.element.entity_type
    if entity_type == "Pupil" || entity_type == "Staff"
      set1 = IcalUrlSet.new("Simple feeds")
      set1 << IcalUrl.new("Breakthrough events", nil, 0)
      set1 << IcalUrl.new("Schedule", @concern.element, 1)
      result << set1
      if entity_type == "Staff"
        set2 = IcalUrlSet.new("More separation")
        set2 << IcalUrl.new("Breakthrough events", nil, 2)
        set2 << IcalUrl.new("Basic schedule",
                            @concern.element,
                            3,
                            cover: false,
                            categories: "!Invigilation")
        set2 << IcalUrl.new("Cover",
                            @concern.element,
                            4,
                            cover: true)
        set2 << IcalUrl.new("Invigilation",
                            @concern.element,
                            5,
                            categories: "Invigilation")
        result << set2
      end
      set3 = IcalUrlSet.new("All in one")
      set3 << IcalUrl.new("The lot",
                          @concern.element,
                          6,
                          everything: true)
      result << set3
    else
      set4 = IcalUrlSet.new("Feeds for #{@concern.element.name}")
      set4 << IcalUrl.new("On its own",
                          @concern.element,
                          7)
      set4 << IcalUrl.new("With breakthrough events",
                          @concern.element,
                          8,
                          everything: true)
      result << set4
    end
    result
  end

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
                    :edit_any,
                    :subedit_any,
                    :skip_permissions,
                    :list_teachers)
    else
      params.require(:concern).
             permit(:element_id,
                    :name,
                    :visible,
                    :colour,
                    :auto_add,
                    :owns,
                    :seek_permission,
                    :list_teachers)
    end
  end
end
