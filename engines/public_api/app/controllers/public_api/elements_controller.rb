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
        else
          status = :ok
        end
      elsif params[:namelike]
        @elements =
          Element.current.
                  where("name LIKE ?", "%#{params[:namelike]}%").
                  limit(100)
        if @elements.empty?
          status = :not_found
        else
          status = :ok
        end
      else
        @elements = []
        status = :ok
      end
      data = ModelHasher.new.summary_from(@elements)
      render json: {
        status: status_text(status),
        elements: data
      }, status: status
    end

    def show
      #
      #  We use find_by rather than find because we want to handle
      #  the non-existence case explicitly and tidily rather than
      #  throwing the caller into a generic error handler.
      #
      @element = Element.includes(:entity).find_by(id: params[:id])
      if @element
        render json: {
          status: "OK",
          element: ModelHasher.new.detail_from(@element)
        }
      else
        render json: {status: status_text(:not_found)}, status: :not_found
      end
    end

  end

end
