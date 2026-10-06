# Bu kod, veri hazırlık sürecine başlamadan önce gerekli bağımlılıkların tamam olup olmadığını kontrol eden bir güvenlik adımıdır.
Eğer sistemde yapılandırma ayarları (CONFIG), loglama fonksiyonu (log_msg) veya veri çekme fonksiyonu (tum_gostergeleri_cek) tanımlı değilse,
kodun yarıda çökmesini önlemek için çalışmayı hemen durdurur ve kullanıcıya önceden hangi dosyaları yüklemesi gerektiğini söyler.

if (!exists("CONFIG"))  stop("[data.prep.R] Önce config.R yükle: source('R/config.R')")
if (!exists("log_msg")) stop("[data.prep.R] Önce utils.R yükle: source('R/utils.R')")
if (!exists("tum_gostergeleri_cek")) stop("[data.prep.R] Önce api_functions.R yükle")

# Kodun düzgün çalışması için ihtiyaç duyduğumuz iki temel kütüphaneyi (dplyr ve zoo) projeye çağırıyoruz.
Normalde bu paketler yüklenirken ekrana bir sürü teknik uyarı ve mesaj düşer; suppressPackageStartupMessages komutunu kullanarak o gereksiz mesaj kalabalığını gizliyor, konsolun temiz kalmasını sağlıyoruz.

suppressPackageStartupMessages({
library(dplyr)
library(zoo)
})

#Bu kod, elimizdeki ham veriyi alıp zaman serisi analizine uygun, boşluksuz ve derli toplu bir tablo haline getiriyor.
Önce verideki boş değerleri temizliyor ve tarihleri dönemin başlangıcına oturtuyor.
Aynı tarihe ait birden fazla kayıt varsa, kafa karışıklığı olmasın diye sadece en son güncellenen veriyi alıyor.
İlk tarihten son tarihe kadar hiç eksik ay/dönem atlamayan kesintisiz bir takvim oluşturuyor.
Bu takvimde verisi eksik kalan ara dönemlerin değerlerini, önceki ve sonraki rakamlara bakarak ortalama bir çizgiyle (interpolasyonla) tamamlıyor.
En sonunda da hangi değerin sistemden gelen orijinal veri, hangisinin bizim sonradan doldurduğumuz veri olduğunu belirten bir etiketle (gercek) birlikte temiz bir tablo veriyor.

seri_hazirla <- function(d, g) {
f <- gosterge_frekansi(g)
d <- d[!is.na(d$deger), ]
d$tarih <- donem_basi(d$tarih, f)
d <- d[!duplicated(d$tarih, fromLast = TRUE), ]
takvim <- donem_dizisi(min(d$tarih), max(d$tarih), f)
deger  <- d$deger[match(takvim, d$tarih)]
gercek <- !is.na(deger)
deger  <- zoo::na.approx(deger, na.rm = FALSE)
data.frame(gosterge = g, tarih = takvim, deger = deger, gercek = gercek,
stringsAsFactors = FALSE)
}

# Bu kod, hazırlanan veri tablosunda kaç tane dönemin aslında boş olup sonradan bizim tarafımızdan doldurulduğunu hesaplar.
# Tablodaki 'gercek' sütununda yer alan ve orijinal verisi bulunmayan (FALSE olan) satırları sayarak toplam eksik/tamamlanmış veri sayısını verir.

ic_bosluk_say <- function(veri) sum(!veri$gercek)

#Bu kod, bir veri serisinde ani ve olağandışı sıçrama yapan aykırı değerleri Hampel filtresi yöntemiyle tespit etmemizi sağlar. 
Önce hassasiyet eşiğini belirleyerek işe başlıyoruz. Dışarıdan özel bir eşik değeri verilmediyse sistem ayarlarındaki (CONFIG) varsayılan değeri alıyoruz, orada da yoksa standart kabul edilen 3 değerini kullanıyoruz.
Sağlıklı bir sapma hesabı yapabilmek için elimizde yeterli veri olması gerekir. Bu yüzden verinin uzunluğuna bakıyoruz; eğer 8 gözlemden az veri varsa güvenilir bir analiz yapılamayacağı için tüm değerleri normal (FALSE) kabul edip işlemi bitiriyoruz.
Ardından verinin kendi içindeki hareketini anlamak için bir önceki döneme göre yaşanan değişimleri (farkları) hesaplıyoruz ve bu değişimlerin genel oynaklığını medyan mutlak sapması (MAD) ile ölçüyoruz. 
Eğer seride hiç değişim yoksa veya hesaplanan sapma geçersiz/sıfır çıkarsa, ortada sapan bir durum olamayacağı için  yine tüm verileri temiz (FALSE) sayıyoruz.
Son aşamada ise her bir değişimin genel gidişattan ne kadar saptığını (Z-skoru) hesaplayıp, belirlediğimiz eşik değerinin üzerinde kalan aşırı sıçramaları sapan veri (TRUE) olarak işaretleyip döndürüyoruz.

