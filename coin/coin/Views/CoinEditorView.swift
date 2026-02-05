import SwiftUI
import SwiftData

struct CoinEditorView: View {
    @Environment(\.modelContext) var modelContext
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) private var colorScheme
    
    let entry: FeedbackEntry?
    
    // COIN fields
    @State private var context = ""
    @State private var observation = ""
    @State private var impact = ""
    @State private var nextSteps = ""
    
    // Recipient fields
    @State private var recipientName = ""
    @State private var recipientEmail = ""
    @State private var showRecipientSection = false
    
    // UI state
    @FocusState private var focusedField: CoinField?
    
    enum CoinField {
        case context, observation, impact, nextSteps, recipientName, recipientEmail
    }
    
    var isSaveEnabled: Bool {
        !context.trimmingCharacters(in: .whitespaces).isEmpty &&
        !observation.trimmingCharacters(in: .whitespaces).isEmpty &&
        !impact.trimmingCharacters(in: .whitespaces).isEmpty &&
        !nextSteps.trimmingCharacters(in: .whitespaces).isEmpty
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient matching HistoryView
                AppColors.backgroundGradient(for: colorScheme)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        Text("MY FEEDBACK")
                            .font(.system(size: 28, weight: .bold))
                            .tracking(1.5)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .foregroundColor(AppColors.textPrimary(for: colorScheme))
                            .padding(.top, 8)
                        
                        // COIN Sections
                        CoinSectionView(
                            label: "C",
                            title: "Context",
                            placeholder: "Describe the situation, setting, or background...",
                            text: $context,
                            focusedField: $focusedField,
                            fieldType: .context
                        )
                        .accessibilityLabel("Context section")
                        .accessibilityHint("Enter the context or background of your feedback")
                        
                        CoinSectionView(
                            label: "O",
                            title: "Observation",
                            placeholder: "What did you observe? Be specific and objective...",
                            text: $observation,
                            focusedField: $focusedField,
                            fieldType: .observation
                        )
                        .accessibilityLabel("Observation section")
                        .accessibilityHint("Enter what you observed")
                        
                        CoinSectionView(
                            label: "I",
                            title: "Impact",
                            placeholder: "What was the effect or consequence?",
                            text: $impact,
                            focusedField: $focusedField,
                            fieldType: .impact
                        )
                        .accessibilityLabel("Impact section")
                        .accessibilityHint("Enter the impact or effect")
                        
                        CoinSectionView(
                            label: "N",
                            title: "Next steps",
                            placeholder: "What actions should be taken moving forward?",
                            text: $nextSteps,
                            focusedField: $focusedField,
                            fieldType: .nextSteps
                        )
                        .accessibilityLabel("Next steps section")
                        .accessibilityHint("Enter recommended next steps")
                        
                        // Recipient Section (Optional)
                        recipientSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(AppColors.textPrimary(for: colorScheme))
                }
                
                ToolbarItem(placement: .primaryAction) {
                    Button(action: saveFeedback) {
                        Text("Save")
                            .fontWeight(.semibold)
                    }
                    .disabled(!isSaveEnabled)
                    .foregroundColor(isSaveEnabled ? AppColors.primaryAccent : AppColors.textSecondary(for: colorScheme))
                    .accessibilityLabel("Save feedback")
                    .accessibilityHint(isSaveEnabled ? "Saves your feedback entry" : "Complete all four sections to save")
                }
            }
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") {
                        focusedField = nil
                    }
                    .fontWeight(.medium)
                }
            }
            .onAppear {
                loadEntry()
            }
        }
    }
    
    private var recipientSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Toggle for showing recipient fields
            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    showRecipientSection.toggle()
                }
            }) {
                HStack {
                    Image(systemName: showRecipientSection ? "person.fill.badge.minus" : "person.fill.badge.plus")
                        .font(.system(size: 16))
                    Text(showRecipientSection ? "Remove Recipient" : "Add Recipient (Optional)")
                        .font(.system(size: 16, weight: .medium))
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .rotationEffect(.degrees(showRecipientSection ? 90 : 0))
                }
                .foregroundColor(.primary)
                .padding(16)
                .modifier(GlassCardModifier())
            }
            .accessibilityLabel(showRecipientSection ? "Remove recipient information" : "Add recipient information")
            
            if showRecipientSection {
                VStack(spacing: 12) {
                    // Recipient Name
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Recipient Name")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)
                        
                        TextField("Enter recipient name", text: $recipientName)
                            .textFieldStyle(.plain)
                            .foregroundColor(AppColors.textPrimary(for: colorScheme))
                            .padding(12)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color(.secondarySystemBackground))
                            )
                            .focused($focusedField, equals: .recipientName)
                            .accessibilityLabel("Recipient name field")
                    }
                    
                    // Recipient Email
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Recipient Email")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)
                        
                        TextField("Enter recipient email", text: $recipientEmail)
                            .textFieldStyle(.plain)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                            .foregroundColor(AppColors.textPrimary(for: colorScheme))
                            .padding(12)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color(.secondarySystemBackground))
                            )
                            .focused($focusedField, equals: .recipientEmail)
                            .accessibilityLabel("Recipient email field")
                    }
                }
                .padding(16)
                .modifier(GlassCardModifier())
                .transition(.scale.combined(with: .opacity))
            }
        }
    }
    
    private func loadEntry() {
        guard let entry = entry else { return }
        
        context = entry.context
        observation = entry.observation
        impact = entry.impact
        nextSteps = entry.nextSteps
        
        if let name = entry.recipientName, !name.isEmpty {
            recipientName = name
            showRecipientSection = true
        }
        if let email = entry.recipientEmail, !email.isEmpty {
            recipientEmail = email
            showRecipientSection = true
        }
    }
    
    private func saveFeedback() {
        if let entry = entry {
            // Update existing entry
            entry.context = context
            entry.observation = observation
            entry.impact = impact
            entry.nextSteps = nextSteps
            entry.updatedAt = Date()
            
            // Update recipient info
            entry.recipientName = recipientName.trimmingCharacters(in: .whitespaces).isEmpty ? nil : recipientName
            entry.recipientEmail = recipientEmail.trimmingCharacters(in: .whitespaces).isEmpty ? nil : recipientEmail
        } else {
            // Create new entry
            let newEntry = FeedbackEntry(
                context: context,
                observation: observation,
                impact: impact,
                nextSteps: nextSteps,
                recipientName: recipientName.trimmingCharacters(in: .whitespaces).isEmpty ? nil : recipientName,
                recipientEmail: recipientEmail.trimmingCharacters(in: .whitespaces).isEmpty ? nil : recipientEmail
            )
            modelContext.insert(newEntry)
        }
        
        dismiss()
    }
}

#Preview {
    CoinEditorView(entry: nil)
        .modelContainer(for: FeedbackEntry.self, inMemory: true)
}

#Preview("With Entry") {
    let container = try! ModelContainer(for: FeedbackEntry.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
    let entry = FeedbackEntry(
        context: "Team meeting discussion about Q4 goals",
        observation: "Sarah presented the roadmap with clear milestones",
        impact: "Team now has clarity on deliverables",
        nextSteps: "Schedule follow-up in 2 weeks"
    )
    container.mainContext.insert(entry)
    
    return CoinEditorView(entry: entry)
        .modelContainer(container)
}
