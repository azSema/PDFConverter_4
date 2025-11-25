import Foundation
import UIKit
import Combine

@MainActor
final class SignatureStorage: ObservableObject {
    
    @Published var savedSignatures: [SavedSignature] = []
    
    private let userDefaults = UserDefaults.standard
    private let signaturesKey = "PDFConverter_SavedSignatures"
    private let fileManager = FileManager.default
    
    // Documents directory for signature files
    private var signaturesDirectory: URL {
        let documentsDir = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documentsDir.appendingPathComponent("Signatures", isDirectory: true)
    }
    
    init() {
        createSignaturesDirectoryIfNeeded()
        loadSignatures()
    }
    
    // MARK: - Directory Management
    
    private func createSignaturesDirectoryIfNeeded() {
        do {
            if !fileManager.fileExists(atPath: signaturesDirectory.path) {
                try fileManager.createDirectory(at: signaturesDirectory, withIntermediateDirectories: true)
            }
        } catch {
            print("Failed to create signatures directory: \(error)")
        }
    }
    
    // MARK: - Signature Management
    
    func saveSignature(_ signature: UIImage, name: String, color: String) -> SavedSignature? {
        guard let data = signature.pngData() else {
            print("Failed to convert signature to PNG data")
            return nil
        }
        
        let filename = "signature_\(UUID().uuidString).png"
        let fileURL = signaturesDirectory.appendingPathComponent(filename)
        
        do {
            try data.write(to: fileURL)
            
            let savedSignature = SavedSignature(name: name, imageName: filename, color: color)
            savedSignatures.append(savedSignature)
            saveSignaturesToUserDefaults()
            
            print("✅ Signature saved: \(name) as \(filename)")
            return savedSignature
            
        } catch {
            print("❌ Failed to save signature: \(error)")
            return nil
        }
    }
    
    func loadSignatureImage(_ signature: SavedSignature) -> UIImage? {
        let fileURL = signaturesDirectory.appendingPathComponent(signature.imageName)
        guard fileManager.fileExists(atPath: fileURL.path) else {
            print("❌ Signature file not found: \(signature.imageName)")
            return nil
        }
        
        return UIImage(contentsOfFile: fileURL.path)
    }
    
    func deleteSignature(_ signature: SavedSignature) {
        // Remove from array
        savedSignatures.removeAll { $0.id == signature.id }
        
        // Delete file
        let fileURL = signaturesDirectory.appendingPathComponent(signature.imageName)
        do {
            try fileManager.removeItem(at: fileURL)
            print("✅ Signature file deleted: \(signature.imageName)")
        } catch {
            print("❌ Failed to delete signature file: \(error)")
        }
        
        // Update UserDefaults
        saveSignaturesToUserDefaults()
    }
    
    func renameSignature(_ signature: SavedSignature, newName: String) {
        if let index = savedSignatures.firstIndex(where: { $0.id == signature.id }) {
            // Create new signature with updated name
            let updatedSignature = SavedSignature(
                name: newName,
                imageName: signature.imageName,
                color: signature.color
            )
            
            // Update the ID to keep it the same
            var updated = updatedSignature
            updated.id = signature.id
            
            savedSignatures[index] = updated
            saveSignaturesToUserDefaults()
            
            print("✅ Signature renamed to: \(newName)")
        }
    }
    
    // MARK: - Bulk Operations
    
    func clearAllSignatures() {
        for signature in savedSignatures {
            let fileURL = signaturesDirectory.appendingPathComponent(signature.imageName)
            try? fileManager.removeItem(at: fileURL)
        }
        
        savedSignatures.removeAll()
        saveSignaturesToUserDefaults()
        
        print("✅ All signatures cleared")
    }
    
    func getSignaturesCount() -> Int {
        return savedSignatures.count
    }
    
    // MARK: - Default Signatures
    
    func loadDefaultSignatureIfNeeded() {
        guard savedSignatures.isEmpty else { return }
        
        // Create a default "Tap to Create" placeholder if no signatures exist
        print("No saved signatures found. User needs to create first signature.")
    }
    
    // MARK: - Private Methods
    
    private func loadSignatures() {
        if let data = userDefaults.data(forKey: signaturesKey),
           let signatures = try? JSONDecoder().decode([SavedSignature].self, from: data) {
            
            // Validate that signature files still exist
            let validSignatures = signatures.filter { signature in
                let fileURL = signaturesDirectory.appendingPathComponent(signature.imageName)
                return fileManager.fileExists(atPath: fileURL.path)
            }
            
            savedSignatures = validSignatures
            
            // If some signatures were invalid, save the cleaned list
            if validSignatures.count != signatures.count {
                saveSignaturesToUserDefaults()
                print("Cleaned up \(signatures.count - validSignatures.count) invalid signature references")
            }
            
            print("✅ Loaded \(savedSignatures.count) signatures")
        } else {
            print("No saved signatures found in UserDefaults")
        }
    }
    
    private func saveSignaturesToUserDefaults() {
        do {
            let data = try JSONEncoder().encode(savedSignatures)
            userDefaults.set(data, forKey: signaturesKey)
            print("✅ Signatures saved to UserDefaults")
        } catch {
            print("❌ Failed to save signatures to UserDefaults: \(error)")
        }
    }
}