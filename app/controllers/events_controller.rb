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
    if request.xhr?
      if params[:date]
        start_date = Time.zone.parse(params[:date])
        @event.starts_at = start_date
        @event.ends_at   = start_date
        if start_date.hour == 0 &&
           start_date.min == 0
          @event.all_day = true
          @event.ends_at = start_date + 1.day
        end
      end
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
    @new_event = Event.new
    @new_event.owner = current_user
    @new_event.body          = @event.body
    @new_event.eventcategory = @event.eventcategory
    @new_event.eventsource   = Eventsource.find_by name: "Manual"
    @new_event.owner         = current_user
    @new_event.starts_at     = @event.starts_at
    @new_event.ends_at       = @event.ends_at
    @new_event.approximate   = @event.approximate
    @new_event.non_existent  = @event.non_existent
    @new_event.private       = @event.private
    @new_event.all_day       = @event.all_day
    @new_event.compound      = @event.compound
    @new_event.source_id     = @event.source_id
    @new_event.source_hash   = @event.source_hash
    @new_event.save!
    #
    #  And any associated resources.
    #
    @event.commitments.each do |commitment|
      #
      #  Cover commitments don't get cloned.
      #
      unless commitment.covering
        new_commitment = Commitment.new
        new_commitment.event       = @new_event
        new_commitment.element     = commitment.element
        new_commitment.names_event = commitment.names_event
        new_commitment.source_id   = commitment.source_id
        new_commitment.save!
      end
    end
    #
    #  And throw the user straight into editing it.
    #
    @event = @new_event
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

  private
    def authorized?(action = action_name, resource = nil)
      (logged_in? && current_user.create_events?) ||
      action == 'show'
    end

    # Use callbacks to share common setup or constraints between actions.
    def set_event
      @event = Event.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def event_params
      params.require(:event).permit(:body, :eventcategory_id, :eventsource_id, :owner_id, :integer, :starts_at_text, :ends_at_text, :all_day_field, :approximate, :non_existent, :private, :reference_id, :reference_type, :new_end)
    end
end
