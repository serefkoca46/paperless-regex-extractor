# -*- coding: utf-8 -*-
"""
Paperless Regex Extractor - Database Migration

Bu migration CustomField modeline regex extraction alanlarını ekler:
- extraction_enabled: Otomatik extraction aktif mi?
- extraction_pattern: Regex pattern
- extraction_group: Hangi capture group kullanılacak (default: 1)

Kullanım:
    python manage.py migrate documents 0001_add_extraction_fields
"""

from django.db import migrations, models


class Migration(migrations.Migration):
    """
    CustomField modeline regex extraction alanlarını ekleyen migration.
    """

    dependencies = [
        ('documents', '0046_customfield'),  # CustomField migration'ından sonra
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
                help_text='Değer çıkarmak için kullanılacak regex pattern. Örnek: (\\d{10})-\\d+-'
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


class ReversesMigration(migrations.Migration):
    """
    Rollback için migration - alanları kaldırır.
    """
    
    dependencies = [
        ('documents', '0001_add_extraction_fields'),
    ]

    operations = [
        migrations.RemoveField(
            model_name='customfield',
            name='extraction_enabled',
        ),
        migrations.RemoveField(
            model_name='customfield',
            name='extraction_pattern',
        ),
        migrations.RemoveField(
            model_name='customfield',
            name='extraction_group',
        ),
    ]
