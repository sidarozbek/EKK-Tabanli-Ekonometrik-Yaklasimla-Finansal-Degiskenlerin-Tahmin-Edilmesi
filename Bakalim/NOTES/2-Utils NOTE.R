#Bu kod, R ortamında CONFIG adında bir ayar değişkeni tanımlı değilse çalışmayı anında durdurarak kullanıcıdan önce R/config.R dosyasını yüklemesini isteyen bir kontrol mekanizmasıdır.
if (!exists("CONFIG")) {
  stop("[utils.R] Önce config.R yükle: source('R/config.R')")
}

#Asıl veri bozuk veya boşsa, B planındaki (yedek) veriyi kullan.
varsayilan <- function(deger, yedek) {
  if (is.null(deger) || length(deger) == 0 || all(is.na(deger))) yedek else deger
}

#Ayarlardaki (CONFIG$saklama) ismi "klasoru" ile biten tüm klasör yollarını bulur ve bilgisayarınızda bu klasörler henüz yoksa hepsini otomatik olarak oluşturur.
klasor_hazirla <- function() {
  yollar <- unlist(CONFIG$saklama[grep("klasoru$", names(CONFIG$saklama))])
  for (y in yollar) dir.create(y, showWarnings = FALSE, recursive = TRUE)
  invisible(yollar)
}

#Bu kod, verdilen mesajı tarih ve saat ekleyerek hem ekrana yazdıran hem de calisma.log adlı bir günlük dosyasına kaydeden bir kayıt (log) tutucudur.
log_msg <- function(mesaj, seviye = "BILGI") {
  satir <- paste0("[", format(Sys.time(), "%Y-%m-%d %H:%M:%S"), "] [", seviye, "] ", mesaj)
  cat(satir, "\n")
  klasor <- varsayilan(CONFIG$saklama$log_klasoru, "logs")
  dir.create(klasor, showWarnings = FALSE, recursive = TRUE)
  try(cat(satir, "\n", file = file.path(klasor, "calisma.log"), append = TRUE), silent = TRUE)
  invisible(NULL)
}

#Bu kod, belirtilen bir dosyanın kaç gün önce düzenlendiğini (yaşını) hesaplar; eğer dosya hiç yoksa sonucu sonsuz (Inf) olarak döndürür.
dosya_yasi_gun <- function(yol) {
  if (!file.exists(yol)) return(Inf)
  as.numeric(difftime(Sys.time(), file.mtime(yol), units = "days"))
}

#Bu kod, verilen bir veriyi önbelleğe (cache) almak için belirtilen klasöre .rds uzantılı bir dosya olarak kaydeder.
cache_yaz <- function(veri, ad) {
  klasor <- varsayilan(CONFIG$saklama$cache_klasoru, "data/cache")
  dir.create(klasor, showWarnings = FALSE, recursive = TRUE)
  saveRDS(veri, file.path(klasor, paste0(ad, ".rds")))
  invisible(NULL)
}

#Bu kod, önbellekteki (cache) kaydedilmiş veriyi okur; eğer dosya yoksa veya belirlediğiniz süreden (varsayılan 1 gün) daha eskiyse veriyi eski kabul edip boş (NULL) döndürür.
cache_oku <- function(ad, tazelik_gun = 1) {
  klasor <- varsayilan(CONFIG$saklama$cache_klasoru, "data/cache")
  yol <- file.path(klasor, paste0(ad, ".rds"))
  if (!file.exists(yol)) return(NULL)
  if (dosya_yasi_gun(yol) > tazelik_gun) return(NULL)
  tryCatch(readRDS(yol), error = function(e) NULL)
}

#Bu kod, elinizdeki veriden sadece "tarih" ve "deger" sütunlarını seçip yedek klasörüne .csv dosyası olarak kaydeder.
yedek_csv_yaz <- function(veri, ad) {
  klasor <- varsayilan(CONFIG$saklama$yedek_klasoru, "data/yedek")
  dir.create(klasor, showWarnings = FALSE, recursive = TRUE)
  try(utils::write.csv(veri[, c("tarih", "deger")], file.path(klasor, paste0(ad, ".csv")),
                       row.names = FALSE), silent = TRUE)
  invisible(NULL)
}

