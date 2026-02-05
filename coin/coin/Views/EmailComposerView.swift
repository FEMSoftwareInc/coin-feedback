import SwiftUI
import MessageUI
import UIKit

struct EmailComposerView: UIViewControllerRepresentable {
    let entry: FeedbackEntry
    @Binding var isPresented: Bool
    var onShare: (String, String) -> Void
    
    func makeUIViewController(context: Context) -> UIViewController {
        let controller = UIViewController()
        DispatchQueue.main.async {
            presentMailComposer(from: controller, context: context)
        }
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
    
    private func presentMailComposer(from controller: UIViewController, context: Context) {
        guard MFMailComposeViewController.canSendMail() else {
            isPresented = false
            return
        }
        
        let mailComposer = MFMailComposeViewController()
        mailComposer.mailComposeDelegate = context.coordinator
        
        let subject = "Feedback: \(entry.context)"
        let body = """
        COIN Feedback Entry:
        
        Context:
        \(entry.context)
        
        Observation:
        \(entry.observation)
        
        Impact:
        \(entry.impact)
        
        Next Steps:
        \(entry.nextSteps)
        
        ---
        Sent from COIN Feedback App
        """
        
        mailComposer.setSubject(subject)
        mailComposer.setMessageBody(body, isHTML: false)
        
        DispatchQueue.main.async {
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                windowScene.windows.first?.rootViewController?.present(mailComposer, animated: true)
            }
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(isPresented: $isPresented, onShare: onShare)
    }
    
    class Coordinator: NSObject, MFMailComposeViewControllerDelegate {
        @Binding var isPresented: Bool
        var onShare: (String, String) -> Void
        
        init(isPresented: Binding<Bool>, onShare: @escaping (String, String) -> Void) {
            self._isPresented = isPresented
            self.onShare = onShare
        }
        
        func mailComposeController(
            _ controller: MFMailComposeViewController,
            didFinishWith result: MFMailComposeResult,
            error: Error?
        ) {
            if result == .sent {
                // Extract recipient email from the compose view
                // Note: MFMailComposeViewController doesn't expose recipients directly,
                // so you may need to implement a custom email capture
                onShare("recipient@example.com", "")
            }
            isPresented = false
            controller.dismiss(animated: true)
        }
    }
}

// Import statement placeholder
import MessageUI
