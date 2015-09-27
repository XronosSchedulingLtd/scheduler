module ApplicationHelper

  def title_text
    @title_text ||= (ENV["SCHEDULER_TITLE_TEXT"] || "Scheduler")
  end

  def known_user?
    current_user && current_user.known?
  end
end
