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
api_yolu    <- normalizePath("R/api_functions.R", winslash = "/")
file.exists(c(config_yolu, utils_yolu, api_yolu))

```

* [ ] Gerekli paketlerin kurulu olduğunu kontrol et; dört `TRUE` döndürmeli:

```r
sapply(c("fredr", "httr", "jsonlite", "wbstats"), requireNamespace, quietly = TRUE)

```

* [ ] Gerçek API anahtarlarını sakla ve testler için sahte anahtar tanımla (14. bölümdeki canlı test dışında hiçbir adım internete çıkmaz):

```r
eski_fred <- Sys.getenv("FRED_API_KEY")
eski_evds <- Sys.getenv("EVDS_API_KEY")
Sys.setenv(FRED_API_KEY = "KT_FRED", EVDS_API_KEY = "KT_EVDS")

```

* [ ] config.R + utils.R + api_functions.R'ı temiz bir ortamda yükleyen yardımcı fonksiyonu tanımla:

```r
yukle_api <- function() {
  e <- new.env(parent = globalenv())
  suppressMessages(suppressWarnings({
    sys.source(config_yolu, envir = e, keep.source = FALSE, toplevel.env = e)
    sys.source(utils_yolu,  envir = e, keep.source = FALSE, toplevel.env = e)
    sys.source(api_yolu,    envir = e, keep.source = FALSE, toplevel.env = e)
  }))
  e
}

```

* [ ] Test ortamını yükle; fonksiyonlara bundan sonra `u$fonksiyon_adi()` şeklinde ulaşılacak:

```r
u <- yukle_api()

```

* [ ] Yazılan dosyaları geçici klasöre yönlendir ve tekrar denemeler arasındaki beklemeyi sıfırla (testler hızlı çalışsın):

```r
gecici <- file.path(tempdir(), "api_test")
u$CONFIG$saklama$processed_klasoru <- file.path(gecici, "processed")
u$CONFIG$saklama$cache_klasoru     <- file.path(gecici, "cache")
u$CONFIG$saklama$yedek_klasoru     <- file.path(gecici, "yedek")
u$CONFIG$saklama$log_klasoru       <- file.path(gecici, "logs")
u$CONFIG$baglanti$yeniden_deneme_bekleme <- 0

```

* [ ] Dosyanın satırlarını oku:

```r
satirlar <- readLines(api_yolu, encoding = "UTF-8", warn = FALSE)

```

## 1) Sözdizimi, kodlama ve biçim

* [ ] Sözdizimi hatası olmadığını kontrol et ve tanımlanan fonksiyonları listele; **20** fonksiyon olmalı (`kaynak_kullanilabilir` bu dosyada tanımlı değil):

```r
ifadeler <- parse(api_yolu, encoding = "UTF-8")
tanimlar <- Filter(function(e) is.call(e) && identical(e[[1]], as.name("<-")) &&
                     is.call(e[[3]]) && identical(e[[3]][[1]], as.name("function")), ifadeler)
length(tanimlar)
sapply(tanimlar, function(e) as.character(e[[2]]))

```

* [ ] BOM olmadığını (`FALSE`) ve dosyanın geçerli UTF-8 olduğunu (`TRUE`) kontrol et:

```r
ham_bayt <- readBin(api_yolu, "raw", file.info(api_yolu)$size)
identical(ham_bayt[1:3], as.raw(c(0xEF, 0xBB, 0xBF)))
metin <- rawToChar(ham_bayt)
Encoding(metin) <- "UTF-8"
validUTF8(metin)

```

* [ ] Türkçe harfin kodda (değişken adında) geçmediğini ve sekme olmadığını kontrol et; ikisi de `integer(0)` olmalı:

```r
which(grepl("[çğıöşüÇĞİÖŞÜ]", gsub('"[^"]*"|#.*$', "", satirlar)))
grep("\t", satirlar)

```

* [ ] Satır sonu boşluğu ve 120 karakterden uzun satırları listele (uyarı, testi düşürmez):

```r
grep("[ \t]+$", satirlar)
which(nchar(satirlar, type = "width") > 120)

```

* [ ] Dosyada gömülü API anahtarı olmadığını kontrol et; `integer(0)` döndürmeli:

```r
grep("\\b[0-9a-f]{32}\\b|key\\s*=\\s*\"[^\"]{8,}\"", satirlar)

```

## 2) Yükleme ve bağımlılıklar

* [ ] Önkoşulların sırasıyla kontrol edildiğini doğrula; iki komut sırasıyla "config.R" ve "utils.R" uyarısı veren hata döndürmeli:

```r
dene <- function(e) tryCatch({ sys.source(api_yolu, envir = e, toplevel.env = e); "YÜKLENDİ" },
                             error = function(h) conditionMessage(h))
e1 <- new.env(parent = baseenv())
dene(e1)
e2 <- new.env(parent = baseenv()); e2$CONFIG <- u$CONFIG
dene(e2)

```

* [ ] Anahtarlar varken yüklemenin uyarısız olduğunu ve "21 fonksiyon; … doğrulandı" mesajı verdiğini kontrol et; `uyarilar` `character(0)` olmalı:

```r
mesajlar <- uyarilar <- character(0)
withCallingHandlers({
    e3 <- new.env(parent = globalenv())
    sys.source(config_yolu, envir = e3, toplevel.env = e3)
    sys.source(utils_yolu,  envir = e3, toplevel.env = e3)
    sys.source(api_yolu,    envir = e3, toplevel.env = e3)
  },
  message = function(m) { mesajlar <<- c(mesajlar, trimws(conditionMessage(m))); invokeRestart("muffleMessage") },
  warning = function(w) { uyarilar <<- c(uyarilar, conditionMessage(w)); invokeRestart("muffleWarning") }
)
uyarilar
grep("api_functions", mesajlar, value = TRUE)

