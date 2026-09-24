## Hazırlık

* [ ] RStudio'da projeyi aç, Console'da proje kökünde olduğunu kontrol et ve `R/` klasöründeki dosya adlarına bak:

```r
getwd()
list.files("R")

```

* [ ] Dosyaların tam yollarını değişkenlere yaz (adları farklıysa listede gördüğün adlarla değiştir):

```r
config_yolu <- normalizePath("R/config.R", winslash = "/")
utils_yolu  <- normalizePath("R/utils.R", winslash = "/")
prep_yolu   <- normalizePath("R/data_prep.R", winslash = "/")
models_yolu <- normalizePath("R/models.R", winslash = "/")
file.exists(c(config_yolu, utils_yolu, prep_yolu, models_yolu))

```

* [ ] Gerçek API anahtarlarını sakla ve testler için sahte anahtar tanımla:

```r
eski_fred <- Sys.getenv("FRED_API_KEY")
eski_evds <- Sys.getenv("EVDS_API_KEY")
Sys.setenv(FRED_API_KEY = "KT_FRED", EVDS_API_KEY = "KT_EVDS")

```

* [ ] İnternete çıkmadan test edebilmek için sahte veri kaynağının durumunu tanımla (çağrı sayacı, hata anahtarı, ham veri, güncellemede eklenecek yeni satır):

```r
sahte <- new.env()
sahte$cagri <- 0
sahte$hata  <- FALSE
sahte$ham   <- NULL
sahte$ek    <- NULL

```

* [ ] api_functions.R'daki üç fonksiyonun sahtelerini ortama ekleyen yardımcıyı tanımla (`tum_gostergeleri_cek`, `fetch_indicator`, `metaveri_olustur`):

```r
sahte_api <- function(e) {
  e$metaveri_olustur <- function(liste) {
    data.frame(gosterge = names(liste), kaynak = "SAHTE", stringsAsFactors = FALSE)
  }
  e$tum_gostergeleri_cek <- function(yenile = FALSE) {
    sahte$cagri <- sahte$cagri + 1
    if (sahte$hata) stop("sahte bağlantı hatası")
    ikili_kaydet(metaveri_olustur(split(sahte$ham, sahte$ham$kimlik)), "metaveri")
    sahte$ham
  }
  e$fetch_indicator <- function(ad, yenile = FALSE) {
    sahte$cagri <- sahte$cagri + 1
    if (sahte$hata) return(NULL)
    x <- sahte$ham[sahte$ham$kimlik == ad, ]
    if (!is.null(sahte$ek)) x <- rbind(x, sahte$ek)
    x
  }
  for (f in c("metaveri_olustur", "tum_gostergeleri_cek", "fetch_indicator")) environment(e[[f]]) <- e
  invisible(e)
}

```

* [ ] Tüm katmanları (config → utils → sahte API → veri hazırlama → models) temiz bir ortamda yükleyen yardımcı fonksiyonu tanımla:

```r
yukle_modeller <- function() {
  e <- new.env(parent = globalenv())
  suppressMessages({
    sys.source(config_yolu, envir = e, keep.source = FALSE, toplevel.env = e)
    sys.source(utils_yolu,  envir = e, keep.source = FALSE, toplevel.env = e)
  })
  sahte_api(e)
  suppressMessages({
    sys.source(prep_yolu,   envir = e, keep.source = FALSE, toplevel.env = e)
    sys.source(models_yolu, envir = e, keep.source = FALSE, toplevel.env = e)
  })
  e
}

```

* [ ] Test ortamını yükle; fonksiyonlara bundan sonra `u$fonksiyon_adi()` şeklinde ulaşılacak:

```r
u <- yukle_modeller()

```

* [ ] Kaydedilen dosyaların projedeki gerçek klasörlere gitmemesi için tüm klasörleri geçici bir klasöre yönlendir:

```r
gecici <- file.path(tempdir(), "models_test")
u$CONFIG$saklama$processed_klasoru <- file.path(gecici, "processed")
u$CONFIG$saklama$model_klasoru     <- file.path(gecici, "model")
u$CONFIG$saklama$cache_klasoru     <- file.path(gecici, "cache")
u$CONFIG$saklama$yedek_klasoru     <- file.path(gecici, "yedek")
u$CONFIG$saklama$log_klasoru       <- file.path(gecici, "logs")
hazir_yol  <- file.path(gecici, "processed", "hazir_veri.rds")
sonuc_yolu <- file.path(gecici, "model", "sonuclar.rds")

```

* [ ] Değiştirilecek ayarların orijinal değerlerini sakla:

```r
eski_secim    <- u$CONFIG$model$model_secimi
eski_otomatik <- u$CONFIG$guncelleme$otomatik
tr <- isTRUE(u$CONFIG$model$formulde_trend)
tr

```

* [ ] Her aktif gösterge için kendi frekansında, 2025 Aralık'ta biten ve en büyük pencere adayından 60 dönem uzun sahte AR(1) serisi (φ = 0.7) üret:

