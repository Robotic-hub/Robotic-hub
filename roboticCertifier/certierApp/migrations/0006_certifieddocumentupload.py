# Generated by Django 4.2.15 on 2024-10-10 12:34

from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('certierApp', '0005_customuser'),
    ]

    operations = [
        migrations.CreateModel(
            name='CertifiedDocumentUpload',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('uploaded_at', models.DateTimeField(auto_now=True, null=True)),
                ('stamp', models.ImageField(blank=True, null=True, upload_to='stamps', verbose_name='Stamb_image')),
                ('email', models.EmailField(blank=True, max_length=254, null=True, verbose_name='Email')),
            ],
        ),
    ]