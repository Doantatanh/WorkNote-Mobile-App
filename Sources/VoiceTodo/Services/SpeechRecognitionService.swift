import Foundation
import Speech
import AVFoundation

public class SpeechRecognitionService: ObservableObject {
    @Published public var transcribedText: String = ""
    @Published public var isTranscribing: Bool = false
    @Published public var isAvailable: Bool = false
    @Published public var errorMessage: String?

    private var speechRecognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()

    public init() {
        let viLocale = Locale(identifier: "vi-VN")
        if SFSpeechRecognizer.supportedLocales().contains(viLocale) {
            self.speechRecognizer = SFSpeechRecognizer(locale: viLocale)
        } else {
            self.speechRecognizer = SFSpeechRecognizer(locale: Locale.current)
        }
        checkPermission()
    }

    public func checkPermission() {
        SFSpeechRecognizer.requestAuthorization { [weak self] status in
            DispatchQueue.main.async {
                switch status {
                case .authorized:
                    self?.isAvailable = true
                default:
                    self?.isAvailable = false
                }
            }
        }
    }

    public func startLiveTranscription() {
        guard let recognizer = speechRecognizer, recognizer.isAvailable else {
            errorMessage = "Nhận diện giọng nói hiện không khả dụng"
            return
        }

        stopTranscription()
        transcribedText = ""
        isTranscribing = true

        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let request = recognitionRequest else { return }
        request.shouldReportPartialResults = true

        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)

        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] (buffer, _) in
            self?.recognitionRequest?.append(buffer)
        }

        audioEngine.prepare()
        do {
            try audioEngine.start()
        } catch {
            errorMessage = "Không thể bật microphone: \(error.localizedDescription)"
            stopTranscription()
            return
        }

        recognitionTask = recognizer.recognitionTask(with: request) { [weak self] result, error in
            guard let self = self else { return }
            if let result = result {
                DispatchQueue.main.async {
                    self.transcribedText = result.bestTranscription.formattedString
                }
            }
            if error != nil || (result?.isFinal ?? false) {
                self.stopTranscription()
            }
        }
    }

    public func stopTranscription() {
        if audioEngine.isRunning {
            audioEngine.stop()
            audioEngine.inputNode.removeTap(onBus: 0)
        }
        recognitionRequest?.endAudio()
        recognitionRequest = nil
        recognitionTask?.cancel()
        recognitionTask = nil
        isTranscribing = false
    }

    public func transcribeAudioFile(url: URL, completion: @escaping (String?) -> Void) {
        guard let recognizer = speechRecognizer, recognizer.isAvailable else {
            completion(nil)
            return
        }

        let request = SFSpeechURLRecognitionRequest(url: url)
        recognizer.recognitionTask(with: request) { result, error in
            if let result = result, result.isFinal {
                completion(result.bestTranscription.formattedString)
            } else if error != nil {
                completion(nil)
            }
        }
    }
}
