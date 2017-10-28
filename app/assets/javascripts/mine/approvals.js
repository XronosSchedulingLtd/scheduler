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
      this['statusElement'].removeClass('tentative-commitment rejected-commitment noted-commitment').addClass('constraining-commitment').text('OK');
      this['buttons'].html(that.confirmed_template);
      this['yesButton']     = this['buttons'].find('.approval-yes');
      this['noButton']      = this['buttons'].find('.approval-no');
      this['notedButton']   = this['buttons'].find('.approval-noted');
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
      this['statusElement'].removeClass('tentative-commitment constraining-commitment noted-commitment').addClass('rejected-commitment').text('Rejected');
      this['buttons'].html(that.rejected_template);
      this['yesButton']     = this['buttons'].find('.approval-yes');
      //
      //  Yes, I know there is no "No" button, but I want to update
      //  the data structure to reflect this.
      //
      this['noButton']      = this['buttons'].find('.approval-no');
      this['notedButton']   = this['buttons'].find('.approval-noted');
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
      this['statusElement'].removeClass('tentative-commitment rejected-commitment constraining-commitment').addClass('noted-commitment').text('Noted');
      this['buttons'].html(that.noted_template);
      this['yesButton']     = this['buttons'].find('.approval-yes');
      this['noButton']      = this['buttons'].find('.approval-no');
      this['notedButton']   = this['buttons'].find('.approval-noted');
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
      that.uncontrolled_template = $('#uncontrolled-template').html();
      that.confirmed_template    = $('#confirmed-template').html();
      that.requested_template    = $('#requested-template').html();
      that.rejected_template     = $('#rejected-template').html();
      that.noted_template        = $('#noted-template').html();
      //
      //  At this point, we arguably should check whether that.items
      //  already exists, and if it does then go through explicitly
      //  de-listening all the listens issued earlier.
      //
      that.items = [];
      that.ourRegion.find('.approval-item').each(function(index, element) {
        var thisOne = {}, template = null;
        thisOne['commitmentId']  = $(element).data('commitment-id');
        thisOne['initialStatus'] = $(element).data('commitment-status');
        thisOne['statusElement'] = $(element).find('.approval-status');
        thisOne['buttons']       = $(element).find('.approval-buttons');
        if (thisOne['initialStatus']) {
          switch (thisOne['initialStatus']) {
            case 'uncontrolled':
              template = that.uncontrolled_template;
              break;

            case 'confirmed':
              template = that.confirmed_template;
              break;

            case 'requested':
              template = that.requested_template;
              break;

            case 'rejected':
              template = that.rejected_template;
              break;

            case 'noted':
              template = that.noted_template;
              break;

          }
          if (template) {
            thisOne['buttons'].html(template);
          }
        }
        thisOne['yesButton']     = $(element).find('.approval-yes');
        thisOne['noButton']      = $(element).find('.approval-no');
        thisOne['notedButton']   = $(element).find('.approval-noted');
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

