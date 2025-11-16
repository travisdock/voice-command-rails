import { Controller } from "@hotwired/stimulus"

// Audio Recorder Controller for Voice Command Rails
// Handles audio recording across Web, iOS, and Android platforms
export default class extends Controller {
  static targets = ["button", "input", "status"]

  connect() {
    this.mediaRecorder = null
    this.mediaStream = null
    this.chunks = []
    this.defaultButtonClasses = this.buttonTarget.className
    this.isNativeRecording = false

    // Set up native bridge listeners for Turbo Native apps
    this.setupNativeBridgeListeners()

    this.resetUi()
  }

  disconnect() {
    this.cleanupStream()
    this.removeNativeBridgeListeners()
  }

  // Toggle recording on/off
  toggle() {
    const isRecording = this.buttonTarget.getAttribute("aria-pressed") === "true"

    if (isRecording) {
      this.stopRecording()
    } else {
      this.startRecording()
    }
  }

  // Start recording audio
  async startRecording() {
    try {
      // Check if we're in a Turbo Native app
      if (this.isTurboNativeIOS()) {
        this.startNativeRecordingIOS()
        return
      }

      if (this.isTurboNativeAndroid()) {
        this.startNativeRecordingAndroid()
        return
      }

      // Web Audio API recording
      this.mediaStream = await navigator.mediaDevices.getUserMedia({ audio: true })

      this.chunks = []
      this.mediaRecorder = new MediaRecorder(this.mediaStream)

      this.mediaRecorder.addEventListener("dataavailable", (event) => {
        if (event.data && event.data.size > 0) {
          this.chunks.push(event.data)
        }
      })

      this.mediaRecorder.addEventListener("stop", () => {
        this.handleStop()
      })

      this.mediaRecorder.start()
      this.updateRecordingUI()

    } catch (error) {
      console.error("Error starting recording:", error)
      this.showError("Could not access microphone. Please check permissions.")
      this.resetUi()
    }
  }

  // Stop recording audio
  stopRecording() {
    if (this.isNativeRecording) {
      this.stopNativeRecording()
      return
    }

    if (this.mediaRecorder && this.mediaRecorder.state !== "inactive") {
      this.mediaRecorder.stop()
    }
  }

  // Handle recording stop event
  handleStop() {
    const blob = this.createBlob()

    if (!blob) {
      this.showError("No audio data recorded")
      this.resetUi()
      return
    }

    const file = new File([blob], this.buildFilename(blob.type), {
      type: blob.type
    })

    this.populateFileInput(file)
    this.submitForm()
    this.cleanupStream()
    this.resetUi()
  }

  // Create blob from recorded chunks
  createBlob() {
    if (!this.chunks || this.chunks.length === 0) {
      return null
    }

    const mimeType = this.mediaRecorder?.mimeType || "audio/webm"
    return new Blob(this.chunks, { type: mimeType })
  }

  // Build filename with timestamp and extension
  buildFilename(mimeType) {
    const timestamp = new Date().getTime()
    const extension = this.extensionFor(mimeType)
    return `voice_command_${timestamp}.${extension}`
  }

  // Get file extension from MIME type
  extensionFor(mimeType) {
    if (!mimeType) return "webm"
    if (mimeType.includes("mpeg")) return "mp3"
    if (mimeType.includes("mp4") || mimeType.includes("mp4a")) return "m4a"
    if (mimeType.includes("ogg")) return "ogg"
    if (mimeType.includes("wav")) return "wav"
    if (mimeType.includes("flac")) return "flac"
    return "webm"
  }

  // Populate the hidden file input
  populateFileInput(file) {
    const transfer = new DataTransfer()
    transfer.items.add(file)
    this.inputTarget.files = transfer.files
  }

  // Submit the form
  submitForm() {
    this.element.requestSubmit()
  }

  // Clean up media stream and recorder
  cleanupStream() {
    if (this.mediaStream) {
      this.mediaStream.getTracks().forEach(track => track.stop())
      this.mediaStream = null
    }

    this.mediaRecorder = null
    this.chunks = []
  }

  // Update UI to recording state
  updateRecordingUI() {
    this.buttonTarget.setAttribute("aria-pressed", "true")
    this.buttonTarget.disabled = false

    if (this.hasStatusTarget) {
      this.statusTarget.textContent = "Recording... Tap to stop"
      this.statusTarget.style.display = "block"
    }
  }

