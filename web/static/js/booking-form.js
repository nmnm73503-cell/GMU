(function () {
  var picker = document.getElementById("glam-picker");
  var pkgInput = document.getElementById("package-id-input");
  var revenue = document.getElementById("revenue-input");
  var style = document.getElementById("service-style-input");
  var tier = document.getElementById("headcount-tier-input");
  var startSel = document.getElementById("start-time-select");
  var endSel = document.getElementById("end-time-select");
  var clientSelect = document.getElementById("client-select");
  var toggleNew = document.getElementById("toggle-new-client");
  var newPanel = document.getElementById("new-client-panel");
  var newName = document.getElementById("new-client-name");
  var form = document.getElementById("booking-form");

  function selectGlam(card) {
    if (!picker || !pkgInput) return;
    picker.querySelectorAll(".glam-card").forEach(function (c) {
      c.classList.remove("selected");
    });
    card.classList.add("selected");
    var id = card.getAttribute("data-id");
    pkgInput.value = id;
    var price = card.getAttribute("data-price");
    var svc = card.getAttribute("data-style") || "";
    var t = card.getAttribute("data-tier") || "";
    if (style) style.value = svc;
    if (tier) tier.value = t;
    if (revenue) {
      if (id === "tbd") {
        revenue.value = "";
        revenue.placeholder = "0 — decide on site";
      } else if (price !== null && price !== "") {
        revenue.value = price;
      }
    }
    var statusEl = document.getElementById("booking-status");
    if (statusEl && id === "tbd" && !document.querySelector("[name=date]")?.dataset?.editing) {
      statusEl.value = "inquiry";
    }
  }

  if (picker) {
    picker.addEventListener("click", function (e) {
      var card = e.target.closest(".glam-card");
      if (card) selectGlam(card);
    });
    var selected = picker.querySelector(".glam-card.selected");
    if (selected) selectGlam(selected);
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

  // Start/end are set by the live session (stopwatch), not guessed here.
  // Keep manual time selection available but do not auto-set end time.
  // if (startSel) startSel.addEventListener("change", setEndFromStart);

  if (toggleNew && newPanel) {
    toggleNew.addEventListener("click", function () {
      var open = newPanel.hasAttribute("hidden");
      if (open) {
        newPanel.removeAttribute("hidden");
        toggleNew.setAttribute("aria-expanded", "true");
        toggleNew.textContent = "Cancel";
        if (clientSelect) clientSelect.required = false;
        if (newName) newName.focus();
      } else {
        newPanel.setAttribute("hidden", "");
        toggleNew.setAttribute("aria-expanded", "false");
        toggleNew.textContent = "+ New";
        if (clientSelect) clientSelect.required = true;
        if (newName) newName.value = "";
      }
    });
  }

  if (form) {
    form.addEventListener("submit", function (e) {
      var hasNew = newName && newName.value.trim();
      if (!hasNew && clientSelect && !clientSelect.value) {
        e.preventDefault();
        alert("Select a client or tap + New to add one.");
      }
      if (hasNew && clientSelect) clientSelect.removeAttribute("required");
    });
  }

  // Menu no longer sets a preset package on the booking form.
})();
