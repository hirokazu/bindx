import Foundation
import UniformTypeIdentifiers
import CoreServices
import AppKit

struct AppAssociation: Codable {
    let extensionName: String
    let bundleIdentifier: String?
    let applicationPath: String?
}

@main
struct bindx {
    static func main() {
        let args = CommandLine.arguments
        
        guard args.count > 1 else {
            print("Usage: bindx <extension> | --json | -j | --app <Name> [-j]")
            exit(1)
        }
        
        var jsonOutput = false
        var appFilter: String? = nil
        
        // Simple argument parsing
        for i in 1..<args.count {
            let arg = args[i]
            if arg == "--json" || arg == "-j" {
                jsonOutput = true
            } else if arg == "--app" || arg == "-a" {
                if i + 1 < args.count {
                    appFilter = args[i+1]
                }
            } else if !arg.starts(with: "-") && appFilter == nil && args[i-1] != "--app" && args[i-1] != "-a" {
                 // Assume it's an extension if not a flag and not an app name value
                 checkExtension(arg)
                 return
            }
        }
        
        if jsonOutput || appFilter != nil {
            listAllExtensions(filter: appFilter, json: jsonOutput)
        }
    }
    
    static func checkExtension(_ extInput: String) {
        let ext = extInput.replacingOccurrences(of: ".", with: "")
        
        guard let uti = UTType(filenameExtension: ext) else {
            print("Error: Could not determine UTI for extension '.\(ext)'")
            exit(1)
        }
        
        // Get the default handler for the UTI
        let handler = LSCopyDefaultRoleHandlerForContentType(uti.identifier as CFString, .all)
        
        if let handler = handler?.takeRetainedValue() as String? {
            print("Bundle ID: \(handler)")
            
            if let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: handler) {
                print("Application: \(appURL.path)")
            } else {
                print("Application path not found for bundle ID.")
            }
        } else {
            print("No default handler found for extension '.\(ext)'")
        }
    }
    
    static func listAllExtensions(filter: String?, json: Bool) {
        let query = NSMetadataQuery()
        query.predicate = NSPredicate(format: "kMDItemContentType == 'com.apple.application-bundle'")
        query.searchScopes = [NSMetadataQueryLocalComputerScope]
        
        NotificationCenter.default.addObserver(forName: .NSMetadataQueryDidFinishGathering, object: query, queue: .main) { notification in
            guard let query = notification.object as? NSMetadataQuery else { return }
            query.stop()
            processQueryResults(query, filter: filter, json: json)
            exit(0)
        }
        
        query.start()
        RunLoop.main.run()
    }
    
    static func processQueryResults(_ query: NSMetadataQuery, filter: String?, json: Bool) {
        var uniqueExtensions = Set<String>()
        
        for item in query.results {
            guard let item = item as? NSMetadataItem,
                  let path = item.value(forAttribute: "kMDItemPath") as? String else { continue }
            
            let bundleURL = URL(fileURLWithPath: path)
            guard let bundle = Bundle(url: bundleURL),
                  let info = bundle.infoDictionary,
                  let docTypes = info["CFBundleDocumentTypes"] as? [[String: Any]] else { continue }
            
            for type in docTypes {
                if let extensions = type["CFBundleTypeExtensions"] as? [String] {
                    for ext in extensions {
                        uniqueExtensions.insert(ext)
                    }
                }
            }
        }
        
        var associations: [AppAssociation] = []
        
        for ext in uniqueExtensions.sorted() {
            guard let uti = UTType(filenameExtension: ext) else { continue }
            
            let handler = LSCopyDefaultRoleHandlerForContentType(uti.identifier as CFString, .all)
            let bundleID = handler?.takeRetainedValue() as String?
            
            var appPath: String? = nil
            if let bid = bundleID, let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bid) {
                appPath = appURL.path
            }
            
            if let filter = filter {
                // Filter logic: Check if app path contains the filter string (case insensitive)
                // or if bundle ID contains it.
                let matchesPath = appPath?.localizedCaseInsensitiveContains(filter) ?? false
                let matchesID = bundleID?.localizedCaseInsensitiveContains(filter) ?? false
                
                if !matchesPath && !matchesID {
                    continue
                }
            }
            
            associations.append(AppAssociation(extensionName: ext, bundleIdentifier: bundleID, applicationPath: appPath))
        }
        
        if json {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            
            if let data = try? encoder.encode(associations), let jsonString = String(data: data, encoding: .utf8) {
                print(jsonString)
            }
        } else {
            // Simple list output
            for assoc in associations {
                print(assoc.extensionName)
            }
        }
    }
}
