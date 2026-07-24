import SwiftUI

struct QRCodeView: View {
    let qrText: String

    var body: some View {
        VStack(spacing: 20) {
            if let qrImage = generateQRCode(from: qrText) {
                Image(nsImage: qrImage)
                    .interpolation(.none)
                    .frame(width: 200, height: 200)
            } else {
                Text("Nem sikerült a QR-kód generálása")
                    .foregroundColor(.red)
            }
            
            Text(qrText)
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding()
    }
}
