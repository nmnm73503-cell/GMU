(function () {
  var KEY = "gmu-theme";
  var root = document.documentElement;

  function systemDark() {
    return window.matchMedia("(prefers-color-scheme: dark)").matches;
  }

  function resolved(mode) {
    if (mode === "dark") return "dark";
    if (mode === "light") return "light";
    return systemDark() ? "dark" : "light";
  }

  function logoSrc(theme) {
    var base = root.getAttribute("data-static-base") || "";
    return theme === "dark"
      ? base + "/static/img/logo-dark.svg?v=3"
      : base + "/static/img/logo.svg?v=3";
  }

  function apply(resolvedTheme) {
    root.setAttribute("data-theme", resolvedTheme);
    var meta = document.querySelector('meta[name="theme-color"]');
    if (meta) {
      meta.content = resolvedTheme === "dark" ? "#000000" : "#FFFFFF";
    }
    document.querySelectorAll(".logo-img.logo-variant").forEach(function (img) {
      var light = img.getAttribute("data-logo-light");
      var dark = img.getAttribute("data-logo-dark");
      if (light && dark && img.classList.contains("logo-light")) {
        img.src = resolvedTheme === "dark" ? dark : light;
      }
    });
    document.querySelectorAll(".theme-toggle-btn").forEach(function (btn) {
      btn.textContent = resolvedTheme === "dark" ? "◑" : "◐";
      btn.setAttribute("aria-label", resolvedTheme === "dark" ? "Light mode" : "Dark mode");
    });
    document.querySelectorAll(".theme-select").forEach(function (sel) {
      sel.value = localStorage.getItem(KEY) || "system";
    });
    window.dispatchEvent(new CustomEvent("gmu-theme-change", { detail: resolvedTheme }));
  }

  function init() {
    var mode = localStorage.getItem(KEY) || "system";
    apply(resolved(mode));

    window.matchMedia("(prefers-color-scheme: dark)").addEventListener("change", function () {
      if ((localStorage.getItem(KEY) || "system") === "system") {
        apply(resolved("system"));
      }
    });
  }

  function setMode(mode) {
    localStorage.setItem(KEY, mode);
    apply(resolved(mode));
  }

  function cycleMode() {
    var cur = localStorage.getItem(KEY) || "system";
    var next = cur === "light" ? "dark" : cur === "dark" ? "system" : "light";
    setMode(next);
  }

  document.addEventListener("DOMContentLoaded", function () {
    apply(resolved(localStorage.getItem(KEY) || "system"));
    document.querySelectorAll(".theme-toggle-btn").forEach(function (btn) {
      btn.addEventListener("click", cycleMode);
    });
    document.querySelectorAll(".theme-select").forEach(function (sel) {
      sel.addEventListener("change", function () {
        setMode(sel.value);
      });
    });
  });

  window.GMUTheme = { init: init, setMode: setMode, resolved: function () { return resolved(localStorage.getItem(KEY) || "system"); } };
  init();
})();
