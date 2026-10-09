#NOTE
makro_ui <- function(id) {
  ns <- NS(id)
  roller <- vapply(CONFIG$gostergeler[aktif_gostergeler()], function(k) varsayilan(k$rol, "Diğer"), "")
  rol_sec <- c(setNames("T", sprintf("Tümü (%d)", length(roller))),
               setNames(unique(roller), sprintf("%s (%d)", unique(roller), table(roller)[unique(roller)])))
  tagList(
    div(class = "hero",
      div(class = "hero-sol",
        div(class = "d-flex align-items-center gap-2 flex-wrap",
            rozet("EKONOMETRİK TAHMİN ÇERÇEVESİ", tur = "primary"),
            div(class = "durum-hap", span(class = "nabiz"), textOutput(ns("durum"), inline = TRUE))),
        tags$h1("Makroekonomik Tahmin & Gösterge Paneli"),
        tags$p(class = "hero-p",
               "Kayan Pencere (Rolling Window) AR-EKK modelleri ile Türkiye ekonomisi temel ",
               "parametrelerinin dinamik t+1 kestirimleri ve çok adımlı tahmin yelpazeleri.")),
      div(class = "d-flex gap-3 hero-sag",
          stat_kutu("Çekirdek Algoritma", "AR(p) + OLS Rolling", renk = "secondary"),
          stat_kutu("Ort. Theil U", textOutput(ns("ort_theil"), inline = TRUE), renk = "tertiary"))
    ),
    div(class = "filtre-bar d-flex justify-content-between flex-wrap gap-2",
        hap_secim(ns("rol"), rol_sec, etiket_metin = "GÖSTERGE ROLÜ:"),
        hap_secim(ns("frekans"), c("Tümü" = "T", setNames(names(FREKANS_AD), FREKANS_AD)),
                  etiket_metin = "FREKANS:")),

    uiOutput(ns("kpi"), class = "kpi-izgara"),

    kart(
      kart_baslik("timeline", "Kayan Pencere Tahmin Yörüngesi & Yelpaze (Fan Chart)",
                  alt = "EKONOMETRİK ZAMAN SERİSİ ANALİZİ",
                  sag = div(class = "secim-dar",
                            selectInput(ns("gosterge"), NULL, gosterge_secenekleri(), width = "280px"))),
      uiOutput(ns("fan_rozetler"), class = "d-flex gap-2 flex-wrap mb-2"),
      plotly::plotlyOutput(ns("fan"), height = "460px"),
      div(class = "not-kutu",
          ikon("verified", 18, "text-tertiary-c"),
          div(tags$b("Pesaran & Timmermann (2007)"), " ve ", tags$b("Rossi & Inoue (2012)"),
              " standartlarında her adımda sabit genişlikli pencere kaydırılarak t+1 kestirimi ",
              "(kayan_pencere_tahmin) yapılmış; gelecek_tahmin ile ",
              sprintf("%%%d güven düzeyinde", round(100 * CONFIG$model$guven_duzeyi)), " yelpaze türetilmiştir.",
              div(class = "kod-satir",
                  "AR-EKK: y_t = c + φ₁y_{t-1} + … + φ_p y_{t-p} + ε_t  •  β̂ = (X'X)⁻¹X'Y")))
    ),

    kart(
      kart_baslik("table_chart", "Model Karşılaştırmalı Hata Metrikleri",
                  alt = "TAHMİN ÖZETİ (data/processed/tahmin_ozeti)",
                  sag = div(class = "d-flex gap-2",
                            downloadButton(ns("csv"), "CSV", class = "btn-ikincil btn-sm"),
                            downloadButton(ns("rds"), "sonuclar.rds", class = "btn-ikincil btn-sm"))),
      DT::DTOutput(ns("ozet")),
      div(class = "dipnot", "* Metrikler kayan pencere örnek dışı t+1 tahminlerinden hesaplanır; ",
          "Theil U → 0 tahmin gücünün arttığını gösterir.")
    ),

    div(class = "ikili-izgara",
        kart(kart_baslik("memory", "R Oturumu", alt = "R CORE ACTIVE"), uiOutput(ns("oturum"))),
        kart(class = "konsol",
             kart_baslik("terminal", "EconoLab Veri Hattı Konsolu & Olay Günlüğü",
                         alt = "CANLI YAYIN: logs/calisma.log"),
             uiOutput(ns("gunluk"))))
  )
}

