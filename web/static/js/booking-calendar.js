(function () {
  var root = document.getElementById("booking-calendar");
  var hidden = document.getElementById("booking-date");
  if (!root || !hidden) return;

  var MONTHS = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
  var today = new Date();
  today.setHours(0, 0, 0, 0);

  var initial = hidden.value ? parseIso(hidden.value) : new Date(today);
  if (!initial || isNaN(initial.getTime())) initial = new Date(today);

  var viewYear = initial.getFullYear();
  var viewMonth = initial.getMonth();
  var selected = hidden.value ? parseIso(hidden.value) : null;
  var minDate = root.getAttribute("data-editing") ? null : today;

  function parseIso(s) {
    var p = s.split("-");
    if (p.length !== 3) return null;
    return new Date(parseInt(p[0], 10), parseInt(p[1], 10) - 1, parseInt(p[2], 10));
  }

  function iso(d) {
    var y = d.getFullYear();
    var m = d.getMonth() + 1;
    var day = d.getDate();
    return y + "-" + (m < 10 ? "0" : "") + m + "-" + (day < 10 ? "0" : "") + day;
  }

  function sameDay(a, b) {
    return a && b && a.getFullYear() === b.getFullYear() && a.getMonth() === b.getMonth() && a.getDate() === b.getDate();
  }

  function isDisabled(d) {
    return minDate && d < minDate;
  }

  function render() {
    var first = new Date(viewYear, viewMonth, 1);
    var startDow = first.getDay();
    var daysInMonth = new Date(viewYear, viewMonth + 1, 0).getDate();

    var html = '<div class="cal-header">';
    html += '<button type="button" class="cal-nav" data-dir="-1" aria-label="Previous month">‹</button>';
    html += '<span class="cal-title">' + MONTHS[viewMonth] + " " + viewYear + "</span>";
    html += '<button type="button" class="cal-nav" data-dir="1" aria-label="Next month">›</button>';
    html += "</div>";

    html += '<div class="cal-weekdays">';
    ["Su", "Mo", "Tu", "We", "Th", "Fr", "Sa"].forEach(function (w) {
      html += '<span class="cal-weekday">' + w + "</span>";
    });
    html += "</div>";

    html += '<div class="cal-grid">';
    for (var i = 0; i < startDow; i++) {
      html += '<span class="cal-day cal-day-empty"></span>';
    }
    for (var day = 1; day <= daysInMonth; day++) {
      var d = new Date(viewYear, viewMonth, day);
      var cls = "cal-day";
      if (sameDay(d, today)) cls += " cal-today";
      if (selected && sameDay(d, selected)) cls += " cal-selected";
      if (isDisabled(d)) cls += " cal-disabled";
      html += '<button type="button" class="' + cls + '" data-day="' + day + '"' +
        (isDisabled(d) ? " disabled" : "") + ">" + day + "</button>";
    }
    html += "</div>";

    if (selected) {
      html += '<p class="cal-selected-label">Selected: <strong>' + iso(selected) + "</strong></p>";
    }

    root.innerHTML = html;
    bind();
  }

  function bind() {
    root.querySelectorAll(".cal-nav").forEach(function (btn) {
      btn.addEventListener("click", function () {
        var dir = parseInt(btn.getAttribute("data-dir"), 10);
        viewMonth += dir;
        if (viewMonth < 0) {
          viewMonth = 11;
          viewYear -= 1;
        } else if (viewMonth > 11) {
          viewMonth = 0;
          viewYear += 1;
        }
        render();
      });
    });

    root.querySelectorAll(".cal-day:not(.cal-disabled)").forEach(function (btn) {
      btn.addEventListener("click", function () {
        var day = parseInt(btn.getAttribute("data-day"), 10);
        selected = new Date(viewYear, viewMonth, day);
        hidden.value = iso(selected);
        render();
      });
    });
  }

  if (selected) hidden.value = iso(selected);
  render();
})();
