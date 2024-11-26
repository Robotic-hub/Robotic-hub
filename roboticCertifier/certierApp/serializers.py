 
from .models import userDocuments,CertifiedDocumentUpload
from rest_framework import serializers 
from django.contrib.auth import get_user_model 

User = get_user_model()

class UserRegistrationSerializer(serializers.ModelSerializer):
    password = serializers.CharField(write_only=True)

    class Meta:
        model = User
        fields = ['email', 'password']

    def create(self, validated_data):
        user = User(email=validated_data['email'])
        user.set_password(validated_data['password'])
        user.save()
        return user
class CertifiedDocumentSerializers(serializers.ModelSerializer):
    class Meta:
        model = CertifiedDocumentUpload
        fields = ['stamp','uploaded_at','address']

class FileSerializers(serializers.ModelSerializer):
    class Meta:
        model = userDocuments
        fields = ['image', 'pdf','email','address']
        

    def validate_image(self, image):
        if image.size > 5 * 1024 * 1024: 
            raise serializers.ValidationError("Image size should be less than 5MB.")
        return image

    def validate_pdf(self, pdf):
        if pdf.size > 10 * 1024 * 1024:  
            raise serializers.ValidationError("PDF size should be less than 10MB.")
        return pdf
# serializers.py

class UserLoginSerializer(serializers.Serializer):
    email = serializers.EmailField()
    password = serializers.CharField()

    def validate(self, attrs):
        email = attrs.get('email')
        password = attrs.get('password')

        user = User.objects.filter(email=email).first()
        if user is None or not user.check_password(password):
            raise serializers.ValidationError("Invalid email or password")

        attrs['user'] = user
        return attrs
