from faster_whisper import WhisperModel

# Load Whisper model (tiny or base)
model = WhisperModel("base", device="cpu", compute_type="int8")


def transcribe_audio(audio_path: str) -> str:
    """
    Transcribes audio file to text using Whisper.
    """
    segments, _ = model.transcribe(audio_path)
    full_text = " ".join([segment.text for segment in segments])
    return full_text.strip()
