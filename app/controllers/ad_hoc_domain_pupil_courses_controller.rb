class AdHocDomainPupilCoursesController < ApplicationController

  include AdHoc

  before_action :set_ad_hoc_domain_staff, only: [:create]
  before_action :set_ad_hoc_domain_pupil_course, only: [:destroy, :update]

  # POST /ad_hoc_domain_staff/1/ad_hoc_domain_staffs
  # POST /ad_hoc_domain_staff/1/ad_hoc_domain_staffs.json
  def create
    @ad_hoc_domain_pupil_course =
      @ad_hoc_domain_staff.ad_hoc_domain_pupil_courses.new(
        ad_hoc_domain_pupil_course_params)

    respond_to do |format|
      if @ad_hoc_domain_pupil_course.save
        #
        #  We're going to need to refresh the entire listing of staffs
        #  (because our new one could be anywhere in the list), which
        #  in turn needs a whole hierarchy of new blank records.
        #
        generate_blanks(@ad_hoc_domain_staff)
        @num_staff =
          @ad_hoc_domain_staff.ad_hoc_domain_subject.num_real_staff
        @num_pupils =
          @ad_hoc_domain_staff.ad_hoc_domain_subject.num_real_pupils
        format.js {
          render :created,
                  locals: {
                    owner_id: @ad_hoc_domain_staff.id,
                    grandparent_id: @ad_hoc_domain_subject.id
                  }
        }
      else
        format.js { render :createfailed,
                    status: :conflict,
                    locals: { owner_id: @ad_hoc_domain_staff.id} }
      end
    end
  end

  # PATCH /ad_hoc_domain_pupil_courses/1.json
  def update
    respond_to do |format|
      #
      #  Can update only the minutes field.
      #
      if @ad_hoc_domain_pupil_course.update(update_params)
        format.json
      else
        format.json {
          render json: { id: @ad_hoc_domain_pupil_course.id,
                         owner_id: @ad_hoc_domain_staff.id,
                         errors: @ad_hoc_domain_pupil_course.errors}, 
          status: :unprocessable_entity
        }
      end
    end
  end


  # DELETE /ad_hoc_domain_pupil_courses/1
  # DELETE /ad_hoc_domain_pupil_courses/1.json
  def destroy
    @ad_hoc_domain_pupil_course.destroy
    respond_to do |format|
      generate_blanks(@ad_hoc_domain_staff)
      @num_staff =
        @ad_hoc_domain_staff.ad_hoc_domain_subject.num_real_staff
      @num_pupils =
        @ad_hoc_domain_staff.ad_hoc_domain_subject.num_real_pupils
      format.js {
        render :destroyed,
               locals: {
                 owner_id: @ad_hoc_domain_staff.id,
                 grandparent_id: @ad_hoc_domain_subject.id
               }
      }
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_ad_hoc_domain_staff
    @ad_hoc_domain_staff =
      AdHocDomainStaff.includes(:ad_hoc_domain_subject).
                       find(params[:ad_hoc_domain_staff_id])
    @ad_hoc_domain_subject = @ad_hoc_domain_staff.ad_hoc_domain_subject
  end

  def set_ad_hoc_domain_pupil_course
    @ad_hoc_domain_pupil_course =
      AdHocDomainPupilCourse.includes(ad_hoc_domain_staff: :ad_hoc_domain_subject).
                             find(params[:id])
    @ad_hoc_domain_staff = @ad_hoc_domain_pupil_course.ad_hoc_domain_staff
    @ad_hoc_domain_subject = @ad_hoc_domain_staff.ad_hoc_domain_subject
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def ad_hoc_domain_pupil_course_params
    params.require(:ad_hoc_domain_pupil_course).
           permit(:pupil_element_name, :pupil_element_id, :minutes)
  end

  def update_params
    params.require(:ad_hoc_domain_pupil_course).
           permit(:minutes)
  end

end
