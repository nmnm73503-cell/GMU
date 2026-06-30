(function () {
  if (typeof google === "undefined" || !google.maps || !google.maps.places) return;

  var input = document.getElementById("location-label");
  var latInput = document.getElementById("location-lat");
  var lngInput = document.getElementById("location-lng");
  var mapEl = document.getElementById("location-map");
  if (!input || !latInput || !lngInput || !mapEl) return;

  var startLat = parseFloat(latInput.value || mapEl.getAttribute("data-lat") || "-6.7924");
  var startLng = parseFloat(lngInput.value || mapEl.getAttribute("data-lng") || "39.2083");

  var map = new google.maps.Map(mapEl, {
    center: { lat: startLat, lng: startLng },
    zoom: latInput.value && lngInput.value ? 15 : 12,
    mapTypeControl: false,
    streetViewControl: false,
    fullscreenControl: false,
  });

  var marker = new google.maps.Marker({
    map: map,
    position: { lat: startLat, lng: startLng },
    draggable: true,
    visible: !!(latInput.value && lngInput.value),
  });

  function setPin(lat, lng) {
    marker.setPosition({ lat: lat, lng: lng });
    marker.setVisible(true);
    map.panTo({ lat: lat, lng: lng });
    latInput.value = String(lat.toFixed(6));
    lngInput.value = String(lng.toFixed(6));
  }

  marker.addListener("dragend", function () {
    var p = marker.getPosition();
    if (!p) return;
    setPin(p.lat(), p.lng());
  });

  map.addListener("click", function (e) {
    if (!e || !e.latLng) return;
    setPin(e.latLng.lat(), e.latLng.lng());
  });

  var autocomplete = new google.maps.places.Autocomplete(input, {
    fields: ["formatted_address", "geometry", "name"],
  });
  autocomplete.addListener("place_changed", function () {
    var place = autocomplete.getPlace();
    if (!place || !place.geometry || !place.geometry.location) return;
    var loc = place.geometry.location;
    var label = place.formatted_address || place.name || input.value;
    input.value = label;
    setPin(loc.lat(), loc.lng());
    map.setZoom(15);
  });
})();

