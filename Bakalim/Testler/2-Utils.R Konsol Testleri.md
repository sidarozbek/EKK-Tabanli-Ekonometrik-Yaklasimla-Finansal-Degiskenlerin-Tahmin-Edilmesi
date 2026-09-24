## Hazırlık

* [ ] RStudio'da projeyi aç ve Console'da proje kökünde olduğunu kontrol et; iki satır da `TRUE` döndürmeli:
  
  ```r
getwd()
file.exists("R/config.R")
file.exists("R/utils.R")

```

* [ ] Dosyaların tam yollarını değişkenlere yaz:
  
  ```r
config_yolu <- normalizePath("R/config.R", winslash = "/")
utils_yolu  <- normalizePath("R/utils.R", winslash = "/")

```

* [ ] Gerçek API anahtarlarını sakla ve testler için sahte anahtar tanımla:
  
  ```r
eski_fred <- Sys.getenv("FRED_API_KEY")
eski_evds <- Sys.getenv("EVDS_API_KEY")
Sys.setenv(FRED_API_KEY = "KT_FRED", EVDS_API_KEY = "KT_EVDS")

```

* [ ] config.R + utils.R'ı temiz bir ortamda yükleyen yardımcı fonksiyonu tanımla (global ortamı kirletmez):

```r
yukle_utils <- function() {
  e <- new.env(parent = globalenv())
  suppressMessages({
    sys.source(config_yolu, envir = e, keep.source = FALSE, toplevel.env = e)
    sys.source(utils_yolu,  envir = e, keep.source = FALSE, toplevel.env = e)
  })
  e
}

```

* [ ] Test ortamını yükle; araçlara bundan sonra `u$arac_adi()` şeklinde ulaşılacak:

```r
u <- yukle_utils()

```

* [ ] Dosya yazan araçların projedeki gerçek `data/` ve `logs/` klasörlerine dokunmaması için test ortamındaki klasörleri geçici bir klasöre yönlendir:

```r
gecici <- file.path(tempdir(), "utils_test")
u$CONFIG$saklama$cache_klasoru     <- file.path(gecici, "cache")
u$CONFIG$saklama$yedek_klasoru     <- file.path(gecici, "yedek")
u$CONFIG$saklama$processed_klasoru <- file.path(gecici, "processed")
u$CONFIG$saklama$log_klasoru       <- file.path(gecici, "logs")

```

* [ ] Dosyanın satırlarını oku:

```r
satirlar <- readLines(utils_yolu, encoding = "UTF-8", warn = FALSE)

```

## 1) Sözdizimi

* [ ] Dosyayı çalıştırmadan sözdizimi hatası olup olmadığını kontrol et; hata çıkmamalı:

```r
ifadeler <- parse(utils_yolu, encoding = "UTF-8")
length(ifadeler)
length(satirlar)

```

