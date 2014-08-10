class ElementsController < ApplicationController

  #
  #  It would be nice to be able to use a line like the following to
  #  generate by action, but unfortunately one of my scopes needs
  #  a parameter.  Hence I have to do it manually.
  #
  #autocomplete :element, :name, :scopes => [:current, :mine_or_system], :full => true

  def autocomplete_element_name
    term = params[:term]
    elements =
      Element.current.mine_or_system(current_user).where('name LIKE ?', "%#{term}%").order(:name).all
    render :json => elements.map { |element| {:id => element.id, :label => element.name, :value => element.name} }
  end

  def authorized?(action = action_name, resource = nil)
    logged_in? && current_user.known?
  end
end
