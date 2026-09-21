# =============================================================================
# models.R — Tahmin Katmanı (AR-EKK + Kayan Pencere + Çapraz Doğrulama)
# -----------------------------------------------------------------------------
# Tahmin "geleceği bilmek" değildir. Tahmin, geçmişteki düzeni öğrenip o düzenin
# biraz daha devam edeceğini varsaymaktır. Bu katman:
#   * AR(p) modelini EKK ile tahmin eder:  y_t = c + phi_1 y_{t-1} + ... + e_t,
#   * kayan pencere ile her adımda yalnız son w dönemi kullanır ve tahmin edeceği
#     dönemi ASLA görmez (dürüst test),
#   * MODEL SEÇİMİNDE TEMEL YÖNTEM ÇAPRAZ DOĞRULAMADIR: aday pencereler (frekansa
#     göre ayrı tanımlı) ve aday p'ler (verinin varsayılan p'si, AIC p'si, BIC
#     p'si) kayan-orijinli RMSE ile karşılaştırılır, en iyisi seçilir,
#   * her gösterge KENDİ frekansında (aylık/çeyreklik/yıllık), KENDİ p, pencere
#     ve tahmin ufkuyla çalışır; kartta yazmıyorsa frekansın/genel varsayılan,
#   * geçmişe dönük (örnek dışı) başarıyı MAE, MSE, RMSE, MAPE, Theil U ile;
#     örnek içi uyumu MAE, RMSE, MAPE ile ölçer,
#   * ileriye dönük tahmin ve yaklaşık güven bandı üretir.
#
# GÜNCELLEME MANTIĞI (gosterge_guncelle, her veri için):
#   1) kaynak öncelikleri  2) frekansa göre işleme  3) verinin AR(p) ve pencere
#   ayarları  4) aday pencere/p üzerinden çapraz doğrulama  5) model ve pencere
#   seçimi  6) tahmin ufku kadar tahmin  7) ayar yoksa varsayılan.
#
# DÜRÜSTLÜK: İyi bir model kesinlik vaat etmez. Her tahmin naif (bir önceki
# gözlem) ölçütüyle karşılaştırılır: GORELI_RMSE < 1 ise model naiften iyidir.
#
# Yükleme sırası: config.R -> utils.R -> api_functions.R -> data.prep.R -> models.R
# =============================================================================

# --- Bağımlılık bekçileri -----------------------------------------------------
if (!exists("CONFIG"))          stop("[models.R] Önce config.R yükle: source('R/config.R')")
if (!exists("formul_kur"))      stop("[models.R] Önce utils.R yükle: source('R/utils.R')")
if (!exists("gosterge_verisi")) stop("[models.R] Önce data.prep.R yükle: source('R/data.prep.R')")

# =============================================================================
# 1) BAŞARI ÖLÇÜLERİ (öneri 2.7)
# =============================================================================

#' Ortalama Mutlak Hata (MAE)
#' @param gercek Gerçek değerler.
#' @param tahmin Tahmin değerleri.
#' @return Tek sayı.
mae <- function(gercek, tahmin) mean(abs(gercek - tahmin), na.rm = TRUE)

#' Ortalama Kare Hata (MSE)
#' @inheritParams mae
#' @return Tek sayı.
mse <- function(gercek, tahmin) mean((gercek - tahmin)^2, na.rm = TRUE)

#' Kök Ortalama Kare Hata (RMSE)
#' @inheritParams mae
#' @return Tek sayı.
rmse <- function(gercek, tahmin) sqrt(mse(gercek, tahmin))

#' Ortalama Mutlak Yüzde Hata (MAPE)
#'
#' Sıfır olan gerçek değerler dışlanır. Sıfır civarında gidip gelen ve işaret
#' değiştiren göstergelerde (denge göstergeleri, büyüme oranı) yüzde hata
#' yanıltıcıdır; bunlarda MAE/RMSE'ye güven.
#'
#' @inheritParams mae
#' @return Yüzde olarak tek sayı.
mape <- function(gercek, tahmin) {
  gecerli <- gercek != 0 & !is.na(gercek) & !is.na(tahmin)
  100 * mean(abs((gercek[gecerli] - tahmin[gecerli]) / gercek[gecerli]))
}

#' Theil U istatistiği (öneri 2.7 tanımı)
#'
#' \code{U = sqrt(sum((tahmin - gercek)^2)) / sqrt(sum(gercek^2))}. Ölçekten
#' bağımsızdır; 0'a yaklaştıkça tahmin iyileşir.
#'
#' @inheritParams mae
#' @return Tek sayı.
theil_u <- function(gercek, tahmin) {
  ok <- !is.na(gercek) & !is.na(tahmin)
  sqrt(sum((tahmin[ok] - gercek[ok])^2)) / sqrt(sum(gercek[ok]^2))
}