* [ ] Dosyada kaç fonksiyon tanımlandığını say; **27** döndürmeli (`frekans_ayari` hariç, o config.R'dan gelir):
  
  ```r
tanimlar <- Filter(function(e) is.call(e) && identical(e[[1]], as.name("<-")) &&
                     is.call(e[[3]]) && identical(e[[3]][[1]], as.name("function")), ifadeler)
length(tanimlar)
sapply(tanimlar, function(e) as.character(e[[2]]))

```

## 2) Karakter kodlaması

* [ ] BOM olmadığını (`FALSE`) ve dosyanın geçerli UTF-8 olduğunu (`TRUE`) kontrol et:
  
  ```r
ham <- readBin(utils_yolu, "raw", file.info(utils_yolu)$size)
identical(ham[1:3], as.raw(c(0xEF, 0xBB, 0xBF)))
metin <- rawToChar(ham)
Encoding(metin) <- "UTF-8"
validUTF8(metin)

```

* [ ] Türkçe harflerin yalnız metin ve yorumlarda geçtiğini kontrol et; `integer(0)` döndürmeli:
  
  ```r
kod_kismi <- gsub('"[^"]*"|#.*$', "", satirlar)
which(grepl("[çğıöşüÇĞİÖŞÜ]", kod_kismi))

```

* [ ] Ay adlarının (Şubat, Ağustos…) bozulmadan okunduğunu gözle kontrol et:
  
  ```r
grep("Şubat|Ağustos|Aralık", satirlar, value = TRUE)

```

## 3) Biçim ve parantez dengesi

> Biçim bulguları uyarıdır, testi düşürmez. Her komutun `integer(0)` döndürmesi idealdir.

* [ ] Sekme, satır sonu boşluğu ve 120 karakterden uzun satır olmadığını kontrol et:
  
  ```r
grep("\t", satirlar)
grep("[ \t]+$", satirlar)
which(nchar(satirlar, type = "width") > 120)

```

* [ ] `T`/`F` kısaltması ve `=` ile üst düzey atama olmadığını kontrol et:
  
  ```r
kod2 <- sub("#.*$", "", gsub('"[^"]*"', '""', satirlar))
grep("(^|[^A-Za-z0-9_.$])(T|F)([^A-Za-z0-9_.(]|$)", kod2)
grep("^[A-Za-z_.][A-Za-z0-9_.]*\\s*=[^=]", kod2)

```

* [ ] `<<-` kullanılan satırları listele; yalnızca `tekrar_dene` içindeki `son_hata <<- e` satırı çıkmalı (orada bilinçli kullanılmış):
  
  ```r
grep("<<-", kod2, value = TRUE)

```

* [ ] Parantezlerin dengeli olduğunu kontrol et; "son" değerleri **0**, "en düşük" değerleri **0'dan küçük olmamalı**:

```r
temiz <- sub("#.*$", "", gsub('"([^"\\\\]|\\\\.)*"', '""', satirlar))
say <- function(ch) lengths(regmatches(temiz, gregexpr(ch, temiz, fixed = TRUE)))
for (p in list(c("(", ")"), c("{", "}"), c("[", "]"))) {
  fark <- cumsum(say(p[1]) - say(p[2]))
  cat(p[1], p[2], "| son:", tail(fark, 1), "| en düşük:", min(fark), "\n")
}

```

## 4) config.R bağımlılığı

* [ ] CONFIG yokken utils.R'ın açıklayıcı bir hatayla durduğunu kontrol et; mesajda "Önce config.R yükle" yazmalı:

```r
bos <- new.env(parent = baseenv())
tryCatch(sys.source(utils_yolu, envir = bos, toplevel.env = bos),
         error = function(e) conditionMessage(e))

```

* [ ] Yalnız config.R'ı yükle ve `frekans_ayari`'nın **config.R'da** tanımlı olduğunu kontrol et; `TRUE` döndürmeli (FALSE ise utils.R "Eksik araç: frekans_ayari" hatası verir):

```r
sadece_config <- new.env(parent = globalenv())
suppressMessages(sys.source(config_yolu, envir = sadece_config, toplevel.env = sadece_config))
exists("frekans_ayari", envir = sadece_config, mode = "function", inherits = FALSE)

```

* [ ] utils.R'ın kullandığı CONFIG alanlarının config.R'da var olduğunu kontrol et; hepsi `TRUE` olmalı (`FALSE` olan alan için araç varsayılan değere düşer):

```r
cfg <- sadece_config$CONFIG
c(cache_klasoru          = !is.null(cfg$saklama$cache_klasoru),
  yedek_klasoru          = !is.null(cfg$saklama$yedek_klasoru),
  processed_klasoru      = !is.null(cfg$saklama$processed_klasoru),
  log_klasoru            = !is.null(cfg$saklama$log_klasoru),
  egitim_orani           = !is.null(cfg$model$egitim_orani),
  yeniden_deneme         = !is.null(cfg$baglanti$yeniden_deneme),
  yeniden_deneme_bekleme = !is.null(cfg$baglanti$yeniden_deneme_bekleme),
  frekanslar             = !is.null(cfg$frekanslar),
  gostergeler            = !is.null(cfg$gostergeler))

```

* [ ] `log_klasoru` `FALSE` çıktıysa log dosyası çalışma dizinine göre `logs/` klasörüne yazılır; `shiny::runApp("app")` ile açıldığında `app/logs/` oluşacağını not et

## 5) Yükleme

* [ ] config.R + utils.R'ı yükle, mesaj ve uyarıları yakala; `uyarilar` `character(0)` olmalı, mesajlarda **"28 araç yerinde"** geçmeli:

```r
mesajlar <- uyarilar <- character(0)
withCallingHandlers({
    e2 <- new.env(parent = globalenv())
    sys.source(config_yolu, envir = e2, toplevel.env = e2)
    sys.source(utils_yolu,  envir = e2, toplevel.env = e2)
  },
  message = function(m) { mesajlar <<- c(mesajlar, trimws(conditionMessage(m))); invokeRestart("muffleMessage") },
  warning = function(w) { uyarilar <<- c(uyarilar, conditionMessage(w)); invokeRestart("muffleWarning") }
)
uyarilar
grep("utils.R", mesajlar, value = TRUE)

```

* [ ] utils.R'ın eklediği nesneleri listele; **27** tane olmalı ve hepsi fonksiyon olmalı:

```r
yeni <- setdiff(ls(u, all.names = TRUE), ls(sadece_config, all.names = TRUE))
length(yeni)
all(sapply(yeni, function(n) is.function(get(n, envir = u))))

```

* [ ] Kontrol listesinde olmayan (sonradan eklenip listeye yazılmamış) fonksiyon olmadığını kontrol et; `character(0)` döndürmeli:

```r
araclar <- c("varsayilan", "klasor_hazirla", "log_msg", "dosya_yasi_gun", "cache_yaz", "cache_oku",
             "yedek_csv_yaz", "yedek_csv_oku", "ikili_kaydet", "processed_oku", "tarihe_gore_bol",
             "formul_kur", "yeni_olanlar", "kalici_hata", "tekrar_dene", "frekans_ayari",
             "donem_basi", "donem_dizisi", "donem_ekle", "donem_etiketi", "aktif_gostergeler",
             "gosterge_etiketi", "gosterge_frekansi", "gosterge_oncelik", "gosterge_p",
             "gosterge_pencere", "gosterge_ufuk", "gosterge_pencere_adaylari")
setdiff(yeni, araclar)

```

* [ ] Yüklemenin çalışma dizinini değiştirmediğini kontrol et; `TRUE` döndürmeli:

```r
wd_once <- getwd()
invisible(yukle_utils())
identical(getwd(), wd_once)

```

* [ ] `klasor_hazirla()`'nın yükleme sırasında CONFIG'teki tüm `…_klasoru` yollarını oluşturduğunu kontrol et; hepsi `TRUE` olmalı:

```r
yollar <- unlist(cfg$saklama[grep("klasoru$", names(cfg$saklama))])
dir.exists(yollar)

```

## 6) Tanımsız değişken (codetools)

* [ ] Tüm fonksiyonları codetools ile tara; `character(0)` döndürmesi idealdir:

```r
notlar <- capture.output(codetools::checkUsageEnv(u, all = TRUE, suppressLocalUnused = FALSE))
notlar

```

* [ ] Özellikle tanımsız değişken ("no visible") uyarısı olmadığını kontrol et; `character(0)` döndürmeli:

```r
grep("no visible", notlar, value = TRUE)

```

## 7) varsayilan()

* [ ] Boş değerlerde yedeğe düştüğünü kontrol et; hepsi `"yedek"` döndürmeli:

```r
u$varsayilan(NULL, "yedek")
u$varsayilan(NA, "yedek")
u$varsayilan(c(NA, NA), "yedek")
u$varsayilan(character(0), "yedek")

```

* [ ] Dolu değerlere dokunmadığını kontrol et; sırasıyla `0`, `FALSE`, `""`, `1 NA` döndürmeli:

```r
u$varsayilan(0, "yedek")
u$varsayilan(FALSE, "yedek")
u$varsayilan("", "yedek")
u$varsayilan(c(1, NA), "yedek")

```

## 8) log_msg()

* [ ] Mesajın ekrana ve log dosyasına yazıldığını kontrol et; son satır `[yyyy-aa-gg ss:dd:ss] [BILGI] test mesajı` biçiminde olmalı:

```r
u$log_msg("test mesajı")
log_dosyasi <- file.path(gecici, "logs", "calisma.log")
file.exists(log_dosyasi)
tail(readLines(log_dosyasi, encoding = "UTF-8"), 1)

```

* [ ] Biçimi ve seviye parametresini kontrol et; ikisi de `TRUE` döndürmeli:

```r
u$log_msg("uyarı denemesi", "UYARI")
son <- tail(readLines(log_dosyasi, encoding = "UTF-8"), 2)
grepl("^\\[\\d{4}-\\d{2}-\\d{2} \\d{2}:\\d{2}:\\d{2}\\] \\[BILGI\\] test mesajı", son[1])
grepl("[UYARI] uyarı denemesi", son[2], fixed = TRUE)

```

* [ ] Her çağrının dosyaya yeni satır eklediğini (üzerine yazmadığını) kontrol et; `TRUE` döndürmeli:

```r
once <- length(readLines(log_dosyasi))
u$log_msg("bir satır daha")
length(readLines(log_dosyasi)) == once + 1

```

## 9) dosya_yasi_gun()

* [ ] Olmayan dosya için `Inf` döndürdüğünü kontrol et:

```r
u$dosya_yasi_gun(file.path(gecici, "olmayan.txt"))

```

* [ ] Yeni oluşturulan dosyanın yaşının ~0, tarihi 3 gün geri alınan dosyanın ~3 gün olduğunu kontrol et:

```r
deneme_dosyasi <- file.path(gecici, "yas.txt")
writeLines("x", deneme_dosyasi)
round(u$dosya_yasi_gun(deneme_dosyasi), 2)
Sys.setFileTime(deneme_dosyasi, Sys.time() - 3 * 86400)
round(u$dosya_yasi_gun(deneme_dosyasi), 2)

```

## 10) cache_yaz() / cache_oku()

* [ ] Deneme verisi oluştur ve cache'e yaz; okunan veri yazılanla birebir aynı olmalı (`TRUE`):

```r
veri <- data.frame(tarih = as.Date("2026-01-01") + 0:9, deger = 1:10)
u$cache_yaz(veri, "deneme")
cache_dosyasi <- file.path(gecici, "cache", "deneme.rds")
file.exists(cache_dosyasi)
identical(u$cache_oku("deneme"), veri)

```

* [ ] Tazelik süresini kontrol et: dosyayı 5 gün eskit; 1 günlük tazelikte `TRUE` (NULL döndü), 10 günlükte `TRUE` (veri döndü) olmalı:

```r
Sys.setFileTime(cache_dosyasi, Sys.time() - 5 * 86400)
is.null(u$cache_oku("deneme", tazelik_gun = 1))
identical(u$cache_oku("deneme", tazelik_gun = 10), veri)

```

* [ ] Olmayan ve bozuk cache dosyasında hata vermeden `NULL` döndürdüğünü kontrol et; ikisi de `TRUE` olmalı:

```r
is.null(u$cache_oku("olmayan"))
writeLines("bozuk", cache_dosyasi)
is.null(u$cache_oku("deneme"))

```

## 11) yedek_csv_yaz() / yedek_csv_oku()

* [ ] Fazla sütunlu veriyi yedekle; CSV'de yalnız `tarih` ve `deger` sütunları olmalı:

```r
u$yedek_csv_yaz(transform(veri, fazla = "x"), "deneme")
names(read.csv(file.path(gecici, "yedek", "deneme.csv")))

```

* [ ] Yedeği geri oku; tarih `Date`, deger `numeric` olmalı ve `kimlik` sütunu `"deneme"` içermeli:

```r
y <- u$yedek_csv_oku("deneme")
str(y)
identical(y$tarih, veri$tarih)
all.equal(y$deger, as.numeric(veri$deger))
unique(y$kimlik)

```

* [ ] Olmayan, boş ve yanlış sütunlu CSV'lerde `NULL` döndürdüğünü kontrol et; üçü de `TRUE` olmalı:

```r
is.null(u$yedek_csv_oku("olmayan"))
writeLines("tarih,deger", file.path(gecici, "yedek", "bos.csv"))
is.null(u$yedek_csv_oku("bos"))
write.csv(data.frame(a = 1), file.path(gecici, "yedek", "yanlis.csv"), row.names = FALSE)
is.null(u$yedek_csv_oku("yanlis"))

```

* [ ] `tarih`/`deger` sütunu olmayan veriyle yazmaya çalışınca hata vermediğini ve dosya oluşturmadığını kontrol et; `FALSE` döndürmeli:

```r
u$yedek_csv_yaz(data.frame(a = 1), "eksik")
file.exists(file.path(gecici, "yedek", "eksik.csv"))

```

## 12) ikili_kaydet() / processed_oku()

* [ ] Verinin hem `.rds` hem `.csv` olarak kaydedildiğini kontrol et; iki `TRUE` döndürmeli:

```r
u$ikili_kaydet(veri, "deneme")
file.exists(file.path(gecici, "processed", c("deneme.rds", "deneme.csv")))

```

* [ ] Okunan verinin aynı olduğunu (`TRUE`) ve olmayan dosyada `NULL` döndüğünü (`TRUE`) kontrol et:

```r
identical(u$processed_oku("deneme"), veri)
is.null(u$processed_oku("olmayan"))

```

## 13) tarihe_gore_bol()

* [ ] 100 satırlık deneme verisi oluştur ve config'teki eğitim oranını not et:

```r
d <- data.frame(tarih = as.Date("2020-01-01") + 0:99, deger = 1:100)
u$CONFIG$model$egitim_orani

```

* [ ] Varsayılan oranla böl; eğitim `floor(100 × oran)`, sınama kalan satır sayısı olmalı:

```r
b <- u$tarihe_gore_bol(d)
c(egitim = nrow(b$egitim), sinama = nrow(b$sinama))

```

* [ ] Bölmenin zamana göre yapıldığını ve satır kaybı olmadığını kontrol et; ikisi de `TRUE` olmalı:

```r
max(b$egitim$tarih) < min(b$sinama$tarih)
identical(rbind(b$egitim, b$sinama), d)

```

* [ ] Oran parametresinin çalıştığını kontrol et; `50 50` döndürmeli:

```r
b2 <- u$tarihe_gore_bol(d, 0.5)
c(nrow(b2$egitim), nrow(b2$sinama))

```

* [ ] Uç durum: oran 1 iken sınama kümesinin **0 satır** olduğunu kontrol et:

```r
b3 <- u$tarihe_gore_bol(d, 1)
nrow(b3$sinama)
b3$sinama

```

* [ ] Sonuç 0 yerine **2** (biri `NA` satırı) çıktıysa bu bir hatadır: `(kesim + 1):n` ifadesi `kesim = n` olunca geriye sayar. utils.R'da `sinama` satırını şöyle düzelt ve bu bölümü tekrar çalıştır:

```r
       sinama = veri[seq_len(n) > kesim, , drop = FALSE])

```

## 14) formul_kur()

* [ ] Formül sınıfını ve içeriğini kontrol et; `"formula"` ve `"enflasyon ~ faiz + kur + trend + mevsim"` döndürmeli:

```r
f <- u$formul_kur("enflasyon", c("faiz", "kur"), trend = TRUE, mevsim = TRUE)
class(f)
deparse(f)

```

* [ ] Trend/mevsim kapalıyken sadece girdilerin eklendiğini kontrol et; `"y ~ x"` döndürmeli:

```r
deparse(u$formul_kur("y", "x"))

```

* [ ] Girdi boşken ne olduğuna bak; `"HATA"` dönerse girdisiz model kurulacak yerde `"y ~ 1"` üretecek bir kontrol eklemeyi not et:

```r
tryCatch(deparse(u$formul_kur("y", character(0))), error = function(e) "HATA")

```

## 15) yeni_olanlar()

* [ ] Eski tarih yokken tüm veriyi döndürdüğünü kontrol et; `100` döndürmeli:

```r
nrow(u$yeni_olanlar(d, "tarih", NULL))

```

* [ ] Yalnızca eski tarihten **sonraki** satırları döndürdüğünü kontrol et; `9` ve `0` döndürmeli:

```r
nrow(u$yeni_olanlar(d, "tarih", as.Date("2020-03-31")))
nrow(u$yeni_olanlar(d, "tarih", max(d$tarih)))

```

## 16) kalici_hata() ve tekrar_dene()

* [ ] Kalıcı hatanın sınıfını kontrol et; `"kalici_hata" "error" "condition"` ve `"deneme"` döndürmeli:

```r
h <- tryCatch(u$kalici_hata("deneme"), error = function(e) e)
class(h)
conditionMessage(h)

```

* [ ] İki kez başarısız olup üçüncüde başaran işlemi test et; `"tamam"` ve `3` döndürmeli (ekranda 2 "başarısız, tekrar deneniyor" logu görünür):

```r
sayac <- 0
u$tekrar_dene(function() { sayac <<- sayac + 1; if (sayac < 3) stop("geçici") else "tamam" },
              deneme = 3, bekleme = 0)
sayac

```

* [ ] Kalıcı hatada tekrar denemeden durduğunu kontrol et; `"yetki yok"` ve `1` döndürmeli:

```r
sayac <- 0
tryCatch(u$tekrar_dene(function() { sayac <<- sayac + 1; u$kalici_hata("yetki yok") },
                       deneme = 3, bekleme = 0),
         error = function(e) conditionMessage(e))
sayac

```

* [ ] Hep başarısız olan işlemde tüm denemeleri yapıp son hatayı ilettiğini kontrol et; `"bağlantı yok"` ve `3` döndürmeli:

```r
sayac <- 0
tryCatch(u$tekrar_dene(function() { sayac <<- sayac + 1; stop("bağlantı yok") },
                       deneme = 3, bekleme = 0),
         error = function(e) conditionMessage(e))
sayac

```

* [ ] Hep `NULL` döndüren işlemde açıklayıcı hata verdiğini kontrol et; `"İşlem boş sonuç döndürdü"` döndürmeli:

```r
tryCatch(u$tekrar_dene(function() NULL, deneme = 2, bekleme = 0),
         error = function(e) conditionMessage(e))

```

* [ ] Bekleme süresinin uygulandığını kontrol et; 3 deneme × 0,2 sn beklemede süre **~0,4 sn** olmalı (son denemeden sonra beklenmez):

```r
system.time(try(u$tekrar_dene(function() stop("x"), deneme = 3, bekleme = 0.2), silent = TRUE))[["elapsed"]]

```

## 17) Dönem fonksiyonları

* [ ] `frekans_ayari()`'nın her frekans için ay adımını verdiğini kontrol et; aylık `1`, çeyreklik `3`, yıllık `12` olmalı:

```r
sapply(names(u$CONFIG$frekanslar), function(f) u$frekans_ayari(f)$ay_adimi)

```

* [ ] `donem_basi()` sonuçlarını kontrol et; sırasıyla `2026-08-01`, `2026-07-01`, `2026-01-01` döndürmeli:

```r
t0 <- as.Date("2026-08-17")
u$donem_basi(t0, "aylik")
u$donem_basi(t0, "ceyreklik")
u$donem_basi(t0, "yillik")

```

* [ ] Vektörle çalıştığını kontrol et; `2026-01-01` ve `2026-10-01` döndürmeli:

```r
u$donem_basi(as.Date(c("2026-01-31", "2026-12-31")), "ceyreklik")

```

* [ ] `donem_dizisi()`'ni kontrol et; ilki 4 tarih (Oca/Nis/Tem/Eki), ikincisi `72` döndürmeli:

```r
u$donem_dizisi(as.Date("2025-01-01"), as.Date("2025-12-01"), "ceyreklik")
length(u$donem_dizisi(as.Date("2020-01-01"), as.Date("2025-12-01"), "aylik"))

```

* [ ] `donem_ekle()`'yi kontrol et; ilki `2026-10-01 2027-01-01 2027-04-01`, ikincisi `0` döndürmeli (başlangıç tarihi sonuca dahil edilmez):

```r
u$donem_ekle(as.Date("2026-07-01"), 3, "ceyreklik")
length(u$donem_ekle(as.Date("2026-08-01"), 0, "aylik"))

```

* [ ] Ay sonu tuzağını kontrol et: 31 Ocak'tan 1 ay eklenince ne çıktığına bak. `2026-03-03` çıkarsa bu R'ın davranışıdır; fonksiyona her zaman `donem_basi()` ile ayın 1'ine çekilmiş tarih verildiğinden emin ol:

```r
u$donem_ekle(as.Date("2026-01-31"), 1, "aylik")
u$donem_ekle(u$donem_basi(as.Date("2026-01-31"), "aylik"), 1, "aylik")

```

* [ ] `donem_etiketi()`'ni kontrol et; sırasıyla `"Ağustos 2026"`, `"2026 Ç3"`, `"2026"`, `"2026-08-01"` döndürmeli ve Türkçe harfler düzgün görünmeli:

```r
u$donem_etiketi(as.Date("2026-08-01"), "aylik")
u$donem_etiketi(as.Date("2026-08-01"), "ceyreklik")
u$donem_etiketi(as.Date("2026-08-01"), "yillik")
u$donem_etiketi(as.Date("2026-08-01"), "haftalik")

```

* [ ] Vektörle çalıştığını kontrol et; `"Ocak 2026"` ve `"Aralık 2026"` döndürmeli:

```r
u$donem_etiketi(as.Date(c("2026-01-01", "2026-12-01")), "aylik")

```

## 18) Gösterge fonksiyonları

* [ ] Aktif ve pasif göstergeleri listele; config.R'daki `aktif = TRUE/FALSE` ayarlarıyla uyuşmalı:

```r
u$aktif_gostergeler()
setdiff(names(u$CONFIG$gostergeler), u$aktif_gostergeler())

```

* [ ] Aktif göstergelerin etiket, frekans, öncelik, p, pencere, ufuk ve pencere adaylarını tablo olarak görüntüle:

```r
gosterge_tablo <- do.call(rbind, lapply(u$aktif_gostergeler(), function(g) data.frame(
  gosterge = g,
  etiket   = u$gosterge_etiketi(g),
  frekans  = u$gosterge_frekansi(g),
  oncelik  = paste(u$gosterge_oncelik(g), collapse = ","),
  p        = u$gosterge_p(g),
  pencere  = u$gosterge_pencere(g),
  ufuk     = u$gosterge_ufuk(g),
  adaylar  = paste(u$gosterge_pencere_adaylari(g), collapse = "/")
)))
print(gosterge_tablo, row.names = FALSE)

```

* [ ] Her göstergede pencerenin AR(p) modeli için yeterli olduğunu (`pencere > 2p + 1`) kontrol et; hepsi `TRUE` olmalı:

```r
setNames(gosterge_tablo$pencere > 2 * gosterge_tablo$p + 1, gosterge_tablo$gosterge)

```

* [ ] Her göstergede seçili pencerenin aday listesinde olduğunu kontrol et; hepsi `TRUE` olmalı:

```r
sapply(u$aktif_gostergeler(), function(g) u$gosterge_pencere(g) %in% u$gosterge_pencere_adaylari(g))

```

* [ ] Tanımsız gösterge adında varsayılanlara düştüğünü kontrol et; sırasıyla `"yok_boyle"`, `"aylik"`, `TRUE`, `TRUE` döndürmeli:

```r
u$gosterge_etiketi("yok_boyle")
u$gosterge_frekansi("yok_boyle")
u$gosterge_p("yok_boyle") == u$varsayilan(u$CONFIG$frekanslar$aylik$lag_sayisi, u$CONFIG$model$lag_sayisi)
is.null(u$gosterge_oncelik("yok_boyle"))

```

## 19) Yükleme hızı

* [ ] Yalnız utils.R'ın yükleme süresini 30 kez ölç (ms); **medyan 100 ms'nin altında** olmalı:

```r
sureler <- replicate(30, {
  e <- new.env(parent = u)
  system.time(suppressMessages(sys.source(utils_yolu, envir = e, keep.source = FALSE, toplevel.env = e)))[["elapsed"]] * 1000
})
summary(sureler)

```

* [ ] config.R + utils.R birlikte yükleme süresini ölç (ms):

```r
summary(replicate(30, system.time(yukle_utils())[["elapsed"]] * 1000))

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
  "config_yolu", "utils_yolu", "eski_fred", "eski_evds", "yukle_utils", "u", "gecici", "satirlar",
  "ifadeler", "tanimlar", "ham", "metin", "kod_kismi", "kod2", "temiz", "say", "fark", "p", "bos",
  "sadece_config", "cfg", "mesajlar", "uyarilar", "e2", "yeni", "araclar", "wd_once", "yollar",
  "notlar", "log_dosyasi", "son", "once", "deneme_dosyasi", "veri", "cache_dosyasi", "y", "d",
  "b", "b2", "b3", "f", "h", "sayac", "t0", "gosterge_tablo", "sureler"
)))

```

* [ ] Sağ üstteki "Environment" sekmesinde test nesnelerinin kalmadığını kontrol et
* [ ] Başarısız olan adımları not al ve utils.R'ı düzelttikten sonra ilgili bölümü tekrar çalıştır