"use strict";

//
//  If we seem to be on the right page, then we initialize ourselves
//  automatically.  However, it may be that our section will not appear
//  until later (dynamic dialogue box) so we need to provide the means
//  for other code to effect the same initialisation later.
//
//  We can cope with only one approvals region at a time.  A second call
//  will cause us to forget our first one.
//
window.approvalsHandler = function () {
  var baseURL = "/commitments/";
  var that = {}

  var approveSucceeded = function(data, textStatus, jqXHR) {
    if (data['status']) {
      this['statusElement'].html(that.status_confirmed);
      this['buttons'].html(that.buttons_confirmed);
      this['yesButton']     = this['buttons'].find('.approval-approve');
      this['noButton']      = this['buttons'].find('.approval-reject');
      this['notedButton']   = this['buttons'].find('.approval-hold');
      this['noButton'].click(this, noClicked);
      window.triggerCountsUpdate();
    } else {
      alert("Approval request rejected.");
    }
  }

  var approveFailed = function(jqXHR, textStatus, errorThrown) {
    alert("Approve failed - " + textStatus);
  }

  var yesClicked = function(event) {
//    alert("Yes clicked");
    $.ajax({
      url: baseURL + event.data['commitmentId'] + '/ajaxapprove',
      type: 'PUT',
      context: event.data,
      contentType: 'application/json'
    }).done(approveSucceeded).fail(approveFailed);
    return false;
  }

  var rejectSucceeded = function(data, textStatus, jqXHR) {
    if (data['status']) {
      //
      //  If we have successfully rejected a request then we need to
      //  turn its status to red, change the text, and make sure it has
      //  only "Approve" and "Noted" links.
      //
      this['statusElement'].html(that.status_rejected);
      console.log("Setting title to " + this['reason']);
      this['statusElement'].prop('title', this['reason']);
      this['buttons'].html(that.buttons_rejected);
      this['yesButton']     = this['buttons'].find('.approval-approve');
      //
      //  Yes, I know there is no "No" button, but I want to update
      //  the data structure to reflect this.
      //
      this['noButton']      = this['buttons'].find('.approval-reject');
      this['notedButton']   = this['buttons'].find('.approval-hold');
      this['yesButton'].click(this, yesClicked);
      this['notedButton'].click(this, notedClicked);
      window.triggerCountsUpdate();
    } else {
      alert("Rejection request rejected.");
    }
  }

  var rejectFailed = function(jqXHR, textStatus, errorThrown) {
    alert("Reject failed - " + textStatus);
  }

  var noClicked = function(event) {
//    alert("No clicked for commitment " + event.data['commitmentId']);
    var response = prompt("Please state the problem briefly:");
    if (response != null) {
      event.data['reason'] = response;
      $.ajax({
        url: baseURL + event.data['commitmentId'] + '/ajaxreject?reason=' + response,
        type: 'PUT',
        context: event.data,
        contentType: 'application/json'
      }).done(rejectSucceeded).fail(rejectFailed);

    }
    return false;
  }

  var notedSucceeded = function(data, textStatus, jqXHR) {
    if (data['status']) {
      this['statusElement'].html(that.status_noted);
      this['buttons'].html(that.buttons_noted);
      this['yesButton']     = this['buttons'].find('.approval-approve');
      this['noButton']      = this['buttons'].find('.approval-reject');
      this['notedButton']   = this['buttons'].find('.approval-hold');
      this['yesButton'].click(this, yesClicked);
      this['noButton'].click(this, noClicked);
      window.triggerCountsUpdate();
    } else {
      alert("Noted request rejected.");
    }
  }

  var notedFailed = function(jqXHR, textStatus, errorThrown) {
    alert("Noted failed - " + textStatus);
  }

  var notedClicked = function(event) {
    $.ajax({
      url: baseURL + event.data['commitmentId'] + '/ajaxnoted',
      type: 'PUT',
      context: event.data,
      contentType: 'application/json'
    }).done(notedSucceeded).fail(notedFailed);
    return false;
  }

  that.init = function() {
    that.ourRegion = $('.approvals-region');
    if (that.ourRegion.length) {
      //
      //  Need some templates (although they're not really templates,
      //  just chunks of html).
      //
      that.buttons_uncontrolled = $('#template-buttons-uncontrolled').html();
      that.buttons_confirmed    = $('#template-buttons-confirmed').html();
      that.buttons_requested    = $('#template-buttons-requested').html();
      that.buttons_rejected     = $('#template-buttons-rejected').html();
      that.buttons_noted        = $('#template-buttons-noted').html();
      //
      that.status_uncontrolled = $('#template-status-uncontrolled').html();
      that.status_confirmed    = $('#template-status-confirmed').html();
      that.status_requested    = $('#template-status-requested').html();
      that.status_rejected     = $('#template-status-rejected').html();
      that.status_noted        = $('#template-status-noted').html();
      //
      //  At this point, we arguably should check whether that.items
      //  already exists, and if it does then go through explicitly
      //  de-listening all the listens issued earlier.
      //
      that.items = [];
      that.ourRegion.find('.approval-item').each(function(index, element) {
        var thisOne = {}, buttons = null, statustext = null;
        thisOne['commitmentId']  = $(element).data('commitment-id');
        thisOne['initialStatus'] = $(element).data('commitment-status');
        thisOne['reason']        = $(element).data('commitment-reason');
        thisOne['statusElement'] = $(element).find('.approval-status');
        thisOne['buttons']       = $(element).find('.approval-buttons');
        if (thisOne['initialStatus']) {
          switch (thisOne['initialStatus']) {
            case 'uncontrolled':
              buttons = that.buttons_uncontrolled;
              statustext = that.status_uncontrolled;
              break;

            case 'confirmed':
              buttons = that.buttons_confirmed;
              statustext = that.status_confirmed;
              break;

            case 'requested':
              buttons = that.buttons_requested;
              statustext = that.status_requested;
              break;

            case 'rejected':
              buttons = that.buttons_rejected;
              statustext = that.status_rejected;
              break;

            case 'noted':
              buttons = that.buttons_noted;
              statustext = that.status_noted;
              break;

          }
          if (buttons) {
            thisOne['buttons'].html(buttons);
          }
          if (statustext) {
            thisOne['statusElement'].html(statustext);
            if (thisOne['reason']) {
              thisOne['statusElement'].prop('title', thisOne['reason']);
            }
          }
        }
        thisOne['yesButton']     = $(element).find('.approval-approve');
        thisOne['noButton']      = $(element).find('.approval-reject');
        thisOne['notedButton']   = $(element).find('.approval-hold');
        thisOne['yesButton'].click(thisOne, yesClicked);
        thisOne['noButton'].click(thisOne, noClicked);
        thisOne['notedButton'].click(thisOne, notedClicked);
        that.items.push(thisOne);
      })
    }
  }

  return that;

}();

if ($('.approvals-region').length) {
  $(window.approvalsHandler.init);
}

