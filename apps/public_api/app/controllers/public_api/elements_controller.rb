# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2019 John Winters
# See COPYING and LICENCE in the root directory of the application
# for more information.

module PublicApi

  class ElementsController < PublicApi::ApplicationController
    DEFAULT_LIMIT = 10

    def index
      @elements = Element.first(DEFAULT_LIMIT)
      render json: @elements
    end
  end

end
