//
//  SsPlaylistSongsParserDelegate.swift
//  AmperfyKit
//
//  Created by Maximilian Bauer on 05.04.19.
//  Copyright (c) 2019 Maximilian Bauer. All rights reserved.
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program.  If not, see <http://www.gnu.org/licenses/>.
//

import Foundation
import UIKit
import CoreData
import os.log

class SsPlaylistSongsParserDelegate: SsSongParserDelegate {
    
    private let playlist: Playlist
    var items: [PlaylistItem]
    public private(set) var playlistHasBeenDetected = false
    
    init(performanceMonitor: ThreadPerformanceMonitor, playlist: Playlist, library: LibraryStorage, subsonicUrlCreator: SubsonicUrlCreator) {
        self.playlist = playlist
        self.items = playlist.items
        super.init(performanceMonitor: performanceMonitor, library: library, subsonicUrlCreator: subsonicUrlCreator)
    }
    
    override func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String]) {
        super.parser(parser, didStartElement: elementName, namespaceURI: namespaceURI, qualifiedName: qName, attributes: attributeDict)

        if elementName == "playlist" {
            guard let playlistId = attributeDict["id"] else { return }
            playlistHasBeenDetected = true
            if playlist.id != playlistId {
                playlist.id = playlistId
            }
            if let attributePlaylistName = attributeDict["name"] {
                playlist.name = attributePlaylistName
            }
            if let attributeSongCount = attributeDict["songCount"], let songCount = Int(attributeSongCount) {
                playlist.songCount = songCount
            }
        }
        
        if elementName == "entry" {
            let order = Int(parsedCount)
            var item: PlaylistItem?
            
            if order < items.count {
                item = items[order]
            } else {
                item = library.createPlaylistItem()
                item?.order = order
                playlist.add(item: item!)
            }
            if item?.playable?.id != songBuffer?.id {
                playlist.updateChangeDate()
            }
            item?.playable = songBuffer
        }
    }
    
    override func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        switch(elementName) {
        case "playlist":
            if items.count > parsedCount {
                for i in Array(parsedCount...items.count-1) {
                    library.deletePlaylistItem(item: items[i])
                }
            }
            playlist.updateDuration()
            playlist.updateSongCount()
        default:
            break
        }
        
        super.parser(parser, didEndElement: elementName, namespaceURI: namespaceURI, qualifiedName: qName)
    }
    
}
