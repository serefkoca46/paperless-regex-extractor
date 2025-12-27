# -*- coding: utf-8 -*-
"""
Paperless Regex Extractor - Signal Handler

Bu modül doküman consume edildikten sonra otomatik olarak
regex pattern'lere göre özel alan değerlerini çıkarır.

Kullanım:
    Bu dosyayı paperless-ngx/src/documents/signals/ klasörüne kopyalayın
    ve apps.py dosyasına import edin.
"""

import re
import logging
from typing import Optional, Any, Dict, List

from django.dispatch import receiver
from documents.signals import document_consumption_finished
from documents.models import Document, CustomField, CustomFieldInstance


logger = logging.getLogger('paperless.regex_extractor')


class RegexExtractor:
    """
    Regex tabanlı değer çıkarma işlemlerini yöneten sınıf.
    """
    
    @staticmethod
    def extract_value(
        content: str,
        pattern: str,
        group: int = 1
    ) -> Optional[str]:
        """
        Verilen içerikten regex pattern ile değer çıkarır.
        
        Args:
            content: Doküman içeriği
            pattern: Regex pattern (capture group içermeli)
            group: Hangi capture group kullanılacak (default: 1)
            
        Returns:
            Çıkarılan değer veya None
        """
        if not content or not pattern:
            return None
            
        try:
            # Pattern'i compile et
            regex = re.compile(pattern, re.IGNORECASE | re.MULTILINE | re.DOTALL)
            
            # İçerikte ara
            match = regex.search(content)
            
            if match:
                # Belirtilen group'u al
                try:
                    value = match.group(group)
                    if value:
                        # Whitespace temizle
                        return value.strip()
                except IndexError:
                    logger.warning(
                        f"Pattern '{pattern}' için group {group} bulunamadı"
                    )
                    return None
                    
        except re.error as e:
            logger.error(f"Geçersiz regex pattern '{pattern}': {e}")
            
        return None
    
    @staticmethod
    def get_extraction_fields() -> List[CustomField]:
        """
        Extraction aktif olan özel alanları getirir.
        
        Returns:
            CustomField listesi
        """
        return CustomField.objects.filter(
            extraction_enabled=True,
            extraction_pattern__isnull=False
        ).exclude(
            extraction_pattern=''
        )
    
    @staticmethod
    def convert_value(value: str, field_type: str) -> Any:
        """
        Çıkarılan değeri alan tipine göre dönüştürür.
        
        Args:
            value: Ham string değer
            field_type: CustomField data_type
            
        Returns:
            Dönüştürülmüş değer
        """
        if not value:
            return None
            
        try:
            if field_type == 'integer':
                # Sadece rakamları al
                clean_value = re.sub(r'[^\d-]', '', value)
                return int(clean_value) if clean_value else None
                
            elif field_type == 'float':
                # Virgülü noktaya çevir, sadece sayıları al
                clean_value = value.replace(',', '.').replace(' ', '')
                clean_value = re.sub(r'[^\d.-]', '', clean_value)
                return float(clean_value) if clean_value else None
                
            elif field_type == 'monetary':
                # Para birimi formatı: 1.234,56 → 1234.56
                clean_value = value.replace('.', '').replace(',', '.')
                clean_value = re.sub(r'[^\d.-]', '', clean_value)
                return float(clean_value) if clean_value else None
                
            elif field_type == 'date':
                # Tarih formatlarını parse et
                # TODO: dateutil.parser kullanılabilir
                return value
                
            elif field_type == 'boolean':
                return value.lower() in ('true', 'yes', 'evet', '1', 'aktif')
                
            else:
                # string, text, url, documentlink vb.
                return value
                
        except (ValueError, TypeError) as e:
            logger.warning(f"Değer dönüştürme hatası: {value} → {field_type}: {e}")
            return value  # Dönüştürme başarısız, string olarak döndür


@receiver(document_consumption_finished)
def auto_extract_custom_fields(
    sender,
    document: Document,
    **kwargs
) -> Dict[str, Any]:
    """
    Doküman consume edildikten sonra otomatik regex extraction yapar.
    
    Args:
        sender: Signal gönderen
        document: İşlenen doküman
        **kwargs: Ek parametreler
        
    Returns:
        Çıkarılan değerlerin dict'i
    """
    extractor = RegexExtractor()
    results = {}
    
    # Doküman içeriğini al
    content = document.content or ''
    
    if not content:
        logger.debug(f"Doküman #{document.pk} için içerik bulunamadı")
        return results
    
    # Extraction aktif alanları getir
    extraction_fields = extractor.get_extraction_fields()
    
    if not extraction_fields:
        logger.debug("Extraction aktif özel alan bulunamadı")
        return results
    
    logger.info(
        f"Doküman #{document.pk} için {len(extraction_fields)} alan extract ediliyor"
    )
    
    for field in extraction_fields:
        try:
            # Değeri çıkar
            raw_value = extractor.extract_value(
                content=content,
                pattern=field.extraction_pattern,
                group=field.extraction_group or 1
            )
            
            if raw_value:
                # Değeri alan tipine göre dönüştür
                converted_value = extractor.convert_value(
                    value=raw_value,
                    field_type=field.data_type
                )
                
                if converted_value is not None:
                    # CustomFieldInstance oluştur veya güncelle
                    instance, created = CustomFieldInstance.objects.update_or_create(
                        document=document,
                        field=field,
                        defaults={'value': converted_value}
                    )
                    
                    action = 'oluşturuldu' if created else 'güncellendi'
                    logger.info(
                        f"  ✓ {field.name}: '{converted_value}' ({action})"
                    )
                    
                    results[field.name] = converted_value
                else:
                    logger.debug(
                        f"  - {field.name}: Dönüştürme sonucu boş"
                    )
            else:
                logger.debug(
                    f"  - {field.name}: Eşleşme bulunamadı"
                )
                
        except Exception as e:
            logger.error(
                f"  ✗ {field.name} extraction hatası: {e}",
                exc_info=True
            )
    
    if results:
        logger.info(
            f"Doküman #{document.pk}: {len(results)} alan başarıyla extract edildi"
        )
    
    return results


# Test fonksiyonu
def test_extraction():
    """
    Extraction modülünü test eder.
    
    Kullanım:
        from signals.extraction_handler import test_extraction
        test_extraction()
    """
    extractor = RegexExtractor()
    
    test_cases = [
        {
            'name': 'Tesisat Numarası',
            'content': 'Tesisat: 1234567890-123-ABC',
            'pattern': r'(\d{10})-\d+-',
            'expected': '1234567890'
        },
        {
            'name': 'IBAN',
            'content': 'ALICI HESAP / IBAN TR12 3456 7890 1234 5678 9012 34',
            'pattern': r'ALICI HESAP.*?(TR\d{2}[\s\d]+\d{2})',
            'expected': 'TR12 3456 7890 1234 5678 9012 34'
        },
        {
            'name': 'Tutar',
            'content': 'İŞLEM TUTARI 1.234,56 TL',
            'pattern': r'İŞLEM TUTARI\s+([\d.,]+)\s*TL',
            'expected': '1.234,56'
        },
    ]
    
    print("\n=== Regex Extractor Test ===")
    
    for test in test_cases:
        result = extractor.extract_value(
            content=test['content'],
            pattern=test['pattern']
        )
        
        status = '✓' if result == test['expected'] else '✗'
        print(f"{status} {test['name']}: '{result}' (beklenen: '{test['expected']}')") 
    
    print("\n=== Test Tamamlandı ===")
