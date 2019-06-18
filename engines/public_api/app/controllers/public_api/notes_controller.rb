# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2019 John Winters
# See COPYING and LICENCE in the root directory of the application
# for more information.

module PublicApi

  class NotesController < PublicApi::ApplicationController

    before_action :find_event, only: [:index, :create]
    before_action :find_note, only: [:show, :update, :destroy]

    # GET /event/1/notes.json
    #
    def index
      status = :ok
      requests = nil
      message  = nil
      notes = @event.notes
      #
      #  And send our response.
      #
      json_result = {
        status: status_text(status)
      }
      if notes
        json_result[:notes] =
          ModelHasher.new.summary_from(notes, @event)
      end
      if message
        json_result[:message] = message
      end
      render json: json_result, status: status
    end

    # POST /event/1/notes.json
    #
    def create
      note = nil
      if current_user.can_add_notes?
        note = @event.notes.create(note_params.merge(owner: current_user))
        if note.valid?
          status = :ok
        else
          status = :unprocessable_entity
        end
      else
        status = :forbidden
      end
      mh = ModelHasher.new
      json_result = {
        status: status_text(status)
      }
      if note
        json_result[:note] = mh.summary_from(note, @event)
      end
      render json: json_result, status: status
    end

    # GET /notes/1.json
    #
    def show
      status = :ok
      mh = ModelHasher.new
      json_result = {
        status: status_text(status),
        note: mh.detail_from(@note)
      }
      render json: json_result, status: status
    end

    # PUT /notes/1.json
    #
    def update
      if current_user.can_edit?(@note)
        if @note.update(note_params)
          status = :ok
        else
          status = :unprocessable_entity
        end
      else
        status = :forbidden
      end
      mh = ModelHasher.new
      json_result = {
        status: status_text(status),
        note: mh.summary_from(@note)
      }
      render json: json_result, status: status
    end

    # DELETE /notes/1.json
    #
    def destroy
      if current_user.can_delete?(@note)
        @note.destroy
        status = :ok
      else
        status = :forbidden
      end
      json_result = {
        status: status_text(status)
      }
      render json: json_result, status: status
    end

    private

    def find_event
      @event = Event.find(params[:event_id])
    end

    def find_note
      @note = Note.find(params[:id])
    end

    def note_params
      params.require(:note).permit(:title,
                                   :contents,
                                   :visible_guest,
                                   :visible_staff,
                                   :visible_pupil)
    end
  end

end
