import SwiftUI

struct ConfiguracionView: View {
    @ObservedObject var appState: AppRomanticaState
    @State private var rolSeleccionado: String? = nil

    var body: some View {
        VStack(spacing: 20) {
            Text("Configuración Secreta 🤫")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.pink)

            Text("¿Quién está usando este celular?")
                .foregroundColor(.gray)

            Button(action: {
                rolSeleccionado = "juan_carlos"
            }) {
                Text("Soy Juan 💙")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .foregroundColor(.white)
                    .background(Color.pink)
                    .cornerRadius(25)
            }

            if rolSeleccionado == "juan_carlos" {
                VStack(spacing: 12) {
                    Text("¿Quieres cambiar la frase de hoy?")
                        .foregroundColor(.gray)

                    if appState.puedeCambiarFrase {
                        TextField("Escribe la nueva frase...", text: $appState.fraseNueva, axis: .vertical)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                            .lineLimit(3...5)

                        Button(action: {
                            Task { await appState.guardarFraseDelDia() }
                        }) {
                            Text(appState.guardandoFrase ? "Guardando..." : "Guardar frase")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .foregroundColor(.white)
                                .background(appState.guardandoFrase ? Color.pink.opacity(0.6) : Color.pink)
                                .cornerRadius(25)
                        }
                        .disabled(appState.guardandoFrase)
                    } else {
                        Text("La frase de hoy ya fue cambiada.")
                            .foregroundColor(.secondary)
                    }

                    if !appState.errorFrase.isEmpty {
                        Text(appState.errorFrase)
                            .foregroundColor(.red)
                            .font(.footnote)
                    }

                    Button(action: {
                        appState.guardarRol("juan_carlos")
                        appState.pantallaActual = .menu
                    }) {
                        Text("Entrar sin cambiar")
                            .foregroundColor(.pink)
                            .fontWeight(.semibold)
                    }
                }
                .padding()
                .frame(maxWidth: .infinity)
            }

            Button(action: {
                appState.guardarRol("ella")
                appState.pantallaActual = .menu
            }) {
                Text("Soy Roro ❤️")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .foregroundColor(.white)
                    .background(Color.purple)
                    .cornerRadius(25)
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.pink.opacity(0.12))
    }
}
