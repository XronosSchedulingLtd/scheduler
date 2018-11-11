module DisplaySettings
  #
  #  This needs to be in a module because it adds instance variables
  #  to the calling class.
  #
  def setvars_for_lhs(user)
    @concerns     = Array.new
    if user && user.known?
      @user         = user
      @with_edit    = user.create_events?
      @selector_box = user.can_add_concerns
      @do_filters   = true
      @do_views     = user.can_add_concerns || !user.concern_sets.empty?
      @userid       = user.id
      @filter_state = user.filter_state
      if user.current_concern_set
        name = user.current_concern_set.name
        @current_view = name.truncate(12)
        if name.size > 12
          @current_view_hover_text = name
        end
      else
        @current_view = ConcernSet::DefaultViewName
      end

      @my_events    = user.editor?
      #
      #  If they can't add them, then they can't delete them.
      #
      @third_column = user.can_add_concerns
      @first_day    = user.safe_firstday
      if user.current_concern_set
        @concerns = user.current_concern_set.concerns.to_a
      else
        @concerns = user.concerns.me.default_view.to_a
        @concerns += user.concerns.not_me.default_view.sort.to_a
      end
    else
      @user         = User.new
      @with_edit    = false
      @selector_box = false
      @do_filters   = false
      @do_views     = false
      @filter_state = "unknown"
      @my_events    = false
      @third_column = false
      @first_day    = 0
      Property.public_ones.each do |p|
        fake_id = "E#{p.element.id}"
        @concerns << Concern.new({
          element: p.element,
          colour: p.element.preferred_colour,
          fake_id: fake_id,
          #
          #  This next line looks a trifle weird, but we want the case
          #  of no entry at all in the session to cause it to be set
          #  to true.  Only if it's actively been given a false
          #  value do we make it invisible.
          #
          visible: session[fake_id] != false
        })
      end
    end
  end

end
