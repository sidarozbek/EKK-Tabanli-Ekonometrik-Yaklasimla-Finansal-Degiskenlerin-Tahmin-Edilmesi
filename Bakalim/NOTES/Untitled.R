#NOTE
if (getRversion() < "4.1.0") {
  warning("[config.R] R 4.3+ önerilir; bazı sözdizimleri eski sürümde çalışmayabilir.")
}

#NOTE
.proje_koku <- local({
  d <- normalizePath(getwd(), winslash = "/", mustWork = FALSE)
  repeat {
    if (file.exists(file.path(d, "R", "config.R"))) return(d)
    ust <- dirname(d)
    if (identical(ust, d)) return(normalizePath(getwd(), winslash = "/", mustWork = FALSE))
    d <- ust
  }
})

#NOTE
.fred_key <- Sys.getenv("FRED_API_KEY")
.evds_key <- Sys.getenv("EVDS_API_KEY")

if (!nzchar(.fred_key)) {
  warning("[config.R] FRED_API_KEY boş; FRED atlanacak. .Renviron'a ekleyip R'ı yeniden başlat.")
}
if (!nzchar(.evds_key)) {
  warning("[config.R] EVDS_API_KEY boş; EVDS atlanacak. .Renviron'a ekleyip R'ı yeniden başlat.")
}

