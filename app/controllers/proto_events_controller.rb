class ProtoEventsController < ApplicationController
  wrap_parameters :proto_event,
                  include: [:starts_on_text, :ends_on_text, :rota_template_id]
  before_action :find_exam_cycle, except: [:split]
  before_action :set_proto_event, only: [:show, :edit, :update, :destroy, :generate, :split]

  # GET /proto_events
  # GET /proto_events.json
  def index
    @proto_events = @exam_cycle.proto_events
  end

  # GET /proto_events/1
  # GET /proto_events/1.json
  def show
  end

  # GET /proto_events/new
  def new
    @proto_event = ProtoEvent.new
  end

  # GET /proto_events/1/edit
  def edit
  end

  # POST /proto_events
  # POST /proto_events.json
  def create
    @proto_event = @exam_cycle.proto_events.new(proto_event_params)
    @proto_event.body = "Invigilation"
    #
    #  For now this is hard-coded as we only support proto events in
    #  the context of exam invigilations.  Later on it will need to
    #  be context-sensitive.
    #
    @proto_event.eventcategory = Eventcategory.cached_category("Invigilation")
    #
    #  Originally I set the source here to be ProtoEvent, but then realised
    #  that we already know that - the event will be linked to a ProtoEvent.
    #  When it comes to identifying each individual actual event, we
    #  need to refer back to its RotaSlot.  The source_id will be the
    #  RotaSlot's ID, and so this field should match.
    #
    @proto_event.eventsource = Eventsource.find_by(name: "RotaSlot")
    #
    #  The new proto_event also needs linking to a room, but this
    #  can't be done until after it has been saved.
    #
    #  We also want to add a ProtoRequest, indicating that staff
    #  are required - defaulting to 0.  In the future, this will
    #  need to be made configurable, but as all we're dealing with now
    #  is exam invigilation it can be hard-coded.  We're building
    #  a general purpose structure, but currently using it for
    #  only one purpose.
    #
    if @proto_event.save_with_location(params[:location_id])
      if @exam_cycle.default_group_element
        @proto_event.proto_requests.create({
          element: @exam_cycle.default_group_element,
          quantity: @exam_cycle.default_quantity
        })
      end
      property = Property.find_by(name: "Invigilation")
      if property
        @proto_event.proto_commitments.create({
          element: property.element
        })
      end
      respond_to do |format|
        format.json { render :show, status: :created }
      end
    else
      respond_to do |format|
        format.json { render json: @proto_event.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /proto_events/1
  # PATCH/PUT /proto_events/1.json
  def update
    respond_to do |format|
      if @proto_event.update_with_location(proto_event_params,
                                           params[:location_id])
        format.html { redirect_to @proto_event, notice: 'Proto event was successfully updated.' }
        format.json { render :show, status: :ok }
      else
        format.html { render :edit }
        format.json { render json: @proto_event.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /exam_cycles/1/proto_events/1/generate.json
  def generate
    @proto_event.ensure_required_events
    respond_to do |format|
      format.json { render :show, status: :ok }
    end
  end

  # POST
  def split
    proposed_date = Date.safe_parse(params[:afterdate])
    if proposed_date
      new_pe = @proto_event.split(proposed_date)
      if new_pe
        #
        #  We will send back details of the new proto_event.
        #
        @proto_event = new_pe
        respond_to do |format|
          format.json { render :show, status: :ok }
        end
      else
        respond_to do |format|
          format.json { render :show, status: :error }
        end
      end
    else
      respond_to do |format|
        format.json { render :show, status: :error }
      end
    end
  end

  # DELETE /proto_events/1
  # DELETE /proto_events/1.json
  def destroy
    if @proto_event.can_destroy?
      @proto_event.destroy
    end
    respond_to do |format|
      format.html { redirect_to proto_events_url }
      format.json { head :no_content }
    end
  end

  private
    def authorized?(action = action_name, resource = nil)
      logged_in? && (current_user.admin || current_user.exams?)
    end

    # Use callbacks to share common setup or constraints between actions.
    def set_proto_event
      @proto_event = ProtoEvent.find(params[:id])
    end

    def find_exam_cycle
      @exam_cycle = ExamCycle.find(params[:exam_cycle_id])
    end
                                         
    # Never trust parameters from the scary internet, only allow the white list through.
    def proto_event_params
      params.require(:proto_event).permit(:rota_template_id,
                                          :starts_on_text,
                                          :ends_on_text)
    end
end
