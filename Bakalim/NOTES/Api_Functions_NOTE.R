#NOTE
if (!exists("CONFIG"))      stop("[api_functions.R] Önce config.R yükle: source('R/config.R')")
if (!exists("tekrar_dene")) stop("[api_functions.R] Önce utils.R yükle: source('R/utils.R')")

#NOTE
suppressPackageStartupMessages({
  library(fredr)      # FRED
  library(httr)       # EVDS, OECD, Yahoo (HTTP)
  library(jsonlite)   # JSON çözme
  library(wbstats)    # Dünya Bankası
})

#NOTE
donem_tarih_coz <- function(x) {
  x <- as.character(x)
  iso <- ifelse(grepl("^[0-9]{2}-[0-9]{2}-[0-9]{4}$", x),
                format(as.Date(x, format = "%d-%m-%Y")),
                ifelse(grepl("^[0-9]{4}-Q[1-4]$", x),
                       paste0(substr(x, 1, 4), "-",
                              sprintf("%02d", (as.integer(substr(x, 7, 7)) - 1) * 3 + 1), "-01"),
                       ifelse(grepl("^[0-9]{4}-[0-9]{1,2}$", x),
                              paste0(x, "-01"),
                              ifelse(grepl("^[0-9]{4}$", x),
                                     paste0(x, "-01-01"),
                                     NA_character_))))
  as.Date(iso, format = "%Y-%m-%d")
}

#NOTE
standartlastir <- function(tarih, deger, kimlik) {
  d <- data.frame(tarih = as.Date(tarih), deger = suppressWarnings(as.numeric(deger)),
                  kimlik = kimlik, stringsAsFactors = FALSE)
  d <- d[!is.na(d$tarih) & !is.na(d$deger), , drop = FALSE]
  d <- d[!duplicated(d$tarih, fromLast = TRUE), , drop = FALSE]
  bas <- as.Date(CONFIG$veri$baslangic_tarihi); bit <- as.Date(CONFIG$veri$bitis_tarihi)
  d <- d[d$tarih >= bas & d$tarih <= bit, , drop = FALSE]
  d <- d[order(d$tarih), , drop = FALSE]
  rownames(d) <- NULL
  d
}

#NOTE
http_al <- function(url, basliklar = NULL) {
  girdiler <- list(url, user_agent(CONFIG$baglanti$kullanici_araci),
                   timeout(CONFIG$baglanti$zaman_asimi))
  if (!is.null(basliklar)) girdiler <- c(girdiler, list(basliklar))
  cevap <- tryCatch(do.call(GET, girdiler),
                    error = function(e) stop(paste("Bağlantı hatası:", conditionMessage(e)),
                                             call. = FALSE))
  govde <- content(cevap, "text", encoding = "UTF-8")
  kod   <- status_code(cevap)
  if (kod %in% c(400, 401, 403, 404)) {
    kalici_hata(paste0("HTTP ", kod, ": ", substr(gsub("\\s+", " ", govde), 1, 120)))
  }
  if (http_error(cevap)) stop(paste("HTTP", kod), call. = FALSE)
  govde
}

#NOTE
fred_cek <- function(kod, kimlik, filtre = NULL) {
  fredr_set_key(CONFIG$baglanti$fred_key)
  ham <- fredr(series_id = kod,
               observation_start = as.Date(CONFIG$veri$baslangic_tarihi),
               observation_end   = as.Date(CONFIG$veri$bitis_tarihi))
  standartlastir(ham$date, ham$value, kimlik)
}

#NOTE
evds_cek <- function(kod, kimlik, filtre = NULL) {
  seri  <- gsub("_", ".", trimws(kod))
  bas   <- format(as.Date(CONFIG$veri$baslangic_tarihi), "%d-%m-%Y")
  bitis <- format(as.Date(CONFIG$veri$bitis_tarihi),     "%d-%m-%Y")
  url <- paste0(CONFIG$baglanti$evds_base_url, "/series=", seri,
                "&startDate=", bas, "&endDate=", bitis, "&type=json",
                if (!is.null(filtre) && nzchar(filtre)) paste0("&", filtre) else "")
  govde <- http_al(url, add_headers(key = CONFIG$baglanti$evds_key))
  
  veri <- tryCatch(fromJSON(govde)$items, error = function(e) NULL)
  if (is.null(veri) || NROW(veri) == 0) {
    kalici_hata("EVDS'ten boş/çözülemeyen yanıt geldi (seri kodu yanlış olabilir)")
  }
  tarih <- donem_tarih_coz(veri$Tarih)
  if (all(is.na(tarih))) {
    stop(paste("EVDS tarih biçimi çözülemedi, örnek:", veri$Tarih[1]), call. = FALSE)
  }
  kolon <- gsub("\\.", "_", seri)                     # yanıttaki sütun adı: TP_FG_J0
  deger <- if (kolon %in% names(veri)) veri[[kolon]] else veri[[2]]
  standartlastir(tarih, deger, kimlik)
}

