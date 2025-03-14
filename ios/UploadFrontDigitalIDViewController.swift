import UIKit

class UploadFrontDigitalIDViewController: UIViewController, UIImagePickerControllerDelegate,
    UINavigationControllerDelegate
{

    private let titleLabel = UILabel()
    private let imageView = UIImageView()
    private let placeholderLabel = UILabel()
    private let uploadButton = UIButton(type: .system)
    private let loadingIndicator = UIActivityIndicatorView(style: .large)
    private let processingLabel = UILabel()
    var inactivityTimer: Timer?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupGradientBackground()
        setupUI()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        resetInactivityTimer()  // Start the initial timer
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        inactivityTimer?.invalidate()
        inactivityTimer = nil
    }
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        startInactivityTimer()  // Reset the timer on interaction
    }

    // ✅ Gradient Background
    private func setupGradientBackground() {
        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = view.bounds
        gradientLayer.colors = [
            UIColor(hex: "#60CFFF").cgColor,
            UIColor(hex: "#C5EEFF").cgColor,
        ]
        gradientLayer.startPoint = CGPoint(x: 0.5, y: 0.0)
        gradientLayer.endPoint = CGPoint(x: 0.5, y: 1.0)
        view.layer.insertSublayer(gradientLayer, at: 0)
    }

    private func setupUI() {
        view.backgroundColor = .white

        // ✅ Title Label
        titleLabel.text = "Upload Digital ID (Front Side)"
        titleLabel.font = UIFont.boldSystemFont(ofSize: 24)
        titleLabel.textAlignment = .center
        titleLabel.textColor = .white
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(titleLabel)

        // ✅ Image View (Takes Full Screen Space)
        imageView.contentMode = .scaleAspectFit
        imageView.layer.cornerRadius = 10
        imageView.clipsToBounds = true
        imageView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(imageView)

        // ✅ Placeholder Label (Displayed When No Image Selected)
        placeholderLabel.text = "No Image Selected\nTap 'Upload ID' to select an image"
        placeholderLabel.numberOfLines = 2
        placeholderLabel.textAlignment = .center
        placeholderLabel.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        placeholderLabel.textColor = .darkGray
        placeholderLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(placeholderLabel)

        // ✅ Upload Button (At Bottom)
        uploadButton.setTitle("Upload ID", for: .normal)
        uploadButton.backgroundColor = .blue
        uploadButton.setTitleColor(.white, for: .normal)
        uploadButton.layer.cornerRadius = 10
        uploadButton.translatesAutoresizingMaskIntoConstraints = false
        uploadButton.addTarget(self, action: #selector(uploadButtonTapped), for: .touchUpInside)
        uploadButton.backgroundColor = UIColor(
            red: 0x59 / 255.0, green: 0xD5 / 255.0, blue: 0xFF / 255.0, alpha: 1.0)
        view.addSubview(uploadButton)

        // ✅ Loading Indicator
        loadingIndicator.hidesWhenStopped = true
        loadingIndicator.transform = CGAffineTransform(scaleX: 1.5, y: 1.5)
        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(loadingIndicator)

        // ✅ Processing Label
        processingLabel.text = "Processing..."
        processingLabel.font = UIFont.boldSystemFont(ofSize: 18)
        processingLabel.textAlignment = .center
        processingLabel.textColor = .black
        processingLabel.isHidden = true
        processingLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(processingLabel)

        // ✅ Constraints
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            imageView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 20),
            imageView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            imageView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            imageView.bottomAnchor.constraint(equalTo: uploadButton.topAnchor, constant: -30),

            placeholderLabel.centerXAnchor.constraint(equalTo: imageView.centerXAnchor),
            placeholderLabel.centerYAnchor.constraint(equalTo: imageView.centerYAnchor),

            uploadButton.bottomAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            uploadButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            uploadButton.widthAnchor.constraint(equalToConstant: 280),
            uploadButton.heightAnchor.constraint(equalToConstant: 55),

            loadingIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor),

            processingLabel.topAnchor.constraint(
                equalTo: loadingIndicator.bottomAnchor, constant: 10),
            processingLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
        ])

        // ✅ Show Image if Already Selected
        if let selectedImage = SharedViewModel.shared.digitalFrontImage {
            // imageView.image = selectedImage
            placeholderLabel.isHidden = true
            uploadButton.setTitle("Continue", for: .normal)  // ✅ Change Button Text
        } else {
            placeholderLabel.isHidden = false
        }
    }

    // ✅ Open Gallery
    @objc private func uploadButtonTapped() {
        if let selectedImage = SharedViewModel.shared.digitalFrontImage {
            // ✅ Image Already Selected → Start Loading & API Call
            showLoading()
            if let imageData = selectedImage.jpegData(compressionQuality: 0.9) {
                // let referenceID =
                //     "INNOVERIFYIOS" + String(Int(Date().timeIntervalSince1970))
                //     + String(format: "%08d", Int.random(in: 1_000_000...9_999_999))

                // SharedViewModel.shared.referenceNumber = referenceID
                let referenceID = SharedViewModel.shared.referenceNumber ?? ""
                uploadImageToAPI(data: imageData, referenceID: referenceID)
            }
        } else {
            // ✅ No Image Selected → Open Image Picker
            let imagePicker = UIImagePickerController()
            imagePicker.delegate = self
            imagePicker.sourceType = .photoLibrary
            present(imagePicker, animated: true)
        }
    }

    // ✅ Reset the timer for any other UI interactions (e.g., buttons)
    @objc func someButtonTapped() {
        resetInactivityTimer()
        print("Button tapped")
    }

    // ✅ Handle Image Selection
    func imagePickerController(
        _ picker: UIImagePickerController,
        didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
    ) {
        if let selectedImage = info[.originalImage] as? UIImage {
            SharedViewModel.shared.digitalFrontImage = selectedImage
            imageView.image = selectedImage
            placeholderLabel.isHidden = true
            uploadButton.setTitle("Continue", for: .normal)  // ✅ Change Button Text
        }
        dismiss(animated: true)
    }

    // ✅ Handle Image Picker Cancellation
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true)
    }

    // ✅ Show Loading
    private func showLoading() {
        loadingIndicator.startAnimating()
        processingLabel.isHidden = false
        uploadButton.isEnabled = false
    }

    // ✅ Hide Loading
    private func hideLoading() {
        loadingIndicator.stopAnimating()
        processingLabel.isHidden = true
        uploadButton.isEnabled = true
    }
    private func showLoadingIndicator() {
        DispatchQueue.main.async {
            self.loadingIndicator.startAnimating()
            self.processingLabel.isHidden = false
            self.uploadButton.isEnabled = false
        }
    }

    private func hideLoadingIndicator() {
        DispatchQueue.main.async {
            self.loadingIndicator.stopAnimating()
            self.processingLabel.isHidden = true
            self.uploadButton.isEnabled = true
        }
    }

    // ✅ API Call (Same as Given)
    private func uploadImageToAPI(data: Data, referenceID: String) {
        showLoadingIndicator()
        let client = URLSession.shared
        let username = "test"
        let password = "test"
        let credentials = "\(username):\(password)"
        guard let credentialsData = credentials.data(using: .utf8) else {
            fatalError("Unable to encode credentials")
        }
        let base64Credentials = credentialsData.base64EncodedString()

        // let referenceID = "INNOVERIFYMAN" + String(Int(Date().timeIntervalSince1970))
        SharedViewModel.shared.referenceNumber = referenceID

        // // First API call (Cropping)
        // var croppingRequest = URLRequest(url: URL(string: "https://api.innovitegrasuite.online/crop-aadhar-card/")!)
        // croppingRequest.httpMethod = "POST"
        // let boundary = UUID().uuidString
        // var croppingRequestBody = Data()

        // // Add image data to form
        // croppingRequestBody.append("--\(boundary)\r\n".data(using: .utf8)!)
        // croppingRequestBody.append("Content-Disposition: form-data; name=\"file\"; filename=\"image.jpg\"\r\n".data(using: .utf8)!)
        // croppingRequestBody.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        // croppingRequestBody.append(data)
        // croppingRequestBody.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
        // croppingRequest.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        // croppingRequest.httpBody = croppingRequestBody

        // let croppingTask = client.dataTask(with: croppingRequest) { croppingData, croppingResponse, error in
        //     if let error = error {
        //         print("❌ Cropping API Request Failed: \(error.localizedDescription)")
        //         DispatchQueue.main.async {
        //             self.hideLoadingIndicator()
        //             self.showAlert("Cropping API error", "Failed to process image.")
        //         }
        //         return
        //     }

        //     guard let croppingData = croppingData,
        //           let httpResponse = croppingResponse as? HTTPURLResponse else {
        //         print("❌ No response or data from server")
        //         DispatchQueue.main.async {
        //             self.hideLoadingIndicator()
        //             self.showAlert("Cropping API error", "No response from server.")
        //         }
        //         return
        //     }

        //     SharedViewModel.shared.frontImage = UIImage(data: croppingData)

        //     // ✅ Log response status and headers
        //     print("ℹ️ Cropping API HTTP Status Code: \(httpResponse.statusCode)")
        //     print("ℹ️ Cropping API Response Headers: \(httpResponse.allHeaderFields)")

        //     // ✅ Print response body as string
        //     if let responseString = String(data: croppingData, encoding: .utf8) {
        //         print("✅ Cropping API Response: \(responseString)")
        //     } else {
        //         print("⚠️ Unable to parse response data")
        //     }
        resetInactivityTimer()
        var ocrRequest = URLRequest(
            url: URL(string: "https://api.innovitegrasuite.online/process-id")!)
        ocrRequest.httpMethod = "POST"
        ocrRequest.setValue("testapikey", forHTTPHeaderField: "api-key")
        ocrRequest.setValue("Basic \(base64Credentials)", forHTTPHeaderField: "Authorization")

        let ocrBoundary = UUID().uuidString
        var ocrRequestBody = Data()

        // Add file field
        ocrRequestBody.append("--\(ocrBoundary)\r\n".data(using: .utf8)!)
        ocrRequestBody.append(
            "Content-Disposition: form-data; name=\"file\"; filename=\"image.jpg\"\r\n".data(
                using: .utf8)!)
        ocrRequestBody.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        ocrRequestBody.append(data)  // Ensure valid image data is passed
        ocrRequestBody.append("\r\n".data(using: .utf8)!)

        // Add reference_id field
        ocrRequestBody.append("--\(ocrBoundary)\r\n".data(using: .utf8)!)
        ocrRequestBody.append(
            "Content-Disposition: form-data; name=\"reference_id\"\r\n\r\n".data(using: .utf8)!)
        ocrRequestBody.append("\(referenceID)\r\n".data(using: .utf8)!)

        // Add side field
        ocrRequestBody.append("--\(ocrBoundary)\r\n".data(using: .utf8)!)
        ocrRequestBody.append(
            "Content-Disposition: form-data; name=\"side\"\r\n\r\n".data(using: .utf8)!)
        ocrRequestBody.append("front\r\n".data(using: .utf8)!)

        ocrRequestBody.append("--\(ocrBoundary)--\r\n".data(using: .utf8)!)
        ocrRequest.setValue(
            "multipart/form-data; boundary=\(ocrBoundary)", forHTTPHeaderField: "Content-Type")
        ocrRequest.httpBody = ocrRequestBody

        let ocrTask = client.dataTask(with: ocrRequest) { ocrData, ocrResponse, error in
            DispatchQueue.main.async { self.hideLoadingIndicator() }

            guard let httpResponse = ocrResponse as? HTTPURLResponse else {
                DispatchQueue.main.async {
                    self.showAlert("OCR API error", "No response received from server.")
                }
                return
            }

            if let responseData = ocrData,
                let responseString = String(data: responseData, encoding: .utf8)
            {
                print("OCR API Response Body:", responseString)
            }

            guard let ocrData = ocrData, httpResponse.statusCode == 200 else {
                DispatchQueue.main.async {
                    self.showAlert(
                        "OCR API error",
                        "Failed to analyze image. Status Code: \(httpResponse.statusCode)")
                }
                return
            }
            do {
                let jsonResponse =
                    try JSONSerialization.jsonObject(with: ocrData, options: []) as! [String: Any]
                print("OCR JSON Response:", jsonResponse)

                guard let dataObject = jsonResponse["id_analysis"] as? [String: Any],
                    let frontObject = dataObject["front"] as? [String: Any],
                    let croppedFace = jsonResponse["cropped_face"] as? String
                else {
                    DispatchQueue.main.async {
                        self.showAlert("Error", "Incomplete or missing OCR analysis data.")
                    }
                    return
                }
                let ocrResponse = OcrResponseFront(
                    fullName: frontObject["Full_name"] as? String ?? "N/A",
                    dob: frontObject["Date_of_birth"] as? String ?? "N/A",
                    sex: frontObject["Sex"] as? String ?? "N/A",
                    nationality: frontObject["Nationality"] as? String ?? "N/A",
                    fcn: frontObject["FCN"] as? String ?? "N/A",
                    dateOfExpiry: frontObject["Date_of_expiry"] as? String ?? "N/A",
                    imageUrl: croppedFace
                )
                let bitmap = UIImage(data: data)
                SharedViewModel.shared.ocrResponse = ocrResponse

                func getTopViewController(
                    _ rootViewController: UIViewController? = UIApplication.shared.windows.first?
                        .rootViewController
                ) -> UIViewController? {
                    if let presentedViewController = rootViewController?.presentedViewController {
                        return getTopViewController(presentedViewController)
                    }
                    if let navigationController = rootViewController as? UINavigationController {
                        return getTopViewController(navigationController.visibleViewController)
                    }
                    if let tabBarController = rootViewController as? UITabBarController {
                        return getTopViewController(tabBarController.selectedViewController)
                    }
                    return rootViewController
                }
                DispatchQueue.main.async {
                    self.hideLoadingIndicator()

                    // Save Face Cropped Image to ViewModel
                    if let faceUrl = URL(string: SharedViewModel.shared.ocrResponse?.imageUrl ?? "")
                    {
                        DispatchQueue.global().async {
                            if let data = try? Data(contentsOf: faceUrl),
                                let image = UIImage(data: data)
                            {
                                DispatchQueue.main.async {
                                    SharedViewModel.shared.faceCropped = image
                                }
                            }
                        }
                    }

                    // ✅ Navigate to DigitalFrontDetailsViewController using a proper topViewController
                    let digitalFrontVC = DigitalFrontDetailsViewController()
                    digitalFrontVC.modalPresentationStyle = .fullScreen

                    if let topVC = getTopViewController(), topVC.view.window != nil {
                        topVC.present(
                            digitalFrontVC, animated: true,
                            completion: {
                                print("✅ Successfully presented DigitalFrontDetailsViewController")
                            })
                    } else {
                        print("❌ Unable to find a valid top view controller to present.")
                    }
                }

                //                    self.closeFrontCapturedScreen()

            } catch {
                DispatchQueue.main.async {
                    self.showAlert("Parsing Error", "Failed to parse OCR response.")
                }
            }
        }
        ocrTask.resume()
        // }

        // croppingTask.resume()
    }
    func showAlert(_ title: String, _ message: String) {
        DispatchQueue.main.async {
            let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
            alert.addAction(
                UIAlertAction(title: "Retry", style: .default) { _ in
                    //                self.restartCameraPreview()
                    let imagePicker = UIImagePickerController()
                    imagePicker.delegate = self
                    imagePicker.sourceType = .photoLibrary
                    self.present(imagePicker, animated: true)
                })
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
    }
    func getTopViewController(
        _ rootViewController: UIViewController? = UIApplication.shared.connectedScenes
            .compactMap { ($0 as? UIWindowScene)?.keyWindow }
            .first?.rootViewController
    ) -> UIViewController? {

        if let presentedViewController = rootViewController?.presentedViewController {
            return getTopViewController(presentedViewController)
        }
        if let navigationController = rootViewController as? UINavigationController {
            return getTopViewController(navigationController.visibleViewController)
        }
        if let tabBarController = rootViewController as? UITabBarController {
            return getTopViewController(tabBarController.selectedViewController)
        }
        return rootViewController
    }

    private func startInactivityTimer() {
        // Invalidate the existing timer if any
        inactivityTimer?.invalidate()

        // Start a new timer for 3 minutes (180 seconds)
        inactivityTimer = Timer.scheduledTimer(
            timeInterval: 180,
            // timeInterval: 180,
            target: self,
            selector: #selector(closeCameraAfterTimeout),
            userInfo: nil,
            repeats: false
        )
    }

    // ✅ Stop the inactivity timer
    private func stopInactivityTimer() {
        inactivityTimer?.invalidate()
        inactivityTimer = nil
    }

    // ✅ Close the camera after 3 minutes
    @objc private func closeCameraAfterTimeout() {
        //        print("⚠️ Camera closed due to inactivity")
        //
        //        // Stop the camera session
        //        captureSession.stopRunning()
        Inno.sharedInstance?.sendEvent(withName: "onScreenTimeout", body: 1)

        // Dismiss the current view controller
        DispatchQueue.main.async {
            self.dismiss(animated: true) {
                // Optionally, close any other native screens
                self.closeAllNativeScreens()
            }
        }
    }

    // ✅ Close all native screens
    private func closeAllNativeScreens() {
        if let rootViewController = UIApplication.shared.windows.first?.rootViewController {
            rootViewController.dismiss(animated: true, completion: nil)
        }
    }

    private func resetInactivityTimer() {
        // Invalidate the existing timer
        inactivityTimer?.invalidate()
        // Start a new timer
        inactivityTimer = Timer.scheduledTimer(
            timeInterval: 180,  // 10 seconds (for testing)
            target: self,
            selector: #selector(closeCameraAfterTimeout),
            userInfo: nil,
            repeats: false
        )
        print("Timer reset due to activity")
    }

}
extension UIColor {
    convenience init(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")

        var rgb: UInt64 = 0
        Scanner(string: hexSanitized).scanHexInt64(&rgb)

        let red = CGFloat((rgb >> 16) & 0xFF) / 255.0
        let green = CGFloat((rgb >> 8) & 0xFF) / 255.0
        let blue = CGFloat(rgb & 0xFF) / 255.0

        self.init(red: red, green: green, blue: blue, alpha: 1.0)
    }

}
