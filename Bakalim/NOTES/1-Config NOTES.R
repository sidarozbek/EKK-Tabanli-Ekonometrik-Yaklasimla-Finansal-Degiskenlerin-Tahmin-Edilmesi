.proje_koku <- local({
  d <- normalizePath(getwd(), winslash = "/", mustWork = FALSE)
  repeat {
    if (file.exists(file.path(d, "R", "config.R"))) return(d)
    ust <- dirname(d)
    if (identical(ust, d)) return(normalizePath(getwd(), winslash = "/", mustWork = FALSE))
    d <- ust
  }
})

#GÜVENLİK İÇİN API ŞİFRELERİNİ KODA YAZMAK YERİNE .RENVİRON'DAN ÇEKER,
#ANAHTAR BOŞSA UYARI VERİR
anahtar_oku <- function(ad) {
  temizle <- function(v) trimws(gsub("^[\"']|[\"']$", "", trimws(v)))
  v <- temizle(Sys.getenv(ad))
  if (!nzchar(v)) {
    oturum_basi <- Sys.time() - proc.time()[["elapsed"]]
    for (dosya in unique(c(file.path(.proje_koku, ".Renviron"), path.expand("~/.Renviron")))) {
      if (!file.exists(dosya) || file.mtime(dosya) < oturum_basi) next
      satir <- grep(paste0("^\\s*", ad, "\\s*="), readLines(dosya, warn = FALSE), value = TRUE)
      if (length(satir)) { v <- temizle(sub("^[^=]*=", "", satir[length(satir)])); break }
    }
    if (nzchar(v)) do.call(Sys.setenv, stats::setNames(list(v), ad))
  }
  if (!nzchar(v)) warning("[config.R] ", ad, " bulunamadı (.Renviron). Bu kaynak atlanacak.", call. = FALSE)
  v
}

#PROJENİN BÜTÜN AYARLARININ TOPLANDIĞI YER, DİĞER DOSYALAR DA AYARLARI BURADAN OKUR
CONFIG <- list(

  proje = list(
    baslik  = "EKK Tabanlı Ekonometrik Yaklaşımla Finansal Değişkenlerin Tahmin Edilmesi",
    program = "TÜBİTAK 2209-A Üniversite Öğrencileri Araştırma Projeleri",
    kurum   = "Atılım Üniversitesi",
    surum   = "2.0.0"
  ),

  #VERİ AYARLARI: ÇEKİLECEK VERİNİN TARİH ARALIĞI, CACHE'NİN KAÇ GÜN TAZA SAYILACAĞI
  #MİN GÖZLEM SAYISI
  veri = list(
    baslangic_tarihi    = "2000-01-01",
    bitis_tarihi        = as.character(Sys.Date()),
    yedek_kaynak_kullan = TRUE,   # birincil kaynak çökerse yedek API / CSV denensin
    cache_tazelik_gun   = 1,      # cache bu kadar günden eskiyse API'ye gidilir
    min_gozlem          = 8       # bundan kısa seri "yetersiz" sayılır
  ),

  #BAĞLANTI AYARLARI, API ADRESLERİ, ZAMAN AŞIMI (sn), YENİDEN DENEME HAKKI VE KAÇ sn ARAYLA DENENEBİLECEĞİ
  baglanti = list(
    evds_key               = anahtar_oku("EVDS_API_KEY"),
    fred_key               = anahtar_oku("FRED_API_KEY"),
    evds_base_url          = "https://evds3.tcmb.gov.tr/igmevdsms-dis",
    oecd_base_url          = "https://sdmx.oecd.org/public/rest",
    yahoo_base_url         = "https://query1.finance.yahoo.com/v8/finance/chart",
    kullanici_araci        = "Mozilla/5.0 (EconoLab R; TUBITAK 2209-A)",
    zaman_asimi            = 30,
    yeniden_deneme         = 3,
    yeniden_deneme_bekleme = 2
  ),

  kaynaklar = list(desteklenen = c("EVDS", "FRED", "WORLDBANK", "OECD", "BIST")),

  #SAKLAMA AYARLARI: CACHE, İŞLENMİŞ VERİ, YEDEK CSV, MODEL VE LOG DOSYALARININ NEREYE YAZILACAĞI
  saklama = list(
    kok               = .proje_koku,
    log_klasoru       = file.path(.proje_koku, "logs"),
    cache_klasoru     = file.path(.proje_koku, "data", "cache"),
    yedek_klasoru     = file.path(.proje_koku, "data", "yedek"),
    processed_klasoru = file.path(.proje_koku, "data", "processed"),
    model_klasoru     = file.path(.proje_koku, "models")
  ),

  guncelleme = list(sikligi_gun = 1, otomatik = TRUE),

  sunum = list(genel_azami = 4),

  #MODEL AYARLARI: EKK MODELİNİN VARSAYILANLARI, MODEL SEÇİMİ (çapraz doğrulama veya varsayılan)
  #TAHMİN UFKU, GÜVEN DÜZEYİ VE TEST ORANLARI
  model = list(
    lag_sayisi       = 3,
    pencere_uzunlugu = 48,
    tahmin_ufku      = 6,
    egitim_orani     = 0.80,
    formulde_trend   = FALSE,
    model_secimi     = "capraz",
    capraz_min_n     = 4,
    guven_duzeyi     = 0.95
  ),

  #FREKANS AYARLARI: aylik/ceyreklik/yillik FREKANSLAR İÇİN GECİKME SAYISI (lag)
  #KAYAN PENCERE UZUNLUĞU, EN BÜYÜK P VE ÇAPRAZ DOĞRULAMADA DENENECEK PENCERELER
  frekanslar = list(
    aylik = list(ay_adimi = 1, lag_sayisi = 12, pencere_uzunlugu = 48, tahmin_ufku = 6,
                 pencere_adaylari = seq(36, 60, by = 6), p_max = 12, capraz_son_n = 36),
    ceyreklik = list(ay_adimi = 3, lag_sayisi = 4, pencere_uzunlugu = 24, tahmin_ufku = 4,
                     pencere_adaylari = c(16, 20, 24, 28, 32), p_max = 8, capraz_son_n = 12),
    yillik = list(ay_adimi = 12, lag_sayisi = 1, pencere_uzunlugu = 12, tahmin_ufku = 3,
                  pencere_adaylari = c(8, 10, 12, 15), p_max = 3, capraz_son_n = 6)
  )
)

