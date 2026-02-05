import Foundation
import CoreML
import NaturalLanguage

class TextSummarizer {
    static let shared = TextSummarizer()
    
    private init() {}
    
    /// Summarizes COIN feedback using on-device ML
    func summarize(context: String, observation: String, impact: String, nextSteps: String) -> String {
        // Combine all text
        let fullText = [context, observation, impact, nextSteps]
            .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            .joined(separator: " ")
        
        guard !fullText.isEmpty else { return "No feedback details" }
        
        // Try Apple Intelligence summarization (iOS 18+)
        if #available(iOS 18.0, *) {
            if let summary = summarizeWithAppleIntelligence(fullText) {
                return summary
            }
        }
        
        // Fallback to extractive summarization with NLP
        return extractiveSummary(from: fullText)
    }
    
    // MARK: - Apple Intelligence Summarization (iOS 18+)
    @available(iOS 18.0, *)
    private func summarizeWithAppleIntelligence(_ text: String) -> String? {
        // Apple's new summarization API (if available in iOS 18)
        // This would use on-device Apple Intelligence
        // For now, return nil to use fallback
        return nil
    }
    
    // MARK: - Extractive Summarization
    private func extractiveSummary(from text: String) -> String {
        let embedding = NLEmbedding.sentenceEmbedding(for: .english)
        
        // Split into sentences
        let tokenizer = NLTokenizer(unit: .sentence)
        tokenizer.string = text
        
        var sentences: [(text: String, range: Range<String.Index>)] = []
        tokenizer.enumerateTokens(in: text.startIndex..<text.endIndex) { range, _ in
            let sentence = String(text[range]).trimmingCharacters(in: .whitespacesAndNewlines)
            if sentence.count > 10 { // Filter very short sentences
                sentences.append((text: sentence, range: range))
            }
            return true
        }
        
        guard !sentences.isEmpty else {
            return smartTruncate(text, maxLength: 100)
        }
        
        // If only 1-2 sentences, just return them
        if sentences.count <= 2 {
            return sentences.map { $0.text }.joined(separator: " ")
        }
        
        // Score sentences by position and content
        var scoredSentences: [(sentence: String, score: Double)] = []
        
        for (index, sentence) in sentences.enumerated() {
            var score = 0.0
            
            // Position score (earlier sentences are more important)
            let positionScore = 1.0 - (Double(index) / Double(sentences.count))
            score += positionScore * 0.3
            
            // Length score (prefer medium-length sentences)
            let wordCount = sentence.text.split(separator: " ").count
            let lengthScore = min(Double(wordCount) / 20.0, 1.0)
            score += lengthScore * 0.2
            
            // Keyword density (look for important words)
            let keywordScore = calculateKeywordDensity(sentence.text)
            score += keywordScore * 0.5
            
            scoredSentences.append((sentence: sentence.text, score: score))
        }
        
        // Sort by score and take top sentences
        let topSentences = scoredSentences
            .sorted { $0.score > $1.score }
            .prefix(2)
            .map { $0.sentence }
        
        // Join and truncate
        let summary = topSentences.joined(separator: " ")
        return smartTruncate(summary, maxLength: 120)
    }
    
    private func calculateKeywordDensity(_ text: String) -> Double {
        let importantWords = Set(["achieved", "improved", "completed", "resolved", "helped", 
                                   "created", "delivered", "success", "problem", "solution",
                                   "team", "client", "customer", "project", "result"])
        
        let words = text.lowercased().split(separator: " ").map(String.init)
        let importantCount = words.filter { importantWords.contains($0) }.count
        
        return words.isEmpty ? 0.0 : Double(importantCount) / Double(words.count)
    }
    
    private func smartTruncate(_ text: String, maxLength: Int) -> String {
        let cleaned = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleaned.isEmpty else { return "" }
        
        if cleaned.count <= maxLength {
            return cleaned
        }
        
        // Truncate at word boundary
        let truncated = String(cleaned.prefix(maxLength))
        if let lastSpace = truncated.lastIndex(of: " ") {
            return String(truncated[..<lastSpace]) + "…"
        }
        
        return truncated + "…"
    }
}
