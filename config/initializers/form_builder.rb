class ActionView::Helpers::FormBuilder

  def configured_date_field(selector, **options)
    if Setting.current.dp_jquery?
      #
      #  We want to add a class of datepicker to the options.
      #  There may or may not already be some classes specified
      #  there, and they could be an array, a string or a symbol.
      #
      existing = options[:class]
      if existing
        case existing
        when String
          options[:class] = "#{existing} datepicker"
        when Symbol
          options[:class] = [existing, :datepicker]
        when Array
          options[:class] << :datepicker
        end
      else
        options[:class] = :datepicker
      end
      options[:autocomplete] = :off
      self.text_field(selector, options)
    else
      self.date_field(selector, options)
    end
  end

end
