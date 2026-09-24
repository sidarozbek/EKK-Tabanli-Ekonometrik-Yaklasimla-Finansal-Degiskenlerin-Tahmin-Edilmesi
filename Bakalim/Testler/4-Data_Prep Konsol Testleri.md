## Hazırlık

* [ ] RStudio'da projeyi aç, Console'da proje kökünde olduğunu kontrol et ve `R/` klasöründeki dosya adlarına bak:

```r
getwd()
list.files("R")

```

* [ ] Dosyaların tam yollarını değişkenlere yaz (veri hazırlama dosyasının adı farklıysa `data_prep.R` kısmını listede gördüğün adla değiştir):

```r
config_yolu <- normalizePath("R/config.R", winslash = "/")
utils_yolu  <- normalizePath("R/utils.R", winslash = "/")
prep_yolu   <- normalizePath("R/data_prep.R", winslash = "/")
file.exists(c(config_yolu, utils_yolu, prep_yolu))

```

* [ ] Gerekli paketlerin kurulu olduğunu kontrol et; iki `TRUE` döndürmeli:

```r
c(dplyr = requireNamespace("dplyr", quietly = TRUE), zoo = requireNamespace("zoo", quietly = TRUE))

```

* [ ] Gerçek API anahtarlarını sakla ve testler için sahte anahtar tanımla:

```r
eski_fred <- Sys.getenv("FRED_API_KEY")
eski_evds <- Sys.getenv("EVDS_API_KEY")
Sys.setenv(FRED_API_KEY = "KT_FRED", EVDS_API_KEY = "KT_EVDS")

```

* [ ] İnternete çıkmadan test edebilmek için sahte veri kaynağını tanımla. `tum_gostergeleri_cek()` yerine bu çalışacak; kaç kez çağrıldığını sayar ve istenirse hata verir:

```r
sahte <- new.env()
sahte$cagri <- 0
sahte$hata  <- FALSE
sahte$ham   <- NULL

```

* [ ] config.R + utils.R + sahte kaynak + veri hazırlama dosyasını temiz bir ortamda yükleyen yardımcı fonksiyonu tanımla (api_functions.R yüklenmez, ağ erişimi olmaz):

```r
yukle_hazirlik <- function() {
  e <- new.env(parent = globalenv())
  suppressMessages({
    sys.source(config_yolu, envir = e, keep.source = FALSE, toplevel.env = e)
    sys.source(utils_yolu,  envir = e, keep.source = FALSE, toplevel.env = e)
  })
  e$tum_gostergeleri_cek <- function(yenile = FALSE) {
    sahte$cagri <- sahte$cagri + 1
    if (sahte$hata) stop("sahte bağlantı hatası")
    sahte$ham
  }
  suppressMessages(sys.source(prep_yolu, envir = e, keep.source = FALSE, toplevel.env = e))
  e
}

```

* [ ] Test ortamını yükle; fonksiyonlara bundan sonra `u$fonksiyon_adi()` şeklinde ulaşılacak:

```r
u <- yukle_hazirlik()

```

* [ ] Kaydedilen dosyaların projedeki gerçek `data/processed/` ve `logs/` klasörlerine gitmemesi için test ortamındaki klasörleri geçici bir klasöre yönlendir:

```r
gecici <- file.path(tempdir(), "prep_test")
u$CONFIG$saklama$processed_klasoru <- file.path(gecici, "processed")
u$CONFIG$saklama$cache_klasoru     <- file.path(gecici, "cache")
u$CONFIG$saklama$yedek_klasoru     <- file.path(gecici, "yedek")
u$CONFIG$saklama$log_klasoru       <- file.path(gecici, "logs")

```