hampel_sapan <- function(x, esik = NULL) {
esik <- varsayilan(esik, varsayilan(CONFIG$veri$hampel_esigi, 3))
if (length(x) < 8) return(rep(FALSE, length(x)))
fark <- c(NA, diff(x))
mad_ <- stats::mad(fark, na.rm = TRUE)
if (!is.finite(mad_) || mad_ == 0) return(rep(FALSE, length(x)))
z <- abs(fark - stats::median(fark, na.rm = TRUE)) / mad_
!is.na(z) & z > esik
}

#Bu kod, elimizdeki tüm göstergelerin veri kalitesini ve durumunu detaylıca analiz edip tek bir özet rapor tablosu haline getirir.
İşleme ilk olarak konfigürasyon ayarlarından bugünün (ya da hedef bitiş) tarihini alarak başlıyoruz. Ardından veri setindeki her bir benzersiz gösterge için tek tek kalite kontrollerini çalıştırmak üzere bir döngü kuruyoruz.
Her bir göstergeye sıra geldiğinde, ilk olarak o göstergenin frekansını (aylık, çeyreklik vb.) tespit edip verilerini tarihe göre kronolojik olarak sıralıyoruz ve tüm tarihleri ilgili dönemin başlangıcına oturtuyoruz.
Sonrasında göstergenin zaman içindeki durumunu ölçen temel metrikleri hesaplıyoruz:
- İlk ve son tarih arasında normalde kaç dönem olması gerektiğini (kapsam) bulup, mevcut gözlem sayısı ile kıyaslayarak verideki eksik dönem oranını çıkarıyoruz.
- Güncel tarihten ne kadar geride kalındığını hesaplayarak kaç dönemlik bir veri gecikmesi olduğunu tespit ediyoruz.
- Daha önce yazdığımız Hampel filtresini veriye uygulayarak serideki anomali/sapan değer sayısını ve bunların gerçekleştiği ilk 3 tarihi yakalıyoruz.
- Göstergenin konfigürasyon dosyasındaki kart bilgilerinden (ad, rol vb.) faydalanarak tanım detaylarını çekiyoruz.
Her gösterge için hesaplanan bu bilgileri (gözlem sayısı, tarih aralıkları, gecikme, eksik oranı, sapan veri detayları vb.) düzenli bir veri çerçevesine dönüştürüyoruz.
En son aşamada ise tüm göstergeler için ayrı ayrı üretilen bu satırları tek bir büyük rapor tablosunda birleştirerek çıktı olarak döndürüyoruz.

kalite_raporu_olustur <- function(uzun) {
bugun <- as.Date(CONFIG$veri$bitis_tarihi)
satirlar <- lapply(unique(uzun$kimlik), function(g) {
f <- gosterge_frekansi(g)
d <- uzun[uzun$kimlik == g, ]; d <- d[order(d$tarih), ]
d$tarih <- donem_basi(d$tarih, f)
kapsam <- length(donem_dizisi(min(d$tarih), max(d$tarih), f))
gecikme <- max(0, length(donem_dizisi(max(d$tarih), max(donem_basi(bugun, f), max(d$tarih)), f)) - 1)
sapan <- hampel_sapan(d$deger)
kart <- CONFIG$gostergeler[[g]]
data.frame(
gosterge = g, ad = varsayilan(kart$ad, g), rol = varsayilan(kart$rol, NA), frekans = f,
gozlem = nrow(d), ilk_tarih = min(d$tarih), son_tarih = max(d$tarih),
gecikme_donem = gecikme, eksik_donem_orani = round(1 - nrow(d) / kapsam, 3),
sapan_sayisi = sum(sapan),
sapan_tarihleri = paste(utils::head(format(d$tarih[sapan], "%Y-%m"), 3), collapse = ", "),
stringsAsFactors = FALSE)
})
do.call(rbind, satirlar)
}

#Bu kod, genel veri tablosundan istediğimiz tek bir göstergeye ait verileri çekip tarih sırasına dizilmiş temiz bir tablo haline getirir.
Veri seti içerisinden belirtilen gösterge koduna ait satırlar filtreler, sadece tarih, değer ve verinin orijinalliğini belirten "gercek" sütunlarını alır. 
Ardından bu kayıtları eskiden yeniye doğru kronolojik olarak sıralar ve filtreleme sonrasında karışan satır numaralarını sıfırlayarak düzenli bir veri çerçevesi sunar.

