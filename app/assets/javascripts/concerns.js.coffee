$(document).ready ->
  $('#colour_picker').spectrum
    preferredFormat: "hex"
    showInitial: true
    showPalette: true
    showSelectionPalette: true
    palette: ["#483D8B", "#CD5C5C", "#B8860B", "#7B68EE",
              "#808000", "#6B8E23", "#DB7093", "#2E8B57",
              "#A0522D", "#008080", "#3CB371", "#2F4F4F",
              "#556B2F", "#FF6347"]
    appendTo: $('#colour-sample')
    change: (colour) ->
      $('#colour-sample').css('background-color', colour.toHexString())
