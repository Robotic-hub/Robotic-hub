from django.conf import settings
from rest_framework.response import Response
from rest_framework.decorators import api_view,permission_classes
from rest_framework import status
from .serializers import FileSerializers  
from rest_framework.permissions import AllowAny,IsAuthenticated
from .serializers import UserRegistrationSerializer 
from django.shortcuts import get_object_or_404, render, redirect
from django.contrib.auth import authenticate, login
from django.contrib import messages
from django.contrib.auth.decorators import login_required
from .models import userDocuments  
from rest_framework.permissions import AllowAny
from rest_framework.decorators import api_view, permission_classes
from rest_framework.response import Response
from django.core.mail import EmailMessage
from django.views.decorators.csrf import csrf_exempt 
@api_view(['POST'])
def register_user(request):
    serializer = UserRegistrationSerializer(data=request.data)
    if serializer.is_valid():
        serializer.save()
        return Response({'message': 'User created successfully!'}, status=status.HTTP_201_CREATED)
    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

 
def home(request): 
    documents = userDocuments.objects.all() 
    context = {
        'documents': documents
    }
    return render(request, 'index.html', context)
def done(request):  
    return render(request, 'done.html', )

@permission_classes([AllowAny])
@api_view(['POST'])
def upload_file(request):  
    if 'file' not in request.FILES:
        return Response({'error': 'No file provided!'}, status=400)
    
    file = request.FILES['file']
    file_type = file.content_type
     
    email = request.data.get('email', None)
     
    if not email:
        return Response({'error': 'Email is required!'}, status=400)
     
    if file_type.startswith('image/'): 
        serializers = FileSerializers(data={'image': file, 'email': email})
    elif file_type.startswith('application/pdf'): 
        serializers = FileSerializers(data={'pdf': file, 'email': email})
    else:
        return Response({'error': 'Invalid file type. Only images and PDFs are allowed!'}, status=400)
 
    if serializers.is_valid():
        serializers.save()
        return Response(serializers.data, status=201)
 
    return Response(serializers.errors, status=400)
 




from django.shortcuts import render, redirect
from django.core.mail import EmailMessage
from django.conf import settings
from django.views.decorators.http import require_POST

@require_POST
def upload_certified_document(request):
    if 'file' not in request.FILES or 'email' not in request.POST:
        return render(request, 'error.html', {'error': 'No file or email provided!'})
    
    file = request.FILES['file']
    email = request.POST['email']
    file_type = file.content_type
    
    if not (file_type.startswith('image/') or file_type.startswith('application/pdf')):
        return render(request, 'your_template.html', {'error': 'Invalid file type. Only images and PDFs are allowed!'})

    email_message = EmailMessage(
        subject='Your Certified Document Feedback',
        body='Please find the document attached.',
        from_email=settings.EMAIL_HOST_USER,
        to=[email]
    )

    email_message.attach(file.name, file.read(), file.content_type)

    try:
        email_message.send()
        user_doc = get_object_or_404(userDocuments, email=email) 
        user_doc.delete()
        return redirect('success_url')  
    except Exception as e:
        print(f"Failed to send email: {str(e)}")
        return render(request, 'error.html', {'error': str(e)})

def login_user(request):
    if request.method == 'POST':
        email = request.POST.get('email')
        password = request.POST.get('password')
        user = authenticate(request, username=email, password=password)
        if user is not None:
            login(request, user)
            return redirect('home')   
        else: 
            messages.error(request, 'Invalid email or password.')
            return redirect('login_user')                  

    return render(request, 'login.html')  
     