"use strict";

//
//  Don't do anything at all unless we are on the right page.
//  This module doesn't actually have a visible view - it just provides
//  services to other modules.  It does however communicate
//  with the back end and needs a Backbone View to drive this.
//

if ($('#fullcalendarzzz').length) {

  var periodsHandler = function() {
    var that = {};

    var Period = Backbone.Model.extend({
    });

    var PeriodCollection = Backbone.Collection.extend({
      model: Period,
      url: '/periods'
    });

    var PeriodCollectionView = Backbone.View.extend({
      initialize: function(options) {
        this.collection = new PeriodCollection();
        this.listenTo(this.collection, 'sync', this.gotsome);
        this.collection.fetch();
      },
      gotsome: function() {
//        console.log("Got " + this.collection.size() + " periods");
      }
    });


    that.init = function() {
      //
      //  We need to fetch our list of periods from the back end.
      //
      that.pcv = new PeriodCollectionView();
    };

    return that;
  }();

  $(periodsHandler.init);
}

