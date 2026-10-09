#NOTE
model_ui <- function(id) {
  ns <- NS(id)
  tagList(
    div(class = "hero",
      div(class = "hero-sol",
        div(class = "d-flex gap-2 flex-wrap",
            rozet(tagList(ikon("model_training", 14), "BÖLÜM 2.5 - 2.7"), tur = "primary"),
            rozet("AR(p) Kayan Pencere Optimizasyonu")),
        tags$h1("Model Laboratuvarı & Çapraz Doğrulama Matrisi")),
      uiOutput(ns("optimum_ozet"), class = "d-flex gap-3 hero-sag")
    ),

    div(class = "lab-izgara",
      kart(class = "lab-panel",
        kart_baslik("tune", "Model Parametreleri", alt = "model_sec() — salt okunur"),
        selectInput(ns("gosterge"), "Seçili Makro Gösterge", gosterge_secenekleri(), width = "100%"),
        uiOutput(ns("p_adaylari"), class = "aday-izgara"),
        uiOutput(ns("parametreler")),
        div(class = "dipnot", "Eşitlik kuralı (model_sec): min RMSE → min(pencere) → min(p)")),

      div(class = "d-flex flex-column gap-3",
        kart(kart_baslik("show_chart", "AIC vs BIC Eğrisi", alt = "BİLGİ KRİTERLERİ DİNAMİĞİ • p_sec()"),
             plotly::plotlyOutput(ns("ic"), height = "250px"),
             div(class = "not-kutu", ikon("lightbulb", 18, "text-primary-c"), uiOutput(ns("ic_yorum")))),
        kart(kart_baslik("grid_on", "Örnek Dışı RMSE Isı Haritası (p × w Izgarası)",
                         alt = "ÇAPRAZ DOĞRULAMA (CROSS-VALIDATION) MATRİSİ",
                         sag = rozet("Kaynak: paket$cv (model_sec)", tur = "secondary")),
             plotly::plotlyOutput(ns("isi"), height = "360px"),
             div(class = "dipnot", textOutput(ns("izgara_not"), inline = TRUE))))
    ),

    kart(kart_baslik("ssid_chart", "Özyinelemeli Çok Adımlı Projeksiyon", alt = "BÖLÜM 2.7 • gelecek_tahmin()",
                     sag = uiOutput(ns("proj_rozet"))),
         div(class = "ikili-izgara genis-sol",
             plotly::plotlyOutput(ns("proj"), height = "340px"),
             uiOutput(ns("proj_tablo"), class = "proj-liste"))),

    kart(kart_baslik("waterfall_chart", "Zaman Boyunca AR Katsayı Kararlılığı",
                     alt = "KAYAN PENCERE DİNAMİĞİ (rolling_sonuclar)"),
         plotly::plotlyOutput(ns("katsayi"), height = "300px"),
         div(class = "not-kutu", ikon("menu_book", 18, "text-secondary-c"),
             div(tags$b("Kayan Pencere Formülasyonu — Pesaran & Timmermann (2007) • Rossi & Inoue (2012)"),
                 div(class = "kod-satir", "D_t = {y_{t-w+1}, …, y_t}   •   β̂_t = (X_t'X_t)⁻¹X_t'Y_t  ⟶  ",
                     "ŷ_{t+1|t} = X_{t+1}'β̂_t"),
                 "Her nokta ilgili pencerenin son dönemine ait AR(p) katsayısını gösterir; rejim sıçramaları ",
                 "yapısal kırılmaları yansıtır.")))
  )
}

