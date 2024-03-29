class PropertiesController < ApplicationController
  before_action :set_property, only: [:show, :edit, :update, :destroy]

  # GET /properties
  # GET /properties.json
  def index
    @properties = Property.page(params[:page]).order('name')
  end

  # GET /properties/1
  # GET /properties/1.json
  def show
  end

  # GET /properties/new
  def new
    @property = Property.new
  end

  # GET /properties/1/edit
  def edit
  end

  # POST /properties
  # POST /properties.json
  def create
    @property = Property.new(property_params)

    respond_to do |format|
      if @property.save
        format.html { redirect_to properties_path, notice: 'Property was successfully created.' }
        format.json { render :show, status: :created, property: @property }
      else
        format.html { render :new }
        format.json { render json: @property.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /properties/1
  # PATCH/PUT /properties/1.json
  def update
    respond_to do |format|
      if @property.update(property_params)
        format.html { redirect_to properties_path,
                      notice: 'Property was successfully updated.' }
        format.json { render :show, status: :ok, property: @property }
      else
        format.html { render :edit }
        format.json { render json: @property.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /properties/1
  # DELETE /properties/1.json
  def destroy
    if @property.can_destroy?
      @property.destroy
      respond_to do |format|
        format.html { redirect_back fallback_location: root_path }
        format.json { head :no_content }
      end
    else
      redirect_back fallback_location: root_path
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_property
      @property = Property.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def property_params
      params.require(:property).permit(:name,
                                       :current,
                                       :make_public,
                                       :auto_staff,
                                       :auto_pupils,
                                       :feed_as_category,
                                       :edit_preferred_colour,
                                       :force_colour,
                                       :force_weight,
                                       :locking)
    end
end
