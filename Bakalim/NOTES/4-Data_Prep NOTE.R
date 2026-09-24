#NOTE
if (!exists("CONFIG"))  stop("[data.prep.R] Önce config.R yükle: source('R/config.R')")
if (!exists("log_msg")) stop("[data.prep.R] Önce utils.R yükle: source('R/utils.R')")
if (!exists("tum_gostergeleri_cek")) stop("[data.prep.R] Önce api_functions.R yükle")

#NOTE
suppressPackageStartupMessages({
  library(dplyr)
  library(zoo)
})

#NOTE
seri_hazirla <- function(d, g) {
  f <- gosterge_frekansi(g)
  d <- d[!is.na(d$deger), ]
  d$tarih <- donem_basi(d$tarih, f)
  d <- d[!duplicated(d$tarih, fromLast = TRUE), ]
  takvim <- donem_dizisi(min(d$tarih), max(d$tarih), f)
  deger  <- d$deger[match(takvim, d$tarih)]
  gercek <- !is.na(deger)
  deger  <- zoo::na.approx(deger, na.rm = FALSE)
  data.frame(gosterge = g, tarih = takvim, deger = deger, gercek = gercek,
             stringsAsFactors = FALSE)
}

#NOTE
ic_bosluk_say <- function(veri) sum(!veri$gercek)

#NOTE
hampel_sapan <- function(x, esik = NULL) {
  esik <- varsayilan(esik, varsayilan(CONFIG$veri$hampel_esigi, 3))
  if (length(x) < 8) return(rep(FALSE, length(x)))
  fark <- c(NA, diff(x))
  mad_ <- stats::mad(fark, na.rm = TRUE)
  if (!is.finite(mad_) || mad_ == 0) return(rep(FALSE, length(x)))
  z <- abs(fark - stats::median(fark, na.rm = TRUE)) / mad_
  !is.na(z) & z > esik
}

#NOTE
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

#NOTE
gosterge_serisi <- function(veri, g) {
  d <- veri[veri$gosterge == g, c("tarih", "deger", "gercek"), drop = FALSE]
  d <- d[order(d$tarih), , drop = FALSE]
  rownames(d) <- NULL
  d
}

#NOTE
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

#NOTE
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

#NOTE
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

#NOTE
local({
  fonksiyonlar <- c("seri_hazirla", "ic_bosluk_say", "hampel_sapan", "kalite_raporu_olustur",
                    "gosterge_serisi", "gosterge_verisi", "veriyi_hazirla", "hazir_veriyi_getir")
  eksik <- fonksiyonlar[!sapply(fonksiyonlar, exists, mode = "function")]
  if (length(eksik) > 0) {
    stop("[data.prep.R] Eksik fonksiyon: ", paste(eksik, collapse = ", "))
  }
  message("[data.prep.R] Veri hazırlama yüklendi: ", length(fonksiyonlar), " fonksiyon yerinde. ✔")
})