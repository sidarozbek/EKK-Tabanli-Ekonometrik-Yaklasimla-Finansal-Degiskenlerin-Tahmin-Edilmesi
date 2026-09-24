#NOTE
if (!exists("CONFIG"))          stop("[models.R] Önce config.R yükle: source('R/config.R')")
if (!exists("formul_kur"))      stop("[models.R] Önce utils.R yükle: source('R/utils.R')")
if (!exists("gosterge_verisi")) stop("[models.R] Önce data.prep.R yükle: source('R/data.prep.R')")

#NOTE
mae <- function(gercek, tahmin) mean(abs(gercek - tahmin), na.rm = TRUE)

#NOTE
mse <- function(gercek, tahmin) mean((gercek - tahmin)^2, na.rm = TRUE)

#NOTE
rmse <- function(gercek, tahmin) sqrt(mse(gercek, tahmin))

#NOTE
mape <- function(gercek, tahmin) {
  gecerli <- gercek != 0 & !is.na(gercek) & !is.na(tahmin)
  100 * mean(abs((gercek[gecerli] - tahmin[gecerli]) / gercek[gecerli]))
}

#NOTE
theil_u <- function(gercek, tahmin) {
  ok <- !is.na(gercek) & !is.na(tahmin)
  sqrt(sum((tahmin[ok] - gercek[ok])^2)) / sqrt(sum(gercek[ok]^2))
}

#NOTE
basit_ar <- function(veri, gosterge, p = NULL) {
  p <- varsayilan(p, gosterge_p(gosterge))
  d <- gosterge_verisi(veri, gosterge, p)
  lm(formul_kur(gosterge, paste0(gosterge, "_lag", seq_len(p))), data = d)
}

#NOTE
kayan_pencere_tahmin <- function(veri, gosterge, pencere = NULL, p = NULL, son_n = NULL) {
  p <- varsayilan(p, gosterge_p(gosterge))
  w <- varsayilan(pencere, gosterge_pencere(gosterge))
  trend <- isTRUE(CONFIG$model$formulde_trend)
  d <- gosterge_verisi(veri, gosterge, p, trend = trend)
  formul <- formul_kur(gosterge, paste0(gosterge, "_lag", seq_len(p)), trend = trend)
  n <- nrow(d)
  
  if (w <= p + 1 + trend) {
    stop("Pencere (", w, ") lag sayısına (", p, ") göre çok küçük: ", gosterge, call. = FALSE)
  }
  if (n <= w) stop("Veri (", n, " satır) pencereden (", w, ") kısa: ", gosterge, call. = FALSE)
  
  t_ilk <- if (is.null(son_n)) w else max(w, n - son_n)
  idx <- t_ilk:(n - 1)
  m <- length(idx)
  gercek <- tahmin <- naif <- numeric(m)
  tarih  <- as.Date(rep(NA, m))
  ic     <- matrix(NA_real_, m, 3)
  
  for (i in seq_len(m)) {
    t       <- idx[i]
    egitim  <- d[(t - w + 1):t, , drop = FALSE]
    model   <- lm(formul, data = egitim)
    sonraki <- d[t + 1, , drop = FALSE]
    tahmin[i] <- suppressWarnings(as.numeric(predict(model, newdata = sonraki)))
    gercek[i] <- sonraki[[gosterge]]
    naif[i]   <- sonraki[[paste0(gosterge, "_lag1")]]
    tarih[i]  <- sonraki$tarih
    
    hata <- stats::residuals(model); y <- egitim[[gosterge]]
    ic[i, ] <- c(mean(abs(hata)), mean(hata^2),
                 100 * mean(abs(hata[y != 0] / y[y != 0])))
  }
  s <- data.frame(tarih = tarih, gercek = gercek, tahmin = tahmin, naif = naif)
  attr(s, "p") <- p
  attr(s, "pencere") <- w
  attr(s, "ornek_ici") <- c(MAE = mean(ic[, 1]), MSE = mean(ic[, 2]),
                            RMSE = sqrt(mean(ic[, 2])), MAPE = mean(ic[, 3], na.rm = TRUE))
  s
}

