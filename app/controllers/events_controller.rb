# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2018 John Winters
# See COPYING and LICENCE in the root directory of the application
# for more information.

class EventsController < ApplicationController
  before_action :set_event,
                only: [:show,
                       :edit,
                       :update,
                       :moved,
                       :clone,
                       :destroy,
                       :shownotes,
                       :canceledit,
                       :coverrooms]

  # GET /events
  # GET /events.json
  def index
    @show_owner              = true
    @show_organiser          = true
    @show_actions            = false

    if params[:user_id]
      if (params[:user_id].to_i == current_user.id) || current_user.admin?
        #
        #  Explicit adjustment to allow admin users to view events
        #  for other users.
        #
        #  Note that the only way we can get here with the following
        #  two items not equal is if current_user is an admin.
        #
        if params[:user_id].to_i != current_user.id
          target_user = User.find_by(id: params[:user_id]) || current_user
        else
          target_user = current_user
        end
        #
        #  Being asked for events related to this user.  Note, not
        #  events *involving* this user - events which he owns or
        #  organises.
        #
        #  Just give this user's own events.  He or she is either
        #  the owner or the organiser.  Since we are currently on
        #  Rails 4.x we can't use ActiveRecord's "or" constructor.
        #
        #  All users can *ask* for them, but those who don't have
        #  any will get an empty list.
        #
        staff = target_user.corresponding_staff
        if staff
          #
          #  Events are owned by users, but organised by elements.
          #
          selector = Event.where("owner_id = ? OR organiser_id = ?",
                                 target_user.id,
                                 staff.element.id)
        else
          selector = target_user.events
        end
        if params.has_key?(:pending)
          selector = selector.future.pending
          @title = "#{target_user.name}'s pending events"
          @flip_target = user_events_path(target_user)
          @flip_text = "See All"
        else
          @title = "#{target_user.name}'s events"
          @flip_target = user_events_path(target_user, pending: true)
          @flip_text = "See Pending"
        end
        @flip_button    = true
        @show_owner     = false
        @show_organiser = false
        @show_actions   = true
        @listing_id     = "user-events"
      else
        #
        #  Asked to see someone else's events and isn't an admin.
        #
        selector = nil
      end
    elsif current_user.admin?
      #
      #  The user is asking for all events.  Allow this only for
      #  a system administrator.
      #
      selector = Event.all
      @title = "All events"
      @flip_button = false
      @listing_id     = "all-events"
    else
      #
      #  If we get here then either the user has tried for all events
      #  and isn't an admin, or for events for an element and isn't
      #  allowed free browsing.  Either way, send him or her back to
      #  his or her own events.
      #
      selector = nil
    end
    if selector
      #
      #  If there are lots of events, then it makes sense to start
      #  on the page for today.  The user can page forward or backward
      #  as required.  Do this only if the user has not specified an
      #  explicit page.
      #
      page_no = params[:page]
      unless page_no
        previous_event_count = selector.until(Time.zone.now.midnight).count
