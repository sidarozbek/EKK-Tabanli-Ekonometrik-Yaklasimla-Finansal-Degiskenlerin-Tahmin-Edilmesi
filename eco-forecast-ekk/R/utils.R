# =============================================================================
# utils.R — Alet Çantası (Yardımcı Araçlar)
# -----------------------------------------------------------------------------
# Projenin her yerinde lazım olan küçük işler burada bir kez yazılır ve bir isim
# alır. Asıl iş yapan kod (veri çekme, hazırlama, tahmin, arayüz) bu araçları
# yalnızca çağırır. Bir aracı değiştirmek için tek nokta: burası.
#
# İLKE: Kendini tekrar etme (DRY). Aynı bilgi projede tek bir yerde yaşar.
# Yükleme sırası: config.R -> utils.R -> ...
# =============================================================================

# --- Bağımlılık bekçisi -------------------------------------------------------
if (!exists("CONFIG")) {
  stop("[utils.R] Önce config.R yükle: source('R/config.R')")
}

# =============================================================================
# 1) TEMEL ARAÇLAR
# =============================================================================

#' Nazik varsayılan
#'
#' Değer boş (NULL), sıfır uzunluklu ya da tamamen NA ise yedeği döndürür.
#' Diğer araçların "ya bu bilgi gelmezse" endişesini tek yerde toplar.
#'
#' @param deger Kontrol edilecek değer.
#' @param yedek \code{deger} boşsa kullanılacak değer.
#' @return \code{deger} ya da \code{yedek}.
#' @examples
#' varsayilan(NULL, 30)  # 30
#' varsayilan(5, 30)     # 5
varsayilan <- function(deger, yedek) {
  if (is.null(deger) || length(deger) == 0 || all(is.na(deger))) yedek else deger
}

#' Proje klasörlerini hazırla
#'
#' \code{CONFIG$saklama} altında tanımlı tüm klasörleri (yoksa) oluşturur.
#' Yükleme sırasında bir kez çalışır; ilk kurulumda elle klasör açmayı gerektirmez.
#'
#' @return Oluşturulan/var olan klasör yollarının (görünmez) vektörü.
klasor_hazirla <- function() {
  yollar <- unlist(CONFIG$saklama[grep("klasoru$", names(CONFIG$saklama))])
  for (y in yollar) dir.create(y, showWarnings = FALSE, recursive = TRUE)
  invisible(yollar)
}

#' Zaman damgalı log kaydı
#'
#' Mesajı hem Console'a hem \code{logs/calisma.log} dosyasına yazar.
#'
#' @param mesaj Metin.
#' @param seviye "BILGI", "UYARI" ya da "HATA".
#' @return Görünmez \code{NULL}.
log_msg <- function(mesaj, seviye = "BILGI") {
  satir <- paste0("[", format(Sys.time(), "%Y-%m-%d %H:%M:%S"), "] [", seviye, "] ", mesaj)
  cat(satir, "\n")
  klasor <- varsayilan(CONFIG$saklama$log_klasoru, "logs")
  dir.create(klasor, showWarnings = FALSE, recursive = TRUE)
  try(cat(satir, "\n", file = file.path(klasor, "calisma.log"), append = TRUE), silent = TRUE)
  invisible(NULL)
}

#' Dosyanın yaşı (gün)
#'
#' @param yol Dosya yolu.
#' @return Son değişiklikten bu yana geçen gün sayısı; dosya yoksa \code{Inf}.
dosya_yasi_gun <- function(yol) {
  if (!file.exists(yol)) return(Inf)
  as.numeric(difftime(Sys.time(), file.mtime(yol), units = "days"))
}

# =============================================================================
# 2) SAKLAMA — cache, CSV yedek, ikili kayıt
# =============================================================================

#' Veriyi cache'e kaydet
#'
#' @param veri Kaydedilecek nesne (öznitelikleri, örn. metaveri, korunur).
#' @param ad Dosya adı (uzantısız).
#' @return Görünmez \code{NULL}.
cache_yaz <- function(veri, ad) {
  klasor <- varsayilan(CONFIG$saklama$cache_klasoru, "data/cache")
  dir.create(klasor, showWarnings = FALSE, recursive = TRUE)
  saveRDS(veri, file.path(klasor, paste0(ad, ".rds")))
  invisible(NULL)
}

