import { Controller } from "@hotwired/stimulus"

// Voice Command Audio Recorder Controller
// Handles microphone recording and submits the enclosing form with the audio file.
// Supports both Web Audio API and Turbo Native bridges for iOS and Android.
//
// Usage:
//   <form data-controller="voice-command-audio-recorder">
//     <input type="file" name="audio" data-voice-command-audio-recorder-target="input" class="hidden">
//     <button type="button"
//             data-action="voice-command-audio-recorder#toggle"
//             data-voice-command-audio-recorder-target="button">
//       Record
//     </button>
//   </form>
export default class extends Controller {
  static targets = ["button", "input"]

  connect() {
    this.mediaRecorder = null
    this.mediaStream = null
    this.chunks = []
    this.defaultButtonClasses = this.buttonTarget.className
    this.isNativeRecording = false
    this.setupNativeBridgeListeners()
    this.resetUi()
  }

  disconnect() {
    this.cleanupStream()
    this.removeNativeBridgeListeners()
  }

  // Detect if running in Turbo Native
  isTurboNative() {
    return window.turboNativeAvailable === true
  }

  // Detect if running in iOS Turbo Native
  isTurboNativeIOS() {
    return this.isTurboNative() &&
           window.webkit?.messageHandlers?.startRecording !== undefined
  }

  // Detect if running in Android Turbo Native
  isTurboNativeAndroid() {
    return this.isTurboNative() &&
           window.TurboNativeAudio !== undefined
  }

  // Setup event listeners for native bridge callbacks
  setupNativeBridgeListeners() {
    this.handleRecordingStarted = this.handleRecordingStarted.bind(this)
    this.handleRecordingStopped = this.handleRecordingStopped.bind(this)
    this.handleRecordingError = this.handleRecordingError.bind(this)

    window.addEventListener('turboNative:recordingStarted', this.handleRecordingStarted)
    window.addEventListener('turboNative:recordingStopped', this.handleRecordingStopped)
    window.addEventListener('turboNative:recordingError', this.handleRecordingError)
  }

  removeNativeBridgeListeners() {
    window.removeEventListener('turboNative:recordingStarted', this.handleRecordingStarted)
    window.removeEventListener('turboNative:recordingStopped', this.handleRecordingStopped)
    window.removeEventListener('turboNative:recordingError', this.handleRecordingError)
  }

  // Native bridge callback: recording started
  handleRecordingStarted(event) {
    if (event.detail?.success) {
      this.isNativeRecording = true
      this.updateRecordingUI()
    } else {
      this.cleanupStream()
      this.resetUi()
    }
  }

  // Native bridge callback: recording stopped
  handleRecordingStopped(event) {
    const audioData = event.detail?.audioData
    if (!audioData) {
      this.cleanupStream()
      this.isNativeRecording = false
      this.resetUi()
      return
    }

    // Parse the data (format: "base64data|filename")
    const [base64Data, filename] = audioData.split('|')

    // Convert base64 to blob
    try {
      const byteCharacters = atob(base64Data)
      const byteNumbers = new Array(byteCharacters.length)
      for (let i = 0; i < byteCharacters.length; i++) {
        byteNumbers[i] = byteCharacters.charCodeAt(i)
      }
      const byteArray = new Uint8Array(byteNumbers)
      const blob = new Blob([byteArray], { type: 'audio/m4a' })

      const file = new File([blob], filename || 'recording.m4a', { type: 'audio/m4a' })
      const transfer = new DataTransfer()
      transfer.items.add(file)
      this.inputTarget.files = transfer.files

      this.element.requestSubmit()
    } catch (error) {
      console.error('Failed to process native audio:', error)
    }

    this.cleanupStream()
    this.isNativeRecording = false
    this.resetUi()
  }

  // Native bridge callback: recording error
  handleRecordingError(event) {
    this.cleanupStream()
    this.isNativeRecording = false
    this.resetUi()
  }

  async toggle(event) {
    event.preventDefault()

    if (this.isRecording()) {
      this.stopRecording()
    } else {
      await this.startRecording()
    }
  }

