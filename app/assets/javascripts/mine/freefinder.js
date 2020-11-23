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

      that.init = function() {
        $('.ff-booking').click(openEventModal);
      }

      return that;
    }().init
  );
}