#' Cache'ten oku (tazelik denetimli)
#'
#' @param ad Dosya adı (uzantısız).
#' @param tazelik_gun Bundan eski kayıt \code{NULL} döner. \code{Inf} verilirse
#'   yaşa bakılmaz (bayat da olsa oku: son çare yedeği).
#' @return Kayıtlı nesne ya da \code{NULL}.
cache_oku <- function(ad, tazelik_gun = 1) {
  klasor <- varsayilan(CONFIG$saklama$cache_klasoru, "data/cache")
  yol <- file.path(klasor, paste0(ad, ".rds"))
  if (!file.exists(yol)) return(NULL)
  if (dosya_yasi_gun(yol) > tazelik_gun) return(NULL)   # bayatladı: yeniden çekilsin
  tryCatch(readRDS(yol), error = function(e) NULL)
}

#' CSV yedek veri setini yaz
#'
#' Başarılı her çekimden sonra \code{tarih, deger} sütunlarını
#' \code{data/yedek/<AD>.csv} olarak saklar (Risk 1 / B planı: API tamamen
#' erişilemezse son bilinen veri buradan okunur).
#'
#' @param veri \code{tarih}, \code{deger} sütunlu tablo.
#' @param ad Gösterge adı.
#' @return Görünmez \code{NULL}.
yedek_csv_yaz <- function(veri, ad) {
  klasor <- varsayilan(CONFIG$saklama$yedek_klasoru, "data/yedek")
  dir.create(klasor, showWarnings = FALSE, recursive = TRUE)
  try(utils::write.csv(veri[, c("tarih", "deger")], file.path(klasor, paste0(ad, ".csv")),
                       row.names = FALSE), silent = TRUE)
  invisible(NULL)
}

#' CSV yedek veri setini oku
#'
#' @param ad Gösterge adı.
#' @return \code{tarih, deger, kimlik} sütunlu tablo ya da \code{NULL}.
yedek_csv_oku <- function(ad) {
  yol <- file.path(varsayilan(CONFIG$saklama$yedek_klasoru, "data/yedek"), paste0(ad, ".csv"))
  if (!file.exists(yol)) return(NULL)
  d <- tryCatch(utils::read.csv(yol, stringsAsFactors = FALSE), error = function(e) NULL)
  if (is.null(d) || !all(c("tarih", "deger") %in% names(d)) || nrow(d) == 0) return(NULL)
  data.frame(tarih = as.Date(d$tarih), deger = as.numeric(d$deger), kimlik = ad)
}

#' İşlenmiş veriyi iki biçimde kaydet (RDS + CSV)
#'
#' RDS makine için (hızlı, tip korur), CSV insan için (Excel'de açılır).
#'
#' @param veri data.frame.
#' @param ad Dosya adı (uzantısız).
#' @return Görünmez \code{NULL}.
ikili_kaydet <- function(veri, ad) {
  klasor <- varsayilan(CONFIG$saklama$processed_klasoru, "data/processed")
  dir.create(klasor, showWarnings = FALSE, recursive = TRUE)
  saveRDS(veri, file.path(klasor, paste0(ad, ".rds")))
  utils::write.csv(veri, file.path(klasor, paste0(ad, ".csv")), row.names = FALSE)
  invisible(NULL)
}

#' İşlenmiş RDS dosyasını oku
#'
#' @param ad Dosya adı (uzantısız).
#' @return Nesne ya da \code{NULL}.
processed_oku <- function(ad) {
  yol <- file.path(varsayilan(CONFIG$saklama$processed_klasoru, "data/processed"),
                   paste0(ad, ".rds"))
  if (!file.exists(yol)) return(NULL)
  tryCatch(readRDS(yol), error = function(e) NULL)
}