#NOTE
metrikler <- function(s) {
  ic <- attr(s, "ornek_ici")
  naif_rmse <- rmse(s$gercek, s$naif)
  data.frame(
    MAE = mae(s$gercek, s$tahmin), MSE = mse(s$gercek, s$tahmin),
    RMSE = rmse(s$gercek, s$tahmin), MAPE = mape(s$gercek, s$tahmin),
    THEIL_U = theil_u(s$gercek, s$tahmin),
    NAIF_RMSE = naif_rmse, GORELI_RMSE = rmse(s$gercek, s$tahmin) / naif_rmse,
    IC_MAE = unname(ic["MAE"]), IC_RMSE = unname(ic["RMSE"]), IC_MAPE = unname(ic["MAPE"])
  )
}

#NOTE
p_sec <- function(veri, gosterge, kriter = "AIC", p_max = NULL) {
  p_max <- varsayilan(p_max, frekans_ayari(gosterge_frekansi(gosterge))$p_max)
  n <- nrow(gosterge_serisi(veri, gosterge))
  p_ust <- min(p_max, floor(n / 4))
  if (p_ust < 1) stop("Gecikme seçimi için veri yetersiz: ", gosterge, call. = FALSE)
  d <- gosterge_verisi(veri, gosterge, p_ust)
  tablo <- do.call(rbind, lapply(seq_len(p_ust), function(p) {
    m <- lm(formul_kur(gosterge, paste0(gosterge, "_lag", seq_len(p))), data = d)
    data.frame(p = p, AIC = stats::AIC(m), BIC = stats::BIC(m))
  }))
  list(p = tablo$p[which.min(tablo[[kriter]])], tablo = tablo)
}

#NOTE
model_sec <- function(veri, g) {
  p0 <- gosterge_p(g); w0 <- gosterge_pencere(g)
  varsayilan_sonuc <- list(p = p0, pencere = w0, yontem = "varsayilan", tablo = NULL, son_n = NA)
  if (!identical(CONFIG$model$model_secimi, "capraz")) return(varsayilan_sonuc)
  
  fk <- frekans_ayari(gosterge_frekansi(g))
  p_adaylari <- unique(c(p0,
                         tryCatch(p_sec(veri, g, "AIC")$p, error = function(e) NULL),
                         tryCatch(p_sec(veri, g, "BIC")$p, error = function(e) NULL)))
  w_adaylari <- sort(unique(gosterge_pencere_adaylari(g)))
  n_p <- sapply(p_adaylari, function(p) nrow(gosterge_verisi(veri, g, p)))
  min_n <- varsayilan(CONFIG$model$capraz_min_n, 4)
  
  for (son_n in unique(c(fk$capraz_son_n, ceiling(fk$capraz_son_n / 2), min_n))) {
    if (son_n < min_n) next
    izgara <- do.call(rbind, lapply(seq_along(p_adaylari), function(i) {
      w <- w_adaylari[w_adaylari > p_adaylari[i] + 1 & w_adaylari <= n_p[i] - son_n]
      if (length(w) == 0) NULL else data.frame(p = p_adaylari[i], pencere = w)
    }))
    if (!is.null(izgara) && nrow(izgara) > 0) break
    izgara <- NULL
  }
  if (is.null(izgara)) {
    varsayilan_sonuc$yontem <- "varsayilan"
    return(varsayilan_sonuc)
  }
  
  izgara$RMSE <- NA_real_; izgara$MAE <- NA_real_
  for (i in seq_len(nrow(izgara))) {
    s <- tryCatch(kayan_pencere_tahmin(veri, g, pencere = izgara$pencere[i], p = izgara$p[i], son_n = son_n),
                  error = function(e) NULL)
    if (!is.null(s)) { izgara$RMSE[i] <- rmse(s$gercek, s$tahmin); izgara$MAE[i] <- mae(s$gercek, s$tahmin) }
  }
  izgara <- izgara[!is.na(izgara$RMSE), , drop = FALSE]
  if (nrow(izgara) == 0) return(varsayilan_sonuc)
  en_iyi <- order(izgara$RMSE, izgara$pencere, izgara$p)[1]
  izgara$secildi <- seq_len(nrow(izgara)) == en_iyi
  list(p = izgara$p[en_iyi], pencere = izgara$pencere[en_iyi], yontem = "capraz",
       tablo = izgara, son_n = son_n)
}

