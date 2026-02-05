import Foundation
import MessageUI
import UIKit

class EmailService: NSObject, MFMailComposeViewControllerDelegate {
    static let shared = EmailService()
    
    private var mailComposer: MFMailComposeViewController?
    private var completionHandler: ((Bool, String?) -> Void)?
    
    /// Check if device can send email
    static func canSendEmail() -> Bool {
        return MFMailComposeViewController.canSendMail()
    }
    
    /// Present email composer with feedback entry
    func sendFeedbackEmail(
        entry: FeedbackEntry,
        recipient: String = "",
        from viewController: UIViewController,
        completion: @escaping (Bool, String?) -> Void
    ) {
        guard MFMailComposeViewController.canSendMail() else {
            completion(false, "Mail service is not available")
            return
        }
        
        self.completionHandler = completion
        
        let mailComposer = MFMailComposeViewController()
        mailComposer.mailComposeDelegate = self
        
        // Set recipient if provided
        if !recipient.isEmpty {
            mailComposer.setToRecipients([recipient])
        }
        
        // Set subject
        let subject = "COIN Feedback: \(entry.context)"
        mailComposer.setSubject(subject)
        
        // Set body with COIN format
        let body = formatEmailBody(entry: entry)
        mailComposer.setMessageBody(body, isHTML: false)
        
        self.mailComposer = mailComposer
        viewController.present(mailComposer, animated: true)
    }
    
    /// Format feedback entry as email body
    private func formatEmailBody(entry: FeedbackEntry) -> String {
        return """
        COIN Feedback Entry
        ═══════════════════════════════════════════════════
        
        CONTEXT
        ───────
        \(entry.context)
        
        OBSERVATION
        ───────
        \(entry.observation)
        
        IMPACT
        ───────
        \(entry.impact)
        
        NEXT STEPS
        ───────
        \(entry.nextSteps)
        
        ═══════════════════════════════════════════════════
        Generated: \(Date().formatted())
        App: COIN Feedback
        """
    }
    
    // MARK: - MFMailComposeViewControllerDelegate
    
    func mailComposeController(
        _ controller: MFMailComposeViewController,
        didFinishWith result: MFMailComposeResult,
        error: Error?
    ) {
        var success = false
        var errorMessage: String?
        
        switch result {
        case .sent:
            success = true
        case .saved:
            success = true
        case .cancelled:
            success = false
        case .failed:
            errorMessage = error?.localizedDescription ?? "Email failed to send"
        @unknown default:
            success = false
        }
        
        controller.dismiss(animated: true) { [weak self] in
            self?.completionHandler?(success, errorMessage)
            self?.completionHandler = nil
        }
    }
}