#NOTE
wb_kod_temizle <- function(kod) {
  kod <- sub("\\?.*$", "", trimws(kod))
  kod <- sub("^WB_WDI_", "", kod)
  gsub("_", ".", kod)
}

#NOTE
worldbank_cek <- function(kod, kimlik, filtre = NULL) {
  gosterge <- wb_kod_temizle(kod)
  bas   <- as.integer(format(as.Date(CONFIG$veri$baslangic_tarihi), "%Y"))
  bitis <- as.integer(format(as.Date(CONFIG$veri$bitis_tarihi),     "%Y"))
  ham <- wb_data(indicator = gosterge, country = "TUR", start_date = bas, end_date = bitis)
  if (is.null(ham) || nrow(ham) == 0) {
    kalici_hata(paste("Dünya Bankası'ndan veri gelmedi:", gosterge))
  }
  standartlastir(as.Date(paste0(ham$date, "-01-01")), ham[[gosterge]], kimlik)
}

#NOTE
oecd_cek <- function(kod, kimlik, filtre = NULL) {
  if (is.null(filtre) || !nzchar(filtre)) kalici_hata("OECD için filtre (SDMX anahtarı) gerekli")
  url <- paste0(CONFIG$baglanti$oecd_base_url, "/data/", kod, ",/", filtre,
                "?startPeriod=", format(as.Date(CONFIG$veri$baslangic_tarihi), "%Y-%m"),
                "&format=csvfilewithlabels")
  govde <- http_al(url)
  d <- tryCatch(utils::read.csv(text = govde, stringsAsFactors = FALSE),
                error = function(e) NULL)
  if (is.null(d) || !all(c("TIME_PERIOD", "OBS_VALUE") %in% names(d)) || nrow(d) == 0) {
    kalici_hata("OECD'den veri gelmedi (kod/filtre yanlış olabilir)")
  }
  if (anyDuplicated(d$TIME_PERIOD) > 0) {
    kalici_hata("OECD filtresi tek bir seriyi belirlemiyor (aynı dönem birden çok kez var)")
  }
  standartlastir(donem_tarih_coz(d$TIME_PERIOD), d$OBS_VALUE, kimlik)
}

#NOTE
bist_cek <- function(kod, kimlik, filtre = NULL) {
  sembol <- if (grepl("\\.", kod)) kod else paste0(kod, ".IS")
  p1 <- as.integer(as.POSIXct(as.Date(CONFIG$veri$baslangic_tarihi), tz = "UTC"))
  p2 <- as.integer(as.POSIXct(as.Date(CONFIG$veri$bitis_tarihi) + 1, tz = "UTC"))
  url <- paste0(CONFIG$baglanti$yahoo_base_url, "/", utils::URLencode(sembol, reserved = TRUE),
                "?period1=", p1, "&period2=", p2, "&interval=1mo&events=history")
  j <- tryCatch(fromJSON(http_al(url)), error = function(e) NULL)
  sonuc <- if (is.null(j)) NULL else j$chart$result
  if (is.null(sonuc) || is.null(sonuc$timestamp[[1]])) {
    kalici_hata(paste("Yahoo Finance'ten veri gelmedi:", sembol))
  }
  zaman <- as.POSIXct(sonuc$timestamp[[1]], origin = "1970-01-01", tz = "Europe/Istanbul")
  kapanis <- sonuc$indicators$quote[[1]]$close[[1]]
  # Saat dilimi kaymasına karşı (as.Date UTC'ye çevirir) ve içinde bulunulan ayın
  # kısmi çubuğu için: tarih, İstanbul saatiyle AY BAŞI yapılır; aynı aya düşen
  # iki çubuktan sonuncusu (standartlastir) kalır.
  standartlastir(as.Date(format(zaman, "%Y-%m-01", tz = "Europe/Istanbul")), kapanis, kimlik)
}

#NOTE
tur_uyumlu <- function(hedef, tur) {
  if (identical(hedef, "yillik_degisim")) tur %in% c("duzey", "oran")
  else                                    identical(tur, "duzey")
}

#NOTE
frekans_uyumlu <- function(hedef, kaynak_frekans) {
  sira <- c(yillik = 1, ceyreklik = 2, aylik = 3)
  sira[[kaynak_frekans]] >= sira[[hedef]]
}

