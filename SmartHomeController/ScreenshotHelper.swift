import UIKit

func takeScreenshot() -> UIImage? {
    guard let window = UIApplication.shared.connectedScenes
        .filter({$0.activationState == .foregroundActive})
        .compactMap({$0 as? UIWindowScene})
        .first?.windows
        .filter({$0.isKeyWindow}).first else { return nil }

    let renderer = UIGraphicsImageRenderer(size: window.bounds.size)
    let image = renderer.image { ctx in
        window.drawHierarchy(in: window.bounds, afterScreenUpdates: true)
    }
    return image
} 