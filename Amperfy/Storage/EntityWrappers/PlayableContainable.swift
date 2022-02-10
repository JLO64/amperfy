import Foundation
import CoreData

enum DetailType {
    case short
    case long
}

protocol PlayableContainable {
    var name: String { get }
    var subtitle: String? { get }
    var subsubtitle: String? { get }
    func infoDetails(for api: BackenApiType, type: DetailType) -> [String]
    func info(for api: BackenApiType, type: DetailType) -> String
    var playables: [AbstractPlayable] { get }
    var duration: Int { get }
    var isRateable: Bool { get }
    var isDownloadAvailable: Bool { get }
    func cachePlayables(downloadManager: DownloadManageable)
    func fetchFromServer(inContext: NSManagedObjectContext, syncer: LibrarySyncer)
}

extension PlayableContainable {
    var duration: Int {
        return playables.reduce(0){ $0 + $1.duration }
    }
    
    func cachePlayables(downloadManager: DownloadManageable) {
        for playable in playables {
            if !playable.isCached {
                downloadManager.download(object: playable)
            }
        }
    }
    
    func info(for api: BackenApiType, type: DetailType) -> String {
        return infoDetails(for: api, type: type).joined(separator: " \(CommonString.oneMiddleDot) ")
    }
    
    func fetchSync(storage: PersistentStorage, backendApi: BackendApi) {
        if storage.settings.isOnlineMode {
            storage.context.performAndWait {
                let syncer = backendApi.createLibrarySyncer()
                fetchFromServer(inContext: storage.context, syncer: syncer)
            }
        }
    }
    
    func fetchAsync(storage: PersistentStorage, backendApi: BackendApi, completionHandler: @escaping () -> Void) {
        if storage.settings.isOnlineMode {
            storage.persistentContainer.performBackgroundTask() { (context) in
                let syncer = backendApi.createLibrarySyncer()
                fetchFromServer(inContext: context, syncer: syncer)
                DispatchQueue.main.async {
                    completionHandler()
                }
            }
        } else {
            completionHandler()
        }
    }
    var isRateable: Bool { return false }
    
    var isDownloadAvailable: Bool { return true }
}
