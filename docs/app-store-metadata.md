# App Store & TestFlight – Texte und Angaben

Alle Felder, die App Store Connect für eine watchOS-App verlangt, mit Entwürfen in
Deutsch (Hauptsprache) und Englisch. Zeichenlimits stehen in Klammern; alle Entwürfe
halten sie ein.

## Allgemeine Angaben

| Feld | Wert |
|---|---|
| Bundle-ID | `de.vkemeter.shotclock` (Hülle; die Watch-App selbst ist `de.vkemeter.shotclock.watchkitapp`) |
| SKU | `shotclock-watch` |
| Plattform | watchOS (eigenständige Watch-App, keine iPhone-App) |
| Primäre Kategorie | Sport |
| Sekundäre Kategorie | Gesundheit & Fitness |
| Altersfreigabe | 4+ (keine der abgefragten Inhalte) |
| Preis | kostenlos |
| Copyright | © 2026 Volker Kemeter |
| Verschlüsselung | keine (`ITSAppUsesNonExemptEncryption = NO` ist gesetzt) |
| Support-URL | `https://github.com/vkemeter/shotclock/blob/main/docs/support.md` ([support.md](support.md)) |
| Datenschutz-URL | `https://github.com/vkemeter/shotclock/blob/main/docs/privacy.md` ([privacy.md](privacy.md)) |

### App-Datenschutz („Privacy Nutrition Label“)

**Keine Daten erfasst** („Data Not Collected“). Die App hat keinen Server, kein Tracking,
keine Analyse-SDKs; die Einstellungen liegen nur lokal auf der Uhr.

> Kommt später die Pulsmessung (siehe `heart-rate-plan.md`), bleibt es bei „Keine Daten
> erfasst“, solange Gesundheitsdaten die Uhr bzw. Apple Health nicht verlassen. Die
> Datenschutzerklärung muss dann aber HealthKit erwähnen.

---

## Deutsch

**Name** (30)
```
Shotclock – Billard-Training
```
> „Shotclock“ allein ist im Store sehr wahrscheinlich vergeben. App-Namen sind weltweit
> eindeutig; App Store Connect sagt beim Anlegen, ob der Name frei ist.

**Untertitel** (30)
```
Trainiere unter Zeitdruck
```

**Werbetext** (170, jederzeit ohne neue Version änderbar)
```
Im Turnier läuft die Uhr. Trainiere jeden Stoß unter echtem Zeitdruck – mit Vibration und Countdown-Tönen am Handgelenk, auch wenn der Arm unten ist.
```

**Beschreibung** (4000)
```
Im Turnier entscheidet nicht nur die Technik, sondern auch, wie du mit der Shotclock umgehst. Zeitdruck ist ein eigener Stressfaktor – und den kann man trainieren. Genau dafür ist Shotclock gemacht.

Die App macht deine Apple Watch zur persönlichen Shotclock für Pool-Billard. Du startest die Uhr mit einem Tipp, legst dich an den Tisch und konzentrierst dich auf den Stoß. Die Uhr meldet sich, wenn die Zeit knapp wird – spürbar und hörbar, auch wenn dein Arm unten ist und das Display aus.

SO TRAINIERST DU
• Tippen startet die Uhr, ein weiterer Tipp startet den nächsten Stoß.
• Vibration bei 10 Sekunden Restzeit.
• Ein Ton pro Sekunde ab 5 Sekunden.
• Langes Signal und „TIME“ bei Ablauf.

TURNIERREGELN
Die Standardwerte folgen den Shotclock-Regeln der World Pool-Billiard Association (WPA):
• 30 Sekunden pro Stoß
• eine Verlängerung um 30 Sekunden pro Rack
• 30 Sekunden Bonus für den ersten Stoß nach dem Break

ANPASSBAR
Stoßzeit, Break-Bonus, Dauer und Anzahl der Verlängerungen, Zeitpunkt der Vibration und Beginn der Töne lassen sich einstellen – für lockeres Aufwärmen genauso wie für härteres Training unter verschärftem Zeitdruck. Ein Tipp stellt die Turnierwerte wieder her.

FÜR DICH ALLEIN
Shotclock ist deine eigene Uhr: kein Schiedsrichter, kein Spielstand, keine Ablenkung. Große Ziffern und ein farbiger Ring (grün, gelb, rot) zeigen die Restzeit auf einen Blick, auch im Always-On-Modus.

BARRIEREFREI
VoiceOver sagt Restzeit, Verlängerung und Break-Bonus an. Die App unterstützt große Schrift und „Bewegung reduzieren“.

DATENSCHUTZ
Keine Konten, kein Tracking, keine Daten verlassen deine Uhr.

Shotclock läuft eigenständig auf der Apple Watch, ein iPhone wird während des Trainings nicht gebraucht.
```

