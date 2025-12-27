# 🔍 Paperless Regex Extractor

**Automatic regex-based field extraction for Paperless-ngx**

Extract data from your documents automatically using custom regex patterns. Perfect for invoices, bank statements, receipts, and more.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Paperless-ngx](https://img.shields.io/badge/Paperless--ngx-2.x-green.svg)](https://github.com/paperless-ngx/paperless-ngx)

## ✨ Features

- 🎯 **Auto-extraction**: Automatically extract values from document content using regex
- 📋 **25+ Ready Templates**: Pre-built patterns for common fields (IBAN, dates, amounts, etc.)
- 🇹🇷 **Turkish Support**: Full Turkish character support in patterns
- 🧪 **Pattern Tester**: Test your regex patterns before saving
- 🔄 **Capture Groups**: Support for regex capture groups
- 📦 **Easy Install**: One-command installation script

## 📸 Screenshots

![Custom Field Editor](docs/images/screenshot.png)

## 🚀 Quick Install

### One-Line Installation

```bash
curl -sSL https://raw.githubusercontent.com/serefkoca46/paperless-regex-extractor/main/install.sh | bash
```

### Docker Installation

```bash
# Stop your Paperless-ngx container
docker compose down

# Run the installer inside container
docker exec -it paperless_container bash -c "$(curl -sSL https://raw.githubusercontent.com/serefkoca46/paperless-regex-extractor/main/install.sh)"

# Restart Paperless-ngx
docker compose up -d
```

### Manual Installation

```bash
# Clone the repository
git clone https://github.com/serefkoca46/paperless-regex-extractor.git
cd paperless-regex-extractor

# Run installer
./install.sh /path/to/paperless-ngx
```

## 📖 Usage

### 1. Create a Custom Field

1. Go to **Settings** → **Custom Fields**
2. Click **Add Field**
3. Enter field name and select data type

### 2. Enable Regex Extraction

1. Check **"Enable automatic extraction (Regex)"**
2. Select a ready template OR enter custom pattern
3. Set capture group (1 = first parenthesis group)
4. Test your pattern with sample text
5. Save

### 3. Upload Documents

Upload your documents as usual. The regex extractor will automatically:
- Parse document content
- Match your patterns
- Fill custom field values

## 📋 Ready Templates

| Template | Pattern | Example Match |
|----------|---------|---------------|
| 🏦 IBAN | `TR\d{2}\s?\d{4}...` | TR12 3456 7890... |
| 🪪 TC Kimlik | `[1-9]\d{10}` | 12345678901 |
| 📱 Telefon | `(\+90)?\s?5\d{2}...` | +90 532 123 45 67 |
| 📅 Tarih | `\d{2}[./]\d{2}[./]\d{4}` | 27.12.2025 |
| 💰 Tutar (TL) | `([\d.,]+)\s*TL` | 1.234,56 TL |
| 🔍 EFT Sorgu No | `EFT SORGU NO\s+(\d+)` | 8477077 |
| 🔢 İşlem No | `İŞLEM NO\s+(\d{10,20})` | 12345678901234 |
| 🏛️ Alıcı Banka | `ALICI BANKA\s+([^\n]+)` | AKBANK T.A.Ş. |
| 👤 Alıcı Ad | `ALICI AD\n([^\n]+)` | AHMET YILMAZ |
| ⚡ Tesisat No | `(\d{10})-\d+-` | 3020493873 |

[See all 25+ templates →](docs/TEMPLATES.md)

## 🔧 Configuration

### Environment Variables

```bash
# Enable/disable extraction globally
REGEX_EXTRACTION_ENABLED=true

# Log extraction results
REGEX_EXTRACTION_DEBUG=false

# Max content length to search (characters)
REGEX_MAX_CONTENT_LENGTH=100000
```

## 🏗️ Architecture

```
paperless-regex-extractor/
├── src/
│   ├── migrations/          # Database migrations
│   ├── signals/             # Django signals
│   ├── templates/           # Regex templates
│   └── frontend/            # Angular patches
├── install.sh               # Installer script
├── uninstall.sh             # Uninstaller script
└── docker/                  # Docker support
```

## 🔄 How It Works

1. **Document Upload**: User uploads a document
2. **OCR Processing**: Paperless-ngx extracts text content
3. **Signal Trigger**: `document_consumption_finished` signal fires
4. **Pattern Matching**: For each custom field with extraction enabled:
   - Get the regex pattern
   - Search document content
   - Extract capture group value
5. **Value Assignment**: Matched values are saved to custom fields

## 🤝 Contributing

Contributions are welcome! Please read our [Contributing Guide](CONTRIBUTING.md).

### Adding New Templates

1. Fork the repository
2. Add template to `src/templates/default_templates.json`
3. Test with sample documents
4. Submit a Pull Request

## 📄 License

MIT License - see [LICENSE](LICENSE) file.

## 🙏 Acknowledgments

- [Paperless-ngx](https://github.com/paperless-ngx/paperless-ngx) - The amazing document management system
- Turkish banking community for regex patterns

## 📞 Support

- 🐛 [Report Bug](https://github.com/serefkoca46/paperless-regex-extractor/issues)
- 💡 [Request Feature](https://github.com/serefkoca46/paperless-regex-extractor/issues)
- 💬 [Discussions](https://github.com/serefkoca46/paperless-regex-extractor/discussions)

---

**Made with ❤️ for the Paperless-ngx community**
