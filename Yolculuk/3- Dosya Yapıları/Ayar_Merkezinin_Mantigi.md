# Rehber 1 — Neden Her Şeyden Önce Bir "Ayar Merkezi" Kuruyoruz?

> Bu belge, projenin ilk gerçek parçası olan **ayar merkezini** (config) neden kurduğumuzu anlatır. İçinde tek bir komut yoktur. Amaç, "şunu yaz" demek değil, **"bu merkez neden var, olmasaydı ne olurdu"** sorusuna cevap vermektir.
>
> Önceki rehberde boş ama düzenli bir tezgâh kurmuştuk. Şimdi o tezgâha koyacağımız ilk şey, hiç iş yapmayan ama her işin başvuracağı bir parça: ayarların toplandığı merkez.

---

## Önce sezgisel itiraz: "Ayarları neden ayrı tutalım?"

Yeni başlayan biri haklı olarak şunu sorabilir:

> "Madem program internetten veri çekecek, neden hangi adresten çekeceğini doğrudan veri çekme koduna yazmıyoruz? Ayarı kullanıldığı yere yazmak daha mantıklı değil mi?"

İlk bakışta öyle görünür. Ama bir benzetme bu fikrin neden tehlikeli olduğunu gösterir.

Bir **restoran** düşün. Tuzun ne kadar konacağı, fırının kaç derece olacağı, porsiyonun ne büyüklükte olacağı gibi kararlar var. İki ihtimal:

1. **Her aşçı kendi kafasına göre karar verir.** Biri bol tuz atar, diğeri az; biri fırını 180'e, diğeri 220'ye ayarlar. Sonuç: aynı yemek her seferinde farklı çıkar ve bir şeyi değiştirmek istediğinde her aşçıya tek tek gitmen gerekir.

2. **Tek bir "reçete kartı" vardır.** Tuz miktarı, fırın derecesi, porsiyon — hepsi orada yazılıdır. Herkes ona bakar. Bir şeyi değiştirmek istersen, **tek bir kartı** güncellersin, mutfağın tamamı otomatik uyar.

İşte ayar merkezi, bu ikinci yaklaşımdır. Projedeki tüm kararları **tek bir kartta** toplar.

---

## Gereklilik 1 — Dağınık kararlar tek bir yerde toplanmalı

Bir projede, koda gömülmek isteyen onlarca küçük karar vardır:

- Hangi internet adreslerinden veri çekeceğiz?
- Veriyi hangi tarihten itibaren isteyeceğiz?
- Bir bağlantı kaç saniye beklesin, sonra pes etsin?
- Model geçmişe kaç adım baksın?
- Verinin ne kadarı öğrenme, ne kadarı sınama için ayrılsın?

Bu kararların her biri, projenin **birçok farklı yerinde** işe yarar. Eğer her biri kullanıldığı yere ayrı ayrı yazılırsa, aynı karar projeye onlarca kez serpiştirilmiş olur.

Şimdi bir gün "veriyi 2015 yerine 2010'dan itibaren çekelim" demek istediğini düşün. Eğer bu tarih kodun 15 ayrı yerine dağılmışsa, 15 yeri tek tek bulup değiştirmen gerekir. Birini kaçırırsan, projenin bir kısmı 2015'i, bir kısmı 2010'u kullanır — ve bu tür tutarsızlıklar en sinir bozucu hataları doğurur.

Ayar merkezi bunu çözer:

> **Her karar tek bir yerde yazılır. Değiştirmek istediğinde tek bir noktaya dokunursun, projenin tamamı uyar.**

### Bu fikrin adı

Programcılar koda öylece serpiştirilmiş, nereden geldiği belirsiz sayı ve adreslere **"sihirli sayılar"** der — çünkü kodun ortasında bir `30` görürsün ama "bu 30 da neyin nesi?" diye sorarsın. Ayar merkezi, tüm bu sihirli sayılara bir **isim ve ev** verir. Artık `30` değil, "bağlantı zaman aşımı: 30 saniye" diye anlamlı bir şey okursun.

---

## Gereklilik 2 — Sırlar ayarların içinde ama görünmez olmalı

Önceki rehberde gizli anahtarları koruma altına almıştık. Şimdi bir incelik var: Bu anahtarlar **ayarların bir parçası** (çünkü "şu servise şu anahtarla gir" de bir ayardır), ama yine de **görünür olmamalı.**

Bunu nasıl çözeriz? Ayar merkezi anahtarın **kendisini** taşımaz; bunun yerine, anahtarın saklandığı gizli kasadan onu **o an çağırır.** Yani ayar merkezinde "anahtar şudur: ABC123" yazmaz; "anahtarı gizli kasadan al" yazar.

