#NOTE
regresyon_ui <- function(id) {
  ns <- NS(id)
  tagList(
    div(class = "hero",
      div(class = "hero-sol",
        div(class = "d-flex gap-2 flex-wrap",
            rozet("BÖLÜM 2.3 & 2.4", tur = "primary"),
            rozet("TÜBİTAK 2209-A • ATILIM ÜNİVERSİTESİ"), rozet("v2.0.0", tur = "tertiary")),
        tags$h1("EKK Tabanlı Ekonometrik Yaklaşımla Finansal Değişkenlerin Tahmini"),
        tags$p(class = "hero-p", uiOutput(ns("model_ozet"), inline = TRUE))),
      div(class = "d-flex gap-2 flex-wrap hero-sag align-items-start",
          tags$button(class = "btn btn-ikincil", `data-kopyala` = ns("r_kodu"),
                      ikon("terminal", 16), "R Kodu Kopyala"),
          downloadButton(ns("latex"), "LaTeX Tablosu", class = "btn-ikincil"),
          downloadButton(ns("model_rds"), "Model (.rds)", class = "btn-ana"))
    ),
    div(class = "filtre-bar",
        div(class = "d-flex gap-4 flex-wrap align-items-end w-100",
            selectInput(ns("gosterge"), "Bağımlı Değişken", gosterge_secenekleri(), width = "280px"),
            div(class = "stat-alt pb-3", textOutput(ns("p_kaynak"), inline = TRUE)))),

    uiOutput(ns("istatistikler"), class = "stat-izgara"),

    div(class = "ikili-izgara genis-sol",
        kart(kart_baslik("table_rows", "Katsayı Tahminleri & Güven Aralıkları",
                         sag = rozet("EKK / Klasik Standart Hatalar", tur = "secondary")),
             DT::DTOutput(ns("katsayilar")),
             div(class = "dipnot", "Anlamlılık Kodları: 0 '***' 0.001 '**' 0.01 '*' 0.05 '.' 0.1 ' ' 1  •  ",
                 textOutput(ns("artik_se"), inline = TRUE))),
        kart(kart_baslik("functions", "EKK Model Spesifikasyonu", alt = "BÖLÜM 2.3 & R/models.R"),
             div(class = "formul", "y_t = c + φ₁y_{t-1} + φ₂y_{t-2} + … + φ_p y_{t-p} + ε_t"),
             div(class = "formul", "β̂ = (X'X)⁻¹ X'Y      s² = e'e / (n − k)"),
             tags$pre(id = ns("r_kodu"), class = "kod-blok", textOutput(ns("r_kodu_metin"))))),

    kart(kart_baslik("ssid_chart", "Kalıntı Analizi (ε_t)", alt = "SIFIR EKSENİ YAYILIMI (±3σ)",
                     sag = uiOutput(ns("carpiklik"))),
         plotly::plotlyOutput(ns("kalinti"), height = "300px")),

    kart(kart_baslik("fact_check", "Ekonometrik Tanı & Varsayım Testleri Bataryası",
                     sag = rozet("BÖLÜM 2.4 STANDARDI", tur = "primary")),
         uiOutput(ns("testler"), class = "test-izgara")),

    kart(kart_baslik("query_stats", "Örnek Dışı Doğrulama & Tahmin Metrikleri",
                     alt = "BÖLÜM 2.8 STANDARDI • kayan_pencere_tahmin + metrikler",
),
         uiOutput(ns("oos"), class = "stat-izgara"),
         uiOutput(ns("asiri_uyum")))
  )
}

