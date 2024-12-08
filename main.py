import streamlit as st
import cv2
import numpy as np
import mediapipe as mp
from sklearn.metrics.pairwise import cosine_similarity
import requests
from pdf2image import convert_from_bytes
from PIL import Image
import insightface  # Import InsightFace for ArcFace
import io
# Mediapipe utilities
def save_document_to_db(file, email, options):
    try:
        if file.type in ["image/jpeg", "image/png"]:
            image_data = np.asarray(bytearray(file.read()), dtype=np.uint8)
            image = cv2.imdecode(image_data, cv2.IMREAD_COLOR)
            pil_image = Image.fromarray(cv2.cvtColor(image, cv2.COLOR_BGR2RGB))
            
            # Save as a PDF with white background
            a4_width, a4_height = 595, 842
            white_background = Image.new("RGB", (a4_width, a4_height), "white")
            pil_image.thumbnail((a4_width - 50, a4_height - 50))
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

        data = {'email': email, 'address': options}
        url = "http://127.0.0.1:8000/upload_document/"
        response = requests.post(url, files=files, data=data)

        if response.status_code == 201:
            st.success("Your document is being certified. You will receive feedback within 10 minutes.")
        else:
            st.error(f"Failed to upload document. Server returned status code: {response.status_code}")
    except Exception as e:
        st.error(f"An error occurred: {str(e)}")
mp_face_mesh = mp.solutions.face_mesh
mp_drawing = mp.solutions.drawing_utils
drawing_spec = mp_drawing.DrawingSpec(thickness=1, circle_radius=1)
connection_spec = mp_drawing.DrawingSpec(thickness=1, color=(0, 255, 0))

# Load ArcFace model using InsightFace
model = insightface.app.FaceAnalysis()
model.prepare(ctx_id=0, det_size=(640, 640))

st.title("Upload your ID for Face Verification")
st.write("Upload your document (ID or other), and let's verify your identity!")

email = st.text_input(label="Enter your email address")

# Address selection
with st.expander('Please choose your address'):
    res = requests.get('http://127.0.0.1:8000/get_stamp/')
    if res.status_code == 200:
        data = res.json()
        addresses = [item['address'] for item in data.get('data', []) if item['address'] is not None]

        if addresses: 
            options = st.radio('Addresses', addresses, index=0)
            st.write(f'This is the selected Address: {options}')
        else:
            st.write("No addresses available.") 

# File upload
uploaded_file = st.file_uploader("Upload your ID document (Image/PDF)", type=["jpg", "png", "pdf"])

if 'face_match_success' not in st.session_state:
    st.session_state.face_match_success = False

if uploaded_file:
    file_bytes = np.asarray(bytearray(uploaded_file.read()), dtype=np.uint8)
    st.write(f"Uploaded file type: {uploaded_file.type}")

    # Process uploaded file (image or PDF)
    if uploaded_file.type == "application/pdf":
        images = convert_from_bytes(file_bytes, first_page=1, last_page=1)
        id_image = np.array(images[0]) 
        id_image = cv2.cvtColor(id_image, cv2.COLOR_RGB2BGR)
    else:
        id_image = cv2.imdecode(file_bytes, 1)

    id_image_rgb = cv2.cvtColor(id_image, cv2.COLOR_BGR2RGB)


    # Use Mediapipe to detect landmarks
    with mp_face_mesh.FaceMesh(static_image_mode=True) as face_mesh:
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
            st.image(id_image, caption="ID Document with Detected Face and Landmarks", channels="BGR")

            # Use ArcFace for face embeddings
            id_faces = model.get(id_image_rgb)
            if len(id_faces) > 0:
                id_face = id_faces[0]
                st.write("ArcFace embedding extracted for ID face.")

                # Live webcam for face verification
                start_webcam = st.button("Verify Your Face")
                if start_webcam:
                    st.write("Now verifying your face with the live webcam.")
                    cap = cv2.VideoCapture(0)
                    stframe = st.empty()

                    with mp_face_mesh.FaceMesh(min_detection_confidence=0.5, min_tracking_confidence=0.5) as webcam_face_mesh:
                        while cap.isOpened():
                            ret, frame = cap.read()
                            if not ret:
                                st.error("Failed to open the webcam.")
                                break

                            frame_rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
                            webcam_results = webcam_face_mesh.process(frame_rgb)

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

                                # Extract ArcFace embedding from live webcam face
                                webcam_faces = model.get(frame_rgb)
                                if len(webcam_faces) > 0:
                                    webcam_face = webcam_faces[0]
                                    id_embedding = id_face.embedding
                                    webcam_embedding = webcam_face.embedding

                                    similarity = cosine_similarity([id_embedding], [webcam_embedding])[0][0]
                                    if similarity > 0.3:  # Adjust threshold as needed
                                        st.session_state.face_match_success = True
                                        st.success(f"Face matched successfully")
                                        if st.session_state.face_match_success:
                                            save_to_db = st.button("Certify Document", key="certify_document")
                                            if save_to_db:
                                                st.write("Sending to certify...")
                                                uploaded_file.seek(0)
                                                save_document_to_db(uploaded_file, email, options)
                                                cap.release()
                                                st.success(f"The certified document have been sent to you via an email you provided")
                                            
                                                break
                                    else:
                                        st.warning(f"Faces does not match!")
                                        cap.release()
                                        break


# Save document to database

# Certify the document

