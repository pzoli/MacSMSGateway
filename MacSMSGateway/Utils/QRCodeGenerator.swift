//
//  QRCodeGenerator.swift
//  MacSMSGateway
//
//  Created by Papp Zoltán on 2026. 07. 23..
//

import SwiftUI
import AppKit
import CoreImage.CIFilterBuiltins


func generateQRCode(from string: String) -> NSImage? {
    let context = CIContext()
    let filter = CIFilter.qrCodeGenerator()
    
    // 1. Átalakítjuk a szöveget Data-vá
    filter.message = Data(string.utf8)
    // Hibajavítási szint (H = High / kb. 30% sérülésig olvasható)
    filter.correctionLevel = "H"

    // 2. Kinyerjük a CIImage-et
    guard let outputImage = filter.outputImage else { return nil }
    
    // 3. Felskálázzuk, hogy ne legyen pixeles (pl. 5x-ösére)
    let transform = CGAffineTransform(scaleX: 5, y: 5)
    let scaledImage = outputImage.transformed(by: transform)
    
    // 4. Létrehozzuk a végleges NSImage-et
    if let cgImage = context.createCGImage(scaledImage, from: scaledImage.extent) {
        let size = NSSize(width: scaledImage.extent.width, height: scaledImage.extent.height)
        let image = NSImage(cgImage: cgImage, size: size)
        return image
    }
    
    return nil
}
