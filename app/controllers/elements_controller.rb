class ElementsController < ApplicationController
  autocomplete :element, :name

  def authorized?(action = action_name, resource = nil)
    logged_in? && current_user.known?
  end
end