# =============================================================================
# 3) ZAMAN SERİSİ ARAÇLARI
# =============================================================================

#' Tarihe göre böl (eğitim / sınama)
#'
#' Zaman serisinde RASTGELE bölme yasaktır: geleceği eğitime sızdırır. Veri
#' tarihe göre sıralanır, ilk \code{egitim_orani} kadarı eğitim, gerisi sınama.
#'
#' @param veri data.frame (tarihe göre sıralı).
#' @param egitim_orani 0-1 arası; boşsa \code{CONFIG$model$egitim_orani}.
#' @return \code{list(egitim = , sinama = )}.
tarihe_gore_bol <- function(veri, egitim_orani = NULL) {
  oran <- varsayilan(egitim_orani, varsayilan(CONFIG$model$egitim_orani, 0.80))
  n <- nrow(veri)
  kesim <- floor(n * oran)
  list(egitim = veri[seq_len(kesim), , drop = FALSE],
       sinama = veri[(kesim + 1):n, , drop = FALSE])
}

#' AR formülü kur
#'
#' "hedef ~ girdi1 + girdi2 + ..." kalıbını amaçtan üretir.
#'
#' @param hedef Bağımlı değişken adı.
#' @param girdiler Açıklayıcı değişken adları (gecikmeli değerler).
#' @param trend \code{TRUE} ise "trend" terimi eklenir.
#' @param mevsim \code{TRUE} ise "mevsim" terimi eklenir.
#' @return \code{formula}.
formul_kur <- function(hedef, girdiler, trend = FALSE, mevsim = FALSE) {
  terimler <- girdiler
  if (trend)  terimler <- c(terimler, "trend")
  if (mevsim) terimler <- c(terimler, "mevsim")
  stats::as.formula(paste(hedef, "~", paste(terimler, collapse = " + ")))
}

#' Sadece yeni gelen satırları ayıkla
#'
#' @param veri data.frame.
#' @param tarih_sutunu Tarih sütununun adı.
#' @param eski_tarih Bu tarihten SONRAKİ satırlar döner; \code{NULL} ise hepsi.
#' @return data.frame.
yeni_olanlar <- function(veri, tarih_sutunu, eski_tarih) {
  if (is.null(eski_tarih)) return(veri)
  veri[veri[[tarih_sutunu]] > eski_tarih, , drop = FALSE]
}

# =============================================================================
# 4) HATA YÖNETİMİ
# =============================================================================

#' Kalıcı (tekrar denemeye değmeyen) hata üret
#'
#' Yanlış anahtar (401/403) ya da olmayan seri (404) gibi durumlar tekrar
#' denemekle düzelmez; \code{tekrar_dene} bu sınıfı görünce beklemeden bırakır.
#'
#' @param mesaj Hata metni.
#' @return Hiçbir şey döndürmez; \code{stop()} eder.
kalici_hata <- function(mesaj) {
  stop(structure(class = c("kalici_hata", "error", "condition"),
                 list(message = mesaj, call = NULL)))
}

#' Geçici aksaklıkta yeniden dene
#'
#' \code{islem} hata verirse en fazla \code{deneme} kez tekrarlar. Kalıcı hata
#' (\code{kalici_hata}) tekrarlanmaz. Hepsi başarısızsa son hatayı fırlatır.
#'
#' @param islem Argümansız fonksiyon.
#' @param deneme Deneme sayısı; boşsa \code{CONFIG$baglanti$yeniden_deneme}.
#' @param bekleme Denemeler arası saniye; boşsa config'ten.
#' @return \code{islem}'in NULL olmayan sonucu.
tekrar_dene <- function(islem, deneme = NULL, bekleme = NULL) {
  n <- varsayilan(deneme, varsayilan(CONFIG$baglanti$yeniden_deneme, 3))
  b <- varsayilan(bekleme, varsayilan(CONFIG$baglanti$yeniden_deneme_bekleme, 2))
  son_hata <- NULL
  for (i in seq_len(n)) {
    sonuc <- tryCatch(islem(), error = function(e) { son_hata <<- e; NULL })
    if (!is.null(sonuc)) return(sonuc)
    if (inherits(son_hata, "kalici_hata")) break        # tekrar denemeye değmez
    if (i < n) {
      log_msg(paste0("Deneme ", i, "/", n, " başarısız, tekrar deneniyor"), "UYARI")
      Sys.sleep(b)
    }
  }
  if (is.null(son_hata)) stop("İşlem boş sonuç döndürdü", call. = FALSE)
  stop(conditionMessage(son_hata), call. = FALSE)
}

