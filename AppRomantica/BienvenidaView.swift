import SwiftUI

struct BienvenidaView: View {
    @ObservedObject var appState: AppRomanticaState

    var body: some View {
        VStack(spacing: 28) {
            VStack(spacing: 12) {
                Text("Frase del día ✨")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.pink)

                if appState.isLoading {
                    ProgressView()
                        .tint(.pink)
                } else {
                    Text("\"\(appState.fraseDia)\"")
                        .font(.title3)
                        .fontWeight(.medium)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.gray)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.white)
                        .cornerRadius(20)
                        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
                }
            }
            .frame(maxWidth: .infinity)

            Button(action: {
                appState.pantallaActual = .menu
            }) {
                Text("Te quiero 🤍")
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.pink)
                    .cornerRadius(30)
            }
            .padding(.horizontal, 40)
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.pink.opacity(0.12))
    }
}