model_server <- function(id, paket, secili) {
  moduleServer(id, function(input, output, session) {

    veri <- reactive({ req(paket()); paket()$veri })
    g <- reactive({ req(input$gosterge); input$gosterge })
    ozet_satir <- reactive({
      r <- paket()$ozet[paket()$ozet$gosterge == g(), ]
      shiny::validate(need(nrow(r) == 1, "Bu gösterge için model sonucu yok (günlüğe bakın)."))
      r
    })

    observeEvent(secili(), updateSelectInput(session, "gosterge", selected = secili()))

    ic <- reactive(tryCatch(p_sec(veri(), g(), "AIC"), error = function(e) NULL))

    output$p_adaylari <- renderUI({
      s <- ic(); req(s)
      t <- s$tablo
      a <- t[which.min(t$AIC), ]; b <- t[which.min(t$BIC), ]
      aday <- function(baslik, p, alt, tur)
        div(class = paste("aday", tur), etiket(baslik), div(class = "aday-p", sprintf("p = %d", p)),
            div(class = "stat-alt", alt))
      tagList(aday("VARSAYILAN", gosterge_p(g()), "gosterge_p()", "primary"),
              aday("AIC MİNİMUM", a$p, sprintf("AIC: %.1f", a$AIC), "secondary"),
              aday("BIC CEZALI", b$p, sprintf("BIC: %.1f", b$BIC), "tertiary"))
    })

    output$parametreler <- renderUI({
      r <- ozet_satir()
      fk <- frekans_ayari(gosterge_frekansi(g()))
      tagList(
        bilgi_satir("Seçilen gecikme (p*)", r$P),
        bilgi_satir("Kayan pencere (w*)", r$PENCERE),
        bilgi_satir("Değerlendirme penceresi (capraz_son_n)", fk$capraz_son_n),
        bilgi_satir("Pencere adayları", paste(gosterge_pencere_adaylari(g()), collapse = ", ")),
        bilgi_satir("Tahmin ufku (H)", r$UFUK),
        bilgi_satir("Seçim yöntemi", r$YONTEM),
        bilgi_satir("Örnek dışı tahmin sayısı", r$N_TAHMIN))
    })

    output$ic <- plotly::renderPlotly({
      s <- ic(); shiny::validate(need(!is.null(s), "Gecikme seçimi için veri yetersiz."))
      plotly::plot_ly(s$tablo, x = ~p) |>
        plotly::add_trace(y = ~AIC, name = "AIC = -2ln(L) + 2k", type = "scatter", mode = "lines+markers",
                          line = list(color = RENK$primary, width = 2.5), marker = list(color = RENK$primary)) |>
        plotly::add_trace(y = ~BIC, name = "BIC = -2ln(L) + k·ln(n)", type = "scatter", mode = "lines+markers",
                          line = list(color = RENK$secondary, width = 2.5), marker = list(color = RENK$secondary)) |>
        plotly::layout(xaxis = list(title = "p", dtick = 1), yaxis = list(title = "")) |>
        pl_tema()
    })

    output$ic_yorum <- renderUI({
      s <- ic(); req(s); t <- s$tablo; r <- ozet_satir()
      div(sprintf("AIC p=%d, BIC p=%d seçiyor (ortak örneklem, p_max=%d). ", t$p[which.min(t$AIC)],
                  t$p[which.min(t$BIC)], max(t$p)),
          sprintf("model_sec() bu adaylar + varsayılan p arasında örnek dışı RMSE ile p*=%d, w*=%d seçti.",
                  r$P, r$PENCERE))
    })

    izgara <- reactive({
      cv <- paket()$cv
      if (is.null(cv)) return(NULL)
      cv <- cv[cv$gosterge == g(), ]
      if (nrow(cv) == 0) NULL else cv
    })

    output$isi <- plotly::renderPlotly({
      z0 <- izgara()
      shiny::validate(need(!is.null(z0), "Bu gösterge için çapraz doğrulama tablosu yok (yöntem: varsayılan)."))
      ps <- sort(unique(z0$p)); ws <- sort(unique(z0$pencere))
      z <- matrix(NA_real_, length(ps), length(ws))
      z[cbind(match(z0$p, ps), match(z0$pencere, ws))] <- z0$RMSE
      metin <- matrix(ifelse(is.na(z), "—", sprintf("%.3g", z)), nrow = nrow(z))
      o <- z0[z0$secildi, ]
      if (nrow(o)) metin[match(o$p, ps), match(o$pencere, ws)] <- sprintf("★ %.3g", o$RMSE)
      plotly::plot_ly(x = paste0("w=", ws), y = paste0("p=", ps), z = z, type = "heatmap",
                      text = metin, texttemplate = "%{text}",
                      hovertemplate = "%{y}, %{x}<br>RMSE: %{z:.4f}<extra></extra>",
                      colorscale = list(c(0, RENK$tertiary), c(0.5, "#4f2fa0"), c(1, RENK$error)),
                      xgap = 3, ygap = 3, colorbar = list(title = "RMSE", len = 0.8)) |>
        plotly::layout(xaxis = list(type = "category"), yaxis = list(type = "category")) |>
        pl_tema(legend = FALSE)
    })

    output$izgara_not <- renderText({
      z <- izgara(); req(z)
      o <- z[z$secildi, ]
      sprintf("Toplam %d model kombinasyonu • optimum p=%d, w=%d (RMSE %.4f) • eşitlikte kısa pencere ve düşük p.",
              nrow(z), o$p, o$pencere, o$RMSE)
    })

    output$optimum_ozet <- renderUI({
      r <- ozet_satir()
      birim <- switch(gosterge_frekansi(g()), aylik = "Ay", ceyreklik = "Çeyrek", "Yıl")
      tagList(
        stat_kutu("OPTİMAL SEÇİLEN ÇİFT", sprintf("p* = %d | w* = %d %s", r$P, r$PENCERE, birim),
                  r$YONTEM, renk = "primary"),
        stat_kutu("RMSE (TEST)", bicim(r$RMSE, 3), sprintf("MAPE %%%s • Theil U %s", bicim(r$MAPE),
                                                            bicim(r$THEIL_U, 3)), renk = "tertiary"))
    })

    fan <- reactive({
      f <- paket()$gelecek
      f <- f[f$gosterge == g(), ]
      shiny::validate(need(nrow(f) > 0, "Bu gösterge için ileriye dönük tahmin yok."))
      f
    })

    output$proj_rozet <- renderUI({
      r <- ozet_satir(); d <- gosterge_serisi(veri(), g())
      div(class = "d-flex gap-2 flex-wrap",
          rozet(sprintf("Model: AR(%d) | w=%d | H=%d", r$P, r$PENCERE, r$UFUK), tur = "primary"),
          rozet(sprintf("Baz: %s (%s)", donem_etiketi(max(d$tarih), gosterge_frekansi(g())),
                        deger_bicim(utils::tail(d$deger, 1), g()))))
    })

    output$proj <- plotly::renderPlotly({
      f <- fan()
      d <- utils::tail(gosterge_serisi(veri(), g()), 4 * nrow(f))
      plotly::plot_ly() |>
        plotly::add_ribbons(data = f, x = ~tarih, ymin = ~alt, ymax = ~ust,
                            name = sprintf("%%%d Güven", round(100 * CONFIG$model$guven_duzeyi)),
                            line = list(width = 0), fillcolor = "rgba(207,189,255,0.25)") |>
        plotly::add_lines(data = d, x = ~tarih, y = ~deger, name = "Gerçekleşen",
                          line = list(color = RENK$metin, width = 2)) |>
        plotly::add_trace(data = f, x = ~tarih, y = ~tahmin, name = "Nokta Tahmin", type = "scatter",
                          mode = "lines+markers", line = list(color = RENK$primary, width = 2.5),
                          marker = list(color = RENK$primary, size = 7)) |>
        pl_tema()
    })

    output$proj_tablo <- renderUI({
      f <- fan()
      lapply(seq_len(nrow(f)), function(h)
        div(class = "proj-satir",
            div(etiket(sprintf("t+%d • %s", h, donem_etiketi(f$tarih[h], gosterge_frekansi(g())))),
                div(class = "stat-alt", sprintf("[%s – %s]", bicim(f$alt[h]), bicim(f$ust[h])))),
            div(class = "text-end", tags$b(deger_bicim(f$tahmin[h], g())),
                div(class = "stat-alt", sprintf("±%s", bicim((f$ust[h] - f$alt[h]) / 2))))))
    })

    # 1-Config NOTE2.R'deki rolling_sonuclar: her pencerenin son dönemine ait katsayılar
    output$katsayi <- plotly::renderPlotly({
      r <- ozet_satir(); p <- r$P; w <- r$PENCERE
      d <- gosterge_verisi(veri(), g(), p)
      shiny::validate(need(nrow(d) > w && w > p + 1, "Veri seçilen pencereden kısa."))
      lag_ad <- paste0(g(), "_lag", seq_len(p))
      form <- formul_kur(g(), lag_ad)
      bas <- max(1, nrow(d) - w - 120 + 1)
      k <- do.call(rbind, lapply(bas:(nrow(d) - w + 1), function(b) {
        alt <- d[b:(b + w - 1), ]
        kt <- stats::coef(lm(form, data = alt))
        data.frame(tarih = alt$tarih[w], phi1 = kt[lag_ad[1]], phip = kt[lag_ad[p]])
      }))
      pl <- plotly::plot_ly(k, x = ~tarih) |>
        plotly::add_lines(y = ~phi1, name = "φ1 (Kalıcılık)", line = list(color = RENK$primary, width = 2))
      if (p > 1)
        pl <- plotly::add_lines(pl, y = ~phip, name = sprintf("φ%d (%s)", p,
                                                              if (p == 12) "Mevsimsellik" else "son gecikme"),
                                line = list(color = RENK$tertiary, width = 2))
      pl_tema(pl)
    })
  })
}
