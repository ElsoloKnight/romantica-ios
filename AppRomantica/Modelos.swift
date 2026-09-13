import Foundation

struct FraseRespuesta: Decodable {
    let frase: String
    let puede_cambiar: Bool?
}

struct Mensaje: Decodable, Identifiable {
    let id: Int
    let texto: String
    let remitente: String
}

struct Foto: Decodable, Identifiable {
    let id: Int
    let url: String
}

struct ContadoresApi: Decodable {
    let te_extrano: Int
    let toma_agua: Int
    let te_amo: Int
}

struct NuevoValor: Decodable {
    let nuevo_valor: Int
}

enum PantallaApp: String {
    case bienvenida
    case menu
    case buzon
    case galeria
    case estadoEstres
    case galeriaRemota
}