# =============================================================================
# 2) KAYAN PENCERE TAHMİNİ (öneri 2.5)
# =============================================================================

#' En basit AR(p) modeli (tüm örnekte tek EKK)
#'
#' @param veri Hazır uzun tablo.
#' @param gosterge Gösterge adı.
#' @param p Gecikme sayısı; boşsa göstergenin varsayılan p'si.
#' @return \code{lm} nesnesi.
basit_ar <- function(veri, gosterge, p = NULL) {
  p <- varsayilan(p, gosterge_p(gosterge))
  d <- gosterge_verisi(veri, gosterge, p)
  lm(formul_kur(gosterge, paste0(gosterge, "_lag", seq_len(p))), data = d)
}

#' Kayan pencere ile tek adım ilerisi tahmin (dürüst test)
#'
#' Her t anında yalnız \code{[t-w+1, t]} penceresiyle AR(p) modeli EKK ile kurulur,
#' t+1 dönemi tahmin edilir, pencere bir dönem kayar ve model BAŞTAN kurulur.
#' Tahmin edilen dönem asla eğitime girmez. Pencere ve p, çağrıdaki değer >
#' göstergenin varsayılanı sırasıyla belirlenir. Anlaşılır hatayla durur: pencere
#' parametre sayısına göre çok küçükse, veri pencereden kısaysa.
#'
#' Çıktının \code{"ornek_ici"} özniteliği, pencerelerin EĞİTİM örneklerindeki
#' (örnek içi) ortalama MAE, MSE, RMSE ve MAPE değerleridir.
#'
#' @param veri Hazır uzun tablo.
#' @param gosterge Gösterge adı.
#' @param pencere Pencere uzunluğu (dönem); boşsa göstergenin varsayılanı.
#' @param p Gecikme sayısı; boşsa göstergenin varsayılanı.
#' @param son_n Yalnız son n dönemi tahmin et (çapraz doğrulama için).
#' @return \code{data.frame(tarih, gercek, tahmin, naif)}; \code{naif} = bir önceki
#'   gözlem (rastgele yürüyüş ölçütü).
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
  ic     <- matrix(NA_real_, m, 3)                     # örnek içi MAE, MSE, MAPE

  for (i in seq_len(m)) {
    t       <- idx[i]
    egitim  <- d[(t - w + 1):t, , drop = FALSE]        # sadece geçmiş pencere
    model   <- lm(formul, data = egitim)
    sonraki <- d[t + 1, , drop = FALSE]                # görülmemiş bir sonraki dönem
    tahmin[i] <- suppressWarnings(as.numeric(predict(model, newdata = sonraki)))
    gercek[i] <- sonraki[[gosterge]]
    naif[i]   <- sonraki[[paste0(gosterge, "_lag1")]]  # y_t: "değişmez" tahmini
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

#' Bir geçmişe dönük tahminin metrikleri
#'
#' Örnek DIŞI: MAE, MSE, RMSE, MAPE, Theil U; naif ölçüt RMSE'si ve
#' \code{GORELI_RMSE = RMSE / NAIF_RMSE} (1'in altı: model naiften iyi).
#' Örnek İÇİ: IC_MAE, IC_RMSE, IC_MAPE.
#'
#' @param s \code{kayan_pencere_tahmin} çıktısı.
#' @return Tek satırlık data.frame.
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

# =============================================================================
# 3) MODEL SEÇİMİ — TEMEL YÖNTEM: ÇAPRAZ DOĞRULAMA (öneri 2.5 - 2.6)
# =============================================================================

#' Bilgi kriteriyle gecikme uzunluğu (p) seçimi
#'
#' Aynı örnek üzerinde p = 1..p_max için AR(p) kurar; AIC (\code{-2lnL + 2k})
#' ya da BIC/SBC (\code{-2lnL + k ln n}) en düşük olanı seçer. Çapraz
#' doğrulamada aday p'leri üretmek için kullanılır.
#'
#' @param veri Hazır uzun tablo.
#' @param gosterge Gösterge adı.
#' @param kriter "AIC" ya da "BIC".
#' @param p_max Üst sınır; boşsa göstergenin frekansının \code{p_max}'ı.
#' @return \code{list(p =, tablo = data.frame(p, AIC, BIC))}.
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

#' Çapraz doğrulamayla model (p) ve pencere seçimi
#'
#' Aday p'ler (verinin varsayılan p'si, AIC ve BIC ile seçilenler) ile aday
#' pencerelerin (frekansa ya da veriye özel; aylıkta \code{c(36,42,48,54,60)})
#' her birleşimi, AYNI son n dönemi tek adım ilerisi tahmin eder; RMSE'si en
#' düşük olan seçilir (eşitlikte küçük pencere, sonra küçük p). Veri bazı
#' adaylara yetmiyorsa o adaylar elenir, değerlendirme dönemi gerekirse
#' kısaltılır; hiçbir aday uygun değilse verinin kendi varsayılan p ve penceresi
#' kullanılır. \code{model$model_secimi = "varsayilan"} ise seçim yapılmaz.
#'
#' @param veri Hazır uzun tablo.
#' @param g Gösterge adı.
#' @return \code{list(p, pencere, yontem, tablo, son_n)}; \code{yontem}: "capraz"
#'   ya da "varsayilan"; \code{tablo}: aday \code{p, pencere, RMSE, MAE, secildi}.
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

  # Değerlendirme dönemini gerekirse kısalt: aday (p, w) için n_p - son_n >= w olmalı
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

# =============================================================================
# 4) İLERİYE DÖNÜK TAHMİN (öneri Hedef 3)
# =============================================================================

#' İleriye dönük h dönemlik tahmin
#'
#' Serinin SON penceresiyle AR(p) kurulur; tahminler özyinelemeli üretilir (her
#' tahmin bir sonrakinin gecikmesi olur). Tarihler göstergenin KENDİ frekansında
#' ilerler (aylık: ay, çeyreklik: çeyrek, yıllık: yıl). Yaklaşık güven bandı, AR'nin
#' MA(inf) ağırlıklarından (psi) ve artık standart sapmasından hesaplanır:
#' \code{se_h = sigma * sqrt(sum(psi_0^2..psi_(h-1)^2))}. Parametre belirsizliği
#' hesaba katılmadığından bant biraz dardır.
#'
#' @param veri Hazır uzun tablo.
#' @param gosterge Gösterge adı.
#' @param ufuk Kaç dönem; boşsa göstergenin \code{tahmin_ufku} değeri (varsayılan 6).
#' @param pencere Pencere; boşsa göstergenin varsayılanı.
#' @param p Gecikme sayısı; boşsa göstergenin varsayılanı.
#' @return \code{data.frame(gosterge, tarih, tahmin, alt, ust)}.
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
    x <- rev(utils::tail(gecmis, p))                       # x[1] = y_T (lag1)
    tahmin[h] <- c0 + sum(phi * x) + b_trend * (tr_son + h)
    gecmis <- c(gecmis, tahmin[h])
  }
  psi <- numeric(ufuk); psi[1] <- 1                        # psi_0 = 1
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

