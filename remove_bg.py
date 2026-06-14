import sys
from PIL import Image

def remove_background(image_path, output_path, tolerance=15):
    img = Image.open(image_path).convert("RGBA")
    data = img.getdata()

    # Get background color from top-left corner
    bg_color = data[0]

    new_data = []
    for item in data:
        # Check if the pixel is within tolerance of the background color
        if (abs(item[0] - bg_color[0]) <= tolerance and
            abs(item[1] - bg_color[1]) <= tolerance and
            abs(item[2] - bg_color[2]) <= tolerance):
            # Change to transparent
            new_data.append((255, 255, 255, 0))
        else:
            new_data.append(item)

    img.putdata(new_data)
    img.save(output_path, "PNG")
    print("Background removed successfully.")

if __name__ == "__main__":
    import os
    target_path = r"C:\Users\HP\FlutterProject\kepake_lagi_1\kepake_lagi_1\assets\images\empty_inbox.png"
    if os.path.exists(target_path):
        remove_background(target_path, target_path, tolerance=25)
    else:
        print("File not found")
