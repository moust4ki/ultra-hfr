// Ultra HFR — lecture d'un sujet dans la vue web.
// Le natif appelle window.reader.* ; la page lui répond par webkit.messageHandlers.reader.

(() => {
  "use strict";

  const send = (message) => window.webkit?.messageHandlers?.reader?.postMessage(message);
  const thread = () => document.getElementById("thread");

  // MARK: Pages

  let nearEndSent = false;
  let nearStartSent = false;
  let postsCache = null;
  /** « Sujet suivant » shown in the end card: { title, detail } or null. */
  let nextTopic = null;

  function renderNextTopic() {
    for (const old of document.querySelectorAll(".topic-next")) old.remove();
    const end = document.querySelector(".topic-end");
    if (!end || !nextTopic) return;
    const link = document.createElement("button");
    link.className = "topic-next";
    const eyebrow = document.createElement("span");
    eyebrow.className = "topic-next-eyebrow";
    eyebrow.textContent = "Sujet suivant";
    const title = document.createElement("span");
    title.className = "topic-next-title";
    title.textContent = nextTopic.title;
    const detail = document.createElement("span");
    detail.className = "topic-next-detail";
    detail.textContent = nextTopic.detail;
    link.append(eyebrow, title, detail);
    end.append(link);
  }

  function changed() {
    postsCache = null;
    renderNextTopic();
    scheduleLayoutReport();
    onScroll();
  }

  window.reader = {
    /** Replaces everything (opening a topic, jumping to a page). */
    replace(html, anchorPost) {
      thread().innerHTML = html;
      nearEndSent = false;
      nearStartSent = false;
      changed();
      if (!anchorPost || !reader.scrollToPost(anchorPost)) {
        window.scrollTo(0, 0);
        captureAnchor();
      }
      // Fresh content: allow loading the previous page once the reader moves.
      requestAnimationFrame(() => { nearStartSent = false; });
    },

    append(html) {
      // The topic grew: the end card moves to the new end.
      for (const end of document.querySelectorAll(".topic-end, .page-loading")) end.remove();
      thread().insertAdjacentHTML("beforeend", html);
      nearEndSent = false;
      changed();
    },

    /** Inserts a page above the current one without moving what the reader sees. */
    prepend(html) {
      const anchor = visibleElement();
      const anchorTop = anchor ? anchor.getBoundingClientRect().top : 0;
      thread().insertAdjacentHTML("afterbegin", html);
      postsCache = null;
      if (anchor) {
        window.scrollBy(0, anchor.getBoundingClientRect().top - anchorTop);
      }
      nearStartSent = false;
      changed();
    },

    scrollToPost(id) {
      const element = document.getElementById("t" + id);
      if (!element) return false;
      const top = element.getBoundingClientRect().top + window.scrollY - topInset();
      window.scrollTo(0, Math.max(0, top));
      anchor = { element, top: element.getBoundingClientRect().top };
      return true;
    },

    setQuoted(ids) {
      const quoted = new Set(ids.map(String));
      for (const post of document.querySelectorAll(".post[data-post]")) {
        post.classList.toggle("quoted", quoted.has(post.dataset.post));
      }
    },

    /** Marks the message found by a search and the searched words in it; `id` 0 clears. */
    highlight(id, words) {
      for (const post of document.querySelectorAll(".post.search-hit")) post.classList.remove("search-hit");
      for (const mark of document.querySelectorAll("mark[data-search]")) {
        const parent = mark.parentNode;
        mark.replaceWith(document.createTextNode(mark.textContent));
        parent.normalize();
      }
      const post = id ? document.getElementById("t" + id) : null;
      if (!post) return;
      post.classList.add("search-hit");
      const terms = words.split(/\s+/).filter((word) => word.length >= 2)
        .map((word) => word.replace(/[.*+?^${}()|[\]\\]/g, "\\$&"));
      const body = post.querySelector(".post-body");
      if (terms.length && body) markTerms(body, new RegExp(terms.join("|"), "giu"));
      reader.scrollToPost(id);
    },

    /** Next (1) or previous (-1) message, from the one at the top of the screen. */
    step(offset) {
      const list = posts();
      const current = visiblePost();
      let index = current ? list.indexOf(current) : -1;
      // A message partly scrolled past: "previous" goes back to its top first.
      if (offset < 0 && current && current.getBoundingClientRect().top < topInset() - 4) index += 1;
      const target = list[Math.min(Math.max(index + offset, 0), list.length - 1)];
      if (target) reader.scrollToPost(Number(target.dataset.post));
    },

    /** Removes the pages before `page`, keeping what the reader sees in place. */
    trimPagesBefore(page) {
      const anchorElement = visibleElement();
      const anchorTop = anchorElement ? anchorElement.getBoundingClientRect().top : 0;
      for (const section of thread().querySelectorAll(".topic-page")) {
        if (Number(section.dataset.page) < page) section.remove();
      }
      postsCache = null;
      if (anchorElement && anchorElement.isConnected) {
        isAdjusting = true;
        window.scrollBy(0, anchorElement.getBoundingClientRect().top - anchorTop);
        isAdjusting = false;
      }
      nearStartSent = false;
      changed();
    },

    /** Removes the pages after `page` (the reader went back up). */
    trimPagesAfter(page) {
      for (const section of thread().querySelectorAll(".topic-page")) {
        if (Number(section.dataset.page) > page) section.remove();
      }
      for (const loading of document.querySelectorAll(".page-loading")) loading.remove();
      nearEndSent = false;
      changed();
    },

    /** The next topic to read, or null; shown at the end of the topic. */
    setNextTopic(topic) {
      nextTopic = topic;
      renderNextTopic();
    },

    /** Page `page` is on its way: a divider and skeletons at the bottom of the thread. */
    showLoading(page, label) {
      for (const old of document.querySelectorAll(".page-loading")) old.remove();
      const html = '<div class="page-loading" aria-live="polite">'
        + '<div class="page-divider"><span class="page"></span><span class="date">chargement…</span></div>'
        + '<div class="skeleton"><i></i><i></i><i class="short"></i></div>'
        + '<div class="skeleton"><i></i><i class="short"></i></div></div>';
      thread().insertAdjacentHTML("beforeend", html);
      thread().lastElementChild.querySelector(".page").textContent = label;
      scheduleLayoutReport();
    },

    /** Page `page` could not be loaded: a card to try again, where the page should be. */
    showLoadFailed(message) {
      const loading = document.querySelector(".page-loading");
      if (!loading) return;
      loading.innerHTML = '<div class="page-failed"><span class="page-failed-text"></span>'
        + '<button class="page-retry">Réessayer</button></div>';
      loading.querySelector(".page-failed-text").textContent = message;
    },

    /** Nothing new after a check: the end card says so. */
    endChecked(message) {
      const end = document.querySelector(".topic-end");
      if (!end) return;
      end.classList.remove("checking");
      const button = end.querySelector(".topic-refresh");
      if (button) button.textContent = message;
    },

    setTopInset(value) {
      document.documentElement.style.setProperty("--top-inset", value + "px");
    },
  };

  function markTerms(root, pattern) {
    const walker = document.createTreeWalker(root, NodeFilter.SHOW_TEXT);
    const nodes = [];
    while (walker.nextNode()) nodes.push(walker.currentNode);
    for (const node of nodes) {
      const text = node.nodeValue;
      pattern.lastIndex = 0;
      if (!pattern.test(text)) continue;
      pattern.lastIndex = 0;
      const fragment = document.createDocumentFragment();
      let last = 0;
      for (const match of text.matchAll(pattern)) {
        fragment.append(text.slice(last, match.index));
        const mark = document.createElement("mark");
        mark.dataset.search = "";
        mark.textContent = match[0];
        fragment.append(mark);
        last = match.index + match[0].length;
      }
      fragment.append(text.slice(last));
      node.replaceWith(fragment);
    }
  }

  function topInset() {
    return parseFloat(getComputedStyle(document.documentElement).getPropertyValue("--top-inset")) || 0;
  }

  // MARK: Scroll: visible message, edges

  function posts() {
    if (!postsCache) postsCache = Array.from(document.querySelectorAll(".post[data-post]"));
    return postsCache;
  }

  /** First message whose bottom is below the top bar. */
  function visiblePost() {
    const list = posts();
    const limit = topInset() + 8;
    let low = 0;
    let high = list.length - 1;
    let found = null;
    while (low <= high) {
      const middle = (low + high) >> 1;
      const rect = list[middle].getBoundingClientRect();
      if (rect.bottom > limit) {
        found = list[middle];
        high = middle - 1;
      } else {
        low = middle + 1;
      }
    }
    return found;
  }

  /** First page divider or message below the top bar: the anchor kept still by prepend(). */
  function visibleElement() {
    const limit = topInset() + 8;
    for (const element of document.querySelectorAll(".page-divider, .post[data-post]")) {
      if (element.getBoundingClientRect().bottom > limit) return element;
    }
    return null;
  }

  /** Last message whose top went past the middle of the screen: read, or being read. */
  function lastSeenPost() {
    const list = posts();
    const limit = window.innerHeight * 0.6;
    let low = 0;
    let high = list.length - 1;
    let found = null;
    while (low <= high) {
      const middle = (low + high) >> 1;
      if (list[middle].getBoundingClientRect().top < limit) {
        found = list[middle];
        low = middle + 1;
      } else {
        high = middle - 1;
      }
    }
    return found;
  }

  let reported = null;
  let scrollScheduled = false;

  function onScroll() {
    if (scrollScheduled) return;
    scrollScheduled = true;
    requestAnimationFrame(() => {
      scrollScheduled = false;
      const viewport = window.innerHeight;
      const height = document.documentElement.scrollHeight;
      if (!nearEndSent && window.scrollY + viewport > height - viewport * 2) {
        nearEndSent = true;
        send({ type: "nearEnd" });
      }
      if (!nearStartSent && window.scrollY < viewport) {
        nearStartSent = true;
        send({ type: "nearStart" });
      }
      const post = visiblePost();
      const seen = lastSeenPost() || post;
      const key = post ? post.dataset.post + "/" + seen.dataset.post : null;
      if (key && key !== reported) {
        reported = key;
        send({
          type: "visible",
          post: Number(post.dataset.post), page: Number(post.dataset.page),
          seen: Number(seen.dataset.post), seenPage: Number(seen.dataset.page),
        });
      }
    });
  }

  window.addEventListener("scroll", onScroll, { passive: true });

  // MARK: Message menus: the native side places a real menu button over each "•••"

  let layoutTimer = null;

  function scheduleLayoutReport() {
    clearTimeout(layoutTimer);
    layoutTimer = setTimeout(reportLayout, 60);
  }

  function reportLayout() {
    const items = [];
    for (const button of document.querySelectorAll(".post-menu")) {
      const rect = button.getBoundingClientRect();
      if (rect.width === 0) continue;
      items.push({
        post: Number(button.dataset.post),
        x: rect.left + window.scrollX,
        y: rect.top + window.scrollY,
        width: rect.width,
        height: rect.height,
      });
    }
    send({ type: "menus", items });
  }

  // MARK: Scroll anchoring
  // WebKit does not keep the content still when something above the screen changes size
  // (images loading, a page added above). The first element on screen is remembered at each
  // scroll and put back in place when the layout changes.

  let anchor = null;
  let isAdjusting = false;

  function captureAnchor() {
    const element = visibleElement();
    anchor = element ? { element, top: element.getBoundingClientRect().top } : null;
  }

  function restoreAnchor() {
    if (!anchor || !anchor.element.isConnected) return;
    const delta = anchor.element.getBoundingClientRect().top - anchor.top;
    if (Math.abs(delta) > 1) {
      isAdjusting = true;
      window.scrollBy(0, delta);
      isAdjusting = false;
    }
  }

  window.addEventListener("scroll", () => {
    if (!isAdjusting) captureAnchor();
  }, { passive: true });

  new ResizeObserver(() => {
    restoreAnchor();
    scheduleLayoutReport();
  }).observe(document.body);
  document.addEventListener("load", (event) => {
    if (event.target.tagName === "IMG") scheduleLayoutReport();
  }, true);

  // Images whose host is gone (very common on old topics): a small frame with the address
  // instead of a broken image.
  document.addEventListener("error", (event) => {
    const image = event.target;
    if (image.tagName !== "IMG" || !image.classList.contains("image")) return;
    const frame = document.createElement("a");
    frame.className = "image-missing";
    frame.href = image.src;
    let host = "";
    try { host = new URL(image.src).hostname.replace(/^www\./, ""); } catch (_) {}
    frame.textContent = host ? "Image indisponible · " + host : "Image indisponible";
    image.replaceWith(frame);
    scheduleLayoutReport();
  }, true);

  // MARK: Taps

  document.addEventListener("click", (event) => {
    const spoiler = event.target.closest(".spoiler-block");
    if (spoiler && !spoiler.classList.contains("revealed")) {
      spoiler.classList.add("revealed");
      event.preventDefault();
      return;
    }
    const quoteLink = event.target.closest("a[data-quoted]");
    if (quoteLink) {
      event.preventDefault();
      const id = Number(quoteLink.dataset.quoted);
      if (!reader.scrollToPost(id)) {
        send({ type: "openQuotedPost", post: id, path: quoteLink.getAttribute("href") });
      }
      return;
    }
    if (event.target.closest(".topic-next")) {
      send({ type: "openNext" });
      return;
    }
    const retry = event.target.closest(".page-retry");
    if (retry) {
      send({ type: "retry" });
      return;
    }
    const refresh = event.target.closest(".topic-refresh");
    if (refresh) {
      refresh.closest(".topic-end")?.classList.add("checking");
      refresh.textContent = "Vérification…";
      send({ type: "refresh" });
      return;
    }
    const author = event.target.closest(".post-head .avatar, .post-head .pseudo");
    if (author) {
      const post = author.closest(".post[data-post]");
      if (post) send({ type: "openProfile", post: Number(post.dataset.post) });
      return;
    }
    const expand = event.target.closest(".quote-expand");
    if (expand) {
      expand.closest(".quote")?.classList.remove("collapsed");
      changed();
      return;
    }
    const video = event.target.closest(".video");
    if (video) {
      event.preventDefault();
      send({ type: "openLink", url: video.dataset.url });
      return;
    }
    const image = event.target.closest("img.image");
    if (image) {
      event.preventDefault();
      const siblings = Array.from(image.closest(".post-body")?.querySelectorAll("img.image") ?? [image]).map((img) => img.src);
      send({ type: "openImage", url: image.src, urls: siblings });
      return;
    }
    const link = event.target.closest("a[href]");
    if (link) {
      event.preventDefault();
      send({ type: "openLink", url: link.href });
    }
  });

  // MARK: Swipe to quote

  const threshold = 64;
  let swipe = null;

  document.addEventListener("touchstart", (event) => {
    const post = event.target.closest(".post[data-post]");
    if (!post || event.touches.length !== 1 || document.body.classList.contains("locked")) return;
    const touch = event.touches[0];
    swipe = { post, startX: touch.clientX, startY: touch.clientY, active: false, armed: false };
  }, { passive: true });

  document.addEventListener("touchmove", (event) => {
    if (!swipe) return;
    const touch = event.touches[0];
    const dx = touch.clientX - swipe.startX;
    const dy = touch.clientY - swipe.startY;
    if (!swipe.active) {
      if (Math.abs(dy) > 10 && Math.abs(dy) > Math.abs(dx)) {
        swipe = null;
        return;
      }
      if (dx > 12 && dx > Math.abs(dy) * 1.5) {
        swipe.active = true;
        swipe.post.classList.add("swiping");
      } else {
        return;
      }
    }
    event.preventDefault();
    const offset = Math.max(0, Math.min(dx - 12, threshold * 1.5));
    swipe.post.style.setProperty("--swipe", offset + "px");
    swipe.post.style.transform = `translateX(${offset}px)`;
    const armed = offset >= threshold;
    if (armed !== swipe.armed) {
      swipe.armed = armed;
      swipe.post.classList.toggle("armed", armed);
      if (armed) send({ type: "haptic" });
    }
  }, { passive: false });

  function endSwipe() {
    if (!swipe) return;
    const { post, active, armed } = swipe;
    swipe = null;
    if (!active) return;
    post.classList.remove("swiping", "armed");
    post.style.transform = "";
    post.style.removeProperty("--swipe");
    if (armed) send({ type: "toggleQuote", post: Number(post.dataset.post) });
  }

  document.addEventListener("touchend", endSwipe, { passive: true });
  document.addEventListener("touchcancel", endSwipe, { passive: true });

  send({ type: "ready" });
})();