```r
set.seed(42)
sahte$ham <- do.call(rbind, lapply(u$aktif_gostergeler(), function(g) {
  adim <- u$frekans_ayari(u$gosterge_frekansi(g))$ay_adimi
  n <- max(u$gosterge_pencere_adaylari(g), u$gosterge_pencere(g)) + 60
  data.frame(tarih  = rev(seq(as.Date("2025-12-01"), by = paste0("-", adim, " months"), length.out = n)),
             deger  = round(100 + as.numeric(arima.sim(list(ar = 0.7), n)), 3),
             kimlik = g, stringsAsFactors = FALSE)
}))
table(sahte$ham$kimlik)

```

* [ ] Sahte kaynaktan hazır veriyi üret (metaveri de yazılır):

```r
hazir <- u$hazir_veriyi_getir(yenile = TRUE)
file.exists(file.path(gecici, "processed", c("hazir_veri.rds", "metaveri.rds")))

```

* [ ] Testlerde kullanılacak aylık bir göstergeyi seç; `NA` dönerse `ga`'ya başka bir aktif göstergenin adını elle yaz:

```r
ga <- Filter(function(g) u$gosterge_frekansi(g) == "aylik", u$aktif_gostergeler())[1]
ga
c(p = u$gosterge_p(ga), pencere = u$gosterge_pencere(ga), ufuk = u$gosterge_ufuk(ga))

```

* [ ] Dosyanın satırlarını oku:

```r
satirlar <- readLines(models_yolu, encoding = "UTF-8", warn = FALSE)

```

## 1) Sözdizimi, kodlama ve biçim

* [ ] Sözdizimi hatası olmadığını kontrol et ve tanımlanan fonksiyonları listele; **18** fonksiyon olmalı:

```r
ifadeler <- parse(models_yolu, encoding = "UTF-8")
tanimlar <- Filter(function(e) is.call(e) && identical(e[[1]], as.name("<-")) &&
                     is.call(e[[3]]) && identical(e[[3]][[1]], as.name("function")), ifadeler)
length(tanimlar)
sapply(tanimlar, function(e) as.character(e[[2]]))

```

* [ ] BOM olmadığını (`FALSE`) ve dosyanın geçerli UTF-8 olduğunu (`TRUE`) kontrol et:

```r
ham_bayt <- readBin(models_yolu, "raw", file.info(models_yolu)$size)
identical(ham_bayt[1:3], as.raw(c(0xEF, 0xBB, 0xBF)))
metin <- rawToChar(ham_bayt)
Encoding(metin) <- "UTF-8"
validUTF8(metin)

```

* [ ] Türkçe harfin kodda (değişken adında) geçmediğini, sekme olmadığını kontrol et; ikisi de `integer(0)` olmalı:

```r
which(grepl("[çğıöşüÇĞİÖŞÜ]", gsub('"[^"]*"|#.*$', "", satirlar)))
grep("\t", satirlar)

```

* [ ] Satır sonu boşluğu ve 120 karakterden uzun satırları listele (uyarı, testi düşürmez; boş satırlardaki girinti boşlukları da burada çıkar):

```r
grep("[ \t]+$", satirlar)
which(nchar(satirlar, type = "width") > 120)

```

## 2) Yükleme ve bağımlılıklar

* [ ] Önkoşulların sırasıyla kontrol edildiğini doğrula; üç komut sırasıyla "config.R", "utils.R" ve "data.prep.R" uyarısı veren hata döndürmeli:

```r
dene <- function(e) tryCatch({ sys.source(models_yolu, envir = e, toplevel.env = e); "YÜKLENDİ" },
                             error = function(h) conditionMessage(h))
e1 <- new.env(parent = baseenv())
dene(e1)
e2 <- new.env(parent = baseenv()); e2$CONFIG <- u$CONFIG
dene(e2)
e3 <- new.env(parent = baseenv()); e3$CONFIG <- u$CONFIG; e3$formul_kur <- u$formul_kur
dene(e3)

```

* [ ] Yüklemenin uyarısız olduğunu ve "18 fonksiyon yerinde" mesajı verdiğini kontrol et; `uyarilar` `character(0)` olmalı:

```r
mesajlar <- uyarilar <- character(0)
withCallingHandlers(
  invisible(yukle_modeller()),
  message = function(m) { mesajlar <<- c(mesajlar, trimws(conditionMessage(m))); invokeRestart("muffleMessage") },
  warning = function(w) { uyarilar <<- c(uyarilar, conditionMessage(w)); invokeRestart("muffleWarning") }
)
uyarilar
grep("models.R", mesajlar, value = TRUE)

```

* [ ] Yüklemede kontrol **edilmeyen** ama `gosterge_guncelle()` içinde kullanılan fonksiyonların projede tanımlı olduğunu kontrol et; hepsi `TRUE` olmalı (`FALSE` olan, güncelleme butonuna basılınca "could not find function" hatası verir):

```r
tanimli_mi <- function(ad) any(sapply(list.files("R", "\\.R$", full.names = TRUE), function(f)
  any(grepl(paste0("^\\s*", ad, "\\s*<-\\s*function"), readLines(f, warn = FALSE, encoding = "UTF-8")))))
sapply(c("fetch_indicator", "metaveri_olustur", "tum_gostergeleri_cek"), tanimli_mi)

```

* [ ] models.R'ın kullandığı config alanlarını kontrol et; hepsi `TRUE` olmalı:

