import streamlit as st
import cv2
import numpy as np
import mediapipe as mp
from sklearn.metrics.pairwise import cosine_similarity
import requests
from pdf2image import convert_from_bytes
from PIL import Image
import io
from reportlab.lib.utils import ImageReader 

from io import BytesIO
from PyPDF2 import PdfReader, PdfWriter
from reportlab.pdfgen import canvas
from reportlab.lib.pagesizes import letter 


st.title("Upload your ID for Face Verification")
st.write("Upload your document (ID or other), and let's verify your identity!")

mp_face_mesh = mp.solutions.face_mesh
mp_drawing = mp.solutions.drawing_utils
face_mesh = mp_face_mesh.FaceMesh(static_image_mode=True, max_num_faces=1, min_detection_confidence=0.5, min_tracking_confidence=0.5)

drawing_spec = mp_drawing.DrawingSpec(color=(0, 255, 0), thickness=1, circle_radius=1)
connection_spec = mp_drawing.DrawingSpec(color=(255, 0, 0), thickness=1, circle_radius=1)

email = st.text_input(label="Enter your email address")
with st.expander('Please choose your address'):
    res = requests.get('http://127.0.0.1:8000/get_stamp/')
    if  res.status_code == 200:
        data =  res.json()
        addresses = [item['address'] for item in data.get('data', []) if item['address'] is not None]
            
        if addresses: 
            options = st.radio('Addresses', addresses, index=0)
            st.write(f'This is the selected Address: {options}')
        else:
            st.write("No addresses available.")
    options =st.radio('Addresses',(data.get("address",[])),index=0)
    st.write(f'This is the selected Address {options}')
uploaded_file = st.file_uploader("Upload your ID document (Image/PDF)", type=["jpg", "png", "pdf"])

if 'face_match_success' not in st.session_state:
    st.session_state.face_match_success = False

if uploaded_file:
    file_bytes = np.asarray(bytearray(uploaded_file.read()), dtype=np.uint8)
    st.write(f"Uploaded file type: {uploaded_file.type}")

    if uploaded_file.type == "application/pdf":
        images = convert_from_bytes(file_bytes, first_page=1, last_page=1)
        id_image = np.array(images[0]) 
        id_image = cv2.cvtColor(id_image, cv2.COLOR_RGB2BGR)
    else:
        id_image = cv2.imdecode(file_bytes, 1)

    id_image_rgb = cv2.cvtColor(id_image, cv2.COLOR_BGR2RGB)
    id_results = face_mesh.process(id_image_rgb)

    if id_results.multi_face_landmarks:
        st.success("Face detected in the ID document.")
        for face_landmarks in id_results.multi_face_landmarks:
            mp_drawing.draw_landmarks(
                id_image,
                face_landmarks,
                mp_face_mesh.FACEMESH_TESSELATION,
                drawing_spec,
                connection_spec,
            )
        st.image(id_image, caption="ID Document with Detected Face", channels="BGR")

        start_webcam = st.button("Verify Your Face")
        if start_webcam:
            st.write("Now verifying your face with the live webcam.")
            cap = cv2.VideoCapture(0)
            stframe = st.empty()

            while cap.isOpened():
                ret, frame = cap.read()
                if not ret:
                    st.error("Failed to open the webcam.")
                    break

                frame_rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
                webcam_results = face_mesh.process(frame_rgb)

                if webcam_results.multi_face_landmarks:
                    for face_landmarks in webcam_results.multi_face_landmarks:
                        mp_drawing.draw_landmarks(
                            frame,
                            face_landmarks,
                            mp_face_mesh.FACEMESH_TESSELATION,
                            drawing_spec,
                            connection_spec,
                        )

                    stframe.image(frame, channels="BGR")

                    id_landmarks = np.array([[lm.x, lm.y, lm.z] for lm in id_results.multi_face_landmarks[0].landmark])
                    webcam_landmarks = np.array([[lm.x, lm.y, lm.z] for lm in webcam_results.multi_face_landmarks[0].landmark])

                    id_landmarks_vector = id_landmarks.flatten()
                    webcam_landmarks_vector = webcam_landmarks.flatten()

                    similarity = cosine_similarity([id_landmarks_vector], [webcam_landmarks_vector])[0][0]

                    if similarity > 0.95:
                        st.session_state.face_match_success = True
                        st.success(f"Face match successful with similarity: {similarity:.2f}")
                        cap.release()
                        break
                    else:
                        st.warning(f"Face mismatch: similarity {similarity:.2f}")
                if st.button("Stop Webcam"):
                    cap.release()
                    break

            cap.release()
            
  
def save_document_to_db(file, email,options):
    try:
        if file.type in ["image/jpeg", "image/png"]:
            image_data = np.asarray(bytearray(file.read()), dtype=np.uint8)
            image = cv2.imdecode(image_data, cv2.IMREAD_COLOR)
            pil_image = Image.fromarray(cv2.cvtColor(image, cv2.COLOR_BGR2RGB))
            
            a4_width, a4_height = 595, 842

            white_background = Image.new("RGB", (a4_width, a4_height), "white")

            max_width = a4_width - 50   
            max_height = a4_height - 50
            pil_image.thumbnail((max_width, max_height))

            x_offset = (a4_width - pil_image.width) // 2
            y_offset = (a4_height - pil_image.height) // 2

            white_background.paste(pil_image, (x_offset, y_offset))

            pdf_bytes = io.BytesIO()
            white_background.save(pdf_bytes, format='PDF')
            pdf_bytes.seek(0)

            files = {'file': (f"{file.name}.pdf", pdf_bytes, 'application/pdf')}
        else:
            file.seek(0)
            files = {'file': (file.name, file, file.type)}

        data = {'email': email, 'address':options}
        url = "http://127.0.0.1:8000/upload_document/"

        response = requests.post(url, files=files, data=data)

        if response.status_code == 201:
            st.success("Your document is being certified. You will receive feedback within 10 minutes.")
        else:
            st.error(f"Failed to upload document. Server returned status code: {response.status_code}")
            st.write(f"Response details: {response.content}")
    except Exception as e:
        st.error(f"An error occurred: {str(e)}")
        st.write(f"Exception details: {e}")
 
