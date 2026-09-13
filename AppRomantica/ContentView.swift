import SwiftUI

struct ContentView: View {
    @StateObject private var appState = AppRomanticaState()

    var body: some View {
        Group {
            if appState.role == nil {
                ConfiguracionView(appState: appState)
            } else if appState.pantallaActual == .buzon {
                BuzonView(appState: appState)
            } else if appState.pantallaActual == .galeria {
                GaleriaView(appState: appState)
            } else if appState.pantallaActual == .menu {
                MenuView(appState: appState)
            } else {
                BienvenidaView(appState: appState)
            }
        }
        .task {
            await appState.obtenerFrase()
            await appState.cargarContadores()
            await appState.cargarMensajes()
            await appState.cargarFotos()
        }
    }
}

#Preview {
    ContentView()
}
