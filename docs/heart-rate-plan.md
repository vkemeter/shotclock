# Plan: Pulsmessung mit Workout-Sitzung

Status: **Entwurf, nicht umgesetzt.** Grundlage für die Entscheidung, ob und wie die App
von `WKExtendedRuntimeSession` (`physical-therapy`) auf `HKWorkoutSession` umgestellt wird.

## Ziel

Beim Shotclock-Training soll sichtbar werden, wie der Körper auf Zeitdruck reagiert. Der
Puls wird während des Trainings gemessen, live angezeigt und **dauerhaft gespeichert**:
als Training in Apple Health (sichtbar in der Fitness-App auf dem iPhone) und mit
Auswertungen pro Stoß in der App.

## Warum das gleichzeitig das Hintergrund-Problem löst

| | `physical-therapy` (heute) | `HKWorkoutSession` (Plan) |
|---|---|---|
| Läuft bei gesenktem Arm | ja | ja |
| Zeitlimit | 1 h pro Sitzung | keins |
| Passt zum Zweck (Richtlinie 2.5.4) | Grauzone | Sporttraining – gut begründbar |
| Puls | nein | ja, live über `HKLiveWorkoutBuilder` |
| Action-Taste › Training | nein | möglich (`StartWorkoutIntent`) |
| Nachteile | – | HealthKit-Freigabe, Pulssensor kostet Akku, Trainingssymbol in der Uhr, Datenschutzerklärung muss HealthKit nennen |

## Technische Grundlage (HealthKit)

- **Capability** HealthKit → Entitlement `com.apple.developer.healthkit`
- **Info.plist:** `NSHealthShareUsageDescription` (Puls lesen),
  `NSHealthUpdateUsageDescription` (Training speichern); beide lokalisiert über
  `InfoPlist.xcstrings`
- **Hintergrundmodus:** `workout-processing` statt `physical-therapy`
- **Freigabe:** `HKHealthStore.requestAuthorization(toShare: [workoutType], read: [heartRate])`
- **Sitzung:** `HKWorkoutSession` + `associatedWorkoutBuilder()` mit
  `HKLiveWorkoutDataSource`; Puls kommt über
  `workoutBuilder(_:didCollectDataOf:)` → `statistics(for: .heartRate)`
- **Trainingsart:** HealthKit kennt kein Billard. `.other` ist die ehrliche Wahl; der
  Name „Billard-Training“ lässt sich über `HKMetadataKeyWorkoutBrandName` mitgeben (vor
  der Umsetzung prüfen, wie Fitness das anzeigt).
- **Stöße im Training:** jeder Stoß wird als `HKWorkoutEvent` vom Typ `.segment` mit
  `DateInterval` (Start → Ende) und Metadaten (Verlängerung genutzt, abgelaufen) an den
  Builder gehängt. Health kennt damit die Stoßgrenzen; der Pulsverlauf lässt sich später
  jedem Stoß zuordnen.
- **Ende:** `session.end()` → `builder.endCollection(at:)` → `builder.finishWorkout()`
  speichert das Training in Health.

## Ablauf in der App (Vorschlag)

Heute gibt es keine „Sitzung“: Die Uhr läuft pro Stoß. Ein Workout braucht dagegen einen
klaren Anfang und ein Ende. Vorschlag nach dem Muster der Apple-Trainings-App:

1. **Startbildschirm:** „Training starten“ (zusätzlich zur heutigen Shotclock ohne
   Aufzeichnung, siehe offene Fragen).
2. **Während des Trainings:** die bekannte Uhr, zusätzlich klein der aktuelle Puls
   (♥ 112) und die Trainingsdauer. Nach links wischen: Seite mit „Beenden“.
3. **Nach dem Training:** Zusammenfassung – Dauer, Stöße, abgelaufene Stöße, Ø-/Max-Puls,
   Puls in den letzten 5 Sekunden vor dem Stoß im Vergleich zum Ruhepuls zwischen den
   Stößen.
