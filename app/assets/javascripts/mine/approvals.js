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
//  Note that this code could arguably be done very neatly with Backbone,
//  but I've done it semi-deliberately without, in order to compare
//  what Backbone gives me with how things are without it.
//
window.approvalsHandler = function () {
  var baseURL = "/commitments/";
  var that = {}

  var approveSucceeded = function(data, textStatus, jqXHR) {
    var chunks;

    if (data['status']) {
      chunks = that.htmlChunks.confirmed;
      this.statusElement.html(chunks.statusText);
      this.statusElement.removeAttr('title');
      this.buttons.html(chunks.buttons);
      this.yesButton     = this.buttons.find('.approval-approve');
      this.noButton      = this.buttons.find('.approval-reject');
      this.notedButton   = this.buttons.find('.approval-hold');
      this.noButton.click(this, noClicked);
      if (data.formStatus.length) {
        this.formStatus.html(data.formStatus);
      }
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
      url: baseURL + event.data.commitmentId + '/ajaxapprove',
      type: 'PUT',
      context: event.data,
      contentType: 'application/json'
    }).done(approveSucceeded).fail(approveFailed);
    return false;
  }

  var rejectSucceeded = function(data, textStatus, jqXHR) {
    var chunks;

    if (data['status']) {
      chunks = that.htmlChunks.rejected;
      //
      //  If we have successfully rejected a request then we need to
      //  turn its status to red, change the text, and make sure it has
      //  only "Approve" and "Noted" links.
      //
      this.statusElement.html(chunks.statusText);
      this.statusElement.prop('title', this['reason']);
      this.buttons.html(chunks.buttons);
      this.yesButton     = this.buttons.find('.approval-approve');
      //
      //  Yes, I know there is no "No" button, but I want to update
      //  the data structure to reflect this.
      //
      this.noButton      = this.buttons.find('.approval-reject');
      this.notedButton   = this.buttons.find('.approval-hold');
      this.yesButton.click(this, yesClicked);
      this.notedButton.click(this, notedClicked);
      if (data.formStatus.length) {
        this.formStatus.html(data.formStatus);
      }
      window.triggerCountsUpdate();
    } else {
      alert("Rejection request rejected.");
    }
  }

  var rejectFailed = function(jqXHR, textStatus, errorThrown) {
    alert("Reject failed - " + textStatus);
  }

  var noClicked = function(event) {
//    alert("No clicked for commitment " + event.data.commitmentId);
    var response = prompt("Please state the problem briefly:");
    if (response != null) {
      event.data['reason'] = response;
      $.ajax({
        url: baseURL + event.data.commitmentId + '/ajaxreject?reason=' + response,
        type: 'PUT',
        context: event.data,
        contentType: 'application/json'
      }).done(rejectSucceeded).fail(rejectFailed);

    }
    return false;
  }

  var notedSucceeded = function(data, textStatus, jqXHR) {
    var chunks;

    if (data['status']) {
      chunks = that.htmlChunks.noted;
      this.statusElement.html(chunks.statusText);
      this.statusElement.prop('title', this['reason']);
      this.buttons.html(chunks.buttons);
      this.yesButton     = this.buttons.find('.approval-approve');
      this.noButton      = this.buttons.find('.approval-reject');
      this.notedButton   = this.buttons.find('.approval-hold');
      this.yesButton.click(this, yesClicked);
      this.noButton.click(this, noClicked);
      if (data.formStatus.length) {
        this.formStatus.html(data.formStatus);
      }
      window.triggerCountsUpdate();
    } else {
      alert("Noted request rejected.");
    }
  }

  var notedFailed = function(jqXHR, textStatus, errorThrown) {
    alert("Noted failed - " + textStatus);
  }

  var notedClicked = function(event) {
    var response = prompt("Additional information for requester - (optional):");
    if (response != null) {
      event.data['reason'] = response;
      $.ajax({
        url: baseURL + event.data.commitmentId + '/ajaxnoted?reason=' + response,
        type: 'PUT',
        context: event.data,
        contentType: 'application/json'
      }).done(notedSucceeded).fail(notedFailed);
    }
    return false;
  }

  that.init = function() {
    that.ourRegion = $('.approvals-region');
    if (that.ourRegion.length) {
      //
      //  Need some templates (although they're not really templates,
      //  just chunks of html).
      //
      that.htmlChunks = {
        uncontrolled: {},
        confirmed: {},
        requested: {},
        rejected: {},
        noted: {}
      } ;
      that.htmlChunks.uncontrolled.buttons =
        $('#template-buttons-uncontrolled').html();
      that.htmlChunks.confirmed.buttons =
        $('#template-buttons-confirmed').html();
      that.htmlChunks.requested.buttons =
        $('#template-buttons-requested').html();
      that.htmlChunks.rejected.buttons =
        $('#template-buttons-rejected').html();
      that.htmlChunks.noted.buttons =
        $('#template-buttons-noted').html();
      //
      that.htmlChunks.uncontrolled.statusText =
        $('#template-status-uncontrolled').html();
      that.htmlChunks.confirmed.statusText =
        $('#template-status-confirmed').html();
      that.htmlChunks.requested.statusText =
        $('#template-status-requested').html();
      that.htmlChunks.rejected.statusText =
        $('#template-status-rejected').html();
      that.htmlChunks.noted.statusText =
        $('#template-status-noted').html();
      //
      //  At this point, we arguably should check whether that.items
      //  already exists, and if it does then go through explicitly
      //  de-listening all the listens issued earlier.
      //
      that.items = [];
      that.ourRegion.find('.approval-item').each(function(index, element) {
        var thisOne = {}, chunks;

        thisOne.commitmentId  = $(element).data('commitment-id');
        thisOne.initialStatus = $(element).data('commitment-status');
        thisOne.reason        = $(element).data('commitment-reason');
        thisOne.statusElement = $(element).find('.approval-status');
        thisOne.buttons       = $(element).find('.approval-buttons');
        thisOne.formStatus    = $(element).find('.form-status');
        if (thisOne.initialStatus) {
          chunks = that.htmlChunks[thisOne.initialStatus];
          if (chunks) {
            thisOne.buttons.html(chunks.buttons);
            thisOne.statusElement.html(chunks.statusText);
            if (thisOne.reason) {
              thisOne.statusElement.prop('title', thisOne['reason']);
            }
          }
        }
        thisOne.yesButton     = $(element).find('.approval-approve');
        thisOne.noButton      = $(element).find('.approval-reject');
        thisOne.notedButton   = $(element).find('.approval-hold');
        thisOne.yesButton.click(thisOne, yesClicked);
        thisOne.noButton.click(thisOne, noClicked);
        thisOne.notedButton.click(thisOne, notedClicked);
        that.items.push(thisOne);
      })
    }
  }

  return that;

}();

if ($('.approvals-region').length) {
  $(window.approvalsHandler.init);
}

