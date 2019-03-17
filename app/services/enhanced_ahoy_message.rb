# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2019 John Winters
# See COPYING and LICENCE in the root directory of the application
# for more information.

class EnhancedAhoyMessage
  #
  #  Brings together Ahoy::Messages and the Mail library for
  #  easy handling.  Adds some extra functions related to unpacking
  #  a previously stored message, and then defers to the original message
  #  for all else.
  #  

  attr_reader :message

  def initialize(message)
    #
    #  Pass in an Ahoy::Message straight from the database.
    #
    @message = message
    @deconstructed = Mail.new(message.content)
  end

  def multipart?
    @deconstructed.multipart?
  end

  def parts
    if @deconstructed.multipart?
      @deconstructed.parts
    else
      [@deconstructed]
    end
  end

  def content_type
    @deconstructed.content_type
  end

  def to_partial_path
    "eam"
  end

  #
  #  Interesting discovery - the render code tries to call "to_model"
  #  if available before trying "to_partial_path".  We need to implement
  #  this too, because otherwise the call on "to_model" will be passed
  #  to our Ahoy::Message, which has a different idea about the kind
  #  of partial which is needed.
  #
  def to_model
    self
  end

  #
  #  These defer anything which we still don't understand to the
  #  original Ahoy::Message
  #
  def method_missing(method_sym, *arguments, &block)
    #
    #  Delegate to our original Ahoy::Message
    #
    @message.send(method_sym, *arguments, &block)
  end

  def respond_to_missing?(method_sym, *arguments)
    @message.respond_to?(method_sym, *arguments)
  end
end
