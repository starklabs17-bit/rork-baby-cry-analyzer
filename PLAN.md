# Add account creation and password reset screens

**Features**
- [x] Add a sign-up screen where new users can enter their email, password, and password confirmation.
- [x] Show a clear message if the passwords do not match or are too short.
- [x] Let people create an account with one primary action button and return to sign in with a secondary text button.
- [x] Add a password reset screen where users can enter their email and request a reset link.
- [x] Show a confirmation message after a reset link is sent and return the user to sign in after they acknowledge it.
- [x] Reuse the existing account error messaging so sign-up and reset problems appear in native alerts.

**Design**
- [x] Match the existing dark, premium authentication style so the new screens feel consistent with sign in.
- [x] Use the same glassy input fields and full-width primary buttons for visual continuity.
- [x] Keep the layout simple and focused with clear titles, supporting text, and generous spacing.
- [x] Preserve native sheet behavior so the screens feel like polished iPhone account flows.

**Pages / Screens**
- [x] **Create Account**: Email, password, confirm password, a primary sign-up button, and a text button to return to sign in.
- [x] **Reset Password**: Email field, reset-link button, and a text button to go back to sign in.
- [x] **Alerts**: A native message for validation issues, account errors, and reset-link success.
