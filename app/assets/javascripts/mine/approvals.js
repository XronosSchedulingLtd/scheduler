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
      this['statusElement'].removeClass('tentative-commitment rejected-commitment').addClass('constraining-commitment').text('OK');
      this['buttons'].html('<span><a class="approval-no" href="#">Reject</a></span>')
      this['yesButton']     = this['buttons'].find('.approval-yes');
      this['noButton']      = this['buttons'].find('.approval-no');
      this['noButton'].click(this, noClicked);
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
      //  only an "Approve" link.
      //
      this['statusElement'].removeClass('tentative-commitment constraining-commitment').addClass('rejected-commitment').text('Rejected');
      this['buttons'].html('<span><a class="approval-yes" href="#">Approve</a></span>')
      this['yesButton']     = this['buttons'].find('.approval-yes');
      //
      //  Yes, I know there is no "No" button, but I want to update
      //  the data structure to reflect this.
      //
      this['noButton']      = this['buttons'].find('.approval-no');
      this['yesButton'].click(this, yesClicked);
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
      $.ajax({
        url: baseURL + event.data['commitmentId'] + '/ajaxreject?reason=' + response,
        type: 'PUT',
        context: event.data,
        contentType: 'application/json'
      }).done(rejectSucceeded).fail(rejectFailed);

    }
    return false;
  }

  that.init = function() {
    that.ourRegion = $('.approvals-region');
    if (that.ourRegion.length) {
      //
      //  At this point, we arguably should check whether that.items
      //  already exists, and if it does then go through explicitly
      //  de-listening all the listens issued earlier.
      //
      that.items = [];
      that.ourRegion.find('.approval-item').each(function(index, element) {
        var thisOne = {}
        thisOne['commitmentId'] = $(element).data('commitment-id');
        thisOne['statusElement'] = $(element).find('.approval-status');
        thisOne['buttons']       = $(element).find('.approval-buttons');
        thisOne['yesButton']     = $(element).find('.approval-yes');
        thisOne['noButton']      = $(element).find('.approval-no');
//        $(element).find('.approval-status').removeClass('constraining-commitment').addClass('tentative-commitment');
        thisOne['yesButton'].click(thisOne, yesClicked);
        thisOne['noButton'].click(thisOne, noClicked);
        that.items.push(thisOne);
      })
    }
  }

  return that;

}();

if ($('.approvals-region').length) {
  $(window.approvalsHandler.init);
}

