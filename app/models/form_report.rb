# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2019 John Winters
# See COPYING and LICENCE in the root directory of the application
# for more information.

class FormReport
  include ActiveModel::Model

  attr_reader :starts_on, :ends_on

  def initialize
    super
    @starts_on = Date.today.at_beginning_of_month
    @ends_on   = Date.today.at_end_of_month
  end

  def starts_on=(string)
    @starts_on = Date.parse(string)
  end

  def ends_on=(string)
    @ends_on = Date.parse(string)
  end

  def to_partial_path
    'form_reports/form_report'
  end
end
