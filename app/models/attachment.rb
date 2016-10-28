# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2016 John Winters
# See COPYING and LICENCE in the root directory of the application
# for more information.
#
class Attachment < ActiveRecord::Base
  belongs_to :parent, :polymorphic => true

  validates :note, :presence => true
  validates :original_file_name, :presence => true
end
