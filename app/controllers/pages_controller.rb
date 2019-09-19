class PagesController < ApplicationController
  def error_404
    render status: 404
  end

  private

  def authorized?
    true
  end
end
