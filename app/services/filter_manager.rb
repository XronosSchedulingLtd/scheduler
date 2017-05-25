# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2017 John Winters
# See COPYING and LICENCE in the root directory of the application
# for more information.

class FilterManager

  class FilterSlot
    attr_reader :title, :ticked, :id

    def initialize(ec, user)
      @title = ec.name
      @id    = ec.id
      #
      #  Each defaults to ticked, unless suppressed.
      #
      @ticked = !user.suppressed_eventcategories.include?(ec.id)
    end

    def symbol
      "fs#{@id}".to_sym
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

  class Filter < FakeActiveRecord
    attr_reader :num_columns, :columns, :slots, :id

    #
    #  This class behaves a bit like an ActiveRecord model.
    #
    def initialize(user)
      @id    = 1   # Always
      @user  = user
      @slots = []
    end

    PER_COLUMN = 10

    def generate_slots
      Eventcategory.available.visible.sort.collect do |ec|
        @slots << FilterSlot.new(ec, @user)
        @slot_hash = Hash.new
        @slots.each do |s|
          @slot_hash[s.symbol] = s
        end
        #
        #  Should also add a getter and setter so that each
        #  slot appears as an apparent attribute of the Filter
        #  fake record.
        #
        #
        #  If there are sufficient slots, then split them into
        #  columns.  Can have up to three of these.
        #
        @columns = []
        if @slots.size > PER_COLUMN
          if @slots.size > (PER_COLUMN * 2)
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
      end
      #
      #  Return self for chaining.
      #
      self
    end

    def to_partial_path
      "filter"
    end

    def method_missing(method_sym, *arguments, &block)
      if /^fs\d+/ =~ method_sym
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
      mine = params[:filter_manager_filter]
      if mine
        mine.each do |key, value|
          if /^fs\d+/ =~ key && (slot = @slot_hash[key.to_sym])
            if slot.set(value)
              modified = true
            end
          end
        end
      end
      if modified
        @user.suppressed_eventcategories =
          @slots.select {|s| !s.ticked}.collect {|s| s.id}
        @user.save!
      end
      modified
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
    Filter.new(@user).generate_slots
  end

end
