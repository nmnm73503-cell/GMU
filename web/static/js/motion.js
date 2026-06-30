(function () {
  'use strict';

  var reduced = window.matchMedia('(prefers-reduced-motion: reduce)').matches;
  var STAGGER_SELECTORS = ['.motion-stagger', '.stat-grid', '.hub-grid'];

  function ready(fn) {
    if (document.readyState === 'loading') {
      document.addEventListener('DOMContentLoaded', fn);
    } else {
      fn();
    }
  }

  function isInViewport(el) {
    var rect = el.getBoundingClientRect();
    return rect.top < window.innerHeight * 0.96 && rect.bottom > 0;
  }

  function markVisible(items) {
    items.forEach(function (item, i) {
      item.style.setProperty('--motion-delay', (i * 55) + 'ms');
      item.classList.add('is-visible');
    });
  }

  function initStagger() {
    var containers = [];
    STAGGER_SELECTORS.forEach(function (sel) {
      document.querySelectorAll(sel).forEach(function (el) {
        if (containers.indexOf(el) === -1) containers.push(el);
      });
    });

    containers.forEach(function (container) {
      var children = Array.prototype.filter.call(container.children, function (child) {
        return child.nodeType === 1 && !child.classList.contains('motion-ignore');
      });
      children.forEach(function (child) {
        child.classList.add('motion-item');
      });

      var observer = new IntersectionObserver(function (entries) {
        entries.forEach(function (entry) {
          if (!entry.isIntersecting) return;
          var items = entry.target.querySelectorAll('.motion-item:not(.is-visible)');
          markVisible(Array.prototype.slice.call(items));
          observer.unobserve(entry.target);
        });
      }, { threshold: 0.08, rootMargin: '0px 0px -4% 0px' });

      if (reduced || isInViewport(container)) {
        markVisible(children);
        return;
      }

      observer.observe(container);
    });
  }

  function initSections() {
    var sections = document.querySelectorAll('.motion-section');
    if (!sections.length) return;

    if (reduced) {
      sections.forEach(function (section) {
        section.classList.add('is-visible');
        markVisible(Array.prototype.slice.call(section.querySelectorAll('.list-item')));
      });
      return;
    }

    var observer = new IntersectionObserver(function (entries) {
      entries.forEach(function (entry) {
        if (!entry.isIntersecting) return;
        var section = entry.target;
        section.classList.add('is-visible');
        var items = section.querySelectorAll('.list-item');
        items.forEach(function (item, i) {
          item.classList.add('motion-item');
          item.style.setProperty('--motion-delay', (i * 50) + 'ms');
        });
        requestAnimationFrame(function () {
          markVisible(Array.prototype.slice.call(items));
        });
        observer.unobserve(section);
      });
    }, { threshold: 0.05, rootMargin: '0px 0px -3% 0px' });

    sections.forEach(function (section) {
      if (isInViewport(section)) {
        section.classList.add('is-visible');
        var items = section.querySelectorAll('.list-item');
        items.forEach(function (item) { item.classList.add('motion-item'); });
        markVisible(Array.prototype.slice.call(items));
        return;
      }
      observer.observe(section);
    });
  }

  function initFadeElements() {
    var els = document.querySelectorAll('.motion-fade');
    if (!els.length) return;

    if (reduced) {
      els.forEach(function (el) { el.classList.add('is-visible'); });
      return;
    }

    var observer = new IntersectionObserver(function (entries) {
      entries.forEach(function (entry) {
        if (!entry.isIntersecting) return;
        entry.target.classList.add('is-visible');
        observer.unobserve(entry.target);
      });
    }, { threshold: 0.12 });

    els.forEach(function (el) {
      if (isInViewport(el)) {
        el.classList.add('is-visible');
        return;
      }
      observer.observe(el);
    });
  }

  function initPageTransitions() {
    if (reduced) return;

    document.addEventListener('click', function (e) {
      if (e.defaultPrevented || e.button !== 0) return;
      if (e.metaKey || e.ctrlKey || e.shiftKey || e.altKey) return;

      var link = e.target.closest('a[href]');
      if (!link || link.target === '_blank' || link.hasAttribute('download')) return;
      if (link.dataset.noTransition !== undefined) return;

      var href = link.getAttribute('href');
      if (!href || href.charAt(0) === '#' || href.indexOf('javascript:') === 0) return;

      var url;
      try {
        url = new URL(link.href, window.location.origin);
      } catch (err) {
        return;
      }
      if (url.origin !== window.location.origin) return;

      e.preventDefault();
      document.body.classList.remove('page-enter');
      document.body.classList.add('page-exit');
      window.setTimeout(function () {
        window.location.href = link.href;
      }, 180);
    });
  }

  function initRipple() {
    if (reduced) return;

    document.addEventListener('click', function (e) {
      var btn = e.target.closest('.btn, .fab, .theme-toggle-btn, nav.bottom-nav a.nav-item');
      if (!btn || btn.disabled) return;

      var rect = btn.getBoundingClientRect();
      var ripple = document.createElement('span');
      ripple.className = 'ripple';
      var size = Math.max(rect.width, rect.height) * 2.2;
      ripple.style.width = ripple.style.height = size + 'px';
      ripple.style.left = (e.clientX - rect.left - size / 2) + 'px';
      ripple.style.top = (e.clientY - rect.top - size / 2) + 'px';
      btn.appendChild(ripple);
      ripple.addEventListener('animationend', function () {
        ripple.remove();
      });
    });
  }

  ready(function () {
    initStagger();
    initSections();
    initFadeElements();
    initPageTransitions();
    initRipple();
    window.setTimeout(function () {
      document.body.classList.remove('page-enter');
    }, 600);
  });
})();
