import SwiftUI

struct EstadoEstresView: View {
    @ObservedObject var appState: AppRomanticaState

    @State private var animoSeleccionado: String = "normal"
    @State private var estresSeleccionado: String = "normal"
    @State private var guardando: Bool = false
    @State private var showMensajeGuardado: Bool = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                HStack {
                    Button(action: { appState.pantallaActual = .menu }) {
                        Text("← Volver")
                            .fontWeight(.bold)
                            .foregroundColor(.pink)
                    }
                    Spacer()
                    Text("Estado Emocional")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.black)
                    Spacer()
                    Text("     ") // Spacer oculto para balancear el HStack
                }
                .padding(.bottom, 10)

                // Ánimo
                Text("Ánimo")
                    .font(.headline)
                    .foregroundColor(.secondary)

                HStack(spacing: 12) {
                    EstadoBoton(
                        emoji: "😢",
                        texto: "triste",
                        seleccionado: animoSeleccionado == "triste"
                    ) { animoSeleccionado = "triste" }

                    EstadoBoton(
                        emoji: "😐",
                        texto: "normal",
                        seleccionado: animoSeleccionado == "normal"
                    ) { animoSeleccionado = "normal" }

                    EstadoBoton(
                        emoji: "😊",
                        texto: "feliz",
                        seleccionado: animoSeleccionado == "feliz"
                    ) { animoSeleccionado = "feliz" }
                }

                // Estrés
                Text("Estrés")
                    .font(.headline)
                    .foregroundColor(.secondary)
                    .padding(.top, 10)

                HStack(spacing: 12) {
                    EstadoBoton(
                        emoji: "😌",
                        texto: "relajado",
                        seleccionado: estresSeleccionado == "relajado"
                    ) { estresSeleccionado = "relajado" }

                    EstadoBoton(
                        emoji: "😐",
                        texto: "normal",
                        seleccionado: estresSeleccionado == "normal"
                    ) { estresSeleccionado = "normal" }

                    EstadoBoton(
                        emoji: "😵",
                        texto: "estresado",
                        seleccionado: estresSeleccionado == "estresado"
                    ) { estresSeleccionado = "estresado" }
                }

                // Información de estado
                Text("Estado actual: \(animoSeleccionado) / \(estresSeleccionado)")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, 20)

                // Botón Guardar
                Button(action: {
                    Task {
                        guardando = true
                        let exito = await appState.subirEstadoEmocional(animo: animoSeleccionado, estres: estresSeleccionado)
                        guardando = false
                        if exito {
                            showMensajeGuardado = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                                showMensajeGuardado = false
                            }
                        }
                    }
                }) {
                    Text(guardando ? "Guardando..." : "Guardar Estado")
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.pink)
                        .cornerRadius(12)
                }
                .disabled(guardando)

                if showMensajeGuardado {
                    Text("Estado subido al servidor correctamente ❤️")
                        .font(.footnote)
                        .foregroundColor(.pink)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, 4)
                }
            }
            .padding(24)
        }
        .background(Color.pink.opacity(0.12).ignoresSafeArea())
    }
}

struct EstadoBoton: View {
    let emoji: String
    let texto: String
    let seleccionado: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Text(emoji)
                    .font(.system(size: 32))
                Text(texto)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(seleccionado ? Color.pink.opacity(0.2) : Color.white)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(seleccionado ? Color.pink : Color.clear, lineWidth: 2)
            )
        }
    }
}