```r
cfg <- u$CONFIG
c(model_klasoru   = !is.null(cfg$saklama$model_klasoru),
  model_secimi    = !is.null(cfg$model$model_secimi),
  capraz_min_n    = !is.null(cfg$model$capraz_min_n),
  formulde_trend  = !is.null(cfg$model$formulde_trend),
  guven_duzeyi_01 = isTRUE(cfg$model$guven_duzeyi > 0 && cfg$model$guven_duzeyi < 1),
  sikligi_gun     = !is.null(cfg$guncelleme$sikligi_gun))

```

* [ ] Her frekansta `p_max` ve `capraz_son_n` ayarlarının tanımlı olduğunu kontrol et; tablodaki tüm değerler `TRUE` olmalı:

```r
sapply(names(cfg$frekanslar), function(f) c(p_max = !is.null(u$frekans_ayari(f)$p_max),
                                            capraz_son_n = !is.null(u$frekans_ayari(f)$capraz_son_n)))

```

* [ ] Tanımsız değişken olmadığını codetools ile kontrol et; `character(0)` döndürmeli:

```r
notlar <- capture.output(codetools::checkUsageEnv(u, all = TRUE))
grep("no visible", notlar, value = TRUE)

```

## 3) Hata metrikleri (mae, mse, rmse, mape, theil_u)

* [ ] Elle hesaplanabilen bir örnek tanımla (hatalar: 2, −2, 5, 5):

```r
gr <- c(100, 110, 90, 0)
th <- c(102, 108, 95, 5)

```

