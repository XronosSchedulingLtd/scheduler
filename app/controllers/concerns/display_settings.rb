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
      @my_events    = user.editor
      #
      #  If they can't add them, then they can't delete them.
      #
      @third_column = user.can_add_concerns
      @first_day    = user.safe_firstday
      @concerns += user.concerns.me.to_a
      @concerns += user.concerns.not_me.sort.to_a
    else
      @user         = User.new
      @with_edit    = false
      @selector_box = false
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