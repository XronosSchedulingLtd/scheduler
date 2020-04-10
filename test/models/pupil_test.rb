#
# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2020 John Winters
# See COPYING and LICENCE in the root directory of the application
# for more information.
#

require 'test_helper'

class PupilTest < ActiveSupport::TestCase
  setup do
    @entity_class = Pupil
    @valid_params = {
      name: "Hi there - I'm a pupil"
    }
  end

  include CommonEntityTests

  #
  #  The Pupil model overrides the sorting method (<=>) and so needs
  #  its own separate sorting test.
  #

  test "pupils sort by year surname forename" do
    pupils = []
    #
    #  This chap comes right at the end because, although he has
    #  an aaaa name, he has no start year.
    #
    pupils << Pupil.create(
      @valid_params.merge(
        {
          surname: "Aaaaa",
          forename: "Aaaaa"
        }
      )
    )
    pupils << Pupil.create(
      @valid_params.merge(
        {
          start_year: 2015,
          surname: "Wilson",
          forename: "Able"
        }
      )
    )
    pupils << Pupil.create(
      @valid_params.merge(
        {
          start_year: 2015,
          surname: "Smith",
          forename: "Bert"
        }
      )
    )
    pupils << Pupil.create(
      @valid_params.merge(
        {
          start_year: 2015,
          surname: "Smith",
          forename: "Able"
        }
      )
    )
    #
    #  This chap should come first, by dint of his start year
    #  making him younger than anyone else.
    #
    pupils << Pupil.create(
      @valid_params.merge(
        {
          start_year: 2018,
          surname: "Zebedee",
          forename: "Zacariah"
        }
      )
    )
    #
    #  But this one even earlier, because he has no names.
    #
    pupils << Pupil.create(
      @valid_params.merge(
        {
          start_year: 2018
        }
      )
    )
    sorted = pupils.sort
    assert_equal pupils[0], sorted[5]
    assert_equal pupils[1], sorted[4]
    assert_equal pupils[2], sorted[3]
    assert_equal pupils[3], sorted[2]
    assert_equal pupils[4], sorted[1]
    assert_equal pupils[5], sorted[0]
  end

end
