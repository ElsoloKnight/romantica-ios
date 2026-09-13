import SwiftUI
import PhotosUI
import UniformTypeIdentifiers

struct GaleriaView: View {
    @ObservedObject var appState: AppRomanticaState
    @State private var isPickerPresented = false

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button(action: { appState.pantallaActual = .menu }) {
                    Text("← Volver")
                        .fontWeight(.bold)
                        .foregroundColor(.pink)
                }
                Spacer()
                Text("Nuestras Fotos 📸")
                    .font(.title3)
                    .fontWeight(.bold)
                Spacer()
                Color.clear.frame(width: 60)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 12)
            .background(Color.pink.opacity(0.12))

            ScrollView {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                    ForEach(appState.fotos) { foto in
                        let url = URL(string: "https://api-romantica.onrender.com\(foto.url)")
                        AsyncImage(url: url) { image in
                            image
                                .resizable()
                                .scaledToFill()
                        } placeholder: {
                            Color.gray.opacity(0.3)
                        }
                        .frame(width: (UIScreen.main.bounds.width - 52) / 3, height: (UIScreen.main.bounds.width - 52) / 3)
                        .clipped()
                        .cornerRadius(8)
                    }
                }
                .padding(8)
            }

            Button(action: {
                isPickerPresented = true
            }) {
                Text("+ Subir Foto")
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.vertical, 14)
                    .padding(.horizontal, 24)
                    .background(Color.pink)
                    .cornerRadius(30)
            }
            .padding(.bottom, 24)
        }
        .sheet(isPresented: $isPickerPresented) {
            PhotoPicker { data, name in
                if let data = data {
                    Task { await appState.subirFoto(data: data, nombre: name) }
                }
            }
        }
        .background(Color.pink.opacity(0.12))
        .task {
            await appState.cargarFotos()
        }
    }
}

struct PhotoPicker: UIViewControllerRepresentable {
    var onImageSelected: (Data?, String) -> Void

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.filter = .images
        config.selectionLimit = 1

        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    final class Coordinator: NSObject, PHPickerViewControllerDelegate {
        var parent: PhotoPicker

        init(_ parent: PhotoPicker) {
            self.parent = parent
        }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)

            guard let provider = results.first?.itemProvider,
                  provider.canLoadObject(ofClass: UIImage.self) else {
                parent.onImageSelected(nil, "foto.jpg")
                return
            }

            let fileName = "foto.jpg"
            provider.loadDataRepresentation(forTypeIdentifier: UTType.image.identifier) { data, _ in
                guard let data = data else {
                    DispatchQueue.main.async {
                        self.parent.onImageSelected(nil, fileName)
                    }
                    return
                }

                DispatchQueue.main.async {
                    self.parent.onImageSelected(data, fileName)
                }
            }
        }
    }
}
