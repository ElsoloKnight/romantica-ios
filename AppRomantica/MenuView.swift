import SwiftUI

struct MenuView: View {
    @ObservedObject var appState: AppRomanticaState

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                Text("Para Ti 🤍")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.top, 20)

                VStack(alignment: .leading, spacing: 14) {
                    Text("Contadores")
                        .font(.headline)
                        .foregroundColor(.secondary)

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        ContadorCard(emoji: "🥺", titulo: "Te extraño", valor: appState.contadores["te_extrano"] ?? 0) {
                            Task { await appState.incrementarContador("te_extrano") }
                        }

                        ContadorCard(emoji: "💧", titulo: "Toma agua", valor: appState.contadores["toma_agua"] ?? 0) {
                            Task { await appState.incrementarContador("toma_agua") }
                        }

                        ContadorCard(emoji: "❤️", titulo: "Te amo", valor: appState.contadores["te_amo"] ?? 0) {
                            Task { await appState.incrementarContador("te_amo") }
                        }
                    }

                    // Segunda fila de contadores
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        ContadorCard(emoji: "🌞", titulo: "Buenos días", valor: appState.contadores["buen_dia"] ?? 0) {
                            Task { await appState.incrementarContador("buen_dia") }
                        }

                        ContadorCard(emoji: "😍", titulo: "Te admira", valor: appState.contadores["te_admira"] ?? 0) {
                            Task { await appState.incrementarContador("te_admira") }
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 14) {
                    Text("Recuerdos")
                        .font(.headline)
                        .foregroundColor(.secondary)

                    BotonRecuerdo(emoji: "📸", texto: "Me recuerdan a ti") {
                        appState.pantallaActual = .galeria
                    }

                    BotonRecuerdo(emoji: "💌", texto: "Buzón de Mensajes") {
                        appState.pantallaActual = .buzon
                    }

                    BotonRecuerdo(emoji: "😊", texto: "Estado Emocional") {
                        appState.pantallaActual = .estadoEstres
                    }
                }

                Button(action: {
                    appState.pantallaActual = .bienvenida
                }) {
                    Text("Volver al inicio")
                        .fontWeight(.bold)
                        .foregroundColor(.pink)
                        .padding(.top, 8)
                }
            }
            .padding(24)
        }
        .background(Color.pink.opacity(0.12))
    }
}

struct ContadorCard: View {
    let emoji: String
    let titulo: String
    let valor: Int
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Text(emoji)
                    .font(.title)
                Text(titulo)
                    .font(.caption)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.gray)
                Text("\(valor)")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.pink)
            }
            .frame(maxWidth: .infinity)
            .padding(12)
            .background(Color.white)
            .cornerRadius(18)
            .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 3)
        }
    }
}

struct BotonRecuerdo: View {
    let emoji: String
    let texto: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Text(emoji)
                    .font(.title)
                Text(texto)
                    .foregroundColor(.gray)
                    .fontWeight(.medium)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(18)
            .background(Color.white)
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 3)
        }
    }
}
