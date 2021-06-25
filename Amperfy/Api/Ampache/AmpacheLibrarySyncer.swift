import Foundation
import CoreData
import os.log
import UIKit

class AmpacheLibrarySyncer: LibrarySyncer {
    
    private let ampacheXmlServerApi: AmpacheXmlServerApi
    private let log = OSLog(subsystem: AppDelegate.name, category: "AmpacheLibSyncer")
    
    var artistCount: Int {
        return ampacheXmlServerApi.artistCount
    }
    var albumCount: Int {
        return ampacheXmlServerApi.albumCount
    }
    var songCount: Int {
        return ampacheXmlServerApi.songCount
    }
    var genreCount: Int {
        return ampacheXmlServerApi.genreCount
    }
    var playlistCount: Int {
        return ampacheXmlServerApi.playlistCount
    }
    var podcastCount: Int {
        return ampacheXmlServerApi.podcastCount
    }
    
    init(ampacheXmlServerApi: AmpacheXmlServerApi) {
        self.ampacheXmlServerApi = ampacheXmlServerApi
    }
    
    func sync(currentContext: NSManagedObjectContext, persistentContainer: NSPersistentContainer, statusNotifyier: SyncCallbacks? = nil) {
        guard let libMetaData = ampacheXmlServerApi.requesetLibraryMetaData() else { return }
        
        let downloadSlotCounter = DownloadSlotCounter(maximumActiveDownloads: 5)
        let syncLibrary = LibraryStorage(context: currentContext)

        let syncWave = syncLibrary.createSyncWave()
        syncWave.setMetaData(fromLibraryChangeDates: libMetaData.libraryChangeDates)
        syncLibrary.saveContext()

        statusNotifyier?.notifySyncStarted(ofType: .genre)
        let genreParser = GenreParserDelegate(library: syncLibrary, syncWave: syncWave, parseNotifier: statusNotifyier)
        self.ampacheXmlServerApi.requestGenres(parserDelegate: genreParser)
        syncLibrary.saveContext()

        statusNotifyier?.notifySyncStarted(ofType: .artist)
        let pollCountArtist = (ampacheXmlServerApi.artistCount / AmpacheXmlServerApi.maxItemCountToPollAtOnce)
        for i in 0...pollCountArtist {
            downloadSlotCounter.waitForDownloadSlot()
            persistentContainer.performBackgroundTask() { (context) in
                let batchLibrary = LibraryStorage(context: context)
                let syncWaveMO = try! context.existingObject(with: syncWave.managedObject.objectID) as! SyncWaveMO
                let syncWaveContext = SyncWave(managedObject: syncWaveMO)
                let artistParser = ArtistParserDelegate(library: batchLibrary, syncWave: syncWaveContext, parseNotifier: statusNotifyier)
                self.ampacheXmlServerApi.requestArtists(parserDelegate: artistParser, startIndex: i*AmpacheXmlServerApi.maxItemCountToPollAtOnce)
                batchLibrary.saveContext()
                downloadSlotCounter.downloadFinished()
            }
        }
        downloadSlotCounter.waitTillAllDownloadsFinished()

        statusNotifyier?.notifySyncStarted(ofType: .album)
        let pollCountAlbum = (ampacheXmlServerApi.albumCount / AmpacheXmlServerApi.maxItemCountToPollAtOnce)
        for i in 0...pollCountAlbum {
            downloadSlotCounter.waitForDownloadSlot()
            persistentContainer.performBackgroundTask() { (context) in
                let batchLibrary = LibraryStorage(context: context)
                let syncWaveMO = try! context.existingObject(with: syncWave.managedObject.objectID) as! SyncWaveMO
                let syncWaveContext = SyncWave(managedObject: syncWaveMO)
                let albumDelegate = AlbumParserDelegate(library: batchLibrary, syncWave: syncWaveContext, parseNotifier: statusNotifyier)
                self.ampacheXmlServerApi.requestAlbums(parserDelegate: albumDelegate, startIndex: i*AmpacheXmlServerApi.maxItemCountToPollAtOnce)
                batchLibrary.saveContext()
                downloadSlotCounter.downloadFinished()
            }
        }
        downloadSlotCounter.waitTillAllDownloadsFinished()
        
        statusNotifyier?.notifySyncStarted(ofType: .playlist)
        let playlistParser = PlaylistParserDelegate(library: syncLibrary, parseNotifier: statusNotifyier)
        ampacheXmlServerApi.requestPlaylists(parserDelegate: playlistParser)
        syncLibrary.saveContext()
        
        if ampacheXmlServerApi.isPodcastSupported {
            statusNotifyier?.notifySyncStarted(ofType: .podcast)
            let podcastParser = PodcastParserDelegate(library: syncLibrary, syncWave: syncWave, parseNotifier: statusNotifyier)
            ampacheXmlServerApi.requestPodcasts(parserDelegate: podcastParser)
            syncLibrary.saveContext()
        }
        
        syncWave.syncState = .Done
        syncLibrary.saveContext()
        statusNotifyier?.notifySyncFinished()
    }
    
