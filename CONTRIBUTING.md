# 🤝 Katkıda Bulunma Rehberi

Paperless Regex Extractor projesine katkıda bulunmak istediğiniz için teşekkürler!

## İçindekiler

- [Nasıl Katkıda Bulunabilirim?](#nasıl-katkıda-bulunabilirim)
- [Geliştirme Ortamı](#geliştirme-ortamı)
- [Kod Standartları](#kod-standartları)
- [Commit Mesajları](#commit-mesajları)
- [Pull Request Süreci](#pull-request-süreci)
- [Yeni Şablon Ekleme](#yeni-şablon-ekleme)

---

## Nasıl Katkıda Bulunabilirim?

### 🐛 Bug Raporlama

1. [Issues](https://github.com/serefkoca46/paperless-regex-extractor/issues) sayfasını kontrol edin
2. Aynı bug daha önce raporlanmamışsa yeni issue açın
3. Bug report template'ini kullanın
4. Mümkün olduğunca detay verin:
   - Paperless-ngx versiyonu
   - Python versiyonu
   - Hata mesajı
   - Tekrar adımları

### 💡 Özellik Önerisi

1. [Issues](https://github.com/serefkoca46/paperless-regex-extractor/issues) sayfasında "Feature Request" açın
2. Özelliğin ne işe yarayacağını açıklayın
3. Mümkünse kullanım örneği verin

### 📝 Dokümantasyon

- Yazım hataları düzeltme
- Eksik açıklamalar ekleme
- Yeni örnekler ekleme
- Çeviri katkıları

### 🔧 Kod Katkısı

1. Repo'yu fork edin
2. Feature branch oluşturun
3. Değişikliklerinizi yapın
4. Test edin
5. Pull Request gönderin

---

## Geliştirme Ortamı

### Gereksinimler

- Python 3.9+
- Django 4.0+
- Paperless-ngx kurulu sistem (test için)

### Kurulum

```bash
# Repo'yu klonla
git clone https://github.com/YOUR_USERNAME/paperless-regex-extractor.git
cd paperless-regex-extractor

# Virtual environment
python -m venv venv
source venv/bin/activate  # Linux/Mac
# veya
venv\Scripts\activate  # Windows

# Test dependencies
pip install pytest pytest-django
```

### Test

```bash
# Tüm testler
pytest

# Belirli test
pytest tests/test_extraction.py

# Coverage
pytest --cov=src
```

---

## Kod Standartları

### Python

- PEP 8 uyumlu kod
- Type hints kullanın
- Docstring yazın (Google style)
- Maximum line length: 88 (black formatter)

```python
def extract_value(
    content: str,
    pattern: str,
    group: int = 1
) -> Optional[str]:
    """
    Verilen içerikten regex pattern ile değer çıkarır.
    
    Args:
        content: Doküman içeriği
        pattern: Regex pattern
        group: Capture group numarası
        
    Returns:
        Çıkarılan değer veya None
    """
    ...
```

### JSON (Templates)

- 2 space indentation
- Trailing comma yok
- UTF-8 encoding
- Açıklayıcı description

---

## Commit Mesajları

[Conventional Commits](https://www.conventionalcommits.org/) kullanıyoruz:

```
<type>(<scope>): <description>

[optional body]

[optional footer]
```

### Types

- `feat`: Yeni özellik
- `fix`: Bug düzeltme
- `docs`: Dokümantasyon
- `style`: Format değişikliği (kod değişikliği yok)
- `refactor`: Kod refactoring
- `test`: Test ekleme/düzeltme
- `chore`: Build, config değişiklikleri

### Örnekler

```bash
feat(templates): add shipping category templates
fix(extraction): handle unicode characters in patterns
docs(readme): add docker installation section
test(handler): add unit tests for date conversion
```

---

## Pull Request Süreci

### PR Öncesi Checklist

- [ ] Testler geçiyor (`pytest`)
- [ ] Kod formatlanmış (`black .`)
- [ ] Lint hataları yok (`flake8`)
- [ ] Dokümantasyon güncel
- [ ] Commit mesajları conventional format

### PR Açma

1. `main` branch'ten güncel kalın:
   ```bash
   git checkout main
   git pull upstream main
   git checkout -b feature/your-feature
   ```

2. Değişikliklerinizi yapın ve commit edin

3. Push edin:
   ```bash
   git push origin feature/your-feature
   ```

4. GitHub'da PR açın

### PR Template

```markdown
## Açıklama
[Değişikliğin ne yaptığını açıklayın]

## İlgili Issue
Fixes #123

## Değişiklik Türü
- [ ] Bug fix
- [ ] Yeni özellik
- [ ] Breaking change
- [ ] Dokümantasyon

## Checklist
- [ ] Testler eklendi/güncellendi
- [ ] Dokümantasyon güncellendi
- [ ] Kod review için hazır
```

---

## Yeni Şablon Ekleme

### Template Yapısı

`src/templates/default_templates.json` dosyasına yeni category veya field ekleyin:

```json
{
  "templates": {
    "your_category": {
      "name": "Kategori Adı",
      "description": "Kategori açıklaması",
      "fields": [
        {
          "name": "Alan Adı",
          "data_type": "string|integer|float|date|monetary|boolean",
          "extraction_pattern": "REGEX_PATTERN_HERE",
          "extraction_group": 1,
          "description": "Alan açıklaması"
        }
      ]
    }
  }
}
```

### Regex Kuralları

1. **Capture Group:** En az bir `()` olmalı
2. **Escape:** JSON'da `\` yerine `\\` kullanın
3. **Türkçe:** `[A-ZÇĞİÖŞÜa-zçğıöşü]` kullanın
4. **Test:** regex101.com'da test edin

### Örnek PR

```markdown
## Yeni Şablon: E-Ticaret

E-ticaret siparişleri için yeni şablonlar:
- Sipariş numarası
- Kargo takip no
- Ürün kodu

### Test Edildi
- [x] Trendyol siparişleri
- [x] Hepsiburada siparişleri
- [x] Amazon.com.tr siparişleri
```

---

## Sorular?

- [Discussions](https://github.com/serefkoca46/paperless-regex-extractor/discussions) sayfasını kullanın
- Issue açın

Katkılarınız için teşekkürler! 🎉