regresyon_server <- function(id, paket, secili) {
  moduleServer(id, function(input, output, session) {

    ozet_satir <- reactive({
      o <- paket()$ozet; req(o, input$gosterge)
      o[o$gosterge == input$gosterge, ]
    })

    observeEvent(secili(), updateSelectInput(session, "gosterge", selected = secili()))

    #NOTE
    p_secili <- reactive({
      r <- ozet_satir()
      if (nrow(r)) r$P else gosterge_p(input$gosterge)
    })

    output$p_kaynak <- renderText({
      r <- ozet_satir()
      if (nrow(r)) sprintf("Pipeline seçimi: p=%d, w=%d (%s)", r$P, r$PENCERE, r$YONTEM)
      else sprintf("Varsayılan: p=%d", gosterge_p(input$gosterge))
    })

    veri <- reactive({ req(paket()); paket()$veri })
    fit <- reactive({
      req(input$gosterge)
      shiny::validate(need(input$gosterge %in% veri()$gosterge, "Bu gösterge hazır veride yok."))
      basit_ar(veri(), input$gosterge, p_secili())
    })
    ct <- reactive(lmtest::coeftest(fit()))
    y <- reactive(gosterge_serisi(veri(), input$gosterge)$deger)

    output$model_ozet <- renderUI({
      k <- CONFIG$gostergeler[[input$gosterge]]; m <- paket()$meta
      kay <- m[m$gosterge == input$gosterge, ]
      tagList("Model: ", tags$b(sprintf("AR(%d) %s", p_secili(), input$gosterge)),
              sprintf(" (%s) — Bağımlı değişken: %s: %s • dönüşüm: %s (formulde_trend = %s)",
                      k$ad, varsayilan(kay$kaynak, k$kaynak), varsayilan(kay$kod, k$kod),
                      varsayilan(k$donusum, "duzey"), toupper(CONFIG$model$formulde_trend)))
    })

    output$istatistikler <- renderUI({
      f <- fit(); s <- summary(f)
      d <- gosterge_verisi(veri(), input$gosterge, p_secili())
      fst <- s$fstatistic
      fp <- pf(fst[1], fst[2], fst[3], lower.tail = FALSE)
      tagList(
        stat_kutu("Örneklem (n)", nobs(f), sprintf("%s → %s", donem_kisa(min(d$tarih), input$gosterge),
                                                   donem_kisa(max(d$tarih), input$gosterge))),
        stat_kutu("Determinasyon (R²)", bicim(s$r.squared, 4), renk = "primary"),
        stat_kutu("Düzeltilmiş R²", bicim(s$adj.r.squared, 4), sprintf("k = %d", length(coef(f)) - 1)),
        stat_kutu("F-İstatistiği", bicim(fst[1], 1), if (fp < 1e-4) "p < 0.0001 (***)" else sprintf("p = %.4f", fp)),
        stat_kutu("Log-Likelihood", bicim(as.numeric(logLik(f))), sprintf("SD: %d", df.residual(f))),
        stat_kutu("Akaike IC (AIC)", bicim(AIC(f)), renk = "secondary"),
        stat_kutu("Schwarz IC (BIC)", bicim(BIC(f)), "Ceza: ln(n)", renk = "secondary"),
        stat_kutu("Varyans Tahmini", "Klasik EKK", "s² = e'e / (n − k)", renk = "tertiary"))
    })

    output$katsayilar <- DT::renderDT({
      m <- ct(); ci <- confint(fit())
      ad <- rownames(m)
      ad <- ifelse(ad == "(Intercept)", "Sabit Terim (c)",
                   ifelse(ad == "trend", "Trend (t)", sub("^.*_lag(\\d+)$", "y<sub>t-\\1</sub> (Gecikme \\1)", ad)))
      yildiz <- as.character(symnum(m[, 4], corr = FALSE, na = FALSE,
                                    cutpoints = c(0, .001, .01, .05, .1, 1),
                                    symbols = c("***", "**", "*", ".", " ")))
      p_metin <- ifelse(m[, 4] < 1e-4, "<0.0001", sprintf("%.4f", m[, 4]))
      d <- data.frame(Değişken = ad, `Katsayı (β)` = m[, 1], `Std. Hata` = m[, 2],
                      `t-Değeri` = m[, 3], `Pr(>|t|)` = paste(p_metin, yildiz),
                      `%95 Güven Aralığı` = sprintf("[%.3f, %.3f]", ci[, 1], ci[, 2]), check.names = FALSE)
      dt_tablo(d, sayfa = 20) |> DT::formatRound(2:4, 4)
    })

    output$artik_se <- renderText(sprintf("Artık Standart Hatası: %.3f (%d SD)",
                                          summary(fit())$sigma, df.residual(fit())))

    output$r_kodu_metin <- renderText({
      g <- input$gosterge
      paste0(
        "source('R/config.R'); source('R/utils.R'); source('R/api_functions.R')\n",
        "source('R/data.prep.R'); source('R/models.R')\n",
        "paket <- sonuclari_getir()\n",
        sprintf("fit <- basit_ar(paket$veri, \"%s\", p = %d)\n", g, p_secili()),
        "summary(fit)\n",
        "lmtest::bgtest(fit, order = 2); lmtest::bptest(fit)\n",
        "tseries::jarque.bera.test(resid(fit))\n",
        sprintf("tseries::adf.test(gosterge_serisi(paket$veri, \"%s\")$deger)\n", g),
        sprintf("s <- kayan_pencere_tahmin(paket$veri, \"%s\", pencere = %d, p = %d)\n", g,
                ozet_satir()$PENCERE, p_secili()),
        "metrikler(s)")
    })

    output$kalinti <- plotly::renderPlotly({
      e <- resid(fit()); sg <- sd(e)
      x <- utils::tail(gosterge_verisi(veri(), input$gosterge, p_secili())$tarih, length(e))
      plotly::plot_ly(x = x) |>
        plotly::add_bars(y = e, name = "ε_t", hovertemplate = "%{x|%Y-%m}: %{y:.3f}<extra></extra>",
                         marker = list(color = ifelse(abs(e) > 2 * sg, RENK$error, RENK$secondary))) |>
        plotly::layout(bargap = 0.1, shapes = lapply(c(-3, 3), function(k)
          list(type = "line", xref = "paper", x0 = 0, x1 = 1, y0 = k * sg, y1 = k * sg,
               line = list(color = RENK$primary, dash = "dot", width = 1)))) |>
        pl_tema(legend = FALSE)
    })

    output$carpiklik <- renderUI({
      e <- resid(fit()); z <- (e - mean(e)) / sd(e)
      rozet(sprintf("S: %.2f  •  K: %.2f", mean(z^3), mean(z^4)), tur = "secondary")
    })

    test_kart <- function(baslik, test_adi, durum, tur, satirlar, aciklama) {
      div(class = "test-kart",
          div(class = "d-flex justify-content-between align-items-start gap-2",
              div(etiket(baslik), tags$h4(test_adi)), rozet(durum, tur = tur)),
          lapply(names(satirlar), function(a) bilgi_satir(a, satirlar[[a]])),
          div(class = "test-aciklama", aciklama))
    }

    output$testler <- renderUI({
      f <- fit(); e <- resid(f)
      bg <- lmtest::bgtest(f, order = 2)
      bp <- lmtest::bptest(f)
      jb <- tseries::jarque.bera.test(e)
      adf <- suppressWarnings(tseries::adf.test(y()))
      tagList(
        test_kart("Otokorelasyon Testi", "Breusch-Godfrey LM",
                  if (bg$p.value > .05) "GEÇTİ (H₀ KABUL)" else "H₀ RED",
                  if (bg$p.value > .05) "basari" else "hata",
                  list("χ² İstatistiği" = bicim(bg$statistic, 3), "Gecikme" = "2",
                       "p-Değeri" = bicim(bg$p.value, 4)),
                  if (bg$p.value > .05) "Kalıntılarda 2. dereceye kadar seri korelasyon bulunmamaktadır."
                  else "Kalıntılarda seri korelasyon var; gecikme yapısı yetersiz olabilir."),
        test_kart("Değişen Varyans", "Breusch-Pagan",
                  if (bp$p.value > .05) "HOMOSKEDASTİK" else "DEĞİŞEN VARYANS",
                  if (bp$p.value > .05) "basari" else "hata",
                  list("BP LM İstatistiği" = bicim(bp$statistic, 3), "SD" = bp$parameter,
                       "p-Değeri" = bicim(bp$p.value, 4)),
                  if (bp$p.value > .05) "Sabit varyans varsayımı reddedilemiyor."
                  else "Değişen varyans tespit edildi; standart hatalar ve t-testleri temkinli yorumlanmalıdır."),
        test_kart("Normallik Testi", "Jarque-Bera",
                  if (jb$p.value > .05) "NORMAL" else "ASİMPTOTİK NORM",
                  if (jb$p.value > .05) "basari" else "secondary",
                  list("JB Değeri" = bicim(jb$statistic, 3), "Kritik Değer (%5)" = "5.991",
                       "p-Değeri" = bicim(jb$p.value, 4)),
                  sprintf("n = %d; %s", length(e), if (jb$p.value > .05) "kalıntılar normal dağılıma uyuyor."
                          else "kalın kuyruk mevcut; büyük örneklemde merkezi limit teoremine dayanılır.")),
        test_kart("Durağanlık (Birim Kök)", "Genişletilmiş Dickey-Fuller",
                  if (adf$p.value < .05) "DURAĞAN: I(0)" else "BİRİM KÖK: I(1)?",
                  if (adf$p.value < .05) "basari" else "hata",
                  list("Tau İstatistiği" = bicim(adf$statistic, 3), "Gecikme" = adf$parameter,
                       "p-Değeri" = if (adf$p.value <= .01) "≤ 0.01" else bicim(adf$p.value, 4)),
                  if (adf$p.value < .05) "Seri durağan kabul edilir; sahte regresyon riski düşüktür."
                  else "Seri durağan değil; fark alma (yillik_degisim dönüşümü) değerlendirilebilir.")
      )
    })

    oos <- reactive({
      w <- ozet_satir()$PENCERE
      req(length(w) == 1)
      s <- tryCatch(kayan_pencere_tahmin(veri(), input$gosterge, pencere = w, p = p_secili()),
                    error = function(e) NULL)
      shiny::validate(need(!is.null(s), sprintf("p=%d ile w=%d pencerede örnek dışı tahmin üretilemedi.", p_secili(), w)))
      list(m = metrikler(s), w = w, n = nrow(s))
    })

    output$oos <- renderUI({
      m <- oos()$m
      tagList(
        stat_kutu("MAE (Dış / İç)", bicim(m$MAE, 3), sprintf("İç (örnek içi): %s", bicim(m$IC_MAE, 3))),
        stat_kutu("MSE", bicim(m$MSE, 3), "Hata kareleri ortalaması"),
        stat_kutu("RMSE (Dış / İç)", bicim(m$RMSE, 3), sprintf("İç: %s", bicim(m$IC_RMSE, 3)), renk = "primary"),
        stat_kutu("MAPE (Dış / İç)", paste0("%", bicim(m$MAPE)), sprintf("İç: %%%s", bicim(m$IC_MAPE))),
        stat_kutu("Theil U", bicim(m$THEIL_U, 3), "U → 0 ideal", renk = "tertiary"))
    })

    output$asiri_uyum <- renderUI({
      m <- oos()$m
      sapma <- 100 * (m$RMSE - m$IC_RMSE) / m$IC_RMSE
      saglam <- sapma < 20
      div(class = "not-kutu",
          ikon("verified", 18, if (saglam) "text-tertiary-c" else "text-error-c"),
          div(tags$b("Aşırı Uyum (Overfitting) Kontrol Raporu: "),
              sprintf("Örnek içi RMSE (%.3f) ile örnek dışı RMSE (%.3f; w=%d, %d tahmin) arasındaki sapma %%%.1f. ",
                      m$IC_RMSE, m$RMSE, oos()$w, oos()$n, sapma),
              if (saglam) "%20 sınırının altında — model genellenebilir kabul edilir."
              else "%20 sınırının üzerinde — kayan pencere örnek dışında belirgin biçimde daha kötü."),
          rozet(if (saglam) "Sağlam (Robust)" else "Riskli", tur = if (saglam) "basari" else "hata"))
    })

    output$model_rds <- downloadHandler(
      function() sprintf("AR%d_%s.rds", p_secili(), input$gosterge),
      function(f) saveRDS(list(model = fit(), katsayi = ct(), oos = oos()), f))

    output$latex <- downloadHandler(
      function() sprintf("AR%d_%s.tex", p_secili(), input$gosterge),
      function(f) {
        m <- ct()
        satir <- sprintf("%s & %.4f & %.4f & %.3f & %.4f \\\\", gsub("_", "\\\\_", rownames(m)),
                         m[, 1], m[, 2], m[, 3], m[, 4])
        writeLines(c("\\begin{tabular}{lrrrr}", "\\hline",
                     "Değişken & $\\beta$ & Std. Hata & $t$ & $p$ \\\\", "\\hline",
                     satir, "\\hline", "\\end{tabular}"), f)
      })
  })
}