    func sync(artist: Artist, library: LibraryStorage) {
        guard let syncWave = library.getLatestSyncWave() else { return }
        let albumParser = AlbumParserDelegate(library: library, syncWave: syncWave, parseNotifier: nil)
        self.ampacheXmlServerApi.requestArtistAlbums(of: artist, parserDelegate: albumParser)
        let songParser = SongParserDelegate(library: library, syncWave: syncWave, parseNotifier: nil)
        self.ampacheXmlServerApi.requestArtistSongs(of: artist, parserDelegate: songParser)
        library.saveContext()
    }
    
    func sync(album: Album, library: LibraryStorage) {
        guard let syncWave = library.getLatestSyncWave() else { return }
        let songParser = SongParserDelegate(library: library, syncWave: syncWave, parseNotifier: nil)
        self.ampacheXmlServerApi.requestAlbumSongs(of: album, parserDelegate: songParser)
        library.saveContext()
    }
    
    func syncMusicFolders(library: LibraryStorage) {
        ampacheXmlServerApi.eventLogger.error(topic: "Internal Error", statusCode: .internalError, message: "GetMusicFolders API function is not support by Ampache")
    }
    
    func syncIndexes(musicFolder: MusicFolder, library: LibraryStorage) {
        ampacheXmlServerApi.eventLogger.error(topic: "Internal Error", statusCode: .internalError, message: "GetIndexes API function is not support by Ampache")
    }
    
    func sync(directory: Directory, library: LibraryStorage) {
        ampacheXmlServerApi.eventLogger.error(topic: "Internal Error", statusCode: .internalError, message: "GetMusicDirectory API function is not support by Ampache")
    }

    func syncDownPlaylistsWithoutSongs(library: LibraryStorage) {
        let playlistParser = PlaylistParserDelegate(library: library, parseNotifier: nil)
        ampacheXmlServerApi.requestPlaylists(parserDelegate: playlistParser)
        library.saveContext()
    }
    
    func syncDown(playlist: Playlist, library: LibraryStorage) {
        guard let syncWave = library.getLatestSyncWave() else { return }
        os_log("Download playlist \"%s\" from server", log: log, type: .info, playlist.name)
        guard playlist.id != "" else { return }
        validatePlaylistId(playlist: playlist, library: library)
        guard playlist.id != "" else { return }

        os_log("Sync songs of playlist \"%s\"", log: log, type: .info, playlist.name)
        let parser = PlaylistSongsParserDelegate(playlist: playlist, library: library, syncWave: syncWave)
        ampacheXmlServerApi.requestPlaylistSongs(parserDelegate: parser, id: playlist.id)
        playlist.ensureConsistentItemOrder()
        library.saveContext()
    }
    
