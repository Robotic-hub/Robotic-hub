from django.conf import settings
from django.conf.urls.static import static
from django.urls import path
from . import views

urlpatterns = [
    
    path('upload_document/',views.upload_file,name='upload_files'), 
    path('home/',views.home,name='home'),
     
    path('', views.login_user, name='login_user'),
]

urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)
