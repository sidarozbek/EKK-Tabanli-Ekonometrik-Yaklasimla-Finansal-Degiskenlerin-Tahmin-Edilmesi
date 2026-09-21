# =============================================================================
# app/app.R — Arayüz (shinydashboard + plotly + DT + shinyWidgets)
# -----------------------------------------------------------------------------
# Sonucu bir insanın diline çevirir: teknik bilgi gerektirmeden göstergeleri
# izlemek, bir sonraki dönemin tahminlerini görmek, istenen dönemin tahminini
# takvimden seçmek ve verileri güncellemek.
#
# TASARIM İLKESİ: Modelin teknik ayarları (pencere, tahmin ufku, p, çapraz
# doğrulama) arayüzde SEÇTİRİLMEZ. Sistem, her veri için config'te tanımlı
# ayarlarla otomatik tahmin yapar; kullanılan değerler yalnızca BİLGİ olarak
# gösterilir. Kullanıcı yalnızca ne görmek istediğini seçer: hangi grafikler
# (Genel Bakış) ve hangi dönemin tahmini (Tahmin, takvim).
#
# Çalıştırma:   shiny::runApp("app")     (proje kökünden ya da app/ içinden)
# =============================================================================

# --- Paketler -----------------------------------------------------------------
# install.packages(c("shiny", "shinydashboard", "shinyWidgets", "plotly", "DT"))
suppressPackageStartupMessages({
  library(shiny)
  library(shinydashboard)
  library(shinyWidgets)
  library(plotly)
  library(DT)
})

# --- Motoru yükle -------------------------------------------------------------
# Proje kökü: çalışma dizininden yukarı doğru "R/config.R" aranır (shiny::runApp
# çalışma dizinini app/ yapar). setwd() KULLANILMAZ; yollar config'te mutlaktır.
kok_bul <- function() {
  d <- normalizePath(getwd(), winslash = "/", mustWork = FALSE)
  repeat {
    if (file.exists(file.path(d, "R", "config.R"))) return(d)
    ust <- dirname(d)
    if (identical(ust, d)) stop("Proje kökü bulunamadı (R/config.R yok)")
    d <- ust
  }
}
.kok <- kok_bul()
for (.dosya in c("config", "utils", "api_functions", "data.prep", "models")) {
  source(file.path(.kok, "R", paste0(.dosya, ".R")), encoding = "UTF-8")
}

# jsonlite (api_functions.R) da bir validate() dışa aktarır ve shiny'ninkini
# gölgeler; öneksiz kullanımda "is.character(txt) is not TRUE" hatası çıkar.
validate <- shiny::validate
# httr (api_functions.R) de bir config() dışa aktarır; plotly::config'i gölgeler.
# Grafiklerde her zaman plotly::config(...) yazılır.

# --- Başlangıç verisi ---------------------------------------------------------
# Taze kayıt varsa okunur; yoksa (ve güncelleme açıksa) kaynaklardan çekilip hesaplanır.
baslangic <- sonuclari_getir(FALSE)

# =============================================================================
# YARDIMCILAR
# =============================================================================

renkler_rol <- c(bagimli = "#1f6fb2", kontrol = "#e08a1e", ek = "#7a8b99")

#' Gösterge menüsü seçenekleri: role göre gruplu, okunur adlı
gosterge_secenekleri <- function(ozet) {
  sonuc <- list()
  for (rol in names(CONFIG$sunum$roller)) {
    g <- ozet$gosterge[ozet$rol == rol]
    if (length(g) > 0) sonuc[[CONFIG$sunum$roller[[rol]]]] <- setNames(g, sapply(g, gosterge_etiketi))
  }
  sonuc
}

#' Sayıyı okunur biçime getir (çok büyük/küçük değerlerde bilimsel gösterim)
sayi_bicimle <- function(x, basamak = 2) {
  ifelse(is.na(x), "-",
         ifelse(abs(x) >= 1e6 | (abs(x) < 0.01 & x != 0), formatC(x, format = "e", digits = 2),
                formatC(x, format = "f", digits = basamak, big.mark = ".", decimal.mark = ",")))
}

#' Göstergenin biriminde değer metni ("30,7 %", "48,5 TL")
deger_metni <- function(g, x) {
  b <- CONFIG$gostergeler[[g]][["birim"]]
  paste0(sayi_bicimle(x), if (!is.null(b)) paste0(" ", b) else "")
}

#' Genel Bakış için varsayılan grafik seçimi (config'ten, mevcut olanlar)
genel_baslangic_secimi <- function(ozet) {
  s <- intersect(CONFIG$sunum$genel_varsayilan, ozet$gosterge)
  if (length(s) == 0) s <- utils::head(ozet$gosterge, CONFIG$sunum$genel_azami)
  utils::head(s, CONFIG$sunum$genel_azami)
}

