class SubjectsController < ApplicationController
  before_action :set_subject, only: [:show, :edit, :update, :destroy]

  # GET /subjects
  # GET /subjects.json
  def index
    @subjects = Subject.includes(:datasource).page(params[:page]).order('name')
    @manual_datasource = Datasource.find_by(name: "Manual")
  end

  # GET /subjects/1
  # GET /subjects/1.json
  def show
  end

  # GET /subjects/new
  def new
    manual_source = Datasource.find_by(name: "Manual")
    if manual_source
      @subject = manual_source.subjects.new
    else
      @subject = Subject.new
    end
    @all_fields = true
  end

  # GET /subjects/1/edit
  def edit
    manual_source = Datasource.find_by(name: "Manual")
    @all_fields = @subject.datasource == manual_source
  end

  # POST /subjects
  # POST /subjects.json
  def create
    manual_source = Datasource.find_by(name: "Manual")
    if manual_source
      @subject = manual_source.subjects.new(subject_params)
    else
      @subject = Subject.new(subject_params)
    end

    respond_to do |format|
      if @subject.save
        format.html { redirect_to subjects_path, notice: 'Subject was successfully created.' }
        format.json { render :show, status: :created, subject: @subject }
      else
        format.html { render :new }
        format.json { render json: @subject.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /subjects/1
  # PATCH/PUT /subjects/1.json
  def update
    respond_to do |format|
      if @subject.update(subject_params)
        format.html { redirect_to subjects_path,
                      notice: 'Subject was successfully updated.' }
        format.json { render :show, status: :ok, subject: @subject }
      else
        format.html { render :edit }
        format.json { render json: @subject.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /subjects/1
  # DELETE /subjects/1.json
  def destroy
    if @subject.can_destroy?
      @subject.destroy
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
    def set_subject
      @subject = Subject.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def subject_params
      params.require(:subject).permit(:name, :current, :missable)
    end
end
