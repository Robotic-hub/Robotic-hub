from django.conf import settings
from django.conf.urls.static import static
from django.urls import path
from . import views

urlpatterns = [
    path('upload_document/',views.upload_file,name='upload_files'),
    path('completed/',views.done,name='success_url'),
    path('upload_certified_document/',views.upload_certified_document,name='upload_certified_document'), 
    path('create_stamp/',views.create_stamp,name='create_stamp'), 
    path('upload_stamp/',views.upload_stamp,name='upload_stamp'), 
    path('get_stamp/',views.get_stamp,name='get_stamp'), 
    path('home/',views.home,name='home'),
    path('', views.login_user, name='login_user'),
    
]

urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)
