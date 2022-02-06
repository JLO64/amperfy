import Foundation
import UIKit

enum SwipeActionType: Int, CaseIterable {
    case insertUserQueue = 0
    case appendUserQueue = 1
    case insertContextQueue = 2
    case appendContextQueue = 3
    case download = 4
    case removeFromCache = 5
    
    var displayName: String {
        switch self {
        case .insertUserQueue:
            return "Insert User Queue"
        case .appendUserQueue:
            return "Append User Queue"
        case .insertContextQueue:
            return "Insert Context Queue"
        case .appendContextQueue:
            return "Append Context Queue"
        case .download:
            return "Download"
        case .removeFromCache:
            return "Remove from Cache"
        }
    }

    var settingsName: String {
        switch self {
        case .insertUserQueue:
            return "Insert in User Queue"
        case .appendUserQueue:
            return "Append to User Queue"
        case .insertContextQueue:
            return "Insert in Context Queue"
        case .appendContextQueue:
            return "Append to Context Queue"
        case .download:
            return "Download"
        case .removeFromCache:
            return "Remove from Cache"
        }
    }

    var image: UIImage {
        switch self {
        case .insertUserQueue:
            return UIImage(named: "user_queue_insert") ?? Artwork.defaultImage
        case .appendUserQueue:
            return UIImage(named: "user_queue_append") ?? Artwork.defaultImage
        case .insertContextQueue:
            return UIImage(named: "context_queue_insert") ?? Artwork.defaultImage
        case .appendContextQueue:
            return UIImage(named: "context_queue_append") ?? Artwork.defaultImage
        case .download:
            return UIImage(named: "download") ?? Artwork.defaultImage
        case .removeFromCache:
            return UIImage(named: "trash") ?? Artwork.defaultImage
        }
    }
}

struct SwipeActionSettings {
    var combined: [[SwipeActionType]]

    var leading: [SwipeActionType] {
        return combined[0]
    }
    var trailing: [SwipeActionType] {
        return combined[1]
    }
    var notUsed: [SwipeActionType] {
        return combined[2]
    }
    
    init(leading: [SwipeActionType], trailing: [SwipeActionType]) {
        let notUsedSet = Set(SwipeActionType.allCases).subtracting(Set(leading)).subtracting(Set(trailing))
        combined = [ leading, trailing, Array(notUsedSet) ]
    }
    
    static var defaultSettings: SwipeActionSettings {
        return SwipeActionSettings(
            leading: [
                .appendContextQueue,
                .insertContextQueue

            ], trailing: [
                .appendUserQueue,
                .insertUserQueue,
                .download
        ])
    }
}