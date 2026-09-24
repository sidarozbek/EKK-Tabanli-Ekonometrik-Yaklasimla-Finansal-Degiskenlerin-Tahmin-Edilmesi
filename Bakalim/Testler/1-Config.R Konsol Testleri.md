## Hazırlık

* [ ] RStudio'da projeyi aç ve Console'da proje kökünde olduğunu kontrol et; ikinci satır `TRUE` döndürmeli:

```r
getwd()
file.exists("R/config.R")

```

* [ ] Config dosyasının tam yolunu bir değişkene yaz (çalışma dizini değişse de doğru dosyayı göstersin diye):

```r
config_yolu <- normalizePath("R/config.R", winslash = "/")

```

* [ ] Gerçek API anahtarlarını sakla ve testler için sahte anahtar tanımla:

```r
eski_fred <- Sys.getenv("FRED_API_KEY")
eski_evds <- Sys.getenv("EVDS_API_KEY")
Sys.setenv(FRED_API_KEY = "KT_FRED", EVDS_API_KEY = "KT_EVDS")

```

* [ ] config.R'ı temiz bir ortamda yükleyen yardımcı fonksiyonu tanımla (global ortamı kirletmez):

```r
yukle <- function() {
  e <- new.env(parent = globalenv())
  suppressMessages(sys.source(config_yolu, envir = e, keep.source = FALSE, toplevel.env = e))
  e
}

```

* [ ] Dosyanın satırlarını oku:

```r
satirlar <- readLines(config_yolu, encoding = "UTF-8", warn = FALSE)

```

## 1) Sözdizimi

* [ ] Dosyayı çalıştırmadan sözdizimi hatası olup olmadığını kontrol et; hata çıkmamalı, ifade ve satır sayısı yazmalı:

```r
ifadeler <- parse(config_yolu, encoding = "UTF-8")
length(ifadeler)
length(satirlar)

```

* [ ] Hata çıktıysa R'ın hatayı çoğu zaman gerçek yerinden **sonra** gösterdiğini unutma; yerini bulmak için 4. bölüme (parantez dengesi) geç

## 2) Karakter kodlaması

