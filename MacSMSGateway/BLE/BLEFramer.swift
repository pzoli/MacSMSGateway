import Foundation

class BLEFramer {

    private var buffer = Data()

    func append(
        _ data: Data
    ) -> [Data] {

        buffer.append(data)

        var result: [Data] = []

        while let index =
            buffer.firstIndex(of: 0x0A) {

            let packet =
                buffer.prefix(upTo: index)

            result.append(
                Data(packet)
            )

            buffer.removeSubrange(
                ...index
            )
        }

        return result
    }

    /// Kimenő üzenet felkészítése: soremelés (0x0A) hozzáfűzése és darabolás (chunking)
    func frame(_ data: Data, maxChunkSize: Int = 180) -> [Data] {
        var framedData = data
        framedData.append(0x0A) // 0x0A (LF) lezáró bájt hozzáadása
        
        var chunks: [Data] = []
        var offset = 0
        while offset < framedData.count {
            let chunkSize = min(maxChunkSize, framedData.count - offset)
            let chunk = framedData.subdata(in: offset..<(offset + chunkSize))
            chunks.append(chunk)
            offset += chunkSize
        }
        return chunks
    }
}
