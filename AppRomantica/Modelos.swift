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
    let te_extrano: Int?
    let toma_agua: Int?
    let te_amo: Int?
    let buen_dia: Int?
    let te_admira: Int?
}

struct NuevoValor: Decodable {
    let nuevo_valor: Int
}

struct EstadoRemoto: Decodable {
    let usuario: String
    let animo: String
    let estres: String
}

struct StatusOnline: Decodable {
    let usuario: String
    let online: Bool
}

enum PantallaApp: String {
    case bienvenida
    case menu
    case buzon
    case galeria
    case estadoEstres
    case galeriaRemota
}
