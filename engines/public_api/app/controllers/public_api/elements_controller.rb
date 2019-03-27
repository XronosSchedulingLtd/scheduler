# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2019 John Winters
# See COPYING and LICENCE in the root directory of the application
# for more information.

module PublicApi

  class ElementsController < PublicApi::ApplicationController

    def index
      #
      #  Although this is an index function, we expect to be given
      #  some more parameters.  Returning an index of all the elements
      #  would mean sending quite a lot and could be some kind of
      #  security risk.
      #
      #  We take the view that if they don't send any parameters,
      #  we don't return any elements.  You didn't ask for any
      #  so you don't get any.
      #
      if params[:name]
        @elements = Element.current.where(name: params[:name])
        if @elements.empty?
          status = :not_found
          status_text = 'Not found'
        else
          status = :ok
          status_text = 'OK'
        end
      elsif params[:namelike]
        @elements =
          Element.current.where("name LIKE ?", "%#{params[:namelike]}%")
        if @elements.empty?
          status = :not_found
          status_text = 'Not found'
        else
          status = :ok
          status_text = 'OK'
        end
      else
        @elements = []
        status = :ok
        status_text = 'OK'
      end
      hashes = @elements.collect {|e| e.hash_of([:id, :name, :entity_type])}
      render json: {
        status: status_text,
        elements: hashes
      }, status: status
    end

    def show
      #
      #  We use find_by rather than find because we want to handle
      #  the non-existence case explicitly and tidily rather than
      #  throwing the caller into a generic error handler.
      #
      @element = Element.find_by(id: params[:id])
      if @element
        render json: {
          status: "OK",
          element: @element.hash_of([:id, :name, :entity_type])
        }
      else
        render json: {status: "Not found"}, status: :not_found
      end
    end

  end

end
