# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2019 John Winters
# See COPYING and LICENCE in the root directory of the application
# for more information.

module PublicApi
  class ApplicationController < ActionController::Base

    include ControllerCommon

    class FailureRecord < Hash

      def initialize(item, index, element_id)
        super()
        self[:index]      = index
        self[:element_id] = element_id
        self[:item_type]  = item.class.to_s
        self[:item]       = item
      end

    end

    class ModelHasher
      #
      #  An object which knows how to build suitable hashes from
      #  our ActiveModel records to send with Json.
      #
      #  You can pass in either a single record, or an array of them.
      #
      #  We might in the future add the means to request extra fields.
      #

      def initialize(extras = {})
        @extras = extras
      end

      def summary_from(data, context = nil)
        if data.respond_to?(:collect)
          data.collect {|item| item_summary(item, context)}
        else
          item_summary(data, context)
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

      def item_summary(item, context = :none)
        #
        #  The context is where we came to this object from.
        #
        #  Thus, if we are looking at a commitment record in the
        #  context of an event, we don't want to see details
        #  of the event again, but we do want to know about the
        #  element.  Likewise if we are in the context of the
        #  element, we don't want to know about the element again,
        #  but we do want to know about the event.
        #
        #  Note the use of :none rather than nil for the default
        #  context.  This is so that if we compare it to a
        #  field in the item which happens to be nil, it won't
        #  match.
        #
        hash = nil
        case item
        when Element
          hash = {
            id:          item.id,
            name:        item.name,
            entity_type: item.entity_type,
            entity_id:   item.entity_id
          }
        when Request
          hash = {
            id:            item.id,
            quantity:      item.quantity,
            num_allocated: item.num_allocated
          }
          unless item.element == context
            hash[:element] = self.summary_from(item.element, item)
          end
          unless item.event == context
            hash[:event] = self.summary_from(item.event, item)
          end
        when Commitment
          hash = {
            id:     item.id,
            status: item.status
          }
          unless item.element == context
            hash[:element] = self.summary_from(item.element, item)
          end
          unless item.event == context
            hash[:event] = self.summary_from(item.event, item)
          end
        when Event
          hash = {
            id:        item.id,
            body:      item.body,
            starts_at: item.starts_at,
            ends_at:   item.ends_at,
            all_day:   item.all_day,
          }
          #
          #  If asked for an event in the context of something else,
          #  we just give the bare essentials (above).
          #
          unless context
            hash[:commitments] = self.summary_from(item.commitments, item)
            hash[:requests] = self.summary_from(item.requests, item)
          end
          #
          #  But the caller might want to know about teachers and/or rooms
          #
          if @extras[:staff]
            #
            #  Don't use staff_elements because we didn't do our database
            #  hit with that and so it will cause another hit.
            #
            hash[:staff] = item.commitments.collect { |c|
              if c.element.entity_type == "Staff"
                c.element.entity.initials
              else
                nil
              end
            }.compact.join(",")
          end
          if @extras[:locations]
            hash[:locations] = item.commitments.collect { |c|
              if c.element.entity_type == "Location"
                c.element.entity.name
              else
                nil
              end
            }.compact.join(",")
          end
        when Eventcategory
          hash = {
            id:   item.id,
            name: item.name
          }
        when Note
          #
          #  Note that this is used for both summary and detail
          #  responses.  There's too little to draw a useful
          #  dividing line between them.
          #
          hash = {
            id:                 item.id,
            contents:           item.contents,
            visible_guest:      item.visible_guest,
            visible_staff:      item.visible_staff,
            visible_pupil:      item.visible_pupil,
            formatted_contents: item.formatted_contents
          }
          unless item.parent == context
            hash[:parent] = self.summary_from(item.parent, item)
          end
          unless item.owner == context
            hash[:owner] = self.summary_from(item.owner, item)
          end
        when User
          hash = {
            id: item.id,
            name: item.name,
            email: item.email
          }

        when FailureRecord
          #
          #  This next bit looks a little weird.  The failure record
          #  contains an item which is one of:
          #
          #  * Commitment record
          #  * Request record
          #  * Hash
          #
          #  The first two need to be converted to hashes.  We do
          #  that and then supplant the entry in our new hash.
          #
          hash = item.merge({
            item: item_summary(item[:item], context)
          })
        end

        if hash
          #
          #  Item is some sort of model, or a FailureRecord.
          #
          if item.respond_to?(:valid?)
            #
            #  Checking validity can involve a number of database
            #  queries.  Avoid them if possible.
            #
            if item.persisted? && !item.changed?
              valid = true
            else
              valid = item.valid?
            end
            hash[:valid] = valid
            unless valid
              hash[:errors] = item.errors
            end
          end
          return hash
        else
          if item.nil?
            return nil
          elsif item.kind_of?(Hash)
            return item
          else
            return {}
          end
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
            hash[:members]     = item.entity.members.count
          when 'Property'
            hash[:make_public] = item.entity.make_public
            hash[:auto_staff]  = item.entity.auto_staff
            hash[:auto_pupils] = item.entity.auto_pupils
          end
          hash
        when Event
          hash = {
            id:          item.id,
            body:        item.body,
            starts_at:   item.starts_at,
            ends_at:     item.ends_at,
            all_day:     item.all_day,
            organiser:   self.summary_from(item.organiser),
            owner:       self.summary_from(item.owner),
            commitments: self.summary_from(item.commitments, item),
            requests:    self.summary_from(item.requests, item)
          }
        when Eventcategory
          hash = {
            id:            item.id,
            name:          item.name,
            pecking_order: item.pecking_order,
            schoolwide:    item.schoolwide,
            publish:       item.publish,
            visible:       item.visible,
            unimportant:   item.unimportant,
            can_merge:     item.can_merge,
            can_borrow:    item.can_borrow,
            compactable:   item.compactable,
            privileged:    item.privileged,
            clash_check:   item.clashcheck,
            busy:          item.busy,
            timetable:     item.timetable
          }
          hash
        when Note
          #
          #  There really is no point in trying to have two different
          #  representations of a note - there's so little in it.
          #
          item_summary(item)
        else
          {}
        end
      end

    end

    protect_from_forgery with: :null_session
    skip_before_action :verify_authenticity_token

    before_action :login_required

    rescue_from Exception do |exception|
      message = exception.to_s
      exception_class = exception.class.to_s
      status = :bad_request
      case exception
      when ActiveRecord::RecordNotFound
        status = :not_found
      end
      render json: {status: status_text(status),
                    exception: exception_class,
                    message: message}, status: status
    end

    StatusTexts = {
      ok:                   'OK',
      created:              'Created',
      not_found:            'Not found',
      bad_request:          'Bad request',
      unauthorized:         'Access denied',
      forbidden:            'Permission denied',
      method_not_allowed:   'Method not allowed',
      unprocessable_entity: 'Unable to process',
      service_unavailable:  'Service unavailable'
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
          render json: {
            status: status_text(:unauthorized)
          }, status: :unauthorized
        end
      end
    end

    #
    #  Check whether, given the current state of login/su, use of
    #  the API is permitted.
    #
    def we_can_api?
      #
      #  If we are in an su'ed state, then it's the original user
      #  who needs to have api permission.
      #
      if known_user?
        if original_user
          original_user.can_api?
        else
          current_user.can_api?
        end
      else
        false
      end
    end

    def authorized?(action = action_name, resource = nil)
      #
      #  Note that when su is in effect, it's the original user
      #  who needs to have the "can_api?" permission.
      #
      request.format == 'json' && we_can_api?
    end

    def set_appropriate_approval_status(commitment)
      #
      #  It's just possible that we will be passed nil for the element
      #  (if someone is trying to create a gash commitment).  Rather
      #  than raising an exception, return uncontrolled.
      #
      #  The saving of the commitment will fail due to the
      #  lack of an element.
      #
      if commitment.element
        if current_user.needs_permission_for?(commitment.element)
          commitment.status = :requested
        else
          commitment.status = :uncontrolled
        end
      else
        commitment.status = :uncontrolled
      end
    end
  end
end
