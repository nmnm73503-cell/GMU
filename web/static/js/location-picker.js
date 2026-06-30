(function () {
  var mapEl = document.getElementById("location-map");
  if (!mapEl || typeof L === "undefined") return;

  var latInput = document.getElementById("location-lat");
  var lngInput = document.getElementById("location-lng");
  var labelInput = document.getElementById("location-label");

  var startLat = parseFloat(mapEl.getAttribute("data-lat")) || -6.7924;
  var startLng = parseFloat(mapEl.getAttribute("data-lng")) || 39.2083;
  if (latInput && latInput.value) startLat = parseFloat(latInput.value);
  if (lngInput && lngInput.value) startLng = parseFloat(lngInput.value);

  var map = L.map(mapEl, { scrollWheelZoom: false }).setView([startLat, startLng], 13);
  L.tileLayer("https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png", {
    attribution: "© OpenStreetMap",
    maxZoom: 19,
  }).addTo(map);

  var marker = null;

  function setPin(lat, lng) {
    if (marker) marker.setLatLng([lat, lng]);
    else marker = L.marker([lat, lng], { draggable: true }).addTo(map);
    if (latInput) latInput.value = lat.toFixed(6);
    if (lngInput) lngInput.value = lng.toFixed(6);
    marker.on("dragend", function () {
      var p = marker.getLatLng();
      if (latInput) latInput.value = p.lat.toFixed(6);
      if (lngInput) lngInput.value = p.lng.toFixed(6);
    });
  }

  if (latInput && latInput.value && lngInput && lngInput.value) {
    setPin(startLat, startLng);
  }

  map.on("click", function (e) {
    setPin(e.latlng.lat, e.latlng.lng);
    if (labelInput && !labelInput.value.trim()) {
      labelInput.placeholder = "Pinned location — add address name";
    }
  });

  setTimeout(function () { map.invalidateSize(); }, 400);
})();