```

* [ ] `kaynak_kullanilabilir()`'in config.R'da tanımlı olduğunu kontrol et; `TRUE` döndürmeli:

```r
sadece_config <- new.env(parent = globalenv())
suppressMessages(sys.source(config_yolu, envir = sadece_config, toplevel.env = sadece_config))
exists("kaynak_kullanilabilir", envir = sadece_config, mode = "function", inherits = FALSE)

```

* [ ] `kaynak_kullanilabilir()`'in desteklenen her kaynak için sonucunu gör; sahte anahtarlarla hepsi `TRUE` olmalı:

```r
kaynaklar <- c(u$CONFIG$kaynaklar$desteklenen, "CSV_YEDEK")
sapply(kaynaklar, u$kaynak_kullanilabilir)

```

* [ ] Anahtarlar boşken FRED ve EVDS'nin kullanılamaz sayıldığını kontrol et; FRED ve EVDS `FALSE`, diğerleri `TRUE` olmalı:

```r
Sys.setenv(FRED_API_KEY = "", EVDS_API_KEY = "")
anahtarsiz <- yukle_api()
sapply(kaynaklar, anahtarsiz$kaynak_kullanilabilir)
Sys.setenv(FRED_API_KEY = "KT_FRED", EVDS_API_KEY = "KT_EVDS")

```

* [ ] Dosyanın kullandığı config alanlarını kontrol et; hepsi `TRUE` olmalı (OECD/BIST kullanılmıyorsa ilgili URL'ler `FALSE` olabilir):

```r
cfg <- u$CONFIG
c(kullanici_araci     = !is.null(cfg$baglanti$kullanici_araci),
  zaman_asimi         = !is.null(cfg$baglanti$zaman_asimi),
  evds_base_url       = !is.null(cfg$baglanti$evds_base_url),
  oecd_base_url       = !is.null(cfg$baglanti$oecd_base_url),
  yahoo_base_url      = !is.null(cfg$baglanti$yahoo_base_url),
  baslangic_tarihi    = !is.null(cfg$veri$baslangic_tarihi),
  bitis_tarihi        = !is.null(cfg$veri$bitis_tarihi),
  desteklenen         = !is.null(cfg$kaynaklar$desteklenen),
  yedek_kaynak_kullan = !is.null(cfg$veri$yedek_kaynak_kullan),
  min_gozlem          = !is.null(cfg$veri$min_gozlem))

```

* [ ] Bitiş tarihinin bugünü kapsadığını kontrol et; `TRUE` döndürmeli (`FALSE` ise `standartlastir()` en yeni verileri keser; bilinçli değilse config'i güncelle):

```r
as.Date(cfg$veri$bitis_tarihi) >= Sys.Date()

```

* [ ] Dosyanın `library()` ile fredr, httr, jsonlite ve wbstats'ı global arama yoluna eklediğini not et; dört `TRUE` döner:

```r
paste0("package:", c("fredr", "httr", "jsonlite", "wbstats")) %in% search()

```

* [ ] Tanımsız değişken olmadığını codetools ile kontrol et; `character(0)` döndürmeli:

```r
notlar <- capture.output(codetools::checkUsageEnv(u, all = TRUE))
grep("no visible", notlar, value = TRUE)

```

## 3) Kaynak zinciri ve yükleme doğrulaması

* [ ] Her aktif göstergenin kaynak zincirini tablo olarak görüntüle:

```r
zincir_tablo <- do.call(rbind, lapply(u$aktif_gostergeler(), function(g) {
  z <- u$kaynak_zinciri(g)
  data.frame(gosterge = g, sira = seq_along(z),
             kaynak   = sapply(z, `[[`, "kaynak"),
             kod      = sapply(z, function(h) as.character(h$kod)),
             tur      = sapply(z, `[[`, "tur"),
             carpan   = sapply(z, `[[`, "carpan"),
             yaklasik = sapply(z, `[[`, "yaklasik"),
             birincil = sapply(z, `[[`, "birincil"))
}))
print(zincir_tablo, row.names = FALSE)

```

* [ ] Her zincirin ilk halkasının birincil kaynak olduğunu kontrol et; hepsi `TRUE` olmalı (`FALSE` olan göstergede birincil kaynak `oncelik` listesine yazılmamış demektir):

```r
sapply(u$aktif_gostergeler(), function(g) isTRUE(u$kaynak_zinciri(g)[[1]]$birincil))

```

* [ ] Öncelik listesinde olup zincire **girmeyen** kaynakları gör (filtresiz OECD, tür/frekans uyumsuzluğu ya da desteklenmeyen kaynak yüzünden atlananlar):

```r
sapply(u$aktif_gostergeler(), function(g)
  paste(setdiff(u$gosterge_oncelik(g), sapply(u$kaynak_zinciri(g), `[[`, "kaynak")), collapse = ", "))

```

* [ ] EVDS kodlarının sonunda `-1` gibi bir ek olmadığını kontrol et; `character(0)` döndürmeli:

```r
evds_kodlari <- unlist(lapply(u$CONFIG$gostergeler, function(k) c(
  if (identical(k$kaynak, "EVDS")) k$kod,
  if (!is.null(k$alternatifler$EVDS)) { a <- k$alternatifler$EVDS; if (is.list(a)) a$kod else a })))
grep("-\\d+$", evds_kodlari, value = TRUE)

```

* [ ] Yukarıda kod çıktıysa `evds_cek()` bu eki silmediği için istek başarısız olur (web sitesindeki `TP_TUKFIY2025_GENEL-1` gibi kodlar). Ya config'teki kodu düzelt ya da `evds_cek()` içinde `seri <- ...` satırının altına şunu ekle:

```r
  seri  <- sub("-\\d+$", "", seri)

```

* [ ] Farklı config ile yüklemeyi deneyen yardımcıyı tanımla:

```r
yukle_degisik <- function(degistir) {
  e <- new.env(parent = globalenv())
  suppressMessages({
    sys.source(config_yolu, envir = e, keep.source = FALSE, toplevel.env = e)
    sys.source(utils_yolu,  envir = e, keep.source = FALSE, toplevel.env = e)
  })
  degistir(e)
  tryCatch({ suppressMessages(sys.source(api_yolu, envir = e, keep.source = FALSE, toplevel.env = e)); "YÜKLENDİ" },
           error = function(h) conditionMessage(h))
}

