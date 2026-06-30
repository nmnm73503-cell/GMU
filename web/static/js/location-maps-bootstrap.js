(function () {
  var mapEl = document.getElementById("location-map");
  if (!mapEl) return;

  var cfg = window.gmuMapsConfig || {};
  var staticBase = document.body.getAttribute("data-static-base") || "";

  function loadScript(src, onload) {
    var s = document.createElement("script");
    s.src = src;
    s.onload = onload || null;
    document.body.appendChild(s);
  }

  function loadOsmFallback() {
    if (window.gmuOsmLoaded) return;
    window.gmuOsmLoaded = true;
    var link = document.createElement("link");
    link.rel = "stylesheet";
    link.href = "https://unpkg.com/leaflet@1.9.4/dist/leaflet.css";
    document.head.appendChild(link);
    loadScript("https://unpkg.com/leaflet@1.9.4/dist/leaflet.js", function () {
      loadScript(staticBase + "/static/js/location-picker.js?v=2");
    });
  }

  window.gmuLoadOsmFallback = loadOsmFallback;

  window.gm_authFailure = function () {
    loadOsmFallback();
  };

  if (!cfg.googleKey) {
    return;
  }

  window.gmuInitGoogleMaps = function () {
    if (!window.google || !window.google.maps) {
      loadOsmFallback();
      return;
    }
    loadScript(staticBase + "/static/js/location-google.js?v=3");
  };

  setTimeout(function () {
    if (!window.google || !window.google.maps) {
      loadOsmFallback();
    }
  }, 6000);
})();
