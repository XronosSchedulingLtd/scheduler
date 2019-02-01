# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2019 John Winters
# See COPYING and LICENCE in the root directory of the application
# for more information.

require 'json'
require 'csv'

class UserFormField
  attr_reader :type, :label, :name, :subtype

  def initialize(definition)
    @type    = definition['type']
    @label   = definition['label']
    @name    = definition['name']
    @subtype = definition['subtype']
  end
end

class IndividualResponse

  @@sanitizer = Rails::Html::FullSanitizer.new

  attr_reader :event

  #
  #  joiner may be either a Commitment or a Request
  #
  def initialize(joiner)
    Rails.logger.debug('Creating IndividualResponse')
    @ufr = joiner.user_form_response
    @event = joiner.event
    @joiner = joiner
    #
    #  Convert our field contents into a structure.
    #
    @contents = Hash.new
    if @ufr.form_data
      raw_contents = JSON.parse(@ufr.form_data)
      raw_contents.each do |raw_data|
        id = raw_data['id']
        value = raw_data['value']
        if id && value
          @contents[id] = value
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
      value = @contents[name]
      if value
        result << value
      else
        result << ''
      end
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
    Rails.logger.debug("Passed #{starts_on}, #{ends_on}")
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
          Rails.logger.debug("Evaluating joiner")
          joiner.user_form_response != nil &&
            joiner.user_form_response.user_form == @user_form
        }
      joiners.each do |joiner|
        @responses << IndividualResponse.new(joiner)
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
