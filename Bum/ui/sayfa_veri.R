#NOTE
KAYNAK_IKON <- c(EVDS = "account_balance", FRED = "cloud_sync", WORLDBANK = "public",
                 OECD = "hub", BIST = "candlestick_chart", CSV_YEDEK = "inventory_2")

veri_ui <- function(id) {
  ns <- NS(id)
  tagList(
    div(class = "hero",
      div(class = "hero-sol",
        div(class = "d-flex gap-2 flex-wrap",
            rozet("BÖLÜM 2 & 4 DENETİMİ", tur = "primary"),
            rozet(sprintf("ETL MİMARİSİ: %d AÇIK VERİ KAYNAĞI", length(CONFIG$kaynaklar$desteklenen))),
            rozet("Yedekleme Zinciri Canlı", tur = "tertiary")),
        tags$h1("Veri Hattı & Metaveri Denetimi"),
        tags$p(class = "hero-p", "Çok kanallı geri çekilme mimarisi (Multi-Channel Fallback Chain), ",
               "doğrusal enterpolasyon (zoo::na.approx), kalite raporu ve ",
               tags$code("data/cache/"), " dosya sisteminin senkronizasyon raporu.")),
      div(class = "d-flex gap-2 flex-wrap hero-sag align-items-start",
          actionButton(ns("yeniden_cek"), tagList(ikon("downloading", 16), "Seçili Seriyi Yeniden Çek"),
                       class = "btn-ana"),
          actionButton(ns("bosalt"), tagList(ikon("cached", 16), "Önbelleği Boşalt"), class = "btn-ikincil"))
    ),

    uiOutput(ns("ozet_kutular"), class = "stat-izgara"),

    kart(kart_baslik("account_tree", "Yedekleme Zinciri Mimarisi (Multi-Channel Fallback)",
                     alt = "kaynak_zinciri() — seçili gösterge",
                     sag = div(class = "secim-dar",
                               selectInput(ns("gosterge"), NULL, gosterge_secenekleri(), width = "280px"))),
         tags$p(class = "alt-metin",
                sprintf("Taze önbellek (TTL < %g gün) → Birincil kaynak → Yedek API'ler → Yerel CSV (%s/) → ",
                        CONFIG$veri$cache_tazelik_gun, CONFIG$saklama$yedek_klasoru),
                sprintf("Bayat önbellek → NULL (gösterge atlanır). Retry: %d deneme, %g sn bekleme, ",
                        CONFIG$baglanti$yeniden_deneme, CONFIG$baglanti$yeniden_deneme_bekleme),
                "HTTP 400/401/403/404 kalıcı hata."),
         uiOutput(ns("zincir"), class = "zincir"),
         plotly::plotlyOutput(ns("seri"), height = "260px")),

    div(class = "ikili-izgara genis-sol",
        kart(kart_baslik("verified", "Veri Kalitesi & Doğrusal Enterpolasyon Matrisi",
                         alt = "kalite_raporu_olustur() + ic_bosluk_say()", sag = uiOutput(ns("butunluk"))),
             div(class = "ikili-izgara",
                 plotly::plotlyOutput(ns("halka"), height = "230px"),
                 plotly::plotlyOutput(ns("eksik"), height = "230px"))),
        kart(kart_baslik("key", "Kimlik & Önbellek Teşhisi", alt = ".Renviron parametreleri ve dosya sağlığı"),
             uiOutput(ns("kimlik")))),

    kart(kart_baslik("dataset", "metaveri Tablosu & Kanal Denetimi",
                     alt = "data/processed/metaveri + kalite_raporu", sag = uiOutput(ns("kanal_sayilari"))),
         DT::DTOutput(ns("metaveri")))
  )
}

