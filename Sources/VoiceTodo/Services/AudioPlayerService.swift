import Foundation
import AVFoundation
import Combine

public class AudioPlayerService: NSObject, ObservableObject, AVAudioPlayerDelegate {
    @Published public var isPlaying = false
    @Published public var currentTime: TimeInterval = 0
    @Published public var duration: TimeInterval = 0
    @Published public var playingFileName: String?
    @Published public var playbackRate: Float = 1.0

    private var audioPlayer: AVAudioPlayer?
    private var timer: AnyCancellable?

    public override init() {
        super.init()
    }

    public func playAudio(fileName: String) {
        if playingFileName == fileName && audioPlayer != nil {
            if isPlaying {
                pause()
            } else {
                resume()
            }
            return
        }

        stop()

        let fileURL = AudioRecorderService.audioURL(for: fileName)
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            print("File không tồn tại: \(fileURL.path)")
            return
        }

        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default)
            try session.setActive(true)

            audioPlayer = try AVAudioPlayer(contentsOf: fileURL)
            audioPlayer?.delegate = self
            audioPlayer?.enableRate = true
            audioPlayer?.rate = playbackRate
            audioPlayer?.prepareToPlay()
            audioPlayer?.play()

            self.playingFileName = fileName
            self.duration = audioPlayer?.duration ?? 0
            self.currentTime = 0
            self.isPlaying = true

            startTimer()
        } catch {
            print("Lỗi phát audio: \(error.localizedDescription)")
        }
    }

    public func pause() {
        audioPlayer?.pause()
        isPlaying = false
        stopTimer()
    }

    public func resume() {
        audioPlayer?.rate = playbackRate
        audioPlayer?.play()
        isPlaying = true
        startTimer()
    }

    public func stop() {
        audioPlayer?.stop()
        audioPlayer = nil
        isPlaying = false
        currentTime = 0
        playingFileName = nil
        stopTimer()
    }

    public func seek(to time: TimeInterval) {
        audioPlayer?.currentTime = time
        currentTime = time
    }

    public func setRate(_ rate: Float) {
        playbackRate = rate
        if let player = audioPlayer {
            player.rate = rate
        }
    }

    public func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        DispatchQueue.main.async { [weak self] in
            self?.stop()
        }
    }

    private func startTimer() {
        timer = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect().sink { [weak self] _ in
            guard let self = self, let player = self.audioPlayer, player.isPlaying else { return }
            self.currentTime = player.currentTime
        }
    }

    private func stopTimer() {
        timer?.cancel()
        timer = nil
    }
}