  async startRecording() {
    // Use native bridge if available
    if (this.isTurboNativeIOS()) {
      this.startNativeRecordingIOS()
      return
    }

    if (this.isTurboNativeAndroid()) {
      this.startNativeRecordingAndroid()
      return
    }

    // Fall back to Web Audio API
    if (!window.MediaRecorder || !navigator.mediaDevices?.getUserMedia) {
      console.error('MediaRecorder or getUserMedia not supported')
      return
    }

    try {
      this.mediaStream = await navigator.mediaDevices.getUserMedia({ audio: true })
    } catch (error) {
      console.error('Failed to get user media:', error)
      return
    }

    try {
      this.chunks = []
      this.mediaRecorder = new MediaRecorder(this.mediaStream)
    } catch (error) {
      console.error('Failed to create MediaRecorder:', error)
      this.cleanupStream()
      return
    }

    this.mediaRecorder.addEventListener("dataavailable", (event) => {
      if (event.data?.size > 0) this.chunks.push(event.data)
    })

    this.mediaRecorder.addEventListener("stop", () => {
      this.handleStop()
    })

    this.mediaRecorder.start()
    this.updateRecordingUI()
  }

  stopRecording() {
    // Use native bridge if recording natively
    if (this.isNativeRecording) {
      this.stopNativeRecording()
      return
    }

    // Fall back to Web Audio API
    if (!this.isRecording()) return

    this.buttonTarget.disabled = true
    this.mediaRecorder.stop()
  }

  // Start recording using iOS native bridge
  startNativeRecordingIOS() {
    try {
      window.webkit.messageHandlers.startRecording.postMessage({})
    } catch (error) {
      console.error('Failed to start iOS native recording:', error)
      this.cleanupStream()
      this.isNativeRecording = false
      this.resetUi()
    }
  }

  // Start recording using Android native bridge
  startNativeRecordingAndroid() {
    try {
      window.TurboNativeAudio.startRecording()
    } catch (error) {
      console.error('Failed to start Android native recording:', error)
      this.cleanupStream()
      this.isNativeRecording = false
      this.resetUi()
    }
  }

  // Stop recording using native bridge (works for both iOS and Android)
  stopNativeRecording() {
    this.buttonTarget.disabled = true

    try {
      if (this.isTurboNativeIOS()) {
        window.webkit.messageHandlers.stopRecording.postMessage({})
      } else if (this.isTurboNativeAndroid()) {
        window.TurboNativeAudio.stopRecording()
      }
    } catch (error) {
      console.error('Failed to stop native recording:', error)
      this.cleanupStream()
      this.isNativeRecording = false
      this.resetUi()
    }
  }

  // Update UI to show recording state
  // Customize these classes to match your design system
  updateRecordingUI() {
    this.buttonTarget.setAttribute("aria-pressed", "true")
    this.buttonTarget.className = this.defaultButtonClasses
    this.buttonTarget.classList.remove("bg-slate-900", "hover:bg-slate-800")
    this.buttonTarget.classList.add("bg-red-600", "hover:bg-red-700")
    this.buttonTarget.disabled = false
  }

  handleStop() {
    const blob = this.createBlob()
    this.cleanupStream()

    if (!blob) {
      this.resetUi()
      return
    }

    const file = new File([blob], this.buildFilename(blob.type), { type: blob.type })
    let transfer

    try {
      transfer = new DataTransfer()
    } catch (error) {
      console.error('DataTransfer not supported:', error)
      this.resetUi()
      return
    }

    transfer.items.add(file)
    this.inputTarget.files = transfer.files

    this.element.requestSubmit()
    this.resetUi()
  }

  isRecording() {
    return this.isNativeRecording || this.mediaRecorder?.state === "recording"
  }

  createBlob() {
    if (this.chunks.length === 0) return null
    const type = this.mediaRecorder?.mimeType || "audio/webm"
    return new Blob(this.chunks, { type })
  }

  buildFilename(mimeType) {
    const extension = this.extensionFor(mimeType)
    return `recording-${Date.now()}.${extension}`
  }

  extensionFor(mimeType) {
    if (!mimeType) return "webm"
    if (mimeType.includes("mpeg")) return "mp3"
    if (mimeType.includes("mp4") || mimeType.includes("mp4a")) return "m4a"
    if (mimeType.includes("ogg")) return "ogg"
    return "webm"
  }

  resetUi() {
    this.buttonTarget.setAttribute("aria-pressed", "false")
    this.buttonTarget.className = this.defaultButtonClasses
    this.buttonTarget.disabled = false
  }

  cleanupStream() {
    this.mediaStream?.getTracks().forEach((track) => track.stop())
    this.mediaStream = null
    this.mediaRecorder = null
    this.chunks = []
  }
}
