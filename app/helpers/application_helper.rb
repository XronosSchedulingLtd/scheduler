module ApplicationHelper

  def title_text
    if known_user?
      @logged_in_title_text ||= (ENV["SCHEDULER_TITLE_TEXT"] || "Scheduler")
    else
      @public_title_text ||= (ENV["PUBLIC_TITLE_TEXT"] || "Scheduler")
    end
  end

  def known_user?
    current_user && current_user.known?
  end

  def admin_user?
    current_user && current_user.admin?
  end

  def public_groups_user?
    current_user && current_user.public_groups?
  end

  def single_flag(f, content)
    result = Array.new
    if content[:disabled]
      result << "    #{f.check_box(content[:field], disabled: true)}"
    else
      result << "    #{f.check_box(content[:field],
                                   title: content[:annotation])}"
    end
    if content[:prompt]
      result << "    #{f.label(content[:field],
                               content[:prompt],
                               title: content[:annotation])}"
    else
      result << "    #{f.label(content[:field],
                               title: content[:annotation])}"
    end
    result.join("\n").html_safe
  end

  def flag_group(f, small_cols, med_cols, label, contents)
    result = Array.new
    result << "<div class='small-#{small_cols} medium-#{med_cols} columns'>"
    result << "  <label>#{label}</label>"
    contents.each_with_index do |content, i|
      result << single_flag(f, content)
      if (i + 1) % 3 == 0
        result << "<br/>"
      end
    end
    result << "</div>"
    result.join("\n").html_safe
  end
end
