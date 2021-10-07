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
  var statusTemplate ; 
  var timerID = null;
  var buttonsDisabled = false;
  var cycle_id = 1;

  var pollResponse = function(response, textStatus, jqXHR) {
    var job_status = response.job_status;
    $('#ahd-job-status').html(statusTemplate(job_status));
    if (job_status.can_queue) {
      stopTimer();
      enableButtons();
    } else {
      //
      //  If they're already disabled this will do nothing.
      //
      disableButtons();
    }
  };

  var pollFailed = function(jqXHR, textStatus, errorThrown) {
    alert("Poll failed");
  };

  var handleTimer = function() {
    $.ajax({
      url: '/ad_hoc_domain_cycles/' + cycle_id + '/poll',
      type: 'GET',
      context: this,
      dataType: 'json',
      contentType: 'application/json'
    }).done(pollResponse).error(pollFailed);

  };

  var stopTimer = function() {
    if (timerID) {
      window.clearInterval(timerID);
      timerID = null;
    }
  };

  var startTimer = function() {
    if (!timerID) {
      timerID = window.setInterval(handleTimer, 5000);
    }
  };

  var disableButtons = function() {
    if (!buttonsDisabled) {
      $('.ahd-implement-button').addClass('disabled');
      buttonsDisabled = true;
    }
  };

  var enableButtons = function() {
    if (buttonsDisabled) {
      $('.ahd-implement-button').removeClass('disabled');
      buttonsDisabled = false;
    }
  };

  var implementDone = function(response, textStatus, jqXHR) {
    //
    //  At this point we know that our exchange with the server has
    //  succeeded, but we don't yet know whether it enqueued our
    //  job.  It may not have done if there was one already in the queue.
    //
    //  The processing however turns out to be much the same.
    //
    $('#ahd-job-status').html(statusTemplate(response.job_status));
  };

  var implementFailed = function(jqXHR, textStatus, errorThrown) {
    enableButtons();
    stopTimer();
  };

  var doImplement = function(event) {
    event.preventDefault();
    //
    //  Although we visually disable the buttons, because they are
    //  still objects with a click handler we still get called when
    //  one of them is clicked.
    //
    if (!buttonsDisabled) {
      disableButtons();
      startTimer();
      $.ajax({
        url: $(this).attr('href'),
        type: 'POST',
        context: this,
        dataType: 'json',
        contentType: 'application/json'
      }).done(implementDone).error(implementFailed);
    }
    //
    //  The documentation for click handlers does not seem to be quite
    //  correct.  Although we call preventDefault() above, this is not
    //  sufficient if we then don't make an ajax call ourselves.
    //
    //  We need to return false as well to prevent the browser sending
    //  up an unwanted request.
    //
    return false;
  };

  //
  //================================================================
  //
  //  Initialisation entry point.
  //
  //================================================================
  //

  that.init = function() {
    //
    //  We have already checked that our master parent division
    //  exists, otherwise we wouldn't be running at all.
    //
    $('.ahd-implement-button').click(doImplement);
    //
    //  Fill in our current data.
    //
    statusTemplate = _.template($('#ahd-job-status-template').html());
    //
    //  Local variable because we will use it only once.
    //
    var templateData = JSON.parse($('#ahd-job-status-data').text());
    $('#ahd-job-status').html(statusTemplate(templateData));
    //
    //  If can_queue is false then we should:
    //  
    //  a) Disable the buttons
    //  b) Start a ticker to poll for updates
    //
    if (!templateData.can_queue) {
      disableButtons();
      startTimer();
    }
    cycle_id = templateData.cycle_id;
    //
    window.addEventListener("beforeunload", stopTimer);
  }

  return that;

}();

//
//  Once the DOM is ready, get our code to initialise itself.
//
$(implementing_allocation.init);

}
