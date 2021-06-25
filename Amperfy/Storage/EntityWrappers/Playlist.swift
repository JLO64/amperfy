import Foundation
import CoreData
import os.log

public class Playlist: NSObject, SongContainable, Identifyable {
    
    static let smartPlaylistIdPrefix = "smart_"
    
    let managedObject: PlaylistMO
    private let library: LibraryStorage
    
    init(library: LibraryStorage, managedObject: PlaylistMO) {
        self.library = library
        self.managedObject = managedObject
    }
    
    var identifier: String {
        return name
    }
    
    func getManagedObject(in context: NSManagedObjectContext, library: LibraryStorage) -> Playlist {
        let playlistMO = context.object(with: managedObject.objectID) as! PlaylistMO
        return Playlist(library: library, managedObject: playlistMO)
    }
    
    private var sortedPlaylistItems: [PlaylistItem] {
        var sortedItems = [PlaylistItem]()
        guard let itemsMO = managedObject.items?.allObjects as? [PlaylistItemMO] else {
            return sortedItems
        }
        sortedItems = itemsMO.lazy
            .sorted(by: { $0.order < $1.order })
            .compactMap{ PlaylistItem(library: library, managedObject: $0) }
        return sortedItems
    }
    
    private var sortedCachedPlaylistItems: [PlaylistItem] {
        var sortedCachedItems = [PlaylistItem]()
        guard let itemsMO = managedObject.items?.allObjects as? [PlaylistItemMO] else {
            return sortedCachedItems
        }
        sortedCachedItems = itemsMO.lazy
            .filter{ return $0.song?.file != nil }
            .sorted(by: { $0.order < $1.order })
            .compactMap{ PlaylistItem(library: library, managedObject: $0) }
        return sortedCachedItems
    }
    
    var songCount: Int {
        get { return Int(managedObject.songCount) }
        set {
            guard Int16.isValid(value: newValue), managedObject.songCount != Int16(newValue) else { return }
            managedObject.songCount = Int16(newValue)
        }
    }
    var songs: [Song] {
        var sortedSongs = [Song]()
        guard let itemsMO = managedObject.items?.allObjects as? [PlaylistItemMO] else {
            return sortedSongs
        }
        sortedSongs = itemsMO.lazy
            .sorted(by: { $0.order < $1.order })
            .compactMap{ $0.song }
            .compactMap{ Song(managedObject: $0) }
        return sortedSongs
    }
    var items: [PlaylistItem] {
        return sortedPlaylistItems
    }
    var id: String {
        get {
            return managedObject.id
        }
        set {
            managedObject.id = newValue
            library.saveContext()
        }
    }
    var name: String {
        get {
            return managedObject.name ?? ""
        }
        set {
            if managedObject.name != newValue {
                managedObject.name = newValue
                library.saveContext()
            }
        }
    }
    var isSmartPlaylist: Bool {
        return id.hasPrefix(Self.smartPlaylistIdPrefix)
    }
    var lastSongIndex: Int {
        guard songs.count > 0 else { return 0 }
        return songs.count-1
    }
    
    var hasCachedSongs: Bool {
        return songs.hasCachedSongs
    }
    
    var info: String {
        var infoText = "Name: " + name + "\n"
        infoText += "Count: " + String(sortedPlaylistItems.count) + "\n"
        infoText += "Songs:\n"
        for playlistItem in sortedPlaylistItems {
            infoText += String(playlistItem.order) + ": "
            if let song = playlistItem.song {
                infoText += song.creatorName
                infoText += " - "
                infoText += song.title
            } else {
                infoText += "NOT AVAILABLE"
            }
            infoText += "\n"
        }
        return infoText
    }
    
    func previousCachedSongIndex(downwardsFrom: Int) -> Int? {
        let cachedPlaylistItems = sortedCachedPlaylistItems
        guard downwardsFrom <= songs.count, !cachedPlaylistItems.isEmpty else {
            return nil
        }
        var previousIndex: Int? = nil
        for item in cachedPlaylistItems.reversed() {
            if item.order < downwardsFrom {
                previousIndex = Int(item.order)
                break
            }
        }
        return previousIndex
    }
    
    func previousCachedSongIndex(beginningAt: Int) -> Int? {
        return previousCachedSongIndex(downwardsFrom: beginningAt+1)
    }
    