    func syncUpload(playlistToAddSongs playlist: Playlist, songs: [Song], library: LibraryStorage) {
        os_log("Upload SongsAdded on playlist \"%s\"", log: log, type: .info, playlist.name)
        validatePlaylistId(playlist: playlist, library: library)
        for song in songs {
            ampacheXmlServerApi.requestPlaylistAddSong(playlist: playlist, song: song)
        }
    }
    
    func syncUpload(playlistToDeleteSong playlist: Playlist, index: Int, library: LibraryStorage) {
        os_log("Upload SongDelete on playlist \"%s\"", log: log, type: .info, playlist.name)
        ampacheXmlServerApi.requestPlaylistDeleteItem(playlist: playlist, index: index)
    }
    
    func syncUpload(playlistToUpdateOrder playlist: Playlist, library: LibraryStorage) {
        os_log("Upload OrderChange on playlist \"%s\"", log: log, type: .info, playlist.name)
        ampacheXmlServerApi.requestPlaylistEdit(playlist: playlist)
    }
    
    func syncUpload(playlistToDelete playlist: Playlist) {
        os_log("Upload Delete playlist \"%s\"", log: log, type: .info, playlist.name)
        ampacheXmlServerApi.requestPlaylistDelete(playlist: playlist)
    }
    
    private func validatePlaylistId(playlist: Playlist, library: LibraryStorage) {
        let playlistParser = PlaylistParserDelegate(library: library, parseNotifier: nil)
        playlistParser.playlist = playlist
        ampacheXmlServerApi.requestPlaylist(parserDelegate: playlistParser, id: playlist.id)
        if playlist.id == "" {
            os_log("Create playlist on server", log: log, type: .info)
            let playlistParser = PlaylistParserDelegate(library: library, parseNotifier: nil)
            playlistParser.playlist = playlist
            ampacheXmlServerApi.requestPlaylistCreate(parserDelegate: playlistParser, playlist: playlist)
        }
    }
    
    func syncDownPodcastsWithoutEpisodes(library: LibraryStorage) {
        guard let syncWave = library.getLatestSyncWave() else { return }
        let podcastParser = PodcastParserDelegate(library: library, syncWave: syncWave, parseNotifier: nil)
        ampacheXmlServerApi.requestPodcasts(parserDelegate: podcastParser)
        library.saveContext()
    }
    
    func sync(podcast: Podcast, library: LibraryStorage) {
        guard let syncWave = library.getLatestSyncWave() else { return }
        let podcastEpisodeParser = PodcastEpisodeParserDelegate(podcast: podcast, library: library, syncWave: syncWave)
        self.ampacheXmlServerApi.requestPodcastEpisodes(of: podcast, parserDelegate: podcastEpisodeParser)
        library.saveContext()
    }
    
    func searchArtists(searchText: String, library: LibraryStorage) {
        guard let syncWave = library.getLatestSyncWave(), searchText.count > 0 else { return }
        os_log("Search artists via API: \"%s\"", log: log, type: .info, searchText)
        let parser = ArtistParserDelegate(library: library, syncWave: syncWave)
        ampacheXmlServerApi.requestSearchArtists(parserDelegate: parser, searchText: searchText)
        library.saveContext()
    }
    
    func searchAlbums(searchText: String, library: LibraryStorage) {
        guard let syncWave = library.getLatestSyncWave(), searchText.count > 0 else { return }
        os_log("Search albums via API: \"%s\"", log: log, type: .info, searchText)
        let parser = AlbumParserDelegate(library: library, syncWave: syncWave)
        ampacheXmlServerApi.requestSearchAlbums(parserDelegate: parser, searchText: searchText)
        library.saveContext()
    }
    
    func searchSongs(searchText: String, library: LibraryStorage) {
        guard let syncWave = library.getLatestSyncWave(), searchText.count > 0 else { return }
        os_log("Search songs via API: \"%s\"", log: log, type: .info, searchText)
        let parser = SongParserDelegate(library: library, syncWave: syncWave)
        ampacheXmlServerApi.requestSearchSongs(parserDelegate: parser, searchText: searchText)
        library.saveContext()
    }

}
