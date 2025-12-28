#!/bin/bash
#
# Paperless Regex Extractor - Installer Script
# https://github.com/serefkoca46/paperless-regex-extractor
#
# Kullanım:
#   curl -fsSL https://raw.githubusercontent.com/serefkoca46/paperless-regex-extractor/main/install.sh | bash
#
# veya:
#   wget -qO- https://raw.githubusercontent.com/serefkoca46/paperless-regex-extractor/main/install.sh | bash
#

set -e

# Renkler
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Banner
echo -e "${BLUE}"
cat << 'EOF'
╔═══════════════════════════════════════════════════════════════╗
║     ____                       __                             ║
║    / __ \___  ____ ____  _  __/ /_  _________ _____  ___      ║
║   / /_/ / _ \/ __ `/ _ \| |/_/ __/ / ___/ __ `/ __ \/ _ \     ║
║  / ____/  __/ /_/ /  __/>  </ /__ / /  / /_/ / / / /  __/     ║
║ /_/    \___/\__, /\___/_/|_|\__(_)_/   \__,_/_/ /_/\___/      ║
║            /____/                                              ║
║                                                                ║
║            Paperless Regex Extractor v1.1.0                    ║
║      Otomatik Değer Çıkarma Eklentisi - Paperless-ngx          ║
╚═══════════════════════════════════════════════════════════════╝
EOF
echo -e "${NC}"

# Fonksiyonlar
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[✓]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[!]${NC} $1"
}

log_error() {
    echo -e "${RED}[✗]${NC} $1"
}

# Paperless-ngx dizinini bul
find_paperless_dir() {
    # Yaygın konumlar
    local dirs=(
        "/opt/paperless"
        "/opt/paperless-ngx"
        "/usr/src/paperless"
        "$HOME/paperless-ngx"
        "$HOME/paperless"
        "/var/lib/paperless"
    )
    
    for dir in "${dirs[@]}"; do
        if [[ -d "$dir/src/documents" ]]; then
            echo "$dir"
            return 0
        fi
    done
    
    # Docker volume kontrol
    if [[ -d "/usr/src/paperless/src/documents" ]]; then
        echo "/usr/src/paperless"
        return 0
    fi
    
    return 1
}