#NOTE
gelecek_tahmin <- function(veri, gosterge, ufuk = NULL, pencere = NULL, p = NULL) {
  ufuk <- varsayilan(ufuk, gosterge_ufuk(gosterge))
  p    <- varsayilan(p, gosterge_p(gosterge))
  trend <- isTRUE(CONFIG$model$formulde_trend)
  d <- gosterge_verisi(veri, gosterge, p, trend = trend)
  w <- min(varsayilan(pencere, gosterge_pencere(gosterge)), nrow(d))
  if (w <= p + 1 + trend) stop("Pencere lag sayısına göre çok küçük: ", gosterge, call. = FALSE)
  
  egitim <- utils::tail(d, w)
  girdiler <- paste0(gosterge, "_lag", seq_len(p))
  model <- lm(formul_kur(gosterge, girdiler, trend = trend), data = egitim)
  kat <- stats::coef(model); kat[is.na(kat)] <- 0
  c0  <- unname(kat["(Intercept)"]); phi <- unname(kat[girdiler])
  b_trend <- if (trend) unname(kat["trend"]) else 0
  sigma <- summary(model)$sigma
  
  gecmis <- egitim[[gosterge]]
  tr_son <- if (trend) utils::tail(egitim$trend, 1) else 0
  tahmin <- numeric(ufuk)
  for (h in seq_len(ufuk)) {
    x <- rev(utils::tail(gecmis, p))
    tahmin[h] <- c0 + sum(phi * x) + b_trend * (tr_son + h)
    gecmis <- c(gecmis, tahmin[h])
  }
  psi <- numeric(ufuk); psi[1] <- 1
  if (ufuk > 1) for (j in 1:(ufuk - 1)) {
    psi[j + 1] <- sum(phi[seq_len(min(j, p))] * psi[j - seq_len(min(j, p)) + 1])
  }
  se <- sigma * sqrt(cumsum(psi^2))
  z  <- stats::qnorm(1 - (1 - CONFIG$model$guven_duzeyi) / 2)
  out <- data.frame(
    gosterge = gosterge,
    tarih = donem_ekle(max(d$tarih), ufuk, gosterge_frekansi(gosterge)),
    tahmin = tahmin, alt = tahmin - z * se, ust = tahmin + z * se)
  attr(out, "p") <- p; attr(out, "pencere") <- w
  out
}

#NOTE
gosterge_hesapla <- function(veri, ad, kaynak = NA) {
  ms <- model_sec(veri, ad)
  s  <- kayan_pencere_tahmin(veri, ad, pencere = ms$pencere, p = ms$p)
  ufuk <- gosterge_ufuk(ad)
  f  <- gelecek_tahmin(veri, ad, ufuk = ufuk, pencere = ms$pencere, p = ms$p)
  f_ad <- gosterge_frekansi(ad)
  ozet <- cbind(
    data.frame(gosterge = ad, ad = gosterge_etiketi(ad),
               rol = varsayilan(CONFIG$gostergeler[[ad]]$rol, NA), FREKANS = f_ad, KAYNAK = kaynak,
               P = ms$p, PENCERE = ms$pencere, UFUK = ufuk,
               YONTEM = if (ms$yontem == "capraz") "çapraz doğrulama" else "varsayılan",
               N_TAHMIN = nrow(s), SON_GOZLEM = max(gosterge_verisi(veri, ad, ms$p)$tarih),
               stringsAsFactors = FALSE),
    metrikler(s))
  cv <- if (is.null(ms$tablo)) NULL else cbind(data.frame(gosterge = ad), ms$tablo)
  list(ozet = ozet, gelecek = f,
       gecmis = cbind(data.frame(gosterge = ad), s), cv = cv)
}

