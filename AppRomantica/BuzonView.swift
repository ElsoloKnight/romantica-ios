import SwiftUI

struct BuzonView: View {
    @ObservedObject var appState: AppRomanticaState
    @State private var nuevoMensaje: String = ""

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button(action: { appState.pantallaActual = .menu }) {
                    Text("← Volver")
                        .fontWeight(.bold)
                        .foregroundColor(.pink)
                }

                Spacer()

                Text("Buzón 💌")
                    .font(.title3)
                    .fontWeight(.bold)

                Spacer()
                Color.clear.frame(width: 60)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 12)
            .background(Color.pink.opacity(0.12))

            ScrollView {
                VStack(spacing: 12) {
                    ForEach(appState.mensajes) { mensaje in
                        let esMio = mensaje.remitente == (appState.role ?? "juan_carlos")
                        HStack {
                            if esMio { Spacer() }
                            Text(mensaje.texto)
                                .padding(14)
                                .background(esMio ? Color.pink : Color.white)
                                .foregroundColor(esMio ? .white : .gray)
                                .cornerRadius(18)
                                .frame(maxWidth: UIScreen.main.bounds.width * 0.75, alignment: esMio ? .trailing : .leading)
                            if !esMio { Spacer() }
                        }
                    }
                }
                .padding(20)
            }

            HStack {
                TextField("Escríbele algo bonito...", text: $nuevoMensaje)
                    .padding(14)
                    .background(Color(.systemGray6))
                    .cornerRadius(25)

                Button(action: {
                    let texto = nuevoMensaje
                    nuevoMensaje = ""
                    Task { await appState.enviarMensaje(texto) }
                }) {
                    Text("Enviar")
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(Color.pink)
                        .cornerRadius(25)
                }
            }
            .padding(15)
            .background(Color.white)
        }
        .task {
            await appState.cargarMensajes()
        }
        .background(Color.pink.opacity(0.12))
    }
}
