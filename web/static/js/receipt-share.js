(function () {
  function basePath() {
    var b = document.body.getAttribute("data-static-base") || "";
    return b.replace(/\/$/, "");
  }

  function loadHtml2Canvas() {
    if (window.html2canvas) return Promise.resolve(window.html2canvas);
    return new Promise(function (resolve, reject) {
      var s = document.createElement("script");
      s.src = basePath() + "/static/js/html2canvas.min.js?v=1";
      s.onload = function () { resolve(window.html2canvas); };
      s.onerror = reject;
      document.head.appendChild(s);
    });
  }

  function captureReceipt(el) {
    return loadHtml2Canvas().then(function (h2c) {
      return h2c(el, {
        backgroundColor: "#ffffff",
        scale: 2,
        useCORS: true,
        logging: false,
      });
    });
  }

  function canvasToBlob(canvas) {
    return new Promise(function (resolve) {
      canvas.toBlob(function (blob) { resolve(blob); }, "image/png");
    });
  }

  function downloadBlob(blob, filename) {
    var url = URL.createObjectURL(blob);
    var a = document.createElement("a");
    a.href = url;
    a.download = filename;
    a.click();
    URL.revokeObjectURL(url);
  }

  window.shareReceiptPng = function (targetEl, filename) {
    var el = typeof targetEl === "string" ? document.getElementById(targetEl) : targetEl;
    if (!el) return Promise.reject(new Error("Receipt not found"));
    var name = filename || ("receipt-" + (el.getAttribute("data-receipt-no") || "gmu") + ".png");

    return captureReceipt(el).then(function (canvas) {
      return canvasToBlob(canvas).then(function (blob) {
        if (!blob) throw new Error("Could not create image");
        var file = new File([blob], name, { type: "image/png" });
        if (navigator.canShare && navigator.canShare({ files: [file] })) {
          return navigator.share({ files: [file], title: "Receipt" });
        }
        downloadBlob(blob, name);
      });
    });
  };

  document.addEventListener("click", function (e) {
    var btn = e.target.closest("[data-share-receipt]");
    if (!btn) return;
    e.preventDefault();
    var targetId = btn.getAttribute("data-share-receipt");
    var card = document.getElementById(targetId);
    btn.disabled = true;
    var label = btn.textContent;
    btn.textContent = "Sharing…";
    window.shareReceiptPng(card).catch(function () {
      if (card) downloadBlob && window.shareReceiptPng(card);
    }).finally(function () {
      btn.disabled = false;
      btn.textContent = label;
    });
  });
})();