# En son migration'ı bul
get_latest_migration() {
    local migrations_dir="$1"
    
    # En yüksek numaralı migration'ı bul
    local latest=$(ls -1 "$migrations_dir"/*.py 2>/dev/null | \
        grep -v '__pycache__' | \
        grep -v '__init__' | \
        sed 's/.*\///' | \
        grep -E '^[0-9]+_' | \
        sort -t'_' -k1 -n | \
        tail -1)
    
    if [[ -n "$latest" ]]; then
        # Dosya adından numarayı ve tam adı çıkar
        local num=$(echo "$latest" | grep -oE '^[0-9]+')
        local name=$(echo "$latest" | sed 's/\.py$//')
        echo "$num:$name"
        return 0
    fi
    
    return 1
}

# Gereksinimler kontrolü
check_requirements() {
    log_info "Gereksinimler kontrol ediliyor..."
    
    # Python kontrolü
    if command -v python3 &> /dev/null; then
        PYTHON_VERSION=$(python3 --version 2>&1 | awk '{print $2}')
        log_success "Python $PYTHON_VERSION bulundu"
    else
        log_error "Python 3 bulunamadı!"
        exit 1
    fi
    
    # Django kontrolü
    if python3 -c "import django" 2>/dev/null; then
        DJANGO_VERSION=$(python3 -c "import django; print(django.VERSION[:2])" 2>/dev/null)
        log_success "Django $DJANGO_VERSION bulundu"
    else
        log_warning "Django bulunamadı - paperless-ngx ortamında çalıştırılmalı"
    fi
    
    # Paperless dizini
    if PAPERLESS_DIR=$(find_paperless_dir); then
        log_success "Paperless dizini bulundu: $PAPERLESS_DIR"
    else
        log_warning "Paperless dizini otomatik bulunamadı"
        read -p "Paperless-ngx dizinini girin: " PAPERLESS_DIR
        
        if [[ ! -d "$PAPERLESS_DIR/src/documents" ]]; then
            log_error "Geçersiz Paperless dizini: $PAPERLESS_DIR"
            exit 1
        fi
    fi
}

# Dosyaları indir ve kur
install_files() {
    log_info "Dosyalar indiriliyor..."
    
    REPO_URL="https://raw.githubusercontent.com/serefkoca46/paperless-regex-extractor/main"
    TEMP_DIR=$(mktemp -d)
    
    # Migration dosyası
    log_info "Migration dosyası indiriliyor..."
    curl -fsSL "$REPO_URL/src/migrations/0001_add_extraction_fields.py" \
        -o "$TEMP_DIR/0001_add_extraction_fields.py"
    
    # Signal handler
    log_info "Signal handler indiriliyor..."
    curl -fsSL "$REPO_URL/src/signals/extraction_handler.py" \
        -o "$TEMP_DIR/extraction_handler.py"
    
    # Templates
    log_info "Şablonlar indiriliyor..."
    curl -fsSL "$REPO_URL/src/templates/default_templates.json" \
        -o "$TEMP_DIR/default_templates.json"
    
    log_success "Dosyalar indirildi"
    
    # Migration dosyasını dinamik olarak güncelle
    MIGRATIONS_DIR="$PAPERLESS_DIR/src/documents/migrations"
    if [[ -d "$MIGRATIONS_DIR" ]]; then
        log_info "En son migration tespit ediliyor..."
        
        LATEST_INFO=$(get_latest_migration "$MIGRATIONS_DIR")
        if [[ -n "$LATEST_INFO" ]]; then
            LATEST_NUM=$(echo "$LATEST_INFO" | cut -d':' -f1)
            LATEST_NAME=$(echo "$LATEST_INFO" | cut -d':' -f2)
            NEW_NUM=$((LATEST_NUM + 1))
            
            log_success "En son migration: $LATEST_NAME (No: $LATEST_NUM)"
            log_info "Yeni migration numarası: $NEW_NUM"
            
            # Migration dosyasını güncelle
            NEW_MIGRATION_FILE="${NEW_NUM}_add_extraction_fields.py"
            
            # Dependency'yi güncelle
            sed -i.bak "s/dependencies = \[.*\]/dependencies = [\n        ('documents', '$LATEST_NAME'),\n    ]/" \
                "$TEMP_DIR/0001_add_extraction_fields.py" 2>/dev/null || \
            sed "s/dependencies = \[.*\]/dependencies = [\n        ('documents', '$LATEST_NAME'),\n    ]/" \
                "$TEMP_DIR/0001_add_extraction_fields.py" > "$TEMP_DIR/temp_migration.py" && \
                mv "$TEMP_DIR/temp_migration.py" "$TEMP_DIR/0001_add_extraction_fields.py"
            
            # Doğrudan Python ile güncelle (daha güvenilir)
            python3 << PYEOF
import re

# Migration dosyasını oku
with open("$TEMP_DIR/0001_add_extraction_fields.py", "r") as f:
    content = f.read()

# Dependencies satırını güncelle
new_deps = """dependencies = [
        ('documents', '$LATEST_NAME'),
    ]"""

# Regex ile değiştir
content = re.sub(
    r"dependencies\s*=\s*\[.*?\]",
    new_deps,
    content,
    flags=re.DOTALL
)

# Yaz
with open("$TEMP_DIR/0001_add_extraction_fields.py", "w") as f:
    f.write(content)

print("Migration dependency güncellendi: $LATEST_NAME")
PYEOF
            
            # Yeni isimle kopyala
            cp "$TEMP_DIR/0001_add_extraction_fields.py" "$MIGRATIONS_DIR/$NEW_MIGRATION_FILE"
            log_success "Migration kopyalandı: $MIGRATIONS_DIR/$NEW_MIGRATION_FILE"
        else
            log_warning "Mevcut migration bulunamadı, varsayılan kullanılıyor"
            cp "$TEMP_DIR/0001_add_extraction_fields.py" "$MIGRATIONS_DIR/"
            log_success "Migration kopyalandı: $MIGRATIONS_DIR/"
        fi
    else
        log_warning "Migrations dizini bulunamadı: $MIGRATIONS_DIR"
    fi
    
    # Signal handler
    SIGNALS_DIR="$PAPERLESS_DIR/src/documents/signals"
    mkdir -p "$SIGNALS_DIR"
    cp "$TEMP_DIR/extraction_handler.py" "$SIGNALS_DIR/"
    log_success "Signal handler kopyalandı: $SIGNALS_DIR/"
    
    # Templates
    TEMPLATES_DIR="$PAPERLESS_DIR/data/regex_templates"
    mkdir -p "$TEMPLATES_DIR"
    cp "$TEMP_DIR/default_templates.json" "$TEMPLATES_DIR/"
    log_success "Şablonlar kopyalandı: $TEMPLATES_DIR/"
    
    # Temizlik
    rm -rf "$TEMP_DIR"
}

# Signal handler'ı aktifleştir (Lazy import ile)
activate_handler() {
    log_info "Signal handler aktifleştiriliyor (lazy import)..."
    
    SIGNALS_INIT="$PAPERLESS_DIR/src/documents/signals/__init__.py"
    
    # Lazy import kullan - circular import'u önlemek için
    HANDLER_IMPORT="# Paperless Regex Extractor - Lazy signal binding
try:
    from .extraction_handler import connect_signal
except ImportError:
    pass"
    
    if [[ -f "$SIGNALS_INIT" ]]; then
        if grep -q "extraction_handler" "$SIGNALS_INIT"; then
            log_success "Handler zaten aktif"
        else
            echo "" >> "$SIGNALS_INIT"
            echo "$HANDLER_IMPORT" >> "$SIGNALS_INIT"
            log_success "Handler __init__.py'a eklendi (lazy import)"
        fi
    else
        # __init__.py yoksa oluştur
        echo "# Paperless Signals" > "$SIGNALS_INIT"
        echo "$HANDLER_IMPORT" >> "$SIGNALS_INIT"
        log_success "__init__.py oluşturuldu ve handler eklendi"
    fi
    
    # apps.py'a signal connection ekle
    APPS_FILE="$PAPERLESS_DIR/src/documents/apps.py"
    if [[ -f "$APPS_FILE" ]]; then
        if grep -q "connect_signal" "$APPS_FILE"; then
            log_success "Signal connection zaten apps.py'da mevcut"
        else
            log_info "apps.py'a signal connection ekleniyor..."
            
            # Python ile apps.py'ı güncelle
            python3 << PYEOF
import re

with open("$APPS_FILE", "r") as f:
    content = f.read()

# ready() metodunu bul ve signal connection ekle
if "def ready(self):" in content:
    # ready() metodunun sonuna ekle
    signal_code = '''
        # Paperless Regex Extractor - Signal bağlantısı
        try:
            from documents.signals.extraction_handler import connect_signal
            connect_signal()
        except Exception:
            pass  # Extraction modülü kurulu değilse sessizce geç
'''
    
    # ready() metodunun içine ekle
    # Mevcut ready() içeriğinin sonuna ekle
    if "connect_signal" not in content:
        # ready metodunun sonunu bul ve ekle
        lines = content.split('\n')
        new_lines = []
        in_ready = False
        ready_indent = 0
        
        for i, line in enumerate(lines):
            new_lines.append(line)
            
            if "def ready(self):" in line:
                in_ready = True
                ready_indent = len(line) - len(line.lstrip()) + 4
            elif in_ready:
                # ready() metodunun sonunu tespit et
                current_indent = len(line) - len(line.lstrip())
                if line.strip() and current_indent <= ready_indent - 4 and not line.strip().startswith('#'):
                    # ready() metodu bitti, signal kodunu ekle
                    new_lines.insert(-1, signal_code)
                    in_ready = False
        
        # Eğer ready() dosyanın sonundaysa
        if in_ready:
            new_lines.append(signal_code)
        
        content = '\n'.join(new_lines)
        
        with open("$APPS_FILE", "w") as f:
            f.write(content)
        
        print("Signal connection apps.py'a eklendi")
else:
    print("ready() metodu bulunamadı - manuel ekleme gerekebilir")
PYEOF
            
            log_success "apps.py güncellendi"
        fi
    else
        log_warning "apps.py bulunamadı: $APPS_FILE"
    fi
}

# Migration çalıştır
run_migration() {
    log_info "Database migration çalıştırılıyor..."
    
    cd "$PAPERLESS_DIR/src"
    
    if [[ -f "../manage.py" ]]; then
        cd ..
        python3 manage.py migrate documents 2>/dev/null && log_success "Migration tamamlandı" || log_warning "Migration atlandı (zaten uygulanmış olabilir)"
    elif [[ -f "manage.py" ]]; then
        python3 manage.py migrate documents 2>/dev/null && log_success "Migration tamamlandı" || log_warning "Migration atlandı (zaten uygulanmış olabilir)"
    else
        log_warning "manage.py bulunamadı - Migration manuel çalıştırılmalı"
        log_info "Komut: python3 manage.py migrate documents"
    fi
}

# Kurulumu doğrula
verify_installation() {
    log_info "Kurulum doğrulanıyor..."
    
    # Signal handler dosyası
    if [[ -f "$PAPERLESS_DIR/src/documents/signals/extraction_handler.py" ]]; then
        log_success "Signal handler dosyası mevcut"
    else
        log_error "Signal handler dosyası eksik!"
        return 1
    fi
    
    # Migration dosyası
    if ls "$PAPERLESS_DIR/src/documents/migrations/"*_add_extraction_fields.py 1>/dev/null 2>&1; then
        log_success "Migration dosyası mevcut"
    else
        log_error "Migration dosyası eksik!"
        return 1
    fi
    
    # Database alanları kontrol et
    cd "$PAPERLESS_DIR"
    python3 << PYEOF 2>/dev/null && log_success "Database alanları doğrulandı" || log_warning "Database alanları kontrol edilemedi"
import os
import sys
import django

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'paperless.settings')
sys.path.insert(0, 'src')

django.setup()

from documents.models import CustomField

# Alanları kontrol et
fields = [f.name for f in CustomField._meta.get_fields()]
required = ['extraction_enabled', 'extraction_pattern', 'extraction_group']

missing = [f for f in required if f not in fields]
if missing:
    print(f"Eksik alanlar: {missing}")
    sys.exit(1)
else:
    print("Tüm extraction alanları mevcut")
    sys.exit(0)
PYEOF
    
    return 0
}

# Docker yeniden başlat
restart_services() {
    log_info "Servisler yeniden başlatılıyor..."
    
    if command -v docker &> /dev/null; then
        # Docker container'ı bul ve yeniden başlat
        CONTAINER=$(docker ps --format '{{.Names}}' | grep -i paperless | head -1)
        
        if [[ -n "$CONTAINER" ]]; then
            docker restart "$CONTAINER" 2>/dev/null && \
                log_success "Container yeniden başlatıldı: $CONTAINER" || \
                log_warning "Container yeniden başlatılamadı"
        else
            log_warning "Paperless container bulunamadı"
        fi
    else
        log_info "Paperless servisini manuel yeniden başlatın"
    fi
}

# Ana akış
main() {
    echo ""
    log_info "Kurulum başlıyor..."
    echo ""
    
    check_requirements
    install_files
    activate_handler
    run_migration
    
    echo ""
    log_info "Kurulum doğrulanıyor..."
    if verify_installation; then
        echo ""
        log_success "══════════════════════════════════════════════════════════════"
        log_success "  Kurulum başarıyla tamamlandı!"
        log_success "══════════════════════════════════════════════════════════════"
    else
        echo ""
        log_warning "══════════════════════════════════════════════════════════════"
        log_warning "  Kurulum tamamlandı ancak bazı kontroller başarısız oldu."
        log_warning "  Lütfen manuel olarak doğrulayın."
        log_warning "══════════════════════════════════════════════════════════════"
    fi
    
    echo ""
    log_info "Sonraki adımlar:"
    echo "  1. Paperless-ngx'i yeniden başlatın"
    echo "  2. Admin panelinden özel alanları oluşturun"
    echo "  3. 'Otomatik Extraction' seçeneğini aktifleştirin"
    echo "  4. Regex pattern girin"
    echo ""
    log_info "Hazır şablonlar: $PAPERLESS_DIR/data/regex_templates/"
    log_info "Dokümantasyon: https://github.com/serefkoca46/paperless-regex-extractor"
    echo ""
    
    read -p "Servisleri şimdi yeniden başlatmak ister misiniz? (e/H): " restart_choice
    if [[ "$restart_choice" =~ ^[Ee]$ ]]; then
        restart_services
    fi
    
    echo ""
    log_success "İyi kullanımlar! 🎉"
}

# Çalıştır
main