# =============================================================================
# GÖRÜNEN KISIM (UI) — "neyin nerede durduğu"
# =============================================================================
ui <- dashboardPage(
  skin = "blue",

  dashboardHeader(title = "Ekonomik Tahmin", titleWidth = 230),

  dashboardSidebar(
    width = 230,
    sidebarMenu(
      id = "sekme",
      menuItem("Genel Bakış",         tabName = "genel",         icon = icon("home")),
      menuItem("Tahmin",              tabName = "tahmin",        icon = icon("chart-line")),
      menuItem("Model Karşılaştırma", tabName = "karsilastirma", icon = icon("table")),
      menuItem("Veri ve Metaveri",    tabName = "veri",          icon = icon("database")),
      menuItem("Metodoloji",          tabName = "metod",         icon = icon("book"))
    ),
    div(style = "padding: 12px 15px;",
        actionButton("guncelle", "Tüm verileri güncelle", icon = icon("sync"), width = "100%"),
        tags$p(style = "margin-top: 10px; font-size: 12px; opacity: .8;",
               textOutput("son_guncelleme", inline = TRUE)))
  ),

  dashboardBody(
    tags$head(tags$style(HTML("
      .content { padding: 10px; }
      .box { margin-bottom: 10px; }
      .box-title { font-weight: 600; }
      .uyari-etiket { background:#fff3cd; color:#7a5b00; padding:2px 8px; border-radius:10px; font-size:12px; }
      .tamam-etiket { background:#d9f2e3; color:#0d5c2e; padding:2px 8px; border-radius:10px; font-size:12px; }
      .bilgi-satir { margin: 3px 0; font-size: 12.5px; color:#4b5563; }
      .bilgi-kutu { background:#f5f7fa; border-radius:6px; padding:8px 10px; margin-top:10px; }

      /* Genel Bakış kartı */
      .gb-kart { background:#fff; border-radius:6px; border-top:3px solid #1f6fb2; padding:10px 12px 6px; margin-bottom:10px; }
      .gb-baslik { font-size:13px; color:#4b5563; margin:0 0 2px 0; }
      .gb-donem  { font-size:12px; color:#6b7280; }
      .gb-deger  { font-size:26px; font-weight:700; line-height:1.15; color:#111827; }
      .gb-fark   { font-size:13px; margin-left:6px; color:#6b7280; font-weight:400; }
      .gb-alt    { font-size:11.5px; color:#9ca3af; margin-top:2px; }

      /* Tahmin takvimi (dönem seçici) */
      .takvim { max-width: 340px; }
      .takvim-ust { display:flex; justify-content:space-between; align-items:center; margin-bottom:8px; font-weight:600; }
      .yil-ok { border:1px solid #cbd5e1; background:#fff; border-radius:6px; width:34px; height:30px; cursor:pointer; }
      .yil-ok:disabled { background:#eceff3; color:#a6afbb; cursor:not-allowed; }
      .takvim-izgara { display:grid; grid-template-columns: repeat(4, 1fr); gap:6px; }
      .ay-dugme { border:1px solid #cbd5e1; background:#fff; border-radius:6px; padding:9px 0; cursor:pointer; font-size:13px; }
      .ay-dugme.gelecek { border-color:#e08a1e; }
      .ay-dugme.secili  { background:#1f6fb2; color:#fff; border-color:#1f6fb2; }
      .ay-dugme.pasif, .ay-dugme:disabled { background:#eceff3; color:#a6afbb; border-color:#eceff3; cursor:not-allowed; }
      .takvim-not { font-size:11.5px; color:#6b7280; margin-top:8px; }
      .nokta { display:inline-block; width:9px; height:9px; border-radius:2px; margin-right:4px; vertical-align:middle; }

      .sonuc-donem { font-size:13px; color:#6b7280; }
      .sonuc-deger { font-size:30px; font-weight:700; color:#111827; line-height:1.15; }
      .sonuc-alt   { font-size:13px; color:#6b7280; }

      @media (max-width: 767px) {
        .content { padding: 6px; }
        .gb-deger { font-size:22px; }
        .sonuc-deger { font-size:24px; }
        .takvim { max-width: 100%; }
      }
    "))),

    tabItems(

      # ---- Genel Bakış -------------------------------------------------------
      # Az, seçilebilir grafik; bir sonraki dönemin tahmini görünür.
      tabItem(tabName = "genel",
        pickerInput("genel_secim", "Gösterilecek grafikler",
                    choices = gosterge_secenekleri(baslangic$ozet), multiple = TRUE,
                    selected = genel_baslangic_secimi(baslangic$ozet), width = "100%",
                    options = list(`max-options` = CONFIG$sunum$genel_azami,
                                   `max-options-text` = paste0("En fazla ", CONFIG$sunum$genel_azami, " grafik"),
                                   `selected-text-format` = "count > 2",
                                   `count-selected-text` = "{0} grafik seçili",
                                   `none-selected-text` = "Grafik seçin",
                                   `live-search` = TRUE)),
        uiOutput("genel_alan")
      ),

      # ---- Tahmin ------------------------------------------------------------
      tabItem(tabName = "tahmin",
        fluidRow(
          column(width = 4,
            box(title = "Gösterge ve dönem", width = NULL, status = "primary", solidHeader = TRUE,
                pickerInput("gosterge", NULL, choices = gosterge_secenekleri(baslangic$ozet),
                            width = "100%", options = list(`live-search` = TRUE)),
                uiOutput("takvim"),
                uiOutput("gosterge_bilgi"),
                br(),
                actionButton("gosterge_guncelle", "Bu göstergeyi güncelle", icon = icon("sync"),
                             class = "btn-sm"))),
          column(width = 8,
            box(title = textOutput("grafik_baslik", inline = TRUE), width = NULL,
                status = "primary", solidHeader = TRUE,
                uiOutput("secili_sonuc"),
                plotlyOutput("grafik", height = 380)))
        ),
        fluidRow(
          column(width = 6,
            box(title = "Tahmin tablosu", width = NULL,
                DTOutput("tablo_gelecek"), br(), downloadButton("indir", "CSV indir"))),
          column(width = 6,
            box(title = "Başarı ölçümleri", width = NULL, collapsible = TRUE, collapsed = TRUE,
                tableOutput("metrikler"),
                helpText("Örnek dışı: her dönem, yalnız o dönemden ÖNCEKİ pencereyle kurulan modelin tek adım ilerisi tahmini.",
                         "Örnek içi: pencerelerin eğitim örneğindeki uyum.")))
        )
      ),

      # ---- Model Karşılaştırma -----------------------------------------------
      tabItem(tabName = "karsilastirma",
        fluidRow(
          box(title = "Tüm göstergeler", width = 12, status = "primary", solidHeader = TRUE,
              DTOutput("tablo_ozet"))
        ),
        fluidRow(
          box(title = "Karşılaştırma grafiği", width = 12,
              fluidRow(
                column(4, selectInput("olcu", "Ölçü",
                                      choices = c("Göreli RMSE (naif = 1)" = "GORELI_RMSE",
                                                  "MAPE (%)" = "MAPE", "Theil U" = "THEIL_U"))),
                column(8, checkboxGroupInput("roller", "Gruplar", inline = TRUE,
                                             choices = setNames(names(CONFIG$sunum$roller),
                                                                unlist(CONFIG$sunum$roller)),
                                             selected = names(CONFIG$sunum$roller)))),
              plotlyOutput("karsilastirma_grafik", height = 420),
              helpText("RMSE/MAE göstergenin biriminde olduğu için göstergeler arası karşılaştırmada",
                       "ölçekten bağımsız ölçüler (Göreli RMSE, MAPE, Theil U) kullanılır."))
        )
      ),

      # ---- Veri ve Metaveri --------------------------------------------------
      tabItem(tabName = "veri",
        fluidRow(
          box(title = "Metaveri: kaynak önceliği, birincil yedek ve kullanılan kaynak", width = 12,
              status = "primary", solidHeader = TRUE,
              DTOutput("tablo_meta"),
              helpText("Her verinin kaynak öncelik sırası ve BİRİNCİL YEDEĞİ ayrı ayrı tanımlıdır;",
                       "güncelleme bu sırayla ilerler. \"CSV_YEDEK\": API'ler erişilemezse kullanılan yerel yedek kanal.",
                       "Yedek kaynak kullanıldıysa (sarı) tanım/ölçek farkı olabilir; \"Yaklaşık\" yedek asıl seriye yakın ama aynı tanımda değildir."))
        ),
        fluidRow(
          box(title = "Veri kalite raporu", width = 12, status = "primary", solidHeader = TRUE,
              DTOutput("tablo_kalite"),
              helpText("Sapan sayısı: Hampel filtresiyle işaretlenen şüpheli gözlemler (veri değiştirilmez).",
                       "Gecikme ve eksik oran, göstergenin KENDİ frekansındaki dönem cinsindendir."))
        )
      ),

      # ---- Metodoloji --------------------------------------------------------
      tabItem(tabName = "metod",
        withMathJax(),
        box(title = "Yöntem", width = 12, status = "primary", solidHeader = TRUE,
          h4("Otoregresif model AR(p) ve EKK"),
          p("Bir göstergenin değeri, kendi geçmiş değerlerinin doğrusal bir fonksiyonu olarak modellenir:"),
          p("$$y_t = c + \\varphi_1 y_{t-1} + \\varphi_2 y_{t-2} + \\dots + \\varphi_p y_{t-p} + \\varepsilon_t$$"),
          p("Parametreler En Küçük Kareler (EKK) ile tahmin edilir:"),
          p("$$\\hat\\beta = (X'X)^{-1}X'Y$$"),
          h4("Frekans"),
          p("Her gösterge KENDİ frekansında (aylık, çeyreklik ya da yıllık) işlenir ve tahmin edilir.",
            "Çeyreklik ve yıllık seriler aylığa yayılmaz; pencere ve tahmin ufku o frekansın dönem sayısıdır."),
          h4("Kayan pencere"),
          p("Yapısal kırılmalara uyum için sabit parametreli tek model yerine, her t anında yalnızca",
            "son \\(w\\) dönemlik pencere kullanılır; model her adımda yeniden kurulur ve t+1 dönemi tahmin edilir.",
            "Tahmin edilen dönem hiçbir zaman eğitime girmez."),
          h4("Model ve pencere seçimi: çapraz doğrulama"),
          p("Her veri güncellendiğinde, o verinin aday pencereleri (aylıkta 36, 42, 48, 54, 60; diğer frekanslarda kendi adayları)",
            "ve aday gecikme sayıları (verinin varsayılan p'si, AIC ve BIC ile seçilenler) kayan-orijinli çapraz doğrulamayla",
            "karşılaştırılır; ortak son dönemlerde tek adım ilerisi tahmin hatası (RMSE) en düşük olan model ve pencere seçilir."),
          p("$$AIC = -2\\ln L + 2k \\qquad BIC = -2\\ln L + k\\ln n$$"),
          p("Seçilen değerler ve tahmin ufku her tahminin yanında bilgi olarak gösterilir; arayüzden değiştirilmez."),
          h4("Başarı ölçüleri"),
          p("$$MAE=\\tfrac{1}{n}\\sum|y_t-\\hat y_t| \\quad MSE=\\tfrac{1}{n}\\sum(y_t-\\hat y_t)^2 \\quad RMSE=\\sqrt{MSE}$$"),
          p("$$MAPE=\\tfrac{100}{n}\\sum\\left|\\tfrac{y_t-\\hat y_t}{y_t}\\right| \\quad U=\\tfrac{\\sqrt{\\sum(\\hat y_t-y_t)^2}}{\\sqrt{\\sum y_t^2}}$$"),
          p("Göreli RMSE, modelin RMSE'sinin \"bir önceki değeri tekrarla\" (naif) tahmininin RMSE'sine oranıdır."),
          h4("Veri ve sınırlamalar"),
          tags$ul(
            tags$li("Kaynaklar: FRED, TCMB EVDS, OECD, Dünya Bankası, Borsa İstanbul (Yahoo Finance)."),
            tags$li("Her verinin kaynak önceliği ayrıdır: asıl kaynak, birincil yedek ve sonraki yedekler; son kanal yerel CSV yedeğidir."),
            tags$li("Enflasyon ve büyüme, endeks/tutar serilerinin yıllık yüzde değişimi olarak modellenir."),
            tags$li("Yedek kaynağa geçildiğinde bu durum Veri ve Metaveri sekmesinde işaretlenir."),
            tags$li("Denge göstergelerinde (cari, bütçe, dış ticaret) ve sıfır civarında seyreden serilerde MAPE yanıltıcıdır."),
            tags$li("İleriye dönük güven bandı yaklaşıktır (parametre belirsizliği dahil değildir).")
          ),
          hr(),
          p(tags$small(paste0(CONFIG$proje$program, " · ", CONFIG$proje$kurum, " · sürüm ", CONFIG$proje$surum)))
        )
      )
    )
  )
)

# =============================================================================
# ÇALIŞAN KISIM (SERVER) — "işin nasıl yapıldığı"
# =============================================================================
server <- function(input, output, session) {

  # ---- Ortak durum: güncelleme düğmeleri bunu yeniler -------------------------
  durum <- reactiveValues(veri = baslangic$veri, ozet = baslangic$ozet, gelecek = baslangic$gelecek,
                          gecmis = baslangic$gecmis, cv = baslangic$cv, meta = baslangic$meta,
                          kalite = baslangic$kalite, zaman = baslangic$zaman)

  paketi_uygula <- function(p) {
    durum$veri <- p$veri; durum$ozet <- p$ozet; durum$gelecek <- p$gelecek; durum$gecmis <- p$gecmis
    durum$cv <- p$cv; durum$meta <- p$meta; durum$kalite <- p$kalite; durum$zaman <- p$zaman
    updatePickerInput(session, "gosterge", choices = gosterge_secenekleri(p$ozet), selected = isolate(input$gosterge))
    updatePickerInput(session, "genel_secim", choices = gosterge_secenekleri(p$ozet), selected = isolate(input$genel_secim))
  }

  output$son_guncelleme <- renderText({
    paste("Son hesaplama:", format(durum$zaman, "%d.%m.%Y %H:%M"))
  })

  # ---- Tüm verileri güncelle ---------------------------------------------------
  observeEvent(input$guncelle, {
    sonuc <- withProgress(message = "Veriler kaynak önceliklerine göre çekiliyor, modeller kuruluyor...",
                          value = 0.3, tryCatch(calistir_hepsi(yenile = TRUE), error = function(e) e))
    if (inherits(sonuc, "error")) {
      showNotification(paste("Güncelleme başarısız:", conditionMessage(sonuc)), type = "error", duration = 10)
      return()
    }
    paketi_uygula(sonuc)
    n_yedek <- sum(sonuc$meta$yedek_kullanildi %in% TRUE)
    showNotification(paste0("Güncellendi: ", nrow(sonuc$ozet), " gösterge",
                            if (n_yedek > 0) paste0(" (", n_yedek, " tanesi yedek kaynaktan)") else ""),
                     type = "message")
  })

  # ---- Tek göstergeyi güncelle (verinin kendi ayarlarıyla) ---------------------
  observeEvent(input$gosterge_guncelle, {
    g <- req(input$gosterge)
    sonuc <- withProgress(message = paste("Güncelleniyor:", gosterge_etiketi(g)), value = 0.3,
                          tryCatch(gosterge_guncelle(g), error = function(e) e))
    if (inherits(sonuc, "error")) {
      showNotification(paste("Güncelleme başarısız:", conditionMessage(sonuc)), type = "error", duration = 10)
      return()
    }
    paketi_uygula(sonuc)
    showNotification(paste("Güncellendi:", gosterge_etiketi(g)), type = "message")
  })

  # ===========================================================================
  # GENEL BAKIŞ — seçilen grafikler ve bir sonraki dönemin tahmini
  # ===========================================================================
  genel_gostergeler <- reactive({
    utils::head(intersect(input$genel_secim, durum$ozet$gosterge), CONFIG$sunum$genel_azami)
  })

  # Bir göstergenin ilk tahmin dönemi, değeri ve son gerçek değere göre değişimi
  sonraki_tahmin <- function(g) {
    f <- durum$gelecek[durum$gelecek$gosterge == g, ]
    s <- gosterge_serisi(durum$veri, g); s <- s[s$gercek, ]
    if (nrow(f) == 0 || nrow(s) == 0) return(NULL)
    list(tarih = f$tarih[1], tahmin = f$tahmin[1], fark = f$tahmin[1] - utils::tail(s$deger, 1))
  }

  output$genel_alan <- renderUI({
    g_liste <- genel_gostergeler()
    validate(need(length(g_liste) > 0, "Görmek istediğiniz göstergeleri yukarıdan seçin."))
    kartlar <- lapply(g_liste, function(g) {
      f_ad <- gosterge_frekansi(g); fk <- frekans_ayari(f_ad)
      o <- durum$ozet[durum$ozet$gosterge == g, ]
      n <- sonraki_tahmin(g)
      div(class = "col-xs-12 col-md-6",
        div(class = "gb-kart",
          p(class = "gb-baslik", gosterge_etiketi(g)),
          if (!is.null(n)) tagList(
            div(class = "gb-donem", paste("Sonraki dönem ·", donem_etiketi(n$tarih, f_ad))),
            div(class = "gb-deger", deger_metni(g, n$tahmin),
                span(class = "gb-fark", paste0(if (n$fark >= 0) "▲ " else "▼ ", sayi_bicimle(abs(n$fark)))))),
          plotlyOutput(paste0("genel_g_", g), height = "210px"),
          div(class = "gb-alt", paste0(fk$etiket, " · Pencere: ", o$PENCERE, " ", fk$birim,
                                       " · Tahmin ufku: ", o$UFUK, " ", fk$birim))))
    })
    fluidRow(kartlar)
  })

  observe({
    for (g in genel_gostergeler()) local({
      gg <- g
      output[[paste0("genel_g_", gg)]] <- renderPlotly({
        s <- gosterge_serisi(durum$veri, gg)
        f <- durum$gelecek[durum$gelecek$gosterge == gg, ]
        o <- durum$ozet[durum$ozet$gosterge == gg, ]
        s <- utils::tail(s, max(24, 2 * o$UFUK + 12))                       # kısa geçmiş: sade grafik
        plot_ly() %>%
          add_lines(data = s, x = ~tarih, y = ~deger, name = "Gerçek", line = list(color = "#1f2d3d", width = 1.6)) %>%
          add_ribbons(data = f, x = ~tarih, ymin = ~alt, ymax = ~ust, name = "Bant", showlegend = FALSE,
                      fillcolor = "rgba(224,138,30,0.22)", line = list(color = "transparent")) %>%
          add_lines(data = f, x = ~tarih, y = ~tahmin, name = "Tahmin", line = list(color = "#e08a1e", width = 2.4)) %>%
          add_markers(data = f[1, ], x = ~tarih, y = ~tahmin, name = "Sonraki", showlegend = FALSE,
                      marker = list(color = "#e08a1e", size = 9)) %>%
          layout(showlegend = FALSE, hovermode = "x unified", xaxis = list(title = "", showgrid = FALSE),
                 yaxis = list(title = "", zeroline = FALSE), margin = list(l = 40, r = 8, t = 4, b = 24)) %>%
          plotly::config(displayModeBar = FALSE)
      })
    })
  })

  # ===========================================================================
  # TAHMİN — gösterge + takvim
  # ===========================================================================

  # Seçilebilir dönemler: bu göstergenin tahmin kapsamı (geçmişe dönük + ileriye dönük).
  # Frekansa göre otomatik daralır: çeyreklikte yalnız çeyrek başı, yıllıkta yalnız yıl başı.
  secilebilir <- reactive({
    g <- req(input$gosterge)
    sort(unique(c(durum$gecmis$tarih[durum$gecmis$gosterge == g],
                  durum$gelecek$tarih[durum$gelecek$gosterge == g])))
  })
  gelecek_tarihleri <- reactive({
    g <- req(input$gosterge); durum$gelecek$tarih[durum$gelecek$gosterge == g]
  })

  # Varsayılan dönem HER ZAMAN aynı kuralla seçilir: içinde bulunulan ay; o gösterge için
  # seçilemiyorsa ondan sonraki ilk seçilebilir dönem (yoksa en son dönem).
  varsayilan_donem <- function(sec) {
    ref <- as.Date(format(Sys.Date(), "%Y-%m-01"))
    ileri <- sec[sec >= ref]
    if (length(ileri) > 0) min(ileri) else max(sec)
  }

  secili_donem  <- reactiveVal(NULL)
  takvim_yili   <- reactiveVal(NULL)
  son_gosterge  <- reactiveVal(NULL)

  # Gösterge değişince varsayılan döneme dön; aynı göstergede veri güncellenirse seçimi koru.
  observeEvent(list(input$gosterge, durum$gelecek), {
    sec <- secilebilir(); req(length(sec) > 0)
    onceki <- secili_donem()
    yeni <- if (identical(son_gosterge(), input$gosterge) && !is.null(onceki) && onceki %in% sec) onceki
            else varsayilan_donem(sec)
    son_gosterge(input$gosterge); secili_donem(yeni)
    takvim_yili(as.integer(format(yeni, "%Y")))
  })

  # Seçilemeyen (gri) dönemler sunucuda da reddedilir: yalnız tahmin kapsamındakiler seçilebilir.
  observeEvent(input$secili_donem, {
    d <- tryCatch(as.Date(input$secili_donem), error = function(e) NA)
    if (!is.na(d) && d %in% secilebilir()) secili_donem(d)
  })
  observeEvent(input$yil_yon, {
    yillar <- as.integer(format(secilebilir(), "%Y"))
    y <- takvim_yili() + input$yil_yon
    if (y >= min(yillar) && y <= max(yillar)) takvim_yili(y)
  })

  output$takvim <- renderUI({
    req(input$gosterge); sec <- secilebilir(); yil <- req(takvim_yili()); secili <- secili_donem()
    gel <- gelecek_tarihleri()
    yillar <- as.integer(format(sec, "%Y"))
    ay_adlari <- c("Oca", "Şub", "Mar", "Nis", "May", "Haz", "Tem", "Ağu", "Eyl", "Eki", "Kas", "Ara")
    tuslar <- lapply(1:12, function(m) {
      t <- as.Date(sprintf("%d-%02d-01", yil, m))
      uygun <- t %in% sec
      sinif <- paste("ay-dugme", if (uygun && t %in% gel) "gelecek",
                     if (uygun && !is.null(secili) && t == secili) "secili", if (!uygun) "pasif")
      tags$button(type = "button", class = sinif, disabled = if (!uygun) NA else NULL,
                  onclick = if (uygun) sprintf("Shiny.setInputValue('secili_donem','%s',{priority:'event'})", format(t)) else NULL,
                  ay_adlari[m])
    })
    yil_ok <- function(yon, etiket, kapali) {
      tags$button(type = "button", class = "yil-ok", disabled = if (kapali) NA else NULL,
                  onclick = sprintf("Shiny.setInputValue('yil_yon',%d,{priority:'event'})", yon), etiket)
    }
    div(class = "takvim", style = "margin-top:10px;",
      div(class = "takvim-ust", yil_ok(-1L, "‹", yil <= min(yillar)), span(yil), yil_ok(1L, "›", yil >= max(yillar))),
      div(class = "takvim-izgara", tuslar),
      div(class = "takvim-not",
          span(class = "nokta", style = "background:#1f6fb2;"), "seçili  ",
          span(class = "nokta", style = "border:1.5px solid #e08a1e;background:#fff;"), "ileriye tahmin  ",
          span(class = "nokta", style = "background:#eceff3;"), "seçilemez"))
  })

  output$gosterge_bilgi <- renderUI({
    g <- req(input$gosterge)
    m <- durum$meta[durum$meta$gosterge == g, ]; o <- durum$ozet[durum$ozet$gosterge == g, ]
    f_ad <- gosterge_frekansi(g); fk <- frekans_ayari(f_ad)
    yedek <- isTRUE(m$yedek_kullanildi[1]); sorun <- m$durum[1] %in% c("bayat_cache", "csv_yedek")
    div(class = "bilgi-kutu",
      div(class = "bilgi-satir", strong("Frekans: "), fk$etiket, " · ", strong("Pencere: "), o$PENCERE, " ", fk$birim,
          " · ", strong("Ufuk: "), o$UFUK, " ", fk$birim),
      div(class = "bilgi-satir", strong("Model: "), paste0("AR(", o$P, ")"), " · ", o$YONTEM),
      div(class = "bilgi-satir", strong("Kaynak: "), m$kaynak[1], " · ", tags$code(varsayilan(m$kod[1], "-"))),
      div(class = "bilgi-satir", strong("Öncelik: "), m$kaynak_onceligi[1], " · ", strong("Birincil yedek: "), m$birincil_yedek[1]),
      div(class = "bilgi-satir", strong("Son gözlem: "), donem_etiketi(o$SON_GOZLEM, f_ad)),
      if (yedek) div(class = "bilgi-satir", span(class = "uyari-etiket", paste0("Yedek kaynak kullanılıyor (birincil: ", m$birincil_kaynak[1], ")"))),
      if (sorun) div(class = "bilgi-satir", span(class = "uyari-etiket",
                     if (m$durum[1] == "bayat_cache") "Bayat önbellek verisi" else "CSV yedek verisi")),
      if (!yedek && !sorun) div(class = "bilgi-satir", span(class = "tamam-etiket", "Birincil kaynaktan güncel")))
  })

  output$grafik_baslik <- renderText({ req(input$gosterge); gosterge_etiketi(input$gosterge) })

  # Seçili dönemin sonucu: ileriye dönükse tahmin ve bant; geçmişe dönükse tahmin, gerçek ve hata
  output$secili_sonuc <- renderUI({
    g <- req(input$gosterge); d <- req(secili_donem()); f_ad <- gosterge_frekansi(g)
    f <- durum$gelecek[durum$gelecek$gosterge == g & durum$gelecek$tarih == d, ]
    s <- durum$gecmis[durum$gecmis$gosterge == g & durum$gecmis$tarih == d, ]
    if (nrow(f) == 1) {
      div(style = "margin-bottom:6px;",
          div(class = "sonuc-donem", paste(donem_etiketi(d, f_ad), "· tahmin")),
          div(class = "sonuc-deger", deger_metni(g, f$tahmin)),
          div(class = "sonuc-alt", paste0(round(100 * CONFIG$model$guven_duzeyi), "% bant: ",
                                          sayi_bicimle(f$alt), " – ", sayi_bicimle(f$ust))))
    } else if (nrow(s) == 1) {
      div(style = "margin-bottom:6px;",
          div(class = "sonuc-donem", paste(donem_etiketi(d, f_ad), "· geçmişe dönük tahmin (o dönemden önceki veriyle)")),
          div(class = "sonuc-deger", deger_metni(g, s$tahmin)),
          div(class = "sonuc-alt", paste0("Gerçek: ", sayi_bicimle(s$gercek), " · Hata: ", sayi_bicimle(s$tahmin - s$gercek))))
    }
  })

  output$grafik <- renderPlotly({
    g <- req(input$gosterge); d <- req(secili_donem()); f_ad <- gosterge_frekansi(g)
    seri <- gosterge_serisi(durum$veri, g)
    s <- durum$gecmis[durum$gecmis$gosterge == g, ]; f <- durum$gelecek[durum$gelecek$gosterge == g, ]
    if (f_ad != "yillik") seri <- seri[seri$tarih >= seq(max(seri$tarih), by = "-10 years", length.out = 2)[2], ]
    birim <- varsayilan(CONFIG$gostergeler[[g]]$birim, "Değer")
    y_sec <- c(f$tahmin[f$tarih == d], s$tahmin[s$tarih == d])[1]
    p <- plot_ly() %>%
      add_lines(data = seri, x = ~tarih, y = ~deger, name = "Gerçek", line = list(color = "#1f2d3d", width = 1.6)) %>%
      add_lines(data = s[s$tarih >= min(seri$tarih), ], x = ~tarih, y = ~tahmin, name = "Geçmişe dönük tahmin",
                line = list(color = "#1f6fb2", width = 1.3, dash = "dot")) %>%
      add_ribbons(data = f, x = ~tarih, ymin = ~alt, ymax = ~ust, name = paste0("%", round(100 * CONFIG$model$guven_duzeyi), " bant"),
                  fillcolor = "rgba(224,138,30,0.25)", line = list(color = "transparent")) %>%
      add_lines(data = f, x = ~tarih, y = ~tahmin, name = "İleriye tahmin", line = list(color = "#e08a1e", width = 2.4))
    if (length(y_sec) == 1 && !is.na(y_sec)) {
      p <- p %>% add_markers(x = d, y = y_sec, name = "Seçili dönem",
                             marker = list(color = "#1f6fb2", size = 11, line = list(color = "#fff", width = 2)))
    }
    p %>% layout(xaxis = list(title = "", rangeslider = list(visible = FALSE)), yaxis = list(title = birim),
                 hovermode = "x unified", legend = list(orientation = "h", y = -0.12),
                 margin = list(l = 50, r = 10, t = 10)) %>%
      plotly::config(displayModeBar = FALSE)
  })

  output$tablo_gelecek <- renderDT({
    g <- req(input$gosterge); f <- durum$gelecek[durum$gelecek$gosterge == g, ]; f_ad <- gosterge_frekansi(g)
    tablo <- data.frame("Dönem" = donem_etiketi(f$tarih, f_ad), "Tahmin" = round(f$tahmin, 3),
                        "Alt sınır" = round(f$alt, 3), "Üst sınır" = round(f$ust, 3), check.names = FALSE)
    datatable(tablo, rownames = FALSE, options = list(dom = "t", pageLength = 12, scrollX = TRUE))
  })

  output$metrikler <- renderTable({
    g <- req(input$gosterge); o <- durum$ozet[durum$ozet$gosterge == g, ]
    data.frame(
      "Ölçü" = c("MAE", "MSE", "RMSE", "MAPE (%)", "Theil U", "Naif RMSE", "Göreli RMSE"),
      "Örnek dışı" = c(sayi_bicimle(o$MAE), sayi_bicimle(o$MSE), sayi_bicimle(o$RMSE), sayi_bicimle(o$MAPE),
                       sayi_bicimle(o$THEIL_U), sayi_bicimle(o$NAIF_RMSE), sayi_bicimle(o$GORELI_RMSE)),
      "Örnek içi" = c(sayi_bicimle(o$IC_MAE), "-", sayi_bicimle(o$IC_RMSE), sayi_bicimle(o$IC_MAPE), "-", "-", "-"),
      check.names = FALSE)
  }, align = "lrr", spacing = "s")

  output$indir <- downloadHandler(
    filename = function() paste0(input$gosterge, "_tahmin_", format(Sys.Date(), "%Y%m%d"), ".csv"),
    content = function(file) {
      g <- input$gosterge
      s <- durum$gecmis[durum$gecmis$gosterge == g, ]; f <- durum$gelecek[durum$gelecek$gosterge == g, ]
      cikti <- rbind(
        data.frame(gosterge = g, tur = "geriye_donuk", tarih = s$tarih, gercek = s$gercek,
                   tahmin = s$tahmin, alt = NA_real_, ust = NA_real_),
        data.frame(gosterge = g, tur = "ileriye_donuk", tarih = f$tarih, gercek = NA_real_,
                   tahmin = f$tahmin, alt = f$alt, ust = f$ust))
      utils::write.csv(cikti, file, row.names = FALSE)
    })

  # ===========================================================================
  # MODEL KARŞILAŞTIRMA
  # ===========================================================================
  output$tablo_ozet <- renderDT({
    o <- durum$ozet
    tablo <- data.frame(
      "Gösterge" = o$ad, "Grup" = unname(unlist(CONFIG$sunum$roller)[match(o$rol, names(CONFIG$sunum$roller))]),
      "Frekans" = unname(sapply(o$FREKANS, function(f) frekans_ayari(f)$etiket)), "Kaynak" = o$KAYNAK,
      "p" = o$P, "Pencere" = o$PENCERE, "Ufuk" = o$UFUK, "Seçim" = o$YONTEM,
      "Son gözlem" = unname(mapply(donem_etiketi, o$SON_GOZLEM, o$FREKANS)),
      "MAE" = signif(o$MAE, 4), "RMSE" = signif(o$RMSE, 4), "MAPE (%)" = round(o$MAPE, 2),
      "Theil U" = round(o$THEIL_U, 4), "Göreli RMSE" = round(o$GORELI_RMSE, 3),
      "Örn. içi RMSE" = signif(o$IC_RMSE, 4), "Örn. içi MAPE (%)" = round(o$IC_MAPE, 2), check.names = FALSE)
    datatable(tablo, rownames = FALSE, filter = "top", options = list(pageLength = 25, scrollX = TRUE)) %>%
      formatStyle("Göreli RMSE", color = styleInterval(1, c("#0d5c2e", "#a12622")), fontWeight = "bold")
  })

  output$karsilastirma_grafik <- renderPlotly({
    req(input$olcu)
    o <- durum$ozet[durum$ozet$rol %in% input$roller, ]
    validate(need(nrow(o) > 0, "En az bir grup seçin."))
    o$deger <- o[[input$olcu]]
    o <- o[order(o$deger), ]
    p <- plot_ly(o, x = ~deger, y = ~factor(ad, levels = rev(ad)), type = "bar", orientation = "h",
                 color = ~rol, colors = renkler_rol,
                 hovertemplate = paste0("%{y}<br>", input$olcu, ": %{x:.3f}<extra></extra>")) %>%
      layout(xaxis = list(title = input$olcu), yaxis = list(title = ""),
             legend = list(orientation = "h", y = -0.15), margin = list(l = 220))
    if (input$olcu == "GORELI_RMSE") {
      p <- p %>% layout(shapes = list(list(type = "line", x0 = 1, x1 = 1, y0 = 0, y1 = 1, yref = "paper",
                                          line = list(color = "#c0392b", dash = "dash"))))
    }
    p
  })

  # ===========================================================================
  # VERİ VE METAVERİ
  # ===========================================================================
  output$tablo_meta <- renderDT({
    m <- durum$meta
    tablo <- data.frame(
      "Gösterge" = m$ad, "Frekans" = unname(sapply(m$frekans, function(f) frekans_ayari(f)$etiket)),
      "Kaynak önceliği" = m$kaynak_onceligi, "Birincil yedek" = m$birincil_yedek,
      "Kullanılan" = m$kaynak, "Kod" = m$kod,
      "Yedek" = ifelse(m$yedek_kullanildi %in% TRUE, "EVET", "hayır"),
      "Yaklaşık" = ifelse(m$yaklasik %in% TRUE, "evet", ""), "Durum" = m$durum,
      "Biçim" = ifelse(m$donusum == "yillik_degisim", "yıllık %", "düzey"),
      "İlk" = format(m$ilk_tarih, "%Y-%m"), "Son" = format(m$son_tarih, "%Y-%m"), "Gözlem" = m$gozlem,
      "Çekim zamanı" = format(m$cekim_zamani, "%d.%m.%Y %H:%M"), check.names = FALSE)
    datatable(tablo, rownames = FALSE, filter = "top", options = list(pageLength = 25, scrollX = TRUE)) %>%
      formatStyle("Yedek", backgroundColor = styleEqual("EVET", "#fff3cd")) %>%
      formatStyle("Durum", backgroundColor = styleEqual(c("bayat_cache", "csv_yedek", "alinamadi"),
                                                        c("#fff3cd", "#fff3cd", "#f8d7da")))
  })

  output$tablo_kalite <- renderDT({
    k <- durum$kalite
    validate(need(!is.null(k), "Kalite raporu henüz yok; verileri güncelleyin."))
    tablo <- data.frame(
      "Gösterge" = k$ad, "Frekans" = unname(sapply(k$frekans, function(f) frekans_ayari(f)$etiket)),
      "Gözlem" = k$gozlem, "İlk" = format(k$ilk_tarih, "%Y-%m"), "Son" = format(k$son_tarih, "%Y-%m"),
      "Gecikme (dönem)" = k$gecikme_donem, "Eksik dönem oranı" = k$eksik_donem_orani,
      "Sapan sayısı" = k$sapan_sayisi, "Sapan örnekleri" = k$sapan_tarihleri, check.names = FALSE)
    datatable(tablo, rownames = FALSE, filter = "top", options = list(pageLength = 25, scrollX = TRUE)) %>%
      formatStyle("Gecikme (dönem)", backgroundColor = styleInterval(c(3, 12), c("white", "#fff3cd", "#f8d7da")))
  })
}

# =============================================================================
# UYGULAMAYI AYAĞA KALDIR
# =============================================================================
shinyApp(ui, server)
