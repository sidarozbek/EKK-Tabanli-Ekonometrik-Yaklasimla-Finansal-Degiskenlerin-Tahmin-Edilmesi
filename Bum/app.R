# =============================================================================
# EconoLab — Makroekonomik Tahmin Portalı (Shiny)
# TÜBİTAK 2209-A • AR(p) Kayan Pencere EKK tahmin çerçevesi
#
# Çalıştırma (Bum klasöründe):  shiny::runApp()
#
# Katmanlar
#   R/config.R         CONFIG: göstergeler, kaynaklar, frekanslar, model ayarları
#   R/utils.R          alet çantası (cache, log, dönem, gösterge ayarları)
#   R/api_functions.R  EVDS / FRED / Dünya Bankası / OECD / BIST + yedek zinciri
#   R/data.prep.R      takvim, enterpolasyon, kalite raporu
#   R/models.R         AR-EKK, kayan pencere, çapraz doğrulama, gelecek tahmin
#   ui/                4 ekran: Makro Panel, Model Lab, Regresyon, Veri Hattı
# =============================================================================

suppressPackageStartupMessages({
  library(shiny)
  library(bslib)
})

# Pipeline: hata mesajlarındaki sırayla yüklenir (R/_disable_autoload.R otomatik yüklemeyi kapatır)
for (f in c("config", "utils", "api_functions", "data.prep", "models")) source(file.path("R", paste0(f, ".R")))
for (f in c("arayuz", "sayfa_makro", "sayfa_regresyon", "sayfa_veri", "sayfa_model")) source(file.path("ui", paste0(f, ".R")))

# İlk sonuç paketi: güncel kayıt varsa diskten gelir, yoksa kaynaklardan çekilip hesaplanır
PAKET0 <- tryCatch(sonuclari_getir(FALSE), error = function(e) {
  log_msg(paste("Başlangıçta sonuç üretilemedi:", conditionMessage(e)), "HATA"); NULL })
LOG_DOSYASI <- file.path(CONFIG$saklama$log_klasoru, "calisma.log")

ui <- page(
  title = "EconoLab — Makroekonomik Tahmin Portalı",
  theme = bs_theme(version = 5, bg = "#111018", fg = "#e5e0ec", primary = "#ffb689",
                   secondary = "#cfbdff", success = "#7dd8b4", danger = "#FF6B72",
                   base_font = "Inter, sans-serif", heading_font = "'Space Grotesk', sans-serif",
                   code_font = "'JetBrains Mono', monospace"),
  tags$head(
    tags$link(rel = "stylesheet", href = paste0(
      "https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700",
      "&family=Space+Grotesk:wght@500;600;700&family=JetBrains+Mono:wght@400;500;700&display=swap")),
    tags$link(rel = "stylesheet", href = paste0(
      "https://fonts.googleapis.com/css2?family=Material+Symbols+Outlined:opsz,wght,FILL,GRAD@20..48,300..500,0..1,0")),
    tags$link(rel = "stylesheet", href = "econolab.css"),
    tags$script(src = "econolab.js")
  ),
  kenar_menu(),
  div(class = "ana-alan",
      ust_bar(),
      tags$main(class = "icerik",
        tabsetPanel(id = "sayfalar", type = "hidden",
          tabPanelBody("makro", makro_ui("makro")),
          tabPanelBody("model", model_ui("model")),
          tabPanelBody("regresyon", regresyon_ui("regresyon")),
          tabPanelBody("veri", veri_ui("veri"))
        )))
)

server <- function(input, output, session) {

  paket <- reactiveVal(PAKET0)
  secili <- reactiveVal(aktif_gostergeler()[1])

  # logs/calisma.log canlı okunur (utils.R::log_msg buraya yazar)
  gunluk <- reactiveFileReader(1500, session, LOG_DOSYASI, function(f)
    if (file.exists(f)) utils::tail(readLines(f, warn = FALSE, encoding = "UTF-8"), 200) else character())

  # Uzun süren pipeline çağrılarını ilerleme çubuğu ve hata yakalamayla çalıştırır
  paket_yenile <- function(mesaj, islem) {
    withProgress(message = mesaj, value = 0.3, {
      sonuc <- tryCatch(islem(), error = function(e) e)
    })
    if (inherits(sonuc, "error")) {
      log_msg(paste("Arayüz işlemi başarısız:", conditionMessage(sonuc)), "HATA")
      showNotification(conditionMessage(sonuc), type = "error", duration = 10)
    } else {
      paket(sonuc)
      showNotification("Sonuçlar güncellendi.", type = "message")
    }
  }

  output$ust_durum <- renderText({
    p <- paket()
    if (is.null(p)) return("Veri yok • Kaynaklardan Yenile ile başlatın")
    m <- p$meta[p$meta$gosterge %in% aktif_gostergeler(), ]
    sprintf("%s • %d/%d Gösterge • %s",
            paste(unique(stats::na.omit(m$kaynak)), collapse = ", "),
            sum(m$durum != "alinamadi"), nrow(m),
            if (all(m$durum %in% c("api", "cache"))) "Canlı" else "Yedek kanal devrede")
  })

  # Kenar menü / KPI kartı gezinmesi
  observeEvent(input$nav, {
    updateTabsetPanel(session, "sayfalar", selected = input$nav$sayfa)
    session$sendCustomMessage("aktif_sayfa", list(sayfa = input$nav$sayfa, gosterge = input$nav$gosterge))
    g <- input$nav$gosterge
    if (!is.null(g) && g %in% names(CONFIG$gostergeler)) secili(g)
  })

  observeEvent(input$hepsini_calistir,
               paket_yenile("Tüm modeller yeniden kestiriliyor (calistir_hepsi)…", function() calistir_hepsi(FALSE)))
  observeEvent(input$kaynaktan_yenile,
               paket_yenile("Tüm göstergeler kaynaklardan çekiliyor (1-2 dk)…", function() sonuclari_getir(TRUE)))

  makro_server("makro", paket, secili, gunluk)
  model_server("model", paket, secili)
  regresyon_server("regresyon", paket, secili)
  veri_server("veri", paket, secili, paket_yenile)
}

shinyApp(ui, server)
