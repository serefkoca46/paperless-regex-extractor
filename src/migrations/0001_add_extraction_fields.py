# -*- coding: utf-8 -*-
"""
Paperless Regex Extractor - Database Migration

Bu migration CustomField modeline regex extraction alanlarını ekler:
- extraction_enabled: Otomatik extraction aktif mi?
- extraction_pattern: Regex pattern
- extraction_group: Hangi capture group kullanılacak (default: 1)

NOT: Bu migration dosyası kurulum sırasında otomatik olarak
en son migration'a bağımlı hale getirilir.
"""

from django.db import migrations, models


def get_latest_migration():
    """
    documents app'inin en son migration'ını bul.
    Bu fonksiyon kurulum scriptinde kullanılır.
    """
    import os
    import re
    
    migrations_dir = os.path.dirname(os.path.abspath(__file__))
    migrations = []
    
    for f in os.listdir(migrations_dir):
        if f.endswith('.py') and not f.startswith('__'):
            match = re.match(r'^(\d+)_', f)
            if match:
                migrations.append((int(match.group(1)), f[:-3]))
    
    if migrations:
        migrations.sort(key=lambda x: x[0], reverse=True)
        # extraction migration hariç en son migration
        for num, name in migrations:
            if 'extraction' not in name:
                return name
    
    return None


class Migration(migrations.Migration):
    """
    CustomField modeline regex extraction alanlarını ekleyen migration.
    
    Dependency otomatik olarak kurulum sırasında belirlenir.
    Manuel kurulum için: En son documents migration'ını dependency olarak girin.
    """

    # Bu değer kurulum scriptinde otomatik güncellenir
    # Örnek: ('documents', '1074_workflowrun_deleted_at_...')
    dependencies = [
        ('documents', '__latest__'),  # Placeholder - kurulumda güncellenir
    ]

    operations = [
        # extraction_enabled alanı
        migrations.AddField(
            model_name='customfield',
            name='extraction_enabled',
            field=models.BooleanField(
                default=False,
                verbose_name='Otomatik Extraction Aktif',
                help_text='Bu alan için otomatik regex extraction aktif edilsin mi?'
            ),
        ),
        
        # extraction_pattern alanı
        migrations.AddField(
            model_name='customfield',
            name='extraction_pattern',
            field=models.TextField(
                blank=True,
                null=True,
                verbose_name='Regex Pattern',
                help_text=r'Değer çıkarmak için kullanılacak regex pattern. Örnek: (\d{10})-\d+-'
            ),
        ),
        
        # extraction_group alanı
        migrations.AddField(
            model_name='customfield',
            name='extraction_group',
            field=models.PositiveSmallIntegerField(
                default=1,
                verbose_name='Capture Group',
                help_text='Hangi regex capture group kullanılacak (1 = ilk parantez)'
            ),
        ),
    ]
