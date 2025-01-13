//
//  ContentView.swift
//  Bear Classifier App
//
//  Created by Qasim Khan on 12/01/2025.
//

import SwiftUI
import UIKit

struct ContentView: View {
    @State private var selectedImage: UIImage? = nil
    @State private var isImagePickerPresented = false
    @State private var predictionResult: String = ""
    @State private var isLoading = false

    var body: some View {
        VStack {
            Text("Bear Classifier")
                .font(.largeTitle)
                .padding()

            Text("Practical Deep Learning for Coders")
                .font(.subheadline)
                .padding(.bottom)

            if let selectedImage = selectedImage {
                Image(uiImage: selectedImage)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 300)
                    .padding()
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.5))
                    .frame(height: 300)
                    .overlay(Text("Select an Image"))
                    .padding()
            }

            Button("Upload Image") {
                isImagePickerPresented = true
            }
            .padding()
            .sheet(isPresented: $isImagePickerPresented) {
                ImagePicker(image: $selectedImage)
            }

            if isLoading {
                ProgressView("Processing...")
                    .padding()
            }

            Button("Classify Image") {
                if let selectedImage = selectedImage {
                    classifyImage(image: selectedImage)
                }
            }
            .disabled(selectedImage == nil || isLoading)
            .padding()

            if !predictionResult.isEmpty {
                Text("Result: \(predictionResult)")
                    .padding()
            }

            Spacer()

            HStack {
                Link("API", destination: URL(string: "https://qasimkhan001-bear-classifier.hf.space/gradio_api/call/predict")!)
                Spacer()
                Link("Read More", destination: URL(string: "https://github.com/qasimkhan/Practical-Deep-Learning-for-Coders/")!)
            }
            .padding()
        }
        .padding()
    }

    func classifyImage(image: UIImage) {
        isLoading = true
        uploadImage(image: image) { result in
            switch result {
            case .success(let uploadResponse):
                if let path = uploadResponse["path"] as? String {
                    predictImage(path: path) { predictResult in
                        DispatchQueue.main.async {
                            switch predictResult {
                            case .success(let prediction):
                                predictionResult = prediction
                            case .failure(let error):
                                predictionResult = "Error: \(error.localizedDescription)"
                            }
                            isLoading = false
                        }
                    }
                } else {
                    DispatchQueue.main.async {
                        predictionResult = "Error: Invalid upload response"
                        isLoading = false
                    }
                }
            case .failure(let error):
                DispatchQueue.main.async {
                    predictionResult = "Error: \(error.localizedDescription)"
                    isLoading = false
                }
            }
        }
    }

    func uploadImage(image: UIImage, completion: @escaping (Result<[String: Any], Error>) -> Void) {
        let uploadURL = URL(string: "https://qasimkhan001-bear-classifier.hf.space/gradio_api/upload")!
        var request = URLRequest(url: uploadURL)
        request.httpMethod = "POST"

        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        var body = Data()
        if let imageData = image.jpegData(compressionQuality: 0.8) {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"files\"; filename=\"image.jpg\"\r\n".data(using: .utf8)!)
            body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
            body.append(imageData)
            body.append("\r\n".data(using: .utf8)!)
            body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        }

        request.httpBody = body

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                completion(.failure(error ?? NSError(domain: "Unknown Error", code: -1, userInfo: nil)))
                return
            }

            do {
                if let jsonArray = try JSONSerialization.jsonObject(with: data, options: []) as? [[String: Any]],
                   let firstItem = jsonArray.first {
                    completion(.success(firstItem))
                } else {
                    completion(.failure(NSError(domain: "Invalid response format", code: -1, userInfo: nil)))
                }
            } catch {
                completion(.failure(error))
            }
        }

        task.resume()
    }

    func predictImage(path: String, completion: @escaping (Result<String, Error>) -> Void) {
        let predictURL = URL(string: "https://qasimkhan001-bear-classifier.hf.space/gradio_api/call/predict")!
        var request = URLRequest(url: predictURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = ["data": [["path": path]]]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body, options: [])

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                completion(.failure(error ?? NSError(domain: "Unknown Error", code: -1, userInfo: nil)))
                return
            }

            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let predictions = json["data"] as? [[String: Any]],
                   let label = predictions.first?["label"] as? String {
                    completion(.success(label))
                } else {
                    completion(.failure(NSError(domain: "Invalid response format", code: -1, userInfo: nil)))
                }
            } catch {
                completion(.failure(error))
            }
        }

        task.resume()
    }
}

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .photoLibrary
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: ImagePicker

        init(_ parent: ImagePicker) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let uiImage = info[.originalImage] as? UIImage {
                parent.image = uiImage
            }
            picker.dismiss(animated: true)
        }
    }
}

extension Data {
    mutating func append(_ string: String) {
        if let data = string.data(using: .utf8) {
            append(data)
        }
    }
}