gosterge_serisi <- function(veri, g) {
d <- veri[veri$gosterge == g, c("tarih", "deger", "gercek"), drop = FALSE]
d <- d[order(d$tarih), , drop = FALSE]
rownames(d) <- NULL
d
}

# Bu kod, modele veya analize sokulacak tek bir göstergenin verisini alıp onun gecikmeli (lag) değerlerini ve isteğe bağlı trend değişkenini içeren hazır bir veri tablosuna dönüştürür.
İşlem öncesinde göstergeye ait gecikme sayısı belirlenmemişse varsayılan değeri çeker ve ilgili göstergeyi seriden filtreler. Veri setinde bu göstergeye ait hiçbir satır bulunamazsa hata vererek çalışmayı durdurur. 
Ardından ana değerlerin yanına istenen sayı kadar geçmiş dönem gecikmesini (lag1, lag2 vb.) sütun olarak ekler; eğer trend parametresi aktifse zamanın akışını temsil eden sıra numaralarını oluşturur. 
Son aşamada gecikme hesaplamalarından ötürü başta oluşan boş (NA) satırları temizler ve satır numaralarını sıfırlayarak modellemeye hazır bir tablo sunar.

gosterge_verisi <- function(veri, g, p = NULL, trend = FALSE) {
p <- varsayilan(p, gosterge_p(g))
d <- gosterge_serisi(veri, g)
if (nrow(d) == 0) stop("Hazır veride yok: ", g, " (gösterge çekilememiş olabilir)", call. = FALSE)
out <- data.frame(tarih = d$tarih)
out[[g]] <- d$deger
for (k in seq_len(p)) out[[paste0(g, "_lag", k)]] <- dplyr::lag(d$deger, k)
if (trend) out$trend <- seq_len(nrow(out))
out <- out[stats::complete.cases(out), , drop = FALSE]
rownames(out) <- NULL
out
}

#Bu kod, sisteme giren ham veriyi alıp uçtan uca işleyen ve analize hazır hale getiren ana veri hazırlama akışını yönetir.
Süreç başladığında ilk olarak sistem günlüğüne akışın başladığını bildiren bir mesaj düşüyoruz. Ardından ham veri içerisindeki her bir göstergeyi kendi özel kodu üzerinden tek tek ayırarak, önceden tanımladığımız seri_hazirla fonksiyonundan geçiriyoruz. Böylece her gösterge kendi frekansına (aylık, çeyreklik vb.) göre temizleniyor, verilerden arındırılıyor ve kesintisiz bir takvime oturtuluyor.
Ayrı ayrı işlenen bu gösterge parçalarını tek bir büyük veri tablosunda birleştirip satır numaralarını sıfırlıyoruz. Sonrasında hazırladığımız bu temiz veri setini ve ham veriden ürettiğimiz kalite raporunu ikili_kaydet fonksiyonu ile sisteme kaydediyoruz.
İşlem tamamlandığında kaç göstergenin işlendiğini, toplam kaç gözlem elde edildiğini ve bunlar içerisinden kaç tanesinin eksik veri tamamlama ile doldurulduğunu log mesajı olarak yazdırıp nihai veri tablosunu döndürüyoruz.

veriyi_hazirla <- function(ham) {
log_msg("Veri hazırlama akışı başladı (her gösterge kendi frekansında)")
parcalar <- lapply(unique(ham$kimlik), function(g) {
seri_hazirla(ham[ham$kimlik == g, c("tarih", "deger")], g)
})
sonuc <- do.call(rbind, parcalar)
rownames(sonuc) <- NULL
ikili_kaydet(sonuc, "hazir_veri")
ikili_kaydet(kalite_raporu_olustur(ham), "kalite_raporu")
log_msg(paste0("Veri hazırlama bitti: ", length(parcalar), " gösterge, ", nrow(sonuc),
" gözlem (interpolasyonla doldurulan: ", ic_bosluk_say(sonuc), "); kaydedildi"))
sonuc
}

