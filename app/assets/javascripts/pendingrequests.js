"use strict";

//
//  Don't do anything at all unless we are on the right page.
//

if ($('#pending_count').length) {

  var pendingRequestsHandler = function() {
    var that = {};

    var RequestCount = Backbone.Model.extend({
      url: "/users/pp",
      pp: "0"
    });

    var RequestCountView = Backbone.View.extend({
      el: '#pending_count',
      initialize: function(options) {
        _.bindAll(this, "fetchCount");
        this.model = new RequestCount();
        this.listenTo(this.model, 'sync', this.render);
        setInterval(this.fetchCount, 300 * 1000);
      },
      fetchCount: function() {
        this.model.fetch();
      },
      render: function() {
        this.$el.html(this.model.get("pp"));
      }
    });


    that.init = function() {
      //
      //  We need to fetch our list of periods from the back end.
      //
      that.rcv = new RequestCountView();
    };

    return that;
  }();

  $(pendingRequestsHandler.init);
}

