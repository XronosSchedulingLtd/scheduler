"use strict";

if ($('#event-index').length) {

  var eventIndex = function() {

    var that = {};

    that.modalClosed = function() {
      //
      //  The dorefresh flag is set using a class selector, so a single bit
      //  of setting code can set it anywhere in the whole application.
      //
      //  However, it's checked using a specific ID, because we want to
      //  check our very own instance.  We also reset it by ID, so we affect
      //  only ours.
      //
      var flag = $('#event-index').data('dorefresh');
      if (flag == "1") {
        location.reload();
        $('#event-index').data('dorefresh', '0');
      }
    }

    that.init = function() {
      $(document).on('closed', '[data-reveal]', that.modalClosed);
    }

    return that;

  }();

  $(eventIndex.init);
}
