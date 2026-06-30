(function () {
  var carousels = document.querySelectorAll("[data-package-carousel]");
  if (!carousels.length) return;

  carousels.forEach(function (root) {
    var slides = root.querySelectorAll(".carousel-slide");
    if (slides.length < 2) return;
    var idx = 0;
    var dots = root.querySelectorAll(".carousel-dot");
    var interval = 3000;

    function show(i) {
      idx = (i + slides.length) % slides.length;
      slides.forEach(function (s, n) {
        s.classList.toggle("active", n === idx);
      });
      dots.forEach(function (d, n) {
        d.classList.toggle("active", n === idx);
      });
    }

    dots.forEach(function (dot, n) {
      dot.addEventListener("click", function () {
        show(n);
        resetTimer();
      });
    });

    var touchStartX = 0;
    root.addEventListener("touchstart", function (e) {
      touchStartX = e.changedTouches[0].screenX;
    }, { passive: true });
    root.addEventListener("touchend", function (e) {
      var dx = e.changedTouches[0].screenX - touchStartX;
      if (Math.abs(dx) > 40) show(idx + (dx < 0 ? 1 : -1));
      resetTimer();
    }, { passive: true });

    var timer;
    function resetTimer() {
      clearInterval(timer);
      timer = setInterval(function () { show(idx + 1); }, interval);
    }
    show(0);
    resetTimer();
  });

  // No booking CTA in menu (personal-use reference).
})();
