# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2019 John Winters
# See COPYING and LICENCE in the root directory of the application
# for more information.

class EmailsController < ApplicationController
  prepend_before_action :set_user, only: [:index]
  prepend_before_action :set_email, only: [:show]

  class EamArray < Array
    #
    #  Pass an ActiveRecord relation.
    #
    def initialize(relation)
      super()
      @relation = relation
      relation.each do |email|
        self << EnhancedAhoyMessage.new(email)
      end
    end

    def total_pages
      @relation.total_pages
    end

    def current_page
      @relation.current_page
    end

  end

  # GET /emails
  # GET /emails.json
  def index
    if @user
      selector = @user.messages
      @provide_button = current_user.admin?
    else
      selector = Ahoy::Message
    end
    emails = selector.paginate({
      page: params[:page],
      per_page: 15
    }).order('sent_at DESC')
    @eams = EamArray.new(emails)
  end

  # GET /emails/1
  # GET /emails/1.json
  def show
    @modal = request.xhr?
    #
    #  Actually shows just part of an e-mail in a pop-up box.
    #
    #  Has the user specified which part?  If not, we show the first
    #  one.
    #
    if params[:part_no]
      part_no = params[:part_no].to_i
    else
      part_no = 0
    end
    eam = EnhancedAhoyMessage.new(@email)
    if part_no < eam.parts.count
      @part = eam.parts[part_no]
    else
      @part = eam.parts.first
    end
    #
    #  Is it text or HTML?
    #
    case @part.content_type
      when /\Atext\/html/
        @document = Nokogiri::HTML(@part.decoded)
        @html = @document.at('body').children.to_html
      else
        #
        #  Treat as text.
        #
        @text = @part.decoded
    end
    render layout: !@modal
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_email
    @email = Ahoy::Message.includes(:user).find(params[:id])
  end

  def set_user
    if params[:user_id]
      @user = User.find(params[:user_id])
    end
  end

  def authorized?(action = action_name, resource = nil)
    logged_in? &&
      (current_user.admin? ||
       (action == 'index' && @user == current_user) ||
       (action == 'show' && @email.user == current_user))
  end

end

