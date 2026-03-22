# Harden analysis error logging

**Progress**
- [x] Replace print-based error logging with OSLog Logger
- [x] Mark HTTP response body logs as private
- [x] Verify the iOS app builds successfully after the logging changes

**Features**
- Keep analysis failures traceable for debugging without exposing sensitive response details.
- Hide server response content from device logs and crash reports on normal devices.
- Preserve retry and error tracking so failures can still be diagnosed safely.

**Design**
- No visual changes to the app.
- This is a behind-the-scenes privacy and security improvement.

**Pages / Screens**
- Listening screen: no visible changes.
- History screen: no visible changes.
- Analysis flow: same behavior for the user, with safer internal error recording.