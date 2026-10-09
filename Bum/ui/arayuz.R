#NOTE
RENK <- list(
  primary = "#ffb689", secondary = "#cfbdff", tertiary = "#7dd8b4", error = "#FF6B72",
  outline = "#8B829A", metin = "#e5e0ec", metin2 = "#C4BDCF",
  kap = "#1D1A27", kap_yuksek = "#2a2932", yuzey = "#111018"
)

FREKANS_AD <- c(aylik = "Aylık (M)", ceyreklik = "Çeyreklik (Q)", yillik = "Yıllık (A)")
DURUM_AD <- c(api = "Canlı API", cache = "Önbellek", csv_yedek = "CSV Yedek",
              bayat_cache = "Bayat Önbellek", alinamadi = "Alınamadı")
DURUM_TUR <- c(api = "basari", cache = "secondary", csv_yedek = "primary",
               bayat_cache = "hata", alinamadi = "hata")

ikon <- function(ad, boyut = 18, class = NULL) {
  tags$span(class = paste("material-symbols-outlined", class),
            style = sprintf("font-size:%dpx", boyut), ad)
}

etiket <- function(..., class = NULL) tags$span(class = paste("label-caps", class), ...)
rozet <- function(..., tur = "notr") tags$span(class = paste("rozet", tur), ...)
kart <- function(..., class = NULL) div(class = paste("kart", class), ...)

kart_baslik <- function(ikon_ad, baslik, alt = NULL, sag = NULL) {
  div(class = "kart-baslik",
      div(class = "d-flex align-items-center gap-2",
          ikon(ikon_ad, 20, "text-primary-c"),
          div(if (!is.null(alt)) etiket(alt), tags$h3(baslik))),
      sag)
}

stat_kutu <- function(etiket_metin, deger, alt = NULL, renk = "metin") {
  div(class = "stat-kutu",
      etiket(etiket_metin),
      div(class = paste("stat-deger", paste0("c-", renk)), deger),
      if (!is.null(alt)) div(class = "stat-alt", alt))
}

bilgi_satir <- function(a, b) div(class = "bilgi-satir", span(a), tags$b(b))

nav_oge <- function(sayfa, ikon_ad, metin, gosterge = NULL, sag = NULL) {
  tags$a(href = "#", class = "nav-oge", `data-sayfa` = sayfa, `data-gosterge` = gosterge,
         div(class = "d-flex align-items-center gap-2", ikon(ikon_ad), span(metin)), sag)
}

kenar_menu <- function() {
  tags$aside(class = "kenar",
    div(class = "kenar-ust",
        div(class = "d-flex align-items-center gap-2",
            div(class = "logo", ikon("query_stats", 20)),
            span(class = "logo-yazi", "EconoLab")),
        span(class = "surum", "v2.0.0")),
    div(class = "px-3 pt-2", span(class = "proje-rozet", "TÜBİTAK 2209-A PROJESİ")),
    div(class = "kenar-govde",
      etiket("ANALİZ & TAHMİN", class = "nav-grup"),
      nav_oge("makro", "monitoring", "Makro Gösterge Paneli"),
      nav_oge("model", "biotech", "Model Laboratuvarı & ÇD"),
      nav_oge("regresyon", "insights", "Regresyon & Tanı Testleri"),
      nav_oge("veri", "dataset", "Veri Hattı & Metaveri"),
      etiket("SİSTEM & YEDEK", class = "nav-grup"),
      nav_oge("veri", "lan", "Önbellek & API", sag = span(class = "nabiz")),
      nav_oge("veri", "tune", "Ayarlar & .Renviron")
    )
  )
}

ust_bar <- function() {
  tags$header(class = "ust-bar",
    div(class = "d-flex align-items-center gap-3 flex-grow-1",
        div(class = "canli-rozet", span(class = "nokta"), textOutput("ust_durum", inline = TRUE))),
    div(class = "d-flex align-items-center gap-2",
        actionButton("hepsini_calistir", tagList(ikon("play_arrow", 16), "Hepsini Çalıştır"),
                     class = "btn-ana", title = "calistir_hepsi(): hazır veriyle tüm modelleri yeniden kestirir"),
        actionButton("kaynaktan_yenile", tagList(ikon("sync", 16), "Kaynaklardan Yenile"),
                     class = "btn-ikincil", title = "sonuclari_getir(yenile = TRUE): tüm API'lerden yeniden çeker"),
        div(class = "avatar", ikon("person", 18)))
  )
}