#NOTE
kaynak_zinciri <- function(gosterge_adi) {
  kart  <- CONFIG$gostergeler[[gosterge_adi]]
  hedef <- varsayilan(kart$donusum, "duzey")
  frek  <- gosterge_frekansi(gosterge_adi)
  zincir <- list()
  for (k in gosterge_oncelik(gosterge_adi)) {
    if (identical(k, kart$kaynak)) {
      zincir[[length(zincir) + 1]] <- list(kaynak = k, kod = kart$kod, filtre = NULL,
                                           tur = varsayilan(kart$kaynak_tur, "duzey"), carpan = 1, yaklasik = FALSE, birincil = TRUE)
      next
    }
    if (!isTRUE(CONFIG$veri$yedek_kaynak_kullan)) next
    if (identical(k, "CSV_YEDEK")) {
      zincir[[length(zincir) + 1]] <- list(kaynak = k, kod = NA_character_, filtre = NULL,
                                           tur = "duzey", carpan = 1, yaklasik = FALSE, birincil = FALSE)
      next
    }
    a <- kart$alternatifler[[k]]
    if (is.null(a) || !k %in% CONFIG$kaynaklar$desteklenen) next
    kod    <- if (is.list(a)) a$kod else a
    filtre <- if (is.list(a)) a$filtre else NULL
    tur    <- if (is.list(a)) varsayilan(a$tur, "duzey") else "duzey"
    carpan <- if (is.list(a)) varsayilan(a$carpan, 1) else 1
    kfrek  <- if (is.list(a)) varsayilan(a$frekans, frek) else frek
    yakl   <- is.list(a) && isTRUE(a$yaklasik)
    if (k == "OECD" && is.null(filtre)) next            # filtresiz OECD kodu = katalog
    if (!tur_uyumlu(hedef, tur)) next                    # tanım/ölçek uyumsuz = katalog
    if (!frekans_uyumlu(frek, kfrek)) next               # seyrek kaynak sıkı frekansa uymaz
    zincir[[length(zincir) + 1]] <- list(kaynak = k, kod = kod, filtre = filtre, tur = tur,
                                         carpan = carpan, yaklasik = yakl, birincil = FALSE)
  }
  zincir
}

#NOTE
frekansa_cevir <- function(d, frekans) {
  kimlik <- d$kimlik[1]
  d$tarih <- donem_basi(d$tarih, frekans)
  a <- stats::aggregate(deger ~ tarih, data = d, FUN = mean)
  data.frame(tarih = a$tarih, deger = a$deger, kimlik = kimlik)
}

#NOTE
seri_donustur <- function(d, hedef = "duzey", tur = "duzey", carpan = 1) {
  d$deger <- d$deger * carpan
  if (identical(hedef, "yillik_degisim") && identical(tur, "duzey")) {
    onceki  <- as.Date(paste0(as.integer(format(d$tarih, "%Y")) - 1, format(d$tarih, "-%m-%d")))
    eski    <- d$deger[match(onceki, d$tarih)]
    d$deger <- ifelse(is.na(eski) | eski <= 0, NA_real_, (d$deger / eski - 1) * 100)
    d <- d[!is.na(d$deger), , drop = FALSE]
    rownames(d) <- NULL
  }
  d
}

#NOTE
cek_kaynak <- function(kaynak, kod, kimlik, filtre = NULL) {
  switch(kaynak,
         FRED      = fred_cek(kod, kimlik, filtre),
         EVDS      = evds_cek(kod, kimlik, filtre),
         WORLDBANK = worldbank_cek(kod, kimlik, filtre),
         OECD      = oecd_cek(kod, kimlik, filtre),
         BIST      = bist_cek(kod, kimlik, filtre),
         CSV_YEDEK = { d <- yedek_csv_oku(kimlik); if (is.null(d)) kalici_hata("CSV yedek yok"); d },
         stop(paste("Bu kaynağın tercümanı yok:", kaynak), call. = FALSE))
}

#NOTE
meta_ekle <- function(veri, kaynak, kod, filtre, birincil, durum, cekim_zamani = Sys.time(),
                      donusum = "duzey", tur = "duzey", frekans = "aylik", yaklasik = FALSE) {
  attr(veri, "meta") <- list(kaynak = kaynak, kod = kod, filtre = filtre, birincil = birincil,
                             durum = durum, cekim_zamani = cekim_zamani, donusum = donusum,
                             tur = tur, frekans = frekans, yaklasik = yaklasik)
  veri
}

