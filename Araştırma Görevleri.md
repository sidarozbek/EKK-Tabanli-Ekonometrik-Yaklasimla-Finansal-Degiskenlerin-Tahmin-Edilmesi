
---
## Görev 1: Yapısal kırılmalar ve Türkiye ekonomisi (Hedef 2)

**Kişi:** Elif Işıl Çiçek  
**Hedef:** Giriş (literatür), Tartışma (H1 ve H2)

>**Hatırlatma:** 
> 
  **H1:** Kayan pencere yaklaşımı ile güncellenen AR-EKK modeli, ekonomik göstergelerdeki veri örüntülerini anlamlı düzeyde açıklamaktadır. 
> 
  **H2:** Geliştirilen webtabanlı tahmin sistemi, model esnekliği ve güncelleme hızı açısından veri temelli politika analizleri için uygun öngörü performansı sunmaktadır.
  > 
  **Hedef 2:** Yapısal kırılmalara ve nonlineer dinamiklere uyum sağlayabilen kayan pencere yaklaşımı ile Otoregresif (AR) modelleri En Küçük Kareler (EKK) yöntemi kullanarak tahmin etmek ve bu modellerin farklı dönemlerdeki ekonomik dinamikleri yakalama kapasitesini değerlendirmek.

**Teorik sorular**

- Yapısal kırılma nedir? Ortalamada, varyansta ve katsayılarda kırılma arasındaki fark ne?
- Sabit parametreli bir AR modeli kırılma karşısında neden bozulur? Kayan pencere bu sorunu nasıl hafifletir, bedeli ne? Burada yanlılık ile varyans arasındaki ödünleşim (bias–variance trade-off) önemli.
- Kırılma testleri hangileri? Chow (1960) bilinen tarih için, Bai-Perron (1998, 2003) bilinmeyen ve çoklu kırılma için, CUSUM/MOSUM ve Zivot-Andrews (1992) kırılmalı birim kök testi için kullanılıyor.

**Türkiye'ye özgü araştırma**  
Aşağıdaki dönemleri doğrulayıp her birinin hangi göstergeyi nasıl etkilediğini gösteren bir tablo hazırlasın. Liste bir başlangıç noktası, tarihleri ve etkileri kendisi kaynaklardan teyit etmeli:

|Dönem|Olay|Beklenen etkilenen seriler|
|---|---|---|
|Şubat 2001|Bankacılık krizi, dalgalı kura geçiş|USD/TRY, faiz, büyüme|
|2002–2006|Enflasyon hedeflemesine geçiş, 2005'te altı sıfırın atılması|TÜFE, kur, M2|
|2008–2009|Küresel finansal kriz|Büyüme, sanayi üretimi, dış ticaret|
|Mayıs 2013|Fed'in parasal sıkılaştırma sinyali ("taper tantrum")|Kur, BIST-100|
|2016|Darbe girişimi|Turizm, büyüme, güven endeksleri|
|Ağustos 2018|Kur krizi|Kur, TÜFE, ÜFE, faiz|
|2020|COVID-19|Büyüme, işsizlik, turizm, kapasite kullanımı|
|Eylül 2021 – 2023|Faiz indirimleri, KKM, enflasyonun yüzde 80'leri aşması|TÜFE, kur, faiz, konut fiyatları|
|Haziran 2023 sonrası|Para politikasında normalleşme|Faiz, kur, enflasyon|
|Mart 2025|Finansal piyasalarda ani dalgalanma|Kur, BIST-100, faiz|

**Uygulama (R)**

- `strucchange` paketiyle en az enflasyon, USD/TRY ve büyüme için Bai-Perron testi yapılsın. Bulunan kırılma tarihleri yukarıdaki olaylarla karşılaştırılsın.
- Bu kırılma tarihleri, kayan pencere tahmin hatası grafiklerinin üzerine dikey çizgi olarak işaretlensin. Hatanın kırılmadan sonra sıçrayıp sıçramadığı ve pencerenin kaç dönemde "toparlandığı" incelensin.

**Teslim:** 2 sayfalık metin, kırılma tablosu, 3 grafik.

---

## Görev 2: Tahmin değerlendirme teorisi ve model geçerliliği (Hedef 3, H1)

**Kişi:** Melek Sevimli, Sidar Özbek 
**Hedef:** Yöntem 2.4–2.7, Bulgular 3.3, Tartışma

