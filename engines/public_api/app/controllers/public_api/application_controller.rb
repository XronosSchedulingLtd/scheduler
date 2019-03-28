# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2019 John Winters
# See COPYING and LICENCE in the root directory of the application
# for more information.

module PublicApi
  class ApplicationController < ActionController::Base

    class ModelHasher
      #
      #  An object which knows how to build suitable hashes from
      #  our ActiveModel records to send with Json.
      #
      #  You can pass in either a single record, or an array of them.
      #
      #  We might in the future add the means to request extra fields.
      #

      def summary_from(data)
        if data.respond_to?(:collect)
          data.collect {|item| item_summary(item)}
        else
          item_summary(data)
        end
      end

      def detail_from(data)
        if data.respond_to?(:collect)
          data.collect {|item| item_detail(item)}
        else
          item_detail(data)
        end
      end

      private

      def item_summary(item)
        case item
        when Element
          {
            id:          item.id,
            name:        item.name,
            entity_type: item.entity_type,
            entity_id:   item.entity_id
          }
        when Request, Commitment
          {
            id: item.id,
            event: {
              id:        item.event.id,
              body:      item.event.body,
              starts_at: item.event.starts_at,
              ends_at:   item.event.ends_at,
              all_day:   item.event.all_day,
              elements:  self.summary_from(item.event.elements)
            }
          }
        else
          {}
        end
      end

      #
      #  Note that the purpose of this method is to provide detailed
      #  information about the item or items passed - the items themselves.
      #
      #  It would not be appropriate for it to look up the membership
      #  of a group and start giving details of that.  If you want
      #  details of each of the members, then look them up yourself and
      #  pass an array of them in to here.
      #
      def item_detail(item)
        case item
        when Element
          hash = {
            id:          item.id,
            name:        item.name,
            entity_type: item.entity_type,
            entity_id:   item.entity_id,
            current:     item.current
          }
          case item.entity_type
          when 'Staff'
            hash[:email]      = item.entity.email
            hash[:title]      = item.entity.title
            hash[:initials]   = item.entity.initials
            hash[:forename]   = item.entity.forename
            hash[:surname]    = item.entity.surname
          when 'Pupil'
            hash[:email]      = item.entity.email
            hash[:forename]   = item.entity.forename
            hash[:surname]    = item.entity.surname
            hash[:known_as]   = item.entity.known_as
            hash[:year_group] = item.entity.year_group
            hash[:house_name] = item.entity.house_name
          when 'Group'
            hash[:description] = item.entity.description
          else
          end
          hash
        else
          {}
        end
      end

    end

    protect_from_forgery with: :null_session

    before_action :login_required

    StatusTexts = {
      ok:                 'OK',
      created:            'Created',
      not_found:          'Not found',
      bad_request:        'Bad request',
      unauthorized:       'Access denied',
      method_not_allowed: 'Method not allowed'
    }
    StatusTexts.default = 'Unknown error'

    private

    #
    #  Shared between a couple of controllers.
    #
    def process_date_params(params)
      status = :ok
      message = nil
      #
      #  Default to just today.  If just a start date is given,
      #  then default to 1 day.
      #
      #  Note that here our end date is inclusive, which is less
      #  logical but appeals to end users.  Our groups unfortunately
      #  work that way, although the datetimes on our events don't.
      #
      start_date = Date.today
      end_date = Date.today
      if params[:start_date]
        #
        #  Attempted to set the start date.
        #
        start_date = Time.zone.parse(params[:start_date])
        if start_date
          if params[:end_date]
            end_date = Time.zone.parse(params[:end_date])
            unless end_date
              status = :bad_request
              message = 'End date not understood'
            end
          else
            end_date = start_date
          end
        else
          status = :bad_request
          message = 'Start date not understood'
        end
      else
        if params[:end_date]
          end_date = Time.zone.parse(params[:end_date])
          unless end_date
            status = :bad_request
            message = 'End date not understood'
          end
        end
      end
      if status == :ok
        if end_date < start_date
          status = :bad_request
          message = "End date before start date"
        end
      end
      return [status, message, start_date, end_date]
    end

    def status_text(code)
      StatusTexts[code]
    end

    def current_user
      @current_user ||=
        User.find_by(id: session[:user_id]) if session[:user_id]
    end

    def logged_in?
      !!current_user
    end

    def login_required
      authorized? || access_denied
    end

    def access_denied
      respond_to do |format|
        format.html do
          #
          #  Shouldn't be getting HTML requests at all.
          #  Send them back to the application proper
          #
          redirect_to '/'
        end
        format.json do
          render json: { status: 'Access denied' }, status: :unauthorized
        end
      end
    end

    def authorized?(action = action_name, resource = nil)
      Rails.logger.debug("session[:user_id] = #{session[:user_id]}")
      logged_in? && current_user.can_api? && request.format == 'json'
    end

  end
end
