from django.db import models
from django.contrib.auth.models import AbstractUser
 


class userDocuments(models.Model):
    pdf=models.FileField(upload_to='pdfs/',verbose_name='Document',blank=True,null=True)
    image=models.ImageField(upload_to='images/',verbose_name='Document',blank=True,null=True)
    uploaded_at=models.DateTimeField(auto_now=True,blank=True,null=True)
    email = models.EmailField(verbose_name="Email",max_length=254,blank=True,null=True)
    
    def __str__(self):
        return self.email

from django.contrib.auth.models import AbstractUser
from django.db import models

class CustomUser(AbstractUser):
    # Add related_name attributes to avoid the clashes
    groups = models.ManyToManyField(
        'auth.Group',
        related_name='customuser_set',  # Use a custom related name to avoid clashes
        blank=True,
        help_text=('The groups this user belongs to. A user will get all permissions '
                   'granted to each of their groups.'),
        verbose_name=('groups'),
    )
    user_permissions = models.ManyToManyField(
        'auth.Permission',
        related_name='customuser_set',  # Use a custom related name to avoid clashes
        blank=True,
        help_text=('Specific permissions for this user.'),
        verbose_name=('user permissions'),
    )
