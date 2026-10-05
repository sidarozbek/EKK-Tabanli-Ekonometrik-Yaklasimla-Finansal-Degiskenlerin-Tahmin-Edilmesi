#Bu kod, CONFIG, log_msg ve tum_gostergeleri_cek tanımlı değilse çalışmayı anında durdurarak kullanıcıdan önce ilgili dosyaları (config.R, utils.R, api_functions.R) yüklemesini isteyen bir kontrol mekanizmasıdır.
if (!exists("CONFIG"))  stop("[data.prep.R] Önce config.R yükle: source('R/config.R')")
if (!exists("log_msg")) stop("[data.prep.R] Önce utils.R yükle: source('R/utils.R')")
if (!exists("tum_gostergeleri_cek")) stop("[data.prep.R] Önce api_functions.R yükle")

#Bu kod, veri işlemede kullanılan dplyr ve zoo paketlerini ekrana yükleme mesajı basmadan sessizce yükler.
suppressPackageStartupMessages({
  library(dplyr)
  library(zoo)
})

#Bu kod, tek bir göstergenin ham verisindeki boş değerleri atar, tarihleri dönem başına çeker, aynı döneme ait tekrarlarda sonuncuyu tutar, eksiksiz bir takvim kurar ve aradaki boşlukları doğrusal interpolasyonla doldurur; hangi değerlerin gerçek, hangilerinin doldurulmuş olduğunu "gercek" sütununda işaretler.
seri_hazirla <- function(d, g) {
  f <- gosterge_frekansi(g)
  d <- d[!is.na(d$deger), ]
   if (nrow(d) == 0) stop("Seri boş (hepsi NA): ", g, call. = FALSE)   # EKLENDİ
  d <- d[order(d$tarih), ]                                            # EKLENDİ
  d$tarih <- donem_basi(d$tarih, f)
  d <- d[!duplicated(d$tarih, fromLast = TRUE), ]
  takvim <- donem_dizisi(min(d$tarih), max(d$tarih), f)
  deger  <- d$deger[match(takvim, d$tarih)]
  gercek <- !is.na(deger)
  deger  <- zoo::na.approx(deger, na.rm = FALSE)
  data.frame(gosterge = g, tarih = takvim, deger = deger, gercek = gercek,
             stringsAsFactors = FALSE)
}

#Bu kod, hazırlanmış veride "gercek" sütunu FALSE olan, yani interpolasyonla doldurulmuş gözlemlerin sayısını verir.
ic_bosluk_say <- function(veri) sum(!veri$gercek)

#Bu kod, serideki ani sıçramaları (sapan değerleri) bulur: ardışık farkları medyan ve MAD'e göre standartlaştırıp eşiği (varsayılan 3) aşanları işaretler; 8'den az gözlem varsa ya da MAD sıfırsa hiçbir şey işaretlemez.
hampel_sapan <- function(x, esik = NULL) {
  esik <- varsayilan(esik, varsayilan(CONFIG$veri$hampel_esigi, 3))
  if (length(x) < 8) return(rep(FALSE, length(x)))
  fark <- c(NA, diff(x))
  mad_ <- stats::mad(fark, na.rm = TRUE)
  if (!is.finite(mad_) || mad_ == 0) return(rep(FALSE, length(x)))
  z <- abs(fark - stats::median(fark, na.rm = TRUE)) / mad_
  !is.na(z) & z > esik
}

#Bu kod, her gösterge için veri kalite raporu üretir: frekans, gözlem sayısı, ilk ve son tarih, bitiş tarihine göre gecikme, eksik dönem oranı, sapan değer sayısı ve ilk üç sapan tarihi; hepsini tek tabloda birleştirir.
kalite_raporu_olustur <- function(uzun) {
  bugun <- as.Date(CONFIG$veri$bitis_tarihi)
  *** bugun <- as.Date(varsayilan(CONFIG$veri$bitis_tarihi, Sys.Date()))          # DEĞİŞTİ
  satirlar <- lapply(unique(uzun$kimlik), function(g) {
    f <- gosterge_frekansi(g)
    d <- uzun[uzun$kimlik == g, ]; d <- d[order(d$tarih), ]
    ***  d <- uzun[uzun$kimlik == g & !is.na(uzun$deger), ]                       # DEĞİŞTİ
      d <- d[order(d$tarih), ]                                                    # DEĞİŞTİ
    d$tarih <- donem_basi(d$tarih, f)
     d <- d[!duplicated(d$tarih, fromLast = TRUE), ]                              # EKLENDİ
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


#Bu kod, hazır veriden seçilen göstergenin tarih, değer ve gerçek sütunlarını tarihe göre sıralı küçük bir tablo olarak verir.
gosterge_serisi <- function(veri, g) {
  d <- veri[veri$gosterge == g, c("tarih", "deger", "gercek"), drop = FALSE]
  d <- d[order(d$tarih), , drop = FALSE]
  rownames(d) <- NULL
  d
}

#Uyarı: trend atılan satırlardan önce üretildiği için 1 yerine p+1'den başlar (modeli bozmaz, istersen complete.cases satırından sonraya taşırsın). p gözlem sayısından büyükse tablo sessizce boş döner, ona bir uyarı eklenebilir.
#Bu kod, seçilen gösterge için modele hazır tablo kurar: değerin yanına p tane gecikmeli (lag) sütun ekler, istenirse trend sütunu koyar ve gecikme yüzünden boş kalan ilk satırları atar.
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

#Uyarı: Küçük bir eksik: ham boşsa rbind NULL döner ve rownames<- hata verir. Fonksiyonun başına if (is.null(ham) || nrow(ham) == 0) stop("Ham veri boş") eklenebilir.
#Bu kod, ham verideki tüm göstergeleri kendi frekansında tek tek hazırlayıp birleştirir, hazır veriyi ve kalite raporunu processed klasörüne kaydeder ve kaç gözlemin interpolasyonla doldurulduğunu loglar.
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

#Bu kod, hazır veriyi getiren ana fonksiyondur: kayıtlı dosya yeterince tazeyse (varsayılan 1 gün) onu kullanır, bayatsa ya da yoksa kaynaklardan çekip yeniden hazırlar; çekim başarısız olursa eldeki eski veriyi korur, o da yoksa hata verip durur.
hazir_veriyi_getir <- function(yenile = FALSE) {
  yol <- file.path(CONFIG$saklama$processed_klasoru, "hazir_veri.rds")
***  yol <- file.path(varsayilan(CONFIG$saklama$processed_klasoru, "data/processed"), "hazir_veri.rds")                                       # DEĞİŞTİ
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

#Bu kod, dosyanın sonunda 8 fonksiyonun hepsinin tanımlı olduğunu doğrular; eksik varsa hata verir, yoksa "yüklendi" mesajı yazar.
local({
  fonksiyonlar <- c("seri_hazirla", "ic_bosluk_say", "hampel_sapan", "kalite_raporu_olustur",
                    "gosterge_serisi", "gosterge_verisi", "veriyi_hazirla", "hazir_veriyi_getir")
  eksik <- fonksiyonlar[!sapply(fonksiyonlar, exists, mode = "function")]
  if (length(eksik) > 0) {
    stop("[data.prep.R] Eksik fonksiyon: ", paste(eksik, collapse = ", "))
  }
  message("[data.prep.R] Veri hazırlama yüklendi: ", length(fonksiyonlar), " fonksiyon yerinde. ✔")
})
