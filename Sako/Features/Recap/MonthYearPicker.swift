import SwiftUI

struct MonthYearPicker: UIViewControllerRepresentable {
    @Binding var selectedDate: Date

    func makeUIViewController(context: Context) -> UIViewController {
        let vc = UIViewController()
        let picker = UIDatePicker()

        // Deteksi iOS 17.4 atau tidak
        if #available(iOS 17.4, *) {
            picker.datePickerMode = .yearAndMonth
        } else {
            // "Magic value" untuk iOS < 17.4
            picker.datePickerMode = .init(rawValue: 4269) ?? .date
        }

        picker.preferredDatePickerStyle = .wheels
        picker.addTarget(context.coordinator, action: #selector(Coordinator.dateChanged(_:)), for: .valueChanged)
        picker.date = selectedDate

        vc.view.addSubview(picker)
        picker.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            picker.centerXAnchor.constraint(equalTo: vc.view.centerXAnchor),
            picker.centerYAnchor.constraint(equalTo: vc.view.centerYAnchor)
        ])

        return vc
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator($selectedDate)
    }

    class Coordinator: NSObject {
        var selectedDate: Binding<Date>

        init(_ selectedDate: Binding<Date>) {
            self.selectedDate = selectedDate
        }

        @objc func dateChanged(_ sender: UIDatePicker) {
            selectedDate.wrappedValue = sender.date
        }
    }
}