* [ ] Dosyanın BOM ile başlamadığını kontrol et; `FALSE` döndürmeli (TRUE ise RStudio'da "File → Save with Encoding → UTF-8" ile kaydet):

```r
ham <- readBin(config_yolu, "raw", file.info(config_yolu)$size)
identical(ham[1:3], as.raw(c(0xEF, 0xBB, 0xBF)))

```

* [ ] Dosyanın geçerli UTF-8 olduğunu kontrol et; `TRUE` döndürmeli:

```r
metin <- rawToChar(ham)
Encoding(metin) <- "UTF-8"
validUTF8(metin)

```

* [ ] Windows satır sonu (CRLF) olup olmadığına bak; `FALSE` beklenir (TRUE ise zararsız, bilgi amaçlı):

```r
any(ham == as.raw(0x0D))

```

* [ ] Türkçe harflerin yalnız metin ve yorumlarda geçtiğini kontrol et; `integer(0)` döndürmeli (dönen satırlarda değişken adında Türkçe harf var):

```r
kod_kismi <- gsub('"[^"]*"|#.*$', "", satirlar)
which(grepl("[çğıöşüÇĞİÖŞÜ]", kod_kismi))

```

* [ ] R oturumunun UTF-8 olduğunu kontrol et; `TRUE` döndürmeli:

```r
l10n_info()$`UTF-8`

```

## 3) Biçim / stil

> Bu bölümdeki bulgular uyarıdır, testi düşürmez. Her komutun `integer(0)` döndürmesi idealdir.

* [ ] Metin ve yorumları ayıklanmış kod satırlarını hazırla:

```r
kod2 <- sub("#.*$", "", gsub('"[^"]*"', '""', satirlar))

```

* [ ] Sekme karakteri, satır sonu boşluğu ve 120 karakterden uzun satır olmadığını kontrol et:

```r
grep("\t", satirlar)
grep("[ \t]+$", satirlar)
which(nchar(satirlar, type = "width") > 120)

```

* [ ] `T`/`F` kısaltması kullanılmadığını kontrol et (her yerde `TRUE`/`FALSE` yazılmalı):

```r
grep("(^|[^A-Za-z0-9_.$])(T|F)([^A-Za-z0-9_.(]|$)", kod2)

```

* [ ] Satır sonunda gereksiz `;`, üst düzeyde `=` ile atama ve `<<-` (global atama) olmadığını kontrol et:

```r
grep(";\\s*$", kod2)
grep("^[A-Za-z_.][A-Za-z0-9_.]*\\s*=[^=]", kod2)
grep("(^|[^<])<<-", kod2)

```

* [ ] Dosya sonunun düzgün olduğunu kontrol et; `TRUE` döndürmeli:

```r
nzchar(tail(satirlar, 1))

```

## 4) Parantez ve tırnak dengesi

* [ ] Metinleri ve yorumları temizle, parantez sayma fonksiyonunu tanımla:

```r
temiz <- sub("#.*$", "", gsub('"([^"\\\\]|\\\\.)*"', '""', satirlar))
say <- function(ch) lengths(regmatches(temiz, gregexpr(ch, temiz, fixed = TRUE)))

```

* [ ] Her parantez türü için "son" değerin **0**, "en düşük" değerin **0'dan küçük olmadığını** kontrol et:

```r
for (p in list(c("(", ")"), c("{", "}"), c("[", "]"))) {
  fark <- cumsum(say(p[1]) - say(p[2]))
  cat(p[1], p[2], "| son:", tail(fark, 1), "| en düşük:", min(fark), "| en derin:", max(fark), "\n")
}

```

* [ ] Sorun varsa hangi satırda bozulduğunu bul (örnek: normal parantez için; `{` veya `[` için karakterleri değiştir):

```r
fark <- cumsum(say("(") - say(")"))
which(fark < 0)[1]
plot(fark, type = "s")

```

* [ ] Tek sayıda tırnak içeren satır olmadığını kontrol et; `integer(0)` beklenir (dönen satır çok satırlı bir metin olabilir):

```r
which(lengths(regmatches(temiz, gregexpr('"', temiz))) %% 2 == 1)

```

## 5) Tanımsız değişken / kullanılmayan atama

* [ ] config.R'ı test ortamına yükle:

```r
test_ortami <- yukle()

```

* [ ] `local()` bloklarını codetools ile tara ve tüm notları listele:

```r
bulgular <- character(0)
for (e in ifadeler) {
  if (is.call(e) && identical(e[[1]], as.name("local"))) {
    f <- eval(call("function", NULL, e[[2]]), test_ortami)
    codetools::checkUsage(f, all = TRUE, suppressLocalUnused = FALSE,
                          report = function(x) bulgular <<- c(bulgular, trimws(x)))
  }
}
unique(bulgular)

```

* [ ] Ciddi bulgu (tanımsız değişken) olmadığını kontrol et; `character(0)` döndürmeli:

```r
grep("no visible|global", bulgular, value = TRUE)

```

## 6) Yükleme

* [ ] Anahtarlar tanımlıyken dosyanın hatasız ve uyarısız yüklendiğini kontrol et; `uyarilar` `character(0)` olmalı:

```r
uyarilar <- character(0)
withCallingHandlers(
  yukle(),
  warning = function(w) { uyarilar <<- c(uyarilar, conditionMessage(w)); invokeRestart("muffleWarning") }
)
uyarilar

```

* [ ] Anahtarları boşalt ve yükle; yükleme durmamalı, **2** uyarı (FRED ve EVDS) çıkmalı:

```r
Sys.setenv(FRED_API_KEY = "", EVDS_API_KEY = "")
uyarilar <- character(0)
withCallingHandlers(
  yukle(),
  warning = function(w) { uyarilar <<- c(uyarilar, conditionMessage(w)); invokeRestart("muffleWarning") }
)
length(uyarilar)
uyarilar

```

* [ ] Sahte anahtarları geri yükle:

```r
Sys.setenv(FRED_API_KEY = "KT_FRED", EVDS_API_KEY = "KT_EVDS")

```

## 7) Yükleme hızı

* [ ] Bir kez ısınma yüklemesi yap, sonra 50 kez yükleyip süreleri (ms) özetle; **medyan 200 ms'nin altında** olmalı:

```r
invisible(yukle())
sureler <- replicate(50, system.time(yukle())[["elapsed"]] * 1000)
summary(sureler)

```

* [ ] Yalnız parse süresini ölç (ms):

```r
mean(replicate(50, system.time(parse(config_yolu, encoding = "UTF-8", keep.source = FALSE))[["elapsed"]] * 1000))

```

* [ ] Medyan 200 ms'yi geçiyorsa config.R içinde ağ/disk erişimi olup olmadığını kontrol et

## 8) Doğrulama bloğunun hızı

* [ ] Dosyanın son ifadesini (kendini doğrulama bloğu) 200 kez çalıştır ve bir seferlik süreyi (ms) hesapla:

```r
dogrulama <- ifadeler[[length(ifadeler)]]
cfg_ortam <- yukle()
t <- system.time(for (i in 1:200) suppressMessages(eval(dogrulama, cfg_ortam)))[["elapsed"]]
1000 * t / 200

```

* [ ] Kaç göstergenin doğrulandığını not et:

```r
length(cfg_ortam$CONFIG$gostergeler)

```

## 9) Bellek kullanımı

* [ ] CONFIG'in toplam boyutunu kontrol et; **5 MB'ın altında** olmalı:

```r
format(object.size(cfg_ortam$CONFIG), units = "KB")

```

* [ ] Alt bölümlerin boyutunu (KB) büyükten küçüğe listele:

```r
sort(sapply(cfg_ortam$CONFIG, function(x) round(as.numeric(object.size(x)) / 1024, 1)), decreasing = TRUE)

```

## 10) Global ortama bıraktıkları

* [ ] config.R'ın oluşturduğu tüm nesneleri listele; yalnızca `CONFIG`, `.proje_koku`, `.fred_key`, `.evds_key` olmalı:

```r
ls(cfg_ortam, all.names = TRUE)

```

* [ ] Beklenmeyen nesne olmadığını kontrol et; `character(0)` döndürmeli:

```r
setdiff(ls(cfg_ortam, all.names = TRUE), c("CONFIG", ".proje_koku", ".fred_key", ".evds_key"))

```

* [ ] Çalışma dizinini ve `options()` ayarlarını değiştirmediğini kontrol et; ilk satır `TRUE`, ikinci satır `character(0)` olmalı:

```r
wd_once <- getwd()
opt_once <- names(options())
invisible(yukle())
identical(getwd(), wd_once)
setdiff(names(options()), opt_once)

```

## 11) Tekrarlanabilirlik

* [ ] İki ayrı yüklemenin birebir aynı CONFIG ürettiğini kontrol et; `TRUE` döndürmeli:

```r
identical(yukle()$CONFIG, yukle()$CONFIG)

```

* [ ] `FALSE` döndüyse farkları görüntüle:

```r
all.equal(yukle()$CONFIG, yukle()$CONFIG)

```

## 12) Farklı çalışma dizininden yükleme

* [ ] Proje kökünü not et, `app/` klasörüne geç (yoksa geçici oluştur) ve config.R'ı oradan yükle:

```r
kok <- normalizePath(getwd(), winslash = "/")
app_vardi <- dir.exists("app")
if (!app_vardi) dir.create("app")
setwd("app")
dizin_testi <- yukle()$CONFIG$saklama$kok

```

* [ ] Proje köküne geri dön ve geçici klasörü sil:

```r
setwd(kok)
if (!app_vardi) unlink("app", recursive = TRUE)

```

* [ ] `app/` içinden yüklenince de kökün doğru bulunduğunu kontrol et; `TRUE` döndürmeli:

```r
dizin_testi
identical(normalizePath(dizin_testi, winslash = "/"), kok)

```

## 13) API anahtarı güvenliği

* [ ] Dosyada gömülü anahtar olmadığını kontrol et; iki komut da `integer(0)` döndürmeli:

```r
grep("(key|anahtar|token|password|sifre)\\s*=\\s*\"[^\"]{8,}\"", satirlar, ignore.case = TRUE)
grep("\\b[0-9a-f]{32}\\b", satirlar)

```

* [ ] Anahtarların ortam değişkeninden (`.Renviron`) okunduğunu kontrol et; ilk satır `"GIZLI123"` döndürmeli:

```r
Sys.setenv(FRED_API_KEY = "GIZLI123", EVDS_API_KEY = "GIZLI456")
gizli_cfg <- yukle()$CONFIG
gizli_cfg$baglanti$fred_key

```

* [ ] `str(CONFIG)` çıktısının anahtarı ekrana basıp basmadığına bak; `TRUE` ise ekran görüntüsü/log paylaşırken dikkat et:

```r
any(grepl("GIZLI", capture.output(str(gizli_cfg, max.level = 2))))

```

* [ ] Sahte anahtarları geri yükle:

```r
Sys.setenv(FRED_API_KEY = "KT_FRED", EVDS_API_KEY = "KT_EVDS")

```

* [ ] `.Renviron`'un `.gitignore`'da olduğunu kontrol et; `TRUE` döndürmeli (git kullanıyorsan):

```r
file.exists(".gitignore") && any(grepl("^\\.Renviron", readLines(".gitignore", warn = FALSE)))

```

## 14) Ayar tipleri

* [ ] Test edilecek CONFIG'i al ve tip kontrol fonksiyonlarını tanımla:

```r
cfg <- yukle()$CONFIG
sayi   <- function(x) is.numeric(x) && length(x) == 1 && !is.na(x)
mantik <- function(x) is.logical(x) && length(x) == 1 && !is.na(x)
metin  <- function(x) is.character(x) && length(x) == 1 && nzchar(x)

```

* [ ] Sayısal ayarları kontrol et; hepsi `TRUE` olmalı (`FALSE` olanın tipi yanlış):

```r
sapply(list(
  zaman_asimi              = cfg$baglanti$zaman_asimi,
  yeniden_deneme           = cfg$baglanti$yeniden_deneme,
  yeniden_deneme_bekleme   = cfg$baglanti$yeniden_deneme_bekleme,
  cache_tazelik_gun        = cfg$veri$cache_tazelik_gun,
  min_gozlem               = cfg$veri$min_gozlem,
  hampel_esigi             = cfg$veri$hampel_esigi,
  lag_sayisi               = cfg$model$lag_sayisi,
  pencere_uzunlugu         = cfg$model$pencere_uzunlugu,
  capraz_min_n             = cfg$model$capraz_min_n,
  tahmin_ufku              = cfg$model$tahmin_ufku,
  guven_duzeyi             = cfg$model$guven_duzeyi,
  egitim_orani             = cfg$model$egitim_orani,
  sikligi_gun              = cfg$guncelleme$sikligi_gun,
  genel_azami              = cfg$sunum$genel_azami
), sayi)

```

* [ ] Mantıksal (TRUE/FALSE) ayarları kontrol et; hepsi `TRUE` olmalı:

```r
sapply(list(
  yedek_kaynak_kullan = cfg$veri$yedek_kaynak_kullan,
  formulde_trend      = cfg$model$formulde_trend,
  otomatik            = cfg$guncelleme$otomatik
), mantik)

```

* [ ] Metin ayarlarını kontrol et; hepsi `TRUE` olmalı:

```r
sapply(list(
  baslik        = cfg$proje$baslik,
  surum         = cfg$proje$surum,
  model_secimi  = cfg$model$model_secimi,
  evds_base_url = cfg$baglanti$evds_base_url
), metin)

```

* [ ] Başlangıç tarihinin geçerli tarih, sürümün `x.y.z` formatında olduğunu kontrol et; ikisi de `TRUE` olmalı:

```r
!is.na(as.Date(cfg$veri$baslangic_tarihi, optional = TRUE))
grepl("^\\d+\\.\\d+\\.\\d+$", cfg$proje$surum)

```

* [ ] Göstergelerin `aktif`, `p`, `pencere`, `tahmin_ufku` alanlarını kontrol et; **hiçbir şey yazdırmamalı**:

```r
for (ad in names(cfg$gostergeler)) {
  g <- cfg$gostergeler[[ad]]
  if (!mantik(g$aktif)) cat(ad, ": aktif TRUE/FALSE olmalı\n")
  for (a in c("p", "pencere", "tahmin_ufku")) {
    if (!is.null(g[[a]]) && !(sayi(g[[a]]) && g[[a]] == round(g[[a]]) && g[[a]] > 0))
      cat(ad, ":", a, "pozitif tam sayı olmalı\n")
  }
}

```

## 15) Gösterge özeti

* [ ] Göstergelerin özet tablosunu oluştur (serbestlik = pencere − 2p − 1 − trend; AR(p) EKK artık serbestlik derecesi):

```r
vs <- function(x, y) if (is.null(x) || length(x) == 0 || is.na(x[1])) y else x
ozet <- do.call(rbind, lapply(names(cfg$gostergeler), function(ad) {
  g <- cfg$gostergeler[[ad]]
  if (!isTRUE(g$aktif)) {
    return(data.frame(gosterge = ad, aktif = FALSE, rol = vs(g$rol, ""), frekans = "", kaynak = "",
                      yedek = "", p = NA, pencere = NA, ufuk = NA, serbestlik = NA, durum = "pasif"))
  }
  fk <- cfg$frekanslar[[g$frekans]]
  p  <- vs(g[["p"]], fk$lag_sayisi)
  w  <- vs(g[["pencere"]], fk$pencere_uzunlugu)
  sd <- (w - p) - (p + 1 + cfg$model$formulde_trend)
  data.frame(gosterge = ad, aktif = TRUE, rol = g$rol, frekans = g$frekans, kaynak = g$kaynak,
             yedek = vs(g$birincil_yedek, ""), p = p, pencere = w,
             ufuk = vs(g$tahmin_ufku, cfg$model$tahmin_ufku), serbestlik = sd,
             durum = if (sd < 5) "DÜŞÜK sd"
                     else if (!w %in% vs(g$pencere_adaylari, fk$pencere_adaylari)) "aday dışı pencere"
                     else "tamam")
}))

```

* [ ] Tabloyu görüntüle ve `durum` sütununu incele:

```r
print(ozet, row.names = FALSE)

```

* [ ] Serbestliği düşük gösterge olmadığını kontrol et; `0` döndürmeli:

```r
sum(ozet$durum == "DÜŞÜK sd")

```

## Temizlik

* [ ] Gerçek API anahtarlarını geri yükle:

```r
if (nzchar(eski_fred)) Sys.setenv(FRED_API_KEY = eski_fred) else Sys.unsetenv("FRED_API_KEY")
if (nzchar(eski_evds)) Sys.setenv(EVDS_API_KEY = eski_evds) else Sys.unsetenv("EVDS_API_KEY")

```

* [ ] Test sırasında oluşan nesneleri sil:

```r
rm(list = intersect(ls(), c(
  "config_yolu", "eski_fred", "eski_evds", "yukle", "satirlar", "ifadeler", "ham", "metin",
  "kod_kismi", "kod2", "temiz", "say", "fark", "p", "test_ortami", "bulgular", "e", "f",
  "uyarilar", "sureler", "dogrulama", "cfg_ortam", "t", "i", "wd_once", "opt_once", "kok",
  "app_vardi", "dizin_testi", "gizli_cfg", "cfg", "sayi", "mantik", "ad", "g", "a", "vs", "ozet"
)))

```

* [ ] Sağ üstteki "Environment" sekmesinde test nesnelerinin kalmadığını kontrol et
* [ ] Başarısız olan adımları not al ve config.R'ı düzelttikten sonra ilgili bölümü tekrar çalıştır
