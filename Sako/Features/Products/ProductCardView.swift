import SwiftUI
import SwiftData

struct ProductCardView: View {
    @Query private var products: [Products]
    
    @Bindable var product: Products

    @Environment(\.modelContext) private var context

    @State private var isExpanded = false
    @State private var editedName: String = ""
    @State private var priceInput: String = ""
    @State private var formattedPrice: String = ""
    @State private var nameError: String? = nil
    @State private var priceError: String? = nil

    private var canSave: Bool {
        nameError == nil && priceError == nil
    }

    private var hasChanges: Bool {
        let trimmedName = editedName.trimmingCharacters(in: .whitespacesAndNewlines)
        let originalName = product.name.trimmingCharacters(in: .whitespacesAndNewlines)
        let originalPrice = String(product.price)
        return trimmedName != originalName || priceInput != originalPrice
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text(product.name)
                        .font(.headline)
                        .foregroundColor(.black)

                    Text(product.price.formatPrice())
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }

                Spacer()

                Button {
                    withAnimation(.easeInOut(duration: 0.4)) {
                        isExpanded.toggle()
                        editedName = product.name
                        priceInput = String(product.price)
                        formattedPrice = product.price.formattedWithSeparator()
                        nameError = nil
                        priceError = nil
                    }
                } label: {
                    Text("Ubah")
                        .font(.system(size: 16))
                        .foregroundColor(.blue)
                }
            }
            .padding(16)
            .background(Color.white)

            if isExpanded {
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Nama Produk")
                            .font(.caption)
                            .foregroundColor(.black)

                        TextField("Masukkan nama produk", text: $editedName)
                            .autocorrectionDisabled()
                            .textFieldStyle(.roundedBorder)
                            .onChange(of: editedName) {
                                validateName()
                            }

                        if let error = nameError {
                            Text(error)
                                .font(.caption)
                                .foregroundColor(.red)
                        }

                        Text("Maksimal 25 karakter")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Harga Produk")
                            .font(.caption)
                            .foregroundColor(.black)

                        TextField("Masukkan harga", text: $formattedPrice)
                            .autocorrectionDisabled()
                            .keyboardType(.numberPad)
                            .textFieldStyle(.roundedBorder)
                            .onChange(of: formattedPrice) { oldValue, newValue in
                                let filtered = newValue.filter { $0.isNumber }
                                priceInput = filtered

                                if let number = Int(filtered), !filtered.isEmpty {
                                    formattedPrice = number.formattedWithSeparator()
                                } else {
                                    formattedPrice = filtered
                                }

                                _ = validatePrice()
                            }

                        if let error = priceError {
                            Text(error)
                                .font(.caption)
                                .foregroundColor(.red)
                        }

                        Text("Hanya angka")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }

                    HStack(spacing: 12) {
                        Button {
                            withAnimation(.easeInOut(duration: 0.4)) {
                                isExpanded = false
                            }
                        } label: {
                            Text("Batal")
                                .font(.headline)
                                .foregroundColor(.blue)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(Color.white)
                                .cornerRadius(12)
                        }

                        Button {
                            if validateName() && validatePrice() {
                                saveChanges()
                            }
                        } label: {
                            Text("Simpan")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(hasChanges && canSave ? Color.blue : Color.gray.opacity(0.4))
                                .cornerRadius(12)
                        }
                        .disabled(!hasChanges || !canSave)
                    }
                }
                .padding(16)
                .background(Color(.systemGray6))
                .transition(.opacity.combined(with: .scale(scale: 0.95)))
            }
        }
        .animation(.easeInOut(duration: 0.4), value: isExpanded)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        .padding(.horizontal, 4)
        .padding(.vertical, 3)
    }

    @discardableResult
    private func validateName() -> Bool {
        nameError = ProductValidator.validateEditedName(editedName, existingProducts: products)
        return nameError == nil
    }

    @discardableResult
    private func validatePrice() -> Bool {
        priceError = ProductValidator.validatePrice(priceInput)
        return priceError == nil
    }

    private func saveChanges() {
        product.name = editedName.trimmingCharacters(in: .whitespacesAndNewlines)
        product.price = Int(priceInput) ?? 0
        try? context.save()
        withAnimation {
            isExpanded = false
        }
    }
}
