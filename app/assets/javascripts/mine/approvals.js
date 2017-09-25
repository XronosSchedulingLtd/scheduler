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
  var that = {}

  that.init = function() {
    that.ourRegion = $('.approvals-region');
    if (that.ourRegion.length) {
      that.items = [];
      that.ourRegion.find('.approval-item').each(function(index, element) {
//        console.log("Found item " + index);
        var thisOne = {}
        thisOne['commitmentId'] = $(element).data('commitment-id');
        thisOne['statusElement'] = $(element).find('.approval-status');
//        $(element).find('.approval-status').removeClass('constraining-commitment').addClass('tentative-commitment');
        that.items.push(thisOne);
      })
      console.log(that.items);
    }
  }

  return that;

}();

if ($('.approvals-region').length) {
//  console.log("Found an approvals region.");
  $(window.approvalsHandler.init);
}