#ASIL KAYNAK -> YEDEK SIRALAMASI (oncelik)
#ASIL KAYNAĞIN ÇALIŞMAMASI DURUMUNDA ÖNCELİK SIRASINA GÖRE SIRADAKİ KAYNAĞA GEÇİLİR
gosterge_karti <- function(ad, rol, kaynak, kod, frekans = "aylik", donusum = "duzey",
                           oncelik = c(kaynak, "CSV_YEDEK"), alternatifler = NULL,
                           birincil_yedek = oncelik[2], ...) {
  ek <- list(...)
  yasak <- intersect(names(ek), c("p", "pencere", "pencere_adaylari", "capraz_son_n"))
  if (length(yasak) > 0) {
    stop("[config.R] ", ad, ": ", paste(yasak, collapse = ", "),
         " gösterge bazında seçilemez; model tarafından belirlenir", call. = FALSE)
  }
  c(list(ad = ad, rol = rol, aktif = TRUE, kaynak = kaynak, kod = kod, kaynak_tur = "duzey",
         frekans = frekans, donusum = donusum, oncelik = oncelik,
         alternatifler = alternatifler, birincil_yedek = birincil_yedek), ek)
}
AYLIK_ORT <- "frequency=5&aggregationTypes=avg"

CONFIG$gostergeler <- list(
  ## Bağımlı (6)
  ENFLASYON = gosterge_karti("ENFLASYON (TÜFE)", "Bağımlı", "EVDS", "TP.TUKFIY2025.GENEL",
                             donusum = "yillik_degisim", oncelik = c("EVDS", "FRED", "CSV_YEDEK"),
                             alternatifler = list(FRED = list(kod = "TURCPIALLMINMEI", tur = "duzey"))),
  BUYUME    = gosterge_karti("BÜYÜME (GSYH)", "Bağımlı", "FRED", "NGDPRSAXDCTRQ",
                             frekans = "ceyreklik", donusum = "yillik_degisim"),
  USDTRY    = gosterge_karti("USD/TRY Kuru", "Bağımlı", "EVDS", "TP.DK.USD.A.YTL", filtre = AYLIK_ORT,
                             oncelik = c("EVDS", "FRED", "CSV_YEDEK"),
                             alternatifler = list(FRED = list(kod = "CCUSMA02TRM618N", tur = "duzey"))),
  ISSIZLIK  = gosterge_karti("İŞSİZLİK Oranı", "Bağımlı", "EVDS", "TP.YISGUCU2.G8",
                             oncelik = c("EVDS", "FRED", "CSV_YEDEK"),
                             alternatifler = list(FRED = list(kod = "LRHUTTTTTRM156S", tur = "duzey"))),
  FAIZ      = gosterge_karti("Politika / Fonlama Faizi", "Bağımlı", "EVDS", "TP.APIFON4",
                             filtre = AYLIK_ORT, oncelik = c("EVDS", "FRED", "CSV_YEDEK"),
                             alternatifler = list(FRED = list(kod = "IRSTCI01TRM156N", tur = "duzey"))),
  BIST100   = gosterge_karti("BIST 100 Endeksi", "Bağımlı", "BIST", "XU100"),

  ## Kontrol (4)
  EURTRY        = gosterge_karti("EUR/TRY Kuru", "Kontrol", "EVDS", "TP.DK.EUR.A.YTL", filtre = AYLIK_ORT),
  UFE           = gosterge_karti("Yİ-ÜFE", "Kontrol", "EVDS", "TP.TUFE1YI.T1", donusum = "yillik_degisim"),
  M2            = gosterge_karti("Para Arzı (M2)", "Kontrol", "EVDS", "TP.PBD.H09", donusum = "yillik_degisim"),
  SANAYI_URETIM = gosterge_karti("Sanayi Üretimi", "Kontrol", "FRED", "TURPROINDMISMEI",
                                 donusum = "yillik_degisim"),

  ## Ek (11)
  TUKETICI_GUVEN    = gosterge_karti("Tüketici Güven Endeksi", "Ek", "EVDS", "TP.TG2.Y01",
                                     oncelik = c("EVDS", "FRED", "CSV_YEDEK"),
                                     alternatifler = list(FRED = list(kod = "CSCICP03TRM665S", tur = "duzey"))),
  REEL_KESIM_GUVEN  = gosterge_karti("Reel Kesim Güven Endeksi", "Ek", "EVDS", "TP.GY1.N2"),
  KAPASITE_KULLANIM = gosterge_karti("Kapasite Kullanım Oranı", "Ek", "EVDS", "TP.KKO2.IS.TOP",
                                     oncelik = c("EVDS", "FRED", "CSV_YEDEK"),
                                     alternatifler = list(FRED = list(kod = "BSCURT02TRM160S", tur = "duzey"))),
  KONUT_FIYAT       = gosterge_karti("Konut Fiyat Endeksi", "Ek", "EVDS", "TP.KFE.TR",
                                     donusum = "yillik_degisim"),
  PERAKENDE_SATIS   = gosterge_karti("Perakende Satış (yıllık %)", "Ek", "FRED", "TURSLRTTO01GYSAQ",
                                     frekans = "ceyreklik"),
  GENC_ISSIZLIK     = gosterge_karti("Genç İşsizlik (15-24)", "Ek", "FRED", "SLUEM1524ZSTUR",
                                     frekans = "yillik", oncelik = c("FRED", "WORLDBANK", "CSV_YEDEK"),
                                     alternatifler = list(WORLDBANK = list(kod = "SL.UEM.1524.ZS", tur = "duzey"))),
  GINI              = gosterge_karti("GINI Endeksi", "Ek", "FRED", "SIPOVGINITUR",
                                     frekans = "yillik", oncelik = c("FRED", "WORLDBANK", "CSV_YEDEK"),
                                     alternatifler = list(WORLDBANK = list(kod = "SI.POV.GINI", tur = "duzey"))),
  CARI_DENGE        = gosterge_karti("Cari Denge / GSYH (%)", "Ek", "WORLDBANK", "BN.CAB.XOKA.GD.ZS",
                                     frekans = "yillik"),
  DIS_TICARET       = gosterge_karti("Dış Ticaret / GSYH (%)", "Ek", "WORLDBANK", "NE.TRD.GNFS.ZS",
                                     frekans = "yillik"),
  BUTCE_DENGESI     = gosterge_karti("Genel Devlet Dengesi / GSYH (%)", "Ek", "FRED", "GGNLBATRA188N",
                                     frekans = "yillik"),
  TURIZM_GELIRI     = gosterge_karti("Turizm Gelirleri (USD)", "Ek", "WORLDBANK", "ST.INT.RCPT.CD",
                                     frekans = "yillik")
)

#NOTE
for (g in c("ENFLASYON", "BUYUME", "USDTRY", "ISSIZLIK")) CONFIG$gostergeler[[g]]$aktif <- FALSE
rm(gosterge_karti, AYLIK_ORT, g)

#FREKANS AYARI: utils.R bu fonksiyonu bekliyor.
#Verilen frekansın ("aylik" / "ceyreklik" / "yillik") ayar listesini döndürür.
#Kullanım: frekans_ayari("aylik")$ay_adimi  ->  1
frekans_ayari <- function(frekans) {
  f <- CONFIG$frekanslar[[frekans]]
  if (is.null(f)) stop("Tanımsız frekans: ", frekans, call. = FALSE)
  f
}

kaynak_kullanilabilir <- function(kaynak) {
  switch(kaynak,
         EVDS = isTRUE(nzchar(CONFIG$baglanti$evds_key)),
         FRED = isTRUE(nzchar(CONFIG$baglanti$fred_key)),
         TRUE)
}

message("[config.R] Ayarlar yüklendi: ", length(CONFIG$gostergeler), " gösterge, ",
        length(CONFIG$frekanslar), " frekans. ✔")
