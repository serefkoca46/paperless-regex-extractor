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
║            Paperless Regex Extractor v1.0.0                    ║
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
    
    # Dosyaları kopyala
    log_info "Dosyalar kurulum dizinine kopyalanıyor..."
    
    # Migration
    MIGRATIONS_DIR="$PAPERLESS_DIR/src/documents/migrations"
    if [[ -d "$MIGRATIONS_DIR" ]]; then
        cp "$TEMP_DIR/0001_add_extraction_fields.py" "$MIGRATIONS_DIR/"
        log_success "Migration kopyalandı: $MIGRATIONS_DIR/"
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

# Signal handler'ı aktifleştir
activate_handler() {
    log_info "Signal handler aktifleştiriliyor..."
    
    SIGNALS_INIT="$PAPERLESS_DIR/src/documents/signals/__init__.py"
    HANDLER_IMPORT="from .extraction_handler import auto_extract_custom_fields"
    
    if [[ -f "$SIGNALS_INIT" ]]; then
        if grep -q "extraction_handler" "$SIGNALS_INIT"; then
            log_success "Handler zaten aktif"
        else
            echo "" >> "$SIGNALS_INIT"
            echo "# Paperless Regex Extractor" >> "$SIGNALS_INIT"
            echo "$HANDLER_IMPORT" >> "$SIGNALS_INIT"
            log_success "Handler __init__.py'a eklendi"
        fi
    else
        # __init__.py yoksa oluştur
        echo "# Paperless Signals" > "$SIGNALS_INIT"
        echo "$HANDLER_IMPORT" >> "$SIGNALS_INIT"
        log_success "__init__.py oluşturuldu ve handler eklendi"
    fi
}

# Migration çalıştır
run_migration() {
    log_info "Database migration çalıştırılıyor..."
    
    cd "$PAPERLESS_DIR"
    
    if [[ -f "manage.py" ]]; then
        python3 manage.py migrate documents --fake-initial 2>/dev/null || true
        python3 manage.py migrate 2>/dev/null && log_success "Migration tamamlandı" || log_warning "Migration atlandı (zaten uygulanmış olabilir)"
    else
        log_warning "manage.py bulunamadı - Migration manuel çalıştırılmalı"
    fi
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
    log_success "══════════════════════════════════════════════════════════════"
    log_success "  Kurulum tamamlandı!"
    log_success "══════════════════════════════════════════════════════════════"
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