veri_server <- function(id, paket, secili, paket_yenile) {
  moduleServer(id, function(input, output, session) {

    observeEvent(secili(), updateSelectInput(session, "gosterge", selected = secili()))

    meta <- reactive({ req(paket()); m <- paket()$meta; m[m$gosterge %in% aktif_gostergeler(), ] })

    observeEvent(input$yeniden_cek, {
      g <- input$gosterge
      paket_yenile(sprintf("%s kaynaklardan yeniden çekiliyor…", g), function() gosterge_guncelle(g))
    })

    observeEvent(input$bosalt, {
      f <- list.files(CONFIG$saklama$cache_klasoru, pattern = "\\.rds$", full.names = TRUE)
      unlink(f)
      log_msg(sprintf("Önbellek boşaltıldı: %d dosya silindi (data/cache)", length(f)), "UYARI")
      showNotification(sprintf("%d önbellek dosyası silindi. Sonraki çekimde API'ye gidilecek.", length(f)),
                       type = "warning")
    })

    output$ozet_kutular <- renderUI({
      m <- meta(); p <- paket()
      d <- table(factor(m$durum, levels = names(DURUM_AD)))
      tagList(
        stat_kutu("Aktif Gösterge", sprintf("%d / %d", sum(m$durum != "alinamadi"), nrow(m)),
                  "çekilen / tanımlı", renk = "primary"),
        stat_kutu("Canlı API", d[["api"]], "durum = api", renk = "tertiary"),
        stat_kutu("Önbellek / CSV", sprintf("%d / %d", d[["cache"]], d[["csv_yedek"]]), "cache • csv_yedek"),
        stat_kutu("Yedek Kaynak", sum(m$yedek_kullanildi %in% TRUE), "birincil dışı kanal",
                  renk = if (any(m$yedek_kullanildi %in% TRUE)) "primary" else "metin"),
        stat_kutu("Bayat / Alınamadı", sprintf("%d / %d", d[["bayat_cache"]], d[["alinamadi"]]),
                  "kritik durum", renk = if (d[["bayat_cache"]] + d[["alinamadi"]] > 0) "error" else "metin"),
        stat_kutu("Toplam Gözlem", format(nrow(p$veri), big.mark = ","),
                  sprintf("enterpolasyon: %d", ic_bosluk_say(p$veri))))
    })

    output$zincir <- renderUI({
      g <- input$gosterge; req(g)
      m <- meta()[meta()$gosterge == g, ]
      kullanilan <- if (nrow(m)) m$kaynak else NA
      durum <- if (nrow(m)) m$durum else "alinamadi"
      adim <- function(baslik, ikon_ad, ad, kod, alt, tur, aktif = FALSE, rz = NULL) {
        div(class = paste("zincir-adim", paste0("kenar-", tur), if (aktif) "aktif"),
            etiket(baslik),
            div(class = "d-flex align-items-center gap-2 my-1", ikon(ikon_ad, 20, paste0("text-", tur, "-c")),
                tags$b(ad)),
            tags$code(kod), div(class = "stat-alt", alt), rz)
      }
      halkalar <- kaynak_zinciri(g)
      ok <- function() div(class = "zincir-ok", ikon("arrow_forward", 18))
      parcalar <- list(adim("Aşama 0", "bolt", "Taze Önbellek",
                            file.path(CONFIG$saklama$cache_klasoru, paste0(g, ".rds")),
                            sprintf("TTL < %g gün", CONFIG$veri$cache_tazelik_gun), "tertiary",
                            aktif = durum == "cache", if (durum == "cache") rozet("KULLANILDI", tur = "basari")))
      for (i in seq_along(halkalar)) {
        h <- halkalar[[i]]
        csv <- identical(h$kaynak, "CSV_YEDEK")
        hazir <- kaynak_kullanilabilir(h$kaynak)
        aktif <- (csv && durum == "csv_yedek") || (!csv && durum == "api" && identical(h$kaynak, kullanilan))
        parcalar <- c(parcalar, list(ok(), adim(
          sprintf("Aşama %d • %s", i, if (h$birincil) "Birincil" else if (csv) "Yerel Depo" else "Yedek API"),
          varsayilan(KAYNAK_IKON[h$kaynak], "hub"), h$kaynak,
          if (csv) file.path(CONFIG$saklama$yedek_klasoru, paste0(g, ".csv")) else h$kod,
          paste0(h$tur, if (isTRUE(h$yaklasik)) " • yaklaşık seri" else "",
                 if (!is.null(h$filtre)) paste0(" • ", h$filtre) else ""),
          if (h$birincil) "primary" else "secondary", aktif,
          if (aktif) rozet("KULLANILDI", tur = "basari") else if (!hazir) rozet("ANAHTAR YOK", tur = "hata")
          else rozet("HAZIR"))))
      }
      c(parcalar, list(ok(), adim("Son Çare", "history_toggle_off", "Bayat Önbellek", "cache_oku(g, Inf)",
                                  "tüm kanallar çökerse", "error", aktif = durum == "bayat_cache",
                                  if (durum == "bayat_cache") rozet("KULLANILDI", tur = "hata"))))
    })

    output$seri <- plotly::renderPlotly({
      g <- input$gosterge; req(g)
      d <- gosterge_serisi(paket()$veri, g)
      shiny::validate(need(nrow(d) > 0, "Bu gösterge hiçbir kanaldan alınamadı."))
      plotly::plot_ly(d, x = ~tarih) |>
        plotly::add_lines(y = ~deger, name = gosterge_etiketi(g), line = list(color = RENK$metin2, width = 1.8)) |>
        plotly::add_markers(data = d[!d$gercek, ], y = ~deger, name = "Enterpolasyon (na.approx)",
                            marker = list(color = RENK$primary, size = 7, symbol = "circle-open")) |>
        pl_tema()
    })

    output$butunluk <- renderUI({
      v <- paket()$veri
      rozet(sprintf("BÜTÜNLÜK: %%%.2f", 100 * mean(v$gercek)), tur = "tertiary")
    })

    output$halka <- plotly::renderPlotly({
      v <- paket()$veri; s <- ic_bosluk_say(v)
      plotly::plot_ly(labels = c("Orijinal", "Enterpolasyon"), values = c(nrow(v) - s, s),
                      type = "pie", hole = 0.72, sort = FALSE, textinfo = "none",
                      marker = list(colors = c(RENK$tertiary, RENK$primary), line = list(color = RENK$kap, width = 2))) |>
        pl_tema() |>
        plotly::layout(legend = list(orientation = "h", x = 0.5, xanchor = "center", y = -0.05),
                       margin = list(l = 10, r = 10, t = 10, b = 10),
                       annotations = list(list(text = sprintf("%%%.2f", 100 * (1 - s / nrow(v))), showarrow = FALSE,
                                               font = list(size = 20, color = RENK$metin, family = "Space Grotesk"))))
    })

    output$eksik <- plotly::renderPlotly({
      k <- paket()$kalite; req(k)
      k <- k[k$gosterge %in% aktif_gostergeler(), ]
      k <- k[order(k$eksik_donem_orani), ]
      plotly::plot_ly(k, x = ~100 * eksik_donem_orani, y = ~factor(gosterge, levels = gosterge), type = "bar",
                      orientation = "h", marker = list(color = RENK$secondary), text = ~gecikme_donem,
                      hovertemplate = "%{y}: %%%{x:.1f} eksik dönem<br>gecikme: %{text} dönem<extra></extra>") |>
        plotly::layout(xaxis = list(title = "Eksik dönem oranı (%)"), yaxis = list(title = ""),
                       margin = list(l = 120, r = 10, t = 10, b = 40)) |>
        pl_tema(legend = FALSE)
    })

    output$kimlik <- renderUI({
      paket()
      anahtar <- function(ad, kaynak) {
        v <- Sys.getenv(ad)
        div(class = "bilgi-satir",
            span(tags$code(ad)),
            span(class = "d-flex gap-2 align-items-center",
                 tags$b(if (nzchar(v)) paste0("••••••••", substring(v, nchar(v) - 3)) else "—"),
                 if (kaynak_kullanilabilir(kaynak)) rozet("GEÇERLİ", tur = "basari") else rozet("TANIMSIZ", tur = "hata")))
      }
      klasor <- function(yol, desen = NULL) {
        f <- list.files(yol, pattern = desen, full.names = TRUE)
        if (!length(f)) return("boş")
        sprintf("%d dosya • %.1f KB • en eski %.1f gün", length(f), sum(file.size(f)) / 1024,
                max(vapply(f, dosya_yasi_gun, numeric(1))))
      }
      tagList(
        etiket(".Renviron Kimlik Kontrolü"),
        anahtar("EVDS_API_KEY", "EVDS"), anahtar("FRED_API_KEY", "FRED"),
        bilgi_satir("EVDS uç noktası", CONFIG$baglanti$evds_base_url),
        div(class = "mt-3", etiket("Yerel Depo Durumu")),
        bilgi_satir(CONFIG$saklama$cache_klasoru, klasor(CONFIG$saklama$cache_klasoru, "\\.rds$")),
        bilgi_satir(CONFIG$saklama$yedek_klasoru, klasor(CONFIG$saklama$yedek_klasoru, "\\.csv$")),
        bilgi_satir(CONFIG$saklama$processed_klasoru, klasor(CONFIG$saklama$processed_klasoru)),
        bilgi_satir("Güncelleme sıklığı", sprintf("%g gün • otomatik = %s", CONFIG$guncelleme$sikligi_gun,
                                                  CONFIG$guncelleme$otomatik)),
        div(class = "not-kutu mt-3", ikon("security", 18, "text-secondary-c"),
            div("Anahtarlar ", tags$code("~/.Renviron"), " dosyasından okunur (config.R); arayüzde ",
                "yalnızca son 4 karakter gösterilir.")))
    })

    output$kanal_sayilari <- renderUI({
      t <- table(factor(meta()$durum, levels = names(DURUM_AD)))
      t <- t[t > 0]
      div(class = "d-flex gap-2 flex-wrap",
          lapply(names(t), function(k) rozet(sprintf("%s: %d", DURUM_AD[[k]], t[[k]]), tur = DURUM_TUR[[k]])))
    })

    output$metaveri <- DT::renderDT({
      m <- meta(); k <- paket()$kalite
      k <- k[match(m$gosterge, k$gosterge), ]
      d <- data.frame(
        Gösterge = sprintf("<b>%s</b><br><span class='stat-alt'>%s</span>", m$gosterge, m$ad),
        Rol = m$rol, Frekans = FREKANS_AD[m$frekans],
        `Aktif Kaynak` = ifelse(is.na(m$kaynak), "—", m$kaynak),
        `Seri Kodu` = ifelse(is.na(m$kod), "—", sprintf("<code>%s</code>", m$kod)),
        Öncelik = m$kaynak_onceligi,
        Durum = sprintf('<span class="rozet %s">%s</span>', DURUM_TUR[m$durum], DURUM_AD[m$durum]),
        Dönüşüm = m$donusum,
        `Tarih Aralığı` = ifelse(is.na(m$ilk_tarih), "—", paste(format(m$ilk_tarih, "%Y-%m"), "/",
                                                             format(m$son_tarih, "%Y-%m"))),
        Gözlem = m$gozlem, `Gecikme (dönem)` = k$gecikme_donem,
        `Eksik Oranı` = k$eksik_donem_orani,
        `Son Çekim` = ifelse(is.na(m$cekim_zamani), "—", format(m$cekim_zamani, "%d.%m %H:%M")),
        check.names = FALSE)
      dt_tablo(d, sayfa = 21)
    })
  })
}