**Schlüsselwörter** (100, durch Kommas getrennt, ohne Leerzeichen nach dem Komma; Wörter
aus Name und Untertitel werden automatisch berücksichtigt und sind deshalb nicht doppelt
aufgeführt)
```
Pool,Shot Clock,Stoßuhr,Turnier,Timer,Countdown,8-Ball,9-Ball,10-Ball,Queue,Snooker,Stoßzeit
```

**Neuerungen** (4000, für Version 1.0 nicht nötig; ab 1.1)

---

## English

**Name** (30)
```
Shotclock – Pool Training
```

**Subtitle** (30)
```
Train under time pressure
```

**Promotional text** (170)
```
In a tournament, the clock is running. Train every shot under real time pressure – with haptics and countdown tones on your wrist, even with your arm down.
```

**Description** (4000)
```
In a tournament, technique is only half the game – the other half is handling the shot clock. Time pressure is a stress factor of its own, and it can be trained. That is what Shotclock is for.

Shotclock turns your Apple Watch into a personal shot clock for pool. Start it with a tap, get down on the shot and focus. The watch lets you know when time is running out – you feel it and hear it, even with your arm down and the display off.

HOW YOU TRAIN
• Tap to start the clock, tap again to start the next shot.
• Haptic warning at 10 seconds remaining.
• A tone every second from 5 seconds.
• A long signal and "TIME" when the clock runs out.

TOURNAMENT RULES
The defaults follow the shot clock rules of the World Pool-Billiard Association (WPA):
• 30 seconds per shot
• one 30-second extension per rack
• 30 extra seconds for the first shot after the break

ADJUSTABLE
Shot time, break bonus, length and number of extensions, the warning and the start of the countdown tones can all be changed – for a relaxed warm-up or for tougher drills under tighter time pressure. One tap restores the tournament values.

JUST FOR YOU
Shotclock is your own clock: no referee, no score, no distractions. Large digits and a colored ring (green, yellow, red) show the remaining time at a glance, including in Always On.

ACCESSIBLE
VoiceOver announces the remaining time, the extension and the break bonus. Shotclock supports larger text and Reduce Motion.

PRIVACY
No accounts, no tracking, no data leaves your watch.

Shotclock runs independently on Apple Watch; you don't need your iPhone while you train.
```

**Keywords** (100)
```
billiards,shot clock,cue,tournament,timer,countdown,8-ball,9-ball,10-ball,snooker,practice
```

---

## TestFlight

**Beta-App-Beschreibung** (4000, Pflicht für externe Tester)
```
Shotclock ist eine persönliche Shotclock für Pool-Billard auf der Apple Watch. Sie dient dazu, das Spielen unter Zeitdruck gezielt zu trainieren: 30 Sekunden pro Stoß, Vibration bei 10 Sekunden, Töne ab 5 Sekunden, eine Verlängerung pro Rack und Bonuszeit nach dem Break (WPA-Regeln, anpassbar).
```

**Was testen** (4000, pro Build)
```
• Uhr am Tisch benutzen: Kommen Vibration und Töne pünktlich, auch mit gesenktem Arm?
• Sind die Töne laut genug in deiner Umgebung?
• Verlängerung, Neues Rack und Break-Bonus: Ist die Bedienung während des Spiels verständlich?
• Einstellungen: Fehlt dir eine Einstellung?
Feedback bitte über TestFlight (Screenshot auf der Uhr oder in der TestFlight-App auf dem iPhone).
```

**Feedback-E-Mail:** tresen-grau-2o@icloud.com

**Hinweise für die Prüfung** (App Review Information › Notes; auch für die Beta-Prüfung)
```
Shotclock is a personal shot clock for pool players to practice under time pressure. No login is required.

How to test: tap the large clock to start a 30-second countdown. You get a haptic at 10 seconds, a tone every second from 5 seconds and a long signal at 0. The "+" button adds one extension per rack, the bolt button adds bonus time to the next start, the gear opens the settings.

Background execution: the app uses a WKExtendedRuntimeSession (physical-therapy) only while a countdown is running, so that the haptic and audio cues still arrive on time when the player lowers the wrist to take the shot. The session ends when the clock is stopped or expires.
```

**Kontakt für die Prüfung:** Name, Telefonnummer, E-Mail (Pflicht, wird in App Store Connect eingetragen).

---

## Datenschutzerklärung

Steht in [privacy.md](privacy.md) (Deutsch und Englisch) und ist über die
Datenschutz-URL oben öffentlich erreichbar, sobald sie auf `main` gepusht ist.

---

## Screenshots

Pflicht: mindestens eine Watch-Displaygröße. Der Ultra-Simulator liefert 422 × 514 px
(`xcrun simctl io <UDID> screenshot`). Vor dem Upload in App Store Connect prüfen, welche
Größen dort aktuell angeboten werden. Vorschlag für 3–5 Bilder:

1. Uhr läuft, grüner Ring (Startbildschirm des Trainings)
2. Gelb bei ≤ 10 s
3. Rot bei ≤ 5 s
4. „TIME“
5. Einstellungen
