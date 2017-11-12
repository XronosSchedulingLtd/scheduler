"use strict";

//
//  Don't do anything at all unless we are on the right page.
//

if ($('#pending-grand-total').length) {

  var pendingRequestsHandler = function() {
    var that = {};

    var RequestCount = Backbone.Model.extend({
      url: "/users/pp",
      pph: {}
    });

    var RequestCountView = Backbone.View.extend({
      el: '#pending-grand-total',
      initialize: function(options) {
        _.bindAll(this, "fetchCount");
        this.model = new RequestCount();
        this.listenTo(this.model, 'sync', this.render);
        this.polling = false;
      },
      fetchCount: function() {
        this.model.fetch();
      },
      render: function() {
        var pph = this.model.get("pph");
        for (var property in pph) {
          if (pph.hasOwnProperty(property)) {
            // console.log(property + ":" + pph[property]);
            var targetId = '#' + property;
            $(targetId).text(pph[property]);
          }
        }
      },
      startPolling: function() {
        if (!this.polling) {
          setInterval(this.fetchCount, 600 * 1000);
          this.polling = true;
        }
      }
    });


    that.init = function() {
      //
      //  We need to fetch our list of periods from the back end.
      //
      that.rcv = new RequestCountView();
      // console.log("Thinking about polling.");
      if ($('#pending-grand-total').data('auto-poll')) {
        // console.log("Starting polling");
        that.rcv.startPolling();
      }
    };

    //
    //  We provide a trigger method on the main window object
    //  so that other scripts can cause us to start polling.
    //
    //  When triggered, we will do an immediate request, and then
    //  if not already polling we will start polling.
    //
    window.triggerCountsUpdate = function() {
      that.rcv.fetchCount();
      that.rcv.startPolling();
    };


    return that;
  }();

  $(pendingRequestsHandler.init);
}

