# Practical Deep Learning for Coders: iOS App with Hugging Face Gradio API

This project is part of the **Practical Deep Learning for Coders** course. The goal was to create an iOS app to test a deep learning model hosted on Hugging Face using Gradio. Additionally, the project explored the use of AI to generate code for this app.

## Project Overview

This iOS app allows users to:
1. Select an image from their device.
2. Upload the image to a Hugging Face API endpoint.
3. Receive and display predictions from a deep learning model hosted on Hugging Face.

<p align="center">
  <img src="https://github.com/qasimkhan/Bear-Classifier-App/blob/7f96a5da8e158ea928d9fda36cc8182ce15d91db/bear_classifier_view.jpeg" width="200">
</p>

### API Details
- **Hugging Face Space**: [Bear Classifier](https://huggingface.co/spaces/qasimkhan001/bear_classifier)
- **Upload Endpoint**: `/upload`
  - Accepts an image file and returns the uploaded file's path on the server.
- **Predict Endpoint**: `/gradio_api/call/predict`
  - Accepts the file path from the upload endpoint and returns model predictions.

### Course Link
- Practical Deep Learning for Coders: [course.fast.ai](https://course.fast.ai/)

## Features
- **Image Picker**: Select an image from the device’s photo library.
- **File Upload**: Upload the selected image to the server using the `/upload` API.
- **Prediction**: Send the uploaded image's path to the `/predict` API to get classification results.
- **User-Friendly UI**: Displays the selected image and predictions in a clean, intuitive layout.
- **Debugging Tools**: Includes logging for API requests and responses to assist with troubleshooting.

## Installation and Setup

### Prerequisites
- macOS with Xcode installed.
- SwiftUI knowledge (basic understanding).
- A working Hugging Face account and API access.

### Steps to Run the Project
1. Clone this repository to your local machine:
   ```bash
   git clone https://github.com/qasimkhan/Bear-Classifier-App.git
   ```
2. Open the project in Xcode.
3. Connect your iOS device or use the simulator.
4. Build and run the app.

## How It Works
1. The user selects an image using the app's image picker.
2. The image is uploaded to the Hugging Face `/upload` endpoint.
3. The app retrieves the file path from the upload response.
4. The file path is sent to the `/predict` endpoint.
5. Predictions are displayed to the user.

## API Integration

### Upload Request
- **Endpoint**: `/upload`
- **Method**: `POST`
- **Content-Type**: `multipart/form-data`
- **Parameters**:
  - `files`: The image file to upload.

Making a prediction and getting a result requires 2 requests: a POST and a GET request. The POST request returns an EVENT_ID, which is used in the second GET request to fetch the results. In these snippets, we've used awk and read to parse the results, combining these two requests into one command for ease of use.

### Predict Request
- **Endpoint**: `/gradio_api/call/predict`
- **Method**: `POST`
- **Content-Type**: `application/json`
- **Body**:
  ```json
  {
      "data": [
          {"path": "/path/to/uploaded/image"}
      ]
  }
  ```
- **Response**:
  ```json
  {
      "event_id": "..."
  }
  ```
  
### Predict Request
- **Endpoint**: `/gradio_api/call/predict/{EVENT_ID}`
- **Method**: `GET`
- **Content-Type**: `application/json`

## Debugging and Logging
Logs are included for both the upload and predict requests to aid debugging. Errors and responses are displayed in the app interface for clarity.

## Resources
- **API Documentation**: [Bear Classifier API](https://huggingface.co/spaces/qasimkhan001/bear_classifier)
- **Course**: [Practical Deep Learning for Coders](https://course.fast.ai/)

## Future Enhancements
- Add support for live camera input.
- Implement real-time feedback for predictions.
- Optimize for performance on older devices.

---

Thank you for exploring this project! If you have any feedback or suggestions, feel free to open an issue or contribute to the repository.