#NOTE
fetch_indicator <- function(gosterge_adi, tazelik_gun = NULL, yenile = FALSE) {
  kart <- CONFIG$gostergeler[[gosterge_adi]]
  if (is.null(kart)) { log_msg(paste("Tanımsız gösterge:", gosterge_adi), "UYARI"); return(NULL) }
  if (!isTRUE(kart$aktif)) { log_msg(paste("Pasif gösterge, atlandı:", gosterge_adi)); return(NULL) }
  tazelik <- varsayilan(tazelik_gun, varsayilan(CONFIG$veri$cache_tazelik_gun, 1))
  frekans <- gosterge_frekansi(gosterge_adi)
  hedef   <- varsayilan(kart$donusum, "duzey")
  
#NOTE
  if (!yenile) {
    onbellek <- cache_oku(gosterge_adi, tazelik)
    m <- attr(onbellek, "meta")
    gecerli <- !is.null(onbellek) && !is.null(m) &&
      identical(varsayilan(m$donusum, "duzey"), hedef) &&
      identical(varsayilan(m$frekans, "aylik"), frekans) &&
      (!isTRUE(m$birincil) || (identical(m$kod, kart$kod) && identical(m$kaynak, kart$kaynak)))
    if (gecerli) {
      log_msg(paste0("Cache'ten geldi: ", gosterge_adi, " (", m$kaynak, ")"))
      m$durum <- "cache"; attr(onbellek, "meta") <- m
      return(onbellek)
    }
  }

#NOTE
  for (halka in kaynak_zinciri(gosterge_adi)) {
    if (!kaynak_kullanilabilir(halka$kaynak)) {
      log_msg(paste0(gosterge_adi, ": ", halka$kaynak, " atlandı (anahtar yok)"), "UYARI")
      next
    }
    csv_mi <- identical(halka$kaynak, "CSV_YEDEK")
    sonuc <- tryCatch(
      tekrar_dene(function() cek_kaynak(halka$kaynak, halka$kod, gosterge_adi, halka$filtre),
                  deneme = if (csv_mi) 1 else NULL),
      error = function(e) {
        if (!csv_mi) log_msg(paste0("Veri alınamadı: ", gosterge_adi, " [", halka$kaynak, "] - ",
                                    conditionMessage(e)), "UYARI")
        NULL
      })
  
#NOTE
    if (!is.null(sonuc) && !csv_mi) {
      sonuc <- tryCatch(seri_donustur(frekansa_cevir(sonuc, frekans), hedef, halka$tur, halka$carpan),
                        error = function(e) NULL)
    }
    if (!is.null(sonuc) && nrow(sonuc) >= varsayilan(CONFIG$veri$min_gozlem, 8)) {
      if (csv_mi) {
        log_msg(paste0("CSV YEDEK kanalı kullanıldı: ", gosterge_adi,
                       " (API kaynakları erişilemedi; son bilinen veri)"), "UYARI")
        return(meta_ekle(sonuc, "CSV_YEDEK", NA_character_, NULL, FALSE, "csv_yedek",
                         file.mtime(file.path(CONFIG$saklama$yedek_klasoru, paste0(gosterge_adi, ".csv"))),
                         donusum = hedef, tur = "duzey", frekans = frekans))
      }
      if (!halka$birincil) {
        log_msg(paste0("YEDEK KAYNAK kullanıldı: ", gosterge_adi, " <- ", halka$kaynak,
                       " (birincil: ", kart$kaynak, ")",
                       if (halka$yaklasik) "; seri asıl seriye YAKIN ama aynı tanımda değil" else ""), "UYARI")
      }
      sonuc <- meta_ekle(sonuc, halka$kaynak, halka$kod, halka$filtre, halka$birincil, "api",
                         donusum = hedef, tur = halka$tur, frekans = frekans, yaklasik = halka$yaklasik)
      cache_yaz(sonuc, gosterge_adi)
      yedek_csv_yaz(sonuc, gosterge_adi)
      return(sonuc)
    }
    if (!is.null(sonuc)) {
      log_msg(paste0(gosterge_adi, " [", halka$kaynak, "]: yetersiz gözlem (", nrow(sonuc), ")"), "UYARI")
    }
  }

#NOTE
  eski <- cache_oku(gosterge_adi, Inf)
  if (!is.null(eski)) {
    m <- attr(eski, "meta"); if (is.null(m)) m <- list(kaynak = NA, kod = NA, birincil = NA)
    m$durum <- "bayat_cache"; attr(eski, "meta") <- m
    log_msg(paste("Tüm kanallar başarısız; BAYAT cache kullanılıyor:", gosterge_adi), "UYARI")
    return(eski)
  }
  log_msg(paste("Gösterge alınamadı:", gosterge_adi), "HATA")
  NULL
}

