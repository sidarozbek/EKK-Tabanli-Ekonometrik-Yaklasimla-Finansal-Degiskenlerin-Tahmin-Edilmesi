# =============================================================================
# data.prep.R — Veri Hazırlama (Frekansa Göre İşleme, Doldurma, Kalite Kontrol)
# -----------------------------------------------------------------------------
# Her gösterge KENDİ frekansında (aylık / çeyreklik / yıllık) işlenir ve tahmin
# edilir; ortak bir aylık takvime dönüştürülmez. Böylece çeyreklik ve yıllık
# serilerde interpolasyonla uydurulmuş aylık değerler modele girmez.
#
# Bu katman: (1) her seriyi kendi dönem takvimine oturtur, (2) iki gerçek
# gözlem ARASINDAKİ eksik dönemleri doğrusal interpolasyonla doldurur (baş ve
# sona dokunmaz: olmayan geçmiş uydurulmaz), (3) AR modeli için gecikmeleri
# gösterge bazında üretir (gosterge_verisi), (4) veri kalitesini raporlar
# (öneri Risk 2: kalite kontrol, sapan gözlem işaretleme).
#
# Çıktı UZUN biçimlidir: gosterge, tarih, deger, gercek (gercek = FALSE ise
# değer interpolasyonla dolduruldu).
#
# Yükleme sırası: config.R -> utils.R -> api_functions.R -> data.prep.R -> ...
# =============================================================================

# --- Bağımlılık bekçileri -----------------------------------------------------
if (!exists("CONFIG"))  stop("[data.prep.R] Önce config.R yükle: source('R/config.R')")
if (!exists("log_msg")) stop("[data.prep.R] Önce utils.R yükle: source('R/utils.R')")
if (!exists("tum_gostergeleri_cek")) stop("[data.prep.R] Önce api_functions.R yükle")

# --- Paketler -----------------------------------------------------------------
# install.packages(c("dplyr", "zoo"))
suppressPackageStartupMessages({
  library(dplyr)      # gecikme (lag)
  library(zoo)        # interpolasyon (na.approx)
})

# =============================================================================
# 1) TEK SERİYİ KENDİ FREKANSINA OTURT
# =============================================================================

#' Bir seriyi kendi dönem takvimine oturt ve iç boşlukları doldur
#'
#' Seri, ilk ve son gözlemi arasında kesintisiz bir dönem takvimine (gösterge
#' frekansına göre ay / çeyrek / yıl) yerleştirilir. Aradaki eksik dönemler
#' doğrusal interpolasyonla doldurulur; ilk gözlemden öncesine ve son gözlemden
#' sonrasına DOKUNULMAZ. Bu bir TAHMİNDİR; \code{gercek = FALSE} ile işaretlenir.
#'
#' @param d \code{data.frame(tarih, deger)} (dönem başı tarihli).
#' @param g Gösterge adı.
#' @return \code{data.frame(gosterge, tarih, deger, gercek)}.
seri_hazirla <- function(d, g) {
  f <- gosterge_frekansi(g)
  d <- d[!is.na(d$deger), ]
  d$tarih <- donem_basi(d$tarih, f)
  d <- d[!duplicated(d$tarih, fromLast = TRUE), ]
  takvim <- donem_dizisi(min(d$tarih), max(d$tarih), f)
  deger  <- d$deger[match(takvim, d$tarih)]
  gercek <- !is.na(deger)
  deger  <- zoo::na.approx(deger, na.rm = FALSE)           # yalnız iki gözlem arası
  data.frame(gosterge = g, tarih = takvim, deger = deger, gercek = gercek,
             stringsAsFactors = FALSE)
}

#' İç (interpolasyonla doldurulmuş) dönemleri say
#'
#' @param veri Hazır uzun tablo.
#' @return Doldurulmuş (\code{gercek = FALSE}) satır sayısı.
ic_bosluk_say <- function(veri) sum(!veri$gercek)

# =============================================================================
# 2) KALİTE KONTROL (öneri Risk 2)
# =============================================================================

#' Hampel sapan gözlem işaretleyici
#'
#' Ardışık farkların medyan ve MAD'ine göre robust z-skoru hesaplar;
#' \code{|z| > esik} olan gözlemleri işaretler. Veriyi DEĞİŞTİRMEZ.
#'
#' @param x Sayısal vektör (tarihe göre sıralı).
#' @param esik z-skoru eşiği; boşsa \code{CONFIG$veri$hampel_esigi}.
#' @return Mantıksal vektör (\code{x} ile aynı uzunlukta).
hampel_sapan <- function(x, esik = NULL) {
  esik <- varsayilan(esik, varsayilan(CONFIG$veri$hampel_esigi, 3))
  if (length(x) < 8) return(rep(FALSE, length(x)))
  fark <- c(NA, diff(x))
  mad_ <- stats::mad(fark, na.rm = TRUE)
  if (!is.finite(mad_) || mad_ == 0) return(rep(FALSE, length(x)))
  z <- abs(fark - stats::median(fark, na.rm = TRUE)) / mad_
  !is.na(z) & z > esik
}