#NOTE
hap_secim <- function(id, secenekler, secili = secenekler[[1]], etiket_metin = NULL) {
  div(class = "d-flex align-items-center gap-2 flex-wrap",
      if (!is.null(etiket_metin)) etiket(etiket_metin),
      div(class = "hap-grup",
          radioButtons(id, NULL, choices = secenekler, selected = secili, inline = TRUE)))
}

#NOTE
gosterge_secenekleri <- function(adlar = aktif_gostergeler()) {
  roller <- vapply(adlar, function(g) varsayilan(CONFIG$gostergeler[[g]]$rol, "Diğer"), "")
  lapply(split(adlar, factor(roller, levels = unique(roller))), function(a)
    setNames(a, vapply(a, gosterge_etiketi, "")))
}

#NOTE
pl_tema <- function(p, legend = TRUE) {
  eksen <- list(gridcolor = "#2a2932", zeroline = FALSE, linecolor = "#35343d",
                tickfont = list(family = "JetBrains Mono", size = 11))
  p |>
    plotly::layout(paper_bgcolor = "rgba(0,0,0,0)", plot_bgcolor = "rgba(0,0,0,0)",
                   font = list(color = RENK$metin2, family = "Inter", size = 12),
                   xaxis = eksen, yaxis = eksen, showlegend = legend,
                   legend = list(orientation = "h", x = 0, y = 1.12, bgcolor = "rgba(0,0,0,0)"),
                   hoverlabel = list(bgcolor = RENK$kap_yuksek, font = list(family = "Inter")),
                   margin = list(l = 55, r = 20, t = 30, b = 40)) |>
    plotly::config(displaylogo = FALSE,
                   modeBarButtonsToRemove = c("lasso2d", "select2d", "autoScale2d"))
}

dt_tablo <- function(df, sayfa = 25, ...) {
  DT::datatable(df, rownames = FALSE, escape = FALSE, class = "compact koyu-tablo",
                selection = "none",
                options = list(pageLength = sayfa, dom = if (nrow(df) > sayfa) "tp" else "t",
                               ordering = TRUE, scrollX = TRUE, ...))
}

#NOTE
kivilcim <- function(seriler, renkler, kesikli = rep(FALSE, length(seriler)), w = 240, h = 44) {
  tum <- unlist(seriler); tum <- tum[is.finite(tum)]
  if (length(tum) < 2) return(NULL)
  ar <- range(tum); if (diff(ar) == 0) ar <- ar + c(-1, 1)
  yol <- function(y) {
    x <- seq(0, w, length.out = length(y))
    yy <- h - 2 - (y - ar[1]) / diff(ar) * (h - 4)
    paste(sprintf("%.1f,%.1f", x[is.finite(y)], yy[is.finite(y)]), collapse = " ")
  }
  HTML(sprintf('<svg class="kivilcim" viewBox="0 0 %d %d" preserveAspectRatio="none">%s</svg>', w, h,
               paste(mapply(function(y, r, k) sprintf(
                 '<polyline points="%s" fill="none" stroke="%s" stroke-width="%s"%s/>',
                 yol(y), r, if (k) 1.2 else 1.8, if (k) ' stroke-dasharray="3 3"' else ""),
                 seriler, renkler, kesikli), collapse = "")))
}

#NOTE
gosterge_birimi <- function(g) {
  k <- CONFIG$gostergeler[[g]]
  if (identical(k$donusum, "yillik_degisim") || grepl("%|Oranı|Faiz|İşsizlik", k$ad)) "%"
  else if (grepl("TRY$", g)) "₺" else ""
}

bicim <- function(x, d = 2) {
  if (length(x) == 0 || is.na(x)) return("—")
  if (abs(x) >= 1e9) return(sprintf("%.2f Mr", x / 1e9))
  if (abs(x) >= 1e6) return(sprintf("%.2f Mn", x / 1e6))
  formatC(x, format = "f", digits = d, big.mark = ",")
}

deger_bicim <- function(x, g, d = 2) {
  b <- gosterge_birimi(g)
  if (b == "%") paste0("%", bicim(x, d)) else if (b == "₺") paste(bicim(x, d), "₺") else bicim(x, d)
}

donem_kisa <- function(tarih, g) {
  f <- gosterge_frekansi(g)
  y <- format(tarih, "%Y"); m <- as.integer(format(tarih, "%m"))
  switch(f, aylik = sprintf("%s-M%02d", y, m), ceyreklik = sprintf("%s-Q%d", y, (m - 1) %/% 3 + 1), y)
}

bos_durum <- function(mesaj = "Henüz sonuç yok. Üst bardan “Kaynaklardan Yenile” ile veriyi çekin.") {
  div(class = "bos-durum", ikon("cloud_off", 32), div(mesaj))
}