4. **Verlauf:** Liste früherer Trainings auf der Uhr (lokal, SwiftData); die
   vollständigen Pulsdaten liegen in Health.

## Auswertung, die für Billard-Spieler interessant ist

- Ø-Puls pro Stoß und Pulsanstieg vom Start bis zum Stoß
- Puls in der Warnphase (≤ 10 s) und in der Countdown-Phase (≤ 5 s)
- Abgelaufene Stöße und genutzte Verlängerungen im Verhältnis zum Puls
- Entwicklung über mehrere Trainings: Wird der Pulsanstieg unter Zeitdruck kleiner?

Die Auswertung ist reine Rechnerei über Zeitstempel und Pulswerte und gehört deshalb in
`ShotClockCore` (testbar ohne Uhr). HealthKit bleibt in der App-Schicht hinter einem
Protokoll, damit die Logik mit erfundenen Pulsreihen getestet werden kann.

## Architektur

```
ShotClockCore
  ShotRecord        Start, Ende, Ergebnis (gestoppt/abgelaufen), Verlängerung genutzt
  TrainingLog       sammelt ShotRecords einer Sitzung
  HeartRateStats    ordnet Pulswerte Stößen und Phasen zu, berechnet Kennzahlen
ShotClock (App)
  WorkoutSession    ersetzt RuntimeSession: HKWorkoutSession + HKLiveWorkoutBuilder
  HealthAuthorization  Freigabe anfragen, Ablehnung behandeln
  TrainingSummaryView, HistoryView
```

## Phasen

1. **Core:** `ShotRecord`, `TrainingLog`, `HeartRateStats` testgetrieben
2. **Workout-Sitzung:** `WorkoutSession` statt `RuntimeSession`, Freigabe, Hintergrundmodus
   `workout-processing`; auf der Uhr prüfen, dass Töne/Vibration weiter pünktlich kommen
3. **Live-Puls** in der Uhr anzeigen
4. **Stöße als Segmente** an das Workout hängen, Training in Health speichern
5. **Zusammenfassung** nach dem Training
6. **Verlauf** auf der Uhr (SwiftData)
7. **Store:** Datenschutzerklärung um HealthKit ergänzen, Prüfnotiz anpassen,
   App-Datenschutz-Angaben prüfen; optional Action-Taste über `StartWorkoutIntent`

## Store-Regeln, die dabei gelten

- **5.1.3 Gesundheit:** Gesundheitsdaten nicht für Werbung oder Data-Mining nutzen, nicht
  an Dritte weitergeben, keine Gesundheitsdaten in iCloud ablegen. Die App braucht eine
  Datenschutzerklärung, die HealthKit nennt.
- **Keine medizinischen Aussagen:** keine „Stressmessung“ oder Diagnose versprechen;
  „Puls während des Trainings“ ist unproblematisch.
- **Ablehnung der Freigabe:** Die App muss weiter funktionieren (Shotclock ohne Puls).

## Offene Fragen an dich

1. **Immer mit Workout oder wählbar?** Variante A: Jede Nutzung ist ein Training. Variante B:
   „Training“ (mit Puls, gespeichert) und „Spiel“ (nur Uhr). Bei B braucht „Spiel“
   weiterhin einen Hintergrundmodus – entweder ebenfalls ein Workout ohne Speichern oder
   weiter `physical-therapy` (dann bleibt die Grauzone).
2. **Was passiert bei verweigerter Health-Freigabe?** Ohne Freigabe für `workoutType`
   startet keine Workout-Sitzung. Fallback wäre `physical-therapy` (beide Modi lassen sich
   deklarieren) oder ein Hinweis, die Freigabe zu erteilen.
3. **Verlauf auf der Uhr oder nur Health?** Health/Fitness zeigt Puls und Dauer, aber
   keine Stoß-Auswertung. Eine eigene Auswertung braucht den Verlauf in der App – oder
   später eine iPhone-App mit mehr Platz.
4. **Welche Kennzahlen sind dir als Spieler am wichtigsten?** (siehe Liste oben)