Bir benzetme: Reçete kartında "kasadaki yedek anahtarı kullan" yazar, kasanın şifresini kartın üstüne yazmazsın. Kart herkese gösterilebilir çünkü sırrı içinde taşımıyor, sadece sırrın **nerede olduğunu** biliyor.

### Neden bu kadar dikkat?

Çünkü ayar merkezi, projenin **paylaşılabilir** kısmıdır — başkaları görsün, incelesin diye. Eğer sırrı doğrudan içine yazsaydık, paylaşıldığı an sır da sızardı. "Sırrı tut ama gösterme" dengesi böyle kurulur.

> 🔑 **Özet:** Ayarlar herkese açık olabilir; ama sırlar ayarların içinde **değer olarak değil, adres olarak** durur. Kart paylaşılır, kasa paylaşılmaz.

---

## Gereklilik 3 — Karar vermeden önce keşfetmek

Bu rehberin en güzel fikirlerinden biri şu: Ayar merkezine "hangi verileri kullanacağız" yazmadan **önce**, kısa bir **keşif** yapıyoruz.

Neden? Çünkü bu proje "Türkiye'nin finansal göstergelerini tahmin etmek" üzerine. Ama aynı göstergenin (örneğin işsizlik) birden çok kaynağı var: bir kaynak ABD'nin işsizliğini verir, başka bir kaynak Türkiye'ninkini. İkisi farklı sayılardır, farklı sıklıkta gelir.

Eğer kör bir şekilde ayarlara rastgele bir kaynak yazsaydık, projeye yanlış ülkenin verisi girebilirdi — ve bu hatayı çok sonra, her şey kurulmuşken fark ederdik.

Bunun yerine, **önce iki kaynağı yan yana koyup farkı gözümüzle görüyoruz.** "Bu kaynak ABD'yi, şu kaynak Türkiye'yi veriyor; projemiz Türkiye olduğu için şunu seçiyoruz" diyerek **bilinçli bir karar** veriyoruz.

Bir benzetme: Bir tarif için elma alacaksın. Markete gidip "elma" deyip ilk gördüğünü kapmazsın; iki çeşidi eline alıp "bu tatlı, bu ekşi; benim tarifim için ekşi olan lazım" dersin. Keşif, kararı **isabetli** kılar.

> 🔍 **Özet:** Ayarlara bir şey yazmadan önce, seçeneklerin ne olduğunu gözümüzle görür, sonra bilinçli seçeriz. Körlemesine yazılan ayar, sonradan en pahalı hataya dönüşür.

---

## Gereklilik 4 — Ayarlar mantıklı gruplara bölünmeli

Tüm kararları tek bir merkeze topluyoruz, ama bu merkez de kendi içinde **düzenli** olmalı. Yüzlerce ayarı tek bir uzun listeye dökersek, içinde kaybolur.

Bu yüzden ayarları **konularına göre kümeleriz:**

- **Bağlantı ayarları** — internetteki kaynaklara nasıl ve nereden ulaşacağımız
- **Veri ayarları** — hangi göstergeleri, hangi tarihten, hangi sıklıkta isteyeceğimiz
- **Model ayarları** — tahmin yönteminin nasıl davranacağı
- **Saklama ve kayıt ayarları** — geçici verinin nerede tutulacağı, kayıtların nasıl yazılacağı

Bir benzetme: Bir dolabın gözleri gibi. Hepsi aynı dolapta (tek merkez), ama çoraplar bir gözde, gömlekler başka gözde. Bir gömlek ararken çorapların arasını karıştırmazsın. Ayar merkezinin içindeki bu gruplama da, "bağlantıyla ilgili bir şey mi arıyorum, modelle ilgili mi" sorusunu anında çözer.

### Özellikle akıllı bir detay: her göstergenin kendi kimliği

Bu projede çok hoş bir fikir var. Her ekonomik gösterge, ayarların içinde sadece adıyla değil, **"hangi kaynaktan ve hangi kodla çekileceği" bilgisiyle birlikte** durur. Yani gösterge kendi "kimlik kartını" taşır.

Bunun faydası ileride ortaya çıkacak: Veri çeken kod, "enflasyon nereden gelir, faiz nereden gelir" diye düşünmek zorunda kalmaz. Sadece ayarlara bakar, göstergenin kimlik kartını okur ve doğru kaynağa gider. Karmaşık karar, tek bir yere (ayarlara) hapsedilmiş olur.

> 🗂️ **Özet:** Tek merkez, ama içi konularına göre düzenli. Her ayar mantıklı bir kümede durur; her gösterge kendi kaynağını ve kodunu yanında taşır.