#Bu kod, kaydedilmiş yedek .csv dosyasını okur; içindeki "tarih" ve "deger" bilgilerini doğru veri tiplerine (tarih ve sayıya) dönüştürüp, yanına bir de kimlik ekleyerek temiz bir tablo halinde geri verir.
yedek_csv_oku <- function(ad) {
  yol <- file.path(varsayilan(CONFIG$saklama$yedek_klasoru, "data/yedek"), paste0(ad, ".csv"))
  if (!file.exists(yol)) return(NULL)
  d <- tryCatch(utils::read.csv(yol, stringsAsFactors = FALSE), error = function(e) NULL)
  if (is.null(d) || !all(c("tarih", "deger") %in% names(d)) || nrow(d) == 0) return(NULL)
  data.frame(tarih = as.Date(d$tarih), deger = as.numeric(d$deger), kimlik = ad)
}

#Bu kod, işlenmiş bir veriyi garanti olsun diye aynı anda iki farklı formatta (hem R dosyası .rds hem de Excel/metin dosyası .csv olarak) klasöre kaydeder.
ikili_kaydet <- function(veri, ad) {
  klasor <- varsayilan(CONFIG$saklama$processed_klasoru, "data/processed")
  dir.create(klasor, showWarnings = FALSE, recursive = TRUE)
  saveRDS(veri, file.path(klasor, paste0(ad, ".rds")))
  utils::write.csv(veri, file.path(klasor, paste0(ad, ".csv")), row.names = FALSE)
  invisible(NULL)
}

#Bu kod, önceden işlenip data/processed klasörüne .rds olarak kaydedilmiş veriyi güvenle geri okur.
processed_oku <- function(ad) {
  yol <- file.path(varsayilan(CONFIG$saklama$processed_klasoru, "data/processed"),
                   paste0(ad, ".rds"))
  if (!file.exists(yol)) return(NULL)
  tryCatch(readRDS(yol), error = function(e) NULL)
}

#Bu kod, elinizdeki veriyi kronolojik sırasını bozmadan belirlediğiniz oranda (varsayılan olarak %80 model eğitimi, %20 sınama/test için) eğitim ve sınama kümesi olarak ikiye böler.
tarihe_gore_bol <- function(veri, egitim_orani = NULL) {
  oran <- varsayilan(egitim_orani, varsayilan(CONFIG$model$egitim_orani, 0.80))
  n <- nrow(veri)
  kesim <- floor(n * oran)
  list(egitim = veri[seq_len(kesim), , drop = FALSE],
       sinama = veri[(kesim + 1):n, , drop = FALSE])
}

#Bu kod, belirlediğiniz hedef ve girdi değişkenlerine isteğinize göre trend ve mevsim etkilerini de ekleyerek istatistiksel modeller için hazır bir formül (hedef ~ girdi1 + girdi2) oluşturur.
formul_kur <- function(hedef, girdiler, trend = FALSE, mevsim = FALSE) {
  terimler <- girdiler
  if (trend)  terimler <- c(terimler, "trend")
  if (mevsim) terimler <- c(terimler, "mevsim")
  stats::as.formula(paste(hedef, "~", paste(terimler, collapse = " + ")))
}

#Bu kod, bir tablodaki verileri inceleyip yalnızca belirlediğiniz tarihten (eski_tarih) daha yeni olan satırları filtreleyip size verir; eğer eski bir tarih belirtilmemişse verinin tamamını olduğu gibi geri döndürür.
yeni_olanlar <- function(veri, tarih_sutunu, eski_tarih) {
  if (is.null(eski_tarih)) return(veri)
  veri[veri[[tarih_sutunu]] > eski_tarih, , drop = FALSE]
}

