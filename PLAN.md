# Set up the app’s Supabase connection

## Implementation Checklist
- [x] Install the Supabase Swift SDK via Swift Package Manager.
- [x] Add app config constants for the Supabase URL and publishable key.
- [x] Create a shared Supabase client service file.
- [x] Build the app and verify the integration compiles cleanly.

**Features**
- Connect the app to your Supabase project using the project URL you provided.
- Use your public publishable key in the app and keep the server secret out of the iPhone app.
- Add a single shared connection so future login, database, and storage features can all use the same setup.
- Add a small app settings layer so these values are read cleanly from the app’s public configuration.

**Design**
- No visual design changes.
- No layout, color, or interaction changes.
- This is an under-the-hood setup step to prepare the app for future connected features.

**Pages / Screens**
- No new screens.
- No changes to the current listening, results, or history experience.

**Connection Values To Use**
- Project URL: `https://cmtlwxpqgrslnknlmraf.supabase.co`
- App key: use the public publishable key you sent for the app connection.