# =============================================================================
# 5) BİR GÖSTERGE İÇİN TAM HESAP, TÜM GÖSTERGELER, GÜNCELLEME
# =============================================================================

#' Bir gösterge için model seçimi, geçmişe dönük ve ileriye dönük tahmin
#'
#' Sıra: (3) verinin AR(p) ve pencere ayarları, (4) aday pencere/p üzerinden
#' çapraz doğrulama, (5) model ve pencere seçimi, (6) tahmin ufku kadar tahmin.
#'
#' @param veri Hazır uzun tablo.
#' @param ad Gösterge adı.
#' @param kaynak Kullanılan kaynağın adı (özet tabloya yazılır).
#' @return \code{list(ozet, gelecek, gecmis, cv)}.
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

#' Tüm aktif göstergeler için hesap
#'
#' NAZİK: biri başarısız olursa nedeni log'a yazılır ve ATLANIR.
#'
#' @param veri Hazır uzun tablo.
#' @return \code{list(ozet, gelecek, gecmis, cv)} (her biri data.frame).
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

#' Sonuçları kaydet
#'
#' @param sonuc \code{list(ozet, gelecek, gecmis, cv)}.
#' @return Görünmez zaman damgası.
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

#' Tüm sonuç paketini oluştur (arayüzün okuduğu yapı)
#'
#' @param veri Hazır uzun tablo.
#' @param sonuc \code{list(ozet, gelecek, gecmis, cv)}.
#' @param zaman Hesaplama zamanı.
#' @return \code{list(veri, ozet, gelecek, gecmis, cv, meta, kalite, zaman)}.
sonuc_paketi <- function(veri, sonuc, zaman) {
  list(veri = veri, ozet = sonuc$ozet, gelecek = sonuc$gelecek, gecmis = sonuc$gecmis,
       cv = sonuc$cv, meta = processed_oku("metaveri"), kalite = processed_oku("kalite_raporu"),
       zaman = zaman)
}