#NOTE
CONFIG <- list(
  proje = list(
    baslik  = "EKK Tabanlı Ekonometrik Yaklaşımla Finansal Değişkenlerin Tahmin Edilmesi",
    program = "TÜBİTAK 2209-A Üniversite Öğrencileri Araştırma Projeleri",
    kurum   = "Atılım Üniversitesi",
    surum   = "2.0.0"
  ),
  
  #NOTE
  baglanti = list(
    fred_key       = .fred_key,
    evds_key       = .evds_key,
    evds_base_url  = "https://evds3.tcmb.gov.tr/igmevdsms-dis",
    oecd_base_url  = "https://sdmx.oecd.org/public/rest",
    yahoo_base_url = "https://query1.finance.yahoo.com/v8/finance/chart",
    kullanici_araci = "Mozilla/5.0 (eco-forecast-ekk; akademik arastirma)",
    zaman_asimi    = 30,
    yeniden_deneme = 3,
    yeniden_deneme_bekleme = 2
  ),
  
  #NOTE
  veri = list(
    baslangic_tarihi  = "2000-01-01",
    bitis_tarihi      = Sys.Date(),
    cache_tazelik_gun = 1,
    min_gozlem        = 8,
    yedek_kaynak_kullan = TRUE,
    hampel_esigi      = 3
  ),
  
  #NOTE
  frekanslar = list(
    aylik = list(
      etiket = "Aylık", birim = "ay", ay_adimi = 1, yilda = 12,
      lag_sayisi = 3, pencere_uzunlugu = 48, p_max = 12,
      pencere_adaylari = c(36, 42, 48, 54, 60),
      capraz_son_n = 36   
    ),
    ceyreklik = list(
      etiket = "Çeyreklik", birim = "çeyrek", ay_adimi = 3, yilda = 4,
      lag_sayisi = 4, pencere_uzunlugu = 20, p_max = 8,
      pencere_adaylari = c(12, 16, 20, 24, 28),
      capraz_son_n = 12
    ),
    yillik = list(
      etiket = "Yıllık", birim = "yıl", ay_adimi = 12, yilda = 1,
      lag_sayisi = 2, pencere_uzunlugu = 12, p_max = 3,
      pencere_adaylari = c(8, 10, 12, 14, 16),
      capraz_son_n = 6
    )
  ),
  
  #NOTE
  model = list(
    lag_sayisi        = 3,  
    pencere_uzunlugu  = 48,        
    model_secimi      = "capraz",
    capraz_min_n      = 4,
    tahmin_ufku       = 6,     
    guven_duzeyi      = 0.95,
    egitim_orani      = 0.80,
    formulde_trend    = FALSE     
  ),
  
  #NOTE
  guncelleme = list(
    otomatik    = TRUE,
    sikligi_gun = 1
  ),
  
  #NOTE
  saklama = list(
    kok               = .proje_koku,
    cache_klasoru     = file.path(.proje_koku, "data", "cache"),
    processed_klasoru = file.path(.proje_koku, "data", "processed"),
    yedek_klasoru     = file.path(.proje_koku, "data", "yedek"),
    model_klasoru     = file.path(.proje_koku, "models"),
    log_klasoru       = file.path(.proje_koku, "logs")
  ),
  
  #NOTE
  kaynaklar = list(
    desteklenen = c("FRED", "EVDS", "WORLDBANK", "OECD", "BIST", "CSV_YEDEK"),
    katalog     = character(0),
    aciklama = c(
      FRED      = "Federal Reserve Economic Data (fredr)",
      EVDS      = "TCMB Elektronik Veri Dağıtım Sistemi (httr + jsonlite)",
      WORLDBANK = "Dünya Bankası Açık Veri (wbstats)",
      OECD      = "OECD SDMX API (httr; eski OECD paketi yeni API'yi desteklemiyor)",
      BIST      = "Borsa İstanbul endeksleri (Yahoo Finance grafik API'si)",
      CSV_YEDEK = "Yerel CSV yedek veri seti (data/yedek)"
    )
  ),
  
  #NOTE
  sunum = list(
    roller = c(bagimli = "Bağımlı değişkenler",
               kontrol = "Kontrol değişkenleri",
               ek      = "Ek göstergeler"),
    genel_varsayilan = c("ENFLASYON", "BUYUME", "USDTRY", "ISSIZLIK"),
    genel_azami      = 4
  ),
  
  #NOTE
  gostergeler = list(
    
    ENFLASYON = list(
      aktif = TRUE, rol = "bagimli", ad = "Enflasyon Oranı (TÜFE, yıllık %)", frekans = "aylik",
      birim = "%", donusum = "yillik_degisim",
      kaynak = "EVDS", kod = "TP_TUKFIY2025_GENEL",
      oncelik = c("EVDS", "FRED", "WORLDBANK","OECD", "CSV_YEDEK"), birincil_yedek = "FRED",
      p = 12, pencere = 42,
      alternatifler = list(
        FRED      = list(kod = "TURCPIALLMINMEI", tur = "duzey", frekans="aylik"),
        WORLDBANK = list(kod = "FP.CPI.TOTL.ZG", tur = "oran", frekans = "yillik"),
        OECD      = list(kod = "OECD.SDD.TPS,DSD_PRICES_COICOP2018@DF_PRICES_C2018_ALL",
                         filtre = "TUR.M.N.CPI.PA._T.N.GY", tur = "oran")
        
      )
    ),
    
    #NOTE
    BUYUME = list(
      aktif = TRUE, rol = "bagimli", ad = "Ekonomik Büyüme (reel GSYH, yıllık %)", frekans = "ceyreklik",
      birim = "%", donusum = "yillik_degisim",
      kaynak = "EVDS", kod = "TP_GSYIH20_BY_B1GQ",
      oncelik = c("EVDS", "FRED", "WORLDBANK", "CSV_YEDEK"), birincil_yedek = "FRED",
      p = 8, pencere = 18,
      alternatifler = list(
        FRED      = list(kod = "NGDPRSAXDCTRQ", tur = "farkli", frekans="ceyreklik"),     
        WORLDBANK = list(kod = "WB_WDI_NY_GDP_MKTP_KD_ZG", tur = "oran", frekans = "yillik")
      )
    ),
    
    #NOTE 
    ISSIZLIK = list(
      aktif = TRUE, rol = "bagimli", ad = "İşsizlik Oranı", frekans = "aylik", birim = "%",
      kaynak = "EVDS", kod = "TP_YISGUCU2_G8",
      oncelik = c("EVDS", "FRED", "WORLDBANK", "CSV_YEDEK"), birincil_yedek = "FRED",
      p = 5, pencere = 48,
      alternatifler = list(
        FRED      = list(kod = "LRHUTTTTTRM156S", tur = "duzey", frekans="aylik"),
        WORLDBANK = list(kod = "SL.UEM.TOTL.ZS", tur = "duzey", frekans = "yillik")
      )
    ),
    
    #NOTE
    USDTRY = list(
      aktif = TRUE, rol = "bagimli", ad = "Döviz Kuru (USD/TRY)", frekans = "aylik", birim = "TL",
      kaynak = "EVDS", kod = "TP_DK_USD_A_YTL",
      oncelik = c("EVDS", "WORLDBANK" ,"OECD", "CSV_YEDEK"), birincil_yedek = "WORLDBANK",
      p = 11, pencere = 60,
      alternatifler = list(
        EVDS      = list(kod = "TP_DK_USD_A_YTL", tur = "duzey",
                         filtre = "frequency=5&aggregationTypes=avg"),     
        WORLDBANK = list(kod = "PA.NUS.FCRF", tur = "duzey", frekans = "yillik"),
        OECD      = list(kod = "CCUSMA02TRM618N",
                         filtre = "TUR.M.N.CPI.PA._T.N.GY", tur = "oran")
      )
    ),
    
    #NOTE    
    BIST100 = list(                                   
      aktif = TRUE, rol = "bagimli", ad = "Borsa Endeksi (BIST-100)", frekans = "aylik",
      kaynak = "BIST", kod = "XU100",                
      oncelik = c("BIST", "CSV_YEDEK"), birincil_yedek = "CSV_YEDEK"
    ),
    
    #NOTE  
    FAIZ = list(
      aktif = TRUE, rol = "kontrol", ad = "TCMB Politika Faizi", frekans = "aylik", birim = "%",
      kaynak = "EVDS", kod = "TP_BISPOLFAIZ_TUR",
      oncelik = c("EVDS", "FRED", "CSV_YEDEK"), birincil_yedek = "FRED",
      p = 4, pencere = 54,
      alternatifler = list(FRED = list(kod = "INTDSRTRM193N", tur = "duzey", yaklasik = TRUE))
    ),
    
    #NOTE    
    DIS_TICARET = list(
      aktif = TRUE, rol = "kontrol", ad = "Dış Ticaret Dengesi", frekans = "aylik",
      kaynak = "EVDS", kod = "TP_ODEAYRSUNUM6_Q4",
      oncelik = c("EVDS", "FRED", "CSV_YEDEK"), birincil_yedek = "FRED",
      p = 12, pencere = 60,
      alternatifler = list(FRED = list(kod = "TURXTNTVA01CXMLM", tur = "farkli", frekans="aylik")) 
    ),
    
    #NOTE  
    SANAYI_URETIM = list(
      aktif = TRUE, rol = "kontrol", ad = "Sanayi Üretim Endeksi", frekans = "aylik",
      kaynak = "EVDS", kod = "TP_TSANAY2021_BCD",
      oncelik = c("EVDS", "FRED","CSV_YEDEK"), birincil_yedek = "FRED",
      p = 12, pencere = 60,
      alternatifler = list(FRED = list(kod = "TURPRINTO01GYSAM", tur = "oran",frekans="aylik")) 
    ),
    
    #NOTE    
    TUKETICI_GUVEN = list(
      aktif = TRUE, rol = "kontrol", ad = "Tüketici Güven Endeksi", frekans = "aylik",
      kaynak = "EVDS", kod = "TP_TG2_Y01",
      oncelik = c("EVDS", "CSV_YEDEK"), birincil_yedek = "CSV_YEDEK",
      p = 12, pencere = 60
    ),
    
    #NOTE    
    CARI_DENGE = list(
      aktif = TRUE, rol = "ek", ad = "Cari İşlemler Dengesi", frekans = "ceyreklik",
      kaynak = "EVDS", kod = "TP_IMFCA_TUR",
      oncelik = c("EVDS","FRED" ,"WORLDBANK", "OECD", "CSV_YEDEK"), birincil_yedek = "FRED",
      p = 8, pencere = 20,
      alternatifler = list(
        FRED      = list(kod = "TURB6BLTT02STSAQ", tur = "farkli", frekans="ceyreklik"),
        WORLDBANK = list(kod = "BN.CAB.XOKA.GD.ZS", tur = "farkli", frekans = "yillik"),
        OECD      = list(kod = "DSD_BOP@DF_BOP",
                         filtre = "TUR.WXD.CA.B.T.Q.USD_EXC.N",          
                         tur = "duzey", carpan = 1e6)                   
      )
    ),
    
    #NOTE    
    BUTCE_DENGESI = list(
      aktif = TRUE, rol = "ek", ad = "Bütçe Dengesi", frekans = "aylik",
      kaynak = "EVDS", kod = "TP_KB_GEN35",
      oncelik = c("EVDS","FRED" ,"CSV_YEDEK"), birincil_yedek = "FRED",
      p = 12, pencere = 36,
      alternatifler = list(FRED = list(kod = "GGNLBATRA188N", tur = "farkli", frekans = "yillik"))
    ),
    
    #NOTE    
    UFE = list(
      aktif = TRUE, rol = "ek", ad = "Üretici Fiyat Endeksi (ÜFE)", frekans = "aylik",
      kaynak = "EVDS", kod = "TP_TUFE1YI_T1",
      oncelik = c("EVDS", "CSV_YEDEK"), birincil_yedek = "CSV_YEDEK",
      p = 12, pencere = 48
    ),
    
    #NOTE    
    M2 = list(
      aktif = TRUE, rol = "ek", ad = "M2 Para Arzı", frekans = "aylik",
      kaynak = "EVDS", kod = "TP_PBD_H09",
      oncelik = c("EVDS", "CSV_YEDEK"), birincil_yedek = "CSV_YEDEK",
      p = 12, pencere = 42
    ),
    
    #NOTE    
    EURTRY = list(
      aktif = TRUE, rol = "bagimli", ad = "Döviz Kuru (EUR/TRY)", frekans = "aylik", birim = "TL",
      kaynak = "EVDS", kod = "TP_DK_EUR_A_YTL",
      oncelik = c("EVDS", "CSV_YEDEK"), birincil_yedek = "CSV_YEDEK",
      p =3 , pencere =36,
      alternatifler = list(
        EVDS = list(kod = "TP_DK_EUR_A_YTL", tur = "duzey",
                    filtre = "frequency=5&aggregationTypes=avg")a
      )
    ),
    
    #NOTE    
    REEL_KESIM_GUVEN = list(
      aktif = TRUE, rol = "ek", ad = "Reel Kesim Güven Endeksi", frekans = "aylik",
      kaynak = "EVDS", kod = "TP_GY1_N2",
      oncelik = c("EVDS","FRED" ,"CSV_YEDEK"), birincil_yedek = "FRED",
      p = 12, pencere = 60,
      alternatifler = list(FRED = list(kod = "BSCICP02TRM460S", tur = "farkli", frekans="aylik"))  
    ),
    
    #NOTE    
    KAPASITE_KULLANIM = list(
      aktif = TRUE, rol = "ek", ad = "Kapasite Kullanım Oranı", frekans = "aylik", birim = "%",
      kaynak = "EVDS", kod = "TP_KKO2_IS_TOP",
      oncelik = c("EVDS", "FRED","OECD", "CSV_YEDEK"), birincil_yedek = "FRED",
      p = 2, pencere = 48,
      alternatifler = list(FRED = list(kod = "BSCURT02TRM160S", tur = "duzey", frekans="aylik"),
                           OECD = "BSCURT02")                
    ),
    
    #NOTE    
    GENC_ISSIZLIK = list(               
      aktif = TRUE, rol = "ek", ad = "Genç İşsizlik Oranı", frekans = "yillik", birim = "%",
      kaynak = "FRED", kod = "SLUEM1524ZSTUR",
      oncelik = c("FRED", "WORLDBANK","OECD", "CSV_YEDEK"), birincil_yedek = "WORLDBANK",
      p = 2, pencere = 20,
      alternatifler = list(WORLDBANK = list(kod = "SL.UEM.1524.ZS", tur = "duzey", frekans="yillik"),
                           OECD = "DSD_EAG_LSO_EA@DF_LSO_NEAC_UNEMP")     
    ),
    
    #NOTE    
    PERAKENDE_SATIS = list(           
      aktif = TRUE, rol = "ek", ad = "Perakende Satış Hacim Endeksi", frekans = "ceyreklik",
      kaynak = "FRED", kod = "TURSLRTTO01GYSAQ",
      oncelik = c("FRED", "CSV_YEDEK"), birincil_yedek = "CSV_YEDEK",
      p = 1, pencere = 16,
    ),
    
    #NOTE    
    KONUT_FIYAT = list(
      aktif = TRUE, rol = "ek", ad = "Konut Fiyat Endeksi", frekans = "aylik",
      kaynak = "EVDS", kod = "TP_KFE_TR",
      oncelik = c("EVDS","FRED", "CSV_YEDEK"), birincil_yedek = "FRED",
      p = 12, pencere = 36,
      alternatifler = list(FRED = list(kod = "QTRN628BIS", tur = "farkli", frekans = "ceyreklik"))
    ),
    
    #NOTE    
    TURIZM_GELIRI = list(
      aktif = TRUE, rol = "ek", ad = "Turizm Gelirleri", frekans = "aylik",
      kaynak = "EVDS", kod = "TP_TURIZMGELGIT_GK178635",
      oncelik = c("EVDS","OECD", "CSV_YEDEK"), birincil_yedek = "OECD",
      p = 12, pencere = 54,
      alternatifler = list(OECD = "DSD_TOURISM_RECEIPTS") ),
    
    #NOTE    
    GINI = list(                                             # p / pencere: Excel'de boş
      aktif = TRUE, rol = "ek", ad = "Gini Endeksi", frekans = "yillik",
      kaynak = "FRED", kod = "SIPOVGINITUR",
      oncelik = c("FRED","CSV_YEDEK"), birincil_yedek = "CSV_YEDEK",
      p = 2, pencere = 20,
    )
  )
)

