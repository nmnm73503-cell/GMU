(function () {
  var pkg = document.getElementById("service-package");
  var revenue = document.getElementById("revenue-input");
  var style = document.getElementById("service-style-input");
  var tier = document.getElementById("headcount-tier-input");
  var startSel = document.getElementById("start-time-select");
  var endSel = document.getElementById("end-time-select");
  if (!pkg || !revenue) return;

  function applyPackage() {
    var opt = pkg.options[pkg.selectedIndex];
    if (!opt) return;
    var price = opt.getAttribute("data-price");
    var svc = opt.getAttribute("data-style") || "";
    var t = opt.getAttribute("data-tier") || "";
    if (price !== null && price !== "") {
      revenue.value = price;
    }
    if (style) style.value = svc;
    if (tier) tier.value = t;
  }

  function parseSlot(slot) {
    if (!slot) return null;
    var m = slot.match(/^(\d{1,2}):(\d{2})\s*(AM|PM)$/i);
    if (!m) return null;
    var h = parseInt(m[1], 10);
    var min = parseInt(m[2], 10);
    var pm = m[3].toUpperCase() === "PM";
    if (pm && h !== 12) h += 12;
    if (!pm && h === 12) h = 0;
    return h * 60 + min;
  }

  function formatSlot(mins) {
    mins = ((mins % 1440) + 1440) % 1440;
    var h24 = Math.floor(mins / 60);
    var m = mins % 60;
    var pm = h24 >= 12;
    var h12 = h24 % 12;
    if (h12 === 0) h12 = 12;
    return (h12 < 10 ? "0" : "") + h12 + ":" + (m < 10 ? "0" : "") + m + " " + (pm ? "PM" : "AM");
  }

  function setEndFromStart() {
    if (!startSel || !endSel) return;
    var startMins = parseSlot(startSel.value);
    if (startMins === null) return;
    var target = formatSlot(startMins + 60);
    for (var i = 0; i < endSel.options.length; i++) {
      if (endSel.options[i].value === target) {
        endSel.value = target;
        return;
      }
    }
  }

  pkg.addEventListener("change", applyPackage);
  if (startSel) {
    startSel.addEventListener("change", setEndFromStart);
  }
  if (!revenue.value) applyPackage();
})();
