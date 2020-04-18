# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2017 John Winters
# See COPYING and LICENCE in the root directory of the application
# for more information.

class FilterManager

  attr_reader :positives, :negatives

  class FilterSlot
    attr_reader :title, :ticked, :id, :symbol

    #
    #  Type can be either :positive or :negative
    #
    #  The former means it's an extra category to add in, whilst the
    #  latter means it's one to subtract.  The difference comes in
    #  how we save them.  Negatives are stored in the d/b if unticked,
    #  whilst positives are stored if ticked.
    #
    #  Blank records in the database mean no negatives (nothing to
    #  subtract) and no positives (nothing to add).
    #
    def initialize(ec, user, type)
      @title = ec.name
      @id    = ec.id
      raise "Invalid FilterSlot type - #{type}" unless type == :positive ||
                                                       type == :negative
      @type  = type
      if @type == :negative
        #
        #  Each defaults to ticked, unless suppressed.
        #
        @ticked = !user.suppressed_eventcategories.include?(ec.id)
        @symbol = "fsn#{@id}".to_sym
      else
        @ticked = user.extra_eventcategories.include?(ec.id)
        @symbol = "fsp#{@id}".to_sym
      end
    end

    def to_partial_path
      "filterslot"
    end

    def set(new_value)
      modified = false
      if new_value.to_i == 1
        unless @ticked
          @ticked = true
          modified = true
        end
      else
        if @ticked
          @ticked = false
          modified = true
        end
      end
      modified
    end

  end

  class Filter
    attr_reader :num_columns, :columns, :slots

    def initialize(user, type, min_cols = 1)
      @user     = user
      @slots    = []
      @type     = type
      @min_cols = min_cols
    end

    PER_COLUMN = 10

    def generate_slots
      if @type == :positive
        Eventcategory.available.invisible.sort.collect do |ec|
          @slots << FilterSlot.new(ec, @user, :positive)
        end
      else
        Eventcategory.available.visible.sort.collect do |ec|
          @slots << FilterSlot.new(ec, @user, :negative)
        end
      end
      #
      #  If there are sufficient slots, then split them into
      #  columns.  Can have up to three of these.
      #
      @columns = []
      if @slots.size > PER_COLUMN || @min_cols > 1
        if @slots.size > (PER_COLUMN * 2) || @min_cols > 2
          #
          #  Three columns
          #
          per_column = (@slots.size + 2) / 3
          @columns << @slots[0,per_column]
          @columns << @slots[per_column, per_column]
          @columns << @slots[(per_column * 2)..-1]
        else
          #
          #  Two columns.  If not an even split, then the
          #  first column gets more.
          #
          per_column = (@slots.size + 1) / 2
          @columns << @slots[0,per_column]
          @columns << @slots[per_column..-1]
        end
      else
        #
        #  One column
        #
        @columns << @slots
      end
      @num_columns = @columns.size
      #
      #  Return self for chaining.
      #
      self
    end

    def to_partial_path
      "filter"
    end

  end

  #
  #  This is the thing which looks like an ActiveRecord.  We have one
  #  form for one of these, although it contains and references two
  #  actual filters - one positive and one negative.
  #
  #  We will be asked for the values of fields, and to assign new
  #  values to fields.  Each of these needs to be delegated to the
  #  correct subsidiary record.
  #
  class FilterSet
    include ActiveModel::Model
    include ActiveModel::Validations

    attr_reader :positives, :negatives, :id

    def initialize(user)
      @id    = 1   # Always
      @user = user
      @negatives = Filter.new(@user, :negative).generate_slots
      @positives = Filter.new(@user,
                              :positive,
                              @negatives.slots.size).generate_slots
      @slot_hash = Hash.new
      @positives.slots.each do |s|
        @slot_hash[s.symbol] = s
      end
      @negatives.slots.each do |s|
        @slot_hash[s.symbol] = s
      end
    end

    def method_missing(method_sym, *arguments, &block)
      if /^fs[n|p]\d+/ =~ method_sym
        if /=$/ =~ method_sym
          fs = @slot_hash[method_sym.chomp("=")]
          if fs
            fs.set(*arguments)
          else
            super
          end
        else
          fs = @slot_hash[method_sym]
          if fs
            fs.ticked
          else
            super
          end
        end
      else
        super
      end
    end

    def update(params)
      modified = false
      mine = params[:filter_manager_filter_set]
      if mine
        mine.each do |key, value|
          if /^fs[n|p]\d+/ =~ key && (slot = @slot_hash[key.to_sym])
            if slot.set(value)
              modified = true
            end
          end
        end
      end
      if modified
        @user.extra_eventcategories =
          @positives.slots.select {|s| s.ticked}.collect {|s| s.id}
        @user.suppressed_eventcategories =
          @negatives.slots.select {|s| !s.ticked}.collect {|s| s.id}
        @user.save!
      end
      return [modified, @user.filter_state]
    end

    def to_partial_path
      "filterset"
    end

    #
    #  This is necessary to make the model look like it has already
    #  been saved to the database.  Without it it's treated as a new
    #  record, so you can't get a path to edit it, and attempts
    #  to save a form generate a POST rather than a PUT.
    #
    def persisted?
      true
    end

  end


  def initialize(user)
    @user = user
  end

  #
  #  Assemble a list of the possible filters for the current user
  #  and their individual states.
  #
  def generate_filter
    FilterSet.new(@user)
  end

end