makro_server <- function(id, paket, secili, gunluk) {
  moduleServer(id, function(input, output, session) {

    output$durum <- renderText({
      p <- paket(); req(p)
      sprintf("Son Hesaplama: %s • %d Aktif Gösterge • R %s Motoru Aktif",
              format(p$zaman, "%d.%m.%Y %H:%M"), nrow(p$ozet), getRversion())
    })

    output$ort_theil <- renderText({
      p <- paket(); req(p)
      sprintf("%.3f", mean(p$ozet$THEIL_U, na.rm = TRUE))
    })

    observeEvent(secili(), if (!identical(input$gosterge, secili()))
      updateSelectInput(session, "gosterge", selected = secili()))
    observeEvent(input$gosterge, secili(input$gosterge), ignoreInit = TRUE)

    gorunen <- reactive({
      o <- paket()$ozet; req(o)
      if (input$rol != "T") o <- o[o$rol %in% input$rol, ]
      if (input$frekans != "T") o <- o[o$FREKANS %in% input$frekans, ]
      o
    })

    output$kpi <- renderUI({
      p <- paket()
      if (is.null(p)) return(bos_durum())
      o <- gorunen()
      if (nrow(o) == 0) return(bos_durum("Bu filtreye uyan gösterge yok."))
      lapply(seq_len(nrow(o)), function(i) {
        r <- o[i, ]; g <- r$gosterge
        seri <- gosterge_serisi(p$veri, g)
        gc <- utils::tail(p$gecmis[p$gecmis$gosterge == g, ], 36)
        t1 <- p$gelecek$tahmin[p$gelecek$gosterge == g][1]
        m <- p$meta[p$meta$gosterge == g, ]
        div(class = paste("kpi-kart", if (identical(g, secili())) "secili"),
            onclick = sprintf("Shiny.setInputValue('nav',{sayfa:'makro',gosterge:'%s',n:Date.now()})", g),
            div(class = "d-flex justify-content-between align-items-start gap-2",
                div(etiket(sprintf("%s • %s", varsayilan(m$kaynak, "?"), varsayilan(m$kod, "—"))),
                    tags$h2(r$ad),
                    div(class = "alt-metin", sprintf("%s • %s", FREKANS_AD[[r$FREKANS]], r$rol))),
                rozet(sprintf("MAPE %%%.1f", r$MAPE), tur = "secondary")),
            div(class = "d-flex justify-content-between align-items-end mt-2",
                div(etiket(sprintf("Son: %s", donem_kisa(utils::tail(seri$tarih, 1), g))),
                    div(class = "kpi-deger", deger_bicim(utils::tail(seri$deger, 1), g))),
                div(class = "text-end", etiket("t+1 Tahmin", class = "c-secondary"),
                    div(class = "kpi-tahmin", deger_bicim(t1, g)))),
            kivilcim(list(gc$gercek, gc$tahmin), c(RENK$metin2, RENK$primary)),
            div(class = "kpi-alt",
                span(sprintf("p=%d", r$P)), span(sprintf("w=%d", r$PENCERE)),
                span("RMSE: ", tags$b(bicim(r$RMSE))), span("U: ", tags$b(bicim(r$THEIL_U, 3)))))
      })
    })

    output$fan_rozetler <- renderUI({
      p <- paket(); req(p, input$gosterge)
      r <- p$ozet[p$ozet$gosterge == input$gosterge, ]
      if (nrow(r) == 0) return(NULL)
      tagList(rozet(sprintf("AR(%d) • w=%d • H=%d", r$P, r$PENCERE, r$UFUK), tur = "primary"),
              rozet(r$YONTEM, tur = "secondary"),
              rozet(sprintf("%d örnek dışı tahmin", r$N_TAHMIN)),
              rozet(sprintf("Kaynak: %s", varsayilan(r$KAYNAK, "?")), tur = "tertiary"))
    })

    output$fan <- plotly::renderPlotly({
      p <- paket(); g <- input$gosterge; req(p, g)
      shiny::validate(need(g %in% p$ozet$gosterge, "Bu gösterge için tahmin üretilemedi (günlüğe bakın)."))
      gc <- p$gecmis[p$gecmis$gosterge == g, ]
      fan <- p$gelecek[p$gelecek$gosterge == g, ]
      seri <- gosterge_serisi(p$veri, g)
      seri <- seri[seri$tarih >= min(gc$tarih) - (max(seri$tarih) - min(gc$tarih)) * 0.5, ]
      son <- utils::tail(seri, 1)
      bant <- rbind(data.frame(tarih = son$tarih, tahmin = son$deger, alt = son$deger, ust = son$deger),
                    fan[, c("tarih", "tahmin", "alt", "ust")])
      r <- p$ozet[p$ozet$gosterge == g, ]
      guven <- round(100 * CONFIG$model$guven_duzeyi)

      plotly::plot_ly() |>
        plotly::add_ribbons(data = bant, x = ~tarih, ymin = ~alt, ymax = ~ust,
                            name = sprintf("%%%d Tahmin Yelpazesi (t+1:t+%d)", guven, nrow(fan)),
                            line = list(width = 0), fillcolor = "rgba(255,182,137,0.18)") |>
        plotly::add_lines(data = seri, x = ~tarih, y = ~deger, name = paste0("Gerçekleşen (", r$ad, ")"),
                          line = list(color = RENK$metin, width = 2)) |>
        plotly::add_lines(data = gc, x = ~tarih, y = ~tahmin,
                          name = sprintf("AR-EKK Kayan Pencere [w=%d, p=%d]", r$PENCERE, r$P),
                          line = list(color = RENK$primary, width = 2.5)) |>
        plotly::add_trace(data = bant, x = ~tarih, y = ~tahmin, name = "Nokta Tahmin", type = "scatter",
                          mode = "lines+markers", line = list(color = RENK$primary, dash = "dot", width = 2),
                          marker = list(color = RENK$primary, size = 6)) |>
        plotly::layout(hovermode = "x unified",
                       shapes = list(list(type = "line", x0 = son$tarih, x1 = son$tarih, y0 = 0, y1 = 1,
                                          yref = "paper",
                                          line = list(color = RENK$secondary, dash = "dot", width = 1)))) |>
        pl_tema()
    })

    output$ozet <- DT::renderDT({
      o <- gorunen()
      d <- data.frame(
        Gösterge = sprintf("<b>%s</b><br><span class='stat-alt'>%s</span>", o$gosterge, o$ad),
        Rol = o$rol, Frekans = FREKANS_AD[o$FREKANS], Kaynak = o$KAYNAK,
        `p / w` = sprintf("p=%d / w=%d", o$P, o$PENCERE), Yöntem = o$YONTEM,
        MAE = o$MAE, MSE = o$MSE, RMSE = o$RMSE, `MAPE (%)` = o$MAPE, `Theil U` = o$THEIL_U,
        check.names = FALSE)
      dt_tablo(d, sayfa = 21) |> DT::formatRound(7:11, 3)
    })

    output$csv <- downloadHandler("tahmin_ozeti.csv",
                                  function(f) utils::write.csv(paket()$ozet, f, row.names = FALSE))
    output$rds <- downloadHandler("sonuclar.rds",
                                  function(f) file.copy(file.path(CONFIG$saklama$model_klasoru, "sonuclar.rds"), f))

    output$oturum <- renderUI({
      p <- paket()
      pk <- c("fredr", "httr", "wbstats", "dplyr", "zoo", "shiny", "plotly", "lmtest")
      dosya <- list.files(CONFIG$saklama$cache_klasoru, full.names = TRUE)
      tagList(
        bilgi_satir("R Oturumu", sprintf("%s (%s)", getRversion(), R.version$platform)),
        bilgi_satir("Kütüphaneler", paste(pk, collapse = ", ")),
        bilgi_satir("Önbellek (data/cache)", sprintf("%d dosya • %.1f KB", length(dosya),
                                                     sum(file.size(dosya)) / 1024)),
        bilgi_satir("Model seçimi", sprintf("%s • güven %%%d • trend=%s", CONFIG$model$model_secimi,
                                            round(100 * CONFIG$model$guven_duzeyi), CONFIG$model$formulde_trend)),
        bilgi_satir("Veri aralığı", sprintf("%s → %s", CONFIG$veri$baslangic_tarihi, CONFIG$veri$bitis_tarihi)),
        bilgi_satir("Son hesaplama", if (is.null(p)) "—" else format(p$zaman, "%d.%m.%Y %H:%M:%S")))
    })

    output$gunluk <- renderUI({
      satirlar <- rev(utils::tail(gunluk(), 40))
      if (!length(satirlar)) return(div(class = "konsol-govde", "Günlük boş."))
      div(class = "konsol-govde", lapply(satirlar, function(s) {
        m <- regmatches(s, regexec("^\\[(.*?)\\] \\[(.*?)\\] (.*)$", s))[[1]]
        if (length(m) < 4) return(div(class = "konsol-satir", s))
        div(class = "konsol-satir", span(class = "zaman", substr(m[2], 12, 19)),
            span(class = paste("tur", tolower(m[3])), paste0(m[3], ":")), span(m[4]))
      }))
    })
  })
}
