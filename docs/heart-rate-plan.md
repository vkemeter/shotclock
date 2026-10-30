# Plan: Pulsmessung mit Workout-Sitzung (Version 1.1)

Status: **Plan vollständig, nicht umgesetzt.** Die App stellt von `WKExtendedRuntimeSession`
(`physical-therapy`) auf `HKWorkoutSession` um. Der Puls wird während des Trainings
aufgezeichnet und mit dem Training in Apple Health gespeichert.

## Entscheidungen

| Datum | Entscheidung |
|---|---|
| 2026-10-30 | **Immer Workout.** Jede Nutzung der Shotclock läuft als Workout-Sitzung; kein separater Modus „nur Uhr“. |
| 2026-10-30 | **Verlauf nur in Health.** Keine eigene Auswertung, keine Zusammenfassung, kein Verlauf in der App. Den Pulsverlauf zeigen Health bzw. Fitness. |
| 2026-10-30 | **Keine Live-Anzeige des Pulses** (Platz auf der Uhr). Der Puls wird nur aufgezeichnet. |
| 2026-10-30 | **Verweigerte Health-Freigabe → Hinweis** statt Ausweichen auf `physical-therapy`. Der Modus `physical-therapy` fällt komplett weg. |
| 2026-10-30 | **Trainingsende: Knopf + Nachfrage + Automatik** (wie bei Lauf- und Wandertraining der Apple-Trainings-App), siehe [Trainingsende](#trainingsende). |

## Ziel

- Die Uhr läuft bei gesenktem Arm zuverlässig weiter, ohne 1-Stunden-Grenze und mit einem
  Hintergrundmodus, der zum Zweck passt (Sporttraining).
- Jedes Training erscheint in Apple Health mit Dauer und Pulsverlauf.
- An der Bedienung der Uhr ändert sich so wenig wie möglich.

## Vergleich

| | `physical-therapy` (heute) | `HKWorkoutSession` (1.1) |
|---|---|---|
| Läuft bei gesenktem Arm | ja | ja |
| Zeitlimit | 1 h pro Sitzung | keins |
| Passt zum Zweck (Richtlinie 2.5.4) | Grauzone | Sporttraining – gut begründbar |
| Puls in Health | nein | ja |
| Action-Taste › Training | nein | möglich (`StartWorkoutIntent`) |
| Nachteile | – | Health-Freigabe nötig, Pulssensor kostet Akku, Trainingssymbol auf der Uhr, Datenschutzerklärung muss Health nennen |

## Technische Grundlage (HealthKit)

- **Capability** HealthKit → Entitlement `com.apple.developer.healthkit`. Eine Freigabe
  durch Apple ist dafür nicht nötig; geprüft wird im normalen App Review.
- **Info.plist:**
  - `NSHealthUpdateUsageDescription` – Trainings in Health speichern
  - `NSHealthShareUsageDescription` – Puls lesen
  - beide lokalisiert (Englisch/Deutsch) über `InfoPlist.xcstrings`
- **Hintergrundmodus:** `workout-processing` ersetzt `physical-therapy`.
- **Freigabe:** `HKHealthStore.requestAuthorization(toShare: [workoutType], read: [heartRate])`
  beim ersten Start.
- **Sitzung:** `HKWorkoutSession` + `associatedWorkoutBuilder()` mit
  `HKLiveWorkoutDataSource`. Die Datenquelle sammelt den Puls automatisch; die App liest
  ihn nicht aus und zeigt ihn nicht an.
- **Trainingsart:** HealthKit kennt kein Billard → `.other`. Ob sich über Metadaten (z. B.
  `HKMetadataKeyWorkoutBrandName`) ein Name wie „Billard-Training“ in Fitness anzeigen
  lässt, wird bei der Umsetzung geprüft.
- **Ende:** `session.end()` → `builder.endCollection(at:)` → `builder.finishWorkout()`
  speichert das Training mit allen Pulswerten in Health.

## Health-Freigabe

| Nutzer erlaubt | Verhalten |
|---|---|
| Training speichern + Puls lesen | Alles funktioniert. |
| Training speichern, Puls nicht | Workout läuft, Training wird ohne Puls gespeichert. Kein Hinweis nötig; HealthKit verrät der App aus Datenschutzgründen ohnehin nicht, ob das Lesen erlaubt wurde. |
| Training speichern abgelehnt | Keine Workout-Sitzung möglich. Die App zeigt statt der Uhr einen **Hinweis**: Shotclock braucht die Freigabe, damit die Uhr bei gesenktem Arm weiterläuft, und wo man sie erteilt (Einstellungen › Health auf der Uhr bzw. Health-App auf dem iPhone). Beim nächsten Öffnen prüft die App erneut. |

Status abfragen: `healthStore.authorizationStatus(for: .workoutType())` (`.sharingDenied`).

## Architektur

```
ShotClock (App)
  WorkoutSession        ersetzt RuntimeSession: HKWorkoutSession + HKLiveWorkoutBuilder,
                        Start, Ende, Speichern in Health
  HealthAccess          Freigabe anfragen, Status prüfen
  HealthAccessView      Hinweis bei verweigerter Freigabe
  ShotClockModel        steuert das Training statt der Runtime-Session
ShotClockCore
  TrainingIdleMonitor   Leerlauf, Nachfrage, automatisches Ende, Endzeitpunkt (testbar)
```

`ShotClockCore` bleibt frei von HealthKit. Die App hält Training und Uhr getrennt: Das
Training läuft über viele Stöße, die Uhr startet und stoppt pro Stoß.

## Phasen

1. **Projekt:** HealthKit-Capability, Usage-Texte (lokalisiert), Hintergrundmodus
   `workout-processing` statt `physical-therapy`
2. **Freigabe:** Anfrage beim ersten Start, `HealthAccessView` bei Ablehnung
3. **Trainingsende-Logik:** `TrainingIdleMonitor` in `ShotClockCore`, testgetrieben
4. **Workout-Sitzung:** `WorkoutSession` ersetzt `RuntimeSession`; Training beginnt mit
   dem ersten Start; Knopf „Training beenden“, Nachfrage-Dialog, Automatik; Speichern in
   Health
5. **Test auf der Uhr:** Töne und Vibration bei gesenktem Arm, Training mit Pulsverlauf in
   Health/Fitness, Nachfrage und Automatik, Akkuverbrauch über ein längeres Training,
   Verhalten bei Ablehnung
6. **Doku und Store:** `privacy.md` und `support.md` um Health ergänzen,
   `app-store-metadata.md` (Beschreibung, Prüfnotiz, App-Datenschutz), SPEC, README
7. **Optional später:** Action-Taste über `StartWorkoutIntent`; Stöße als
   `HKWorkoutEvent`-Segmente im Training

## Store-Regeln, die dabei gelten

- **5.1.3 Gesundheit:** Gesundheitsdaten nicht für Werbung oder Data-Mining nutzen, nicht
  an Dritte weitergeben, nicht in iCloud ablegen. Die Datenschutzerklärung muss HealthKit
  nennen.
- **App-Datenschutz-Angaben:** Bleiben die Daten auf dem Gerät bzw. in Health, gilt
  weiterhin „Keine Daten erfasst“ – vor der Einreichung noch einmal prüfen.
- **Keine medizinischen Aussagen** in App und Store-Texten.
- **Hinweis bei Ablehnung:** muss erklären, wozu die Freigabe dient, und darf den Nutzer
  nicht bedrängen.

## Trainingsende

Ein Training läuft über viele Stöße. Es beginnt mit dem ersten Start und endet auf einem
von drei Wegen:

1. **Knopf „Training beenden“** in den Einstellungen (die Hauptansicht bleibt unverändert).
2. **Nachfrage nach 10 Minuten ohne Start:** Die Uhr vibriert und fragt „Training
   beendet?“ mit **Beenden** und **Weiter**. „Weiter“ setzt die Wartezeit zurück.
3. **Automatik als Sicherheitsnetz:** Kommt 5 Minuten nach der Nachfrage keine Antwort
   (also 15 Minuten ohne Start), endet das Training von selbst.

Bei 2 und 3 wird das Training auf das **Ende des letzten Stoßes zurückdatiert**, damit die
Leerlaufzeit nicht als Trainingszeit in Health landet.

Läuft gerade ein Stoß, wird nicht nachgefragt. Die Zeiten (10 / 5 Minuten) sind
Startwerte und lassen sich nach dem Test am Tisch anpassen.

**Technik:** Während eines Workouts holt watchOS die App beim Anheben des Arms in den
Vordergrund. Die Nachfrage ist deshalb ein normaler Dialog in der App mit Vibration
(`WKInterfaceDevice.play(.notification)`) – es braucht **keine Mitteilungs-Freigabe**.
Die Zeitlogik (Leerlauf messen, Nachfrage fällig, Automatik fällig, Endzeitpunkt) ist reine
Rechnerei und kommt testgetrieben als `TrainingIdleMonitor` in `ShotClockCore`.
