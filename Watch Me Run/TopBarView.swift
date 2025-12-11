//
//  TopBarView.swift
//  Watch Me Run
//
//  Created by Andy Kent on 12/9/25.
//

import SwiftUI

struct TopBarView: View {
    @Binding var isShowingSettings: Bool
    @State private var isShowingFlagSheet = false

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
            VStack(spacing: 16) {
                Text("Flag Data Issues")
                    .font(.headline)
                Text("Flag any issues with meet or pro data with the app team. The team will update the data quickly.")
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                Button("Close") {
                    isShowingFlagSheet = false
                }
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .padding(.top, 8)
            }
            .padding()
        }
    }
}

struct TopBarView_Previews: PreviewProvider {
    static var previews: some View {
        TopBarView(isShowingSettings: .constant(false))
            .previewLayout(.sizeThatFits)
    }
}
