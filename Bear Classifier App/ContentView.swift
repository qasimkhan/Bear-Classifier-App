//
//  ContentView.swift
//  Bear Classifier App
//
//  Created by Qasim Khan on 12/01/2025.
//

import SwiftUI
import PhotosUI

struct ContentView: View {
    @State private var selectedImage: UIImage?
    @State private var output: String = ""
    @State private var isShowingImagePicker = false
    @State private var isUploading = false

    var body: some View {
        VStack(spacing: 20) {
            VStack {
                Text("Bear Classifier")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                Text("Practical Deep Learning for Coders")
                    .font(.headline)
                    .foregroundColor(.gray)
            }

            Spacer()

            if let image = selectedImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 200)
                    .cornerRadius(10)
                    .shadow(radius: 5)
            } else {
                Text("No Image Selected")
                    .foregroundColor(.gray)
                    .padding()
                    .frame(height: 200)
                    .frame(maxWidth: .infinity)
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                    .shadow(radius: 5)
            }

            Button(action: {
                isShowingImagePicker = true
            }) {
                Text("Choose Image")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }

            Button(action: {
                if let image = selectedImage {
                    uploadFile(image)
                }
            }) {
                if isUploading {
                    ProgressView()
                } else {
                    Text("Upload and Predict")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(selectedImage == nil ? Color.gray : Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
            }
            .disabled(selectedImage == nil || isUploading)

            if !output.isEmpty {
                ScrollView {
                    Text("API Response:")
                        .font(.headline)
                    Text(output)
                        .font(.body)
                        .foregroundColor(.blue)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                }
            }

            Spacer()

            HStack {
                Link("API", destination: URL(string: "https://huggingface.co/spaces/qasimkhan001/bear_classifier")!)
                Spacer()
                Link("Read more", destination: URL(string: "https://github.com/qasimkhan/Bear-Classifier-App")!)
            }
            .font(.footnote)
            .padding(.top, 10)
        }
        .padding()
        .sheet(isPresented: $isShowingImagePicker) {
            ImagePicker(selectedImage: $selectedImage)
        }
    }

    func uploadFile(_ image: UIImage) {
        guard let url = URL(string: "https://qasimkhan001-bear-classifier.hf.space/gradio_api/upload"),
              let imageData = image.jpegData(compressionQuality: 0.8) else {
            output = "Failed to process image."
            return
        }

        let boundary = UUID().uuidString
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        var body = Data()
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"files\"; filename=\"uploaded_image.jpg\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(imageData)
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)

        request.httpBody = body

        isUploading = true

        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                isUploading = false
            }

            if let error = error {
                DispatchQueue.main.async {
                    output = "Upload error: \(error.localizedDescription)"
                }
                print("Upload error: \(error.localizedDescription)")
                return
            }

            if let data = data {
                do {
                    if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [Any],
                       let path = json.first as? String {
                        print("Upload Response: \(path)")
                        // Use the path to call the predict API
                        predictImage(path: path)
                    } else {
                        DispatchQueue.main.async {
                            output = "Failed to parse upload response."
                        }
                        print("Upload response parsing failed.")
                    }
                } catch {
                    DispatchQueue.main.async {
                        output = "Failed to decode upload response: \(error.localizedDescription)"
                    }
                    print("Decoding upload response error: \(error.localizedDescription)")
                }
            }
        }.resume()
    }

    func predictImage(path: String) {
        guard let url = URL(string: "https://qasimkhan001-bear-classifier.hf.space/gradio_api/call/predict") else {
            output = "Invalid predict API URL."
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let requestBody: [String: Any] = [
            "data": [["path": path]]
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: requestBody, options: [])

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                DispatchQueue.main.async {
                    output = "Predict error: \(error.localizedDescription)"
                }
                print("Predict error: \(error.localizedDescription)")
                return
            }

            if let data = data {
                do {
                    // Decode the response as JSON
                    if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                       let eventID = json["event_id"] as? String {
                        print("Initial Response event_id: \(eventID)")
                        // Call the second API endpoint with the event_id
                        self.fetchResultsWithEventID(eventID: eventID)
                    } else {
                        DispatchQueue.main.async {
                            output = "Failed to parse event_id from response."
                        }
                        print("Failed to parse event_id.")
                    }
                } catch {
                    DispatchQueue.main.async {
                        output = "Failed to decode predict response: \(error.localizedDescription)"
                    }
                    print("Decoding predict response error: \(error.localizedDescription)")
                }
            }
        }.resume()
    }
    
    func fetchResultsWithEventID(eventID: String) {
        // Second request using the event_id
        guard let url = URL(string: "https://qasimkhan001-bear-classifier.hf.space/gradio_api/call/predict/\(eventID)") else {
            output = "Invalid event_id URL."
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET" // Use GET for the second request

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                DispatchQueue.main.async {
                    output = "Error fetching event results: \(error.localizedDescription)"
                }
                print("Error fetching results: \(error.localizedDescription)")
                return
            }

            if let data = data {
                do {
                    let pp = String(data: data, encoding: .utf8) ?? "N/A"
                    print("Final string: \(pp)")

                    DispatchQueue.main.async {
                        output = pp
                    }
                }
            } else {
                DispatchQueue.main.async {
                    output = "No data received for event results."
                }
                print("No data received for event results.")
            }
        }.resume()
    }
}

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.filter = .images
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: ImagePicker

        init(_ parent: ImagePicker) {
            self.parent = parent
        }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)
            guard let provider = results.first?.itemProvider, provider.canLoadObject(ofClass: UIImage.self) else { return }

            provider.loadObject(ofClass: UIImage.self) { image, _ in
                DispatchQueue.main.async {
                    self.parent.selectedImage = image as? UIImage
                }
            }
        }
    }
}

extension Dictionary {
    var prettyPrintedJSONString: String? {
        guard let data = try? JSONSerialization.data(withJSONObject: self, options: .prettyPrinted) else { return nil }
        return String(data: data, encoding: .utf8)
    }
}