#NOTE
metaveri_olustur <- function(sonuclar) {
  satirlar <- lapply(names(sonuclar), function(ad) {
    kart <- CONFIG$gostergeler[[ad]]
    v <- sonuclar[[ad]]; m <- attr(v, "meta")
    data.frame(
      gosterge = ad, ad = kart$ad, rol = kart$rol, frekans = gosterge_frekansi(ad),
      kaynak = if (is.null(m)) NA_character_ else as.character(varsayilan(m$kaynak, NA)),
      kod = if (is.null(m)) NA_character_ else as.character(varsayilan(m$kod, NA)),
      birincil_kaynak = kart$kaynak,
      birincil_yedek = varsayilan(kart$birincil_yedek, NA),
      kaynak_onceligi = paste(gosterge_oncelik(ad), collapse = " > "),
      donusum = varsayilan(kart$donusum, "duzey"),
      yaklasik = if (is.null(m)) NA else isTRUE(m$yaklasik),
      yedek_kullanildi = if (is.null(m)) NA else isFALSE(m$birincil),
      durum = if (is.null(v)) "alinamadi" else varsayilan(m$durum, "api"),
      ilk_tarih = if (is.null(v)) as.Date(NA) else min(v$tarih),
      son_tarih = if (is.null(v)) as.Date(NA) else max(v$tarih),
      gozlem = if (is.null(v)) 0L else nrow(v),
      cekim_zamani = if (is.null(m)) as.POSIXct(NA) else as.POSIXct(m$cekim_zamani),
      stringsAsFactors = FALSE)
  })
  do.call(rbind, satirlar)
}

#NOTE
tum_gostergeleri_cek <- function(yenile = FALSE) {
  sonuclar <- list()
  for (ad in aktif_gostergeler()) {
    sonuclar[ad] <- list(fetch_indicator(ad, yenile = yenile))
  }
  meta <- metaveri_olustur(sonuclar)
  ikili_kaydet(meta, "metaveri")
  gelen <- Filter(Negate(is.null), sonuclar)
  log_msg(paste0("Çekim tamamlandı: ", length(gelen), "/", length(sonuclar), " gösterge",
                 if (any(meta$yedek_kullanildi %in% TRUE))
                   paste0(" (yedek kaynak: ", sum(meta$yedek_kullanildi %in% TRUE), ")") else ""))
  if (length(gelen) == 0) return(NULL)
  uzun <- do.call(rbind, unname(lapply(gelen, function(v) { attr(v, "meta") <- NULL; v })))
  rownames(uzun) <- NULL
  attr(uzun, "metaveri") <- meta
  uzun
}

#NOTE
veri_tazeligi <- function(veri, gosterge_adi) {
  alt <- veri[veri$kimlik == gosterge_adi, ]
  if (nrow(alt) == 0) return(NA)
  max(alt$tarih, na.rm = TRUE)
}

#NOTE
local({
  fonksiyonlar <- c("donem_tarih_coz", "standartlastir", "http_al",
                    "fred_cek", "evds_cek", "wb_kod_temizle", "worldbank_cek",
                    "oecd_cek", "bist_cek", "kaynak_kullanilabilir", "tur_uyumlu",
                    "frekans_uyumlu", "kaynak_zinciri", "frekansa_cevir", "seri_donustur",
                    "cek_kaynak", "meta_ekle", "fetch_indicator", "metaveri_olustur",
                    "tum_gostergeleri_cek", "veri_tazeligi")
  eksik <- fonksiyonlar[!sapply(fonksiyonlar, exists, mode = "function")]
  if (length(eksik) > 0) {
    stop("[api_functions.R] Eksik fonksiyon: ", paste(eksik, collapse = ", "))
  }
  
  for (g in aktif_gostergeler()) {
    z <- kaynak_zinciri(g)
    if (length(z) < 2) {
      stop("[api_functions.R] ", g, ": çalışabilir yedek kanal yok (oncelik/tur/frekans uyumunu kontrol et)")
    }
    if (!identical(z[[2]]$kaynak, CONFIG$gostergeler[[g]]$birincil_yedek)) {
      stop("[api_functions.R] ", g, ": birincil_yedek (", CONFIG$gostergeler[[g]]$birincil_yedek,
           ") uyumsuz olduğu için zincire girmiyor; zincirin 2. halkası: ", z[[2]]$kaynak)
    }
  }
  message("[api_functions.R] Veri kapısı yüklendi: ", length(fonksiyonlar),
          " fonksiyon; her verinin birincil yedeği ve yedek kanalı doğrulandı. ✔")
})