#NOTE
if (!exists("CONFIG")) {
  stop("[utils.R] Önce config.R yükle: source('R/config.R')")
}

#NOTE
varsayilan <- function(deger, yedek) {
  if (is.null(deger) || length(deger) == 0 || all(is.na(deger))) yedek else deger
}

#NOTE
klasor_hazirla <- function() {
  yollar <- unlist(CONFIG$saklama[grep("klasoru$", names(CONFIG$saklama))])
  for (y in yollar) dir.create(y, showWarnings = FALSE, recursive = TRUE)
  invisible(yollar)
}

#NOTE
log_msg <- function(mesaj, seviye = "BILGI") {
  satir <- paste0("[", format(Sys.time(), "%Y-%m-%d %H:%M:%S"), "] [", seviye, "] ", mesaj)
  cat(satir, "\n")
  klasor <- varsayilan(CONFIG$saklama$log_klasoru, "logs")
  dir.create(klasor, showWarnings = FALSE, recursive = TRUE)
  try(cat(satir, "\n", file = file.path(klasor, "calisma.log"), append = TRUE), silent = TRUE)
  invisible(NULL)
}

#NOTE
dosya_yasi_gun <- function(yol) {
  if (!file.exists(yol)) return(Inf)
  as.numeric(difftime(Sys.time(), file.mtime(yol), units = "days"))
}

#NOTE
cache_yaz <- function(veri, ad) {
  klasor <- varsayilan(CONFIG$saklama$cache_klasoru, "data/cache")
  dir.create(klasor, showWarnings = FALSE, recursive = TRUE)
  saveRDS(veri, file.path(klasor, paste0(ad, ".rds")))
  invisible(NULL)
}

#NOTE
cache_oku <- function(ad, tazelik_gun = 1) {
  klasor <- varsayilan(CONFIG$saklama$cache_klasoru, "data/cache")
  yol <- file.path(klasor, paste0(ad, ".rds"))
  if (!file.exists(yol)) return(NULL)
  if (dosya_yasi_gun(yol) > tazelik_gun) return(NULL)
  tryCatch(readRDS(yol), error = function(e) NULL)
}

#NOTE
yedek_csv_yaz <- function(veri, ad) {
  klasor <- varsayilan(CONFIG$saklama$yedek_klasoru, "data/yedek")
  dir.create(klasor, showWarnings = FALSE, recursive = TRUE)
  try(utils::write.csv(veri[, c("tarih", "deger")], file.path(klasor, paste0(ad, ".csv")),
                       row.names = FALSE), silent = TRUE)
  invisible(NULL)
}

#NOTE
yedek_csv_oku <- function(ad) {
  yol <- file.path(varsayilan(CONFIG$saklama$yedek_klasoru, "data/yedek"), paste0(ad, ".csv"))
  if (!file.exists(yol)) return(NULL)
  d <- tryCatch(utils::read.csv(yol, stringsAsFactors = FALSE), error = function(e) NULL)
  if (is.null(d) || !all(c("tarih", "deger") %in% names(d)) || nrow(d) == 0) return(NULL)
  data.frame(tarih = as.Date(d$tarih), deger = as.numeric(d$deger), kimlik = ad)
}

#NOTE
ikili_kaydet <- function(veri, ad) {
  klasor <- varsayilan(CONFIG$saklama$processed_klasoru, "data/processed")
  dir.create(klasor, showWarnings = FALSE, recursive = TRUE)
  saveRDS(veri, file.path(klasor, paste0(ad, ".rds")))
  utils::write.csv(veri, file.path(klasor, paste0(ad, ".csv")), row.names = FALSE)
  invisible(NULL)
}

#NOTE
processed_oku <- function(ad) {
  yol <- file.path(varsayilan(CONFIG$saklama$processed_klasoru, "data/processed"),
                   paste0(ad, ".rds"))
  if (!file.exists(yol)) return(NULL)
  tryCatch(readRDS(yol), error = function(e) NULL)
}

