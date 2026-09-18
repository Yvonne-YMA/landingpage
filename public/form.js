// Progressive enhancement for the StaticForms pages (Widerruf / Kündigung):
// submit via AJAX and show a branded success panel instead of the provider page.
(function () {
  var form = document.querySelector("form.sf-form");
  if (!form || !window.fetch) return;

  form.addEventListener("submit", function (e) {
    e.preventDefault();
    var btn = form.querySelector(".sf-submit");
    var label = btn ? btn.textContent : "";
    if (btn) { btn.disabled = true; btn.textContent = "Wird gesendet …"; }
    clearError();

    var data = {};
    new FormData(form).forEach(function (value, key) { data[key] = value; });

    fetch(form.action, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(data)
    })
      .then(function (res) {
        if (!res.ok) throw new Error("status " + res.status);
        showSuccess();
      })
      .catch(function () {
        if (btn) { btn.disabled = false; btn.textContent = label; }
        showError();
      });
  });

  function showSuccess() {
    var wrap = document.querySelector(".legal__wrap");
    if (!wrap) return;
    var back = wrap.querySelector(".legal__back");
    var html = back ? back.outerHTML : '<a class="legal__back" href="index.html">&larr; Zur Startseite</a>';
    html +=
      '<h1 class="legal__title">Danke &#9752;</h1>' +
      "<p>Deine Nachricht ist bei mir angekommen. Ich melde mich zeitnah bei Dir &#8211; " +
      "eine Bestätigung erhältst Du zudem per E-Mail.</p>" +
      '<p class="sf-home-wrap"><a class="sf-submit" href="index.html">Zurück zur Startseite</a></p>';
    wrap.innerHTML = html;
    window.scrollTo(0, 0);
  }

  function showError() {
    clearError();
    var p = document.createElement("p");
    p.className = "sf-error";
    p.textContent =
      "Das hat leider nicht geklappt. Bitte versuche es erneut oder schreibe mir direkt an yvonne@yma.one.";
    form.appendChild(p);
  }

  function clearError() {
    var e = form.querySelector(".sf-error");
    if (e) e.parentNode.removeChild(e);
  }
})();
