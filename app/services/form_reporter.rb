# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2019 John Winters
# See COPYING and LICENCE in the root directory of the application
# for more information.

require 'json'
require 'csv'

class UserFormField
  attr_reader :label

  def initialize(definition)
    @label      = definition['label']
    @definition = definition
  end

  def selection_label(index)
    label = nil
    values = @definition['values']
    if values
      entry = values[index]
      if entry
        label = entry['label']
        #
        #  For some odd reason, checkbox labels have a leading space.
        #
        if label
          label.strip!
        end
      end
    end
    label
  end

end

class IndividualResponse

  #
  #  Like a hash, except that it auto-creates an array for each entry and
  #  accumulates stuff.
  #
  #  a = Accumulator.new
  #  a[:john] << 'a'
  #  a[:john] << 'b'
  #  a[:john]
  #  ['a', 'b']
  #
  #  I may or may not like this in due course.
  #
  #  Note that you'll never get back nil as the result for an entry,
  #  always just an empty array.
  #
  class Accumulator < Hash

    class AccumulatorArray < Array
      def to_s
        case self.size
        when 0
          ""
        when 1
          self[0].to_s
        else
          self.join("\n")
        end
      end

    end

    def [](key)
      super || (self[key] = AccumulatorArray.new)
    end

  end

  @@sanitizer = Rails::Html::FullSanitizer.new

  attr_reader :event

  #
  #  joiner may be either a Commitment or a Request
  #
  def initialize(joiner, fields)
    @ufr = joiner.user_form_response
    @event = joiner.event
    @joiner = joiner
    #
    #  Convert our field contents into a structure.
    #
    @contents = Accumulator.new
    if @ufr.form_data
      raw_contents = JSON.parse(@ufr.form_data)
      raw_contents.each do |raw_data|
        type = raw_data['type']
        id = raw_data['id']
        case type

        when 'text', 'textarea', 'select-one', 'number', 'date'
          value = raw_data['value']
          if id && value
            @contents[id] << value
          end

        when 'radio', 'checkbox'
          checked = raw_data['checked']
          matched = id.match(/(^#{type}-group-\d+)-(\d+$)/)
          if matched && checked
            #
            #  Now need to work out the name for this item,
            #  which is in the field definitions.
            #
            key = matched[1]
            index = matched[2].to_i
            field = fields[key]
            if field
              label = field.selection_label(index)
              if label
                @contents[key] << label
              end
            end
          end

        end
      end
    end
  end

  #
  #  Each of these returns text suitable for going in a field.
  #
  def event_name
  end

  def datetime
  end

  def duration
  end

  def quantity
    if @joiner.respond_to?(:quantity)
      @joiner.quantity
    else
      1
    end
  end

  def form_status
  end

  def field_contents(fields)
    result = []
    fields.each do |name, definition|
      result << @contents[name].to_s
    end
    result
  end

  def headers
    [@event.starts_at.to_date,
     @event.body,
     @event.starts_at.to_s(:hhmm),
     @event.duration_text,
     @event.owners_initials,
     @event.organisers_initials,
     self.quantity,
     @ufr.status]
  end

  def columns(fields)
    self.headers + self.field_contents(fields)
  end

  def self.column_headers(fields)
    %w(Date Event Time Duration Owner Organiser Quantity Form\ status) +
    fields.collect {|name, f| @@sanitizer.sanitize(f.label)}
  end

  def <=>(other)
    if other.instance_of?(IndividualResponse)
      self.event <=> other.event
    else
      nil
    end
  end

end

class FormReporter

  attr_reader :raw_field_defs

  def initialize(element, starts_on, ends_on)
    @ok        = false
    @element   = element
    @starts_on = starts_on
    @ends_on   = ends_on
    #
    #  If you specify an element with no form, or backward dates
    #  or anything like that, then you will simply end up with no
    #  data.
    #
    @user_form = @element.user_form
    if @user_form
      #
      #  Now let's work out what columns we have.
      #
      @raw_field_defs = JSON.parse(@user_form.definition)
      @fields = Hash.new
      @raw_field_defs.each do |field_def|
        name = field_def['name']
        if name
          @fields[name] = UserFormField.new(field_def)
        end
      end
      #
      #  And our responses.
      #
      @responses = Array.new
      joiners =
        (
          @element.commitments.
                   during(@starts_on, @ends_on + 1.day).to_a +
          @element.requests.
                   during(@starts_on, @ends_on + 1.day).to_a
        ).select {|joiner|
          joiner.user_form_response != nil &&
            joiner.user_form_response.user_form == @user_form
        }
      joiners.each do |joiner|
        @responses << IndividualResponse.new(joiner, @fields)
      end
      @ok = true
    end
  end

  def ok?
    @ok
  end

  def how_many?
    @fields.count
  end

  #
  #  Return a whole file of CSV data ready to be sent to the client.
  #
  def to_csv
    output = []
    #
    #  The to_csv might seem overkill, but there could be a comma in the
    #  element name.
    #
    output << ["", "Forms for #{@element.name} from #{@starts_on} to #{@ends_on}"].to_csv
    output << "\n"
    output << IndividualResponse.column_headers(@fields).to_csv
    @responses.sort.each do |response|
      output << response.columns(@fields).to_csv
    end
    output.join
  end
end