#Bu kod, programda düzeltilemeyecek kritik bir sorun olduğunda (örneğin eksik veya bozuk bir dosya durumunda) özel bir "Kalıcı Hata" uyarısı fırlatarak çalışmayı durduran acil durum butonudur.
kalici_hata <- function(mesaj) {
  stop(structure(class = c("kalici_hata", "error", "condition"),
                 list(message = mesaj, call = NULL)))
}

#Bu kod, bir işlemi hemen pes etmeden belirli sayıda (varsayılan 3 defa) tekrar dener; eğer işlem "kalıcı hata" verirse zaman kaybetmeden durur, geçici bir hataysa aralarda bekleyip tekrar deneyerek log kaydı tutar.
tekrar_dene <- function(islem, deneme = NULL, bekleme = NULL) {
  n <- varsayilan(deneme, varsayilan(CONFIG$baglanti$yeniden_deneme, 3))
  b <- varsayilan(bekleme, varsayilan(CONFIG$baglanti$yeniden_deneme_bekleme, 2))
  son_hata <- NULL
  for (i in seq_len(n)) {
    sonuc <- tryCatch(islem(), error = function(e) { son_hata <<- e; NULL })
    if (!is.null(sonuc)) return(sonuc)
    if (inherits(son_hata, "kalici_hata")) break
    if (i < n) {
      log_msg(paste0("Deneme ", i, "/", n, " başarısız, tekrar deneniyor"), "UYARI")
      Sys.sleep(b)
    }
  }
  if (is.null(son_hata)) stop("İşlem boş sonuç döndürdü", call. = FALSE)
  stop(conditionMessage(son_hata), call. = FALSE)
}

#Bu kod, verilen bir tarihi belirlediğiniz zaman aralığına (örneğin aylık, çeyreklik veya yıllık döneme) göre yuvarlayarak, o dönemin ilk gününü (örneğin ayın veya çeyreğin 1. gününü) bulur.
donem_basi <- function(tarih, frekans) {
  adim <- frekans_ayari(frekans)$ay_adimi
  y <- as.integer(format(tarih, "%Y")); m <- as.integer(format(tarih, "%m"))
  as.Date(sprintf("%04d-%02d-01", y, ((m - 1) %/% adim) * adim + 1))
}

#Bu kod, belirlediğiniz başlangıç ve bitiş tarihleri arasında, seçtiğiniz periyoda (örneğin 1 ay, 3 ay veya 12 ay aralıklarla) uygun sıralı bir tarih listesi/dizisi oluşturur.
donem_dizisi <- function(bas, son, frekans) {
  seq(bas, son, by = paste(frekans_ayari(frekans)$ay_adimi, "months"))
}

#Bu kod, belirttiğiniz bir tarihin üzerine seçtiğiniz zaman aralığına göre (örneğin aylık veya çeyreklik) n adım sonrasındaki gelecek tarihleri hesaplayıp bir liste halinde verir.
donem_ekle <- function(tarih, n, frekans) {
  seq(tarih, by = paste(frekans_ayari(frekans)$ay_adimi, "months"), length.out = n + 1)[-1]
}

#Bu kod, verilen bir tarihi seçtiğiniz frekansa göre okunaklı bir metin etiketine dönüştürür; örneğin aylık için "Ocak 2024", çeyreklik için "2024 Ç1", yıllık için "2024" şeklinde veya tanınmayan bir frekansta doğrudan tarihin kendisini metin olarak döndürür.
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

#Bu kod, sistem ayarlarındaki (CONFIG) göstergeleri tarayarak yalnızca duruma göre aktif olarak işaretlenmiş olan göstergelerin isimlerini bir liste halinde ayıklayıp size verir.
aktif_gostergeler <- function() {
  names(Filter(function(g) isTRUE(g$aktif), CONFIG$gostergeler))
}

