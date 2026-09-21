# =============================================================================
# config.R — Ayar Merkezi
# -----------------------------------------------------------------------------
# Proje : EKK Tabanlı Ekonometrik Yaklaşımla Finansal Değişkenlerin Tahmin
#         Edilmesi (TÜBİTAK 2209-A araştırma önerisi)
#
# Projenin TÜM kararları burada toplanır. İş yapan kod (api_functions.R,
# data.prep.R, models.R, app/app.R) bu dosyaya dokunmadan çalışır; yalnızca
# buradaki değerleri okur. Bir ayarı değiştirmek için tek nokta: burası.
#
# GÜVENLİK: API anahtarları bu dosyada DEĞER olarak durmaz; .Renviron'dan
# Sys.getenv() ile çağrılır. Bu dosya paylaşılabilir, .Renviron paylaşılmaz.
#   FRED_API_KEY=...   (https://fredaccount.stlouisfed.org)
#   EVDS_API_KEY=...   (https://evds3.tcmb.gov.tr  -> Profil -> API Anahtarı)
#
# AYAR MANTIĞI — HER VERİ İÇİN AYRI, YOKSA VARSAYILAN
#   Her göstergenin kartında (bölüm 8) şunlar AYRI AYRI tanımlanabilir:
#     frekans          : verinin işleneceği ve tahmin edileceği frekans
#     oncelik          : kaynak öncelik sırası (1. ASIL, 2. BİRİNCİL YEDEK, ...)
#     birincil_yedek   : birincil yedek kaynağın adı (açıkça belirtilir)
#     p                : varsayılan AR(p) derecesi
#     pencere          : varsayılan kayan pencere uzunluğu
#     tahmin_ufku      : ileriye dönük tahmin ufku
#   Kartta yazmıyorsa FREKANSA ait varsayılan (bölüm 3), o da yoksa genel
#   varsayılan (bölüm 4) geçerlidir.
#
# GÜNCELLEME MANTIĞI (her veri için, models.R -> gosterge_guncelle):
#   1) kaynak öncelikleri -> 2) frekansa göre işleme -> 3) verinin AR(p) ve
#   pencere ayarları -> 4) aday pencereler/p üzerinden ÇAPRAZ DOĞRULAMA ->
#   5) uygun model ve pencere seçimi -> 6) tahmin ufku kadar tahmin.
#
# YÜKLEME SIRASI: config.R -> utils.R -> api_functions.R -> data.prep.R
#                 -> models.R -> app/app.R
# =============================================================================

# --- Sürüm bekçisi ------------------------------------------------------------
if (getRversion() < "4.1.0") {
  warning("[config.R] R 4.3+ önerilir; bazı sözdizimleri eski sürümde çalışmayabilir.")
}

# --- Proje kökü ---------------------------------------------------------------
# Klasör yolları çalışma dizininden BAĞIMSIZ olmalı: shiny::runApp("app") çalışma
# dizinini app/ yapar, cron başka bir yerden başlatır. Kök, çalışma dizininden
# yukarı doğru "R/config.R" dosyasını arayarak bulunur.
.proje_koku <- local({
  d <- normalizePath(getwd(), winslash = "/", mustWork = FALSE)
  repeat {
    if (file.exists(file.path(d, "R", "config.R"))) return(d)
    ust <- dirname(d)
    if (identical(ust, d)) return(normalizePath(getwd(), winslash = "/", mustWork = FALSE))
    d <- ust
  }
})

# --- Anahtarların okunması ----------------------------------------------------
# Anahtarı olmayan kaynak çağrılmaz, öncelik sırasında bir sonrakine geçilir.
.fred_key <- Sys.getenv("FRED_API_KEY")
.evds_key <- Sys.getenv("EVDS_API_KEY")

if (!nzchar(.fred_key)) {
  warning("[config.R] FRED_API_KEY boş; FRED atlanacak. .Renviron'a ekleyip R'ı yeniden başlat.")
}
if (!nzchar(.evds_key)) {
  warning("[config.R] EVDS_API_KEY boş; EVDS atlanacak. .Renviron'a ekleyip R'ı yeniden başlat.")
}

