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
      template: _.template($('#candidate-line').html()),
      events: {
        "dblclick"     : "addCandidate",
        "click .adder" : "addCandidate",
        "select"       : "preventSelect"
      },
      render: function() {
        if (this.model.get("has_suspended")) {
          this.$el.addClass("suspended").
                   html(this.template(this.model.toJSON()));
        } else {
          this.$el.html(this.template(this.model.toJSON()));
        }
        this.$el.disableSelection();
        return this;
      },
      addCandidate: function(event) {
        //
        //  The user wants to add this element to those fulfilling the
        //  request.  Get the main controller (View) to do the work.
        //
        event.preventDefault();
        that.requestView.fulfillWith(this.model.get("element_id"));
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
      comparator: function(able, baker) {
        var result = 0;
        var able_suspended = able.get("has_suspended");
        var baker_suspended = baker.get("has_suspended");
        if (able_suspended === baker_suspended) {
          var able_today = able.get("today_count");
          var baker_today = baker.get("today_count");
          if (able_today === baker_today) {
            var able_tw = able.get("this_week_count");
            var baker_tw = baker.get("this_week_count");
            if (able_tw === baker_tw) {
              //
              //  Fall back on alphabetical.
              //
              var able_name = able.get("name");
              var baker_name = baker.get("name");
              result = able_name.localeCompare(baker_name);
            } else {
              if (able_tw < baker_tw) {
                result = -1;
              } else {
                result = 1;
              }
            }
          } else {
            if (able_today < baker_today) {
              result = -1;
            } else {
              result = 1;
            }
          }
        } else {
          if (able_suspended) {
            result = -1;
          } else {
            result = 1;
          }
        }
        return result;
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
          //
          //  We only get to see them if they are *not* currently
          //  in use as nominees.
          //
          if (!that.requestView.used(model.get("element_id"))) {
            var candidateView = new CandidateView({model: model});
            this.$el.append(candidateView.render().$el);
          }
        }, this);
      },
      updateLoading: function(new_data) {
        var relevant_entry =
          this.collection.findWhere({element_id: new_data.element_id});
        if (relevant_entry) {
          relevant_entry.set({
            today_count: new_data.today_count,
            this_week_count: new_data.this_week_count
          });
          this.collection.sort();
        }
      }
    });

    var Nominee = Backbone.Model.extend({
    });

    var NomineeView = Backbone.View.extend({
      tagName: "li",
      template: _.template($('#nominee-line').html()),
      events: {
        "select"         : "preventSelect",
        "click .deleter" : "removeNominee"
      },
      render: function() {
        this.$el.html(this.template(this.model.toJSON()));
        this.$el.disableSelection();
        return this;
      },
      preventSelect: function(e) {
        e.preventDefault();
        return false;
      },
      removeNominee: function(event) {
        event.preventDefault();
        var element_id = this.model.get("element_id");
        that.requestView.unfulfillWith(element_id);
      }
    });

    var NomineeCollection = Backbone.Collection.extend({
      model: Nominee
    });

    var NomineeCollectionView = Backbone.View.extend({
      initialize: function() {
        this.collection = new NomineeCollection();
      },
      render: function(slots) {
        this.$el.empty();
        this.collection.each(function(model) {
          var nomineeView = new NomineeView({model: model});
          this.$el.append(nomineeView.render().$el);
        }, this);
        if (this.collection.length < slots) {
          var extra = slots - this.collection.length;
          for (var i = 0; i < extra; i++) {
            this.$el.append("<li>blank...</li>");
          }
        }
      },
      used: function(element_id) {
        var found = false;
        this.collection.each(function(model) {
          if (model.get("element_id") === element_id) {
            found = true;
          }
        }, this);
        return found;
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
        this.listenTo(this.model, 'change', this.render);
      },
      render: function() {
        this.$el.html(this.template(this.model.toJSON()));
        var quantity = this.model.get("quantity");
        var currently = this.model.get("nominees").length;
        this.$(".spinner").
             spinner({
               min: currently,
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
          $('#fullcalendar').data("dorefresh", "1")
        }
      }
    });

    var Request = Backbone.Model.extend({
      urlRoot: '/requests',
      defaults: {
        element_name: "** not given **",
        max_quantity: 7,
        candidates: ["...populating..."]
      },
      fulfillWith: function(element_id) {
        $.ajax({
          url: this.url() + '/fulfill?eid=' + element_id,
          type: 'PUT',
          context: this,
          contentType: 'application/json',
        }).done(this.fulfillSucceeded).
           fail(this.fulfillFailed);
      },
      unfulfillWith: function(element_id) {
        $.ajax({
          url: this.url() + '/unfulfill?eid=' + element_id,
          type: 'PUT',
          context: this,
          contentType: 'application/json',
        }).done(this.fulfillSucceeded).
           fail(this.fulfillFailed);
      },
      fulfillSucceeded: function(data, textStatus, jqXHR) {
        this.set(data);
        $('#fullcalendar').data("dorefresh", "1")
      },
      fulfillFailed: function(jqXHR, textStatus, errorThrown) {
        alert("Failed");
      }
    });

    var RequestView = Backbone.View.extend({
      template: _.template($('#request-set-template').html()),
      events: {
        'click #addbutton'          : 'addRequested',
        'keypress input.inputextra' : 'mightSubmit'
      },
      initialize: function() {
        _.bindAll(this, "fulfillWith", "unfulfillWith");
        var rqid = this.$el.data("request-id");
        this.model = new Request({
          id: rqid
        });
        this.listenTo(this.model, 'change', this.render);
        //
        //  Part of our display we want rendering only once, then
        //  separate views take responsiblity for parts of it.
        //
        this.$el.html(this.template(this.model.toJSON()));
        this.quantityView = new QuantityView({
          el: this.$(".quantity"),
          model: this.model
        });
        this.nomineeCollectionView = new NomineeCollectionView({
          el: this.$("div.fulfillments ol")
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
        var nominees = this.model.get("nominees");
        var models = _.map(nominees, function(nominee) {
          return new Nominee(nominee);
        });
        this.nomineeCollectionView.collection.set(models);
        this.nomineeCollectionView.render(quantity);
        //
        //  Need to re-render our candidate list because the change
        //  to our nominee list may well affect it.
        //
        //  Before we do that, we need to check to see whether the
        //  latest response contained an update to the loading of
        //  one of our candidates.
        //
        var updated_nominee = this.model.get("updated_nominee");
        if (updated_nominee) {
          this.candidateCollectionView.updateLoading(updated_nominee);

        }
        this.candidateCollectionView.render();
        this.$('#extra_resource_id').val("");
        this.$('.inputextra').val("");
      },
      fulfillWith: function(element_id) {
        this.model.fulfillWith(element_id);
      },
      unfulfillWith: function(element_id) {
        this.model.unfulfillWith(element_id);
      },
      addRequested: function() {
        var element_id = this.$('#extra_resource_id').val();
        if (element_id) {
          this.model.fulfillWith(element_id);
        }
      },
      mightSubmit: function(e) {
        if (e.which === 13 && this.$('#extra_resource_id').val()) {
          this.addRequested();
        }
      },
      used: function(element_id) {
        return this.nomineeCollectionView.used(element_id);
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
        that.requestView = new RequestView({
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

