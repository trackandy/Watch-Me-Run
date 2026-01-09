//
//  TopBarView.swift
//  Watch Me Run
//
//  Created by Andy Kent on 12/9/25.
//

import SwiftUI
import FirebaseFirestore

struct TopBarView: View {
    @Binding var isShowingSettings: Bool
    @EnvironmentObject var authManager: AuthManager
    @State private var isShowingFlagSheet = false
    @State private var flagMessage: String = ""
    @State private var suggestionMessage: String = ""

    var body: some View {
        HStack {
            // Left: Settings
            Button {
                isShowingSettings = true
            } label: {
                Image(systemName: "gearshape")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(Color.wmrTabNavy)
            }

            Spacer()

            // Center: Logo + Title
            HStack(spacing: 8) {
                // If you add an asset named "WatchMeRunLogo", it will show here.
                // Otherwise, this will just be empty space and the text will still show.
              /*  Image("WatchMeRunLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 30)
                    .accessibilityHidden(true) */

                Text("Watch Me Run")
                    .font(.system(size: 27, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    
            }
            .padding(.vertical, 2)

            Spacer()

            // Right: Flag issues
            Button {
                isShowingFlagSheet = true
            } label: {
                Image(systemName: "flag")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(Color.wmrTabNavy)
            }
            
        }
        .padding(.horizontal)
        .padding(.top, 8)
        .padding(.bottom, 8)
        .background(
            // Slight translucent effect over system background
            Color(red: 5/255, green: 10/255, blue: 30/255)
        )
        .sheet(isPresented: $isShowingFlagSheet) {
            NavigationView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Flag data issues or suggest features")
                        .font(.headline)

                    Text("Let us know if something looks wrong, or share ideas to make Watch Me Run better.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    // First text box: data issues
                    Group {
                        Text("What's wrong?")
                            .font(.subheadline.weight(.semibold))

                        ZStack(alignment: .topLeading) {
                            if flagMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                Text("Describe any incorrect meet, link, schedule, or other data…")
                                    .foregroundColor(.secondary)
                                    .padding(.vertical, 8)
                                    .padding(.horizontal, 6)
                            }
                            TextEditor(text: $flagMessage)
                                .frame(minHeight: 90)
                                .padding(4)
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color.gray.opacity(0.3))
                                )
                        }
                    }

                    // Second text box: feature suggestions / comments
                    Group {
                        Text("Feature suggestions / comments")
                            .font(.subheadline.weight(.semibold))

                        ZStack(alignment: .topLeading) {
                            if suggestionMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                Text("Share feature ideas, UX feedback, or anything else on your mind…")
                                    .foregroundColor(.secondary)
                                    .padding(.vertical, 8)
                                    .padding(.horizontal, 6)
                            }
                            TextEditor(text: $suggestionMessage)
                                .frame(minHeight: 80)
                                .padding(4)
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color.gray.opacity(0.3))
                                )
                        }
                    }

                    Spacer()

                    Button(action: {
                        submitFlag(
                            message: flagMessage,
                            suggestion: suggestionMessage,
                            reporterUid: authManager.uid
                        )
                        // Reset state and close
                        flagMessage = ""
                        suggestionMessage = ""
                        isShowingFlagSheet = false
                    }) {
                        Text("Submit")
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(Color.yellow)
                            .foregroundColor(.black)
                            .cornerRadius(12)
                    }
                    .disabled(
                        flagMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
                        suggestionMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                    )
                }
                .padding()
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            isShowingFlagSheet = false
                        }
                    }
                }
            }
        }
    }
}

private func submitFlag(message: String, suggestion: String, reporterUid: String?) {
    let trimmedMessage = message.trimmingCharacters(in: .whitespacesAndNewlines)
    let trimmedSuggestion = suggestion.trimmingCharacters(in: .whitespacesAndNewlines)

    guard !trimmedMessage.isEmpty || !trimmedSuggestion.isEmpty else {
        print("ℹ️ submitFlag: nothing to send (both fields empty)")
        return
    }

    let db = Firestore.firestore()
    var data: [String: Any] = [
        "createdAt": FieldValue.serverTimestamp(),
        "message": trimmedMessage,
        "suggestion": trimmedSuggestion,
        "source": "topBarFlagSheet"
    ]

    if let reporterUid = reporterUid {
        data["reporterUid"] = reporterUid
    }

    db.collection("flags").addDocument(data: data) { error in
        if let error = error {
            print("⚠️ Failed to submit flag: \(error.localizedDescription)")
        } else {
            print("✅ Flag / feedback submitted successfully")
        }
    }
}

struct TopBarView_Previews: PreviewProvider {
    static var previews: some View {
        TopBarView(isShowingSettings: .constant(false))
            .environmentObject(AuthManager())
            .previewLayout(.sizeThatFits)
    }
}