>**Hatırlatma:** 
> 
  **Yöntem 2.4. En Küçük Kareler (EKK) Tahmincisi**
  AR modelinin parametreleri, En Küçük Kareler (EKK) yöntemiyle tahmin edilecektir. EKK tahmincisi, hata kareler toplamını minimize eden parametre değerlerini bulmayı amaçlar: 
>  
>EKK tahmincisi, Gauss-Markov Teoremi altında En İyi Doğrusal Tarafsız Tahmin Edici (BLUE - Best Linear Unbiased Estimator) özelliğine sahiptir (Wooldridge, 2016). Bu özellik, doğru model varsayımları altında EKK tahmincisinin en küçük varyansa sahip olmasını garanti eder.
>
  **Yöntem 2.7. Tahmin Performansı Değerlendirme**
  Modelin öngörü performansı, aşağıdaki metrikler kullanılarak değerlendirilecektir:
  >
>- Ortalama Mutlak Hata (MAE)
>- Ortalama Kare Hata (MSE)
>- Kök Ortalama Kare Hata (RMSE)
>- Ortalama Mutlak Yüzde Hata (MAPE)
>- Theil U İstatistiği

**Teorik sorular**

- **Durağanlık:** AR modeli durağan seri varsayar. USD/TRY, BIST-100, M2 ve konut fiyatı gibi düzey seriler büyük olasılıkla durağan değil. ADF ve KPSS testleri yapılsın. Sonuca göre bu serilerin logaritmik farkla mı modellenmesi gerektiği tartışılsın. Bu, raporda izleyicinin en çok sorabileceği nokta.
- **Naif modeli geçmek yeterli mi?** Göreli RMSE'nin 1'in altında olması istatistiksel olarak anlamlı mı? Bunun için Diebold-Mariano (1995) testi uygulansın. İç içe modeller için Clark-West (2007) da araştırılsın.
- **Kayan ya da genişleyen pencere:** Pesaran ve Timmermann (2007) ile Rossi ve Inoue (2012) ne diyor? Projede genişleyen pencereyle (expanding window) küçük bir karşılaştırma yapılabilir mi?
- **Metrik sorunları:** MAPE, sıfıra yakın ya da negatif değer alan serilerde bozuluyor. Büyüme, dış ticaret dengesi, cari denge ve bütçe dengesi bu durumda. Hyndman ve Koehler (2006) ile alternatif olarak MASE araştırılsın.
- **Seçim yanlılığı:** Çapraz doğrulama dönemlerinin değerlendirme dönemleriyle çakışabilir. Bunun sonuçları ne kadar iyimser gösterdiği, son 12 dönemi tamamen dışarıda tutan bir test ile ölçülsün.

**Teslim:** Gösterge bazında durağanlık tablosu, DM testi sonuç tablosu, 2 sayfalık metin.

---

## Görev 3: Veri, ölçüm ve kaynak tutarlılığı (Hedef 1, Hedef 6)

**Kişi:** Arzu Gülnur Okman  
**Hedef:** Yöntem 2.2–2.3, Bulgular 3.1, Kısıtlar

>**Hatırlatma:** 
> 
  **Hedef 1:** FRED, TCMB EVDS, OECD ve Dünya Bankası gibi açık kaynaklı veri tabanlarından API entegrasyonu ile otomatik veri çekme altyapısı kurmak ve Türkiye'ye ait makroekonomik, finansal ve sektörel göstergelerin sürekli güncellenebilir bir veri setini oluşturmak.
> 
  **Hedef 6:** Açık veri ve tekrarlanabilirlik ilkeleri doğrultusunda, tüm veri kaynakları, model parametreleri ve güncellenme süreçlerinin şeffaf biçimde dokümante edilmesi ve gelecekteki çalışmalar için sürdürülebilir bir altyapı oluşturulması.
 > 
  **Yöntem 2.2. Değişkenler**
 >
>- Bağımlı Değişkenler
>- Bağımsız Değişkenler
>- Kontrol Değişkenleri
  >
>**Yöntem 2.3. Otoregresif (AR) Model Yapısı**
>
>Otoregresif model, bir değişkenin gelecek değerinin kendi geçmiş değerlerinin doğrusal bir fonksiyonu olarak ifade edildiği bir zaman serisi modelidir. p dereceden bir AR modeli, AR(p) şeklinde gösterilir

**Araştırma soruları**