```

* [ ] Birincil yedek yanlış yazılınca yüklemenin açıklayıcı hatayla durduğunu kontrol et; mesajda "birincil_yedek (YOK) uyumsuz" yazmalı:

```r
g1 <- u$aktif_gostergeler()[1]
yukle_degisik(function(e) e$CONFIG$gostergeler[[g1]]$birincil_yedek <- "YOK")

```

* [ ] **Yedek kaynaklar kapatılınca** dosyanın yüklendiğini kontrol et; `"YÜKLENDİ"` döndürmeli:

```r
yukle_degisik(function(e) e$CONFIG$veri$yedek_kaynak_kullan <- FALSE)

```

* [ ] Yukarıda "çalışabilir yedek kanal yok" hatası çıktıysa bu bir hatadır: `yedek_kaynak_kullan = FALSE` iken zincirde yalnız birincil kalır, doğrulama da bu yüzden dosyayı hiç yükletmez. Dosyanın sonundaki `local({ ... })` bloğunda `for (g in aktif_gostergeler()) {` satırını şöyle değiştir ve bu adımı tekrar çalıştır:

```r
  for (g in if (isTRUE(CONFIG$veri$yedek_kaynak_kullan)) aktif_gostergeler() else character(0)) {

```

## 4) donem_tarih_coz()

* [ ] Desteklenen biçimleri kontrol et; sırasıyla `2025-03-15`, `2025-04-01`, `2025-03-01`, `2025-03-01`, `2025-01-01` döndürmeli:

```r
u$donem_tarih_coz(c("15-03-2025", "2025-Q2", "2025-3", "2025-03", "2025"))

```

* [ ] Çeyrek başlarını kontrol et; `01-01`, `04-01`, `07-01`, `10-01` ayları dönmeli:

```r
u$donem_tarih_coz(paste0("2025-Q", 1:4))

```

* [ ] Geçersiz tarihlerin `NA` döndüğünü kontrol et; hepsi `NA` olmalı:

```r
u$donem_tarih_coz(c("31-02-2025", "2025-13", "Ocak 2025", "", NA))

```

* [ ] Desteklenmeyen biçimleri not et; ISO tarih (`2025-03-15`), yarıyıl (`2025-S1`) ve hafta (`2025-W10`) `NA` döner. Bu biçimlerde veri veren bir kaynak eklenirse fonksiyon genişletilmeli:

```r
u$donem_tarih_coz(c("2025-03-15", "2025-S1", "2025-W10"))

```

## 5) standartlastir()

* [ ] Başlangıç tarihine göre karışık bir örnek hazırla (NA tarih, sayı olmayan değer, aynı tarihte iki kayıt, aralık dışı tarih, bozuk sıra):

```r
b0 <- as.Date(u$CONFIG$veri$baslangic_tarihi)
st <- u$standartlastir(tarih  = b0 + c(40, 10, 10, -5, 20, NA),
                       deger  = c("3", "1", "2", "9", "x", "7"),
                       kimlik = "deneme")
st

```

* [ ] Sonucu kontrol et; iki satır kalmalı (`b0+10 → 2`, `b0+40 → 3`), üç `TRUE` döndürmeli:

```r
identical(st$tarih, b0 + c(10, 40))
identical(st$deger, c(2, 3))
identical(names(st), c("tarih", "deger", "kimlik"))

```

* [ ] Bitiş tarihinden sonraki kaydın atıldığını kontrol et; `0` döndürmeli:

```r
nrow(u$standartlastir(as.Date(u$CONFIG$veri$bitis_tarihi) + 1, 5, "deneme"))

```

* [ ] Aynı tarihli kayıtlarda "girdideki sonuncunun" kaldığını not et (sıralama tekilleştirmeden **sonra** yapılıyor); API'ler veriyi tarih sırasıyla verdiği sürece sorun olmaz:

```r
u$standartlastir(b0 + c(10, 10), c(1, 2), "deneme")$deger

```

## 6) wb_kod_temizle(), tur_uyumlu(), frekans_uyumlu()

* [ ] Dünya Bankası kodlarının temizlendiğini kontrol et; ikisi de `"NY.GDP.MKTP.KD.ZG"` döndürmeli:

```r
u$wb_kod_temizle("WB_WDI_NY_GDP_MKTP_KD_ZG")
u$wb_kod_temizle(" NY.GDP.MKTP.KD.ZG?source=2 ")

```

* [ ] Tür uyumunu kontrol et; sırasıyla `TRUE FALSE TRUE TRUE FALSE` döndürmeli:

```r
c(u$tur_uyumlu("duzey", "duzey"), u$tur_uyumlu("duzey", "oran"),
  u$tur_uyumlu("yillik_degisim", "duzey"), u$tur_uyumlu("yillik_degisim", "oran"),
  u$tur_uyumlu("yillik_degisim", "endeks"))

```

* [ ] Frekans uyumunu kontrol et; sırasıyla `TRUE FALSE TRUE TRUE FALSE` döndürmeli (sık kaynak seyrek hedefe uyar, tersi uymaz):

```r
c(u$frekans_uyumlu("aylik", "aylik"), u$frekans_uyumlu("aylik", "ceyreklik"),
  u$frekans_uyumlu("ceyreklik", "aylik"), u$frekans_uyumlu("yillik", "aylik"),
  u$frekans_uyumlu("aylik", "yillik"))

```

* [ ] Günlük kaynak frekansında ne olduğuna bak; `TRUE` beklenir:

```r
tryCatch(u$frekans_uyumlu("aylik", "gunluk"), error = function(e) paste("HATA:", conditionMessage(e)))

```

* [ ] "subscript out of bounds" hatası çıktıysa bu bir hatadır: bir alternatife `frekans = "gunluk"` yazılırsa `kaynak_zinciri()` ve dolayısıyla dosyanın yüklenmesi çöker (EVDS günlük faiz serisi gibi). `frekans_uyumlu()` içindeki `sira` satırını şöyle değiştir:

```r
  sira <- c(yillik = 1, ceyreklik = 2, aylik = 3, haftalik = 4, gunluk = 5)

```

## 7) frekansa_cevir()

* [ ] Günlük veriyi aylığa çevir; 3 satır, değerler **16, 45.5, 75** (ay ortalamaları) olmalı:

```r
dg <- data.frame(tarih = as.Date("2025-01-01") + 0:89, deger = 1:90, kimlik = "deneme")
fa <- u$frekansa_cevir(dg, "aylik")
fa
identical(fa$deger, c(16, 45.5, 75))

```

* [ ] Aylığı çeyreğe ve yıla çevir; ikisi de tek satır `45.5` döndürmeli:

```r
u$frekansa_cevir(dg, "ceyreklik")
u$frekansa_cevir(dg, "yillik")

```

* [ ] Kısmi dönem davranışını kontrol et: Ocak–Nisan aylık verisini çeyreğe çevir. Q2 yalnız Nisan'dan oluştuğu halde tam çeyrek gibi `100` döner. Bu değer modelde son gözlem olarak kullanılır, bu yüzden eksik dönemleri atmak gerekebileceğini not et:

```r
dm <- data.frame(tarih = seq(as.Date("2025-01-01"), by = "month", length.out = 4),
                 deger = c(10, 20, 30, 100), kimlik = "deneme")
u$frekansa_cevir(dm, "ceyreklik")

```

* [ ] Burada dönem **ortalaması** alındığını, veri hazırlama dosyasındaki `seri_hazirla()`'nın ise dönemin **son** değerini tuttuğunu not et. İkisi aynı seride art arda çalışınca ortalama geçerli olur; tutarlılık için tek bir kural seçilmeli

## 8) seri_donustur()

* [ ] İki yıllık aylık düzey serisinden yıllık değişim hesapla; 12 satır ve hepsi `10` olmalı:

```r
dy <- data.frame(tarih = seq(as.Date("2023-01-01"), by = "month", length.out = 24),
                 deger = c(rep(100, 12), rep(110, 12)), kimlik = "deneme")
r <- u$seri_donustur(dy, "yillik_degisim", "duzey")
nrow(r)
isTRUE(all.equal(r$deger, rep(10, 12)))

```

* [ ] Kaynak zaten oran ise dönüşüm yapılmadığını kontrol et; `24` döndürmeli:

```r
nrow(u$seri_donustur(dy, "yillik_degisim", "oran"))

```

* [ ] Çarpanın uygulandığını kontrol et; `TRUE` döndürmeli:

```r
identical(u$seri_donustur(dy, "duzey", "duzey", carpan = 0.01)$deger, dy$deger * 0.01)

```

* [ ] Önceki yıl değeri 0 ya da eksik olan dönemin atıldığını kontrol et; `11` ve `10` döndürmeli:

```r
dy0 <- dy; dy0$deger[3] <- 0
nrow(u$seri_donustur(dy0, "yillik_degisim", "duzey"))
nrow(u$seri_donustur(dy[-c(2, 5), ], "yillik_degisim", "duzey"))

```

* [ ] Çeyreklik seride de çalıştığını kontrol et; 4 satır, hepsi `10` olmalı:

```r
dq <- data.frame(tarih = seq(as.Date("2023-01-01"), by = "3 months", length.out = 8),
                 deger = c(rep(100, 4), rep(110, 4)), kimlik = "deneme")
u$seri_donustur(dq, "yillik_degisim", "duzey")$deger

```

## 9) Kaynak okuyucuları (sahte yanıtla, internetsiz)

* [ ] Tarih aralığını testler için genişlet ve gerçek `http_al`'ı sakla:

```r
eski_bas <- u$CONFIG$veri$baslangic_tarihi; eski_bit <- u$CONFIG$veri$bitis_tarihi
u$CONFIG$veri$baslangic_tarihi <- "2000-01-01"; u$CONFIG$veri$bitis_tarihi <- "2030-12-31"
gercek_http <- u$http_al

```

* [ ] `http_al`'ı, istenen adresi ve başlıkları kaydedip hazır bir yanıt döndüren sahtesiyle değiştir:

```r
sahte <- new.env()
u$http_al <- function(url, basliklar = NULL) {
  sahte$url <- url; sahte$basliklar <- basliklar
  as.character(sahte$govde)
}

```

* [ ] **EVDS (aylık):** yanıtı çöz; `null` değer atılmalı, 2 satır, tarihler `2024-01-01` ve `2024-02-01` olmalı:

```r
sahte$govde <- '{"totalCount":3,"items":[{"Tarih":"2024-1","TP_FG_J0":"100.5"},{"Tarih":"2024-2","TP_FG_J0":"101.2"},{"Tarih":"2024-3","TP_FG_J0":null}]}'
ev <- u$evds_cek("TP_FG_J0", "deneme")
ev

```

* [ ] **EVDS isteği:** adreste seri kodunun noktalı, tarihlerin gün-ay-yıl yazıldığını ve anahtarın başlıkta gittiğini kontrol et; üç `TRUE` döndürmeli:

```r
grepl("/series=TP.FG.J0&", sahte$url, fixed = TRUE)
grepl("startDate=01-01-2000&endDate=31-12-2030", sahte$url, fixed = TRUE)
identical(unname(sahte$basliklar$headers["key"]), u$CONFIG$baglanti$evds_key)

```

* [ ] **EVDS günlük ve çeyreklik tarihler:** `2024-01-05` ve `2024-04-01` döndürmeli:

```r
sahte$govde <- '{"items":[{"Tarih":"05-01-2024","TP_FG_J0":"1"}]}'
u$evds_cek("TP_FG_J0", "deneme")$tarih
sahte$govde <- '{"items":[{"Tarih":"2024-Q2","TP_FG_J0":"1"}]}'
u$evds_cek("TP_FG_J0", "deneme")$tarih

```

* [ ] **EVDS boş yanıt:** kalıcı hata (tekrar denenmez) verdiğini kontrol et; ilk sınıf `"kalici_hata"` olmalı:

```r
sahte$govde <- '{"totalCount":0,"items":[]}'
class(tryCatch(u$evds_cek("TP_FG_J0", "deneme"), error = function(e) e))

```

* [ ] **EVDS çözülemeyen tarih:** açıklayıcı hata verdiğini kontrol et; mesajda "tarih biçimi çözülemedi" yazmalı:

```r
sahte$govde <- '{"items":[{"Tarih":"Ocak 2024","TP_FG_J0":"1"}]}'
tryCatch(u$evds_cek("TP_FG_J0", "deneme"), error = function(e) conditionMessage(e))

```

* [ ] **OECD:** CSV yanıtı çöz ve adresi kontrol et; 2 satır ve `TRUE` döndürmeli:

```r
sahte$govde <- "TIME_PERIOD,OBS_VALUE\n2024-Q1,1.5\n2024-Q2,1.7\n"
u$oecd_cek("OECD.SDD.X,DSD@DF", "deneme", filtre = "TUR.Q.GDP")
grepl("/data/OECD.SDD.X,DSD@DF,/TUR.Q.GDP?startPeriod=2000-01", sahte$url, fixed = TRUE)

```

* [ ] **OECD hataları:** filtre yok, aynı dönem iki kez ve yanlış sütunlar kalıcı hata vermeli; üçü de `"kalici_hata"` ile başlamalı:

```r
sinif <- function(ifade) class(tryCatch(ifade, error = function(e) e))[1]
sinif(u$oecd_cek("X", "deneme"))
sahte$govde <- "TIME_PERIOD,OBS_VALUE\n2024-Q1,1.5\n2024-Q1,1.6\n"
sinif(u$oecd_cek("X", "deneme", filtre = "F"))
sahte$govde <- "A,B\n1,2\n"
sinif(u$oecd_cek("X", "deneme", filtre = "F"))

```

* [ ] **BIST (Yahoo):** İstanbul saatiyle ay başı zaman damgaları ve ayın ortasında kısmi bir çubuk içeren yanıt hazırla:

```r
ts <- as.numeric(as.POSIXct(c("2024-01-01", "2024-02-01", "2024-03-01", "2024-03-15 18:00"), tz = "Europe/Istanbul"))
sahte$govde <- jsonlite::toJSON(list(chart = list(result = list(list(
  timestamp = ts, indicators = list(quote = list(list(close = c(10, 11, 12, 12.5)))))))), digits = NA)

```

* [ ] **BIST sonucu:** tarihler UTC'ye kaymadan ay başı olmalı (`2024-01-01`, `2024-02-01`, `2024-03-01`), Mart'ta kısmi çubuğun değeri (`12.5`) kalmalı:

```r
bi <- u$bist_cek("THYAO", "deneme")
bi

```

* [ ] **BIST sembolü:** `.IS` ekinin yalnız noktasız kodlara eklendiğini kontrol et; iki `TRUE` döndürmeli:

```r
grepl("/THYAO.IS?", sahte$url, fixed = TRUE) && grepl("interval=1mo", sahte$url, fixed = TRUE)
invisible(u$bist_cek("XU100.IS", "deneme")); grepl("/XU100.IS?", sahte$url, fixed = TRUE)

```

* [ ] **Dünya Bankası:** `wb_data`'yı sahtesiyle değiştir ve çek; 10 satır, ilk tarih `2015-01-01`, gösterge kodu `"NY.GDP.MKTP.KD.ZG"` ve ülke `"TUR"` olmalı:

```r
u$wb_data <- function(indicator, country, start_date, end_date) {
  sahte$wb_arg <- list(indicator = indicator, country = country, start = start_date, end = end_date)
  d <- data.frame(date = 2015:2024); d[[indicator]] <- 1:10; d
}
wb <- u$worldbank_cek("WB_WDI_NY_GDP_MKTP_KD_ZG", "deneme")
c(nrow(wb), format(min(wb$tarih)))
unlist(sahte$wb_arg)

```

* [ ] **FRED:** `fredr`'ı sahtesiyle değiştir ve çek; `NA` atılmalı (5 satır), anahtar config'ten ayarlanmalı (`TRUE`):

```r
u$fredr_set_key <- function(key) sahte$fred_key <- key
u$fredr <- function(series_id, observation_start, observation_end, ...) {
  data.frame(date = seq(as.Date("2024-01-01"), by = "month", length.out = 6), value = c(1, 2, NA, 4, 5, 6))
}
nrow(u$fred_cek("CPIAUCSL", "deneme"))
identical(sahte$fred_key, u$CONFIG$baglanti$fred_key)

```

* [ ] FRED'de yanlış anahtar/seri hatalarının `fredr`'dan sıradan hata olarak geldiğini, bu yüzden kalıcı sayılmayıp `yeniden_deneme` kez (bekleyerek) tekrar denendiğini not et

* [ ] **cek_kaynak():** bilinmeyen kaynakta ve CSV yedeği yokken açıklayıcı hata verdiğini kontrol et; "tercümanı yok" ve `"kalici_hata"` dönmeli:

```r
tryCatch(u$cek_kaynak("BILINMEYEN", "X", "deneme"), error = function(e) conditionMessage(e))
sinif(u$cek_kaynak("CSV_YEDEK", NA, "olmayan_gosterge"))

```

* [ ] Sahteleri kaldır ve ayarları geri yükle:

```r
u$http_al <- gercek_http
rm(list = c("wb_data", "fredr", "fredr_set_key"), envir = u)
u$CONFIG$veri$baslangic_tarihi <- eski_bas; u$CONFIG$veri$bitis_tarihi <- eski_bit

```

## 10) http_al()

* [ ] Erişilemeyen adreste "Bağlantı hatası" ile durduğunu kontrol et (internet olmadan da çalışır):

```r
tryCatch(u$http_al("https://kt-test.invalid"), error = function(e) conditionMessage(e))

```

* [ ] Kodda 400/401/403/404'ün kalıcı hata (tekrar denenmez), 429 ve 5xx'in geçici hata (tekrar denenir) sayıldığını not et; canlı kontrolü 14. bölümde

## 11) fetch_indicator() — kanal senaryoları (sahte kaynakla)

* [ ] Gerçek `cek_kaynak`'ı sakla ve davranışı ayarlanabilen sahtesini kur. Her kaynak `"ok"`, `"gecici"`, `"kalici"` ya da `"kisa"` davranabilir; `CSV_YEDEK` gerçek dosyadan okunur:

```r
gercek_cek <- u$cek_kaynak
u$cek_kaynak <- function(kaynak, kod, kimlik, filtre = NULL) {
  sahte$cagrilar <- c(sahte$cagrilar, kaynak)
  if (kaynak == "CSV_YEDEK") return(gercek_cek(kaynak, kod, kimlik, filtre))
  if (kimlik %in% sahte$bozuk) u$kalici_hata("sahte: gösterge bozuk")
  dav <- u$varsayilan(sahte$davranis[[kaynak]], "ok")
  if (dav == "gecici") stop("sahte geçici hata")
  if (dav == "kalici") u$kalici_hata("sahte kalıcı hata")
  n <- if (dav == "kisa") 3 else 360
  data.frame(tarih = seq(as.Date("1996-01-01"), by = "month", length.out = n),
             deger = round(100 + cumsum(abs(rnorm(n))), 2), kimlik = kimlik)
}
sifirla <- function() { sahte$davranis <- list(); sahte$bozuk <- character(0); sahte$cagrilar <- character(0) }

```

* [ ] Test göstergesini ve zincirini belirle:

```r
set.seed(7)
ga <- u$aktif_gostergeler()[1]
birincil <- u$CONFIG$gostergeler[[ga]]$kaynak
zincir_ga <- sapply(u$kaynak_zinciri(ga), `[[`, "kaynak")
cache_ga <- file.path(gecici, "cache", paste0(ga, ".rds"))
csv_ga   <- file.path(gecici, "yedek", paste0(ga, ".csv"))
c(gosterge = ga, birincil = birincil); zincir_ga

```

* [ ] **Tanımsız ve pasif gösterge:** `NULL` döndürmeli, logda "Tanımsız gösterge" / "Pasif gösterge" yazmalı:

```r
u$fetch_indicator("yok_boyle")
pasifler <- setdiff(names(u$CONFIG$gostergeler), u$aktif_gostergeler())
if (length(pasifler)) u$fetch_indicator(pasifler[1])

```

* [ ] **Birincil çalışıyor:** yalnız birincil çağrılmalı; meta `kaynak = birincil`, `birincil = TRUE`, `durum = "api"` olmalı; cache ve CSV yedek yazılmalı:

```r
sifirla()
vB <- u$fetch_indicator(ga, yenile = TRUE)
sahte$cagrilar
attr(vB, "meta")[c("kaynak", "birincil", "durum", "frekans", "donusum")]
file.exists(c(cache_ga, csv_ga))

```

* [ ] Çıktının göstergenin frekansında olduğunu ve en az `min_gozlem` satır içerdiğini kontrol et; iki `TRUE` döndürmeli:

```r
identical(vB$tarih, u$donem_basi(vB$tarih, u$gosterge_frekansi(ga)))
nrow(vB) >= u$varsayilan(u$CONFIG$veri$min_gozlem, 8)

```

* [ ] **Taze cache:** kaynağa gitmeden cache'ten geldiğini kontrol et; `character(0)` ve `"cache"` döndürmeli:

```r
sifirla()
vC <- u$fetch_indicator(ga)
sahte$cagrilar
attr(vC, "meta")$durum

```

* [ ] **Config'te kod değişince** cache'in geçersiz sayıldığını kontrol et; birincil yeniden çağrılmalı:

```r
eski_kod <- u$CONFIG$gostergeler[[ga]]$kod
u$CONFIG$gostergeler[[ga]]$kod <- paste0(eski_kod, "_X")
sifirla(); invisible(u$fetch_indicator(ga)); sahte$cagrilar
u$CONFIG$gostergeler[[ga]]$kod <- eski_kod
invisible(u$fetch_indicator(ga, yenile = TRUE))

```

* [ ] **Birincil geçici hata:** birincil `yeniden_deneme` kez denenip zincirin 2. halkasına geçmeli; meta `birincil = FALSE` olmalı ve logda "YEDEK KAYNAK kullanıldı" yazmalı:

```r
sifirla(); sahte$davranis[[birincil]] <- "gecici"
vE <- u$fetch_indicator(ga, yenile = TRUE)
table(sahte$cagrilar)
u$CONFIG$baglanti$yeniden_deneme
attr(vE, "meta")[c("kaynak", "birincil")]
attr(vE, "meta")$kaynak == zincir_ga[2]

```

* [ ] **Birincil kalıcı hata:** birincil yalnız **1** kez denenmeli:

```r
sifirla(); sahte$davranis[[birincil]] <- "kalici"
invisible(u$fetch_indicator(ga, yenile = TRUE))
table(sahte$cagrilar)

```

* [ ] **Birincil yetersiz gözlem:** logda "yetersiz gözlem (3)" yazmalı ve sonraki halkaya geçilmeli:

```r
sifirla(); sahte$davranis[[birincil]] <- "kisa"
attr(u$fetch_indicator(ga, yenile = TRUE), "meta")$kaynak

```

* [ ] **Birincilin anahtarı yok:** birincil hiç çağrılmamalı, logda "atlandı (anahtar yok)" yazmalı:

```r
gercek_kk <- u$kaynak_kullanilabilir
u$kaynak_kullanilabilir <- function(k) !identical(k, birincil)
sifirla(); invisible(u$fetch_indicator(ga, yenile = TRUE))
birincil %in% sahte$cagrilar
u$kaynak_kullanilabilir <- gercek_kk

```

* [ ] Birincilden taze veri çek (sonraki senaryolar için cache ve CSV birincilden gelsin):

```r
sifirla(); invisible(u$fetch_indicator(ga, yenile = TRUE))

```

* [ ] **Tüm API kaynakları başarısız, CSV yedek var:** zincirde `CSV_YEDEK` varsa `"csv_yedek"`, yoksa `"bayat_cache"` dönmeli. Her API kaynağı 1 kez (kalıcı hata) denenmeli:

```r
api_h <- setdiff(zincir_ga, "CSV_YEDEK")
sifirla(); sahte$davranis <- setNames(as.list(rep("kalici", length(api_h))), api_h)
vG <- u$fetch_indicator(ga, yenile = TRUE)
"CSV_YEDEK" %in% zincir_ga
attr(vG, "meta")$durum
table(sahte$cagrilar)

```

* [ ] **Tüm kanallar başarısız, yalnız cache var:** `"bayat_cache"` dönmeli, logda "BAYAT cache" yazmalı:

```r
unlink(csv_ga)
attr(u$fetch_indicator(ga, yenile = TRUE), "meta")$durum

```

* [ ] **Hiçbir şey yok:** `NULL` dönmeli, logda "Gösterge alınamadı" (HATA) yazmalı:

```r
unlink(cache_ga)
is.null(u$fetch_indicator(ga, yenile = TRUE))

```

* [ ] Bayat cache kullanılırken dönüşüm/frekans uyumunun (taze cache'teki gibi) kontrol **edilmediğini** not et. Config'te `donusum` ya da `frekans` değiştirildikten sonra tüm kanallar düşerse eski tanımlı veri gelebilir

* [ ] Normal davranışa dön:

```r
sifirla(); invisible(u$fetch_indicator(ga, yenile = TRUE))

```

## 12) meta_ekle(), metaveri_olustur(), veri_tazeligi()

* [ ] `meta_ekle()`'nin 10 alanlı meta eklediğini kontrol et:

```r
names(attr(vB, "meta"))

```

* [ ] Başarılı ve başarısız gösterge için metaveri üret; `ga` satırında `durum = "api"`, ikinci satırda `durum = "alinamadi"` ve `gozlem = 0` olmalı:

```r
gb <- if (length(u$aktif_gostergeler()) > 1) u$aktif_gostergeler()[2] else ga
mv <- u$metaveri_olustur(setNames(list(vB, NULL), c(ga, gb)))
mv[, c("gosterge", "kaynak", "durum", "yedek_kullanildi", "gozlem", "ilk_tarih", "son_tarih")]

```

* [ ] Kartında `ad` alanı olmayan göstergede ne olduğuna bak; `"TAMAM"` beklenir:

```r
kart_yedek <- u$CONFIG$gostergeler[[ga]]
u$CONFIG$gostergeler[[ga]]$ad <- NULL
tryCatch({ u$metaveri_olustur(setNames(list(vB), ga)); "TAMAM" }, error = function(e) conditionMessage(e))
u$CONFIG$gostergeler[[ga]] <- kart_yedek

```

* [ ] Metası eksik (eski sürümden kalma bayat cache) veride ne olduğuna bak; `"TAMAM"` beklenir:

```r
v_eski <- vB; attr(v_eski, "meta") <- list(kaynak = NA, kod = NA, birincil = NA, durum = "bayat_cache")
tryCatch({ u$metaveri_olustur(setNames(list(v_eski), ga)); "TAMAM" }, error = function(e) conditionMessage(e))

```

* [ ] Son iki adımda "differing number of rows" gibi bir hata çıktıysa `metaveri_olustur()` eksik alanlarda çöküyor demektir. Bu durumda tüm çekim durur. `metaveri_olustur()` içinde şu satırları değiştir:

```r
      gosterge = ad, ad = varsayilan(kart$ad, ad), rol = varsayilan(kart$rol, NA), frekans = gosterge_frekansi(ad),

```

```r
      birincil_kaynak = varsayilan(kart$kaynak, NA),

```

```r
      cekim_zamani = if (is.null(m) || is.null(m$cekim_zamani)) as.POSIXct(NA) else as.POSIXct(m$cekim_zamani),

```

* [ ] `veri_tazeligi()`'ni kontrol et; son tarih ve `NA` döndürmeli:

```r
u$veri_tazeligi(vB, ga)
u$veri_tazeligi(vB, "yok_boyle")

```

## 13) tum_gostergeleri_cek()

* [ ] Tüm aktif göstergeleri çek; her gösterge uzun tabloda yer almalı, `metaveri` niteliği ve dosyası oluşmalı:

```r
sifirla()
uzun <- u$tum_gostergeleri_cek(yenile = TRUE)
names(uzun)
table(uzun$kimlik)
setequal(unique(uzun$kimlik), u$aktif_gostergeler())
file.exists(file.path(gecici, "processed", c("metaveri.rds", "metaveri.csv")))

```

* [ ] Uzun tabloda meta niteliği kalmadığını ve metaverinin tam olduğunu kontrol et; `NULL` ve `TRUE` döndürmeli:

```r
attr(uzun, "meta")
nrow(attr(uzun, "metaveri")) == length(u$aktif_gostergeler())

```

* [ ] Bir gösterge tamamen alınamayınca diğerlerinin etkilenmediğini kontrol et; `ga` uzun tabloda olmamalı, metaveride `durum = "alinamadi"` olmalı, logda "Çekim tamamlandı: n-1/n" yazmalı:

```r
unlink(c(cache_ga, csv_ga))
sifirla(); sahte$bozuk <- ga
uzun2 <- u$tum_gostergeleri_cek(yenile = TRUE)
ga %in% uzun2$kimlik
attr(uzun2, "metaveri")[attr(uzun2, "metaveri")$gosterge == ga, c("durum", "gozlem")]

```

* [ ] Hiçbir gösterge alınamazsa `NULL` döndürdüğünü ama metaveriyi yine de kaydettiğini kontrol et; `TRUE` ve `"alinamadi"` döndürmeli:

```r
unlink(file.path(gecici, c("cache", "yedek")), recursive = TRUE)
sifirla(); sahte$bozuk <- u$aktif_gostergeler()
is.null(u$tum_gostergeleri_cek(yenile = TRUE))
unique(readRDS(file.path(gecici, "processed", "metaveri.rds"))$durum)

```

* [ ] Gerçek `cek_kaynak`'ı geri yükle:

```r
sifirla()
u$cek_kaynak <- gercek_cek

```

## 14) Canlı test (isteğe bağlı: internet ve gerçek anahtar gerekir)

* [ ] Gerçek anahtarların tanımlı olduğunu kontrol et; iki `TRUE` döndürmeli (değilse bu bölümü atla):

```r
c(FRED = nzchar(eski_fred), EVDS = nzchar(eski_evds))

```

* [ ] Gerçek anahtarlarla ayrı bir ortam yükle ve dosyaları geçici klasöre yönlendir:

```r
Sys.setenv(FRED_API_KEY = eski_fred, EVDS_API_KEY = eski_evds)
canli <- yukle_api()
canli$CONFIG$saklama[c("processed_klasoru", "cache_klasoru", "yedek_klasoru", "log_klasoru")] <-
  as.list(file.path(gecici, "canli", c("processed", "cache", "yedek", "logs")))

```

* [ ] HTTP durum kodlarının doğru sınıflandığını kontrol et; ilki `"kalici_hata"`, ikincisi `"simpleError"` ile başlamalı (httpbin.org erişilemezse atla):

```r
class(tryCatch(canli$http_al("https://httpbin.org/status/404"), error = function(e) e))[1]
class(tryCatch(canli$http_al("https://httpbin.org/status/503"), error = function(e) e))[1]

```

* [ ] Her göstergenin zincirindeki her API kaynağını tek tek dene ve sonuç tablosunu incele. Birincillerin hepsi `"tamam"` olmalı, son tarihler güncel görünmeli:

```r
canli_tablo <- do.call(rbind, lapply(canli$aktif_gostergeler(), function(g) {
  do.call(rbind, lapply(Filter(function(h) h$kaynak != "CSV_YEDEK", canli$kaynak_zinciri(g)), function(h) {
    t0 <- Sys.time()
    r <- tryCatch(canli$cek_kaynak(h$kaynak, h$kod, g, h$filtre), error = function(e) e)
    tamam <- !inherits(r, "error") && nrow(r) > 0
    data.frame(gosterge = g, kaynak = h$kaynak, birincil = h$birincil,
               durum  = if (inherits(r, "error")) substr(conditionMessage(r), 1, 50) else if (tamam) "tamam" else "boş",
               gozlem = if (tamam) nrow(r) else NA,
               ilk    = if (tamam) format(min(r$tarih)) else NA,
               son    = if (tamam) format(max(r$tarih)) else NA,
               sure_sn = round(as.numeric(difftime(Sys.time(), t0, units = "secs")), 1))
  }))
}))
print(canli_tablo, row.names = FALSE)

```

* [ ] Tüm akışı gerçek kaynaklarla çalıştır ve metaveriyi incele; `durum` hepsi `"api"`, `yedek_kullanildi` hepsi `FALSE` olmalı:

```r
canli_uzun <- canli$tum_gostergeleri_cek(yenile = TRUE)
attr(canli_uzun, "metaveri")[, c("gosterge", "kaynak", "durum", "yedek_kullanildi", "gozlem", "son_tarih")]

```

* [ ] BIST göstergesi varsa son tarihin içinde bulunulan ay olduğunu ve değerin ayın kısmi (henüz kapanmamış) çubuğu olduğunu not et

* [ ] Sahte anahtarlara geri dön:

```r
Sys.setenv(FRED_API_KEY = "KT_FRED", EVDS_API_KEY = "KT_EVDS")

```

## 15) Hız

* [ ] Dosyanın yükleme süresini ölç (ms, config + utils dahil); zincir doğrulaması ağa çıkmadığı için 1 saniyenin altında olmalı:

```r
summary(replicate(10, system.time(yukle_api())[["elapsed"]] * 1000))

```

* [ ] Sahte kaynakla bir göstergenin çekim + dönüştürme süresini ölç (ms):

```r
u$cek_kaynak <- function(kaynak, kod, kimlik, filtre = NULL)
  data.frame(tarih = seq(as.Date("1996-01-01"), by = "month", length.out = 360), deger = 100 + 1:360, kimlik = kimlik)
system.time(invisible(capture.output(u$fetch_indicator(ga, yenile = TRUE))))[["elapsed"]] * 1000
u$cek_kaynak <- gercek_cek

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
  "config_yolu", "utils_yolu", "api_yolu", "eski_fred", "eski_evds", "yukle_api", "u", "gecici", "satirlar",
  "ifadeler", "tanimlar", "ham_bayt", "metin", "dene", "e1", "e2", "e3", "mesajlar", "uyarilar",
  "sadece_config", "kaynaklar", "anahtarsiz", "cfg", "notlar", "zincir_tablo", "evds_kodlari",
  "yukle_degisik", "g1", "b0", "st", "dg", "fa", "dm", "dy", "r", "dy0", "dq", "eski_bas", "eski_bit",
  "gercek_http", "sahte", "ev", "sinif", "ts", "bi", "wb", "gercek_cek", "sifirla", "ga", "birincil",
  "zincir_ga", "cache_ga", "csv_ga", "pasifler", "vB", "vC", "eski_kod", "vE", "gercek_kk", "api_h", "vG",
  "gb", "mv", "kart_yedek", "v_eski", "uzun", "uzun2", "canli", "canli_tablo", "canli_uzun"
)))

```

* [ ] Sağ üstteki "Environment" sekmesinde test nesnelerinin kalmadığını kontrol et
* [ ] Başarısız olan adımları not al ve api_functions.R'ı düzelttikten sonra ilgili bölümü tekrar çalıştıra