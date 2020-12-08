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

  def sane_time_field(selector, **options)
    #
    #  By default, the Rails time_field builder uses %T.%L as its
    #  format string, resulting in stuff like "08:30:00.000", but
    #  then Tod::TimeOfDay can't parse that if/when it comes back.
    #  Let's have just "08:30:00" instead.
    #
    unless options[:value]
      item = @object[selector]
      if item.respond_to?(:strftime)
        options[:value] = item.strftime("%H:%M:%S")
      end
    end
    self.time_field(selector, options)
  end

end
