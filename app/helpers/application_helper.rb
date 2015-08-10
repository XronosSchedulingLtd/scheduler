module ApplicationHelper

  def title_text
    @title_text ||= (ENV["SCHEDULER_TITLE_TEXT"] || "Scheduler")
  end
end
