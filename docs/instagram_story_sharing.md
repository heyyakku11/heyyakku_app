# Instagram Story sharing

Tapping **Instagram** on the "Your card is live" screen renders the Yakku card
to a 1080×1920 PNG and opens Instagram's Story composer with it as the
background. The poll link (`https://heyyakku-web.vercel.app/vote/{code}`) is
copied to the clipboard first. **No Link sticker is created automatically** —
the user adds one in Instagram and pastes the link.

## Flow

`created_poll_screen.dart` → `ShareCoordinator` → `InstagramShareAdapter`
(story) → `StoryImageService.render` → `InstagramStoryChannel` →
native `shareToStory` (MethodChannel `com.example.yakku/instagram_story`).

- Android: `MainActivity.kt` sends `com.instagram.share.ADD_TO_STORY` with a
  FileProvider `content://` URI (`${applicationId}.storyfileprovider`, see
  `res/xml/story_file_paths.xml`) and `FLAG_GRANT_READ_URI_PERMISSION`.
- iOS: `AppDelegate.swift` writes the PNG to the pasteboard as
  `com.instagram.sharedSticker.backgroundImage` (plus the link as plain text in
  the same item) and opens `instagram-stories://share?source_application=<id>`.
- Fallbacks: image render failure or a native error opens instagram.com as
  before; "not installed" shows a message. WhatsApp, Snapchat, Copy link and the
  Instagram inbox adapter are unchanged.

## Required configuration: Meta App ID

Instagram requires a Meta (Facebook) App ID as `source_application`. The code
currently ships with the placeholder `YOUR_META_APP_ID`, so **the feature is not
production-ready until you set a real ID.**

1. Create an app at <https://developers.facebook.com/apps> (type: Other /
   Consumer) and copy its **App ID**.
2. Pass it at build time — it is read in one place,
   `InstagramStoryConfig.metaAppId` (`lib/core/share/instagram_story_channel.dart`):

   ```
   flutter run --dart-define=META_APP_ID=1234567890
   flutter build apk --release --dart-define=META_APP_ID=1234567890
   flutter build ipa --release --dart-define=META_APP_ID=1234567890
   ```

3. In CI, add the same `--dart-define` to the release build commands.

A debug log (`META_APP_ID is not set`) is printed when the placeholder is used.

## Platform configuration added

- Android: `AndroidManifest.xml` — `<provider>` (FileProvider) and `<queries>`
  entries for `com.instagram.android` and the `ADD_TO_STORY` intent.
  `res/xml/story_file_paths.xml` exposes only `cache/yakku_story/`.
- iOS: `Info.plist` — `LSApplicationQueriesSchemes` → `instagram-stories`.
  No Facebook SDK is used, so no `FacebookAppID` plist key is needed.

## Manual device checklist (not yet run)

Android (API 33+) and iOS 17+, with and without Instagram installed:

- [ ] Tap Instagram: Story composer opens with the card as full-screen
      background (not the camera, not the feed).
- [ ] Clipboard contains the exact `…/vote/{code}` URL (paste into a text field).
- [ ] Add a Link sticker manually and paste the URL; it opens the poll.
- [ ] iOS: after sharing, pasting text yields the URL (pasteboard also holds the
      image); confirm the Story still opens with the image.
- [ ] Long question (200+ chars) and emoji: text fits, nothing clipped badly.
- [ ] Card font shows Pacifico "Yakku." (offscreen render uses the app fonts).
- [ ] Instagram not installed: friendly message, no crash.
- [ ] Back out of Instagram and share again; temp PNG is recreated each time.
- [ ] Release build with the real `META_APP_ID`; confirm no rejection.
- [ ] WhatsApp, Snapchat, Copy link still work.