#Bu kod, verilen bir gösterge kodunun (g) sistem ayarlarındaki özel adını bulur; eğer özel bir ad tanımlanmamışsa veya boşsa yedek plan olarak göstergenin kendi kod adını (g) geri verir.
gosterge_etiketi <- function(g) varsayilan(CONFIG$gostergeler[[g]][["ad"]], g)

#Bu kod, verilen bir göstergenin (g) sistem ayarlarında tanımlı zaman frekansını (örneğin "ceyreklik" veya "yillik") bulur; eğer özel bir frekans belirtilmemişse varsayılan olarak "aylik" değerini döndürür.
gosterge_frekansi <- function(g) varsayilan(CONFIG$gostergeler[[g]][["frekans"]], "aylik")

#Bu kod, belirtilen göstergenin (g) sistem ayarlarındaki öncelik sırasını/seviyesini okuyup getiren doğrudan bir erişim fonksiyonudur.
gosterge_oncelik <- function(g) CONFIG$gostergeler[[g]][["oncelik"]]

#Bu kod, bir göstergenin modelde kaç dönem geriye dönük (geikmeli/lag) kullanılacağını bulur; sırasıyla göstergeye özel ayara, bulunamazsa frekansa özel ayara, o da yoksa genel model ayarlarına bakar ve hiçbir şey tanımlı değilse varsayılan olarak 3 değerini alır.
gosterge_p <- function(g) {
  f <- gosterge_frekansi(g)
  varsayilan(CONFIG$gostergeler[[g]][["p"]],
             varsayilan(CONFIG$frekanslar[[f]][["lag_sayisi"]], varsayilan(CONFIG$model$lag_sayisi, 3)))
}

#Bu kod, bir göstergenin analizinde veya modellemesinde kullanılacak zaman penceresi uzunluğunu (veri geçmişi derinliğini) belirler; sırasıyla göstergeye özel ayara, yoksa frekansa özel ayara, o da yoksa genel model ayarlarına bakar ve hiçbir yerde tanımlanmamışsa varsayılan olarak 48 değerini döndürür.
gosterge_pencere <- function(g) {
  f <- gosterge_frekansi(g)
  varsayilan(CONFIG$gostergeler[[g]][["pencere"]],
             varsayilan(CONFIG$frekanslar[[f]][["pencere_uzunlugu"]], varsayilan(CONFIG$model$pencere_uzunlugu, 48)))
}

#Bu kod, belirli bir gösterge için modelin kaç adım ileriye dönük tahmin yapacağını (tahmin ufkunu) belirler; öncelikle göstergeye özel ayara, yoksa frekansa özel ayara, o da yoksa genel model ayarlarına bakar ve hiçbir ayar bulunamazsa varsayılan olarak 6 değerini alır.
gosterge_ufuk <- function(g) {
  f <- gosterge_frekansi(g)
  varsayilan(CONFIG$gostergeler[[g]][["tahmin_ufku"]],
             varsayilan(CONFIG$frekanslar[[f]][["tahmin_ufku"]], varsayilan(CONFIG$model$tahmin_ufku, 6)))
}

#Bu kod, belirli bir gösterge için model optimizasyonunda denenecek pencere uzunluğu adaylarını (farklı geçmiş veri aralıklarını) getirir; öncelikle göstergeye özel tanımlanmış bir aday listesi var mı diye bakar, yoksa göstergenin frekansına uygun olan varsayılan pencere adaylarını döndürür.
gosterge_pencere_adaylari <- function(g) {
  varsayilan(CONFIG$gostergeler[[g]][["pencere_adaylari"]],
             frekans_ayari(gosterge_frekansi(g))$pencere_adaylari)
}

#Bu kod, utils.R dosyasının sonunda çalışan bir kalite kontrol testidir; kütüphanedeki tüm araçların (fonksiyonların) eksiksiz şekilde yüklenip yüklenmediğini denetler, eksik bir fonksiyon varsa hata vererek çalışmayı durdurur, hepsi tamsa alet çantasının başarıyla yüklendiğine dair onay mesajı verir.
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

