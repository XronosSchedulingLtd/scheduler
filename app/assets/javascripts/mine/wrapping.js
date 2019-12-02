"use strict";

//
//  This module is quite unusual in that it does nothing until explicitly
//  called on.  All it does is provide a globally visible method as
//  an entry point.
//

window.wrappingTypeHandler = function () {
  var that = {};

  var tick_box;

  var tickBoxChangeHandler = function() {
    if (tick_box.is(':checked')) {
      //
      //  We are going to single event mode.
      //
      $('.wrapper-twin-fields').hide();
      $('.wrapper-single-fields').show();
    } else {
      $('.wrapper-single-fields').hide();
      $('.wrapper-twin-fields').show();
    }
  }

  that.init = function() {
    //
    //  This function is called blindly when the dialogue box opens.
    //  It's up to us to check whether we're actually needed.
    //
    tick_box = $('#event_wrapper_single_wrapper');
    if (tick_box.length) {
      tick_box.change(tickBoxChangeHandler);
    }
  }
  return that;
}();

