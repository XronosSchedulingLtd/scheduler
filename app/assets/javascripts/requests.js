"use strict";

//
//  Don't do anything at all unless we are on the right page.
//

if ($('#fullcalendar').length) {

  var requestsHandler = function() {
    var that = {};

    var Candidate = Backbone.Model.extend({
    });

    var CandidateView = Backbone.View.extend({
    });

    var CandidateCollection = Backbone.Collection.extend({
      model: Candidate,
      initialize: function(models, options) {
        this.rqid = options.rqid;
      },
      url: function() {
        return '/requests/' + this.rqid + '/candidates'
      }
    });

    var CandidateCollectionView = Backbone.View.extend({
    });

    var Request = Backbone.Model.extend({
      urlRoot: '/requests',
      defaults: {
        element_name: "** not given **",
        max_quantity: 7,
        candidates: ["...populating..."]
      }
    });

    var RequestView = Backbone.View.extend({
      template: _.template($('#request-set-template').html()),
      initialize: function() {
        _.bindAll(this, "spinnerChanged");
        this.model = new Request({
          id: this.$el.data("request-id")
        });
        this.listenTo(this.model, 'sync', this.render);
        this.model.fetch();
      },
      render: function() {
        var quantity = this.model.get("quantity");
        this.$el.html(this.template(this.model.toJSON()));
        this.$(".spinner").
             spinner({
               min: 0,
               max: this.model.get("max_quantity"),
               stop: this.spinnerChanged
             }).
             spinner("value", quantity);
        var fulfillments = this.$(".fulfillments");
        fulfillments.append("<ol>");
        var ol = fulfillments.find("ol");
        for (var i = 0; i < quantity; i++) {
          ol.append("<li>blank...</li>");
        }
        var candidates = this.$(".candidates");
        candidates.append("<ul>");
        var ul = candidates.find("ul");
        var list = this.model.get("candidates");
        if (list) {
          list.forEach(function(entry) {
            ul.append("<li>" + entry + "</li>");
          })
        }

      },
      spinnerChanged: function() {
        var current_value = this.model.get("quantity");
        var value = this.$(".spinner").spinner("value");
        if (value !== null && value !== current_value) {
          this.model.set("quantity", value);
          this.model.save();
        }
      }
    });

    that.modalOpened = function() {
      //alert("Hello - someone opened the modal.");
      //
      //  Now is the time to scan the contents of the modal for our
      //  fields, and attach to them.  Arguably, it might make sense
      //  to fetch our data before the modal is opened, but we'll
      //  worry about that later.
      //
      $('.request-div').each(function(index, el) {
        var requestView = new RequestView({
          el: el
        });
      });
    };

    that.init = function() {
      //
      //  This is called at page initialisation, which is too early
      //  to look for our elements.  We need to wait for the
      //  dialogue box to open, then look.
      //
      _.bindAll(that, 'modalOpened');
      $(document).on('opened', '[data-reveal]', that.modalOpened);
    };

    return that;
  }();

  $(requestsHandler.init);
}

