# Install Glam Me Upp Studio on Your iPhone (Personal Use)

This app is **already an iPhone app** — not a Mac app. It uses SwiftUI and only runs on iPhone (iOS 17+).

Apple does **not** allow installing native iOS apps without signing them first. You do not need to be a developer, but you do need **one** of the paths below.

---

## Option 1 — Easiest for personal use (recommended)

**Apple Developer Program — $99/year**

1. Enroll at [developer.apple.com](https://developer.apple.com)
2. Use a Mac (yours, a friend's, or a library) **once** to open `GlamMeUppStudio.xcodeproj` in Xcode
3. Connect your iPhone with USB
4. Select your iPhone as the run target → click **Run**
5. On iPhone: **Settings → General → VPN & Device Management** → trust your developer profile

The app stays on your phone until you delete it. With a paid account, it lasts **1 year** before re-signing (not 7 days).

---

## Option 2 — Free (no $99 fee)

**Free Apple ID sideloading**

Same steps as Option 1, but sign in to Xcode with a normal Apple ID (no paid account).

- App works fully on your iPhone
- Certificate expires after **7 days** — you must reconnect to Mac and press Run again weekly
- Fine for personal use if you can access a Mac once a week

---

## Option 3 — No Mac at all

You still need **something** to compile the app (Apple requirement):

| Service | What it does |
|---------|----------------|
| [MacinCloud](https://www.macincloud.com) | Rent a Mac by the hour (~$1/hr) |
| [GitHub Actions](https://github.com) | Free macOS build runners (needs GitHub account + setup) |
| Friend with a Mac | 15–30 minutes to build and install |

After build, install via USB or **TestFlight** (requires paid developer account).

---

## Option 4 — If you can never use a Mac

Native Swift apps **cannot** be installed on iPhone without a Mac (or cloud Mac) at least once.

Alternatives if that is impossible:
- **Web app (PWA)** — open in Safari, Add to Home Screen (would need rebuilding the app as a website)
- **Expo / React Native** — cloud build services can produce an iPhone install file without owning a Mac

The current project is native Swift — best quality on iPhone, but requires one build step.

---

## What you need on iPhone

- iOS **17.0** or newer
- iPhone (not iPad-only; works on all iPhones)

## What gets imported automatically

On first launch, the app loads Nawal's career data from `career_seed.json`:
- 12 clients
- 49 appointments
- Income & expense records from *My Career.ods*

---

## Quick checklist

- [ ] Copy `GlamMeUppStudio` folder to a Mac (USB drive, cloud, etc.)
- [ ] Install Xcode from Mac App Store (free)
- [ ] Open `GlamMeUppStudio.xcodeproj`
- [ ] Plug in iPhone → trust computer on phone
- [ ] Xcode → select your iPhone → **Run** (▶)
- [ ] Trust developer on iPhone in Settings

After that, Nawal uses it like any normal app — clients, calendar, receipts, analytics — no Mac needed day to day.
