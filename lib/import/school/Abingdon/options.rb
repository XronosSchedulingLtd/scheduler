class Options
  alias_methodl :old_more_defaults, :more_defaults

  def more_defaults
    old_more_defaults
    #
    #  This saves having to add these on the command line.
    #
    @activities = true
    @cover      = true
  end
end
