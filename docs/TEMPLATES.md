# 📋 Regex Template Dokümantasyonu

Bu dokümanda tüm hazır regex şablonları ve kullanım örnekleri yer almaktadır.

## İçindekiler

- [Banka Dekont Şablonları (Vakıfbank + Ziraat)](#banka-dekont-şablonları-vakıfbank--ziraat)
- [Bankacılık Şablonları](#bankacılık-şablonları)
- [Fatura Şablonları](#fatura-şablonları)
- [Abonelik/Fatura Şablonları](#abonelikfatura-şablonları)
- [Sözleşme Şablonları](#sözleşme-şablonları)
- [Makbuz Şablonları](#makbuz-şablonları)
- [Kimlik Belgeleri](#kimlik-belgeleri)
- [Kargo/Gönderi Şablonları](#kargogönderi-şablonları)
- [Genel Patterns](#genel-patterns)
- [Kendi Pattern'inizi Yazma](#kendi-patterninizi-yazma)

---

## Banka Dekont Şablonları (Vakıfbank + Ziraat)

Bu bölümdeki pattern'ler hem **Vakıfbank** hem de **Ziraat Bankası** dekontlarından otomatik veri çıkarmak için optimize edilmiştir.

### Tesisat Numarası (Çoklu Banka)
```regex
(\d{10,11})(?:-\d+-|\s+TAZMİNAT)
```
**Extraction Group:** 1

**Açıklama:** Hem Vakıfbank hem Ziraat formatlarını destekler
- Vakıfbank: `1234567890-123-456` → `1234567890`
- Ziraat: `42589430970 TAZMİNAT` → `42589430970`

**Önemli:** Eski pattern `(?:(\d{10})-\d+-|(\d{10,11})\s+TAZMİNAT)` iki capture group kullanıyordu ve Ziraat için boş dönüyordu. Yeni pattern tek capture group ile her iki formatı da yakalar.

---

### İşlem Açıklaması
```regex
(?:İŞLEM AÇIKLAMASI|Açıklama)\s*:?\s*([^\n]+)
```
**Extraction Group:** 1

**Örnek Metinler:**
- Vakıfbank: `İŞLEM AÇIKLAMASI MEHMET YILMAZ 1234567890-123` → `MEHMET YILMAZ 1234567890-123`
- Ziraat: `Açıklama : MEHMET KARPUZ 42589430970 TAZMİNAT ÖDEME` → `MEHMET KARPUZ 42589430970 TAZMİNAT ÖDEME`

---

### Gönderen Unvan
```regex
(?:GONDEREN AD|Gönderen)\s*:?\s*([A-ZÇĞİÖŞÜ][^\n]+)
```
**Extraction Group:** 1

**Örnek Metinler:**
- Vakıfbank: `GONDEREN AD AKEDAŞ ELEKTRİK DAĞITIM` → `AKEDAŞ ELEKTRİK DAĞITIM`
- Ziraat: `Gönderen : AKEDAŞ ELEKTRİK DAĞITIM ANONİM ŞİRKETİ` → `AKEDAŞ ELEKTRİK DAĞITIM ANONİM ŞİRKETİ`

---

### Gönderen Şube
```regex
(?:GONDEREN ŞUBE|Alan Şube)\s*:?\s*([^\n]+)
```
**Extraction Group:** 1

**Örnek Metinler:**
- Vakıfbank: `GONDEREN ŞUBE KAHRAMANMARAŞ TİCARİ` → `KAHRAMANMARAŞ TİCARİ`
- Ziraat: `Alan Şube : 2585-AZERBAYCAN BULVARI/KAHRAMANMARAŞ ŞUBESİ` → `2585-AZERBAYCAN BULVARI/KAHRAMANMARAŞ ŞUBESİ`

---

### Alıcı Ad Soyad
```regex
(?:ALICI AD\n|Alıcı:[ ]*)([A-ZÇĞİÖŞÜ][A-ZÇĞİÖŞÜa-zçğıöşü]+(?: [A-ZÇĞİÖŞÜ][A-ZÇĞİÖŞÜa-zçğıöşü]+){0,2})
```
**Extraction Group:** 1

**Açıklama:** Bu pattern önemli!
- Vakıfbank'ta `ALICI AD` satırından sonra newline var, isim bir sonraki satırda
- Ziraat'ta `Alıcı:` ile aynı satırda
- `\s` yerine `[ ]` kullanılıyor çünkü `\s` newline'ı da içerir ve fazla satır yakalar

**Örnek Metinler:**
- Vakıfbank: 
  ```
  ALICI AD
  MEHMET PARLAK
  ```
  → `MEHMET PARLAK`
- Ziraat: `Alıcı: MEHMET KARPUZ` → `MEHMET KARPUZ`

**⚠️ Dikkat:** Eski pattern `([A-ZÇĞİÖŞÜ][A-Za-zÇĞİÖŞÜçğıöşü\s]+)` fazla satır yakalıyordu (örn: `MEHMET KARPUZ\nMasraf Alınan Hesap`)

---

### Alıcı IBAN
```regex
(?:ALICI HESAP[\s\S]{0,100}?|IBAN\s*:\s*)(TR\d{2}[\s\d]+\d{2})
```
**Extraction Group:** 1

**Örnek Metinler:**
- Vakıfbank: `ALICI HESAP TR61 0011 1000 0000 0097 6337` → `TR61 0011 1000 0000 0097 6337`
- Ziraat: `IBAN : TR91 0001 0022 6555 9935 3851 09` → `TR91 0001 0022 6555 9935 3851 09`

---

### İşlem No / Havale Referansı
```regex
(?:İŞLEM NO\s+|Havale Referansı\s*:\s*)([A-Z0-9]+)
```
**Extraction Group:** 1

**Örnek Metinler:**
- Vakıfbank: `İŞLEM NO 2023ABCD12345678` → `2023ABCD12345678`
- Ziraat: `Havale Referansı: 2265HOHI25000307` → `2265HOHI25000307`

---

### İşlem Tutarı
```regex
(?:İŞLEM TUTARI|Havale\s+Tutarı)\s*:?\s*([\d.,]+)\s*(?:TL|TRY)
```
**Extraction Group:** 1

**Örnek Metinler:**
- Vakıfbank: `İŞLEM TUTARI 1.234,56 TL` → `1.234,56`
- Ziraat: `Havale Tutarı : 769,80 TRY` → `769,80`

---

### İşlem Tarihi
```regex
İŞLEM TARİHİ\s*:?\s*(\d{2}[./-]\d{2}[./-]\d{4}(?:[-\s]\d{2}:\d{2}:\d{2})?)
```
**Extraction Group:** 1

**Örnek Metinler:**
- Vakıfbank: `İŞLEM TARİHİ 25.12.2024` → `25.12.2024`
- Ziraat: `İŞLEM TARİHİ : 25/09/2025-13:56:30` → `25/09/2025-13:56:30`

---

## Özet Tablo (Banka Dekontları)

| Alan | Pattern | Group | Vakıfbank | Ziraat |
|------|---------|-------|-----------|--------|
| Tesisat No | `(\d{10,11})(?:-\d+-\|\s+TAZMİNAT)` | 1 | ✅ | ✅ |
| İşlem Açıklama | `(?:İŞLEM AÇIKLAMASI\|Açıklama)\s*:?\s*([^\n]+)` | 1 | ✅ | ✅ |
| Gönderen Unvan | `(?:GONDEREN AD\|Gönderen)\s*:?\s*([A-ZÇĞİÖŞÜ][^\n]+)` | 1 | ✅ | ✅ |
| Gönderen Şube | `(?:GONDEREN ŞUBE\|Alan Şube)\s*:?\s*([^\n]+)` | 1 | ✅ | ✅ |
| Alıcı Ad Soyad | `(?:ALICI AD\n\|Alıcı:[ ]*)([A-ZÇĞİÖŞÜ]...{0,2})` | 1 | ✅ | ✅ |
| Alıcı IBAN | `(?:ALICI HESAP[\s\S]{0,100}?\|IBAN\s*:\s*)(TR\d{2}[\s\d]+)` | 1 | ✅ | ✅ |
| İşlem No | `(?:İŞLEM NO\s+\|Havale Referansı\s*:\s*)([A-Z0-9]+)` | 1 | ✅ | ✅ |
| İşlem Tutarı | `(?:İŞLEM TUTARI\|Havale\s+Tutarı)\s*:?\s*([\d.,]+)` | 1 | ✅ | ✅ |
| İşlem Tarihi | `İŞLEM TARİHİ\s*:?\s*(\d{2}[./-]\d{2}[./-]\d{4}...)` | 1 | ✅ | ✅ |

---

## Bankacılık Şablonları

### IBAN
```regex
(?:IBAN|HESAP).*?(TR\d{2}[\s\d]{22,26})
```
**Açıklama:** Türk IBAN numaralarını yakalar (TR ile başlayan 26 karakter)

**Örnek Metin:**
```
ALICI HESAP / IBAN TR12 3456 7890 1234 5678 9012 34
```
**Çıktı:** `TR12 3456 7890 1234 5678 9012 34`

---

### Hesap Numarası
```regex
HESAP\s*(?:NO|NUMARASI)?\s*[:\s]*(\d{10,16})
```
**Açıklama:** 10-16 haneli banka hesap numaralarını yakalar

**Örnek Metin:**
```
HESAP NO: 1234567890123456
```
**Çıktı:** `1234567890123456`

---

### EFT Referans No
```regex
(?:EFT|HAVALE)\s*(?:SORGU|REF(?:ERANS)?)?\s*NO\s*[:\s]*(\d{12,20})
```
**Açıklama:** EFT veya Havale referans numaralarını yakalar

**Örnek Metin:**
```
EFT SORGU NO 123456789012345678
```
**Çıktı:** `123456789012345678`

---

### İşlem Tutarı
```regex
(?:TUTAR|MEBLAĞ|BEDEL)\s*[:\s]*([\d.,]+)\s*(?:TL|TRY|₺)
```
**Açıklama:** TL formatındaki para tutarlarını yakalar

**Örnek Metin:**
```
İŞLEM TUTARI 1.234,56 TL
```
**Çıktı:** `1.234,56`

---

### İşlem Tarihi
```regex
(?:İŞLEM|DEĞER|VALÖR)\s*TARİHİ\s*[:\s]*(\d{2}[./]\d{2}[./]\d{4})
```
**Açıklama:** DD.MM.YYYY veya DD/MM/YYYY formatındaki tarihleri yakalar

**Örnek Metin:**
```
İŞLEM TARİHİ 25.12.2024
```
**Çıktı:** `25.12.2024`

---

### Alıcı Adı
```regex
ALICI\s*(?:AD|UNVAN)\s*[:\n\s]*([A-ZÇĞİÖŞÜa-zçğıöşü\s]+?)\s*(?:ALICI|IBAN|$)
```
**Açıklama:** Alıcı ad soyad veya şirket ünvanını yakalar

**Örnek Metin:**
```
ALICI AD
AHMET YILMAZ
ALICI IBAN
```
**Çıktı:** `AHMET YILMAZ`

---

## Fatura Şablonları

### Fatura No
```regex
FATURA\s*(?:NO|NUMARASI)?\s*[:\s]*([A-Z]{0,3}\d{4,}(?:[A-Z0-9]*)?)
```
**Açıklama:** Çeşitli formatlardaki fatura numaralarını yakalar

**Örnekler:**
- `FATURA NO: ABC123456` → `ABC123456`
- `FATURA NUMARASI: 2024000001` → `2024000001`

---

### Fatura Tarihi
```regex
FATURA\s*TARİHİ\s*[:\s]*(\d{2}[./]\d{2}[./]\d{4})
```

---

### Vade Tarihi
```regex
VADE\s*TARİHİ\s*[:\s]*(\d{2}[./]\d{2}[./]\d{4})
```

---

### Toplam Tutar
```regex
(?:TOPLAM|GENEL\s*TOPLAM)\s*[:\s]*([\d.,]+)\s*(?:TL|TRY|₺)?
```

---

### KDV Tutarı
```regex
KDV\s*(?:TUTARI)?\s*[:\s]*([\d.,]+)\s*(?:TL|TRY|₺)?
```

---

### Vergi No
```regex
VERGİ\s*(?:DAİRESİ)?\s*(?:NO|NUMARASI)?\s*[:\s]*(\d{10,11})
```
**Açıklama:** 10 veya 11 haneli vergi kimlik numaralarını yakalar

---

### TC Kimlik No
```regex
T\.?C\.?\s*(?:KİMLİK)?\s*(?:NO|NUMARASI)?\s*[:\s]*(\d{11})
```
**Açıklama:** 11 haneli TC Kimlik numaralarını yakalar

---

## Abonelik/Fatura Şablonları

### Tesisat Numarası
```regex
(?:TESİSAT|ABONE)\s*(?:NO|NUMARASI)?\s*[:\s]*(\d{8,12})
```
**Açıklama:** Elektrik, su, doğalgaz tesisat numaralarını yakalar

---

### Sayaç Numarası
```regex
SAYAÇ\s*(?:NO|NUMARASI)?\s*[:\s]*(\d{6,12})
```

---

### Tüketim Miktarı
```regex
TÜKETİM\s*[:\s]*([\d.,]+)\s*(?:kWh|m³|m3)
```
**Açıklama:** kWh veya m³ birimli tüketim değerlerini yakalar

---

### Son Ödeme Tarihi
```regex
SON\s*ÖDEME\s*TARİHİ\s*[:\s]*(\d{2}[./]\d{2}[./]\d{4})
```

---

### Dönem
```regex
DÖNEM\s*[:\s]*(\d{4}[/-]\d{2}|[A-ZŞİĞÜÇÖa-zşığüçö]+\s*\d{4})
```
**Örnekler:**
- `DÖNEM: 2024-12` → `2024-12`
- `DÖNEM: Aralık 2024` → `Aralık 2024`

---

## Sözleşme Şablonları

### Sözleşme No
```regex
SÖZLEŞME\s*(?:NO|NUMARASI)?\s*[:\s]*([A-Z0-9-]+)
```

---

### Sözleşme Tarihi
```regex
SÖZLEŞME\s*TARİHİ\s*[:\s]*(\d{2}[./]\d{2}[./]\d{4})
```

---

### Başlangıç/Bitiş Tarihleri
```regex
# Başlangıç
BAŞLANGIÇ\s*TARİHİ\s*[:\s]*(\d{2}[./]\d{2}[./]\d{4})

# Bitiş
BİTİŞ\s*TARİHİ\s*[:\s]*(\d{2}[./]\d{2}[./]\d{4})
```

---

## Makbuz Şablonları

### Fiş No
```regex
(?:FİŞ|MAKBUZ)\s*(?:NO|NUMARASI)?\s*[:\s]*(\d+)
```

---

### Ödeme Tutarı
```regex
(?:ÖDENEN|TAHSİL\s*EDİLEN|ALINAN)\s*(?:TUTAR)?\s*[:\s]*([\d.,]+)\s*(?:TL|TRY|₺)?
```

---

### Ödeme Yöntemi
```regex
ÖDEME\s*(?:TÜRÜ|YÖNTEMİ|ŞEKLİ)\s*[:\s]*(NAKİT|KREDİ\s*KARTI|BANKA\s*KARTI|HAVALE|EFT)
```

---

## Kimlik Belgeleri

### Ad Soyad
```regex
(?:ADI?\s*SOYADI?|İSİM)\s*[:\s]*([A-ZÇĞİÖŞÜ][a-zçğıöşü]+\s+[A-ZÇĞİÖŞÜ][A-ZÇĞİÖŞÜa-zçğıöşü]+)
```

---

### Doğum Tarihi
```regex
DOĞUM\s*TARİHİ\s*[:\s]*(\d{2}[./]\d{2}[./]\d{4})
```

---

### Doğum Yeri
```regex
DOĞUM\s*YERİ\s*[:\s]*([A-ZÇĞİÖŞÜa-zçğıöşü]+)
```

---

### Kimlik Seri No
```regex
SERİ\s*(?:NO)?\s*[:\s]*([A-Z]\d{2}[A-Z]\d{5})
```
**Örnek:** `A12B34567`

---

## Kargo/Gönderi Şablonları

### Takip No
```regex
(?:TAKİP|GÖNDERI|KARGO)\s*(?:NO|NUMARASI)?\s*[:\s]*([A-Z0-9]{10,20})
```

---

### Ağırlık
```regex
AĞIRLIK\s*[:\s]*([\d.,]+)\s*(?:kg|KG|gr|GR)
```

---

### Desi
```regex
DESİ\s*[:\s]*([\d.,]+)
```

---

## Genel Patterns

Bu pattern'ler `default_templates.json` içinde `common_patterns` bölümünde yer alır:

| Pattern Adı | Regex | Açıklama |
|-------------|-------|----------|
| `turkish_date` | `(\d{2}[./]\d{2}[./]\d{4})` | DD.MM.YYYY veya DD/MM/YYYY |
| `turkish_currency` | `([\d.,]+)\s*(?:TL\|TRY\|₺)` | Türk Lirası tutarları |
| `iban` | `(TR\d{2}[\s\d]{22,26})` | Türk IBAN |
| `tc_kimlik` | `(\d{11})` | 11 haneli TC Kimlik |
| `vergi_no` | `(\d{10,11})` | 10-11 haneli Vergi No |
| `phone` | `(?:\+90\|0)?\s*\(?(\d{3})\)?...` | Türk telefon numarası |
| `email` | `([a-zA-Z0-9._%+-]+@...)` | Email adresi |

---

## Kendi Pattern'inizi Yazma

### Temel Regex Kuralları

| Karakter | Anlamı | Örnek |
|----------|--------|-------|
| `\d` | Herhangi bir rakam | `\d{4}` = 4 rakam |
| `\s` | Boşluk karakteri (newline dahil!) | `\s+` = bir veya daha fazla boşluk |
| `[ ]` | Sadece boşluk (newline hariç) | `[ ]+` = sadece boşluklar |
| `.` | Herhangi bir karakter | `.*` = herhangi bir şey |
| `+` | Bir veya daha fazla | `\d+` = bir veya daha fazla rakam |
| `*` | Sıfır veya daha fazla | `\s*` = sıfır veya daha fazla boşluk |
| `?` | Sıfır veya bir | `\s?` = isteğe bağlı boşluk |
| `{n}` | Tam n adet | `\d{11}` = tam 11 rakam |
| `{n,m}` | n ile m arası | `\d{10,16}` = 10-16 rakam |
| `()` | Capture group | `(\d+)` = yakalanan rakamlar |
| `(?:)` | Non-capturing group | `(?:NO\|NUMARASI)` = yakalanmayan alternatif |
| `\|` | Veya | `TL\|TRY` = TL veya TRY |
| `[]` | Karakter sınıfı | `[A-Z]` = büyük harf |
| `^` | Satır başı | `^FATURA` = satır başındaki FATURA |
| `$` | Satır sonu | `TL$` = satır sonundaki TL |
| `\n` | Newline (satır sonu) | `AD\n` = AD sonrası yeni satır |
| `[^\n]` | Newline hariç herhangi bir karakter | `[^\n]+` = satır sonuna kadar |

### ⚠️ Önemli: `\s` vs `[ ]`

- `\s` → Boşluk, tab VE newline karakterlerini içerir
- `[ ]` → Sadece boşluk karakteri (newline hariç)

**Örnek Sorun:**
```regex
# YANLIŞ - Fazla satır yakalar
([A-Z][a-z]+\s+[A-Z][a-z]+\s*)

# DOĞRU - Sadece aynı satırdaki isim soyismi yakalar
([A-Z][a-z]+[ ]+[A-Z][a-z]+)
```

### Türkçe Karakterler

Türkçe karakterleri yakalamak için:
```regex
[A-ZÇĞİÖŞÜa-zçğıöşü]
```

### Örnek: Kendi Pattern'inizi Oluşturma

**Hedef:** "Sipariş No: ORD-2024-12345" formatındaki numarayı yakalamak

**Pattern:**
```regex
SİPARİŞ\s*(?:NO|NUMARASI)?\s*[:\s]*(ORD-\d{4}-\d{5})
```

**Açıklama:**
- `SİPARİŞ` - "SİPARİŞ" kelimesi
- `\s*` - isteğe bağlı boşluklar
- `(?:NO|NUMARASI)?` - isteğe bağlı "NO" veya "NUMARASI"
- `\s*[:\s]*` - isteğe bağlı boşluk ve iki nokta
- `(ORD-\d{4}-\d{5})` - yakalanacak pattern (ORD-XXXX-XXXXX)

### Test Etme

Pattern'inizi test etmek için:

1. **Online:** [regex101.com](https://regex101.com) (Python flavor seçin)
2. **Python:**
```python
import re
pattern = r'SİPARİŞ\s*(?:NO|NUMARASI)?\s*[:\s]*(ORD-\d{4}-\d{5})'
text = 'Sipariş No: ORD-2024-12345'
match = re.search(pattern, text, re.IGNORECASE)
if match:
    print(f"Yakalanan: {match.group(1)}")
```

---

## Troubleshooting (Sorun Giderme)

### Pattern çalışmıyor - Boş değer dönüyor

**Olası Nedenler:**
1. **Yanlış capture group:** Birden fazla `()` varsa, `extraction_group` değerini kontrol edin
2. **Format farkı:** Farklı bankaların dekont formatları farklı olabilir
3. **Türkçe karakterler:** `İ`, `ı`, `Ğ`, `ğ` karakterlerini kontrol edin

**Çözüm:** Pattern'i tek capture group ile yeniden yazın:
```regex
# YANLIŞ - İki capture group
(?:(\d{10})-\d+-|(\d{10,11})\s+TAZMİNAT)

# DOĞRU - Tek capture group  
(\d{10,11})(?:-\d+-|\s+TAZMİNAT)
```

### Fazla veri yakalanıyor

**Olası Nedenler:**
1. **`\s` newline içeriyor:** `[ ]` kullanın
2. **Greedy matching:** `+?` veya `*?` kullanarak lazy matching yapın

**Çözüm:**
```regex
# YANLIŞ - Newline'ı da yakalar
([A-Z][A-Za-z\s]+)

# DOĞRU - Sadece aynı satırı yakalar
([A-Z][A-Za-z]+(?: [A-Z][A-Za-z]+){0,2})
```

### Birden fazla banka desteği

Her iki format için tek pattern yazın:
```regex
(?:VAKIF_FORMAT|ZIRAAT_FORMAT)\s*:?\s*(CAPTURE_GROUP)
```

---

## SSS

### Pattern çalışmıyor, ne yapmalıyım?

1. **Büyük/küçük harf:** Tüm pattern'ler `re.IGNORECASE` ile çalışır
2. **Türkçe karakterler:** `İ`, `ı`, `Ğ`, `ğ` gibi karakterleri kontrol edin
3. **Escape karakterleri:** JSON'da `\` yerine `\\` kullanın
4. **Test edin:** regex101.com'da test edin

### Birden fazla değer yakalamak istiyorum

Her alan için ayrı pattern tanımlayın. Bir pattern sadece bir değer yakalar.

### Capture group ne demek?

Parantez içindeki kısım "yakalanan" değerdir. Örneğin:
```regex
TUTAR\s*([\d.,]+)\s*TL
```
Bu pattern'de sadece `([\d.,]+)` kısmı yakalanır, "TUTAR" ve "TL" yakalanmaz.

---

## Katkıda Bulunma

Yeni şablonlar eklemek isterseniz:

1. `default_templates.json` dosyasını fork edin
2. Yeni category veya field ekleyin
3. Test edin ve PR gönderin

Detaylar için [CONTRIBUTING.md](../CONTRIBUTING.md) dosyasına bakın.
