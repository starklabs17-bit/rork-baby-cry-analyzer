# Secure recordings and remove audio after analysis

**Features**
- [x] Protect each audio recording with device-level encryption while it is stored on the phone.
- [x] Automatically remove the recording as soon as the analysis finishes and is saved.
- [x] Keep the analysis history intact while avoiding leftover raw audio files.
- [x] Preserve the current recording and analysis flow so the app feels the same to use.

**Design**
- [x] No visual redesign is needed for this change.
- [x] The update is focused on privacy and background behavior.
- [x] Any existing success and error states should continue to behave the same.

**Pages / Screens**
- [x] **Listen screen**: Recording stays the same for the user, but the temporary audio file is protected and then deleted after a successful result is stored.
- [x] **History screen**: Saved analysis results remain available as before, without keeping the original audio recording.
