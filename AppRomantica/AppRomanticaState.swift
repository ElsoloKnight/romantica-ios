import Foundation
import Combine
import SwiftUI
import UserNotifications

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
        "te_amo": 0,
        "buen_dia": 0,
        "te_admira": 0
    ]
    @Published var mensajes: [Mensaje] = []
    @Published var fotos: [Foto] = []
    @Published var estaOnlineOtroUsuario = false

    // Variables de control para las notificaciones locales simuladas
    private var ultimoMensajeCount: Int = -1
    private var ultimosContadoresLocal: [String: Int] = [:]
    private var ultimaFotoCount: Int = -1
    private var ultimoEstadoStr: String = ""
    private var ultimoAvisoOnline: Date? = nil
    private var estabaOnline: Bool = false

    init() {
        // Pedir permiso para notificaciones locales
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            print("Permiso de notificaciones locales: \(granted)")
        }
    }

    private func mostrarNotificacionLocal(titulo: String, cuerpo: String) {
        let content = UNMutableNotificationContent()
        content.title = titulo
        content.body = cuerpo
        content.sound = .default

        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }

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

            let nuevos = [
                "te_extrano": decoded.te_extrano ?? 0,
                "toma_agua": decoded.toma_agua ?? 0,
                "te_amo": decoded.te_amo ?? 0,
                "buen_dia": decoded.buen_dia ?? 0,
                "te_admira": decoded.te_admira ?? 0
            ]

            // Verificar si hay cambios para la notificación
            if !ultimosContadoresLocal.isEmpty {
                var cambios: [String] = []
                let nombresLegibles = [
                    "te_extrano": "te extraño",
                    "toma_agua": "toma agua",
                    "te_amo": "te amo",
                    "buen_dia": "buenos días",
                    "te_admira": "te admira"
                ]

                for (clave, valor) in nuevos {
                    let viejo = ultimosContadoresLocal[clave] ?? 0
                    if valor > viejo {
                        cambios.append("\(valor - viejo) \(nombresLegibles[clave] ?? clave)")
                    }
                }

                if !cambios.isEmpty {
                    let otroRol = (role == "juan_carlos" ? "Roro" : "Juan Carlos")
                    mostrarNotificacionLocal(titulo: "Nuevos contadores ❤️", cuerpo: "\(otroRol) te dio \(cambios.joined(separator: ", "))")
                }
            }

            ultimosContadoresLocal = nuevos
            contadores = nuevos
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

            // Añadir el Header UTF-8 y el usuario
            request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
            if let userRole = role {
                request.setValue(userRole, forHTTPHeaderField: "X-Usuario")
            }

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
            let lista = try JSONDecoder().decode([Mensaje].self, from: data)

            // Si hay mensajes nuevos, notificar el último (si no es mío)
            if ultimoMensajeCount != -1 && lista.count > ultimoMensajeCount {
                if let ultimo = lista.last, ultimo.remitente != role {
                    mostrarNotificacionLocal(titulo: "Nuevo mensaje de \(ultimo.remitente.capitalized) 💌", cuerpo: ultimo.texto)
                }
            }
            ultimoMensajeCount = lista.count
            mensajes = lista
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
            request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")

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
            let lista = try JSONDecoder().decode([Foto].self, from: data)

            // Notificar si hay foto nueva
            if ultimaFotoCount != -1 && lista.count > ultimaFotoCount {
                let otroRol = (role == "juan_carlos" ? "Roro" : "Juan Carlos")
                mostrarNotificacionLocal(titulo: "Nueva foto 📸", cuerpo: "\(otroRol) ha subido un recuerdo")
            }
            ultimaFotoCount = lista.count
            fotos = lista
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
        if let userRole = role {
            request.setValue(userRole, forHTTPHeaderField: "X-Usuario")
        }
        request.httpBody = body

        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse,
                  (200...299).contains(http.statusCode) else {
                throw URLError(.badServerResponse)
            }
            await cargarFotos()
    @MainActor
    func enviarPingYRevisarOnline() async {
        guard let myRole = role else { return }
        let otroRol = myRole == "juan_carlos" ? "roro" : "juan_carlos"

        do {
            // 1. Enviar ping
            let urlPing = baseURL.appendingPathComponent("ping")
            var reqPing = URLRequest(url: urlPing)
            reqPing.httpMethod = "POST"
            reqPing.setValue(myRole, forHTTPHeaderField: "X-Usuario")
            _ = try? await URLSession.shared.data(for: reqPing)

            // 2. Preguntar si el otro está online
            let urlOnline = baseURL.appendingPathComponent("online/\(otroRol)")
            let (dataOnline, _) = try await URLSession.shared.data(from: urlOnline)
            let status = try JSONDecoder().decode(StatusOnline.self, from: dataOnline)
            estaOnlineOtroUsuario = status.online

            // Notificar si se acaba de conectar
            if estaOnlineOtroUsuario && !estabaOnline {
                let ahora = Date()
                if ultimoAvisoOnline == nil || ahora.timeIntervalSince(ultimoAvisoOnline!) > (30 * 60) {
                    mostrarNotificacionLocal(titulo: "¡Está en línea! 💚", cuerpo: "\(otroRol.capitalized) se acaba de conectar.")
                    ultimoAvisoOnline = ahora
                }
            }
            estabaOnline = estaOnlineOtroUsuario

            // 3. Revisar estado emocional
            let urlEstado = baseURL.appendingPathComponent("estado/\(otroRol)")
            let (dataEstado, _) = try await URLSession.shared.data(from: urlEstado)
            let estadoRemoto = try JSONDecoder().decode(EstadoRemoto.self, from: dataEstado)
            let act = estadoRemoto.animo + estadoRemoto.estres
            if act != ultimoEstadoStr && !ultimoEstadoStr.isEmpty {
                mostrarNotificacionLocal(titulo: "Cambio de estado", cuerpo: "\(otroRol.capitalized) se siente \(estadoRemoto.animo) y \(estadoRemoto.estres)")
            }
            ultimoEstadoStr = act

        } catch {
            print("Error en ping/online: \(error)")
        }
    }

    @MainActor
    func subirEstadoEmocional(animo: String, estres: String) async -> Bool {
        guard let myRole = role else { return false }

        do {
            let url = baseURL.appendingPathComponent("estado")
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")

            let body: [String: String] = [
                "usuario": myRole,
                "animo": animo,
                "estres": estres
            ]
            request.httpBody = try JSONEncoder().encode(body)

            let (_, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse,
                  (200...299).contains(http.statusCode) else {
                return false
            }
            return true
        } catch {
            print("Error subiendo estado: \(error)")
            return false
        }
    }
}
            reqPing.setValue(myRole, forHTTPHeaderField: "X-Usuario")
            _ = try? await URLSession.shared.data(for: reqPing)

            // 2. Preguntar si el otro está online
            let urlOnline = baseURL.appendingPathComponent("online/\(otroRol)")
            let (data, _) = try await URLSession.shared.data(from: urlOnline)
            let status = try JSONDecoder().decode(StatusOnline.self, from: data)

            // Actualizamos la variable de estado
            estaOnlineOtroUsuario = status.online
        } catch {
            print("Error en ping/online: \(error)")
        }
    }

    @MainActor
    func subirEstadoEmocional(animo: String, estres: String) async -> Bool {
        guard let myRole = role else { return false }

        do {
            let url = baseURL.appendingPathComponent("estado")
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")

            let body: [String: String] = [
                "usuario": myRole,
                "animo": animo,
                "estres": estres
            ]
            request.httpBody = try JSONEncoder().encode(body)

            let (_, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse,
                  (200...299).contains(http.statusCode) else {
                return false
            }
            return true
        } catch {
            print("Error subiendo estado: \(error)")
            return false
        }
    }
}
