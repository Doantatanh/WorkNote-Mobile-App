import Foundation
import AVFoundation
import Combine

public class AudioRecorderService: NSObject, ObservableObject, AVAudioRecorderDelegate {
    @Published public var isRecording = false
    @Published public var recordingDuration: TimeInterval = 0
    @Published public var currentAudioLevels: [CGFloat] = Array(repeating: 0.15, count: 20)
    @Published public var hasPermission = false
    @Published public var errorMessage: String?

    private var audioRecorder: AVAudioRecorder?
    private var timer: AnyCancellable?
    private var tempFileName: String?

    public override init() {
        super.init()
        checkPermission()
    }

    public static func getRecordingsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let recordingsDir = paths[0].appendingPathComponent("Recordings", isDirectory: true)
        if !FileManager.default.fileExists(atPath: recordingsDir.path) {
            try? FileManager.default.createDirectory(at: recordingsDir, withIntermediateDirectories: true)
        }
        return recordingsDir
    }

    public static func audioURL(for fileName: String) -> URL {
        return getRecordingsDirectory().appendingPathComponent(fileName)
    }

    public func checkPermission() {
        let session = AVAudioSession.sharedInstance()
        switch session.recordPermission {
        case .granted:
            self.hasPermission = true
        case .denied:
            self.hasPermission = false
        case .undetermined:
            session.requestRecordPermission { [weak self] allowed in
                DispatchQueue.main.async {
                    self?.hasPermission = allowed
                }
            }
        @unknown default:
            self.hasPermission = false
        }
    }

    public func startRecording() -> Bool {
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetooth])
            try audioSession.setActive(true)
        } catch {
            self.errorMessage = "Không thể khởi động Microphone: \(error.localizedDescription)"
            return false
        }

        let fileName = "rec_\(UUID().uuidString).m4a"
        let fileURL = Self.audioURL(for: fileName)
        self.tempFileName = fileName

        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100.0,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]

        do {
            audioRecorder = try AVAudioRecorder(url: fileURL, settings: settings)
            audioRecorder?.delegate = self
            audioRecorder?.isMeteringEnabled = true
            audioRecorder?.record()

            self.isRecording = true
            self.recordingDuration = 0

            startTimer()
            return true
        } catch {
            self.errorMessage = "Lỗi ghi âm: \(error.localizedDescription)"
            return false
        }
    }

    public func stopRecording() -> (fileName: String, duration: TimeInterval)? {
        guard isRecording, let recorder = audioRecorder, let fileName = tempFileName else {
            return nil
        }

        recorder.stop()
        let duration = self.recordingDuration
        stopTimer()

        self.isRecording = false
        self.audioRecorder = nil
        self.tempFileName = nil

        try? AVAudioSession.sharedInstance().setActive(false)

        return (fileName: fileName, duration: duration)
    }

    public func cancelRecording() {
        guard let recorder = audioRecorder, let fileName = tempFileName else { return }
        recorder.stop()
        stopTimer()
        self.isRecording = false
        self.audioRecorder = nil
        self.tempFileName = nil

        let url = Self.audioURL(for: fileName)
        try? FileManager.default.removeItem(at: url)
    }

    private func startTimer() {
        timer = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect().sink { [weak self] _ in
            guard let self = self, let recorder = self.audioRecorder, recorder.isRecording else { return }
            self.recordingDuration += 0.1
            recorder.updateMeters()
            let power = recorder.averagePower(forChannel: 0) // range: -160 to 0
            let normalizedPower = max(0.1, CGFloat((power + 50) / 50)) // scale roughly to 0.1 - 1.0

            var levels = self.currentAudioLevels
            levels.removeFirst()
            levels.append(normalizedPower)
            self.currentAudioLevels = levels
        }
    }

    private func stopTimer() {
        timer?.cancel()
        timer = nil
        currentAudioLevels = Array(repeating: 0.15, count: 20)
    }
}
