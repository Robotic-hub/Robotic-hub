from django.contrib import admin

from .models import userDocuments,CertifiedDocumentUpload

# Register your models here.
admin.site.register(userDocuments)
admin.site.register(CertifiedDocumentUpload)

