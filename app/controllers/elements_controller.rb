class ElementsController < ApplicationController
  autocomplete :element, :name, :scopes => [:current], :full => true

  def authorized?(action = action_name, resource = nil)
    logged_in? && current_user.known?
  end
end