#NOTE
local({
  bos <- function(x) is.null(x) || length(x) == 0 || is.na(x[1])
  vs  <- function(x, y) if (bos(x)) y else x            # utils.R henüz yüklü değil
  hata <- function(...) stop("[config.R] ", ..., call. = FALSE)
  
  beklenen_kumeler <- c("proje", "baglanti", "veri", "frekanslar", "model", "guncelleme",
                        "saklama", "kaynaklar", "sunum", "gostergeler")
  eksik_kume <- setdiff(beklenen_kumeler, names(CONFIG))
  if (length(eksik_kume) > 0) hata("Eksik ayar kümesi: ", paste(eksik_kume, collapse = ", "))
  
  frekanslar    <- names(CONFIG$frekanslar)
  desteklenen   <- CONFIG$kaynaklar$desteklenen
  aktifler      <- Filter(function(g) isTRUE(g$aktif), CONFIG$gostergeler)
  
  if (!CONFIG$model$model_secimi %in% c("capraz", "varsayilan")) {
    hata("model$model_secimi 'capraz' ya da 'varsayilan' olmalı")
  }
  if (as.Date(CONFIG$veri$baslangic_tarihi) >= as.Date(CONFIG$veri$bitis_tarihi)) {
    hata("veri$baslangic_tarihi, bitis_tarihi'nden önce olmalı")
  }
  for (f in frekanslar) {                          
    fk <- CONFIG$frekanslar[[f]]
    gerekli <- c("ay_adimi", "yilda", "lag_sayisi", "pencere_uzunlugu", "p_max",
                 "pencere_adaylari", "capraz_son_n")
    yok <- setdiff(gerekli, names(fk))
    if (length(yok) > 0) hata("frekanslar$", f, " için eksik: ", paste(yok, collapse = ", "))
    if (fk$pencere_uzunlugu <= fk$lag_sayisi + 1) hata("frekanslar$", f, ": pencere, p + 1'den büyük olmalı")
  }
  
  for (ad in names(aktifler)) {
    g <- aktifler[[ad]]
    if (bos(g$kaynak) || bos(g$kod)) hata("Kaynak/kod eksik gösterge: ", ad)
    if (!g$rol %in% names(CONFIG$sunum$roller)) hata("Geçersiz rol: ", ad)
    if (!vs(g$frekans, "") %in% frekanslar) hata("Geçersiz/eksik frekans: ", ad)
    if (!vs(g$donusum, "duzey") %in% c("duzey", "yillik_degisim")) hata("Geçersiz donusum: ", ad)
    if (!g$kaynak %in% desteklenen) {
      hata("Kaynağı desteklenmeyen aktif gösterge: ", ad, " (tercümanı yoksa aktif = FALSE yap)")
    }
    
    #NOTE
    o <- g$oncelik
    if (length(o) < 2) hata(ad, ": en az bir yedek kanal tanımlı olmalı (oncelik >= 2 eleman)")
    if (!identical(o[1], g$kaynak)) hata(ad, ": oncelik[1] asıl kaynakla (", g$kaynak, ") aynı olmalı")
    if (bos(g$birincil_yedek)) hata(ad, ": birincil_yedek açıkça yazılmalı")
    if (!identical(o[2], g$birincil_yedek)) hata(ad, ": birincil_yedek, oncelik[2] ile aynı olmalı")
    yabanci <- setdiff(o, c(g$kaynak, "CSV_YEDEK", names(g$alternatifler)))
    if (length(yabanci) > 0) hata(ad, ": oncelik'te alternatifi tanımsız kaynak: ", paste(yabanci, collapse = ", "))
    if (anyDuplicated(o) > 0) hata(ad, ": oncelik'te tekrar eden kaynak var")
    
    #NOTE
    for (k in names(g$alternatifler)) {
      a <- g$alternatifler[[k]]
      if (!k %in% desteklenen) hata("Bilinmeyen alternatif kaynak '", k, "' (gösterge: ", ad, ")")
      if (is.list(a)) {
        if (bos(a$kod)) hata("Alternatif '", k, "' için kod eksik (gösterge: ", ad, ")")
        if (!vs(a$tur, "duzey") %in% c("duzey", "oran", "farkli")) hata("Alternatif '", k, "' için tur geçersiz (", ad, ")")
        if (!vs(a$frekans, g$frekans) %in% frekanslar) hata("Alternatif '", k, "' için frekans geçersiz (", ad, ")")
      }
    }
    
    #NOTE
    sira <- c(yillik = 1, ceyreklik = 2, aylik = 3)
    if (sira[[vs(g$kaynak_frekans, g$frekans)]] < sira[[g$frekans]]) {
      hata(ad, ": asıl kaynağın frekansı atanan frekanstan seyrek")
    }
    
    #NOTE
    p <- g[["p"]]; w <- g[["pencere"]]
    if (!is.null(p) && !is.null(w) && w <= p + 1) hata("Pencere (", w, ") P değerinden (", p, ") küçük/eşit: ", ad)
    if (!is.null(g[["pencere_adaylari"]]) && !is.numeric(g[["pencere_adaylari"]])) hata(ad, ": pencere_adaylari sayısal olmalı")
  }
  
  message("[config.R] Ayar merkezi yüklendi: ",
          length(CONFIG$gostergeler), " gösterge (", length(aktifler), " aktif, ",
          sum(sapply(aktifler, function(g) g$rol == "bagimli")), " bağımlı), ",
          length(setdiff(desteklenen, "CSV_YEDEK")), " kaynak + CSV yedek kanalı. ✔")
})