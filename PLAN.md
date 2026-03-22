# Improve recording safety and block silent analyses

**Features**
- [x] Automatically stop a recording after 5 minutes so it cannot run indefinitely.
- [x] Prevent very quiet recordings from being analyzed when no crying is detected.
- [x] Show a clear message asking the user to move closer and try again for silent captures.

**Design**
- [x] Keep the current recording experience unchanged during normal use.
- [x] Preserve the existing visual style and alerts so the fixes feel native to the app.
- [x] Make the silent-recording message simple, calm, and reassuring.

**Pages / Screens**
- [x] Listening screen: recording ends automatically at the maximum duration.
- [x] Listening screen: silent recordings are stopped early from analysis and show guidance instead of a result.