# Bu kod, daha önceden işlenip diskte saklanan hazır veriyi getiren veya duruma göre ham kaynaklardan yenileyip sıfırdan oluşturan önbellek (cache) mekanizmasını yönetir.
Sistem öncelikle hedef dosya yolunu belirler ve diskte var olan RDS dosyasını okumaya çalışır. Dosya okunurken geçerli sütun yapısına ("gosterge", "tarih", "deger", "gercek") sahip olup olmadığını kontrol eder; dosya bozuksa veya eski formatta kalmışsa bunu geçersiz sayarak uyarı günlüğü düşer.
Mevcut dosyanın yaşını konfigürasyondaki güncelleme sıklığı ile karşılaştırarak verinin "taze" olup olmadığını belirler. Eğer dosya geçerliyse, kullanıcı zorla yenileme istemediyse (`yenile = FALSE`) ve veri taze ise (ya da otomatik güncelleme kapalıysa), zaman kazanmak adına direkt bu diskteki veriyi döndürür.
Veri yoksa, bayatlamışsa veya yenileme talep edildiyse, tüm göstergeleri internet/kaynak üzerinden çekmeye çalışır. Veri çekme aşamasında bir ağ/API hatası yaşanırsa ve elimizde önceden kalan bir veri varsa sistemi çökertmemek için eski veriyi koruyarak döndürür; hiç veri yoksa çalışmayı durdurup hata fırlatır. Çekim başarılı olduysa `veriyi_hazirla` akışını tetikleyip güncel veriyi işler, kaydeder ve sunar.

hazir_veriyi_getir <- function(yenile = FALSE) {
yol <- file.path(CONFIG$saklama$processed_klasoru, "hazir_veri.rds")
  # Eski sürümün (geniş, aylık) kaydı ya da bozuk dosya "hazır veri" sayılmaz: yeniden üretilir.
oku <- function() {
x <- if (file.exists(yol)) tryCatch(readRDS(yol), error = function(e) NULL) else NULL
if (is.data.frame(x) && all(c("gosterge", "tarih", "deger", "gercek") %in% names(x))) x else NULL
}
mevcut <- oku()
if (file.exists(yol) && is.null(mevcut)) {
log_msg("Kayıtlı hazır veri eski/bozuk biçimde; yeniden oluşturuluyor", "UYARI")
}
taze <- !is.null(mevcut) && dosya_yasi_gun(yol) <= varsayilan(CONFIG$guncelleme$sikligi_gun, 1)
if (!is.null(mevcut) && !yenile && (taze || !isTRUE(CONFIG$guncelleme$otomatik))) {
log_msg("Hazır veri bulundu, kullanılıyor")
return(mevcut)
}
log_msg(if (yenile) "Veri yenileniyor (kaynaklar)" else "Hazır veri bayat/yok; kaynaklardan güncelleniyor")
ham <- tryCatch(tum_gostergeleri_cek(yenile = yenile), error = function(e) {
log_msg(paste("Çekim hatası:", conditionMessage(e)), "HATA"); NULL })
if (is.null(ham)) {
if (!is.null(mevcut)) {
log_msg("Güncelleme başarısız; mevcut hazır veri korunuyor", "UYARI")
return(mevcut)
}
stop("Hazır veri yok ve hiçbir gösterge çekilemedi (anahtarları/bağlantıyı kontrol et)")
}
veriyi_hazirla(ham)
}

# Bu kod, betiğin en sonunda çalışan ve tanımlanan tüm veri hazırlama fonksiyonlarının belleğe eksiksiz yüklenip yüklenmediğini denetleyen bir doğrulama testidir.
Süreç başladığında ilk olarak sistemde bulunması gereken 8 temel fonksiyonun ("seri_hazirla", "hampel_sapan", "veriyi_hazirla" vb.) isimlerinden oluşan bir liste hazırlarız.
Ardından `sapply` yardımıyla bu fonksiyonların çalışma ortamında (environment) gerçek birer fonksiyon olarak var olup olmadığını tek tek kontrol eder ve eksik olanların listesini çıkarırız.
Eğer listeden yüklenememiş veya tanımlanmamış en az bir fonksiyon bile çıkarsa, kod akışı `stop` ile durdurulur ve hangi fonksiyonların eksik olduğunu belirten net bir hata mesajı yazılır.
Tüm fonksiyonlar eksiksiz ve sağlıklı bir şekilde yüklendiyse, onay mesajı basılarak dosyanın kullanıma hazır olduğu bildirilir. Tüm bu işlemler `local()` bloğu içerisinde yürütüldüğü için süreç boyunca oluşturulan geçici değişkenler ana çalışma ortamını kirletmeden temizlenir.

local({
fonksiyonlar <- c("seri_hazirla", "ic_bosluk_say", "hampel_sapan", "kalite_raporu_olustur",
"gosterge_serisi", "gosterge_verisi", "veriyi_hazirla", "hazir_veriyi_getir")
eksik <- fonksiyonlar[!sapply(fonksiyonlar, exists, mode = "function")]
if (length(eksik) > 0) {
stop("[data.prep.R] Eksik fonksiyon: ", paste(eksik, collapse = ", "))
}
message("[data.prep.R] Veri hazırlama yüklendi: ", length(fonksiyonlar), " fonksiyon yerinde. ✔")
})
})
