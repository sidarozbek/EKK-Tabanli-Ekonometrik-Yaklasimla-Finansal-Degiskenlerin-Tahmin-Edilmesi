//NOTE
$(document).on('click', '.nav-oge', function (e) {
  e.preventDefault();
  Shiny.setInputValue('nav', {
    sayfa: $(this).data('sayfa'),
    gosterge: $(this).data('gosterge') || null,
    n: Date.now()
  });
});

$(document).on('shiny:connected', function () {
  $('.nav-oge[data-sayfa="makro"]').first().addClass('aktif');
  Shiny.addCustomMessageHandler('aktif_sayfa', function (m) {
    $('.nav-oge').removeClass('aktif');
    var sec = m.gosterge
      ? '.nav-oge[data-gosterge="' + m.gosterge + '"]'
      : '.nav-oge[data-sayfa="' + m.sayfa + '"]:not([data-gosterge])';
    $(sec).first().addClass('aktif');
    window.scrollTo({ top: 0, behavior: 'smooth' });
    // Gizli sekmedeki plotly grafiklerinin boyutunu düzelt
    setTimeout(function () { window.dispatchEvent(new Event('resize')); }, 80);
  });
});

$(document).on('click', '[data-kopyala]', function () {
  var btn = this, metin = document.getElementById($(this).data('kopyala')).innerText;
  navigator.clipboard.writeText(metin).then(function () {
    var eski = btn.innerHTML;
    btn.innerHTML = '<span class="material-symbols-outlined" style="font-size:16px">check</span>Kopyalandı';
    setTimeout(function () { btn.innerHTML = eski; }, 1500);
  });
});
