import SwiftUI

@MainActor
@Observable
class CryHistoryStore {
    var analyses: [CryAnalysis] = []

    private let storageKey = "cry_analyses"

    init() {
        load()
    }

    func add(_ analysis: CryAnalysis) {
        analyses.insert(analysis, at: 0)
        save()
    }

    func delete(at offsets: IndexSet) {
        analyses.remove(atOffsets: offsets)
        save()
    }

    func clearAll() {
        analyses.removeAll()
        save()
    }

    var groupedByDate: [(String, [CryAnalysis])] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: analyses) { analysis in
            calendar.startOfDay(for: analysis.date)
        }

        return grouped.sorted { $0.key > $1.key }.map { (key, value) in
            let formatter = DateFormatter()
            if calendar.isDateInToday(key) {
                return ("Today", value.sorted { $0.date > $1.date })
            } else if calendar.isDateInYesterday(key) {
                return ("Yesterday", value.sorted { $0.date > $1.date })
            } else {
                formatter.dateStyle = .medium
                return (formatter.string(from: key), value.sorted { $0.date > $1.date })
            }
        }
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(analyses) else { return }
        UserDefaults.standard.set(data, forKey: storageKey)
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let decoded = try? JSONDecoder().decode([CryAnalysis].self, from: data) else { return }
        analyses = decoded
    }
}
