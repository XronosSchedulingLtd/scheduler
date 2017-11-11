module ApplicationHelper

  def title_text
    if known_user?
      @logged_in_title_text ||= (ENV["SCHEDULER_TITLE_TEXT"] || "Scheduler")
    else
      @public_title_text ||= (ENV["PUBLIC_TITLE_TEXT"] || "Scheduler")
    end
  end

  def single_flag(f, content)
    if content[:annotation]
      #
      #  Explicit annotation given.
      #
      annotation = content[:annotation]
    else
      #
      #  Can the model supply anything?
      #
      if f.object.respond_to?(:field_title_text)
        annotation = f.object.field_title_text(content[:field])
      else
        annotation = ""
      end
    end
    result = Array.new
    if content[:disabled]
      result << "    #{f.check_box(content[:field], disabled: true)}"
    else
      result << "    #{f.check_box(content[:field],
                                   title: annotation)}"
    end
    if content[:prompt]
      result << "    #{f.label(content[:field],
                               content[:prompt],
                               title: annotation)}"
    else
      result << "    #{f.label(content[:field],
                               title: annotation)}"
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

  #
  #  Take a piece of plain text, with line breaks, and convert it to
  #  the equivalent HTML with <br/> characters.  Escape any dangerous
  #  input, and flag the result as html_safe.
  #
  def preserve_line_breaks(text)
    h(text).gsub("\n", '<br/>').html_safe
  end

end
