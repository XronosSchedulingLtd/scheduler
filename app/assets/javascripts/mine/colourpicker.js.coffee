$(document).ready ->
  colour_picker = $('#colour_picker')
  if colour_picker
    palette = ["#483D8B", "#CD5C5C", "#B8860B", "#7B68EE",
               "#808000", "#6B8E23", "#DB7093", "#2E8B57",
               "#A0522D", "#008080", "#3CB371", "#2F4F4F",
               "#556B2F", "#FF6347"]
    extra = colour_picker.data('default-colour')
    if extra && !$.inArray(extra, palette)
      palette.push extra
    spectrumParams = {
      preferredFormat: "hex"
      showInitial: true
      showPalette: true
      showSelectionPalette: true
      palette: palette
      appendTo: $('#colour-sample')
      change: (colour) ->
        if (colour)
          $('#colour-sample').css('background-color', colour.toHexString())
    }
    if colour_picker.data('allow-empty')
      spectrumParams['allowEmpty'] = true
    $('#colour_picker').spectrum(spectrumParams)

