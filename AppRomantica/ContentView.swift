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

            // Loop en segundo plano (emula el PollService de Android)
            while !Task.isCancelled {
                if appState.role != nil {
                    await appState.enviarPingYRevisarOnline()
                    await appState.cargarContadores()
                    await appState.cargarMensajes()
                }
                try? await Task.sleep(nanoseconds: 10_000_000_000) // 10 segundos
            }
        }
    }
}

#Preview {
    ContentView()
}
