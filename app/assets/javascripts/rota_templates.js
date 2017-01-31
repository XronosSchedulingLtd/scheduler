"use strict";

//
//  Do nothing at all unless we are on the right page.
//
if ($('#rotatemplate').length) {

//
//  Wrap everything in a function to avoid namespace pollution
//  Note that we invoke the function immediately.
//
var rotatemplates = function() {

  var that = {};

  var RotaTemplate = Backbone.Model.extend({
    urlRoot: '/rota_templates'
  });

  var RotaTemplateView = Backbone.View.extend({
    el: "#rt-header",
    model: RotaTemplate,
    template: _.template($('#rt-header-template').html()),
    initialize: function(rtid) {
      _.bindAll(this, 'editTitle', 'mightUpdate', 'abortEdit');
      this.model = new RotaTemplate({id: rtid});
      this.listenTo(this.model, 'sync', this.render);
      this.model.fetch();
    },
    render: function() {
      this.$el.html(this.template(this.model.toJSON()));
      this.$el.find('#title').on('dblclick', null, null, this.editTitle);
      this.$el.find('.edit').on('click', null, null, this.editTitle);
      this.title = this.$('#title');
      this.input = this.$('#title-box');
      this.input.on('keypress', null, null, this.mightUpdate);
      this.input.on('blur', null, null, this.abortEdit);
      return this;
    },
    editTitle: function() {
      console.log("Editing");
      this.input.val(this.model.get("name"));
      this.$el.addClass('editing');
      this.input.focus();
    },
    mightUpdate: function (e) {
      if (e.which === 13) {
        this.$el.removeClass('editing');
        this.model.set("name", this.input.val());
        this.model.save();
      }
    },
    abortEdit: function (e) {
      console.log("Lost focus");
      this.$el.removeClass('editing');
    }
  });

  var RotaSlot = Backbone.Model.extend({
    toggleDay: function(dayno) {
      var daynos = this.get('days');
      daynos[dayno] = !daynos[dayno];
      this.save();
    }
  });

  var RotaSlotView = Backbone.View.extend({
    model: RotaSlot,
    tagName: 'tr',
    className: 'rt-rotaslot',
    template: _.template($('#rt-slot-row').html()),
    initialize: function() {
      this.model.on('change', this.render, this);
      this.model.on('destroy', this.remove, this);
    },
    events: {
      'click .destroy' : 'destroy',
      'click .toggle' : 'toggleDay'
    },
    render: function() {
      this.$el.html(this.template(this.model.toJSON()));
      return this;
    },
    destroy: function() {
      this.model.destroy();
    },
    toggleDay: function(e) {
      console.log("Day toggled." + $(e.target).data('dayno'));
      //
      //  Has the toggle actually changed its value when we get
      //  this event?  Doesn't really matter - we can toggle our
      //  internal idea and then the row gets re-displayed anyway.
      //
      this.model.toggleDay($(e.target).data('dayno'));
    }
  });

  var RotaSlots = Backbone.Collection.extend({
    model: RotaSlot,
    initialize: function(models, options) {
      this.rtid = options.rtid;
    },
    comparator: function(item) {
      return item.attributes.start_second;
    },
    url: function() {
      return '/rota_templates/' + this.rtid + '/rota_slots'
    }
  });

  var SlotsView = Backbone.View.extend({
    el: '#rt-table',
    headertemplate: _.template($('#rt-header-row').html()),
    newslottemplate: _.template($('#rt-newslot-row').html()),
    errortemplate: _.template($('#rt-error-msg').html()),
    initialize: function (rtid) {
      _.bindAll(this, 'mightSubmit');
      this.collection = new RotaSlots(null, {rtid: rtid});
      this.listenTo(this.collection, 'sync', this.render);
      this.collection.fetch();
      //
      //  Also need a spare model to store stuff we might use to
      //  create a new model in the database.
      //
      this.pendingSlot = new RotaSlot({
        days: [false, true, true, true, true, true, false],
        starts_at: "",
        ends_at: ""
      });
    },
    events: {
      'click .add' : 'addSlot'
    },
    render: function() {
      console.log("Asked to render " + this.collection.length + " slots");
      var $list = this.$el.empty();
      $list.append(this.headertemplate);
      this.collection.each(function(model) {
        var slotView = new RotaSlotView({model: model});
        $list.append(slotView.render().$el);
      }, this);
      $list.append(this.newslottemplate(this.pendingSlot.toJSON()));
      this.saInput = this.$('#new-starts-at')
      this.eaInput = this.$('#new-ends-at')
      this.eaInput.on('keypress', null, null, this.mightSubmit);
      this.saInput.focus();
      return this;
    },
    mightSubmit: function (e) {
      if (e.which === 13 && this.saInput.val() && this.eaInput.val()) {
        this.addSlot();
      }
    },
    addSlot: function() {
      //
      //  First get rid of any left over error messages.
      //
      this.$(".error").remove();
      //alert("Asked to add. " + this.saInput.val());
      //
      //  Need to get values from the two input fields, plus build an
      //  array of values from the checkboxes.  This then should
      //  give me enough to request that a new model be created.
      //  The server tries to make sense of the time fields and may
      //  reject the request if it can't.
      //
      var days = [];
      var pendingSlotDays = this.pendingSlot.get('days');
      this.$el.find('#rt-newslot-row').find('.toggle').each(function(index, element)  {
        days[index] = element.checked;
        //
        //  If we succeed in creating the new element then our whole
        //  collection will be re-displayed, and it's friendly to our
        //  end user if we keep his set of flags.
        //
        //  Can assign to the attribute directly, because don't need
        //  any events triggering.
        //
        pendingSlotDays[index] = element.checked;
      });
      var newSlot = this.collection.create({
        days: days,
        starts_at: this.saInput.val(),
        ends_at: this.eaInput.val()
      }, {
        wait: true,
        success: function() {
          console.log("Created successfully.");
        },
        error: function(model, xhr, options) {
          var errors;

          console.log("Failed to create.");
          errors = $.parseJSON(xhr.responseText);
          for (var property in errors) {
            if (errors.hasOwnProperty(property)) {
              console.log(property + ": " + errors[property]);
            }
          }
        }
      }).on('error', this.creationError, this);
    },
    creationError: function(model, response, options) {
      var view, errors;

      console.log("Collection view noting error.");
      view = this;
      errors = $.parseJSON(response.responseText);
      for (var property in errors) {
        if (errors.hasOwnProperty(property)) {
          view.$el.find("#" + property).append(view.errortemplate({error_msg: errors[property]}));
        }
      }
    }
  });

  function getTemplate(rtid) {
    var templateView = new RotaTemplateView(rtid);
  };

  function getSlots(rtid) {
    var slotsView = new SlotsView(rtid);
  };

  that.init = function() {
    //
    //  We have already checked that our master parent division
    //  exists, otherwise we wouldn't be running at all.
    //
    var rtid = $('#rotatemplate').data("rtid");
    getTemplate(rtid);
    getSlots(rtid);
  }

  return that;

}();

//
//  Once the DOM is ready, get our code to initialise itself.
//
$(rotatemplates.init);

}
