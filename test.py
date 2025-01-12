from PIL import Image, ImageDraw, ImageFont
from fpdf import FPDF
import os
from datetime import datetime

def merge_images_with_custom_layout(image1_path, image2_path):
    try:
        # Open the two images (ID and stamp)
        id_image = Image.open(image1_path).convert("L")  # Convert ID image to grayscale
        stamp_image = Image.open(image2_path).convert("L")  # Convert stamp image to grayscale

        # Resize the ID image (stamp image size remains the same)
        id_image = id_image.resize((600, 400))  # Resize ID card

        # Determine the canvas size
        canvas_width = max(id_image.width, stamp_image.width) + 100
        canvas_height = id_image.height + stamp_image.height + 50
        white_bg = Image.new("RGB", (canvas_width, canvas_height), "white")

        # Add ID image to the canvas
        id_x = (canvas_width - id_image.width) // 2
        id_y = 25  # Add some padding at the top
        white_bg.paste(id_image.convert("RGB"), (id_x, id_y))  # Convert grayscale to RGB to paste

        # Add stamp image to the bottom-right corner
        stamp_x = canvas_width - stamp_image.width - 50  # 50px padding from the right
        stamp_y = id_y + id_image.height + 25  # 25px padding below the ID
        white_bg.paste(stamp_image.convert("RGB"), (stamp_x, stamp_y))  # Convert grayscale to RGB to paste

        # Add the current date on the center of the stamp image
        draw = ImageDraw.Draw(white_bg)
        current_date = datetime.now().strftime("%Y-%m-%d")
        font_size = 30  # Adjust font size as needed
        try:
            font = ImageFont.truetype("arial.ttf", font_size)
        except IOError:
            font = ImageFont.load_default()

        # Calculate the center of the stamp image
        stamp_center_x = stamp_x + (stamp_image.width // 2)
        stamp_center_y = stamp_y + (stamp_image.height // 2)

        # Calculate the position of the date text to be centered on the stamp
        bbox = draw.textbbox((0, 0), current_date, font=font)
        text_width = bbox[2] - bbox[0]  # Width of the text
        text_height = bbox[3] - bbox[1]  # Height of the text
        text_x = stamp_center_x - (text_width // 2)  # Center the text horizontally on the stamp
        text_y = stamp_center_y - (text_height // 2)  # Center the text vertically on the stamp

        # Draw a white rectangle as the background for the date text
        padding = 10  # Add some padding around the text
        draw.rectangle(
            [text_x - padding, text_y - padding, text_x + text_width + padding, text_y + text_height + padding],
            fill="white"
        )

        # Draw the date text on top of the white rectangle
        draw.text((text_x, text_y), current_date, fill="black", font=font)

        # Save the merged image temporarily
        temp_image_path = "merged_image.jpg"
        white_bg.save(temp_image_path)

        # Convert the merged image to PDF
        pdf = FPDF()
        pdf.add_page()
        pdf.image(temp_image_path, x=10, y=10, w=190)  # Adjust position and width
        output_pdf_path = "output.pdf"
        pdf.output(output_pdf_path)

        # Remove the temporary merged image
        os.remove(temp_image_path)

        # Open the generated PDF (cross-platform support)
        if os.name == "nt":  # For Windows
            os.startfile(output_pdf_path) 

        print(f"PDF created and displayed successfully at: {output_pdf_path}")

    except Exception as e:
        print(f"An error occurred: {str(e)}")


if __name__ == "__main__":
    # Prompt the user to input the paths for two images
    image1_path = input("Enter the path for the ID image: ")
    image2_path = input("Enter the path for the stamp image: ")

    # Call the function to merge the images and display the PDF
    merge_images_with_custom_layout(image1_path, image2_path)
