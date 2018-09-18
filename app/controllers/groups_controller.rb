# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2014 John Winters
# See COPYING and LICENCE in the root directory of the application
# for more information.

require 'csv'

class GroupsController < ApplicationController
  before_action :set_group, only: [:show,
                                   :edit,
                                   :update,
                                   :destroy,
                                   :members,
                                   :do_clone,
                                   :flatten]

  # GET /groups
  # GET /groups.json
  def index
    #
    #  Need an element to make the finder box work.
    #
    @element = Element.new
    if current_user.admin && !params[:mine]
      if params[:resource]
        selector = Group.resourcegroups.current.order('name')
        @heading = "resource groups"
        @type_to_create = :resource
        @which_finder = :resource
      else
        selector = Group.current.order('name')
        @heading = "all groups"
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
        element_id = params[:element_id]
        unless element_id.blank?
          #
          #  Seem to want to jump to a particular group.
          #  Use find_by to avoid raising an error.
          #
          target_element = Element.agroup.find_by(id: element_id)
          if target_element
            index = selector.find_index {|g| g.id == target_element.entity_id}
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
    else
      @type = :vanilla
    end
    @group = Vanillagroup.new({
      era:           Setting.current_era,
      current:       true
    })
  end

  # GET /groups/1/edit
  def edit
    unless params[:just_created]
      session[:go_back_to] = request.env['HTTP_REFERER']
    end
    if current_user.can_edit?(@group)
      @membership = Membership.new
      @membership.group = @group
      @exclusion = Membership.new
      @exclusion.group = @group
      @exclusion.inverse = true
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
    redirect_to edit_group_path(@new_group)
  end

  # POST /groups/1/flatten
  def flatten
    @new_group = @group.do_clone
    @new_group.flatten
    redirect_to edit_group_path(@new_group)
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

  private
    def authorized?(action = action_name, resource = nil)
      logged_in? && (current_user.create_groups? || action == 'index')
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
                                    :make_public)
    end
end
