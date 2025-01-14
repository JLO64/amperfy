//
//  SongTableCell.swift
//  Amperfy
//
//  Created by Maximilian Bauer on 09.03.19.
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

import UIKit
import AmperfyKit

typealias GetPlayContextFromTableCellCallback = (UITableViewCell) -> PlayContext?
typealias GetPlayerIndexFromTableCellCallback = (PlayableTableCell) -> PlayerIndex?

class PlayableTableCell: BasicTableCell {
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var artistLabel: UILabel!
    @IBOutlet weak var durationLabel: UILabel!
    @IBOutlet weak var entityImage: EntityImageView!
    @IBOutlet weak var trackNumberLabel: UILabel!
    @IBOutlet weak var downloadProgress: UIProgressView! // depricated: replaced with a spinner in the accessoryView
    @IBOutlet weak private var cacheIconImage: UIImageView!
    @IBOutlet weak private var favoriteIconImage: UIImageView!
    
    @IBOutlet weak var labelTrailingCacheConstraint: NSLayoutConstraint!
    @IBOutlet weak var labelTrailingDurationConstraint: NSLayoutConstraint!
    @IBOutlet weak var labelTrailingCellConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var trackNumberTrailingTitleConstaint: NSLayoutConstraint!
    @IBOutlet weak var artworkTrailingTitleConstaint: NSLayoutConstraint!
    
    @IBOutlet weak var cacheTrailingDurationConstaint: NSLayoutConstraint!
    @IBOutlet weak var cacheTrailingCellConstaint: NSLayoutConstraint!
    
    static let rowHeight: CGFloat = 48 + margin.bottom + margin.top
    private static let touchAnimation = 0.4
    
    private var playerIndexCb: GetPlayerIndexFromTableCellCallback?
    private var playContextCb: GetPlayContextFromTableCellCallback?
    private var playable: AbstractPlayable?
    private var download: Download?
    private var rootView: UIViewController?
    private var playIndicator: PlayIndicator?
    private var isDislayAlbumTrackNumberStyle: Bool = false

    override func awakeFromNib() {
        super.awakeFromNib()
        playContextCb = nil
    }
    
    func display(playable: AbstractPlayable, playContextCb: @escaping GetPlayContextFromTableCellCallback, rootView: UIViewController, playerIndexCb: GetPlayerIndexFromTableCellCallback? = nil, isDislayAlbumTrackNumberStyle: Bool = false, download: Download? = nil) {
        if playIndicator == nil {
            playIndicator = PlayIndicator(rootViewTypeName: rootView.typeName)
        }
        self.playable = playable
        self.playContextCb = playContextCb
        self.playerIndexCb = playerIndexCb
        self.rootView = rootView
        self.isDislayAlbumTrackNumberStyle = isDislayAlbumTrackNumberStyle
        self.download = download
        self.selectionStyle = .none
        refresh()
    }

    func refresh() {
        downloadProgress.isHidden = true
        guard let playable = playable else { return }
        titleLabel.text = playable.title
        artistLabel.text = playable.creatorName
        entityImage.display(theme: appDelegate.storage.settings.themePreference, container: playable)
        
        if self.isDislayAlbumTrackNumberStyle {
            configureTrackNumberLabel()
            playIndicator?.willDisplayIndicatorCB = { [weak self] () in
                guard let self = self else { return }
                self.trackNumberLabel.text = ""
            }
            playIndicator?.willHideIndicatorCB = { [weak self] () in
                guard let self = self else { return }
                self.configureTrackNumberLabel()
            }
            
            playIndicator?.display(playable: playable, rootView: self.trackNumberLabel)
            trackNumberLabel.isHidden = false
            entityImage.isHidden = true
            trackNumberTrailingTitleConstaint.isActive = true
            artworkTrailingTitleConstaint.isActive = false
        } else {
            playIndicator?.willDisplayIndicatorCB = nil
            playIndicator?.willHideIndicatorCB = nil
            if self.playerIndexCb == nil {
                playIndicator?.display(playable: playable, rootView: self.entityImage, isOnImage: true)
            } else {
                // don't show play indicator on PopupPlayer
                playIndicator?.reset()
            }
            trackNumberLabel.isHidden = true
            entityImage.isHidden = false
            trackNumberTrailingTitleConstaint.isActive = false
            artworkTrailingTitleConstaint.isActive = true
        }
        
        if playerIndexCb != nil {
            let img = UIImageView(image: .bars)
            img.tintColor = .labelColor
            accessoryView = img
        } else if download?.error != nil {
            let img = UIImageView(image: .exclamation)
            img.tintColor = .labelColor
            accessoryView = img
        } else if download?.isFinishedSuccessfully ?? false {
            let img = UIImageView(image: .check)
            img.tintColor = .labelColor
            accessoryView = img
        } else if download?.isDownloading ?? false {
            let spinner = UIActivityIndicatorView(style: .medium)
            spinner.startAnimating()
            spinner.tintColor = .labelColor
            accessoryView = spinner
        } else {
            accessoryView = nil
        }
        
        refreshSubtitleColor()
        refreshCacheAndDuration()
    }
    