* [ ] Her aktif gösterge için kendi frekansında 60 dönemlik sahte ham veri üret (`tarih`, `deger`, `kimlik` sütunlarıyla, API'den gelen biçimde):

```r
set.seed(42)
sahte$ham <- do.call(rbind, lapply(u$aktif_gostergeler(), function(g) {
  adim <- u$frekans_ayari(u$gosterge_frekansi(g))$ay_adimi
  data.frame(tarih  = seq(as.Date("2018-01-01"), by = paste(adim, "months"), length.out = 60),
             deger  = round(100 + cumsum(rnorm(60)), 2),
             kimlik = g, stringsAsFactors = FALSE)
}))
table(sahte$ham$kimlik)

```

* [ ] Testlerde kullanılacak aylık bir göstergeyi seç; `NA` dönerse aylık aktif gösterge yok demektir, `ga` yerine başka bir aktif göstergenin adını elle yaz:

```r
ga <- Filter(function(g) u$gosterge_frekansi(g) == "aylik", u$aktif_gostergeler())[1]
ga

```

* [ ] Dosyanın satırlarını oku:

```r
satirlar <- readLines(prep_yolu, encoding = "UTF-8", warn = FALSE)

```

## 1) Sözdizimi, kodlama ve biçim

* [ ] Sözdizimi hatası olmadığını kontrol et ve tanımlanan fonksiyonları listele; **8** fonksiyon olmalı:

```r
ifadeler <- parse(prep_yolu, encoding = "UTF-8")
tanimlar <- Filter(function(e) is.call(e) && identical(e[[1]], as.name("<-")) &&
                     is.call(e[[3]]) && identical(e[[3]][[1]], as.name("function")), ifadeler)
sapply(tanimlar, function(e) as.character(e[[2]]))

```

* [ ] BOM olmadığını (`FALSE`) ve dosyanın geçerli UTF-8 olduğunu (`TRUE`) kontrol et:

```r
ham_bayt <- readBin(prep_yolu, "raw", file.info(prep_yolu)$size)
identical(ham_bayt[1:3], as.raw(c(0xEF, 0xBB, 0xBF)))
metin <- rawToChar(ham_bayt)
Encoding(metin) <- "UTF-8"
validUTF8(metin)

```

* [ ] Türkçe harfin kodda (değişken adında) geçmediğini, sekme ve satır sonu boşluğu olmadığını kontrol et; hepsi `integer(0)` olmalı:

```r
which(grepl("[çğıöşüÇĞİÖŞÜ]", gsub('"[^"]*"|#.*$', "", satirlar)))
grep("\t", satirlar)
grep("[ \t]+$", satirlar)

```

* [ ] 120 karakterden uzun satırları listele (uyarı, testi düşürmez):

```r
which(nchar(satirlar, type = "width") > 120)

```

## 2) Yükleme ve bağımlılıklar

* [ ] Önkoşulların sırasıyla kontrol edildiğini doğrula; üç komut sırasıyla "config.R", "utils.R" ve "api_functions.R" uyarısı veren hata döndürmeli:

```r
dene <- function(e) tryCatch({ sys.source(prep_yolu, envir = e, toplevel.env = e); "YÜKLENDİ" },
                             error = function(h) conditionMessage(h))
e1 <- new.env(parent = baseenv())
dene(e1)
e2 <- new.env(parent = baseenv()); e2$CONFIG <- u$CONFIG
dene(e2)
e3 <- new.env(parent = baseenv()); e3$CONFIG <- u$CONFIG; e3$log_msg <- u$log_msg
dene(e3)

```

* [ ] Yüklemenin uyarısız olduğunu ve "8 fonksiyon yerinde" mesajı verdiğini kontrol et; `uyarilar` `character(0)` olmalı:

```r
mesajlar <- uyarilar <- character(0)
withCallingHandlers(
  invisible(yukle_hazirlik()),
  message = function(m) { mesajlar <<- c(mesajlar, trimws(conditionMessage(m))); invokeRestart("muffleMessage") },
  warning = function(w) { uyarilar <<- c(uyarilar, conditionMessage(w)); invokeRestart("muffleWarning") }
)
uyarilar
grep("data.prep", mesajlar, value = TRUE)

```

* [ ] Dosyanın `library()` ile dplyr ve zoo'yu global arama yoluna eklediğini not et; iki `TRUE` döner. dplyr'ın `stats::filter` ve `stats::lag`'i maskelediğini unutma (dosya içinde `dplyr::lag` açıkça yazıldığı için sorun yok):

```r
c("package:dplyr", "package:zoo") %in% search()

```

* [ ] Tanımsız değişken olmadığını codetools ile kontrol et; `character(0)` döndürmeli:

```r
notlar <- capture.output(codetools::checkUsageEnv(u, all = TRUE))
grep("no visible", notlar, value = TRUE)

```

## 3) seri_hazirla()

* [ ] Eksik ay, ay ortası tarih, aynı ayda iki kayıt ve `NA` içeren elle hazırlanmış bir seri oluştur:

```r
d_el <- data.frame(
  tarih = as.Date(c("2025-01-15", "2025-02-10", "2025-04-05", "2025-04-25", "2025-05-01", "2025-06-01")),
  deger = c(10, 20, 40, 44, NA, 60)
)

```

* [ ] Seriyi hazırla ve incele; Ocak–Haziran **6 satır**, tarihler ayın 1'i olmalı:

```r
s <- u$seri_hazirla(d_el, ga)
s

```

* [ ] Değerleri kontrol et; `TRUE` döndürmeli (Mart 20 ile 44 arası → 32, Nisan son kayıt → 44, Mayıs 44 ile 60 arası → 52):

```r
isTRUE(all.equal(s$deger, c(10, 20, 32, 44, 52, 60)))

```

* [ ] `gercek` sütununu kontrol et; Mart ve Mayıs `FALSE` olmalı, `TRUE` döndürmeli:

```r
identical(s$gercek, c(TRUE, TRUE, FALSE, TRUE, FALSE, TRUE))

```

* [ ] `ic_bosluk_say()`'ın doldurulan dönemleri saydığını kontrol et; `2` döndürmeli:

```r
u$ic_bosluk_say(s)

```

* [ ] Girdi sırasının sonucu değiştirmediğini kontrol et; `TRUE` döndürmeli:

```r
s_ters <- u$seri_hazirla(d_el[nrow(d_el):1, ], ga)
isTRUE(all.equal(s$deger, s_ters$deger))
s_ters$deger[4]

```

* [ ] Yukarıdaki `FALSE` ve Nisan değeri `40` çıktıysa bu bir hatadır: aynı döneme düşen kayıtlardan "tarihçe en sonuncusu" değil "girdide en sonda olanı" tutuluyor. `seri_hazirla()` içinde `d <- d[!is.na(d$deger), ]` satırının hemen altına sıralama ekle ve bu bölümü tekrar çalıştır:

```r
  d <- d[order(d$tarih), ]

```

* [ ] Günlük veri aylığa çevrilirken **ay ortalaması değil, ayın son gözlemi** alındığını not et (örneğin günlük faiz serisi için). Ortalama isteniyorsa ayrıca düzenleme gerekir:

```r
gunluk <- data.frame(tarih = as.Date("2025-03-01") + 0:30, deger = 1:31)
u$seri_hazirla(gunluk, ga)

```

* [ ] Tek gözlemli seride 1 satır döndüğünü kontrol et:

```r
u$seri_hazirla(data.frame(tarih = as.Date("2025-01-01"), deger = 5), ga)

```

* [ ] Boş ve tamamen `NA` seride ne olduğuna bak; açıklayıcı olmayan bir hata ya da uyarı çıkarsa (ör. "no non-missing arguments to min"), `seri_hazirla()` başına boş veri kontrolü eklemeyi not et:

```r
tryCatch(u$seri_hazirla(data.frame(tarih = as.Date(character()), deger = numeric()), ga),
         error = function(e) paste("HATA:", conditionMessage(e)))
tryCatch(u$seri_hazirla(data.frame(tarih = as.Date("2025-01-01") + 0:2, deger = NA_real_), ga),
         error = function(e) paste("HATA:", conditionMessage(e)))

```

## 4) hampel_sapan()

* [ ] 8'den kısa seride hiçbir şeyi sapan saymadığını kontrol et; `TRUE` döndürmeli:

```r
!any(u$hampel_sapan(c(1, 2, 3, 50, 4)))

```

* [ ] Düz artan seride (farkların MAD'ı 0) hiçbir şeyi sapan saymadığını kontrol et; `TRUE` döndürmeli:

```r
!any(u$hampel_sapan(1:20))

```

* [ ] Tek noktalık sıçramayı yakaladığını kontrol et; **25 ve 26** döndürmeli (fark üzerinden çalıştığı için hem çıkış hem dönüş işaretlenir):

```r
set.seed(1)
x <- 100 + cumsum(rnorm(40))
x[25] <- x[25] + 30
which(u$hampel_sapan(x))

```

* [ ] Kalıcı seviye kaymasında yalnız kayma noktasını yakaladığını kontrol et; **20** döndürmeli:

```r
set.seed(1)
x2 <- 100 + cumsum(rnorm(40))
x2[20:40] <- x2[20:40] + 30
which(u$hampel_sapan(x2))

```

* [ ] Eşik parametresinin çalıştığını kontrol et; düşük eşik daha çok nokta işaretlemeli:

```r
c(esik_3 = sum(u$hampel_sapan(x, esik = 3)), esik_1 = sum(u$hampel_sapan(x, esik = 1)))

```

* [ ] `NA` içeren seride uzunluğun korunduğunu kontrol et; `40` ve `FALSE` döndürmeli:

```r
x_na <- x; x_na[11] <- NA
length(u$hampel_sapan(x_na))
anyNA(u$hampel_sapan(x_na))

```

## 5) kalite_raporu_olustur()

* [ ] Raporun kullandığı bitiş tarihinin config'te tanımlı ve geçerli olduğunu kontrol et; tarih yazmalı, hata vermemeli:

```r
u$CONFIG$veri$bitis_tarihi
as.Date(u$CONFIG$veri$bitis_tarihi)

```

* [ ] Sahte ham veriden raporu oluştur ve incele; her aktif gösterge için 1 satır olmalı:

```r
rapor <- u$kalite_raporu_olustur(sahte$ham)
print(rapor, row.names = FALSE)
nrow(rapor) == length(u$aktif_gostergeler())

```

* [ ] Boşluksuz sahte veride gözlem sayısının 60, eksik dönem oranının 0 olduğunu kontrol et; iki `TRUE` döndürmeli:

```r
all(rapor$gozlem == 60)
all(rapor$eksik_donem_orani == 0)

```

* [ ] Gecikme hesabını kontrol et: bitiş tarihini geçici olarak 2025-09-15 yap; Haziran 2025'te biten aylık seride `3`, bitişten sonraki tarihte biten seride `0` döndürmeli:

```r
eski_bitis <- u$CONFIG$veri$bitis_tarihi
u$CONFIG$veri$bitis_tarihi <- "2025-09-15"
d_gec <- data.frame(tarih = seq(as.Date("2024-01-01"), as.Date("2025-06-01"), by = "month"), deger = 1:18, kimlik = ga)
u$kalite_raporu_olustur(d_gec)$gecikme_donem
d_ileri <- data.frame(tarih = seq(as.Date("2024-01-01"), as.Date("2025-12-01"), by = "month"), deger = 1:24, kimlik = ga)
u$kalite_raporu_olustur(d_ileri)$gecikme_donem
u$CONFIG$veri$bitis_tarihi <- eski_bitis

```

* [ ] Eksik dönemin oranı doğru hesaplıyor mu kontrol et; 18 aydan 3'ü silinince `0.167` döndürmeli:

```r
u$kalite_raporu_olustur(d_gec[-c(5, 9, 13), ])$eksik_donem_orani

```

* [ ] Aynı döneme düşen tekrar kayıtlarda (günlük veri, çift satır) oranın bozulmadığını kontrol et; `0` döndürmeli:

```r
u$kalite_raporu_olustur(rbind(d_gec, d_gec))$eksik_donem_orani
u$kalite_raporu_olustur(rbind(d_gec, d_gec))$gozlem

```

* [ ] Yukarıda **-1** ve gözlem `36` çıktıysa bu bir hatadır: rapor ham veriyi tekilleştirmeden sayıyor, günlük seride oran büyük negatif olur. `NA` satırları da gözlem sayılır. `kalite_raporu_olustur()` içinde `d$tarih <- donem_basi(d$tarih, f)` satırının hemen altına şunları ekle ve bu bölümü tekrar çalıştır:

```r
    d <- d[!is.na(d$deger), ]
    d <- d[!duplicated(d$tarih, fromLast = TRUE), ]

```

* [ ] Sapan değerin rapora yansıdığını kontrol et; `sapan_sayisi` 2, `sapan_tarihleri` iki ay içermeli:

```r
d_sapan <- data.frame(tarih = seq(as.Date("2022-01-01"), by = "month", length.out = 40), deger = x, kimlik = ga)
u$kalite_raporu_olustur(d_sapan)[, c("sapan_sayisi", "sapan_tarihleri")]

```

## 6) veriyi_hazirla()

* [ ] Sahte ham veriyi hazırla; ekranda "başladı" ve "bitti" logları görünmeli:

```r
hazir <- u$veriyi_hazirla(sahte$ham)

```

* [ ] Çıktının biçimini kontrol et; sütunlar `gosterge tarih deger gercek` olmalı, `deger`'de `NA` olmamalı (`FALSE`):

```r
names(hazir)
str(hazir)
anyNA(hazir$deger)

```

* [ ] Her göstergenin 60 satırla geldiğini ve hiç boşluk doldurulmadığını kontrol et; `TRUE` ve `0` döndürmeli:

```r
all(table(hazir$gosterge) == 60)
u$ic_bosluk_say(hazir)

```

* [ ] Hazır veri ve kalite raporunun hem `.rds` hem `.csv` olarak kaydedildiğini kontrol et; dört `TRUE` döndürmeli:

```r
file.exists(file.path(gecici, "processed",
                      c("hazir_veri.rds", "hazir_veri.csv", "kalite_raporu.rds", "kalite_raporu.csv")))

```

* [ ] Kaydedilen hazır verinin döndürülenle aynı olduğunu kontrol et; `TRUE` döndürmeli:

```r
identical(readRDS(file.path(gecici, "processed", "hazir_veri.rds")), hazir)

```

## 7) gosterge_serisi()

* [ ] Tek göstergenin serisini al; 3 sütun (`tarih deger gercek`), 60 satır, tarih sıralı ve satır adları 1'den başlamalı:

```r
gs <- u$gosterge_serisi(hazir, ga)
names(gs)
nrow(gs)
!is.unsorted(gs$tarih)
head(rownames(gs), 3)

```

* [ ] Karışık sıralı veride de sıralı döndüğünü kontrol et; `TRUE` döndürmeli:

```r
!is.unsorted(u$gosterge_serisi(hazir[sample(nrow(hazir)), ], ga)$tarih)

```

* [ ] Olmayan göstergede hata vermeden 0 satır döndürdüğünü kontrol et; `0` döndürmeli:

```r
nrow(u$gosterge_serisi(hazir, "yok_boyle"))

```

## 8) gosterge_verisi()

* [ ] p = 3 ile model verisini kur; sütunlar `tarih`, gösterge adı ve `_lag1…_lag3`, satır sayısı **57** (60 − 3) olmalı:

```r
gv <- u$gosterge_verisi(hazir, ga, p = 3)
names(gv)
nrow(gv)

```

* [ ] Gecikmelerin doğru kaydırıldığını kontrol et; iki `TRUE` döndürmeli:

```r
seri <- u$gosterge_serisi(hazir, ga)$deger
identical(gv[[paste0(ga, "_lag1")]], seri[3:59])
identical(gv[[paste0(ga, "_lag3")]], seri[1:57])

```

* [ ] Modelde `NA` kalmadığını kontrol et; `FALSE` döndürmeli:

```r
anyNA(gv)

```

* [ ] p verilmeyince config'teki `gosterge_p()` değerinin kullanıldığını kontrol et; `TRUE` döndürmeli:

```r
ncol(u$gosterge_verisi(hazir, ga)) == 2 + u$gosterge_p(ga)

```

* [ ] Trend sütununu kontrol et; ilk değer `1` değil **p + 1** (`4`) çıkar, çünkü trend gecikmeli satırlar atılmadan önce ekleniyor. Tahminde trend sürdürülürken aynı sayımın kullanıldığından emin ol:

```r
gv_t <- u$gosterge_verisi(hazir, ga, p = 3, trend = TRUE)
head(gv_t$trend, 3)

```

* [ ] Hazır veride olmayan göstergede açıklayıcı hata verdiğini kontrol et; mesajda "Hazır veride yok" yazmalı:

```r
tryCatch(u$gosterge_verisi(hazir, "yok_boyle", p = 2), error = function(e) conditionMessage(e))

```

## 9) hazir_veriyi_getir()

* [ ] Güncelleme ayarlarını not et ve yardımcı değişkenleri tanımla:

```r
u$CONFIG$guncelleme$sikligi_gun
eski_otomatik <- u$CONFIG$guncelleme$otomatik
hazir_yol <- file.path(gecici, "processed", "hazir_veri.rds")
eskit <- function() Sys.setFileTime(hazir_yol, Sys.time() - (u$varsayilan(u$CONFIG$guncelleme$sikligi_gun, 1) + 5) * 86400)

```

* [ ] **Kayıt yok:** kaynaktan çekip kaydettiğini kontrol et; `1` ve `TRUE` döndürmeli:

```r
unlink(hazir_yol); sahte$cagri <- 0; sahte$hata <- FALSE
x1 <- u$hazir_veriyi_getir()
sahte$cagri
file.exists(hazir_yol)

```

* [ ] **Taze kayıt:** kaynağa gitmeden kaydı kullandığını kontrol et; `0` ve `TRUE` döndürmeli, ekranda "Hazır veri bulundu" logu görünmeli:

```r
sahte$cagri <- 0
x2 <- u$hazir_veriyi_getir()
sahte$cagri
identical(x1, x2)

```

* [ ] **Yenileme istendi:** kayıt taze olsa da kaynaktan çektiğini kontrol et; `1` döndürmeli:

```r
sahte$cagri <- 0
invisible(u$hazir_veriyi_getir(yenile = TRUE))
sahte$cagri

```

* [ ] **Bayat kayıt + otomatik güncelleme açık:** kaynaktan çektiğini kontrol et; `1` döndürmeli:

```r
u$CONFIG$guncelleme$otomatik <- TRUE
eskit(); sahte$cagri <- 0
invisible(u$hazir_veriyi_getir())
sahte$cagri

```

* [ ] **Bayat kayıt + otomatik güncelleme kapalı:** kaynağa gitmeden eski kaydı kullandığını kontrol et; `0` döndürmeli:

```r
u$CONFIG$guncelleme$otomatik <- FALSE
eskit(); sahte$cagri <- 0
invisible(u$hazir_veriyi_getir())
sahte$cagri

```

* [ ] **Çekim başarısız + kayıt var:** mevcut kaydı koruduğunu kontrol et; `1` ve `TRUE` döndürmeli, ekranda "HATA" ve "mevcut hazır veri korunuyor" logları görünmeli:

```r
mevcut <- readRDS(hazir_yol)
sahte$hata <- TRUE; sahte$cagri <- 0
x3 <- u$hazir_veriyi_getir(yenile = TRUE)
sahte$cagri
identical(x3, mevcut)

```

* [ ] **Çekim başarısız + kayıt yok:** açıklayıcı hatayla durduğunu kontrol et; mesajda "Hazır veri yok ve hiçbir gösterge çekilemedi" yazmalı:

```r
unlink(hazir_yol)
tryCatch(u$hazir_veriyi_getir(), error = function(e) conditionMessage(e))
sahte$hata <- FALSE

```

* [ ] **Eski biçimli (geniş) kayıt:** kaydı geçersiz sayıp yeniden ürettiğini kontrol et; `1` ve `TRUE` döndürmeli, ekranda "eski/bozuk biçimde" uyarısı görünmeli:

```r
dir.create(dirname(hazir_yol), showWarnings = FALSE, recursive = TRUE)
saveRDS(data.frame(tarih = as.Date("2025-01-01"), enflasyon = 1, faiz = 2), hazir_yol)
sahte$cagri <- 0
x4 <- u$hazir_veriyi_getir()
sahte$cagri
all(c("gosterge", "tarih", "deger", "gercek") %in% names(readRDS(hazir_yol)))

```

* [ ] **Bozuk dosya:** hata vermeden yeniden ürettiğini kontrol et; `1` döndürmeli:

```r
writeLines("bozuk", hazir_yol)
sahte$cagri <- 0
invisible(u$hazir_veriyi_getir())
sahte$cagri

```

* [ ] Otomatik güncelleme ayarını eski haline getir:

```r
u$CONFIG$guncelleme$otomatik <- eski_otomatik

```

## 10) Hız

* [ ] Sahte veriyle tüm hazırlama akışının süresini ölç (ms); birkaç yüz ms'nin altında olmalı:

```r
system.time(invisible(capture.output(u$veriyi_hazirla(sahte$ham))))[["elapsed"]] * 1000

```

* [ ] 10 yıllık günlük bir serinin aylığa çevrilme süresini ölç (ms); 100 ms'nin altında olmalı:

```r
gunluk_uzun <- data.frame(tarih = seq(as.Date("2015-01-01"), as.Date("2024-12-31"), by = "day"))
gunluk_uzun$deger <- cumsum(rnorm(nrow(gunluk_uzun)))
system.time(u$seri_hazirla(gunluk_uzun, ga))[["elapsed"]] * 1000

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
  "config_yolu", "utils_yolu", "prep_yolu", "eski_fred", "eski_evds", "sahte", "yukle_hazirlik", "u",
  "gecici", "ga", "satirlar", "ifadeler", "tanimlar", "ham_bayt", "metin", "dene", "e1", "e2", "e3",
  "mesajlar", "uyarilar", "notlar", "d_el", "s", "s_ters", "gunluk", "x", "x2", "x_na", "rapor",
  "eski_bitis", "d_gec", "d_ileri", "d_sapan", "hazir", "gs", "gv", "seri", "gv_t", "eski_otomatik",
  "hazir_yol", "eskit", "x1", "x2", "x3", "x4", "mevcut", "gunluk_uzun"
)))

```

* [ ] Sağ üstteki "Environment" sekmesinde test nesnelerinin kalmadığını kontrol et
* [ ] Başarısız olan adımları not al ve dosyayı düzelttikten sonra ilgili bölümü tekrar çalıştır