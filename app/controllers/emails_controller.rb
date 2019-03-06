# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2019 John Winters
# See COPYING and LICENCE in the root directory of the application
# for more information.

class EmailsController < ApplicationController
  before_action :set_user, only: [:index]
  before_action :set_email, only: [:show, :edit, :update, :destroy]

  # GET /emails
  # GET /emails.json
  def index
    if @user
      selector = @user.messages
    else
      selector = Ahoy::Message
    end
    @emails = selector.paginate({
      page: params[:page],
      per_page: 15
    }).order('sent_at DESC')
  end

  # GET /emails/1
  # GET /emails/1.json
  def show
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_email
    @email = Ahoy::Message.find(params[:id])
  end

  def set_user
    if params[:user_id]
      @user = User.find(params[:user_id])
    end
  end

end