- **Metodoloji ve baz yılı değişiklikleri:** Model veride ekonomik olmayan, istatistiksel kırılmalar da görür. Aşağıdakiler doğrulansın:
    - TÜFE'de baz yılı değişikliği (seri kodunda 2025 bazı görünüyor)
    - GSYH'de 2016 revizyonu ve 2009 bazına geçiş
    - İşsizlikte 2014 ve 2021 tanım ve metodoloji değişiklikleri
    - Sanayi üretiminde 2021 bazı
    - Politika faizinin tanımı (2010'dan itibaren bir hafta vadeli repo, faiz koridoru dönemi)
- **Gerçek zamanlı veri ve revizyonlar:** Bugün indirilen GSYH, o dönemde açıklanan GSYH ile aynı değil. Croushore ve Stark (2001) ile ALFRED (FRED'in arşiv versiyonu) araştırılsın. Bu, raporda önemli bir kısıt olarak yazılmalı.
- **Kaynaklar arası tutarlılık:** Aynı gösterge EVDS ve FRED'den çekilip karşılaştırılsın (fark grafiği ve korelasyon). Yedekleme zincirinin "yaklaşık" seri kullandığı durumlarda hata ne kadar büyük?
- **Mevsimsellik:** Sanayi üretimi, turizm ve dış ticaret serileri mevsimsellikten arındırılmış mı? Arındırılmamışsa AR(12)'nin bunu nasıl yakaladığı açıklansın. TCMB ve TÜİK'in kullandığı X-13/TRAMO yöntemleri araştırılsın.
- **Enterpolasyonun etkisi:** Kalite raporundan kaç dönemin doldurulduğu çıkarılsın. Doldurulan dönemler çıkarıldığında metriklerin değişip değişmediği test edilsin.

**Teslim:** Metodoloji değişiklikleri tablosu, kaynak karşılaştırma grafiği, 1,5 sayfalık metin.

---

## Görev 4: Karar destek sistemi, kullanılabilirlik ve dış karşılaştırma (Hedef 4, Hedef 5)

**Önerilen kişi:** Elif Zeynep Balıkçı  
**Beslediği bölüm:** Bulgular 3.6, Yaygın etki, Proje yönetimi (başarı ölçütü)

**Araştırma soruları**

- **Kullanılabilirlik testi:** Önerideki "%80 üzeri memnuniyet" sözünü karşılamak için System Usability Scale (Brooke, 1996) araştırılsın. 8–10 kişiyle küçük bir test tasarlanıp uygulansın: iktisat öğrencileri ve teknik olmayan kullanıcılar. Bu, şu an raporda en büyük açık olabilir.
- **Benzer araçlar:** Atlanta Fed GDPNow, NY Fed Nowcast, TCMB'nin veri araçları gibi sistemler incelensin. Projenin bunlardan farkı ne (açık kaynak, Türkiye odaklı, yedekli veri)?
- **Profesyonel beklentilerle kıyas:** TCMB Piyasa Katılımcıları Anketi'ndeki enflasyon ve kur beklentileri ile modelin tahminleri aynı dönemler için karşılaştırılsın. Bu, "naif modeli geçti" demekten çok daha güçlü bir bulgu olur.
- **Tekrarlanabilirlik:** `renv`, GitHub yayını ve açık bilim ilkeleri (Hedef 6) için kısa bir değerlendirme yapılsın.

**Teslim:** SUS anket sonuçları, ekran görüntüleri, model ile anket beklentisi karşılaştırma tablosu, 1,5 sayfalık metin.

---

## Ekip için ortak kurallar

- **Tek format:** Kaynaklar APA formatında olsun ve **her kaynağı kendisi açıp okusun**. Yukarıdaki kaynak isimleri birer başlangıç noktası.
- **Takvim önerisi:** İlk taslaklar 31 Ekim'e, düzeltilmiş hali 15 Kasım'a. Ben birleştirme ve tutarlılık kontrolünü Kasım sonuna kadar yaparım, böylece danışmana Aralık başında okuma süresi kalır.
- **Kod:** Her analiz `analysis/` klasöründe ayrı bir R Markdown dosyası olsun ve depoya eklensin. Böylece rapordaki her sayı tekrarlanabilir olur.
- **Görevler arası bağlar:** Görev 1'in kırılma tarihleri Görev 2'nin hata analizinde kullanılacak. Görev 3'ün metodoloji değişiklikleri de Görev 1'in "bu kırılma ekonomik mi, istatistiksel mi" ayrımını besleyecek.