#NOTE
tum_gostergeleri_tahminle <- function(veri) {
  meta <- processed_oku("metaveri")
  parcalar <- list()
  for (ad in aktif_gostergeler()) {
    if (!ad %in% veri$gosterge) { log_msg(paste("Veride yok, atlandı:", ad), "UYARI"); next }
    kaynak <- if (is.null(meta)) NA else meta$kaynak[match(ad, meta$gosterge)]
    r <- tryCatch(gosterge_hesapla(veri, ad, kaynak), error = function(e) {
      log_msg(paste0("Tahmin hatası: ", ad, " - ", conditionMessage(e)), "UYARI"); NULL })
    if (!is.null(r)) parcalar[[ad]] <- r
  }
  birlestir <- function(alan) {
    x <- Filter(Negate(is.null), lapply(parcalar, `[[`, alan))
    if (length(x) == 0) NULL else { y <- do.call(rbind, unname(x)); rownames(y) <- NULL; y }
  }
  list(ozet = birlestir("ozet"), gelecek = birlestir("gelecek"),
       gecmis = birlestir("gecmis"), cv = birlestir("cv"))
}

#NOTE
sonuclari_kaydet <- function(sonuc) {
  ikili_kaydet(sonuc$ozet, "tahmin_ozeti")
  ikili_kaydet(sonuc$gelecek, "gelecek_tahmin")
  ikili_kaydet(sonuc$gecmis, "gecmis_tahmin")
  if (!is.null(sonuc$cv)) ikili_kaydet(sonuc$cv, "capraz_dogrulama")
  zaman <- Sys.time()
  dir.create(CONFIG$saklama$model_klasoru, showWarnings = FALSE, recursive = TRUE)
  saveRDS(c(sonuc[c("ozet", "gelecek", "gecmis", "cv")], list(zaman = zaman)),
          file.path(CONFIG$saklama$model_klasoru, "sonuclar.rds"))
  invisible(zaman)
}

#NOTE
sonuc_paketi <- function(veri, sonuc, zaman) {
  list(veri = veri, ozet = sonuc$ozet, gelecek = sonuc$gelecek, gecmis = sonuc$gecmis,
       cv = sonuc$cv, meta = processed_oku("metaveri"), kalite = processed_oku("kalite_raporu"),
       zaman = zaman)
}

#NOTE
calistir_hepsi <- function(yenile = FALSE) {
  veri  <- hazir_veriyi_getir(yenile)
  sonuc <- tum_gostergeleri_tahminle(veri)
  if (is.null(sonuc$ozet) || nrow(sonuc$ozet) == 0) stop("Hiçbir gösterge için tahmin üretilemedi")
  zaman <- sonuclari_kaydet(sonuc)
  log_msg(paste0("Tahmin tamamlandı: ", nrow(sonuc$ozet), " gösterge; kaydedildi"))
  invisible(sonuc_paketi(veri, sonuc, zaman))
}