#' Veri kalite raporu
#'
#' Her gösterge için frekans, gözlem sayısı, tarih aralığı, güncellik gecikmesi
#' (dönem cinsinden), eksik dönem oranı ve Hampel sapan gözlem sayısı.
#'
#' @param uzun Ham uzun tablo \code{data.frame(tarih, deger, kimlik)} (dönüştürülmüş).
#' @return data.frame: gosterge, ad, rol, frekans, gozlem, ilk_tarih, son_tarih,
#'   gecikme_donem, eksik_donem_orani, sapan_sayisi, sapan_tarihleri.
kalite_raporu_olustur <- function(uzun) {
  bugun <- as.Date(CONFIG$veri$bitis_tarihi)
  satirlar <- lapply(unique(uzun$kimlik), function(g) {
    f <- gosterge_frekansi(g)
    d <- uzun[uzun$kimlik == g, ]; d <- d[order(d$tarih), ]
    d$tarih <- donem_basi(d$tarih, f)
    kapsam <- length(donem_dizisi(min(d$tarih), max(d$tarih), f))
    gecikme <- max(0, length(donem_dizisi(max(d$tarih), max(donem_basi(bugun, f), max(d$tarih)), f)) - 1)
    sapan <- hampel_sapan(d$deger)
    kart <- CONFIG$gostergeler[[g]]
    data.frame(
      gosterge = g, ad = varsayilan(kart$ad, g), rol = varsayilan(kart$rol, NA), frekans = f,
      gozlem = nrow(d), ilk_tarih = min(d$tarih), son_tarih = max(d$tarih),
      gecikme_donem = gecikme, eksik_donem_orani = round(1 - nrow(d) / kapsam, 3),
      sapan_sayisi = sum(sapan),
      sapan_tarihleri = paste(utils::head(format(d$tarih[sapan], "%Y-%m"), 3), collapse = ", "),
      stringsAsFactors = FALSE)
  })
  do.call(rbind, satirlar)
}

# =============================================================================
# 3) AR VERİSİ
# =============================================================================

#' Bir göstergenin serisi
#'
#' @param veri Hazır uzun tablo.
#' @param g Gösterge adı.
#' @return \code{data.frame(tarih, deger, gercek)} (tarihe göre sıralı).
gosterge_serisi <- function(veri, g) {
  d <- veri[veri$gosterge == g, c("tarih", "deger", "gercek"), drop = FALSE]
  d <- d[order(d$tarih), , drop = FALSE]
  rownames(d) <- NULL
  d
}

#' Bir göstergenin AR model verisini üret
#'
#' Göstergenin KENDİ serisinden gecikmeleri (\code{<G>_lag1 ... <G>_lagP})
#' üretir ve tüm sütunları dolu satırları tutar. Her gösterge kendi tarih
#' aralığında ve kendi frekansında modellenir; başka bir serinin başlangıcı ya
#' da bitişi onu kısaltmaz.
#'
#' @param veri Hazır uzun tablo.
#' @param g Gösterge adı.
#' @param p Gecikme sayısı; boşsa göstergenin varsayılan p'si.
#' @param trend \code{TRUE} ise \code{trend} sütunu da eklenir.
#' @return data.frame: \code{tarih}, \code{g}, \code{g_lag1..g_lagP}.
gosterge_verisi <- function(veri, g, p = NULL, trend = FALSE) {
  p <- varsayilan(p, gosterge_p(g))
  d <- gosterge_serisi(veri, g)
  if (nrow(d) == 0) stop("Hazır veride yok: ", g, " (gösterge çekilememiş olabilir)", call. = FALSE)
  out <- data.frame(tarih = d$tarih)
  out[[g]] <- d$deger
  for (k in seq_len(p)) out[[paste0(g, "_lag", k)]] <- dplyr::lag(d$deger, k)
  if (trend) out$trend <- seq_len(nrow(out))
  out <- out[stats::complete.cases(out), , drop = FALSE]
  rownames(out) <- NULL
  out
}

# =============================================================================
# 4) TEK AKIŞ
# =============================================================================

