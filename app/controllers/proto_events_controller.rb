class ProtoEventsController < ApplicationController
  before_action :set_proto_event, only: [:show, :edit, :update, :destroy]

  # GET /proto_events
  # GET /proto_events.json
  def index
    @proto_events = ProtoEvent.all
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
    @proto_event = ProtoEvent.new(proto_event_params)

    respond_to do |format|
      if @proto_event.save
        format.html { redirect_to @proto_event, notice: 'Proto event was successfully created.' }
        format.json { render :show, status: :created, location: @proto_event }
      else
        format.html { render :new }
        format.json { render json: @proto_event.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /proto_events/1
  # PATCH/PUT /proto_events/1.json
  def update
    respond_to do |format|
      if @proto_event.update(proto_event_params)
        format.html { redirect_to @proto_event, notice: 'Proto event was successfully updated.' }
        format.json { render :show, status: :ok, location: @proto_event }
      else
        format.html { render :edit }
        format.json { render json: @proto_event.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /proto_events/1
  # DELETE /proto_events/1.json
  def destroy
    @proto_event.destroy
    respond_to do |format|
      format.html { redirect_to proto_events_url }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_proto_event
      @proto_event = ProtoEvent.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def proto_event_params
      params.require(:proto_event).permit(:body, :starts_on, :ends_on, :event_category_id, :event_source_id)
    end
end