#' Tek düğme: çek -> hazırla -> seç -> tahmin et -> kaydet
#'
#' \code{yenile = TRUE} veriyi her gösterge için KENDİ kaynak önceliğiyle yeniden
#' çeker (cron ile de çalıştırılabilir, bkz. config.R).
#'
#' @param yenile \code{TRUE} ise veri kaynaklardan yenilenir.
#' @return (görünmez) \code{sonuc_paketi} yapısı.
calistir_hepsi <- function(yenile = FALSE) {
  veri  <- hazir_veriyi_getir(yenile)
  sonuc <- tum_gostergeleri_tahminle(veri)
  if (is.null(sonuc$ozet) || nrow(sonuc$ozet) == 0) stop("Hiçbir gösterge için tahmin üretilemedi")
  zaman <- sonuclari_kaydet(sonuc)
  log_msg(paste0("Tahmin tamamlandı: ", nrow(sonuc$ozet), " gösterge; kaydedildi"))
  invisible(sonuc_paketi(veri, sonuc, zaman))
}

#' TEK bir göstergeyi güncelle (kendi ayarlarıyla)
#'
#' (1) verinin kendi kaynak önceliği ve yedekleriyle çekilir, (2) kendi
#' frekansında işlenir, (3-6) verinin kendi AR(p) / pencere / tahmin ufku
#' ayarlarıyla çapraz doğrulama, model seçimi ve tahmin yapılır; ayar yoksa
#' varsayılanlar kullanılır. Diğer göstergelerin sonuçları korunur.
#'
#' @param ad Gösterge adı.
#' @return (görünmez) \code{sonuc_paketi} yapısı.
gosterge_guncelle <- function(ad) {
  if (!ad %in% aktif_gostergeler()) stop("Aktif olmayan gösterge: ", ad, call. = FALSE)
  eski <- processed_oku("hazir_veri"); yol_k <- file.path(CONFIG$saklama$model_klasoru, "sonuclar.rds")
  k <- if (file.exists(yol_k)) tryCatch(readRDS(yol_k), error = function(e) NULL) else NULL
  if (is.null(eski) || !"gosterge" %in% names(eski) || is.null(k) || is.null(k$gecmis)) {
    log_msg("Kayıtlı sonuçlar eksik/eski biçimde; önce tüm göstergeler hesaplanıyor", "UYARI")
    calistir_hepsi(FALSE)
    eski <- processed_oku("hazir_veri"); k <- readRDS(yol_k)
  }
  ham <- fetch_indicator(ad, yenile = TRUE)                                   # 1) kaynak öncelikleri
  if (is.null(ham)) stop("Gösterge hiçbir kanaldan alınamadı: ", ad, call. = FALSE)
  seri <- seri_hazirla(ham[, c("tarih", "deger")], ad)                         # 2) frekansa göre işleme
  veri <- rbind(eski[eski$gosterge != ad, ], seri); rownames(veri) <- NULL
  ikili_kaydet(veri, "hazir_veri")

  degistir <- function(tablo, satir, anahtar = "gosterge") {                   # tabloda yalnız bu göstergeyi yenile
    y <- rbind(tablo[tablo[[anahtar]] != ad, , drop = FALSE], satir); rownames(y) <- NULL; y
  }
  yeni_meta <- metaveri_olustur(setNames(list(ham), ad))
  ikili_kaydet(degistir(processed_oku("metaveri"), yeni_meta), "metaveri")
  ikili_kaydet(degistir(processed_oku("kalite_raporu"), kalite_raporu_olustur(ham)), "kalite_raporu")

  h <- gosterge_hesapla(veri, ad, yeni_meta$kaynak)                            # 3-6) ayarlar, CV, seçim, tahmin
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

#' Sonuçları getir (taze kayıt varsa yeniden hesaplamadan)
#'
#' Arayüzün başlangıç noktası. Kayıtlı sonuçlar hazır veriden daha yeni ve taze
#' ise okunur; değilse \code{calistir_hepsi} çalışır.
#'
#' @param yenile \code{TRUE} ise her şey baştan.
#' @return \code{sonuc_paketi} yapısı.
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

# =============================================================================
# KENDİNİ DOĞRULAMA
# =============================================================================
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
