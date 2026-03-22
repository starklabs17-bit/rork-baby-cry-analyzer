# Limit audio memory use during recording

**Features**
- Keep live recording responsive during long listening sessions.
- Prevent the running sound history from growing without limit in memory.
- Preserve the recent sound level data needed for the current analysis experience.

**Design**
- No visual changes to the app.
- Recording behavior stays the same from the user’s perspective.

**Pages / Screens**
- Listen screen: long recordings remain more stable and memory-efficient.

**Implementation Progress**
- [x] Cap the rolling decibel sample buffer at 500 entries in `AudioRecordingService.updateLevels()`.
