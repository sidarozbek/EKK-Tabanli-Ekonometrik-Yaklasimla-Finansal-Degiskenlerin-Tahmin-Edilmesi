# 2209-A Sonuç Raporu – Başlık İskeleti

## Kapak ve Genel Bilgiler

- Proje başlığı (öneriyle birebir aynı): EKK Tabanlı Ekonometrik Yaklaşımla Finansal Değişkenlerin Tahmin Edilmesi
- Proje yürütücüsü: Melek Sevimli
- Proje ortakları: Sidar Özbek, Elif Zeynep Balıkçı, Arzu Gülnur Okman, Elif Işıl Çiçek
- Akademik danışman: Tolga Omay
- Kurum: Atılım Üniversitesi, İktisat Bölümü
- Proje numarası: (e-BİDEB'den alınacak)
- Proje başlangıç ve bitiş tarihi: (e-BİDEB'den alınacak)
- Not: Kapakta TÜBİTAK logosu kurumsal kimlik standartlarına uygun kullanılmalı.

**Açık soru:** Resmi "2209-A Sonuç Raporu Formatı" şablonu indirilip kapak alanları ona göre düzeltilecek.

## Özet (250–350 kelime, en son yazılacak)

Özet öneri özetindeki dört unsuru geçmiş zamanla ve sayılarla karşılar: bilimsel nitelik, yöntem, proje yönetimi, yaygın etki.

1. Problem ve amaç: 1–2 cümle
2. Yöntem: 5 kaynak, 21 gösterge, kayan pencereli AR-EKK, çapraz doğrulamayla (p, w) seçimi
3. Temel bulgu: kaç göstergede göreli RMSE < 1, en başarılı ve en başarısız göstergeler
4. Hipotezlerin durumu: H1, H2, H3 için tek cümle
5. Çıktılar: Shiny uygulaması, GitHub deposu, varsa bildiri

**Anahtar kelimeler:** Ekonomik Tahmin, Zaman Serisi Analizi, EKK, Kayan Pencere, Yapısal Kırılma, Açık Veri

## 1. Giriş (2 sayfa)

### 1.1 Konunun Önemi ve Problem Tanımı

Türkiye göstergelerindeki yüksek oynaklık ve sabit parametreli modellerin kırılmalar karşısındaki zayıflığı. Öneri 1.1'in kısaltılmış, güncellenmiş hali.

### 1.2 Literatür

- Yapısal kırılma ve parametre istikrarsızlığı (Görev 1)
- Pencere seçimi: Pesaran ve Timmermann (2007), Rossi ve Inoue (2012)
- Türkiye için tahmin çalışmaları ve karar destek araçları (Görev 4)
- Literatürdeki boşluk: açık kaynaklı, sürekli güncellenen, web tabanlı bir AR-EKK sistemi

### 1.3 Araştırma Sorusu ve Hipotezler

Araştırma sorusu ve H1–H3 öneriyle birebir aynı ifadelerle yazılır; değerlendirmesi Bölüm 4.1'de yapılır.

### 1.4 Amaç ve Hedefler

Hedef 1–6 öneriden aynen aktarılır; her hedefin karşılandığı rapor bölümü parantez içinde gösterilir (ör. Hedef 2 → 3.4, 4.2).

## 2. Yöntem (4,5 sayfa)

### 2.1 Araştırma Tasarımı ve Sistem Mimarisi

Üç aşamalı tasarım (veri → model → web) ve README'deki altı katmanlı mimari şeması.

### 2.2 Veri Kaynakları ve Yedekleme Zinciri

- 5 kaynak: TCMB EVDS, FRED, Dünya Bankası, OECD, Yahoo Finance (BIST)
- 21 gösterge: 6 bağımlı, 4 kontrol, 11 ek (rol tablosu)
- Yedekleme zinciri ve tür/frekans uyumluluk filtresi
- Metodoloji ve baz yılı değişiklikleri (Görev 3)

### 2.3 Veri Hazırlama ve Kalite Kontrolü

Kendi frekansında kesintisiz takvim, doğrusal enterpolasyon, yıllık değişim dönüşümü, mevsimsellik notu (Görev 3).

### 2.4 Durağanlık Analizi

ADF ve KPSS sonuçları; düzey seriler için dönüşüm kararı (Görev 2). Öneride olmayan, izleyicinin soracağı yeni alt bölüm.

### 2.5 AR Modeli ve EKK Tahmincisi

AR(p) denklemi ve EKK kapalı form çözümü; formüller README'den.

### 2.6 Kayan Pencere Yaklaşımı

Pencere tanımı, naif kıyas modeli, örnek dışı tahmin mantığı.

### 2.7 Model Seçimi

AIC, BIC ve çapraz doğrulamayla (p, w) seçimi; aday ızgarası ve seçim kuralı.

### 2.8 Performans Ölçütleri ve Anlamlılık Testi

MAE, RMSE, MAPE, Theil U, göreli RMSE; Diebold-Mariano testi (Görev 2). "Doğruluk" başarı ölçütünün tanımı burada yapılır (ör. göreli RMSE < 1).

### 2.9 Yazılım Altyapısı ve Web Arayüzü

R paketleri, Shiny mimarisi, GitHub ve renv ile tekrarlanabilirlik.

## 3. Bulgular (6 sayfa)

Raporun ağırlık merkezi; her alt bölüm bir tablo veya grafik etrafında kurulur, metin onu yorumlar.

### 3.1 Veri Toplama Sonuçları

- Tablo: kalite raporu (gözlem sayısı, tarih aralığı, eksik dönem oranı)
- Tablo: metaveri özeti (hangi gösterge hangi kaynaktan, kaçında yedek kullanıldı)
- EVDS ve FRED karşılaştırma grafiği (Görev 3)

### 3.2 Model Seçimi Sonuçları

Tablo: gösterge başına seçilen p ve w, seçim yöntemi (capraz\_dogrulama tablosundan).

### 3.3 Örnek Dışı Tahmin Performansı

- Tablo: tahmin\_ozeti (RMSE, MAPE, Theil U, göreli RMSE), göreli RMSE'ye göre sıralı
- Diebold-Mariano test sonuçları (Görev 2)
- Seçimden bağımsız dönemlerle sağlamlık kontrolü

### 3.4 Yapısal Kırılmalar ve Tahmin Hataları

Bai-Perron sonuçları ve kırılma tarihleri işaretli hata grafikleri: enflasyon, USD/TRY, büyüme (Görev 1).

### 3.5 Seçilmiş Göstergelerde Tahmin Grafikleri

Enflasyon, USD/TRY, büyüme ve işsizlik için gerçek, tahmin ve naif seriler.

### 3.6 İleriye Dönük Tahminler ve Beklenti Anketiyle Kıyas

6 dönemlik tahminler; TCMB Piyasa Katılımcıları Anketi beklentileriyle karşılaştırma (Görev 4).

### 3.7 Web Arayüzü ve Kullanılabilirlik Testi

Ekran görüntüleri, SUS anketi sonucu, katılımcı sayısı (Görev 4).

## 4. Tartışma (2 sayfa)

### 4.1 Hipotezlerin Değerlendirilmesi

| Hipotez | Sonuç | Dayanak |
| --- | --- | --- |
| H1: AR-EKK veri örüntülerini anlamlı açıklar | (desteklendi / kısmen / desteklenmedi) | 3.3, DM testi |
| H2: Web sistemi esneklik ve güncelleme hızı sunar |  | 3.1, 3.7 |
| H3: Sistem pratik ve sürdürülebilir çıktı üretir |  | 3.6, 3.7 |

### 4.2 Göstergeler Arası Farklar

Modelin naif tahmini hangi göstergelerde geçtiği, hangilerinde geçemediği ve nedeni: kırılmalar, durağan olmama, mevsimsellik.

### 4.3 Literatürle Karşılaştırma

Pencere uzunluğu bulgularının Pesaran ve Timmermann (2007) ile Rossi ve Inoue (2012) ile uyumu.

### 4.4 Kısıtlar

- Çapraz doğrulama ve değerlendirme dönemlerinin çakışması (README metodolojik notu)
- Gerçek zamanlı veri yerine revize veri kullanımı
- Enterpolasyonla doldurulan dönemler ve yaklaşık yedek seriler
- Tek değişkenli model: kontrol değişkenleri modele girmedi

## 5. Proje Yönetimi (1,5 sayfa)

### 5.1 Çalışma Takvimine Uyum

Öneri takvimindeki dört satır, gerçekleşenle yan yana:

| Planlanan faaliyet | Plan tarihi | Gerçekleşen tarih | Başarı ölçütü | Ulaşılan değer |
| --- | --- | --- | --- | --- |
| Veri toplama altyapısı | 01.03–30.04.2026 |  | ≥ 4 API, ≥ 15 gösterge | 5 kaynak, 21 gösterge |
| Model tahminleri ve performans analizi | 01.05–30.06.2026 |  | ≥ 5 göstergede %70 doğruluk, ≥ 3 metrik |  |
| Shiny web uygulaması | 01.09–31.10.2026 |  | ≥ 5 gösterge, ≥ %80 kullanıcı memnuniyeti |  |
| Testler, dokümantasyon, raporlama | 01.11–31.12.2026 |  | Hatasız sistem, tam dokümantasyon |  |

### 5.2 Öneriden Sapmalar ve Gerekçeleri

- 15 yerine 21 gösterge; Yahoo Finance/BIST eklenmesi
- Çapraz doğrulamayla (p, w) seçimi
- ARIMA, VAR, makine öğrenmesi kullanılmaması
- Önerideki araçlardan (RSQLite, Shiny Server vb.) kullanılmayanlar

### 5.3 Gerçekleşen Riskler ve Uygulanan B Planları

Öneri risk tablosundaki Risk 1–6'dan hangilerinin yaşandığı; örneğin Risk 1 için çok kanallı yedekleme zinciri.

## 6. Sonuç, Yaygın Etki ve Öneriler (1 sayfa)

### 6.1 Sonuç

Araştırma sorusuna tek paragraflık net yanıt, temel sayılarla.

### 6.2 Yaygın Etki ve Çıktılar

- Bilimsel: bildiri veya makale (başlık, kongre/dergi, durum)
- Teknik: GitHub deposu bağlantısı, Shiny uygulaması bağlantısı
- Eğitim: ekip üyelerinin kazandığı yetkinlikler
- TÜBİTAK desteğinin tüm çıktılarda belirtildiği notu

### 6.3 Gelecek Çalışmalar

VAR ve kontrol değişkenli modeller, makine öğrenmesi karşılaştırması, gerçek zamanlı veri ile yeniden değerlendirme, olası 1001 projesi.

## Kaynakça ve Ekler

### Kaynakça

APA formatı; yalnızca metinde atıf yapılan ve ekipçe okunmuş kaynaklar. Öneri kaynakçasındaki konu dışı kaynaklar (Beck vd. 2020, Ben-Akiva vd. 2019, Vududala 2025) çıkarılacak.

### Ekler

- Ek A: Tüm göstergeler için tam performans tablosu
- Ek B: Çapraz doğrulama ızgarası
- Ek C: Durağanlık ve kırılma testlerinin tam çıktıları
- Ek D: Kullanılabilirlik anketi formu ve sonuçları
- Ek E: Kod deposu yapısı ve çalıştırma talimatı (README özeti)
- Ek F: Etik kurul belgesi veya muafiyeti (gerekiyorsa)