    func nextCachedSongIndex(upwardsFrom: Int) -> Int? {
        let cachedPlaylistItems = sortedCachedPlaylistItems
        guard upwardsFrom < songs.count, !cachedPlaylistItems.isEmpty else {
            return nil
        }
        var nextIndex: Int? = nil
        for item in cachedPlaylistItems {
            if item.order > upwardsFrom {
                nextIndex = Int(item.order)
                break
            }
        }
        return nextIndex
    }
    
    func nextCachedSongIndex(beginningAt: Int) -> Int? {
        return nextCachedSongIndex(upwardsFrom: beginningAt-1)
    }
    
    func append(song: Song) {
        createPlaylistItem(forSong: song)
        songCount += 1
        library.saveContext()
    }

    func append(songs songsToAppend: [Song]) {
        for song in songsToAppend {
            createPlaylistItem(forSong: song)
        }
        songCount += songsToAppend.count
        library.saveContext()
    }
    
    private func createPlaylistItem(forSong song: Song) {
        let playlistItem = library.createPlaylistItem()
        playlistItem.order = managedObject.items!.count
        playlistItem.playlist = self
        playlistItem.song = song
    }

    func add(item: PlaylistItem) {
        songCount += 1
        managedObject.addToItems(item.managedObject)
    }
    
    func movePlaylistSong(fromIndex: Int, to: Int) {
        guard fromIndex >= 0, fromIndex < songs.count, to >= 0, to < songs.count, fromIndex != to else { return }
        
        let localSortedPlaylistItems = sortedPlaylistItems
        let targetOrder = localSortedPlaylistItems[to].order
        if fromIndex < to {
            for i in fromIndex+1...to {
                localSortedPlaylistItems[i].order = localSortedPlaylistItems[i].order - 1
            }
        } else {
            for i in to...fromIndex-1 {
                localSortedPlaylistItems[i].order = localSortedPlaylistItems[i].order + 1
            }
        }
        localSortedPlaylistItems[fromIndex].order = targetOrder
        
        library.saveContext()
    }
    
    func remove(at index: Int) {
        if index < sortedPlaylistItems.count {
            let itemToBeRemoved = sortedPlaylistItems[index]
            for item in sortedPlaylistItems {
                if item.order > index {
                    item.order = item.order - 1
                }
            }
            library.deletePlaylistItem(item: itemToBeRemoved)
            songCount -= 1
            library.saveContext()
        }
    }
    
    func remove(firstOccurrenceOfSong song: Song) {
        for item in items {
            if item.song?.id == song.id {
                remove(at: Int(item.order))
                songCount -= 1
                break
            }
        }
    }
    
    func getFirstIndex(song: Song) -> Int? {
        for item in items {
            if item.song?.id == song.id {
                return Int(item.order)
            }
        }
        return nil
    }
    
    func removeAllSongs() {
        for item in sortedPlaylistItems {
            library.deletePlaylistItem(item: item)
        }
        songCount = 0
        library.saveContext()
    }
    
    func shuffle() {
        let localSortedPlaylistItems = sortedPlaylistItems
        let songCount = localSortedPlaylistItems.count
        guard songCount > 0 else { return }
        
        var shuffeldIndexes = [Int]()
        shuffeldIndexes += 0...songCount-1
        shuffeldIndexes = shuffeldIndexes.shuffled()
        
        for i in 0..<songCount {
            localSortedPlaylistItems[i].order = shuffeldIndexes[i]
        }
        library.saveContext()
    }

    func ensureConsistentItemOrder() {
        var hasInconsistencyDetected = false
        for (index, item) in sortedPlaylistItems.enumerated() {
            if item.order != index {
                item.order = index
                hasInconsistencyDetected = true
            }
        }
        if hasInconsistencyDetected {
            os_log(.debug, "Playlist inconsistency detected and fixed!")
            library.saveContext()
        }
    }
    
    override public func isEqual(_ object: Any?) -> Bool {
        guard let object = object as? Playlist else { return false }
        return managedObject == object.managedObject
    }

}

extension Array where Element: Playlist {
    
    func filterRegualarPlaylists() -> [Element] {
        let filteredArray = self.filter { element in
            return !element.isSmartPlaylist
        }
        return filteredArray
    }

    func filterSmartPlaylists() -> [Element] {
        let filteredArray = self.filter { element in
            return element.isSmartPlaylist
        }
        return filteredArray
    }
    
}
