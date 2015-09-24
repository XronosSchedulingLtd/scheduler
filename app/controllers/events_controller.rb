# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2014 John Winters
# See COPYING and LICENCE in the root directory of the application
# for more information.

class EventsController < ApplicationController
  before_action :set_event,
                only: [:show, :edit, :update, :moved, :clone, :destroy]

  # GET /events
  # GET /events.json
  def index
    @events = Event.page(params[:page]).order('starts_at')
  end

  # GET /events/1
  # GET /events/1.json
  def show
    if request.xhr?
      @minimal = true
      render :layout => false
    else
      @minimal = false
      render
    end
  end

  # GET /events/new
  def new
    @event = Event.new
    es = Eventsource.find_by name: "Manual"
    @event.eventsource = es if es
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
    if params[:date]
      start_date = Time.zone.parse(params[:date])
      @event.starts_at = start_date
      if params[:enddate]
        end_date = Time.zone.parse(params[:enddate])
        @event.ends_at = end_date
      else
        end_date = nil
        @event.ends_at   = start_date
      end
      if start_date.hour == 0 &&
         start_date.min == 0
        @event.all_day = true
        unless end_date
          @event.ends_at = start_date + 1.day
        end
      end
    end
    #
    #  If the event is now complete enough to save to the database,
    #  then save it.  We will thus go on to edit it instead of
    #  the creation dialogue.  This is kind of breaking the rules
    #  of verbs, but it makes for a slicker user experience.
    #
    #  Actually - it leads to too many problems.  If the user then
    #  cancels the dialogue the event is still in the d/b but doesn't
    #  appear on the screen, causing confusion.  Turned off again.
    #
#    if @event.valid?
#      @event.save
#      @commitment = Commitment.new
#      @commitment.event = @event
#    else
#      #
#      #  Don't whinge prematurely.
#      #
#      @event.errors.clear
#    end
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
    #  Admin can edit anything.  Other editors can only edit their
    #  own events.
    #
    if current_user.can_edit?(@event)
      if request.xhr?
        @minimal = true
        render :layout => false
      else
        @minimal = false
        render
      end
    else
      @minimal = true
      render :show, :layout => false
    end
  end

  # POST /events
  # POST /events.json
  def create
    @event = Event.new(event_params)
    @event.owner = current_user

    respond_to do |format|
      if @event.save
        @event.reload
        #
        #  Does this user have any Concerns with the auto_add flag set?
        #
        current_user.concerns.auto_add.each do |concern|
          c = Commitment.new
          c.event = @event
          c.element = concern.element
          c.save
        end
        #
        #  And was anything specified in the request?
        #
        unless @event.precommit_element_id.blank?
          element = Element.find_by(id: @event.precommit_element_id)
          if element
            #
            #  Guard against double commitment.
            #
            unless current_user.concerns.auto_add.detect {|c| c.element == element}
              c = Commitment.new
              c.event = @event
              c.element = element
              c.save
            end
          else
            Rails.logger.debug("Couldn't find element with id #{@event.precommit_element_id}")
          end
        end
        @success = true
        @minimal = true
        @commitment = Commitment.new
        @commitment.event = @event
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
    respond_to do |format|
      if @event.update(event_params)
        @success = true
        format.html { redirect_to events_path, notice: 'Event was successfully updated.' }
        format.json { render :show, status: :ok, location: @event }
        format.js
      else
        @success = false
        format.html { render :edit }
        format.json { render json: @event.errors, status: :unprocessable_entity }
        format.js
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
    new_start = params[:event][:new_start]
    new_all_day = (params[:event][:all_day] == "true")
    @event.set_timing(new_start, new_all_day)
    respond_to do |format|
      if @event.save
        format.html { redirect_to events_path, notice: 'Event was successfully updated.' }
        format.json { render :show, status: :ok, location: @event }
      else
        format.html { render :edit }
        format.json { render json: @event.errors, status: :unprocessable_entity }
      end
    end
  end

  # POST /events/1/clone
  def clone
    #
    #  We enter this method with @event giving the event to be cloned.
    #
    @event =
      @event.clone_and_save(
        owner:       current_user,
        eventsource: Eventsource.find_by(name: "Manual"))
    #
    #  And throw the user straight into editing it.
    #
    @commitment = Commitment.new
    @commitment.event = @event
    @minimal = true
    respond_to do |format|
      format.js
    end
  end

  # DELETE /events/1
  # DELETE /events/1.json
  def destroy
    if current_user.can_edit?(@event)
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
    calendar_property = Property.find_by(name: "Calendar")
    if search_text.blank? || calendar_property == nil
      redirect_to :back
    else
      selector = Event.beginning(Setting.current_era.starts_on)
      unless current_user && current_user.staff?
        selector = selector.involving(calendar_property.element)
      end
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

#      if current_user && current_user.known?
#        @found_events =
#          Event.beginning(Setting.current_era.starts_on).
#                where("body like ?", "%" + search_text + "%").
#                order(:starts_at).
#                page(params[:page])
#      else
#        @found_events =
#          Event.beginning(Setting.current_era.starts_on).
#                involving(calendar_property.element).
#                where("body like ?", "%" + search_text + "%").
#                order(:starts_at).
#                page(params[:page])
#      end
    end
  end

  private
    def authorized?(action = action_name, resource = nil)
      (logged_in? && current_user.create_events?) ||
      action == 'show' || action == "search"
    end

    # Use callbacks to share common setup or constraints between actions.
    def set_event
      @event = Event.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def event_params
      params.require(:event).permit(:body, :eventcategory_id, :eventsource_id, :owner_id, :integer, :starts_at_text, :ends_at_text, :all_day_field, :approximate, :non_existent, :private, :reference_id, :reference_type, :new_end, :organiser_name, :organiser_id, :organiser_ref, :precommit_element_id)
    end
end