#' Ham uzun tabloyu uçtan uca hazır veriye çevir
#'
#' Her gösterge kendi frekansında \code{seri_hazirla} ile işlenir. Sonuç
#' \code{data/processed/hazir_veri} (RDS + CSV) olarak kaydedilir; kalite raporu
#' \code{kalite_raporu} olarak kaydedilir.
#'
#' @param ham \code{tum_gostergeleri_cek} çıktısı (uzun: tarih, deger, kimlik).
#' @return Hazır uzun tablo.
veriyi_hazirla <- function(ham) {
  log_msg("Veri hazırlama akışı başladı (her gösterge kendi frekansında)")
  parcalar <- lapply(unique(ham$kimlik), function(g) {
    seri_hazirla(ham[ham$kimlik == g, c("tarih", "deger")], g)
  })
  sonuc <- do.call(rbind, parcalar)
  rownames(sonuc) <- NULL
  ikili_kaydet(sonuc, "hazir_veri")
  ikili_kaydet(kalite_raporu_olustur(ham), "kalite_raporu")
  log_msg(paste0("Veri hazırlama bitti: ", length(parcalar), " gösterge, ", nrow(sonuc),
                 " gözlem (interpolasyonla doldurulan: ", ic_bosluk_say(sonuc), "); kaydedildi"))
  sonuc
}

#' Hazır veriyi getir (gerekirse API'den yenile)
#'
#' Hazır veri varsa ve taze ise (\code{guncelleme$sikligi_gun}) okunur. Bayatsa
#' (ve \code{guncelleme$otomatik} açıksa) ya da \code{yenile = TRUE} ise
#' göstergeler kendi kaynak öncelikleriyle çekilip baştan hazırlanır. Çekim
#' başarısız olursa mevcut (bayat) hazır veri korunur: çökmez.
#'
#' @param yenile \code{TRUE} ise kaynaklardan zorla yenile.
#' @return Hazır uzun tablo.
hazir_veriyi_getir <- function(yenile = FALSE) {
  yol <- file.path(CONFIG$saklama$processed_klasoru, "hazir_veri.rds")
  # Eski sürümün (geniş, aylık) kaydı ya da bozuk dosya "hazır veri" sayılmaz: yeniden üretilir.
  oku <- function() {
    x <- if (file.exists(yol)) tryCatch(readRDS(yol), error = function(e) NULL) else NULL
    if (is.data.frame(x) && all(c("gosterge", "tarih", "deger", "gercek") %in% names(x))) x else NULL
  }
  mevcut <- oku()
  if (file.exists(yol) && is.null(mevcut)) {
    log_msg("Kayıtlı hazır veri eski/bozuk biçimde; yeniden oluşturuluyor", "UYARI")
  }
  taze <- !is.null(mevcut) && dosya_yasi_gun(yol) <= varsayilan(CONFIG$guncelleme$sikligi_gun, 1)
  if (!is.null(mevcut) && !yenile && (taze || !isTRUE(CONFIG$guncelleme$otomatik))) {
    log_msg("Hazır veri bulundu, kullanılıyor")
    return(mevcut)
  }
  log_msg(if (yenile) "Veri yenileniyor (kaynaklar)" else "Hazır veri bayat/yok; kaynaklardan güncelleniyor")
  ham <- tryCatch(tum_gostergeleri_cek(yenile = yenile), error = function(e) {
    log_msg(paste("Çekim hatası:", conditionMessage(e)), "HATA"); NULL })
  if (is.null(ham)) {
    if (!is.null(mevcut)) {
      log_msg("Güncelleme başarısız; mevcut hazır veri korunuyor", "UYARI")
      return(mevcut)
    }
    stop("Hazır veri yok ve hiçbir gösterge çekilemedi (anahtarları/bağlantıyı kontrol et)")
  }
  veriyi_hazirla(ham)
}

# =============================================================================
# KENDİNİ DOĞRULAMA
# =============================================================================
local({
  fonksiyonlar <- c("seri_hazirla", "ic_bosluk_say", "hampel_sapan", "kalite_raporu_olustur",
                    "gosterge_serisi", "gosterge_verisi", "veriyi_hazirla", "hazir_veriyi_getir")
  eksik <- fonksiyonlar[!sapply(fonksiyonlar, exists, mode = "function")]
  if (length(eksik) > 0) {
    stop("[data.prep.R] Eksik fonksiyon: ", paste(eksik, collapse = ", "))
  }
  message("[data.prep.R] Veri hazırlama yüklendi: ", length(fonksiyonlar), " fonksiyon yerinde. ✔")
})
