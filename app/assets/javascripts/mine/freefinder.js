"use strict";

//
//  This code is for the "find free times" page.
//
if ($('.ff-booking').length) {
  $(
    function() {

      var that = {};

      function openEventModal(event) {
        event.preventDefault();
        $('#eventModal').foundation('reveal',
                                    'open',
                                    $(this).attr('href'));
      }

      function setSlider(index, element) {
        console.log("One result");
        $(element).find('.show-time').text("Hello");
      }

      that.init = function() {
        $('.ff-booking').click(openEventModal);
        //
        //  Do we have any results on display?  If so, set up the sliders.
        //
        $('.ff-slider').slider(
          {
            min: 0,
            max: 8
          }
        ).slider(
          "pips",
          {
            first: 'pip',
            last: 'pip'
          }
        ).slider(
          "float",
          {
            labels: [
              "09:50-10:35",
              "09:55-10:40",
              "10:00-10:45",
              "10:05-10:50",
              "10:10-10:55",
              "10:15-11:00",
              "10:20-11:05",
              "10:25-11:10",
              "10:30-11:15"
            ]
          }
        );
      }

      return that;
    }().init
  );
}

