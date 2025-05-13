import Foundation

struct ProductValidator {
    static func validateName(_ name: String, existingProducts: [Products]) -> String? {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let isDuplicate = existingProducts.contains { $0.name.lowercased() == name.lowercased() }

        if trimmed.isEmpty {
            return "Nama tidak boleh kosong"
        }

        if isDuplicate {
            return "Nama produk sudah ada"
        }

        if name.first?.isWhitespace == true {
            return "Nama tidak boleh diawali spasi"
        }

        if trimmed.count > 25 {
            return "Nama melebihi 25 karakter"
        }

        if trimmed.rangeOfCharacter(from: .letters) == nil {
            return "Nama tidak valid"
        }

        return nil
    }
    
    static func validateEditedName(_ name: String, existingProducts: [Products]) -> String? {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmed.isEmpty {
            return "Nama tidak boleh kosong"
        }

        if name.first?.isWhitespace == true {
            return "Nama tidak boleh diawali spasi"
        }

        if trimmed.count > 25 {
            return "Nama melebihi 25 karakter"
        }

        if trimmed.rangeOfCharacter(from: .letters) == nil {
            return "Nama tidak valid"
        }

        return nil
    }

    static func validatePrice(_ priceInput: String) -> String? {
        if priceInput.isEmpty {
            return "Harga tidak boleh kosong"
        }

        if priceInput.hasPrefix("0") && priceInput.count > 1 {
            return "Harga tidak boleh dimulai dengan 0"
        }

        guard let value = Int(priceInput) else {
            return "Format harga tidak valid"
        }

        if value <= 0 {
            return "Harga harus lebih dari 0"
        }

        return nil
    }
}
