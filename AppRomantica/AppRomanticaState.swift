import Foundation
import Combine
import SwiftUI

final class AppRomanticaState: ObservableObject {
    let baseURL = URL(string: "https://api-romantica.onrender.com")!

    @Published var pantallaActual: PantallaApp = .bienvenida
    @Published var fraseDia: String = "Cargando frase..."
    @Published var fraseNueva: String = ""
    @Published var errorFrase: String = ""
    @Published var isLoading: Bool = false
    @Published var guardandoFrase: Bool = false
    @Published var puedeCambiarFrase: Bool = false
    @Published var role: String? = UserDefaults.standard.string(forKey: "rol_usuario")
    @Published var contadores: [String: Int] = [
        "te_extrano": 0,
        "toma_agua": 0,
        "te_amo": 0
    ]
    @Published var mensajes: [Mensaje] = []
    @Published var fotos: [Foto] = []

    func guardarRol(_ rol: String) {
        UserDefaults.standard.set(rol, forKey: "rol_usuario")
        role = rol
    }

    @MainActor
    func obtenerFrase() async {
        isLoading = true
        errorFrase = ""

        do {
            let url = baseURL.appendingPathComponent("frase-del-dia")
            let (data, _) = try await URLSession.shared.data(from: url)
            let decoded = try JSONDecoder().decode(FraseRespuesta.self, from: data)
            fraseDia = decoded.frase
            puedeCambiarFrase = decoded.puede_cambiar ?? false
        } catch {
            fraseDia = "No se pudo cargar la frase. Intenta de nuevo."
            errorFrase = "Ocurrió un error al cargar la frase."
        }

        isLoading = false
    }

    @MainActor
    func guardarFraseDelDia() async {
        let texto = fraseNueva.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !texto.isEmpty else {
            errorFrase = "Escribe una frase antes de guardarla."
            return
        }

        guardandoFrase = true
        errorFrase = ""

        do {
            let url = baseURL.appendingPathComponent("frase-del-dia")
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")

            let body: [String: String] = [
                "texto": texto,
                "rol": "juan_carlos"
            ]
            request.httpBody = try JSONEncoder().encode(body)

            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse,
                  (200...299).contains(http.statusCode) else {
                throw URLError(.badServerResponse)
            }

            let decoded = try JSONDecoder().decode(FraseRespuesta.self, from: data)
            fraseDia = decoded.frase
            puedeCambiarFrase = decoded.puede_cambiar ?? false
            fraseNueva = ""
            guardarRol("juan_carlos")
        } catch {
            errorFrase = "No se pudo guardar la frase."
        }

        guardandoFrase = false
    }

    @MainActor
    func cargarContadores() async {
        do {
            let url = baseURL.appendingPathComponent("contadores")
            let (data, _) = try await URLSession.shared.data(from: url)
            let decoded = try JSONDecoder().decode(ContadoresApi.self, from: data)
            contadores["te_extrano"] = decoded.te_extrano
            contadores["toma_agua"] = decoded.toma_agua
            contadores["te_amo"] = decoded.te_amo
        } catch {
            print("Error cargando contadores: \(error)")
        }
    }

    @MainActor
    func incrementarContador(_ tipo: String) async {
        do {
            let url = baseURL.appendingPathComponent("contadores/\(tipo)")
            var request = URLRequest(url: url)
            request.httpMethod = "POST"

            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse,
                  (200...299).contains(http.statusCode) else {
                throw URLError(.badServerResponse)
            }

            let decoded = try JSONDecoder().decode(NuevoValor.self, from: data)
            contadores[tipo] = decoded.nuevo_valor
        } catch {
            print("Error actualizando contador \(tipo): \(error)")
        }
    }

    @MainActor
    func cargarMensajes() async {
        do {
            let url = baseURL.appendingPathComponent("mensajes")
            let (data, _) = try await URLSession.shared.data(from: url)
            mensajes = try JSONDecoder().decode([Mensaje].self, from: data)
        } catch {
            print("Error cargando mensajes: \(error)")
        }
    }

    @MainActor
    func enviarMensaje(_ texto: String) async {
        let limpio = texto.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !limpio.isEmpty else { return }

        do {
            let url = baseURL.appendingPathComponent("mensajes")
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")

            let body: [String: String] = [
                "texto": limpio,
                "remitente": role ?? "juan_carlos"
            ]
            request.httpBody = try JSONEncoder().encode(body)

            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse,
                  (200...299).contains(http.statusCode) else {
                throw URLError(.badServerResponse)
            }

            let mensaje = try JSONDecoder().decode(Mensaje.self, from: data)
            mensajes.append(mensaje)
        } catch {
            print("Error enviando mensaje: \(error)")
        }
    }

    @MainActor
    func cargarFotos() async {
        do {
            let url = baseURL.appendingPathComponent("fotos")
            let (data, _) = try await URLSession.shared.data(from: url)
            fotos = try JSONDecoder().decode([Foto].self, from: data)
        } catch {
            print("Error cargando fotos: \(error)")
        }
    }

    @MainActor
    func subirFoto(data: Data, nombre: String) async {
        let boundary = UUID().uuidString
        var body = Data()

        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"foto\"; filename=\"\(nombre)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(data)
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)

        let url = baseURL.appendingPathComponent("fotos")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.httpBody = body

        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse,
                  (200...299).contains(http.statusCode) else {
                throw URLError(.badServerResponse)
            }
            await cargarFotos()
        } catch {
            print("Error subiendo foto: \(error)")
        }
    }
}