# =============================================================================
# ANA AYAR LİSTESİ
# =============================================================================
CONFIG <- list(

  # ---------------------------------------------------------------------------
  # 0) PROJE — arayüzde ve raporlarda görünen kimlik bilgileri
  # ---------------------------------------------------------------------------
  proje = list(
    baslik  = "EKK Tabanlı Ekonometrik Yaklaşımla Finansal Değişkenlerin Tahmin Edilmesi",
    program = "TÜBİTAK 2209-A Üniversite Öğrencileri Araştırma Projeleri",
    kurum   = "Atılım Üniversitesi",
    surum   = "2.0.0"
  ),

  # ---------------------------------------------------------------------------
  # 1) BAĞLANTI — dış kaynaklara nasıl ve ne kadar sabırla ulaşacağız
  # ---------------------------------------------------------------------------
  baglanti = list(
    fred_key       = .fred_key,
    evds_key       = .evds_key,
    # NOT: TCMB EVDS, 2025'te evds3'e taşındı; eski evds2 adresi yönlendiriyor.
    evds_base_url  = "https://evds3.tcmb.gov.tr/igmevdsms-dis",
    oecd_base_url  = "https://sdmx.oecd.org/public/rest",
    yahoo_base_url = "https://query1.finance.yahoo.com/v8/finance/chart",
    kullanici_araci = "Mozilla/5.0 (eco-forecast-ekk; akademik arastirma)",
    zaman_asimi    = 30,
    yeniden_deneme = 3,
    yeniden_deneme_bekleme = 2
  ),

  # ---------------------------------------------------------------------------
  # 2) VERİ — genel tarih aralığı ve yedekleme kuralları
  # ---------------------------------------------------------------------------
  veri = list(
    baslangic_tarihi  = "2000-01-01",
    bitis_tarihi      = Sys.Date(),
    cache_tazelik_gun = 1,
    min_gozlem        = 8,                     # bundan az gözlemli seri geçersiz sayılır
    # Yedek kaynaklara geçiş: her verinin KENDİ öncelik sırası (kart: oncelik)
    # kullanılır. Kapatmak için FALSE: yalnız asıl kaynak denenir.
    yedek_kaynak_kullan = TRUE,
    hampel_esigi      = 3                      # sapan gözlem eşiği (MAD tabanlı z)
  ),

  # ---------------------------------------------------------------------------
  # 3) FREKANSLAR — her frekansın işlem kuralları ve VARSAYILAN model ayarları
  # Bir gösterge kendi frekansında işlenir ve tahmin edilir (aylığa dönüştürülmez).
  # Pencere ve tahmin ufku, o frekansın DÖNEM sayısıdır (aylıkta ay, çeyrekliğe
  # çeyrek, yıllıkta yıl). Pencere adayları frekansa göre ayrı tanımlanır; aylık
  # adaylar öneriye göre c(36, 42, 48, 54, 60)'tır.
  # ---------------------------------------------------------------------------
  frekanslar = list(
    aylik = list(
      etiket = "Aylık", birim = "ay", ay_adimi = 1, yilda = 12,
      lag_sayisi = 3, pencere_uzunlugu = 48, p_max = 12,
      pencere_adaylari = c(36, 42, 48, 54, 60),
      capraz_son_n = 36                        # çapraz doğrulamada tahmin edilen son n dönem
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

  # ---------------------------------------------------------------------------
  # 4) MODEL — genel varsayılanlar (frekansta/kartta yazmıyorsa geçerli)
  # ---------------------------------------------------------------------------
  model = list(
    lag_sayisi        = 3,                     # genel varsayılan p
    pencere_uzunlugu  = 48,                    # genel varsayılan pencere
    # Model seçiminin TEMEL YÖNTEMİ çapraz doğrulamadır ("capraz"): aday
    # pencerelerin ve aday p'lerin (kart p'si, AIC p'si, BIC p'si) kayan-orijinli
    # RMSE'si karşılaştırılır. "varsayilan" = seçim yapma, kart/varsayılan kullan.
    model_secimi      = "capraz",
    capraz_min_n      = 4,                     # çapraz doğrulamada en az değerlendirme dönemi
    tahmin_ufku       = 6,                     # varsayılan tahmin ufku (dönem)
    guven_duzeyi      = 0.95,
    egitim_orani      = 0.80,
    formulde_trend    = FALSE                  # saf AR: FALSE
  ),

  # ---------------------------------------------------------------------------
  # 5) GÜNCELLEME — otomatik veri güncelleme
  # Arayüz açılırken veri bu kadar günden eskiyse yenilenir. Cron ile de:
  #   Rscript -e 'setwd("~/eco-forecast-ekk"); for (f in c("config","utils",
  #     "api_functions","data.prep","models")) source(file.path("R", paste0(f,".R")));
  #     invisible(calistir_hepsi(yenile = TRUE))'
  # ---------------------------------------------------------------------------
  guncelleme = list(
    otomatik    = TRUE,
    sikligi_gun = 1
  ),

  # ---------------------------------------------------------------------------
  # 6) SAKLAMA
  # ---------------------------------------------------------------------------
  saklama = list(
    kok               = .proje_koku,
    cache_klasoru     = file.path(.proje_koku, "data", "cache"),
    processed_klasoru = file.path(.proje_koku, "data", "processed"),
    yedek_klasoru     = file.path(.proje_koku, "data", "yedek"),
    model_klasoru     = file.path(.proje_koku, "models"),
    log_klasoru       = file.path(.proje_koku, "logs")
  ),

  # ---------------------------------------------------------------------------
  # 7) KAYNAKLAR
  # CSV_YEDEK bir API değil, yedek KANALDIR: her başarılı çekimden sonra veri
  # data/yedek/<GOSTERGE>.csv olarak otomatik saklanır; API'ler erişilemezse
  # son bilinen veri buradan okunur (elle CSV de bırakılabilir: tarih, deger).
  # ---------------------------------------------------------------------------
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

  # ---------------------------------------------------------------------------
  # 7b) SUNUM — arayüz
  #   genel_varsayilan : Genel Bakış'ta varsayılan görünen grafikler
  #   genel_azami      : Genel Bakış'ta aynı anda gösterilebilecek en fazla grafik
  # ---------------------------------------------------------------------------
  sunum = list(
    roller = c(bagimli = "Bağımlı değişkenler",
               kontrol = "Kontrol değişkenleri",
               ek      = "Ek göstergeler"),
    genel_varsayilan = c("ENFLASYON", "BUYUME", "USDTRY", "ISSIZLIK"),
    genel_azami      = 4
  ),

  # ---------------------------------------------------------------------------
  # 8) GÖSTERGELER — her biri kendi "kimlik kartını" taşır
  #   aktif          : TRUE ise çekilir / tahmin edilir
  #   rol            : bagimli (öneri 2.2), kontrol, ek
  #   frekans        : "aylik" | "ceyreklik" | "yillik" — verinin işleneceği frekans
  #   kaynak_frekans : asıl kaynağın frekansı (yazılmazsa = frekans). Kaynak,
  #                    atanan frekanstan SEYREK olamaz; sıkıysa dönem ortalamasına
  #                    toplanır (aylık -> çeyreklik gibi).
  #   kaynak + kod   : ASIL kaynak ve kodu
  #   oncelik        : kaynak öncelik sırası. 1. = ASIL kaynak, 2. = BİRİNCİL YEDEK,
  #                    sonrakiler sıradaki yedekler. "CSV_YEDEK" yerel yedek kanaldır.
  #   birincil_yedek : birincil yedek kaynağın adı (oncelik[2] ile aynı olmalı)
  #   alternatifler  : yedek kaynakların kodları. Değer kod (metin) ya da
  #                    list(kod=, tur=, frekans=, filtre=, carpan=, yaklasik=):
  #                      tur      : "duzey" | "oran" | "farkli". "farkli" (tanımı/
  #                                 ölçeği farklı) asla yedek olmaz. "oran" (zaten %
  #                                 değişim) yalnız donusum = "yillik_degisim" olan
  #                                 göstergelere yedek olabilir.
  #                      frekans  : kaynağın frekansı (yazılmazsa göstergeninki)
  #                      filtre   : OECD SDMX anahtarı ya da EVDS sorgu eki
  #                      carpan   : birim farkını gidermek için çarpan
  #                      yaklasik : TRUE ise seri yakın ama aynı tanımda değil; yedek
  #                                 olarak kullanılır ve metaveride işaretlenir
  #   donusum        : modellenecek biçim: "duzey" | "yillik_degisim"
  #   p, pencere     : bu verinin varsayılan AR(p) ve pencere değeri (Excel)
  #   tahmin_ufku    : bu verinin tahmin ufku (yoksa frekansın/genel varsayılan)
  #   pencere_adaylari: bu veri için özel aday pencereler (yoksa frekansınki)
  # Kodlar Excel'deki (ekokokok.xlsx) haliyle yazılır; tercümanlar API biçimine
  # çevirir. Excel'den SAPMALAR (gerçek veriyle doğrulandı) ilgili kartta yazılıdır.
  # ---------------------------------------------------------------------------
  gostergeler = list(

    # EVDS TP_TUKFIY2025_GENEL = "Genel Endeks" (TÜFE, 2025=100) -> DÜZEY. Öneri
    # "enflasyon oranı" dediği için yıllık % değişime çevrilir; FRED/OECD yedekleri
    # aynı biçime gelir (FRED endeks -> YoY%, OECD zaten yıllık %).
    ENFLASYON = list(
      aktif = TRUE, rol = "bagimli", ad = "Enflasyon Oranı (TÜFE, yıllık %)", frekans = "aylik",
      birim = "%", donusum = "yillik_degisim",
      kaynak = "EVDS", kod = "TP_TUKFIY2025_GENEL",
      oncelik = c("EVDS", "FRED", "OECD", "CSV_YEDEK"), birincil_yedek = "FRED",
      p = 12, pencere = 42,
      alternatifler = list(
        FRED      = list(kod = "TURCPIALLMINMEI", tur = "duzey"),
        OECD      = list(kod = "OECD.SDD.TPS,DSD_PRICES_COICOP2018@DF_PRICES_C2018_ALL",
                         filtre = "TUR.M.N.CPI.PA._T.N.GY", tur = "oran"),   # yıllık değişim, %
        WORLDBANK = list(kod = "FP.CPI.TOTL.ZG", tur = "oran", frekans = "yillik")   # katalog (yıllık)
      )
    ),

    # DİKKAT (Excel'den sapma): Excel'deki EVDS TP_GSYIH20_BY_B1GQ CARİ FİYATLI
    # (nominal) GSYH'dir (yıllık değişimi ~%40). Büyüme ORANI için reel seri gerekir:
    # FRED NGDPRSAXDCTRQ (reel GSYH; yıllık değişimi %2-4). Çeyreklik işlenir.
    BUYUME = list(
      aktif = TRUE, rol = "bagimli", ad = "Ekonomik Büyüme (reel GSYH, yıllık %)", frekans = "ceyreklik",
      birim = "%", donusum = "yillik_degisim",
      kaynak = "FRED", kod = "NGDPRSAXDCTRQ",
      oncelik = c("FRED", "CSV_YEDEK"), birincil_yedek = "CSV_YEDEK",
      p = 8, pencere = 18,
      alternatifler = list(
        EVDS      = list(kod = "TP_GSYIH20_BY_B1GQ", tur = "farkli"),         # nominal GSYH
        WORLDBANK = list(kod = "WB_WDI_NY_GDP_MKTP_KD_ZG", tur = "oran", frekans = "yillik")
      )
    ),

    ISSIZLIK = list(
      aktif = TRUE, rol = "bagimli", ad = "İşsizlik Oranı", frekans = "aylik", birim = "%",
      kaynak = "EVDS", kod = "TP_YISGUCU2_G8",
      oncelik = c("EVDS", "FRED", "CSV_YEDEK"), birincil_yedek = "FRED",
      p = 5, pencere = 48,
      alternatifler = list(
        FRED      = list(kod = "LRHUTTTTTRM156S", tur = "duzey"),
        WORLDBANK = list(kod = "SL.UEM.TOTL.ZS?locations=TR", tur = "duzey", frekans = "yillik")
      )
    ),

    # DİKKAT (Excel'den sapma): Excel'deki EVDS TP_RK_T1_Y USD/TRY değil, REEL
    # EFEKTİF DÖVİZ KURU ENDEKSİ'dir (70-178). Gerçek USD/TRY: FRED CCUSMA02TRM618N
    # (Excel "OECD" sütununda). Birincil yedek: EVDS TP_DK_USD_A_YTL (aylık ortalama;
    # "_YTL" varyantı 2005 öncesini de yeni lirayla verir, düz TP_DK_USD_A eski lirayla
    # milyonlarca çıkar -> ölçek kırığı. FRED ile ortalama fark 0,017 TL).
    USDTRY = list(
      aktif = TRUE, rol = "bagimli", ad = "Döviz Kuru (USD/TRY)", frekans = "aylik", birim = "TL",
      kaynak = "FRED", kod = "CCUSMA02TRM618N",
      oncelik = c("FRED", "EVDS", "CSV_YEDEK"), birincil_yedek = "EVDS",
      p = 11, pencere = 60,
      alternatifler = list(
        EVDS      = list(kod = "TP_DK_USD_A_YTL", tur = "duzey",
                         filtre = "frequency=5&aggregationTypes=avg"),        # aylık ortalama
        WORLDBANK = list(kod = "PA.NUS.FCRF", tur = "duzey", frekans = "yillik")
      )
    ),

    BIST100 = list(                                          # Excel'de p / pencere boş
      aktif = TRUE, rol = "bagimli", ad = "Borsa Endeksi (BIST-100)", frekans = "aylik",
      kaynak = "BIST", kod = "XU100",                        # Yahoo sembolü: XU100.IS
      oncelik = c("BIST", "CSV_YEDEK"), birincil_yedek = "CSV_YEDEK"
    ),

    # Yedek FRED INTDSRTRM193N iskonto faizidir (politika faizine yakın, aynı değil).
    FAIZ = list(
      aktif = TRUE, rol = "kontrol", ad = "TCMB Politika Faizi", frekans = "aylik", birim = "%",
      kaynak = "EVDS", kod = "TP_BISPOLFAIZ_TUR",
      oncelik = c("EVDS", "FRED", "CSV_YEDEK"), birincil_yedek = "FRED",
      p = 4, pencere = 54,
      alternatifler = list(FRED = list(kod = "INTDSRTRM193N", tur = "duzey", yaklasik = TRUE))
    ),

    DIS_TICARET = list(
      aktif = TRUE, rol = "kontrol", ad = "Dış Ticaret Dengesi", frekans = "aylik",
      kaynak = "EVDS", kod = "TP_ODEAYRSUNUM6_Q4",
      oncelik = c("EVDS", "CSV_YEDEK"), birincil_yedek = "CSV_YEDEK",
      p = 12, pencere = 60,
      alternatifler = list(FRED = list(kod = "TURXTNTVA01CXMLM", tur = "farkli"))   # USD, tanım farklı
    ),

    SANAYI_URETIM = list(
      aktif = TRUE, rol = "kontrol", ad = "Sanayi Üretim Endeksi", frekans = "aylik",
      kaynak = "EVDS", kod = "TP_TSANAY2021_BCD",
      oncelik = c("EVDS", "CSV_YEDEK"), birincil_yedek = "CSV_YEDEK",
      p = 12, pencere = 60,
      alternatifler = list(FRED = list(kod = "TURPRINTO01GYSAM", tur = "oran"))   # yıllık % (düzeyle uyumsuz)
    ),

    TUKETICI_GUVEN = list(
      aktif = TRUE, rol = "kontrol", ad = "Tüketici Güven Endeksi", frekans = "aylik",
      kaynak = "EVDS", kod = "TP_TG2_Y01",
      oncelik = c("EVDS", "CSV_YEDEK"), birincil_yedek = "CSV_YEDEK",
      p = 12, pencere = 60
    ),

    CARI_DENGE = list(
      aktif = TRUE, rol = "ek", ad = "Cari İşlemler Dengesi", frekans = "ceyreklik",
      kaynak = "EVDS", kod = "TP_IMFCA_TUR",
      oncelik = c("EVDS", "OECD", "CSV_YEDEK"), birincil_yedek = "OECD",
      p = 8, pencere = 20,
      alternatifler = list(
        OECD      = list(kod = "OECD.SDD.TPS,DSD_BOP@DF_BOP",
                         filtre = "TUR.WXD.CA.B.T.Q.USD_EXC.N",          # çeyreklik, milyon USD
                         tur = "duzey", carpan = 1e6),                   # EVDS USD -> x1e6
        FRED      = list(kod = "TURB6BLTT02STSAQ", tur = "farkli"),      # GSYH oranı
        WORLDBANK = list(kod = "BN.CAB.XOKA.GD.ZS", tur = "farkli", frekans = "yillik")
      )
    ),

    BUTCE_DENGESI = list(
      aktif = TRUE, rol = "ek", ad = "Bütçe Dengesi", frekans = "aylik",
      kaynak = "EVDS", kod = "TP_KB_GEN35",
      oncelik = c("EVDS", "CSV_YEDEK"), birincil_yedek = "CSV_YEDEK",
      p = 12, pencere = 36,
      alternatifler = list(FRED = list(kod = "GGNLBATRA188N", tur = "farkli", frekans = "yillik"))
    ),

    UFE = list(
      aktif = TRUE, rol = "ek", ad = "Üretici Fiyat Endeksi (ÜFE)", frekans = "aylik",
      kaynak = "EVDS", kod = "TP_TUFE1YI_T1",
      oncelik = c("EVDS", "CSV_YEDEK"), birincil_yedek = "CSV_YEDEK",
      p = 12, pencere = 48
    ),

    M2 = list(
      aktif = TRUE, rol = "ek", ad = "M2 Para Arzı", frekans = "aylik",
      kaynak = "EVDS", kod = "TP_PBD_H09",
      oncelik = c("EVDS", "CSV_YEDEK"), birincil_yedek = "CSV_YEDEK",
      p = 12, pencere = 42
    ),

    EURTRY = list(                                           # PASİF: Excel'de henüz kod yok
      aktif = FALSE, rol = "ek", ad = "Döviz Kuru (EUR/TRY)",
      kaynak = NA_character_, kod = NA_character_
    ),

    REEL_KESIM_GUVEN = list(
      aktif = TRUE, rol = "ek", ad = "Reel Kesim Güven Endeksi", frekans = "aylik",
      kaynak = "EVDS", kod = "TP_GY1_N2",
      oncelik = c("EVDS", "CSV_YEDEK"), birincil_yedek = "CSV_YEDEK",
      p = 12, pencere = 60,
      alternatifler = list(FRED = list(kod = "BSCICP02TRM460S", tur = "farkli"))   # ölçek farklı
    ),

    KAPASITE_KULLANIM = list(
      aktif = TRUE, rol = "ek", ad = "Kapasite Kullanım Oranı", frekans = "aylik", birim = "%",
      kaynak = "EVDS", kod = "TP_KKO2_IS_TOP",
      oncelik = c("EVDS", "FRED", "CSV_YEDEK"), birincil_yedek = "FRED",
      p = 2, pencere = 48,
      alternatifler = list(FRED = list(kod = "BSCURT02TRM160S", tur = "duzey"),
                           OECD = "BSCURT02")                                    # katalog (filtresiz)
    ),

    GENC_ISSIZLIK = list(                                    # p / pencere: Excel'de boş
      aktif = TRUE, rol = "ek", ad = "Genç İşsizlik Oranı", frekans = "yillik", birim = "%",
      kaynak = "FRED", kod = "SLUEM1524ZSTUR",
      oncelik = c("FRED", "WORLDBANK", "CSV_YEDEK"), birincil_yedek = "WORLDBANK",
      alternatifler = list(WORLDBANK = list(kod = "SL.UEM.1524.ZS", tur = "duzey"),
                           OECD = "DSD_EAG_LSO_EA@DF_LSO_NEAC_UNEMP")            # katalog (filtresiz)
    ),

    PERAKENDE_SATIS = list(                                  # p / pencere: Excel'de boş
      aktif = TRUE, rol = "ek", ad = "Perakende Satış Hacim Endeksi", frekans = "ceyreklik",
      kaynak = "FRED", kod = "TURSLRTTO01GYSAQ",
      oncelik = c("FRED", "CSV_YEDEK"), birincil_yedek = "CSV_YEDEK"
    ),

    KONUT_FIYAT = list(
      aktif = TRUE, rol = "ek", ad = "Konut Fiyat Endeksi", frekans = "aylik",
      kaynak = "EVDS", kod = "TP_KFE_TR",
      oncelik = c("EVDS", "CSV_YEDEK"), birincil_yedek = "CSV_YEDEK",
      p = 12, pencere = 36,
      alternatifler = list(FRED = list(kod = "QTRN628BIS", tur = "farkli", frekans = "ceyreklik"))
    ),

    TURIZM_GELIRI = list(
      aktif = TRUE, rol = "ek", ad = "Turizm Gelirleri", frekans = "aylik",
      kaynak = "EVDS", kod = "TP_TURIZMGELGIT_GK178635",
      oncelik = c("EVDS", "CSV_YEDEK"), birincil_yedek = "CSV_YEDEK",
      p = 12, pencere = 54,
      alternatifler = list(WORLDBANK = list(kod = "ST.INT.RCPT.CD", tur = "farkli", frekans = "yillik"),
                           OECD = "DSD_TOURISM_RECEIPTS")                        # katalog (filtresiz)
    ),

    GINI = list(                                             # p / pencere: Excel'de boş
      aktif = TRUE, rol = "ek", ad = "Gini Endeksi", frekans = "yillik",
      kaynak = "FRED", kod = "SIPOVGINITUR",
      oncelik = c("FRED", "WORLDBANK", "CSV_YEDEK"), birincil_yedek = "WORLDBANK",
      alternatifler = list(WORLDBANK = list(kod = "SI.POV.GINI", tur = "duzey"))
    )
  )
)

# =============================================================================
# KENDİNİ DOĞRULAMA
# Eksik ya da çelişkili bir ayarı, çok sonra hiç beklenmedik yerde değil;
# ŞİMDİ yakala. (Kaynak zincirinin gerçekten çalışabilir olduğu api_functions.R
# yüklenirken ayrıca doğrulanır.)
# =============================================================================
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
  for (f in frekanslar) {                                # frekans ayarları tam mı
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

    # Kaynak önceliği ve BİRİNCİL YEDEK açıkça tanımlı ve tutarlı olmalı
    o <- g$oncelik
    if (length(o) < 2) hata(ad, ": en az bir yedek kanal tanımlı olmalı (oncelik >= 2 eleman)")
    if (!identical(o[1], g$kaynak)) hata(ad, ": oncelik[1] asıl kaynakla (", g$kaynak, ") aynı olmalı")
    if (bos(g$birincil_yedek)) hata(ad, ": birincil_yedek açıkça yazılmalı")
    if (!identical(o[2], g$birincil_yedek)) hata(ad, ": birincil_yedek, oncelik[2] ile aynı olmalı")
    yabanci <- setdiff(o, c(g$kaynak, "CSV_YEDEK", names(g$alternatifler)))
    if (length(yabanci) > 0) hata(ad, ": oncelik'te alternatifi tanımsız kaynak: ", paste(yabanci, collapse = ", "))
    if (anyDuplicated(o) > 0) hata(ad, ": oncelik'te tekrar eden kaynak var")

    # Alternatifler tanıdık kaynak ve geçerli tür/frekans taşımalı
    for (k in names(g$alternatifler)) {
      a <- g$alternatifler[[k]]
      if (!k %in% desteklenen) hata("Bilinmeyen alternatif kaynak '", k, "' (gösterge: ", ad, ")")
      if (is.list(a)) {
        if (bos(a$kod)) hata("Alternatif '", k, "' için kod eksik (gösterge: ", ad, ")")
        if (!vs(a$tur, "duzey") %in% c("duzey", "oran", "farkli")) hata("Alternatif '", k, "' için tur geçersiz (", ad, ")")
        if (!vs(a$frekans, g$frekans) %in% frekanslar) hata("Alternatif '", k, "' için frekans geçersiz (", ad, ")")
      }
    }

    # Asıl kaynak, atanan frekanstan seyrek olamaz (sıkılık: aylik > ceyreklik > yillik)
    sira <- c(yillik = 1, ceyreklik = 2, aylik = 3)
    if (sira[[vs(g$kaynak_frekans, g$frekans)]] < sira[[g$frekans]]) {
      hata(ad, ": asıl kaynağın frekansı atanan frekanstan seyrek")
    }

    # p ve pencere birlikte tutarlı mı
    p <- g[["p"]]; w <- g[["pencere"]]
    if (!is.null(p) && !is.null(w) && w <= p + 1) hata("Pencere (", w, ") P değerinden (", p, ") küçük/eşit: ", ad)
    if (!is.null(g[["pencere_adaylari"]]) && !is.numeric(g[["pencere_adaylari"]])) hata(ad, ": pencere_adaylari sayısal olmalı")
  }

  message("[config.R] Ayar merkezi yüklendi: ",
          length(CONFIG$gostergeler), " gösterge (", length(aktifler), " aktif, ",
          sum(sapply(aktifler, function(g) g$rol == "bagimli")), " bağımlı), ",
          length(setdiff(desteklenen, "CSV_YEDEK")), " kaynak + CSV yedek kanalı. ✔")
})
