(function () {
  var STORAGE_KEY = "vt-docs-theme";
  var lightSheet = document.getElementById("gh-markdown-light");
  var darkSheet = document.getElementById("gh-markdown-dark");
  var html = document.documentElement;

  function resolvedDark(theme) {
    if (theme === "dark") return true;
    if (theme === "light") return false;
    return window.matchMedia("(prefers-color-scheme: dark)").matches;
  }

  function applyTheme(theme) {
    html.dataset.theme = theme;
    if (darkSheet) darkSheet.disabled = !resolvedDark(theme);
    localStorage.setItem(STORAGE_KEY, theme);
    var btn = document.getElementById("theme-toggle");
    if (btn) {
      btn.textContent = resolvedDark(theme) ? "☀" : "◐";
      btn.title = theme === "auto" ? "Theme: auto (click for light)" :
        theme === "light" ? "Theme: light (click for dark)" :
        "Theme: dark (click for auto)";
    }
  }

  function cycleTheme() {
    var current = localStorage.getItem(STORAGE_KEY) || "auto";
    var next = current === "auto" ? "light" : current === "light" ? "dark" : "auto";
    applyTheme(next);
  }

  var toggle = document.getElementById("theme-toggle");
  if (toggle) {
    applyTheme(localStorage.getItem(STORAGE_KEY) || "auto");
    toggle.addEventListener("click", cycleTheme);
  }

  window.matchMedia("(prefers-color-scheme: dark)").addEventListener("change", function () {
    if ((localStorage.getItem(STORAGE_KEY) || "auto") === "auto") {
      applyTheme("auto");
    }
  });

  var input = document.getElementById("nav-filter");
  if (input) {
    input.addEventListener("input", function () {
      var q = input.value.trim().toLowerCase();
      document.querySelectorAll(".nav-file").forEach(function (li) {
        var text = li.textContent.toLowerCase();
        li.classList.toggle("hidden", q.length > 0 && !text.includes(q));
      });
      document.querySelectorAll(".nav-dir, .nav-section").forEach(function (li) {
        var visible = li.querySelectorAll(".nav-file:not(.hidden)").length;
        li.classList.toggle("hidden", q.length > 0 && visible === 0);
      });
    });
  }

  var SIDEBAR_WIDTH_KEY = "vt-docs-sidebar-width";
  var SIDEBAR_MIN = 200;
  var SIDEBAR_MAX = 560;
  var desktopQuery = window.matchMedia("(min-width: 901px)");
  var splitter = document.getElementById("sidebar-splitter");
  var savedWidth = parseInt(localStorage.getItem(SIDEBAR_WIDTH_KEY), 10);

  function sidebarEnabled() {
    return desktopQuery.matches;
  }

  function setSidebarWidth(px) {
    var width = Math.min(SIDEBAR_MAX, Math.max(SIDEBAR_MIN, px));
    html.style.setProperty("--sidebar-width", width + "px");
    return width;
  }

  function resetSidebarWidth() {
    html.style.removeProperty("--sidebar-width");
    localStorage.removeItem(SIDEBAR_WIDTH_KEY);
  }

  if (splitter && savedWidth >= SIDEBAR_MIN && savedWidth <= SIDEBAR_MAX) {
    setSidebarWidth(savedWidth);
  }

  if (splitter) {
    var dragging = false;

    function onPointerMove(e) {
      if (!dragging) return;
      setSidebarWidth(e.clientX);
    }

    function stopDrag() {
      if (!dragging) return;
      dragging = false;
      splitter.classList.remove("resizing");
      document.body.classList.remove("sidebar-resizing");
      document.removeEventListener("pointermove", onPointerMove);
      document.removeEventListener("pointerup", stopDrag);
      document.removeEventListener("pointercancel", stopDrag);
      var current = parseInt(getComputedStyle(html).getPropertyValue("--sidebar-width"), 10);
      if (!isNaN(current)) {
        localStorage.setItem(SIDEBAR_WIDTH_KEY, String(current));
      }
    }

    splitter.addEventListener("pointerdown", function (e) {
      if (!sidebarEnabled() || e.button !== 0) return;
      e.preventDefault();
      dragging = true;
      splitter.classList.add("resizing");
      document.body.classList.add("sidebar-resizing");
      document.addEventListener("pointermove", onPointerMove);
      document.addEventListener("pointerup", stopDrag);
      document.addEventListener("pointercancel", stopDrag);
    });

    splitter.addEventListener("keydown", function (e) {
      if (!sidebarEnabled()) return;
      var step = e.shiftKey ? 40 : 16;
      var current = parseInt(getComputedStyle(html).getPropertyValue("--sidebar-width"), 10) || 280;
      if (e.key === "ArrowLeft") {
        e.preventDefault();
        localStorage.setItem(SIDEBAR_WIDTH_KEY, String(setSidebarWidth(current - step)));
      } else if (e.key === "ArrowRight") {
        e.preventDefault();
        localStorage.setItem(SIDEBAR_WIDTH_KEY, String(setSidebarWidth(current + step)));
      } else if (e.key === "Home") {
        e.preventDefault();
        resetSidebarWidth();
      }
    });

    splitter.addEventListener("dblclick", function () {
      if (!sidebarEnabled()) return;
      resetSidebarWidth();
    });
  }

  function scrollToHash(hash, behavior) {
    if (!hash || hash === "#") return;
    var id = decodeURIComponent(hash.slice(1));
    var target = document.getElementById(id);
    if (!target) return;
    target.scrollIntoView({ behavior: behavior || "smooth", block: "start" });
  }

  if (location.hash) {
    requestAnimationFrame(function () {
      scrollToHash(location.hash, "instant");
    });
  }

  window.addEventListener("hashchange", function () {
    scrollToHash(location.hash, "smooth");
  });

  var markdownBody = document.querySelector(".markdown-body");
  if (markdownBody) {
    markdownBody.addEventListener("click", function (e) {
      var link = e.target.closest('a[href^="#"]');
      if (!link || link.getAttribute("href") === "#") return;
      var id = decodeURIComponent(link.getAttribute("href").slice(1));
      if (document.getElementById(id)) {
        e.preventDefault();
        history.pushState(null, "", link.getAttribute("href"));
        scrollToHash(link.getAttribute("href"), "smooth");
      }
    });
  }
})();
