# Shotclock

Persönliche Shotclock für Pool-Billard auf der Apple Watch – zum Training unter
Zeitdruck. Eigenständige watchOS-App ohne iPhone-App.

Im Turnier ist die Shotclock ein eigener Stressfaktor. Die App lässt dich jeden Stoß mit
der Uhr am Handgelenk spielen: Vibration bei 10 Sekunden, ein Ton pro Sekunde ab 5
Sekunden, langes Signal bei Ablauf – auch mit gesenktem Arm und ausgeschaltetem Display.
Die Standardwerte folgen den Regeln der World Pool-Billiard Association (WPA).

## Funktionen

- Tippen startet die Uhr bzw. den nächsten Stoß; Doppeltippen (Daumen + Zeigefinger)
  ebenso
- Verlängerung (1× pro Rack), Neues Rack, Break-Bonus (manueller Schalter für den
  nächsten Start)
- Einstellbar: Stoßzeit, Break-Bonus, Dauer und Anzahl der Verlängerungen, Vibration,
  Töne; „WPA-Standard“ setzt zurück
- Läuft im Hintergrund weiter (`WKExtendedRuntimeSession`)
- Always-On, VoiceOver, Dynamic Type, „Bewegung reduzieren“
- Sprachen: Englisch (Basis), Deutsch – folgt der Sprache der Uhr

Die vollständige fachliche Beschreibung steht in [SPEC.md](SPEC.md).

[Support](docs/support.md) · [Datenschutz](docs/privacy.md)

## Voraussetzungen

- Xcode 27.2 oder neuer (watchOS 27.2 SDK)
- Apple Watch mit watchOS 27.0 oder neuer
- Zum Installieren auf der Uhr: Apple-ID in Xcode, Entwicklermodus auf iPhone und Watch

## Projektaufbau

```
ShotClock.xcodeproj         Watch-App (Target ShotClock, nur watchOS)
ShotClock/                  App-Code (SwiftUI)
  ShotClockApp              Einstiegspunkt
  ShotClockModel            @Observable; treibt ShotClock in Echtzeit, löst Feedback aus,
                            speichert die Regeln
  ClockView                 Uhr, Bedienelemente, VoiceOver-Texte
  SettingsView              Einstellungen
  FeedbackService           Vibration (WatchKit) und erzeugte Töne (AVAudioEngine)
  RuntimeSession            WKExtendedRuntimeSession für den Hintergrundbetrieb
  Localizable.xcstrings     Übersetzungen
ShotClockCore/              Swift-Paket: reine Logik ohne UI, vollständig getestet
  RuleSet                   Zeitregeln (WPA-Standard)
  ShotClock                 Zustandsautomat, Verlängerung, Break-Bonus, Signale
  ShotClockCore.docc        DocC-Dokumentation
docs/
  app-store-metadata.md     Texte und Angaben für App Store Connect und TestFlight
  heart-rate-plan.md        Plan: Pulsmessung mit Workout-Sitzung
  support.md                Support-Seite (Support-URL im App Store)
  privacy.md                Datenschutzerklärung (Datenschutz-URL im App Store)
```

Die App ist bewusst in eine testbare Logik (`ShotClockCore`) und eine dünne
Watch-Schicht geteilt. Die Restzeit wird immer aus einem Endzeitpunkt berechnet, nie
heruntergezählt – siehe DocC-Artikel „Timing Model“.

## Bauen und testen

```sh
# Logik-Tests (macOS, ohne Simulator)
cd ShotClockCore && swift test

# App für den Simulator bauen
xcodebuild -project ShotClock.xcodeproj -scheme ShotClock \
  -destination 'generic/platform=watchOS Simulator' build
```

Im Simulator startet das Debug-Argument `-autostart` die Uhr sofort. Eine Sprache lässt
sich mit `-AppleLanguages "(de)"` erzwingen.

## Auf der eigenen Uhr installieren

```sh
xcodebuild -project ShotClock.xcodeproj -scheme ShotClock \
  -destination 'id=<WATCH-UDID>' -derivedDataPath build/device \
  -allowProvisioningUpdates build

xcrun devicectl device install app --device <WATCH-UDID> \
  build/device/Build/Products/Debug-watchos/ShotClock.app
xcrun devicectl device process launch --device <WATCH-UDID> de.vkemeter.shotclock.watchkitapp
```

Die UDID der Uhr liefert `xcrun devicectl list devices`. Das Team (`DEVELOPMENT_TEAM`)
ist im Projekt gesetzt.

## Code-Stil

Formatierung und Lint-Regeln kommen von Apples `swift-format` (liegt Xcode bei),
konfiguriert in `.swift-format` (4 Leerzeichen, 120 Zeichen pro Zeile). Ein Pre-Commit-Hook
prüft die gestagten Swift-Dateien und bricht den Commit bei Verstößen ab.

```sh
git config core.hooksPath .githooks              # einmal pro Klon, aktiviert den Hook
xcrun swift-format format -r -i ShotClock ShotClockCore   # alles formatieren
xcrun swift-format lint -r --strict ShotClock ShotClockCore
```

Im Notfall überspringt `git commit --no-verify` den Hook.

## Dokumentation

Die Entwicklerdokumentation von `ShotClockCore` ist mit DocC geschrieben (Kommentare im
Code plus Katalog `ShotClockCore.docc`).

- In Xcode: *Product › Build Documentation*, dann im Developer-Documentation-Fenster
- Kommandozeile:

  ```sh
  cd ShotClockCore
  xcodebuild docbuild -scheme ShotClockCore -destination 'generic/platform=watchOS' \
    -derivedDataPath ../build/docs
  open ../build/docs/Build/Products/Debug-watchos/ShotClockCore.doccarchive
  ```

## Lokalisierung

Alle Texte stehen in `ShotClock/Localizable.xcstrings` (Basissprache Englisch). Neue
Texte im Code als englische Literale schreiben (`Text("Shot time")`,
`String(localized: "…")`); Xcode übernimmt sie beim Bauen in den Katalog, dort die
Übersetzung ergänzen. Weitere Sprachen: im Katalog über „+“ hinzufügen.

## Veröffentlichung

TestFlight und App Store: Texte, Pflichtangaben und Prüfnotizen stehen in
[docs/app-store-metadata.md](docs/app-store-metadata.md). Ablauf: *Product › Archive*
(Ziel „Any watchOS Device“) → im Organizer zu App Store Connect hochladen → Build in
TestFlight freigeben.

Der App Store nimmt Watch-Apps nur in einer iOS-Hülle an. Deshalb gibt es neben der
Watch-App (`ShotClock`, `de.vkemeter.shotclock.watchkitapp`) das Target
`ShotClockContainer` (`de.vkemeter.shotclock`, ohne Code), das die Watch-App einbettet.
Das Schema baut die Hülle nur beim Archivieren; Ausführen und Testen betreffen nur die
Watch-App. Version und Build-Nummer stehen auf Projektebene und gelten für beide.