#        Rails.logger.debug("Previous event count = #{previous_event_count}")
        page_no = (previous_event_count / Event.per_page) + 1
      end
      @events = selector.includes(commitments: :user_form_response,
                                  requests: :user_form_response).
                         page(page_no).
                         order('starts_at')
    else
      if params.has_key?(:pending)
        redirect_to user_events_path(current_user, pending: true)
      else
        redirect_to user_events_path(current_user)
      end
    end
  end

  def assemble_event_info
    @notes = @event.all_notes_for(current_user)
    if current_user && current_user.exams
      @invigilation_requests = @event.requests.prototyped.to_a
    end
    @files = Array.new
    #
    #  Make an intelligent selection of which commitments this viewer is
    #  allowed to see.  Guests get only a sub-set.  Logged in users
    #  get to see any kind, but some may be sifted out as requiring
    #  approval.
    #
    @visible_commitments, @approvable_commitments =
      @event.commitments_for(current_user)
    #
    #  No point in warning a user who doesn't have the edit privileges
    #  to do anything about it.
    #
    if current_user &&
       current_user.warn_no_resources? &&
       current_user.can_add_resources? &&
       current_user.can_subedit?(@event) &&
       @event.resourceless?
      @resourcewarning = true
    else
      @resourcewarning = false
      if current_user &&
        current_user.can_complete_forms_for?(@event) &&
        !params.has_key?(:from_listing)
        @form_count = @event.pending_form_count
      end
    end
    if current_user && current_user.can_relocate?(@event)
      @relocate_link = true
      #
      #  We also need to provide the id of the commitment to the first
      #  (should be only) location.
      #
      location_commitment = @event.commitments.not_covering_location.take
      if location_commitment
        @location_commitment_id = location_commitment.id
      else
        @location_commitment_id = 0
      end
    else
      @relocate_link = false
    end
    #
    #  Technically, what he can see are user_form_responses.
    #
    if user_can_view_forms?
      #
      #  An element_connection is either a commitment or a request.
      #  It needs to respond to a method called element() and another
      #  called user_form_response().
      #
      @element_connections_with_forms =
        (@event.commitments + @event.requests).select do |c|
          c.user_form_response && !c.user_form_response.pristine?
        end
      if @element_connections_with_forms.empty?
        @element_connections_with_forms = nil
      end
    else
      @element_connections_with_forms = nil
    end
  end

  # GET /events/1
  # GET /events/1.json
  def show
    assemble_event_info
    if request.xhr?
      @minimal = true
      render :layout => false
    else
      @minimal = false
      render
    end
  end

  def canceledit
    assemble_event_info
    @minimal = true
    respond_to do |format|
      format.js
    end
  end

  # GET /events/new
  def new
    #
    #  Note that we place parameters explicitly into our new event model
    #  here, rather than by passing a hash to the model.  This allows
    #  us to control the order (all_day before timings), and to adjust
    #  certain items.
    #
    #  In particular, the model is expecting to receive timings via
    #  starts_at_text= and ends_at_text=.  These provide certain adjustments
    #  to suit the UI.  Both FC and my database agree on how event timings
    #  should be stored, but users need a slightly different presentation.
    #
    #  A user will think of an all-day event as running from Mon 1st
    #  to Wed 3rd, but from the point of view of both FullCalendar
    #  and my d/b it runs from 00:00 on Mon 1st to 00:00 on Thu 4th.
    #  The starts/ends_at_text(=) methods in the model handle the conversion.
    #
    #  At this point in the processing though, the input is coming from
    #  FC, and not from the UI.  Hence we don't want the conversion to
    #  happen.
    #
    @event = Eventsource.find_by(name: "Manual").events.new
    if current_user.preferred_event_category
      @event.eventcategory = current_user.preferred_event_category
    end
    unless current_user.default_event_text.blank?
      @event.body = current_user.default_event_text
    end
    unless current_user.secretary
      staff = current_user.corresponding_staff
      if staff
        @event.organiser = staff.element
      end
    end
    if params[:precommit]
      #
      #  Make no attempt to validate at this point.  If it comes back
      #  later then we will check it, and if it isn't valid then the
      #  pre-commit just won't happen.
      #
      @event.precommit_element_id = params[:precommit]
    else
      @event.precommit_element_id = ""
    end
    @event.all_day = params.has_key?(:all_day)
    #
    #  It's potentially feasible that a front end might request
    #  to create an event without specifying a start time at this
    #  stage.  The current front end does not do this, but allow
    #  for the possibility.
    #
    if params[:starts_at]
      @event.starts_at = Time.zone.parse(params[:starts_at])
    end
    if params[:ends_at]
      @event.ends_at = Time.zone.parse(params[:ends_at])
    else
      if @event.starts_at
        if @event.all_day
          @event.ends_at = @event.starts_at + 1.day
        else
          #
          #  If we have been given a start date and time, but no end
          #  date then the possibility arises of snapping to a period time.
          #
          #  We do this only if the current user has a period set
          #  on display.
          #
          #  If no suitable period is found, then the snap_to_period
          #  method returns the given parameter twice, producing the
          #  same effect as if we hadn't called it.
          #
          if ds = current_user.day_shape
            @event.starts_at, @event.ends_at =
              ds.snap_to_period(@event.starts_at)
          else
            @event.ends_at = @event.starts_at
          end
        end
      end
    end
    @pre_requisites = PreRequisite.pre_creation.order(:priority).to_a
    #
    #  Split into two columns.
    #
    per_column = (@pre_requisites.size + 1) / 2
    @pr_columns = Array.new
    @pr_columns << @pre_requisites[0,per_column]
    @pr_columns << @pre_requisites[per_column..-1]
    session[:request_notifier] = RequestNotifier.new
    if request.xhr?
      @minimal = true
      render :layout => false
    else
      @minimal = false
      render
    end
  end

  # GET /events/1/edit
  def edit
    @commitment = Commitment.new
    @commitment.event = @event
    #
    #  These next two are used in cooperation by this controller and
    #  the commitments controller.  They are zeroed (here) each time
    #  we start a new event editing session.
    #
    session[:request_notifier] = RequestNotifier.new
    #
    #  Admin can edit anything.  Other editors can only edit their
    #  own events.
    #
    #  The three different options for a response here can get a
    #  bit confusing.
    #
    #  In order:
    #
    #  HTML and request.xhr?
    #  Dialogue box opening to edit (not currently used)
    #
    #  HTML and !request.xhr?
    #  Full page edit.  Not publicised, but works.
    #
    #  JS
    #  Starting an edit in an already open dialogue box.  The edit
    #  form replaces the current contents in the dialogue.
    #
    if current_user.can_subedit?(@event)
      @resourcewarning = false
      @quick_buttons = QuickButtons.new(@event)
      respond_to do |format|
        format.html do
          if request.xhr?
            @minimal = true
            render :layout => false
          else
            @minimal = false
            render
          end
        end
        format.js do
          @minimal = true
          render
        end
      end
    else
      #
      #  This is broken and doesn't work.  Happily, you can only
      #  get here if you force an invalid request from the client.
      #  Needs work to reject the unauthorised request cleanly.
      #
      @minimal = true
      render :show, :layout => false
    end
  end

  private

  def add_appropriately(event, element)
    did_add = false
    if element.add_directly? ||
       current_user.owns_parent_of?(element)
      if element.entity.can_have_requests?
        #
        #  Gets a request
        #
        r = event.requests.create({
          element: element,
          quantity: 1
        })
        event.journal_resource_request_created(r, current_user)
        #
        #  TODO add notifications
        #
        did_add = true
      else
        #
        #  Gets an immediate commitment
        #
        c = event.commitments.create({
          element: element
        }) do |c|
          set_appropriate_approval_status(c)
        end
        if session[:request_notifier]
          session[:request_notifier].commitment_added(c)
        end
        event.journal_commitment_added(c, current_user)
      end
    end
    return did_add
  end

  public

  # POST /events
  # POST /events.json
  def create
    @event = Eventsource.find_by(name: "Manual").events.new(event_params)
    @event.owner = current_user

    respond_to do |format|
      if @event.save
        @event.reload
        @event.journal_event_created(current_user)
        added_any = false
        #
        #  Does this user have any Concerns with the auto_add flag set?
        #
        current_user.concerns.auto_add.each do |concern|
          element = concern.element
          if add_appropriately(@event, element)
            added_any = true
          end
        end
        #
        #  And was anything specified in the request?
        #
        unless @event.precommit_element_id.blank?
          #
          #  It's just *possible* that the same ID might appear
          #  more than once due to mis-configuration by a system
          #  admin.  Convert to integers to be really sure we've
          #  found any duplicates.
          #
          element_ids =
            @event.precommit_element_id.
                   split(",").
                   collect {|e| e.to_i}.
                   uniq
          element_ids.each do |eid|
            element = Element.find_by(id: eid)
            if element
              #
              #  Guard against double commitment.
              #
              unless current_user.concerns.auto_add.detect {|c| c.element == element}
                if add_appropriately(@event, element)
                  added_any = true
                end
              end
            else
              Rails.logger.debug("Couldn't find element with id #{eid}")
            end
          end
        end
        if added_any
          #
          #  I'm having a problem with the list of requests attached
          #  to the event ending up slightly corrupted.  It thinks
          #  it has 1 member, but when you iterate through it it returns
          #  that 1 member twice.
          #
          @event.reload
        end
        #
        #  If the user does not have permission to add resources, then
        #  he will be thrown straight out to the event display.
        #  Prepare the necessary data.
        #
        unless current_user.can_add_resources?
          assemble_event_info
        end
        @quick_buttons = QuickButtons.new(@event)
        @success = true
        @minimal = true
        @commitment = Commitment.new
        @commitment.event = @event
        @resourcewarning = false
        format.html { redirect_to events_path, notice: 'Event was successfully created.' }
        format.json { render :show, status: :created, location: @event }
        format.js
      else
        @success = false
        format.html { render :new }
        format.json { render json: @event.errors, status: :unprocessable_entity }
        format.js
      end
    end
  end

  # PATCH/PUT /events/1
  # PATCH/PUT /events/1.json
  def update
    if current_user.can_subedit?(@event)
      respond_to do |format|
        #
        #  Want to make sure the journal exists before we do the
        #  update so that we can tell what if anything has changed.
        #
        @event.ensure_journal
        if @event.update(event_params)
          @event.journal_event_updated(current_user)
          @event.check_timing_changes(current_user)
          if session[:request_notifier]
            session[:request_notifier].
              send_notifications_for(current_user, @event)
          end
          @success = true
          assemble_event_info
          format.html { redirect_to events_path, notice: 'Event was successfully updated.' }
          format.json { render :show, status: :ok, location: @event }
          format.js { @minimal = true; render :update }
        else
          @success = false
          format.html { render :edit }
          format.json { render json: @event.errors, status: :unprocessable_entity }
          format.js
        end
      end
    else
      #
      #  Just don't do anything.
      #
      respond_to do |format|
        @success = true
        @notes = @event.all_notes_for(current_user)
        @files = Array.new
        @visible_commitments, @approvable_commitments =
          @event.commitments_for(current_user)
        format.html { redirect_to events_path, notice: 'Event was successfully updated.' }
        format.json { render :show, status: :ok, location: @event }
        format.js { @minimal = true; render :update }
      end
    end
  end

  #
  #  Much like update, except that we have to be careful about the order
  #  in which we apply the changes.  Called when an event has been dragged
  #  on the visual display.  It gets interesting when a timed event has
  #  been dragged to all-day, or vice versa.
  #
  def moved
    if current_user.can_retime?(@event)
      @event.ensure_journal
      new_start = params[:event][:new_start]
      new_all_day = (params[:event][:all_day] == "true")
      @event.set_timing(new_start, new_all_day)
      respond_to do |format|
        if @event.save
          @event.journal_event_updated(current_user)
          @event.check_timing_changes(current_user)
          format.html { redirect_to events_path, notice: 'Event was successfully updated.' }
          format.json { render :show, status: :ok, location: @event }
        else
          format.html { render :edit }
          format.json { render :revert, status: :failed }
  #        format.json { render json: @event.errors, status: :unprocessable_entity }
        end
      end
    else
      respond_to do |format|
        format.html { render :edit }
        format.json { render :revert, status: :failed }
      end
    end
  end

  # POST /events/1/clone
  def clone
    #
    #  We enter this method with @event giving the event to be cloned.
    #
    #  This is the old one-click cloning, currently not linked from
    #  anywhere.  The new form-based cloning is handled by the Clones
    #  Controller.
    #
    request_notifier = RequestNotifier.new
    @event =
      @event.clone_and_save(
        current_user,
        {
          owner:       current_user,
          eventsource: Eventsource.find_by(name: "Manual")
        }) do |item|
          #
          #  For now we expect only commitments to be passed back for
          #  adjustment, but we may want to extend this in the future.
          #
          if item.instance_of?(Commitment)
            set_appropriate_approval_status(item)
            request_notifier.commitment_added(item)
          end
        end
    request_notifier.send_notifications_for(current_user, @event)
    #
    #  And display it to the user.
    #
    assemble_event_info
    @just_cloned = true
    respond_to do |format|
      format.js
    end
  end

  # DELETE /events/1
  # DELETE /events/1.json
  def destroy
    if current_user.can_edit?(@event)
      RequestNotifier.new.send_notifications_for(current_user, @event, true)
      @event.journal_event_destroyed(current_user)
      @event.destroy
    end
    respond_to do |format|
      format.html { redirect_to events_url }
      format.json { head :no_content }
      format.js
    end
  end

  # GET /events/search
  def search
    #
    #  Logged in, known users can search for any event.
    #  Others only on calendar events.
    #
    search_text = event_params[:body]
    public_properties = Property.public_ones.to_a
    invisible_categories = Eventcategory.invisible.to_a
    if search_text.blank? || public_properties.size == 0
      redirect_to :back
    else
      selector = Event.beginning(Setting.current_era.starts_on).non_confidential
      unless current_user && current_user.staff?
        selector = selector.involving_one_of(public_properties.collect {|pp| pp.element })
      end
      selector = invisible_categories.inject(selector) { |memo, ic|
        memo.excluding_category(ic)
      }
      selector =
        search_text.split(" ").inject(selector) { |memo, snippet|
          memo.where("body like ?", "%#{snippet}%")
        }.order(:starts_at)
      #
      #  Now, has a page number been specified?  If has then we go
      #  to it, otherwise we try to a bit of intelligent adjustment.
      #
      page_param = params[:page]
      if page_param.blank?
        num_events = selector.size
        now = Time.zone.now
        if num_events > Event.per_page
          index = selector.find_index {|e| e.starts_at >= now }
          if index
            #
            #  I want to start on the page on which this event
            #  occurs.
            #
            page_param = ((index / Event.per_page) + 1).to_s
          else
            #
            #  All events are in the past.  Would make sense
            #  to start on the last page.
            #
            page_param = (((num_events - 1) / Event.per_page) + 1).to_s
          end
        end
      end
      @found_events = selector.page(page_param)
      @full_details = current_user && current_user.staff?
    end
  end

  # GET /events/1/coverrooms.json
  def coverrooms
    crf = CoverRoomFinder.new(@event)
    @coverrooms = crf.find_rooms(relocating_user?)
    locations = @event.direct_locations.to_a
    if locations.size > 0
      @orgroom = locations[0].short_name
    else
      @orgroom = "Unknown"
    end
    respond_to do |format|
      format.json
    end
  end

  def shownotes
    @notes = @event.all_notes_for(current_user)
    respond_to do |format|
      format.js
    end
  end

  #
  #  Receive an incoming file.
  #
  def upload
    uploaded_io = params[:attachment]
    if uploaded_io
      File.open(Rails.root.join('staging',
                                uploaded_io.original_filename), 'wb') do |file|
        file.write(uploaded_io.read)
      end
    end
    redirect_to :back
  end

  private

  def authorized?(action = action_name, resource = nil)
    (logged_in? && current_user.create_events?) ||
    (logged_in? && action == 'coverrooms') ||
    action == 'show' || action == "search"
  end

  # Use callbacks to share common setup or constraints between actions.
  def set_event
    @event = Event.find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def event_params
    params.require(:event).permit(:body,
                                  :real_body,
                                  :eventcategory_id,
                                  :owner_id,
                                  :starts_at_text,
                                  :ends_at_text,
                                  :all_day_field,
                                  :approximate,
                                  :non_existent,
                                  :reference_id,
                                  :reference_type,
                                  :new_end,
                                  :organiser_name,
                                  :organiser_id,
                                  :organiser_ref,
                                  :precommit_element_id)
  end
end
