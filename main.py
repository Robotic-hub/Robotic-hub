import streamlit as st
import cv2
import numpy as np
import mediapipe as mp
from sklearn.metrics.pairwise import cosine_similarity
import requests
from pdf2image import convert_from_bytes  
from PIL import Image
import io
 

st.title("Upload your ID for face verification")
st.write('Upload the document that you want to certify and if its the ID then skip!.')
 
mp_face_detection = mp.solutions.face_detection
mp_drawing = mp.solutions.drawing_utils
face_detection = mp_face_detection.FaceDetection(model_selection=1, min_detection_confidence=0.5)
 
email = st.text_input(label="Enter your email address")
 
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
    id_results = face_detection.process(id_image_rgb)

    if id_results.detections:
        st.success("Face detected in the ID document.")
        for detection in id_results.detections:
            mp_drawing.draw_detection(id_image, detection)
        # st.image(id_image, channels="BGR", caption="Detected Face with Landmarks")
 
        start_webcam = st.button("Verify your face")

        if start_webcam:
            st.write("Now let's verify your face with the live webcam.")
            cap = cv2.VideoCapture(0)
            stframe = st.empty()

            while cap.isOpened():
                ret, frame = cap.read()
                if not ret:
                    st.error("Failed to open the webcam.")
                    break

                frame_rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
                webcam_results = face_detection.process(frame_rgb)
                if webcam_results.detections:
                    for detection in webcam_results.detections:
                        mp_drawing.draw_detection(frame, detection)

                    stframe.image(frame, channels="BGR")
 
                    id_landmarks = id_results.detections[0].location_data.relative_keypoints
                    webcam_landmarks = webcam_results.detections[0].location_data.relative_keypoints
                    id_landmarks_vector = np.array([[lm.x, lm.y] for lm in id_landmarks])
                    webcam_landmarks_vector = np.array([[lm.x, lm.y] for lm in webcam_landmarks])
  
                    similarity = cosine_similarity([id_landmarks_vector.flatten()], [webcam_landmarks_vector.flatten()])[0][0]

                    if similarity > 0.95:
                        st.session_state.face_match_success = True
                        st.success(f"Face match successful with similarity: {similarity:.2f}")
                        break
                    else:
                        st.warning(f"Face mismatch: similarity {similarity:.2f}")
                        
                        break
                    
                 
                if st.button("Stop Webcam", key=f"stop_button_{np.random.randint(1000)}"):
                    break

            cap.release()
 
def save_document_to_db(file, email):
    try:
        
        if file.type in ["image/jpeg", "image/png"]:
           
            image_data = np.asarray(bytearray(file.read()), dtype=np.uint8)
            image = cv2.imdecode(image_data, cv2.IMREAD_COLOR)
          
            pil_image = Image.fromarray(cv2.cvtColor(image, cv2.COLOR_BGR2RGB))
 
            pdf_bytes = io.BytesIO()
            pil_image.save(pdf_bytes, format='PDF')
            pdf_bytes.seek(0)   
 
            files = {'file': (f"{file.name}.pdf", pdf_bytes, 'application/pdf')}
            data = {'email': email}
            url = "http://127.0.0.1:8000/upload_document/"  
            
            response = requests.post(url, files=files, data=data)

        else: 
            uploaded_file.seek(0)  
            files = {'file': (file.name, file, file.type)}
            data = {'email': email}
            url = "http://127.0.0.1:8000/upload_document/"
            
            response = requests.post(url, files=files, data=data)

        if response.status_code == 201:
            st.success("Your document is being certified and you will get feedback in 10 mins via your provided email.")
        else:
            st.error(f"Failed to upload document. Server returned status code: {response.status_code}")
            st.write(f"Response details: {response.content}")

    except Exception as e:
        st.error(f"An error occurred: {str(e)}")
        st.write(f"Exception details: {e}")
if st.session_state.face_match_success:
    save_to_db = st.button("Certify Document", key="save_button")
    if save_to_db:
        st.write("Sending to certify...")
        uploaded_file.seek(0)  
        save_document_to_db(uploaded_file, email)
