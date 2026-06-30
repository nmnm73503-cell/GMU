(function () {
  var mapEl = document.getElementById("location-map");
  if (!mapEl || typeof L === "undefined") return;

  var latInput = document.getElementById("location-lat");
  var lngInput = document.getElementById("location-lng");
  var labelInput = document.getElementById("location-label");
  var suggestWrap = document.getElementById("location-suggestions");
  var suggestList = document.getElementById("location-suggestions-list");
  var suggestTimer = null;

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

  function clearSuggestions() {
    if (!suggestWrap || !suggestList) return;
    suggestList.innerHTML = "";
    suggestWrap.hidden = true;
  }

  function showSuggestions(items) {
    if (!suggestWrap || !suggestList) return;
    suggestList.innerHTML = "";
    if (!items.length) {
      suggestWrap.hidden = true;
      return;
    }
    items.slice(0, 6).forEach(function (it) {
      var btn = document.createElement("button");
      btn.type = "button";
      btn.className = "location-suggestion";
      btn.textContent = it.display_name;
      btn.addEventListener("click", function () {
        if (labelInput) labelInput.value = it.display_name;
        var lat = parseFloat(it.lat);
        var lng = parseFloat(it.lon);
        if (!isNaN(lat) && !isNaN(lng)) {
          setPin(lat, lng);
          map.setView([lat, lng], 15);
        }
        clearSuggestions();
      });
      suggestList.appendChild(btn);
    });
    suggestWrap.hidden = false;
  }

  function searchNominatim(q) {
    var url =
      "https://nominatim.openstreetmap.org/search?format=json&addressdetails=1&limit=6&q=" +
      encodeURIComponent(q);
    return fetch(url, { headers: { "Accept": "application/json" } })
      .then(function (r) { return r.json(); })
      .then(function (data) { return Array.isArray(data) ? data : []; })
      .catch(function () { return []; });
  }

  if (labelInput) {
    labelInput.setAttribute("autocomplete", "off");
    labelInput.addEventListener("input", function () {
      var q = labelInput.value.trim();
      if (suggestTimer) clearTimeout(suggestTimer);
      if (q.length < 3) {
        clearSuggestions();
        return;
      }
      suggestTimer = setTimeout(function () {
        searchNominatim(q).then(showSuggestions);
      }, 250);
    });
    labelInput.addEventListener("blur", function () {
      setTimeout(clearSuggestions, 180);
    });
  }

  setTimeout(function () { map.invalidateSize(); }, 400);
})();
