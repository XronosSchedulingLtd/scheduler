# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2019 John Winters
# See COPYING and LICENCE in the root directory of the application
# for more information.

class CommentsController < ApplicationController
  prepend_before_action :find_comment, only: [:destroy]
  prepend_before_action :find_user_form_response, only: [:create]

  def create
    do_pushback = (params[:subaction] == 'pushback')
    @comment =
      @user_form_response.comments.new(
        commitment_params.merge({user: current_user}))
    if @comment.save
      if do_pushback
        @user_form_response.pushback_and_save
      end
    end
    redirect_to :back
  end

  def destroy
    @comment.destroy
    redirect_to :back
  end

  private

  def find_comment
    @comment = Comment.find(params[:id])
  end

  def find_user_form_response
    @user_form_response = UserFormResponse.find(params[:user_form_response_id])
  end

  def commitment_params
    params.require(:comment).permit(:parent_id, :parent_type, :body)
  end

  def authorized?(action = action_name, resource = nil)
    result = false
    if logged_in?
      if current_user.admin
        result = true
      else
        case action
        when 'create'
          #
          #  If you're not an admin, then you must be a controller
          #  of the relevant resource.
          #
          #  linker may be either a Request or a Commitment
          #
          linker = @user_form_response.parent
          if linker
            element = linker.element
            if element
              result = current_user.owns?(element)
            end
          end
        when 'destroy'
          #
          #  You must be either admin, or the owner of the comment.
          #  It is policed by the method in the User model.
          #
          result = current_user.can_delete?(@comment)
        end
      end
    end
    result
  end

end

