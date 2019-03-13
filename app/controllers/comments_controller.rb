# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2019 John Winters
# See COPYING and LICENCE in the root directory of the application
# for more information.

class CommentsController < ApplicationController
  before_action :find_comment, only: [:edit, :update]
  before_action :find_user_form_response, only: [:create]

  def create
    @comment =
      @user_form_response.comments.new(
        commitment_params.merge({user: current_user}))
    @comment.save
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
end