# def create_pdf_with_stamp(file, stamp_api_url):
#     """
#     Adds a stamp fetched from the API onto the provided PDF or image file.
#     """
#     import base64

#     # Fetch the stamp from the API
#     response = requests.get(stamp_api_url)
#     if response.status_code != 200:
#         raise Exception(f"Failed to retrieve stamp. Status code: {response.status_code}, Response: {response.content}")
    
#     # Assuming the API returns the stamp image in Base64 format
#     stamp_data = response.json().get('data', [])
#     if not stamp_data:
#         raise Exception("No stamp data found from the API response.")
    
#     stamp_image_data = stamp_data[0]['stamp']  # Adjust this key according to your API response

#     # Debugging output
#     print(f"Raw Base64 data: {stamp_image_data}")
#     print(f"Length of Base64 data: {len(stamp_image_data)}")

#     # Clean the Base64 string
#     stamp_image_data = ''.join(stamp_image_data.split())  # Remove spaces or newlines

#     # Fix Base64 padding
#     padding = len(stamp_image_data) % 4
#     if padding != 0:
#         stamp_image_data += '=' * (4 - padding)

#     try:
#         # Decode the Base64 string
#         stamp_image_bytes = BytesIO(base64.b64decode(stamp_image_data))
#         stamp_image = Image.open(stamp_image_bytes)
#     except Exception as e:
#         raise Exception(f"Error decoding Base64 stamp image: {str(e)}")

#     # Process the uploaded file
#     if file.type in ["image/jpeg", "image/png"]:
#         # Convert the image file to a PDF
#         image_data = np.asarray(bytearray(file.read()), dtype=np.uint8)
#         image = cv2.imdecode(image_data, cv2.IMREAD_COLOR)
#         pil_image = Image.fromarray(cv2.cvtColor(image, cv2.COLOR_BGR2RGB))

#         # Create an A4 canvas
#         a4_width, a4_height = 595, 842
#         white_background = Image.new("RGB", (a4_width, a4_height), "white")

#         # Resize and center the image on the A4 canvas
#         max_width = a4_width - 50
#         max_height = a4_height - 50
#         pil_image.thumbnail((max_width, max_height))
#         x_offset = (a4_width - pil_image.width) // 2
#         y_offset = (a4_height - pil_image.height) // 2
#         white_background.paste(pil_image, (x_offset, y_offset))

#         # Add the stamp to the PDF
#         pdf_bytes = io.BytesIO()
#         white_background.save(pdf_bytes, format='PDF')
#         pdf_bytes.seek(0)
#     elif file.type == "application/pdf":
#         # Add the stamp directly to the uploaded PDF
#         existing_pdf = PdfReader(file)
#         pdf_bytes = io.BytesIO()
#         output_pdf = PdfWriter()

#         # Add the stamp to the first page
#         packet = BytesIO()
#         c = canvas.Canvas(packet, pagesize=letter)
#         page_width, page_height = letter
#         stamp_width, stamp_height = 65, 65
#         x_position = (page_width - stamp_width) / 2
#         y_position = 50
#         c.drawImage(ImageReader(stamp_image), x_position, y_position, width=stamp_width, height=stamp_height)
#         c.save()

#         packet.seek(0)
#         stamp_pdf = PdfReader(packet)
#         page = existing_pdf.pages[0]
#         page.merge_page(stamp_pdf.pages[0])
#         output_pdf.add_page(page)
#         output_pdf.write(pdf_bytes)
#         pdf_bytes.seek(0)
#     else:
#         raise Exception("Unsupported file type. Please upload an image or PDF.")

#     return pdf_bytes


# def save_document_to_db(file, email):
#     try:
#         # URL for the stamp API
#         stamp_api_url = "http://127.0.0.1:8000/get_stamp/"

#         # Create a stamped PDF
#         stamped_pdf = create_pdf_with_stamp(file, stamp_api_url)

#         # Prepare the data for the API call
#         files = {'file': ("stamped_document.pdf", stamped_pdf, 'application/pdf')}
#         data = {'email': email}
#         url = "http://127.0.0.1:8000/upload_document/"

#         # Send the stamped document to the database
#         response = requests.post(url, files=files, data=data)

#         if response.status_code == 201:
#             st.success("Your document is being certified. You will receive feedback within 10 minutes.")
#         else:
#             st.error(f"Failed to upload document. Server returned status code: {response.status_code}")
#             st.write(f"Response details: {response.content}")
#     except Exception as e:
#         st.error(f"An error occurred: {str(e)}")
#         st.write(f"Exception details: {e}")
        
if st.session_state.face_match_success:
    save_to_db = st.button("Certify Document")
    if save_to_db:
        st.write("Sending to certify...")
        uploaded_file.seek(0)
        save_document_to_db(uploaded_file, email,options)
