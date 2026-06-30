(function () {
  var STORAGE_KEY = "gmu-session-state";
  var root = document.getElementById("session-timer-root");
  if (!root) return;

  var upcoming = [];
  var packages = [];
  var categoryLabels = {};

  try {
    upcoming = JSON.parse(
      (document.getElementById("session-upcoming-data") || {}).textContent || "[]"
    );
  } catch (e) {
    upcoming = [];
  }
  try {
    var pkgData = JSON.parse(
      (document.getElementById("session-packages-data") || {}).textContent || "[]"
    );
    packages = pkgData.packages || pkgData;
    categoryLabels = pkgData.category_labels || {};
  } catch (e2) {
    packages = [];
  }

  var completeUrl = root.getAttribute("data-complete-url") || "";
  var tickTimer = null;
  var faceCounter = 0;

  function loadState() {
    try {
      return JSON.parse(localStorage.getItem(STORAGE_KEY) || "null");
    } catch (e) {
      return null;
    }
  }

  function saveState(state) {
    localStorage.setItem(STORAGE_KEY, JSON.stringify(state));
  }

  function clearState() {
    localStorage.removeItem(STORAGE_KEY);
  }

  function defaultState() {
    return {
      running: false,
      startedAt: null,
      hostApptId: null,
      faces: [],
      phase: "pick",
      receipts: [],
      durationMinutes: 0,
      cfg: null,
    };
  }

  function getState() {
    return loadState() || defaultState();
  }

  function apptById(id) {
    for (var i = 0; i < upcoming.length; i++) {
      if (upcoming[i].id === id) return upcoming[i];
    }
    return null;
  }

  function pkgById(id) {
    for (var i = 0; i < packages.length; i++) {
      if (packages[i].id === id) return packages[i];
    }
    return null;
  }

  function fmtElapsed(ms) {
    var s = Math.floor(ms / 1000);
    var h = Math.floor(s / 3600);
    var m = Math.floor((s % 3600) / 60);
    var sec = s % 60;
    return (
      (h < 10 ? "0" : "") + h + ":" +
      (m < 10 ? "0" : "") + m + ":" +
      (sec < 10 ? "0" : "") + sec
    );
  }

  function fmtMoney(amount, currency) {
    return (currency || "TZS") + " " + Math.round(amount).toLocaleString();
  }

  function escapeHtml(s) {
    if (!s) return "";
    return String(s)
      .replace(/&/g, "&amp;")
      .replace(/</g, "&lt;")
      .replace(/>/g, "&gt;")
      .replace(/"/g, "&quot;");
  }

  function groupFaces(faces) {
    var groups = {};
    faces.forEach(function (f) {
      var key = f.package_id;
      if (!groups[key]) {
        groups[key] = { label: f.label, price: f.price, count: 0 };
      }
      groups[key].count += 1;
    });
    return Object.keys(groups).map(function (k) {
      return groups[k];
    });
  }

  function facesTotal(faces) {
    var t = 0;
    faces.forEach(function (f) {
      t += f.price || 0;
    });
    return t;
  }

  function defaultPackageId(host) {
    if (!host || !packages.length) return packages[0] ? packages[0].id : "";
    var tier = host.headcount_tier || "";
    var style = (host.service_style || "").toLowerCase();
    for (var i = 0; i < packages.length; i++) {
      var p = packages[i];
      if (tier && p.tier === tier && style && p.style === style) return p.id;
    }
    for (var j = 0; j < packages.length; j++) {
      if (packages[j].tier === tier) return packages[j].id;
    }
    return packages[0].id;
  }

  function renderSessionGlamPicker(selectedId) {
    var html = '<div class="glam-picker glam-picker-compact" id="session-glam-picker">';
    packages.forEach(function (p) {
      var sel = p.id === selectedId ? " selected" : "";
      html +=
        '<button type="button" class="glam-card glam-card-sm' + sel + '" data-id="' + escapeHtml(p.id) + '">' +
        '<span class="glam-card-title">' + escapeHtml(p.label.split("(")[0].trim()) + "</span>" +
        '<span class="glam-card-price">' + fmtMoney(p.price) + "</span></button>";
    });
    html += "</div>";
    html += '<input type="hidden" id="session-package-id" value="' + escapeHtml(selectedId || (packages[0] && packages[0].id) || "") + '">';
    return html;
  }

  function renderReceiptCard(r, idx) {
    var appt = r.appt;
    var cfg = r.cfg || {};
    var id = "receipt-share-" + idx;
    var lines = r.session_lines || [];
    var glamTotal = r.glam_total != null ? r.glam_total : (appt.revenue || 0);
    var transport = r.transport_cost != null ? r.transport_cost : (appt.transport_cost || 0);
    var grand = r.grand_total != null ? r.grand_total : glamTotal + transport;

    var lineHtml = "";
    if (lines.length) {
      lines.forEach(function (line) {
        lineHtml +=
          '<div class="receipt-line"><span>' + line.count + "× " + escapeHtml(line.label) +
          "</span><span>" + fmtMoney(line.subtotal, cfg.currency) + "</span></div>";
      });
    } else {
      lineHtml =
        '<div class="receipt-line"><span>Service</span><span>' +
        escapeHtml(appt.service_style || "Makeup") + "</span></div>" +
        '<div class="receipt-line"><span>Base rate</span><span>' +
        fmtMoney(appt.revenue, cfg.currency) + "</span></div>";
    }

    var travel = transport
      ? '<div class="receipt-line"><span>Travel fee</span><span>' +
        fmtMoney(transport, cfg.currency) + "</span></div>"
      : "";

    return (
      '<article class="receipt-page glass receipt-share-card" id="' + id + '" data-receipt-no="' +
      escapeHtml(r.receipt_no) + '">' +
      '<p class="receipt-subtitle">' + escapeHtml(cfg.artist_name || "Nawal") + "</p>" +
      '<div class="receipt-line"><span>Receipt #</span><span>' + escapeHtml(r.receipt_no) + "</span></div>" +
      '<div class="receipt-line"><span>Date</span><span>' + escapeHtml(appt.date) + "</span></div>" +
      '<div class="receipt-line"><span>Booking</span><span>' + escapeHtml(appt.client_name) + "</span></div>" +
      '<div class="receipt-line"><span>Time</span><span>' +
      escapeHtml(appt.start_time || "—") + " – " + escapeHtml(appt.end_time || "—") + "</span></div>" +
      lineHtml +
      travel +
      '<div class="receipt-line receipt-total"><span>Total</span><span>' +
      fmtMoney(grand, cfg.currency) + "</span></div>" +
      '<button type="button" class="btn btn-primary session-share-btn" data-share-receipt="' +
      id + '">Share PNG</button></article>"
    );
  }

  function renderApptRow(a, actionHtml) {
    return (
      '<div class="list-item glass session-appt-row">' +
      '<div class="list-item-body">' +
      "<strong>" + escapeHtml(a.client_name) + "</strong>" +
      '<div class="sub">' + escapeHtml(a.date) + " · " + escapeHtml(a.start_time || "—") + "</div>" +
      '<div class="sub">' + escapeHtml(a.service_style || "—") +
      (a.headcount_tier ? " · " + escapeHtml(a.headcount_tier) : "") + "</div>" +
      "</div>" +
      '<div class="list-item-actions">' + actionHtml + "</div></div>"
    );
  }

  function render() {
    var state = getState();
    var html = "";

    if (state.phase === "receipt" && state.receipts && state.receipts.length) {
      html += '<p class="info-lead">Session complete · ' + state.faces.length +
        " face(s) · " + state.durationMinutes + " min</p>";
      state.receipts.forEach(function (r, i) {
        r.cfg = r.cfg || state.cfg || {};
        html += renderReceiptCard(r, i);
      });
      html += '<button type="button" class="btn btn-accent session-new-btn" style="margin-top:0.75rem">Start new session</button>';
      root.innerHTML = html;
      bindActions();
      return;
    }

    if (state.running && state.startedAt) {
      html += '<div class="session-stopwatch glass">' + fmtElapsed(Date.now() - state.startedAt) + "</div>";
    }

    if (state.phase === "pick") {
      html += '<p class="info-lead">Pick the booking for this session (confirm inquiries first).</p>';
      if (!upcoming.length) {
        html += '<p class="empty-state">No upcoming bookings.<br><a href="' +
          (root.getAttribute("data-add-url") || "#") + '">Add a booking first →</a></p>';
      } else {
        upcoming.forEach(function (a) {
          if ((a.status || "") === "cancelled") return;
          if ((a.status || "") === "inquiry") {
            html += renderApptRow(
              a,
              '<span class="status-pill upcoming">Inquiry</span>' +
              '<a class="btn-edit" href="' + (root.getAttribute("data-bookings-url") || "") + '?tab=edit&id=' + a.id + '">Confirm</a>'
            );
            return;
          }
          html += renderApptRow(
            a,
            '<button type="button" class="btn btn-primary btn-sm session-start-btn" data-id="' + a.id + '">Start session</button>'
          );
        });
      }
    }

    if (state.phase === "running" && state.hostApptId) {
      var host = apptById(state.hostApptId);
      if (host) {
        html += '<div class="session-current glass">';
        html += "<h3>Session for</h3>";
        html += "<strong>" + escapeHtml(host.client_name) + "</strong>";
        html += '<p class="sub">' + escapeHtml(host.date) + " · " + escapeHtml(host.start_time || "—") + "</p>";
        html += "</div>";
      }

      var groups = groupFaces(state.faces);
      if (groups.length) {
        html += '<div class="session-summary glass">';
        html += "<h3>Faces done (" + state.faces.length + ")</h3>";
        html += '<div class="session-summary-chips">';
        groups.forEach(function (g) {
          html += '<span class="session-done-chip">' + g.count + "× " + escapeHtml(g.label.split("(")[0].trim()) + "</span>";
        });
        html += "</div>";
        html += '<p class="session-running-total">Glam subtotal: <strong>' + fmtMoney(facesTotal(state.faces)) + "</strong></p>";
        html += "</div>";

        html += '<div class="session-face-list">';
        state.faces.forEach(function (f) {
          html +=
            '<div class="session-face-row">' +
            '<span class="session-face-icon" aria-hidden="true"></span>' +
            '<div class="session-face-info">' +
            "<strong>" + escapeHtml(f.name || "Face") + "</strong>" +
            '<div class="sub">' + escapeHtml(f.label) + " · " + fmtMoney(f.price) + "</div>" +
            "</div>" +
            '<button type="button" class="btn-delete-inline session-remove-face" data-face-id="' +
            escapeHtml(f.id) + '">Remove</button></div>';
        });
        html += "</div>";
      } else {
        html += '<p class="info-lead">Timer is running — add each face as you finish their glam.</p>';
      }

      html += '<div class="session-add-face glass">';
      html += "<h3>Add a face</h3>";
      html += '<label class="session-label">Name <span class="label-hint">(optional)</span></label>';
      html += '<input type="text" id="session-face-name" class="session-input" placeholder="e.g. bridesmaid, guest 1…">';
      html += '<label class="session-label">Glam package</label>';
      html += renderSessionGlamPicker(defaultPackageId(host));
      html += '<button type="button" class="btn btn-primary session-add-face-btn" style="margin-top:0.65rem">Add face</button>';
      html += "</div>";

      html += '<button type="button" class="btn btn-accent session-finish-btn" style="margin-top:0.75rem"' +
        (state.faces.length ? "" : " disabled") + ">Finish session &amp; receipt</button>";
      if (!state.faces.length) {
        html += '<p class="session-hint">Add at least one face before finishing.</p>';
      }
    }

    root.innerHTML = html;
    bindActions();
  }

  function bindActions() {
    root.querySelectorAll(".session-start-btn").forEach(function (btn) {
      btn.addEventListener("click", function () {
        var id = parseInt(btn.getAttribute("data-id"), 10);
        var startUrl =
          (document.body.getAttribute("data-static-base") || "") +
          "/bookings/" + id + "/session/start";
        fetch(startUrl, { method: "POST" })
          .then(function (r) { if (!r.ok) throw new Error("fail"); return r.json(); })
          .then(function () {
            saveState({
              running: true,
              startedAt: Date.now(),
              hostApptId: id,
              faces: [],
              phase: "running",
              receipts: [],
              durationMinutes: 0,
              cfg: null,
            });
            render();
          })
          .catch(function () {
            alert("Could not start the session. Try again.");
          });
      });
    });

    root.querySelectorAll("#session-glam-picker .glam-card").forEach(function (card) {
      card.addEventListener("click", function () {
        root.querySelectorAll("#session-glam-picker .glam-card").forEach(function (c) {
          c.classList.remove("selected");
        });
        card.classList.add("selected");
        var hid = document.getElementById("session-package-id");
        if (hid) hid.value = card.getAttribute("data-id");
      });
    });

    var addBtn = root.querySelector(".session-add-face-btn");
    if (addBtn) {
      addBtn.addEventListener("click", function () {
        var state = getState();
        var nameEl = document.getElementById("session-face-name");
        var pkgIdEl = document.getElementById("session-package-id");
        var pkgId = pkgIdEl ? pkgIdEl.value : "";
        var pkg = pkgById(pkgId);
        if (!pkg) return;
        faceCounter += 1;
        state.faces.push({
          id: "face-" + Date.now() + "-" + faceCounter,
          name: (nameEl && nameEl.value.trim()) || "",
          package_id: pkg.id,
          label: pkg.label,
          price: pkg.price,
          style: pkg.style,
          tier: pkg.tier,
        });
        saveState(state);
        render();
      });
    }

    root.querySelectorAll(".session-remove-face").forEach(function (btn) {
      btn.addEventListener("click", function () {
        var faceId = btn.getAttribute("data-face-id");
        var state = getState();
        state.faces = state.faces.filter(function (f) {
          return f.id !== faceId;
        });
        saveState(state);
        render();
      });
    });

    var finishBtn = root.querySelector(".session-finish-btn");
    if (finishBtn) {
      finishBtn.addEventListener("click", finishSession);
    }

    var newBtn = root.querySelector(".session-new-btn");
    if (newBtn) {
      newBtn.addEventListener("click", function () {
        clearState();
        render();
      });
    }
  }

  function finishSession() {
    var state = getState();
    if (!state.hostApptId || !state.faces.length) {
      alert("Add at least one face before finishing.");
      return;
    }

    var finishBtn = root.querySelector(".session-finish-btn");
    if (finishBtn) {
      finishBtn.disabled = true;
      finishBtn.textContent = "Finishing…";
    }

    var finishedAt = new Date().toISOString();
    var startedAt = state.startedAt ? new Date(state.startedAt).toISOString() : finishedAt;
    var durationMinutes = state.startedAt
      ? Math.round((Date.now() - state.startedAt) / 60000)
      : 0;

    var payload = {
      appointment_id: state.hostApptId,
      faces: state.faces.map(function (f) {
        return { package_id: f.package_id, name: f.name || "" };
      }),
      started_at: startedAt,
      finished_at: finishedAt,
      duration_minutes: durationMinutes,
    };

    fetch(completeUrl, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(payload),
    })
      .then(function (r) {
        if (!r.ok) throw new Error("Failed");
        return r.json();
      })
      .then(function (data) {
        var receipts = (data.receipts || []).map(function (r) {
          r.cfg = data.cfg;
          return r;
        });
        saveState({
          running: false,
          startedAt: null,
          hostApptId: state.hostApptId,
          faces: state.faces,
          phase: "receipt",
          receipts: receipts,
          cfg: data.cfg,
          durationMinutes: data.duration_minutes || durationMinutes,
        });
        if (tickTimer) clearInterval(tickTimer);
        tickTimer = null;
        render();
      })
      .catch(function () {
        alert("Could not complete session. Try again.");
        if (finishBtn) {
          finishBtn.disabled = false;
          finishBtn.textContent = "Finish session & receipt";
        }
      });
  }

  function tick() {
    var state = getState();
    if (state.running && state.startedAt && state.phase === "running") {
      var sw = root.querySelector(".session-stopwatch");
      if (sw) sw.textContent = fmtElapsed(Date.now() - state.startedAt);
    }
  }

  render();
  tickTimer = setInterval(tick, 1000);
})();