# =============================================================================
# 5) FREKANS VE DÖNEM ARAÇLARI
# Her gösterge KENDİ frekansında (aylık / çeyreklik / yıllık) işlenir. "Dönem",
# o frekansın adımıdır; tarihler dönemin İLK günüdür.
# =============================================================================

#' Frekansın ayar listesi
#'
#' @param frekans "aylik", "ceyreklik" ya da "yillik".
#' @return \code{CONFIG$frekanslar[[frekans]]}.
frekans_ayari <- function(frekans) {
  a <- CONFIG$frekanslar[[frekans]]
  if (is.null(a)) stop("Tanımsız frekans: ", frekans, call. = FALSE)
  a
}

#' Tarihi dönem başına yuvarla
#'
#' @param tarih \code{Date} vektörü.
#' @param frekans "aylik", "ceyreklik" ya da "yillik".
#' @return Dönem başı \code{Date} vektörü (ay / çeyrek / yıl başı).
donem_basi <- function(tarih, frekans) {
  adim <- frekans_ayari(frekans)$ay_adimi
  y <- as.integer(format(tarih, "%Y")); m <- as.integer(format(tarih, "%m"))
  as.Date(sprintf("%04d-%02d-01", y, ((m - 1) %/% adim) * adim + 1))
}

#' İki dönem başı arasındaki kesintisiz dönem dizisi
#'
#' @param bas,son İlk ve son dönem başı.
#' @param frekans Frekans adı.
#' @return \code{Date} vektörü.
donem_dizisi <- function(bas, son, frekans) {
  seq(bas, son, by = paste(frekans_ayari(frekans)$ay_adimi, "months"))
}

#' Bir dönemden sonraki n dönemin başlangıç tarihleri
#'
#' @param tarih Son dönem başı.
#' @param n Kaç dönem.
#' @param frekans Frekans adı.
#' @return \code{Date} vektörü (uzunluk n).
donem_ekle <- function(tarih, n, frekans) {
  seq(tarih, by = paste(frekans_ayari(frekans)$ay_adimi, "months"), length.out = n + 1)[-1]
}

#' Dönemin okunur etiketi
#'
#' Aylık "Eylül 2026", çeyreklik "2026 Ç3", yıllık "2026".
#'
#' @param tarih \code{Date} vektörü (dönem başı).
#' @param frekans Frekans adı.
#' @return Karakter vektörü.
donem_etiketi <- function(tarih, frekans) {
  aylar <- c("Ocak", "Şubat", "Mart", "Nisan", "Mayıs", "Haziran", "Temmuz", "Ağustos",
             "Eylül", "Ekim", "Kasım", "Aralık")
  y <- format(tarih, "%Y"); m <- as.integer(format(tarih, "%m"))
  switch(frekans,
         aylik     = paste(aylar[m], y),
         ceyreklik = paste0(y, " Ç", (m - 1) %/% 3 + 1),
         yillik    = y,
         format(tarih))
}

# =============================================================================
# 6) GÖSTERGE KARTI OKUYUCULARI
# Öncelik HER ZAMAN: göstergenin kartı > frekansın varsayılanı > genel
# varsayılan. Kartlar [[ ]] ile okunur: `$p`, kısmi eşleşmeyle `pencere`'yi
# yakalayabilir.
# =============================================================================

#' Aktif göstergelerin adları
#'
#' "Hangi göstergelerle çalışıyoruz?" sorusunun tek cevabı.
#'
#' @return Karakter vektörü (config'te \code{aktif = TRUE} olanlar).
aktif_gostergeler <- function() {
  names(Filter(function(g) isTRUE(g$aktif), CONFIG$gostergeler))
}

