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
        $('.ff-result').each(setSlider);
      }

      return that;
    }().init
  );
}