    private func configureTrackNumberLabel() {
        guard let playable = playable else { return }
        trackNumberLabel.text = playable.track > 0 ? "\(playable.track)" : ""
    }
    
    func refreshCacheAndDuration() {
        guard let playable = playable else { return }
        let isDurationVisible = appDelegate.storage.settings.isShowSongDuration || (traitCollection.horizontalSizeClass == .regular)
        if traitCollection.horizontalSizeClass == .regular {
            cacheIconImage.isHidden = !playable.isCached
            // only one distant constaint is active for regular
        } else {
            if playable.isCached {
                cacheIconImage.isHidden = false
                labelTrailingCacheConstraint.isActive = true
                labelTrailingDurationConstraint.isActive = false
                labelTrailingCellConstraint.isActive = false
            } else if isDurationVisible {
                cacheIconImage.isHidden = true
                labelTrailingCacheConstraint.isActive = false
                labelTrailingDurationConstraint.isActive = true
                labelTrailingCellConstraint.isActive = false
            } else {
                cacheIconImage.isHidden = true
                labelTrailingCacheConstraint.isActive = false
                labelTrailingDurationConstraint.isActive = false
                labelTrailingCellConstraint.isActive = true
            }
        }
        
        favoriteIconImage.isHidden = !playable.isFavorite
        favoriteIconImage.tintColor = .red
        
        durationLabel.isHidden = !isDurationVisible
        if isDurationVisible {
            durationLabel.text = playable.duration.asColonDurationString
            cacheTrailingDurationConstaint.isActive = true
            cacheTrailingCellConstaint.isActive = false
        } else {
            cacheTrailingDurationConstaint.isActive = false
            cacheTrailingCellConstaint.isActive = true
        }
    }
    
    private func refreshSubtitleColor() {
        if playerIndexCb != nil {
            cacheIconImage.tintColor = UIColor.labelColor
            artistLabel.textColor = UIColor.labelColor
            durationLabel.textColor = UIColor.labelColor
        } else {
            cacheIconImage.tintColor = UIColor.secondaryLabelColor
            artistLabel.textColor = UIColor.secondaryLabelColor
            durationLabel.textColor = UIColor.secondaryLabelColor
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        playIndicator?.reset()
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        playThisSong()
    }
    
    func playThisSong() {
        guard let playable = playable else { return }
        if let playerIndex = playerIndexCb?(self) {
            appDelegate.player.play(playerIndex: playerIndex)
        } else if let context = playContextCb?(self),
            playable.isCached || appDelegate.storage.settings.isOnlineMode {
             animateActivation()
             hideSearchBarKeyboardInRootView()
             Haptics.success.vibrate(isHapticsEnabled: appDelegate.storage.settings.isHapticsEnabled)
             appDelegate.player.play(context: context)
         }
    }
    
    private func hideSearchBarKeyboardInRootView() {
        if let basicRootView = rootView as? BasicTableViewController {
            basicRootView.searchController.searchBar.endEditing(true)
        }
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        playIndicator?.applyStyle()
    }

}