#NOTE
tarihe_gore_bol <- function(veri, egitim_orani = NULL) {
  oran <- varsayilan(egitim_orani, varsayilan(CONFIG$model$egitim_orani, 0.80))
  n <- nrow(veri)
  kesim <- floor(n * oran)
  list(egitim = veri[seq_len(kesim), , drop = FALSE],
       sinama = veri[(kesim + 1):n, , drop = FALSE])
}

#NOTE
formul_kur <- function(hedef, girdiler, trend = FALSE, mevsim = FALSE) {
  terimler <- girdiler
  if (trend)  terimler <- c(terimler, "trend")
  if (mevsim) terimler <- c(terimler, "mevsim")
  stats::as.formula(paste(hedef, "~", paste(terimler, collapse = " + ")))
}

#NOTE
yeni_olanlar <- function(veri, tarih_sutunu, eski_tarih) {
  if (is.null(eski_tarih)) return(veri)
  veri[veri[[tarih_sutunu]] > eski_tarih, , drop = FALSE]
}

#NOTE
kalici_hata <- function(mesaj) {
  stop(structure(class = c("kalici_hata", "error", "condition"),
                 list(message = mesaj, call = NULL)))
}

#NOTE
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

#NOTE
donem_basi <- function(tarih, frekans) {
  adim <- frekans_ayari(frekans)$ay_adimi
  y <- as.integer(format(tarih, "%Y")); m <- as.integer(format(tarih, "%m"))
  as.Date(sprintf("%04d-%02d-01", y, ((m - 1) %/% adim) * adim + 1))
}

#NOTE
donem_dizisi <- function(bas, son, frekans) {
  seq(bas, son, by = paste(frekans_ayari(frekans)$ay_adimi, "months"))
}

#NOTE
donem_ekle <- function(tarih, n, frekans) {
  seq(tarih, by = paste(frekans_ayari(frekans)$ay_adimi, "months"), length.out = n + 1)[-1]
}

#NOTE
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

#NOTE
aktif_gostergeler <- function() {
  names(Filter(function(g) isTRUE(g$aktif), CONFIG$gostergeler))
}

#NOTE
gosterge_etiketi <- function(g) varsayilan(CONFIG$gostergeler[[g]][["ad"]], g)

#NOTE
gosterge_frekansi <- function(g) varsayilan(CONFIG$gostergeler[[g]][["frekans"]], "aylik")

#NOTE
gosterge_oncelik <- function(g) CONFIG$gostergeler[[g]][["oncelik"]]

#NOTE
gosterge_p <- function(g) {
  f <- gosterge_frekansi(g)
  varsayilan(CONFIG$gostergeler[[g]][["p"]],
             varsayilan(CONFIG$frekanslar[[f]][["lag_sayisi"]], varsayilan(CONFIG$model$lag_sayisi, 3)))
}

#NOTE
gosterge_pencere <- function(g) {
  f <- gosterge_frekansi(g)
  varsayilan(CONFIG$gostergeler[[g]][["pencere"]],
             varsayilan(CONFIG$frekanslar[[f]][["pencere_uzunlugu"]], varsayilan(CONFIG$model$pencere_uzunlugu, 48)))
}

#NOTE
gosterge_ufuk <- function(g) {
  f <- gosterge_frekansi(g)
  varsayilan(CONFIG$gostergeler[[g]][["tahmin_ufku"]],
             varsayilan(CONFIG$frekanslar[[f]][["tahmin_ufku"]], varsayilan(CONFIG$model$tahmin_ufku, 6)))
}

#NOTE
gosterge_pencere_adaylari <- function(g) {
  varsayilan(CONFIG$gostergeler[[g]][["pencere_adaylari"]],
             frekans_ayari(gosterge_frekansi(g))$pencere_adaylari)
}

#NOTE
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