---

## Gereklilik 5 — Merkez kurulunca "gerçekten kuruldu mu?" diye sormak

Önceki rehberdeki alışkanlık burada da var. Ayar merkezini kurduktan sonra, dolu olduğuna **inanmakla yetinmiyoruz** — kontrol ediyoruz.

İki şeyi doğruluyoruz:

1. **Beklediğimiz sayıda gösterge var mı?** Beş gösterge yazdıysak, gerçekten beşi de orada mı, yoksa biri yazarken mi düştü?
2. **Bütün ayar kümeleri yerinde mi?** Bağlantı, veri, model, saklama, kayıt — hepsi dolu mu, yoksa biri boş mu kaldı?

Eğer bir küme eksikse, bunu **şimdi** fark etmek isteriz. Çünkü ayar merkezi her şeyin temelidir; eksik bir ayarla devam edersek, hata çok sonra, hiç beklemediğimiz bir yerde patlar ve sebebini bulmak saatler alır.

Bir benzetme: Yola çıkmadan önce çantanı kontrol etmek. "Pasaport var mı, bilet var mı, anahtar var mı?" Havaalanında bunlardan birinin eksik olduğunu fark etmek çok geçtir; evde fark etmek bedavadır.

> ✅ **Özet:** Merkez kurulur kurulmaz, içinin gerçekten dolu olduğunu doğularız. Temeldeki bir eksiği erken yakalamak, en kârlı kontroldür.

---

## Bir tema: "Sabit kalanlar" ile "değişenler"i ayırmak

Tüm bu rehberin altında yatan derin bir fikir var. İyi bir program, iki tür şeyi **birbirinden ayırır:**

- **Değişmeyen mantık** — "veriyi çek, temizle, tahmin et" gibi işin özü. Bu nadiren değişir.
- **Değişebilen kararlar** — "hangi tarihten, hangi kaynaktan, kaç adım geriye" gibi ayarlar. Bunlar sık değişir.

Eğer bu ikisi birbirine karışırsa, küçük bir ayar değiştirmek için işin özüne dokunmak zorunda kalırsın — ve özü her kurcaladığında onu bozma riski alırsın.

Ayar merkezi, **değişebilenleri** tek bir yere toplar ki, değişmeyen mantığa hiç dokunmadan ayar oynatabilesin. Bir benzetme: Arabanın koltuğunu öne çekmek için motoru açmazsın. Koltuk ayarı (sık değişir) ayrı bir koldadır, motor (değişmez) ayrı durur. İyi tasarım, sık değişeni kolay erişilir, nadir değişeni korunaklı yapar.

---

## Özet — Ayar merkezi aslında neyi çözüyordu?

Bu aşamada iş yapan bir kod yazmadık; iş yapmayan ama her işin başvuracağı bir **merkez** kurduk. Çözdüğü sorunlar:

| Gereklilik               | Neyi çözer?                 | Olmasaydı ne olurdu?                           |
| ------------------------ | --------------------------- | ---------------------------------------------- |
| **Tek merkez**           | Kararların dağılmaması      | Bir ayarı değiştirmek için onlarca yeri aramak |
| **Sırrın adresi**        | Gizliyi göstermeden taşımak | Paylaşınca şifrenin sızması                    |
| **Önce keşif**           | Bilinçli kaynak seçimi      | Yanlış veriyle ilerleyip geç fark etmek        |
| **Konulara bölme**       | Merkezin içinde kaybolmamak | Yüzlerce ayarın arasında boğulmak              |
| **Doğrulama**            | Eksiği erken yakalamak      | Temeldeki boşluğun sonradan patlaması          |
| **Sabit/değişen ayrımı** | Özü bozmadan ayar oynatmak  | Her küçük değişiklikte işin özünü riske atmak  |

Hepsinin ardındaki tek fikir şu:

> **Değişebilecek her şeyi tek, düzenli ve güvenli bir yere topla ki; projeyi değiştirmek korkutucu değil, kolay olsun.**

Tecrübesiz biri ayarları "kullanıldığı yere yazmak" ister, çünkü o an daha hızlı görünür. Tecrübeli biri bilir ki bu hız sahtedir — projeyi bir kez büyütüp bir ayar değiştirmek istediğinde, dağınıklığın bedelini fazlasıyla öder. Ayar merkezi, bugünün küçük bir disiplini karşılığında, yarının büyük bir rahatlığını satın alır.

Merkez hazır. Bundan sonraki aşamalarda, bu merkeze başvuran gerçek iş parçalarını (önce yardımcı araçlar, sonra veri çekme) inşa etmeye başlayacağız.