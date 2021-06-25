import XCTest
@testable import Amperfy

class PodcastEpisodesParserTest: AbstractAmpacheTest {
    
    var testPodcast: Podcast?
    
    override func setUp() {
        super.setUp()
        xmlData = getTestFileData(name: "podcast_episodes")
        testPodcast = library.createPodcast()
        recreateParserDelegate()
    }
    
    override func recreateParserDelegate() {
        parserDelegate = PodcastEpisodeParserDelegate(podcast: testPodcast!, library: library, syncWave: syncWave)
    }
    
    override func checkCorrectParsing() {
        guard let podcast = testPodcast else { XCTFail(); return }
        XCTAssertEqual(podcast.episodes.count, 4)

        var episode = podcast.episodes[0]
        XCTAssertEqual(episode.id, "44")
        XCTAssertEqual(episode.playInfo!.id, "")
        XCTAssertEqual(episode.playInfo!.title, "COVID, Quickly, Episode 3: Vaccine Inequality--plus Your Body the Variant Fighter")
        XCTAssertEqual(episode.depiction, "Today&nbsp;we bring you the third&nbsp;episode in&nbsp;a new podcast series: COVID, Quickly.&nbsp;Every two weeks,&nbsp;Scientific American&rsquo;s senior health editors&nbsp;Tanya...&lt;br/&gt;")
        XCTAssertEqual(episode.publishDate.timeIntervalSince1970, 1616815800)//"3/27/21, 3:30 AM"
        XCTAssertNil(episode.streamId)
        XCTAssertEqual(episode.remoteStatus, .completed)
        XCTAssertEqual(episode.podcast, podcast)
        XCTAssertNil(episode.playInfo!.artist)
        XCTAssertNil(episode.playInfo!.album)
        XCTAssertNil(episode.playInfo!.disk)
        XCTAssertEqual(episode.playInfo!.track, 0)
        XCTAssertNil(episode.playInfo!.genre)
        XCTAssertEqual(episode.playInfo!.duration, 325)
        XCTAssertEqual(episode.playInfo!.year, 0)
        XCTAssertEqual(episode.playInfo!.bitrate, 0)
        XCTAssertEqual(episode.playInfo!.contentType, "audio/mpeg")
        XCTAssertEqual(episode.playInfo!.url, "https://music.com.au/play/index.php?ssid=cfj3f237d563f479f5223k23189dbb34&type=podcast_episode&oid=44&uid=4&format=raw&player=api&name=60-Second%20Science%20-%20COVID-%20Quickly-%20Episode%203-%20Vaccine%20Inequality-plus%20Your%20Body%20the%20Variant%20Fighter.mp3")
        XCTAssertEqual(episode.playInfo!.size, 5460000)
        XCTAssertEqual(episode.artwork?.url, "https://music.com.au/image.php?object_id=1&object_type=podcast&auth=eeb9f1b6056246a7d563f479f518bb34&name=art.jpg")
        XCTAssertEqual(episode.artwork?.type, "podcast")
        XCTAssertEqual(episode.artwork?.id, "1")

        episode = podcast.episodes[2]
        XCTAssertEqual(episode.id, "46")
        XCTAssertEqual(episode.playInfo!.id, "")
        XCTAssertEqual(episode.playInfo!.title, "Smartphones Can Hear the Shape of Your Door Keys")
        XCTAssertEqual(episode.depiction, "Can you pick a lock with just a smartphone? New research shows that doing so is possible.")
        XCTAssertEqual(episode.publishDate.timeIntervalSince1970, 1616104800)//"3/18/21, 10:00 PM"
        XCTAssertNil(episode.streamId)
        XCTAssertEqual(episode.remoteStatus, .downloading)
        XCTAssertEqual(episode.podcast, podcast)
        XCTAssertNil(episode.playInfo!.artist)
        XCTAssertNil(episode.playInfo!.album)
        XCTAssertNil(episode.playInfo!.disk)
        XCTAssertEqual(episode.playInfo!.track, 0)
        XCTAssertNil(episode.playInfo!.genre)
        XCTAssertEqual(episode.playInfo!.duration, 222)
        XCTAssertEqual(episode.playInfo!.year, 0)
        XCTAssertEqual(episode.playInfo!.bitrate, 0)
        XCTAssertEqual(episode.playInfo!.contentType, "")
        XCTAssertEqual(episode.playInfo!.url, "https://music.com.au/play/index.php?ssid=cfj3f237d563f479f5223k23189dbb34&type=podcast_episode&oid=46&uid=4&format=raw&player=api&name=60-Second%20Science%20-%20Smartphones%20Can%20Hear%20the%20Shape%20of%20Your%20Door%20Keys.")
        XCTAssertEqual(episode.playInfo!.size, 0)
        XCTAssertEqual(episode.artwork?.url, "https://music.com.au/image.php?object_id=1&object_type=podcast&auth=eeb9f1b6056246a7d563f479f518bb34&name=art.jpg")
        XCTAssertEqual(episode.artwork?.type, "podcast")
        XCTAssertEqual(episode.artwork?.id, "1")

        episode = podcast.episodes[3]
        XCTAssertEqual(episode.id, "47")
        XCTAssertEqual(episode.playInfo!.title, "Chimpanzees Show Altruism while Gathering around the Juice Fountain")
        XCTAssertEqual(episode.depiction, "New research tries to tease out whether our closest animal relatives can be selfless.")
        XCTAssertEqual(episode.publishDate.timeIntervalSince1970, 1615933800)//"3/16/21, 10:30 PM"
        XCTAssertNil(episode.streamId)
        XCTAssertEqual(episode.remoteStatus, .downloading)
        XCTAssertEqual(episode.podcast, podcast)
        XCTAssertNil(episode.playInfo!.artist)
        XCTAssertNil(episode.playInfo!.album)
        XCTAssertNil(episode.playInfo!.disk)
        XCTAssertEqual(episode.playInfo!.track, 0)
        XCTAssertNil(episode.playInfo!.genre)
        XCTAssertEqual(episode.playInfo!.duration, 296)
        XCTAssertEqual(episode.playInfo!.year, 0)
        XCTAssertEqual(episode.playInfo!.bitrate, 0)
        XCTAssertEqual(episode.playInfo!.contentType, "")
        XCTAssertEqual(episode.playInfo!.url, "https://music.com.au/play/index.php?ssid=cfj3f237d563f479f5223k23189dbb34&type=podcast_episode&oid=47&uid=4&format=raw&player=api&name=60-Second%20Science%20-%20Chimpanzees%20Show%20Altruism%20while%20Gathering%20around%20the%20Juice%20Fountain.")
        XCTAssertEqual(episode.playInfo!.size, 0)
        XCTAssertEqual(episode.artwork?.url, "https://music.com.au/image.php?object_id=1&object_type=podcast&auth=eeb9f1b6056246a7d563f479f518bb34&name=art.jpg")
        XCTAssertEqual(episode.artwork?.type, "podcast")
        XCTAssertEqual(episode.artwork?.id, "1")
    }

}
