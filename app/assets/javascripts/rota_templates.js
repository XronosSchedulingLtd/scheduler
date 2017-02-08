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
    initialize: function(rtid) {
      _.bindAll(this, 'editTitle', 'mightUpdate', 'abortEdit');
      this.model = new RotaTemplate({id: rtid});
      this.listenTo(this.model, 'sync', this.render);
      this.model.fetch();
    },
    events: {
      'dblclick #title'     : 'editTitle',
      'click .edit'         : 'editTitle',
      'keypress #title-box' : 'mightUpdate',
      'click .update'       : 'update',
      'click .cancel'       : 'abortEdit'
    },
    render: function() {
      var current_name = this.model.get('name');
      this.$('#title').html(current_name);
      return this;
    },
    editTitle: function() {
      console.log("Editing");
      var titleBox = this.$('#title-box')
      titleBox.val(this.model.get('name'));
      this.$el.addClass('editing');
      titleBox.focus();
    },
    update: function() {
      this.$el.removeClass('editing');
      this.model.set("name", this.$('#title-box').val());
      this.model.save();
    },
    mightUpdate: function(e) {
      if (e.which === 13) {
        this.update();
      }
    },
    abortEdit: function (e) {
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
//      console.log("Day toggled." + $(e.target).data('dayno'));
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
    errortemplate: _.template($('#rt-error-msg').html()),
    initialize: function (rtid) {
      _.bindAll(this, 'creationOK');
      this.$tbody = this.$('tbody');
      this.$tfoot = this.$('tfoot');
      this.saInput = this.$('#new-starts-at')
      this.eaInput = this.$('#new-ends-at')
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
      'click .add'              : 'addSlot',
      'keypress #new-starts-at' : 'mightSubmit',
      'keypress #new-ends-at'   : 'mightSubmit'
    },
    render: function() {
      console.log("Asked to render " + this.collection.length + " slots");
      var $list = this.$tbody.empty();
      this.collection.each(function(model) {
        var slotView = new RotaSlotView({model: model});
        $list.append(slotView.render().$el);
      }, this);
      //
      //  Need to set initial values of input checkboxes.
      //
      var pendingSlotDays = this.pendingSlot.get('days');
      this.$tfoot.find('.toggle').each(function(index, element) {
        $(element).prop('checked', pendingSlotDays[index]);
      });
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
      //  First get rid of any left over error messages and attributes.
      //
      this.$("small.error").remove();
      this.$("div.error").removeClass("error");
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
        success: this.creationOK,
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
    creationOK: function() {
      console.log("Created successfully.");
      this.saInput.val('');
      this.eaInput.val('');
    },
    creationError: function(model, response, options) {
      var view, errors;

      console.log("Collection view noting error.");
      view = this;
      errors = $.parseJSON(response.responseText);
      for (var property in errors) {
        if (errors.hasOwnProperty(property)) {
          var div = view.$el.find("#" + property)
          div.append(view.errortemplate({error_msg: errors[property]}));
          div.addClass("error");
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