#NOTE
gosterge_guncelle <- function(ad) {
  if (!ad %in% aktif_gostergeler()) stop("Aktif olmayan gösterge: ", ad, call. = FALSE)
  eski <- processed_oku("hazir_veri"); yol_k <- file.path(CONFIG$saklama$model_klasoru, "sonuclar.rds")
  k <- if (file.exists(yol_k)) tryCatch(readRDS(yol_k), error = function(e) NULL) else NULL
  if (is.null(eski) || !"gosterge" %in% names(eski) || is.null(k) || is.null(k$gecmis)) {
    log_msg("Kayıtlı sonuçlar eksik/eski biçimde; önce tüm göstergeler hesaplanıyor", "UYARI")
    calistir_hepsi(FALSE)
    eski <- processed_oku("hazir_veri"); k <- readRDS(yol_k)
  }
  ham <- fetch_indicator(ad, yenile = TRUE)
  if (is.null(ham)) stop("Gösterge hiçbir kanaldan alınamadı: ", ad, call. = FALSE)
  seri <- seri_hazirla(ham[, c("tarih", "deger")], ad)
  veri <- rbind(eski[eski$gosterge != ad, ], seri); rownames(veri) <- NULL
  ikili_kaydet(veri, "hazir_veri")
  
  degistir <- function(tablo, satir, anahtar = "gosterge") {
    y <- rbind(tablo[tablo[[anahtar]] != ad, , drop = FALSE], satir); rownames(y) <- NULL; y
  }
  yeni_meta <- metaveri_olustur(setNames(list(ham), ad))
  ikili_kaydet(degistir(processed_oku("metaveri"), yeni_meta), "metaveri")
  ikili_kaydet(degistir(processed_oku("kalite_raporu"), kalite_raporu_olustur(ham)), "kalite_raporu")
  
  h <- gosterge_hesapla(veri, ad, yeni_meta$kaynak)
  sonuc <- list(ozet = degistir(k$ozet, h$ozet), gelecek = degistir(k$gelecek, h$gelecek),
                gecmis = degistir(k$gecmis, h$gecmis),
                cv = if (is.null(h$cv)) k$cv else degistir(k$cv, h$cv))
  # Aktif gösterge sırası korunur
  sirala <- function(t) if (is.null(t)) t else t[order(match(t$gosterge, aktif_gostergeler())), , drop = FALSE]
  sonuc[c("ozet", "gelecek", "gecmis", "cv")] <- lapply(sonuc[c("ozet", "gelecek", "gecmis", "cv")], sirala)
  zaman <- sonuclari_kaydet(sonuc)
  log_msg(paste0("Gösterge güncellendi: ", ad, " (kaynak: ", yeni_meta$kaynak, ", p = ", h$ozet$P,
                 ", pencere = ", h$ozet$PENCERE, ", ufuk = ", h$ozet$UFUK, ")"))
  invisible(sonuc_paketi(veri, sonuc, zaman))
}

#NOTE
sonuclari_getir <- function(yenile = FALSE) {
  yol <- file.path(CONFIG$saklama$model_klasoru, "sonuclar.rds")
  if (yenile) return(calistir_hepsi(TRUE))
  veri <- hazir_veriyi_getir(FALSE)
  hz_yol <- file.path(CONFIG$saklama$processed_klasoru, "hazir_veri.rds")
  guncel <- file.exists(yol) &&
    dosya_yasi_gun(yol) <= varsayilan(CONFIG$guncelleme$sikligi_gun, 1) &&
    file.mtime(yol) >= file.mtime(hz_yol)
  k <- if (guncel) tryCatch(readRDS(yol), error = function(e) NULL) else NULL
  if (is.null(k) || is.null(k$gecmis)) return(calistir_hepsi(FALSE))
  sonuc_paketi(veri, k, k$zaman)
}

#NOTE
local({
  fonksiyonlar <- c("mae", "mse", "rmse", "mape", "theil_u", "basit_ar",
                    "kayan_pencere_tahmin", "metrikler", "p_sec", "model_sec",
                    "gelecek_tahmin", "gosterge_hesapla", "tum_gostergeleri_tahminle",
                    "sonuclari_kaydet", "sonuc_paketi", "calistir_hepsi",
                    "gosterge_guncelle", "sonuclari_getir")
  eksik <- fonksiyonlar[!sapply(fonksiyonlar, exists, mode = "function")]
  if (length(eksik) > 0) {
    stop("[models.R] Eksik fonksiyon: ", paste(eksik, collapse = ", "))
  }
  message("[models.R] Tahmin katmanı yüklendi: ", length(fonksiyonlar), " fonksiyon yerinde. ✔")
})