* [ ] Değerleri kontrol et; sırasıyla `3.5`, `14.5`, `3.807887`, `3.124579`, `0.04382` döndürmeli (MAPE'de gerçek değeri 0 olan gözlem dışarıda kalır):

```r
u$mae(gr, th)
u$mse(gr, th)
round(u$rmse(gr, th), 6)
round(u$mape(gr, th), 6)
round(u$theil_u(gr, th), 5)

```

* [ ] `NA` değerlerin atlandığını kontrol et; `1`, `1`, `50` döndürmeli:

```r
u$mae(c(1, NA, 3), c(2, 5, NA))
u$rmse(c(1, NA), c(2, 7))
u$mape(c(2, NA), c(3, 1))

```

* [ ] Mükemmel tahminde hepsinin 0, tüm gerçek değerler 0 iken MAPE'nin `NaN` olduğunu kontrol et:

```r
c(u$mae(gr, gr), u$rmse(gr, gr), u$mape(gr, gr), u$theil_u(gr, gr))
u$mape(c(0, 0), c(1, 2))

```

* [ ] `theil_u`'nun klasik Theil U1/U2 değil, `√SSE / √Σy²` olduğunu not et; naif modele göre başarı için `GORELI_RMSE` sütununa bakılmalı

## 4) basit_ar()

* [ ] Sahte AR(1) veride p = 1 modelini kur; gecikme katsayısı **0.7'ye yakın** olmalı (`TRUE`):

```r
m_ar <- u$basit_ar(hazir, ga, p = 1)
coef(m_ar)
abs(unname(coef(m_ar)[2]) - 0.7) < 0.15

```

* [ ] p verilmeyince config'teki gecikme sayısının kullanıldığını kontrol et; `TRUE` döndürmeli:

```r
length(coef(u$basit_ar(hazir, ga))) == 1 + u$gosterge_p(ga)

```

* [ ] Projede `basit_ar()`'ın kullanıldığı yerleri listele; hiç çıkmazsa yalnız keşif amaçlı bir araçtır:

```r
unlist(lapply(list.files("R", "\\.R$", full.names = TRUE), function(f)
  grep("basit_ar\\(", readLines(f, warn = FALSE, encoding = "UTF-8"), value = TRUE)))

```

## 5) p_sec()

* [ ] AIC ve BIC ile gecikme seç; tablo 1'den üst sınıra kadar satır içermeli, seçilen p en küçük kriterli satır olmalı:

```r
ps_aic <- u$p_sec(hazir, ga, "AIC")
ps_bic <- u$p_sec(hazir, ga, "BIC")
ps_aic$tablo
c(AIC = ps_aic$p, BIC = ps_bic$p)

```

* [ ] Üst sınırın `min(p_max, n/4)` olduğunu kontrol et; `TRUE` döndürmeli:

```r
n_ga <- nrow(u$gosterge_serisi(hazir, ga))
nrow(ps_aic$tablo) == min(u$frekans_ayari("aylik")$p_max, floor(n_ga / 4))

```

* [ ] AR(1) veride BIC'in küçük p seçtiğini kontrol et; `1` ya da `2` beklenir:

```r
ps_bic$p

```

* [ ] Yetersiz veride açıklayıcı hata verdiğini kontrol et; mesajda "veri yetersiz" yazmalı:

```r
kisa <- hazir[hazir$gosterge == ga, ][1:3, ]
tryCatch(u$p_sec(kisa, ga), error = function(e) conditionMessage(e))

```

* [ ] Geçersiz kriter adında ne olduğuna bak; `integer(0)` dönerse p seçilemez ama hata da vermez. Yalnız `"AIC"`/`"BIC"` kabul eden bir kontrol (`match.arg`) eklemeyi not et:

```r
u$p_sec(hazir, ga, "aic")$p

```

## 6) kayan_pencere_tahmin()

* [ ] p = 2 ve config penceresiyle kayan pencere tahmini yap; satır sayısı `n − pencere` olmalı:

```r
w <- u$gosterge_pencere(ga)
s <- u$kayan_pencere_tahmin(hazir, ga, pencere = w, p = 2)
head(s)
d2 <- u$gosterge_verisi(hazir, ga, 2, trend = tr)
nrow(s) == nrow(d2) - w

```

* [ ] Nitelikleri kontrol et; `p = 2`, `pencere = w` ve `MAE MSE RMSE MAPE` adlı örnek içi hatalar olmalı:

```r
attr(s, "p")
attr(s, "pencere")
attr(s, "ornek_ici")

```

* [ ] İlk tahmini elle yeniden hesapla ve karşılaştır; `TRUE` döndürmeli:

```r
f2 <- u$formul_kur(ga, paste0(ga, "_lag", 1:2), trend = tr)
m1 <- lm(f2, data = d2[1:w, ])
isTRUE(all.equal(unname(predict(m1, newdata = d2[w + 1, ])), s$tahmin[1]))

```

* [ ] Geleceğe bakma (look-ahead) olmadığını kontrol et: ilk tahminin tarihi eğitim penceresinin hemen sonrası olmalı; `TRUE` döndürmeli:

```r
s$tarih[1] == d2$tarih[w + 1]

```

* [ ] Naif tahminin bir önceki gerçek değer olduğunu kontrol et; `TRUE` döndürmeli:

```r
identical(s$naif[-1], s$gercek[-nrow(s)])

```

* [ ] `son_n = 12` ile yalnız son 12 dönemin tahmin edildiğini kontrol et; `12` ve `TRUE` döndürmeli:

```r
s12 <- u$kayan_pencere_tahmin(hazir, ga, pencere = w, p = 2, son_n = 12)
nrow(s12)
identical(tail(s$tahmin, 12), s12$tahmin)

```

* [ ] Uç durum: `son_n = 0` iken ne olduğuna bak; 0 satır ya da hata beklenir. **2 satır** (biri `NA`) dönerse `t_ilk:(n - 1)` ifadesi geriye sayıyor demektir; fonksiyonun başına `if (!is.null(son_n) && son_n < 1) stop("son_n en az 1 olmalı", call. = FALSE)` eklemeyi not et:

```r
tryCatch(u$kayan_pencere_tahmin(hazir, ga, pencere = w, p = 2, son_n = 0),
         error = function(e) paste("HATA:", conditionMessage(e)))

```

* [ ] Çok küçük pencerede ve pencereden kısa veride açıklayıcı hata verdiğini kontrol et; "çok küçük" ve "kısa" mesajları dönmeli:

```r
tryCatch(u$kayan_pencere_tahmin(hazir, ga, pencere = 3, p = 2), error = function(e) conditionMessage(e))
tryCatch(u$kayan_pencere_tahmin(hazir, ga, pencere = 10000, p = 2), error = function(e) conditionMessage(e))

```

## 7) metrikler()

* [ ] Metrik tablosunu oluştur; 10 sütunlu tek satır olmalı:

```r
mt <- u$metrikler(s)
mt
dim(mt)

```

* [ ] `GORELI_RMSE`'nin `RMSE / NAIF_RMSE` olduğunu kontrol et; `TRUE` döndürmeli:

```r
isTRUE(all.equal(mt$GORELI_RMSE, mt$RMSE / mt$NAIF_RMSE))

```

* [ ] AR(1) veride modelin naif tahminden iyi olduğunu kontrol et; `GORELI_RMSE` **1'in altında** olmalı:

```r
mt$GORELI_RMSE < 1

```

* [ ] Örnek dışı hatanın genelde örnek içinden büyük olduğunu kontrol et (`RMSE > IC_RMSE`); `FALSE` ise örnek içi hesabı gözden geçir:

```r
mt$RMSE > mt$IC_RMSE

```

## 8) gelecek_tahmin()

* [ ] 6 dönemlik tahmin üret; 6 satır, sütunlar `gosterge tarih tahmin alt ust` olmalı:

```r
f <- u$gelecek_tahmin(hazir, ga, ufuk = 6, p = 2)
f
names(f)

```

* [ ] Tarihlerin son gözlemden sonraki ardışık dönemler olduğunu kontrol et; `TRUE` döndürmeli:

```r
identical(f$tarih, u$donem_ekle(max(d2$tarih), 6, u$gosterge_frekansi(ga)))

```

* [ ] Güven aralığının tahmini kapsadığını ve ufuk uzadıkça genişlediğini kontrol et; iki `TRUE` döndürmeli:

```r
all(f$alt < f$tahmin & f$tahmin < f$ust)
all(diff(f$ust - f$alt) >= 0)

```

* [ ] 1 adım sonrası tahminin `predict()` ile aynı olduğunu kontrol et; `TRUE` döndürmeli:

```r
egitim <- tail(d2, attr(f, "pencere"))
m_f <- lm(f2, data = egitim)
yeni <- setNames(data.frame(tail(d2[[ga]], 1), d2[[ga]][nrow(d2) - 1]), paste0(ga, "_lag", 1:2))
if (tr) yeni$trend <- tail(d2$trend, 1) + 1
isTRUE(all.equal(unname(predict(m_f, newdata = yeni)), f$tahmin[1]))

```

* [ ] AR(1)'de aralık genişliğini kontrol et: 1. adım yarı genişliği `z × σ`, 2. adımın 1. adıma oranı `√(1 + φ²)` olmalı; iki `TRUE` döndürmeli:

```r
f1 <- u$gelecek_tahmin(hazir, ga, ufuk = 3, p = 1)
d1 <- u$gosterge_verisi(hazir, ga, 1, trend = tr)
m1b <- lm(u$formul_kur(ga, paste0(ga, "_lag1"), trend = tr), data = tail(d1, attr(f1, "pencere")))
phi <- unname(coef(m1b)[paste0(ga, "_lag1")])
z <- qnorm(1 - (1 - u$CONFIG$model$guven_duzeyi) / 2)
gen <- f1$ust - f1$alt
isTRUE(all.equal(gen[1] / 2, z * summary(m1b)$sigma))
isTRUE(all.equal(gen[2] / gen[1], sqrt(1 + phi^2)))

```

* [ ] Trend kapalıysa uzun ufukta tahminin serinin ortalamasına (`c / (1 − φ)`) yaklaştığını kontrol et; iki değer birbirine yakın olmalı:

```r
if (!tr) {
  f60 <- u$gelecek_tahmin(hazir, ga, ufuk = 60, p = 1)
  c(son_tahmin = tail(f60$tahmin, 1), denge = unname(coef(m1b)[1] / (1 - phi)))
}

```

* [ ] Güven düzeyi düşünce aralığın daraldığını kontrol et; `TRUE` döndürmeli:

```r
eski_guven <- u$CONFIG$model$guven_duzeyi
u$CONFIG$model$guven_duzeyi <- 0.80
f80 <- u$gelecek_tahmin(hazir, ga, ufuk = 6, p = 2)
u$CONFIG$model$guven_duzeyi <- eski_guven
all((f80$ust - f80$alt) < (f$ust - f$alt))

```

* [ ] Veriden büyük pencere verilince sessizce veri uzunluğuna indirildiğini kontrol et; `TRUE` döndürmeli:

```r
attr(u$gelecek_tahmin(hazir, ga, ufuk = 3, pencere = 10000, p = 2), "pencere") == nrow(d2)

```

* [ ] Sabit seride (katsayılar `NA` → 0) hata vermeden sabit değeri tahmin ettiğini kontrol et; `TRUE` döndürmeli:

```r
sabit <- data.frame(gosterge = ga, tarih = seq(as.Date("2019-01-01"), by = "month", length.out = 80),
                    deger = 50, gercek = TRUE)
f_s <- suppressWarnings(u$gelecek_tahmin(sabit, ga, ufuk = 3, pencere = 30, p = 2))
isTRUE(all.equal(f_s$tahmin, rep(50, 3)))

```

* [ ] Çok küçük pencerede açıklayıcı hata verdiğini kontrol et:

```r
tryCatch(u$gelecek_tahmin(hazir, ga, ufuk = 3, pencere = 3, p = 2), error = function(e) conditionMessage(e))

```

## 9) model_sec()

* [ ] Mevcut model seçim ayarını not et:

```r
u$CONFIG$model$model_secimi

```

* [ ] Çapraz doğrulamayı aç ve modeli seç; `yontem` `"capraz"` olmalı:

```r
u$CONFIG$model$model_secimi <- "capraz"
ms <- u$model_sec(hazir, ga)
ms[c("p", "pencere", "yontem", "son_n")]
head(ms$tablo)

```

* [ ] Izgarada tam **bir** satırın seçildiğini ve bunun en küçük RMSE'li satır olduğunu kontrol et; iki `TRUE` döndürmeli:

```r
sum(ms$tablo$secildi) == 1
ms$tablo$RMSE[ms$tablo$secildi] == min(ms$tablo$RMSE)

```

* [ ] Seçilen pencerenin aday listesinde olduğunu kontrol et; `TRUE` döndürmeli:

```r
ms$pencere %in% u$gosterge_pencere_adaylari(ga)

```

* [ ] Seçilen satırın RMSE'sinin, aynı ayarlarla elle çalıştırılan kayan pencereyle aynı olduğunu kontrol et; `TRUE` döndürmeli:

```r
s_ms <- u$kayan_pencere_tahmin(hazir, ga, pencere = ms$pencere, p = ms$p, son_n = ms$son_n)
isTRUE(all.equal(u$rmse(s_ms$gercek, s_ms$tahmin), ms$tablo$RMSE[ms$tablo$secildi]))

```

* [ ] Farklı p adaylarının **aynı son dönemleri** tahmin ettiğini (karşılaştırmanın adil olduğunu) kontrol et; `TRUE` döndürmeli:

```r
son_tarihler <- lapply(unique(ms$tablo$p), function(pp)
  u$kayan_pencere_tahmin(hazir, ga, pencere = max(ms$tablo$pencere[ms$tablo$p == pp]), p = pp, son_n = ms$son_n)$tarih)
length(unique(son_tarihler)) == 1

```

* [ ] Çapraz doğrulama kapalıyken config varsayılanlarını döndürdüğünü kontrol et; `"varsayilan"` ve `TRUE` döndürmeli:

```r
u$CONFIG$model$model_secimi <- "sabit"
ms0 <- u$model_sec(hazir, ga)
ms0$yontem
ms0$p == u$gosterge_p(ga) && ms0$pencere == u$gosterge_pencere(ga) && is.null(ms0$tablo)

```

* [ ] Çapraz doğrulama açıkken veri çok kısaysa varsayılana düştüğünü kontrol et; `"varsayilan"` döndürmeli:

```r
u$CONFIG$model$model_secimi <- "capraz"
u$model_sec(hazir[hazir$gosterge != ga | hazir$tarih >= as.Date("2023-01-01"), ], ga)$yontem

```

* [ ] Yöntemsel not: model son `son_n` dönemdeki RMSE'ye göre seçiliyor. `gosterge_hesapla()` ise aynı dönemleri de içeren tüm geçmişte hata raporluyor. Bu yüzden raporlanan örnek dışı hatalar bir miktar **iyimser** çıkar. Temiz bir karşılaştırma için son `son_n` dönem seçimden ayrı tutulmalı.

* [ ] Model seçim ayarını eski haline getir:

```r
u$CONFIG$model$model_secimi <- eski_secim

```

## 10) gosterge_hesapla()

* [ ] Tek gösterge için tüm hesaplamayı çalıştır; liste `ozet gelecek gecmis cv` öğelerini içermeli:

```r
h <- u$gosterge_hesapla(hazir, ga, "SAHTE")
names(h)
t(h$ozet)

```

* [ ] Özet ile ayrıntıların tutarlı olduğunu kontrol et; üç `TRUE` döndürmeli:

```r
h$ozet$N_TAHMIN == nrow(h$gecmis)
h$ozet$UFUK == nrow(h$gelecek)
h$ozet$SON_GOZLEM == max(hazir$tarih[hazir$gosterge == ga])

```

* [ ] Yöntem ile çapraz doğrulama tablosunun uyumlu olduğunu kontrol et; `TRUE` döndürmeli (`YONTEM` Türkçe harflerle düzgün görünmeli):

```r
h$ozet$YONTEM
(h$ozet$YONTEM == "varsayılan") == is.null(h$cv)

```

## 11) tum_gostergeleri_tahminle()

* [ ] Tüm aktif göstergeleri tahminle; özet satır sayısı aktif gösterge sayısına eşit olmalı:

```r
sonuc <- u$tum_gostergeleri_tahminle(hazir)
nrow(sonuc$ozet) == length(u$aktif_gostergeler())
sonuc$ozet[, c("gosterge", "KAYNAK", "P", "PENCERE", "YONTEM", "RMSE", "GORELI_RMSE")]

```

* [ ] Kaynak bilgisinin metaveriden geldiğini kontrol et; hepsi `"SAHTE"` olmalı:

```r
unique(sonuc$ozet$KAYNAK)

```

* [ ] Veride olmayan göstergenin atlanıp diğerlerinin hesaplandığını kontrol et; ekranda "Veride yok, atlandı" logu çıkmalı, satır sayısı bir eksik olmalı:

```r
nrow(u$tum_gostergeleri_tahminle(hazir[hazir$gosterge != ga, ])$ozet)

```

* [ ] Bir göstergede hata olunca diğerlerinin etkilenmediğini kontrol et; ekranda "Tahmin hatası" logu çıkmalı, satır sayısı bir eksik olmalı (en az 2 aktif gösterge gerekir):

```r
kisa_veri <- rbind(hazir[hazir$gosterge != ga, ], head(hazir[hazir$gosterge == ga, ], 8))
nrow(u$tum_gostergeleri_tahminle(kisa_veri)$ozet)

```

## 12) sonuclari_kaydet()

* [ ] Sonuçları kaydet ve kayıt zamanını al:

```r
zaman <- u$sonuclari_kaydet(sonuc)
zaman

```

* [ ] İşlenmiş tabloların hem `.rds` hem `.csv` olarak yazıldığını kontrol et; hepsi `TRUE` olmalı (`capraz_dogrulama` yalnız çapraz doğrulama sonucu varsa yazılır):

```r
adlar <- c("tahmin_ozeti", "gelecek_tahmin", "gecmis_tahmin", if (!is.null(sonuc$cv)) "capraz_dogrulama")
file.exists(file.path(gecici, "processed", paste0(rep(adlar, each = 2), c(".rds", ".csv"))))

```

* [ ] Toplu sonuç dosyasını kontrol et; `ozet gelecek gecmis cv zaman` öğeleri olmalı ve zaman dönen değerle aynı olmalı:

```r
k <- readRDS(sonuc_yolu)
names(k)
identical(k$zaman, zaman)

```

## 13) calistir_hepsi()

* [ ] Tüm akışı çalıştır; paket `veri ozet gelecek gecmis cv meta kalite zaman` öğelerini içermeli, ekranda "Tahmin tamamlandı" logu çıkmalı:

```r
paket <- u$calistir_hepsi()
names(paket)
!is.null(paket$meta) && !is.null(paket$kalite)

```

* [ ] Hiçbir göstergenin tahmin edilemediği durumda açıklayıcı hatayla durduğunu kontrol et; mesajda "Hiçbir gösterge için tahmin üretilemedi" yazmalı:

```r
yedek_ham <- sahte$ham
sahte$ham <- do.call(rbind, lapply(split(yedek_ham, yedek_ham$kimlik), head, 8))
tryCatch(u$calistir_hepsi(yenile = TRUE), error = function(e) conditionMessage(e))

```

* [ ] Sahte veriyi ve hazır veriyi eski haline getir:

```r
sahte$ham <- yedek_ham
hazir <- u$hazir_veriyi_getir(yenile = TRUE)
invisible(u$calistir_hepsi())

```

## 14) sonuclari_getir()

* [ ] Otomatik güncellemeyi kapat (hazır verinin kendiliğinden yenilenmesi senaryoları karıştırmasın) ve yardımcıları tanımla:

```r
u$CONFIG$guncelleme$otomatik <- FALSE
gun <- u$varsayilan(u$CONFIG$guncelleme$sikligi_gun, 1)
z_once <- readRDS(sonuc_yolu)$zaman

```

* [ ] **Güncel sonuç:** yeniden hesaplamadan kayıttan okuduğunu kontrol et; `TRUE` döndürmeli:

```r
identical(u$sonuclari_getir()$zaman, z_once)

```

* [ ] **Hazır veri sonuçlardan yeni:** yeniden hesapladığını kontrol et; `FALSE` döndürmeli (zaman değişti):

```r
Sys.setFileTime(sonuc_yolu, Sys.time() - 3600)
Sys.setFileTime(hazir_yol, Sys.time())
z1 <- u$sonuclari_getir()$zaman
identical(z1, z_once)

```

* [ ] **Bayat sonuç:** güncelleme sıklığından eski sonuçta yeniden hesapladığını kontrol et; `FALSE` döndürmeli:

```r
Sys.setFileTime(hazir_yol,  Sys.time() - (gun + 6) * 86400)
Sys.setFileTime(sonuc_yolu, Sys.time() - (gun + 5) * 86400)
z2 <- u$sonuclari_getir()$zaman
identical(z2, z1)

```

* [ ] **Bozuk dosya:** hata vermeden yeniden hesapladığını kontrol et; `TRUE` döndürmeli:

```r
writeLines("bozuk", sonuc_yolu)
!is.null(u$sonuclari_getir()$ozet)

```

* [ ] **Yenileme istendi:** kaynaktan çekip yeniden hesapladığını kontrol et; `1` döndürmeli:

```r
sahte$cagri <- 0
invisible(u$sonuclari_getir(yenile = TRUE))
sahte$cagri

```

* [ ] Otomatik güncelleme ayarını eski haline getir:

```r
u$CONFIG$guncelleme$otomatik <- eski_otomatik

```

## 15) gosterge_guncelle()

* [ ] Aktif olmayan göstergede açıklayıcı hata verdiğini kontrol et; mesajda "Aktif olmayan gösterge" yazmalı:

```r
tryCatch(u$gosterge_guncelle("yok_boyle"), error = function(e) conditionMessage(e))

```

* [ ] Başlangıç durumunu kaydet ve kaynağa bir yeni dönem ekle:

```r
invisible(u$calistir_hepsi())
once <- readRDS(sonuc_yolu)
hazir_once <- readRDS(hazir_yol)
ga_son <- max(hazir_once$tarih[hazir_once$gosterge == ga])
sahte$ek <- data.frame(tarih = u$donem_ekle(ga_son, 1, u$gosterge_frekansi(ga)), deger = 101, kimlik = ga)

```

* [ ] Göstergeyi güncelle; kaynak yalnız **1** kez çağrılmalı, ekranda "Gösterge güncellendi" logu çıkmalı:

```r
sahte$cagri <- 0
pk <- u$gosterge_guncelle(ga)
sahte$cagri

```

* [ ] Güncellenen göstergeye yeni dönemin eklendiğini ve hazır verinin kaydedildiğini kontrol et; iki `TRUE` döndürmeli:

```r
max(pk$veri$tarih[pk$veri$gosterge == ga]) == sahte$ek$tarih
identical(readRDS(hazir_yol), pk$veri)

```

* [ ] Diğer göstergelerin verisine ve sonuçlarına dokunulmadığını kontrol et; iki `TRUE` döndürmeli:

```r
a <- hazir_once[hazir_once$gosterge != ga, ]; b <- pk$veri[pk$veri$gosterge != ga, ]
rownames(a) <- rownames(b) <- NULL
identical(a, b)
isTRUE(all.equal(once$ozet[once$ozet$gosterge != ga, ], pk$ozet[pk$ozet$gosterge != ga, ], check.attributes = FALSE))

```

* [ ] Gösterge sırasının korunduğunu ve tahminin bir dönem ileri kaydığını kontrol et; iki `TRUE` döndürmeli:

```r
identical(pk$ozet$gosterge, once$ozet$gosterge)
pk$gelecek$tarih[pk$gelecek$gosterge == ga][1] == u$donem_ekle(sahte$ek$tarih, 1, u$gosterge_frekansi(ga))

```

* [ ] Kaynak hiç yanıt vermezse açıklayıcı hata verdiğini kontrol et; mesajda "hiçbir kanaldan alınamadı" yazmalı:

```r
sahte$hata <- TRUE
tryCatch(u$gosterge_guncelle(ga), error = function(e) conditionMessage(e))
sahte$hata <- FALSE

```

* [ ] **Metaveri dosyası yokken** güncellemenin çalıştığını kontrol et; `"TAMAM"` döndürmeli:

```r
unlink(file.path(gecici, "processed", c("metaveri.rds", "metaveri.csv")))
tryCatch({ u$gosterge_guncelle(ga); "TAMAM" }, error = function(e) conditionMessage(e))

```

* [ ] **Çapraz doğrulama kapatılıp güncellenince** eski çapraz doğrulama satırlarının silindiğini kontrol et; ikinci değer `0` olmalı:

```r
u$CONFIG$model$model_secimi <- "capraz"
invisible(u$calistir_hepsi())
sum(readRDS(sonuc_yolu)$cv$gosterge == ga)
u$CONFIG$model$model_secimi <- "sabit"
invisible(u$gosterge_guncelle(ga))
sum(readRDS(sonuc_yolu)$cv$gosterge == ga)

```

* [ ] **Önceki çalıştırmada hiç çapraz doğrulama yokken** güncellemenin çalıştığını kontrol et; `"TAMAM"` döndürmeli:

```r
invisible(u$calistir_hepsi())
u$CONFIG$model$model_secimi <- "capraz"
tryCatch({ u$gosterge_guncelle(ga); "TAMAM" }, error = function(e) conditionMessage(e))
u$CONFIG$model$model_secimi <- eski_secim

```

* [ ] Son üç adımda "TAMAM" yerine hata (ör. "incorrect number of dimensions") ya da `0` yerine pozitif sayı çıktıysa bu hatadır. Sebebi şu: `degistir()` boş (`NULL`) tabloyu işleyemiyor, `cv` de gösterge çapraz doğrulamasız hesaplanınca eski satırlarını koruyor. `gosterge_guncelle()` içinde `degistir` tanımını ve `cv =` satırını şöyle değiştir, sonra bu bölümü tekrar çalıştır:

```r
  degistir <- function(tablo, satir, anahtar = "gosterge") {
    if (is.null(tablo)) return(satir)
    y <- rbind(tablo[tablo[[anahtar]] != ad, , drop = FALSE], satir); rownames(y) <- NULL; y
  }

```

```r
                cv = degistir(k$cv, h$cv))

```

* [ ] Eklenen yeni dönemi kaldır:

```r
sahte$ek <- NULL

```

## 16) Hız

* [ ] Çapraz doğrulama açıkken tek göstergenin hesaplama süresini ölç (sn):

```r
u$CONFIG$model$model_secimi <- "capraz"
system.time(invisible(u$gosterge_hesapla(hazir, ga)))[["elapsed"]]

```

* [ ] Tüm akışın süresini ölç (sn); uygulama açılışında bekleme yaratmaması için birkaç saniyeyi geçmemeli:

```r
system.time(invisible(capture.output(u$calistir_hepsi())))[["elapsed"]]
u$CONFIG$model$model_secimi <- eski_secim

```

## Temizlik

* [ ] Geçici test klasörünü sil:

```r
unlink(gecici, recursive = TRUE)

```

* [ ] Gerçek API anahtarlarını geri yükle:

```r
if (nzchar(eski_fred)) Sys.setenv(FRED_API_KEY = eski_fred) else Sys.unsetenv("FRED_API_KEY")
if (nzchar(eski_evds)) Sys.setenv(EVDS_API_KEY = eski_evds) else Sys.unsetenv("EVDS_API_KEY")

```

* [ ] Test sırasında oluşan nesneleri sil:

```r
rm(list = intersect(ls(), c(
  "config_yolu", "utils_yolu", "prep_yolu", "models_yolu", "eski_fred", "eski_evds", "sahte", "sahte_api",
  "yukle_modeller", "u", "gecici", "hazir_yol", "sonuc_yolu", "eski_secim", "eski_otomatik", "tr", "hazir",
  "ga", "satirlar", "ifadeler", "tanimlar", "ham_bayt", "metin", "dene", "e1", "e2", "e3", "mesajlar",
  "uyarilar", "tanimli_mi", "cfg", "notlar", "gr", "th", "m_ar", "ps_aic", "ps_bic", "n_ga", "kisa", "w",
  "s", "d2", "f2", "m1", "s12", "mt", "f", "egitim", "m_f", "yeni", "f1", "d1", "m1b", "phi", "z", "gen",
  "f60", "eski_guven", "f80", "sabit", "f_s", "ms", "s_ms", "son_tarihler", "ms0", "h", "sonuc",
  "kisa_veri", "zaman", "adlar", "k", "paket", "yedek_ham", "gun", "z_once", "z1", "z2", "once",
  "hazir_once", "ga_son", "pk", "a", "b"
)))

```

* [ ] Sağ üstteki "Environment" sekmesinde test nesnelerinin kalmadığını kontrol et
* [ ] Başarısız olan adımları not al ve models.R'ı düzelttikten sonra ilgili bölümü tekrar çalıştır