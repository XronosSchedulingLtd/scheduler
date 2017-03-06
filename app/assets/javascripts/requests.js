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
      tagName: "li",
      events: {
        "dblclick" : "doubleClicked",
        "select"   : "preventSelect"
      },
      render: function() {
        this.$el.html(this.model.get("name"));
        return this;
      },
      doubleClicked: function(e) {
        alert(this.model.get("name"));
      },
      preventSelect: function(e) {
        e.preventDefault();
        return false;
      }
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
      initialize: function(options) {
        this.collection = new CandidateCollection(null, {rqid: options.rqid});
        this.listenTo(this.collection, 'sync', this.render);
        this.collection.fetch();
      },
      render: function() {
        this.$el.empty();
        this.collection.each(function(model) {
          var candidateView = new CandidateView({model: model});
          this.$el.append(candidateView.render().$el);
        }, this);
      }
    });

    //
    //  This next view is responsible just for the quantity spinner
    //  line.  It doesn't need to listen for changes to the model
    //  because the parent view will do that and ask this one to
    //  render itself.  It exists solely because we want to break
    //  up the display into separate parts, and something needs to
    //  own this part.
    //
    var QuantityView = Backbone.View.extend({
      template: _.template($('#request-quantity-template').html()),
      initialize: function() {
        _.bindAll(this, "spinnerChanged");
        this.listenTo(this.model, 'sync', this.render);
      },
      render: function() {
        this.$el.html(this.template(this.model.toJSON()));
        var quantity = this.model.get("quantity");
        this.$(".spinner").
             spinner({
               min: 0,
               max: this.model.get("max_quantity"),
               stop: this.spinnerChanged
             }).
             spinner("value", quantity);
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
        var rqid = this.$el.data("request-id");
        this.model = new Request({
          id: rqid
        });
        this.listenTo(this.model, 'sync', this.render);
        //
        //  Part of our display we want rendering only once, then
        //  separate views take responsiblity for parts of it.
        //
        this.$el.html(this.template(this.model.toJSON()));
        this.quantityView = new QuantityView({
          el: this.$(".quantity"),
          model: this.model
        });
        this.fulfillmentsol = this.$("div.fulfillments ol");
        this.model.fetch();
        this.candidateCollectionView = new CandidateCollectionView({
          el: this.$("div.candidates ul"),
          rqid: rqid
        });
      },
      render: function() {
        var quantity = this.model.get("quantity");
        this.fulfillmentsol.empty();
        for (var i = 0; i < quantity; i++) {
          this.fulfillmentsol.append("<li>blank...</li>");
        }
      },
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