  // Reset UI to default state
  resetUi() {
    this.buttonTarget.setAttribute("aria-pressed", "false")
    this.buttonTarget.disabled = false

    if (this.hasStatusTarget) {
      this.statusTarget.style.display = "none"
    }
  }

  // Show error message
  showError(message) {
    console.error(message)

    if (this.hasStatusTarget) {
      this.statusTarget.textContent = message
      this.statusTarget.style.display = "block"

      setTimeout(() => {
        this.statusTarget.style.display = "none"
      }, 3000)
    }
  }

  // ===== TURBO NATIVE BRIDGE SUPPORT =====

  // Check if running in Turbo Native
  isTurboNative() {
    return window.turboNativeAvailable === true
  }

  // Check if running in Turbo Native iOS
  isTurboNativeIOS() {
    return this.isTurboNative() &&
           window.webkit?.messageHandlers?.startRecording !== undefined
  }

  // Check if running in Turbo Native Android
  isTurboNativeAndroid() {
    return this.isTurboNative() &&
           window.TurboNativeAudio !== undefined
  }

  // Set up native bridge event listeners
  setupNativeBridgeListeners() {
    this.handleRecordingStarted = this.handleRecordingStarted.bind(this)
    this.handleRecordingStopped = this.handleRecordingStopped.bind(this)
    this.handleRecordingError = this.handleRecordingError.bind(this)

    window.addEventListener('turboNative:recordingStarted', this.handleRecordingStarted)
    window.addEventListener('turboNative:recordingStopped', this.handleRecordingStopped)
    window.addEventListener('turboNative:recordingError', this.handleRecordingError)
  }

  // Remove native bridge event listeners
  removeNativeBridgeListeners() {
    window.removeEventListener('turboNative:recordingStarted', this.handleRecordingStarted)
    window.removeEventListener('turboNative:recordingStopped', this.handleRecordingStopped)
    window.removeEventListener('turboNative:recordingError', this.handleRecordingError)
  }

  // Start native recording on iOS
  startNativeRecordingIOS() {
    try {
      window.webkit.messageHandlers.startRecording.postMessage({})
      this.isNativeRecording = true
      this.updateRecordingUI()
    } catch (error) {
      console.error("Error starting iOS recording:", error)
      this.showError("Could not start recording")
    }
  }

  // Start native recording on Android
  startNativeRecordingAndroid() {
    try {
      window.TurboNativeAudio.startRecording()
      this.isNativeRecording = true
      this.updateRecordingUI()
    } catch (error) {
      console.error("Error starting Android recording:", error)
      this.showError("Could not start recording")
    }
  }

  // Stop native recording
  stopNativeRecording() {
    if (this.isTurboNativeIOS()) {
      window.webkit.messageHandlers.stopRecording.postMessage({})
    } else if (this.isTurboNativeAndroid()) {
      window.TurboNativeAudio.stopRecording()
    }
  }

  // Handle native recording started event
  handleRecordingStarted(event) {
    console.log("Native recording started")
  }

  // Handle native recording stopped event
  handleRecordingStopped(event) {
    const audioData = event.detail?.audioData

    if (!audioData) {
      this.showError("No audio data received")
      this.resetUi()
      return
    }

    // Audio data format: "base64Data|filename"
    const [base64Data, filename] = audioData.split('|')

    try {
      // Convert base64 to blob
      const byteCharacters = atob(base64Data)
      const byteNumbers = new Array(byteCharacters.length)

      for (let i = 0; i < byteCharacters.length; i++) {
        byteNumbers[i] = byteCharacters.charCodeAt(i)
      }

      const byteArray = new Uint8Array(byteNumbers)
      const blob = new Blob([byteArray], { type: 'audio/m4a' })

      const file = new File(
        [blob],
        filename || this.buildFilename('audio/m4a'),
        { type: 'audio/m4a' }
      )

      this.populateFileInput(file)
      this.submitForm()

    } catch (error) {
      console.error("Error processing native audio:", error)
      this.showError("Error processing audio")
    }

    this.isNativeRecording = false
    this.resetUi()
  }

  // Handle native recording error event
  handleRecordingError(event) {
    const errorMessage = event.detail?.error || "Recording error"
    console.error("Native recording error:", errorMessage)
    this.showError(errorMessage)
    this.isNativeRecording = false
    this.resetUi()
  }
}
