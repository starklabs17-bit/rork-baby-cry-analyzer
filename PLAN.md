# Fix occasional analysis tip crash

**Features**
- [x] Prevent the analysis result from crashing when the response only contains one sentence.
- [x] Always fall back to a safe comforting tip when the returned text is too short or empty.

**Design**
- No visual changes.
- The result experience stays the same, but becomes more reliable.

**Pages / Screens**
- [x] Listening and analysis flow: keeps working normally after a result is returned.
- [x] Results card: continues showing a helpful tip without unexpected failures.
