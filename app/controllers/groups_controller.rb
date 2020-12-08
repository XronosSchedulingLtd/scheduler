# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2014 John Winters
# See COPYING and LICENCE in the root directory of the application
# for more information.

require 'csv'

class GroupsController < ApplicationController
  include DisplaySettings

  layout 'schedule', only: [:schedule]

  before_action :set_group, only: [:show,
                                   :edit,
                                   :update,
                                   :destroy,
                                   :members,
                                   :do_clone,
                                   :flatten,
                                   :reinstate,
                                   :schedule,
                                   :scheduleresources,
                                   :scheduleevents]

  # GET /groups
  # GET /groups.json
  def index
    #
    #  Need a group to make the finder box work.
    #
    @group = Group.new
    @reinstate_button = false
    @allow_membership_editing = current_user.can_edit_memberships?
    if admin_user? && !params[:mine]
      @list_type  = true
      @list_owner = true
      @span_cols  = 4
      if params[:resource]
        selector = Group.resourcegroups.current.order('name')
        @heading = "resource groups"
        @type_to_create = :resource
        @which_finder = :resource
      elsif params[:owned]
        if params[:historical]
          selector = Group.has_owner.historical.order('name')
          @heading = "past owned groups"
          @which_finder = :old_owned
        else
          selector = Group.has_owner.current.order('name')
          @heading = "owned groups"
          @which_finder = :owned
        end
        @type_to_create = :vanilla
      elsif params[:deleted]
        selector = Group.historical.order('name')
        @heading = "all deleted groups"
        @type_to_create = :vanilla
        @which_finder = :deleted
        @reinstate_button = true
      else
        selector = Group.current.order('name')
        @heading = "all current groups"
        @type_to_create = :vanilla
        @which_finder = :all
      end
      @paginate = true
      @separate = false
      #
      #  It's possible that we have been asked to display the page
      #  containing a particular group.
      #
      page_param = params[:page]
      if page_param.blank?
        #
        #  Default to page 1.
        #
        page_param = "1"
        #
        #  Although we portray to the user that they are searching
        #  for a group, what we actually search on is element.  Thus
        #  we get an element id returned.
        #
        #  Note that it is just possible that the user will force
        #  in what is a valid element id, but not for a group.
        #
        group_id = params[:group_id]
        unless group_id.blank?
          #
          #  Seem to want to jump to a particular group.
          #  Use find_by to avoid raising an error.
          #
          target_group = Group.find_by(id: group_id)
          if target_group
            index = selector.find_index {|g| g.id == target_group.id}
            if index
              page_param = ((index / Group.per_page) + 1).to_s
            end
          end
        end
      end
      @groups = selector.page(page_param)
    else
      @groups = Group.current.belonging_to(current_user).order('name')
      @heading = "my groups"
      @list_owner = false
      @list_type  = false
      @span_cols  = 2
      @public_groups, @private_groups = @groups.partition {|g| g.make_public}
      @separate = !(@public_groups.empty? || @private_groups.empty?)
      @paginate = false
      @type_to_create = :vanilla
      @which_finder = :mine
    end
  end

  # GET /groups/1
  # GET /groups/1.json
  def show
    @go_back_to = request.env['HTTP_REFERER']
    @atomic_membership = @group.atomic_membership
  end

  # GET /groups/new
  def new
    @go_back_to = request.env['HTTP_REFERER']
    session[:go_back_to] = @go_back_to
    #
    #  We make a vanilla group regardless at this point, because
    #  it's only needed to allow the fields to be created.  However,
    #  we remember what kind it was that the user asked for.
    #
    if params[:type] == 'resource'
      @type = :resource
      group_class = Resourcegroup
    else
      @type = :vanilla
      group_class = Vanillagroup
    end
    @group = group_class.new({
      era:           Setting.current_era,
      current:       true
    })
  end

  # GET /groups/1/edit
  def edit
    if params[:just_created]
      session[:go_back_to] = groups_path(mine: true)
    else
      session[:go_back_to] = request.env['HTTP_REFERER']
    end
    if current_user.can_edit?(@group)
      @membership = @group.memberships.new
      @exclusion  = @group.memberships.new({inverse: true})
      @atomic_membership = @group.atomic_membership
    else
      #
      #  If somebody has got here then they're playing at silly buggers.
      #  Let's not be helpful.
      #
      redirect_to :root
    end
  end

  # POST /groups
  # POST /groups.json
  def create
    if params[:type] == 'resource'
      group_class = Resourcegroup
    else
      group_class = Vanillagroup
    end
    @group = group_class.new(group_params)
    @group.starts_on ||= Date.today
    @group.owner = current_user

    respond_to do |format|
      if @group.save
        format.html { redirect_to edit_group_path(@group, just_created: true), notice: 'Group was successfully created.' }
        format.json { render :show, status: :created, location: @group }
      else
        @membership = @group.memberships.new
        format.html { render :new }
        format.json { render json: @group.errors, status: :unprocessable_entity }
      end
    end
  end

  # POST /groups/1/do_clone
  def do_clone
    @new_group = @group.do_clone
    @new_group.owner = current_user
    #
    #  And round to edit it.
    #
    redirect_to edit_group_path(@new_group, just_created: true)
  end

  # POST /groups/1/flatten
  def flatten
    @new_group = @group.do_clone
    @new_group.flatten
    redirect_to edit_group_path(@new_group, just_created: true)
  end

  # PATCH/PUT /groups/1
  # PATCH/PUT /groups/1.json
  def update
    if current_user.can_edit?(@group)
      respond_to do |format|
        if @group.update(group_params)
          format.html { redirect_to back_or(groups_path),
                        notice: 'Group was successfully updated.' }
          format.json { render :show, status: :ok, location: @group }
        else
          format.html { render :edit }
          format.json { render json: @group.errors, status: :unprocessable_entity }
        end
      end
    else
      redirect_to :root
    end
  end

  # DELETE /groups/1
  # DELETE /groups/1.json
  def destroy
    session[:go_back_to] = request.env['HTTP_REFERER']
    if current_user.can_edit?(@group)
      @group.ceases_existence
      respond_to do |format|
        format.html { redirect_to back_or(groups_url) }
        format.json { head :no_content }
      end
    else
      redirect_to :root
    end
  end

  # GET /groups/1/members
  def members
    #
    #  What we actually do is to produce a listing of all the immediate
    #  members of this group, and explicit exclusions, and then further
    #  listings of all subsidiary groups.
    #
    #  Here we generate an array of groups, starting with this one
    #  and followed by all the ones on which it depends.
    #
    @groups_to_list = @group.influencing_groups
    respond_to do |format|
      format.csv
    end
  end

  def reinstate
    unless @group.current
      @group.reincarnate(true)
    end
    redirect_back fallback_location: root_path
  end

  # GET /groups/1/schedule
  #
  def schedule
    if params[:date]
      session[:allocation_start_date] = Time.zone.parse(params[:date])
      redirect_to request.path
    else
      start_at = session[:allocation_start_date] || Time.zone.now
      session.delete(:allocation_start_date)
      @default_date = start_at.strftime("%Y-%m-%d")
      respond_to do |format|
        format.html
      end
    end
  end

  # GET /groups/1/scheduleresources
  #
  def scheduleresources
    resources = GroupScheduler.new(@group).fc_resources
    respond_to do |format|
      format.json { render json: resources }
    end
  end

  # GET /groups/1/scheduleevents
  #
  def scheduleevents
    events = GroupScheduler.new(@group).fc_events(session, current_user, params)
    respond_to do |format|
      format.json { render json: events }
    end
  end

  def do_autocomplete(selector, org_term)
    term = org_term.split(" ").join("%")
    groups =
      selector.
              where('groups.name LIKE ?', "%#{term}%").
              order(Arel.sql("LENGTH(groups.name)")).
              order(:name).
              all
    render json: groups.map { |group|
      {
        id:    group.id,
        label: group.name,
        value: group.name
      }
    }
  end

  def autocomplete_group_name
    do_autocomplete(Group.current, params[:term])
  end

  def autocomplete_old_group_name
    do_autocomplete(Group.historical, params[:term])
  end

  def autocomplete_resourcegroup_name
    do_autocomplete(Group.resourcegroups.current, params[:term])
  end

  def autocomplete_owned_group_name
    do_autocomplete(Group.owned.current, params[:term])
  end

  def autocomplete_old_owned_group_name
    do_autocomplete(Group.owned.historical, params[:term])
  end

  private
    ALLOCATION_REQUESTS = [
      'schedule',
      'scheduleresources',
      'scheduleevents'
    ]

    def authorized?(action = action_name, resource = nil)
      if known_user?
        if ALLOCATION_REQUESTS.include?(action)
          #
          #  All users can access these screens - although they aren't
          #  given links to reach them - they just can't do anything
          #  to them.
          #
          #  Evaluating the right to edit them is quite costly, so we
          #  wait until the user actually attempts it.
          #
          true
        else
          current_user.can_has_groups?
        end
      else
        false
      end
    end

  # Use callbacks to share common setup or constraints between actions.
  def set_group
    @group = Group.find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def group_params
    params.require(:group).permit(:name,
                                  :era_id,
                                  :current,
                                  :source_id,
                                  :make_public,
                                  :edit_preferred_colour,
                                  :loading_report_days,
                                  :wrapping_mins,
                                  :confirmation_days,
                                  :form_warning_days,
                                  :needs_people)
  end

  def back_or(fallback_location)
    session[:go_back_to] || fallback_location
  end

end
