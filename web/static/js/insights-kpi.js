(function () {
  var pills = document.querySelectorAll(".kpi-pill");
  var panels = document.querySelectorAll("[data-kpi-panel]");
  if (!pills.length) return;

  function show(group) {
    pills.forEach(function (p) {
      p.classList.toggle("active", p.getAttribute("data-kpi") === group);
    });
    panels.forEach(function (panel) {
      panel.classList.toggle("active", panel.getAttribute("data-kpi-panel") === group);
    });
  }

  pills.forEach(function (pill) {
    pill.addEventListener("click", function () {
      show(pill.getAttribute("data-kpi"));
    });
  });
})();
