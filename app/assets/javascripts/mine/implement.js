"use strict";

//
//  Do nothing at all unless we are on the right page.
//
if ($('#ahd-allocation-listing').length) {

//
//  Wrap everything in a function to avoid namespace pollution
//  Note that we invoke the function immediately.
//
var implementing_allocation = function() {

  var that = {};

  //
  //================================================================
  //
  //  Initialisation entry point.
  //
  //================================================================
  //

  var doDisable = function() {
    $('.ahd-implement-button').addClass('disabled');
    $(this).text("Working...");
  }

  window.doAhdEnableImplement = function() {
    $('.ahd-implement-button').text('Implement').removeClass('disabled');
  };

  that.init = function() {
    //
    //  We have already checked that our master parent division
    //  exists, otherwise we wouldn't be running at all.
    //
    //  All we need to do is trap a click on any "Implement" button and
    //  disable all of them, displaying a "Please wait..." message under
    //  the clicked one.
    //
    $('.ahd-implement-button').click(doDisable);
  }

  return that;

}();

//
//  Once the DOM is ready, get our code to initialise itself.
//
$(implementing_allocation.init);

}
