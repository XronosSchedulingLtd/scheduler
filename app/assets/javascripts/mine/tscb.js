"use strict";
//
//  A fresh implementation of Tri-State CheckBoxes (TSCB) to suit
//  Scheduler.  Requires different capabilities from the one in Markbook,
//  plus the rules of JavaScript coding have moved on a bit.
//
//  This implementation uses jQuery, where the old one used Prototype.
//
//  This component will look for elements with a class of 'tscb-zone'
//  and if it finds any then it will initialize any TSCB's it finds
//  therein.  Alternatively you can call it explicitly specifying your
//  own container element.
//
//  Each tscb can have one of three states:
//
//     False
//     True
//     Don't care
//
//  and for the last one we give some visual indication of what the
//  fall-back position will be.  Thus, as well as providing a current
//  state, the element needs to provide a fallback state, and we will
//  then display the correct icon, but faded out.
//
//  If the element does not include the fallback information, then we
//  will allow only the first two states.
//
//  View code should provide the following structure
//
//  <div class='tscb-zone'>
//    <span class='tscb' data-default-value='0'>
//      <input class='tscb-field' type='hidden' value='0'>
//      </input>
//    </span>
//    <span class='tscb' data-default-vault='1'>
//    ...
//    </span>
//    ...
//  </div>
//
//  One zone containing all the fields.
//  N items of class tscb, each of which may provide a default value.
//  A hidden field within the tscb item - the actual img will be
//  inserted immediately before this field.  You can have other
//  things (e.g. a label) within the tscb item.  Clicks are detected
//  on the whole item, so then a click on the label will effect
//  the change too.
//
//  
//

var tscbHandler = function() {

  var BASIC_IMAGES = [
    'false16.png',
    'true16.png'
  ];

  var that = {};

  that.zones = [];

  //
  //  Model for a single Tri-State CheckBox.
  //
  var TSCB = Backbone.Model.extend({
    initialize: function(options) {
      //
      //  Need its current value.
      //
      this.field = options.field;
//      console.log("Default value = " + options.defaultValue);
//      console.log("Default value type = " + typeof options.defaultValue);
      this.images = BASIC_IMAGES.slice();
      //
      //  Note that defaultValue might be "undefined".
      //
      if (options.defaultValue === 0) {
        this.numImages = 3;
        this.images.push(BASIC_IMAGES[0]);
        this.direction = -1;
      } else if (options.defaultValue === 1) {
        this.numImages = 3;
        this.images.push(BASIC_IMAGES[1]);
        this.direction = 1;
      } else {
        this.numImages = 2;
        this.direction = 1;
      }
      this.value = parseInt(this.field.val());
//      console.log("this.value = " + this.value);
      //
      //  Check it's valid.
      //
      if (isNaN(this.value) ||
          this.value < 0 ||
          this.value >= this.numImages) {
//        console.log("Setting to 0");
        this.value = 0;
      }
      this.attributes.imagename = '/images/' + this.images[this.value];
      if (this.value == 2) {
        this.attributes.faded = true;
      } else {
        this.attributes.faded = false;
      }
    },
    clicked: function() {
      this.value += this.direction;
      //
      //  Range check.
      //
      if (this.value < 0) {
        this.value = this.numImages - 1;
      } else if (this.value >= this.numImages) {
        this.value = 0;
      }
      this.field.val(this.value);
      this.set({
        imagename: '/images/' + this.images[this.value],
        faded: (this.value === 2)
      });
    }
  });

  //
  //  View for a single Tri-State CheckBox.
  //
  var TSCBView = Backbone.View.extend({
    initialize: function() {
      this.tscbField = this.$el.find('.tscb-field');
      this.defaultValue = this.$el.data('default-value');
      this.model = new TSCB({
        field:        this.tscbField,
        defaultValue: this.defaultValue
      });
      this.$image = $("<img src='" + this.model.get('imagename') + "'/>");
      if (this.model.get('faded')) {
        this.$image.addClass('default-value');
      }
      this.$image.insertBefore(this.tscbField);
      this.listenTo(this.model, 'change', this.render);
    },
    events: {
      'click': 'clicked'
    },
    clicked: function(event) {
      this.model.clicked();
    },
    render: function() {
      this.$image.attr("src", this.model.get('imagename'));
      if (this.model.get('faded')) {
        this.$image.addClass('default-value');
      } else {
        this.$image.removeClass('default-value');
      }

    }

  });

  var TSCBZoneView = Backbone.View.extend({
    selector: '.tscb',
    initialize: function() {
      this.$el.find(this.selector).each(function(index, element) {
        new TSCBView({el: element});
      });
    }
  });

  var initElement = function(index, element) {
    new TSCBZoneView({el: element});
  }

  that.checkForZones = function() {
//    console.log("In checkForZones");
    $('.tscb-zone').each(initElement);
  }

  return that;
}();

$(tscbHandler.checkForZones);