#' Göstergenin insan-okunur etiketi
#'
#' @param g Gösterge adı.
#' @return Kartın \code{ad} alanı; yoksa \code{g}.
gosterge_etiketi <- function(g) varsayilan(CONFIG$gostergeler[[g]][["ad"]], g)

#' Göstergenin frekansı
#'
#' @param g Gösterge adı.
#' @return "aylik", "ceyreklik" ya da "yillik".
gosterge_frekansi <- function(g) varsayilan(CONFIG$gostergeler[[g]][["frekans"]], "aylik")

#' Göstergenin kaynak öncelik sırası
#'
#' 1. eleman ASIL kaynak, 2. eleman BİRİNCİL YEDEK, sonrakiler sıradaki yedekler.
#'
#' @param g Gösterge adı.
#' @return Karakter vektörü.
gosterge_oncelik <- function(g) CONFIG$gostergeler[[g]][["oncelik"]]

#' Göstergenin varsayılan AR derecesi (p)
#'
#' @param g Gösterge adı.
#' @return Tamsayı.
gosterge_p <- function(g) {
  f <- gosterge_frekansi(g)
  varsayilan(CONFIG$gostergeler[[g]][["p"]],
             varsayilan(CONFIG$frekanslar[[f]][["lag_sayisi"]], varsayilan(CONFIG$model$lag_sayisi, 3)))
}

#' Göstergenin varsayılan pencere uzunluğu (kendi frekansının dönemi cinsinden)
#'
#' @param g Gösterge adı.
#' @return Tamsayı.
gosterge_pencere <- function(g) {
  f <- gosterge_frekansi(g)
  varsayilan(CONFIG$gostergeler[[g]][["pencere"]],
             varsayilan(CONFIG$frekanslar[[f]][["pencere_uzunlugu"]], varsayilan(CONFIG$model$pencere_uzunlugu, 48)))
}

#' Göstergenin tahmin ufku (dönem)
#'
#' @param g Gösterge adı.
#' @return Tamsayı (varsayılan \code{model$tahmin_ufku} = 6).
gosterge_ufuk <- function(g) {
  f <- gosterge_frekansi(g)
  varsayilan(CONFIG$gostergeler[[g]][["tahmin_ufku"]],
             varsayilan(CONFIG$frekanslar[[f]][["tahmin_ufku"]], varsayilan(CONFIG$model$tahmin_ufku, 6)))
}

#' Göstergenin aday pencereleri (çapraz doğrulama için)
#'
#' @param g Gösterge adı.
#' @return Sayısal vektör.
gosterge_pencere_adaylari <- function(g) {
  varsayilan(CONFIG$gostergeler[[g]][["pencere_adaylari"]],
             frekans_ayari(gosterge_frekansi(g))$pencere_adaylari)
}

# =============================================================================
# KENDİNİ DOĞRULAMA
# =============================================================================
klasor_hazirla()

local({
  araclar <- c("varsayilan", "klasor_hazirla", "log_msg", "dosya_yasi_gun",
               "cache_yaz", "cache_oku", "yedek_csv_yaz", "yedek_csv_oku",
               "ikili_kaydet", "processed_oku", "tarihe_gore_bol", "formul_kur",
               "yeni_olanlar", "kalici_hata", "tekrar_dene",
               "frekans_ayari", "donem_basi", "donem_dizisi", "donem_ekle", "donem_etiketi",
               "aktif_gostergeler", "gosterge_etiketi", "gosterge_frekansi", "gosterge_oncelik",
               "gosterge_p", "gosterge_pencere", "gosterge_ufuk", "gosterge_pencere_adaylari")
  eksik <- araclar[!sapply(araclar, exists, mode = "function")]
  if (length(eksik) > 0) {
    stop("[utils.R] Eksik araç: ", paste(eksik, collapse = ", "))
  }
  message("[utils.R] Alet çantası yüklendi: ", length(araclar), " araç yerinde. ✔")
})
