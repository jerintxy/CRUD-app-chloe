import Foundation

class ExcuseDataStore {
    static let shared = ExcuseDataStore() // 1. singleton

    // 1. Keep the array private inside the store class
    private(set) var excuses: [Excuse] = []

    private init() {
        // loads saved items when the store initialises
        self.excuses = loadExcuses()
    }


    private var fileURL: URL {
        let documentsPath = FileManager.default.urls(
            for: .documentDirectory,
            in: .userDomainMask
        )[0]
        return documentsPath.appendingPathComponent("excuses.json")
    }

    func loadExcuses() -> [Excuse] {
        guard let data = try? Data(contentsOf: fileURL),
              let excuses = try? JSONDecoder().decode([Excuse].self, from: data) else {
            return []
        }
        return excuses
    }

    func saveExcuses(_ items: [Excuse]) throws {
        let data = try JSONEncoder().encode(items)
        try data.write(to: fileURL)
    }
    
    
    
    
    func addItem(_ item: Excuse) throws {
        excuses.append(item)
        try saveExcuses(excuses)
    }

    func updateItem(_ item: Excuse) throws {
        if let index = excuses.firstIndex(where: { $0.id == item.id }) {
            excuses[index] = item
            try saveExcuses(excuses)
        }
    }

    func deleteItem(_ item: Excuse) throws {
        if let index = excuses.firstIndex(where: { $0.id == item.id }) {
            excuses.remove(at: index)
            try saveExcuses(excuses)
        }
    }

    func deleteItem(at index: Int) throws {
        // ensure index is valid before attempting to remove to prevent runtime crashes
        guard excuses.indices.contains(index) else { return }
        excuses.remove(at: index)
        try saveExcuses(excuses)
    }
}
