# Shotclock – Spezifikation

Eigenständige Apple-Watch-App (ohne iPhone-App), die dem Träger eine persönliche
Shotclock nach WPA-Regeln beim Pool-Billard bereitstellt.

## Zielgruppe & Kontext

- Genau **ein Nutzer**: der Spieler, der die Uhr trägt. Jeder Spieler ist für seine
  eigene Zeit verantwortlich – kein Schiedsrichter-Modus, keine zwei Spieler.
- **Kein Spielstand**, keine Rack-Zähler, keine Statistik.
- Zielgerät: **Apple Watch Ultra** (Action-Taste), läuft aber auf jeder Watch mit
  watchOS 26.
- Vorerst nur für den Eigengebrauch; spätere App-Store-Veröffentlichung möglich, daher
  keine Abkürzungen, die eine Review blockieren würden.

## Regeln (WPA)

| Regel | Wert |
|---|---|
| Zeit pro Stoß | 30 s |
| Verlängerung | 1× pro Rack, +30 s, nur während die Uhr läuft |
| Erster Stoß nach dem Break | +30 s Bonus (manuell aktiviert, gilt für den nächsten Start) |
| Warnung | **Vibration** bei 10 s Restzeit |
| Absolute Warnung | **Ton jede Sekunde** ab 5 s Restzeit (5, 4, 3, 2, 1) |
| Ablauf (0 s) | langes, deutliches Signal (Vibration + Ton), Anzeige „TIME“ |

Die Werte stehen zentral in `RuleSet.wpa`. Eigene Voreinstellungen sind vorerst nicht
vorgesehen.

## Bedienung

| Aktion | Wirkung |
|---|---|
| **Start / Neustart** | Startet einen neuen Countdown (30 s, ggf. +30 s Break-Bonus). Läuft die Uhr schon, startet sie neu (nächster Stoß). |
| **Stopp** | Aufnahme beendet, Uhr geht in den Ruhezustand. |
| **Verlängerung** | +30 s auf die laufende Zeit, sofern im Rack noch verfügbar. |
| **Neues Rack** | Verlängerung wird wieder verfügbar. |
| **Break-Bonus** | Der nächste Start bekommt +30 s, danach erlischt der Bonus automatisch. |

Eingabewege:

- **Tippen** auf die große Uhr → Start / Neustart
- **Doppeltippen** (Daumen + Zeigefinger) → Start / Neustart (`handGestureShortcut`)
- **Action-Taste (Ultra)** → in der App **konfigurierbar**: Start/Neustart *(Standard)*,
  Start/Stopp im Wechsel, Stopp oder Verlängerung
- Buttons für Stopp, Verlängerung, Neues Rack und Break-Bonus

## Anzeige

- Große Sekunden-Ziffern, Fortschrittsring: grün → gelb (≤ 10 s) → rot (≤ 5 s)
- Zeigt an, ob die Verlängerung im Rack noch verfügbar ist und ob der Break-Bonus aktiv ist
- Always-On-Display: Restzeit bleibt im gedimmten Modus lesbar

## Nicht-funktionale Anforderungen

- **Läuft weiter, wenn das Handgelenk unten ist.** Vibration und Töne kommen auch dann
  pünktlich. Das ist die wichtigste technische Anforderung.
- **Genauigkeit:** Die Restzeit wird immer aus dem Endzeitpunkt berechnet, nicht durch
  Herunterzählen. Abweichung < 0,1 s.
- **Töne trotz Stummmodus?** Muss am Gerät geprüft werden (siehe Risiken).
- Logik (`ShotClockCore`) ist reines Swift ohne UI und vollständig getestet.

## Architektur

```
ShotClockCore/          Swift-Paket: reine Logik, plattformunabhängig, getestet
  RuleSet               WPA-Zeiten
  ShotClock             Zustandsautomat (idle / running / paused / expired),
                        Verlängerung, Break-Bonus, Ereignisse (Warnung, Tick, Ablauf)
ShotClock (Watch-App)   folgt, sobald Xcode installiert ist
  ShotClockModel        @Observable, treibt ShotClock per Timer, löst Feedback aus
  FeedbackService       Vibration (WKInterfaceDevice) und Töne
  RuntimeService        hält die App im Hintergrund am Leben
  ActionButtonIntent    App Intent für die Action-Taste
  Views                 Uhr, Einstellungen
```

## Risiken / Spikes (nur auf echter Hardware prüfbar)

1. **Hintergrundbetrieb:** `HKWorkoutSession` (stabil, braucht HealthKit-Freigabe; ein
   Workout muss nicht gespeichert werden) oder `WKExtendedRuntimeSession` (max. ~1 h,
   Session-Typ muss zum Zweck passen). → Spike entscheidet.
2. **Action-Taste:** Drittanbieter-Apps erscheinen in der Action-Tasten-Auswahl nur über
   bestimmte Intents (z. B. `StartWorkoutIntent` bei Workout-Apps). Alternativ:
   App-Shortcut über die Option „Kurzbefehl“. → Spike entscheidet, wie das Drücken
   *in der laufenden App* die konfigurierte Aktion auslöst.
3. **Töne:** ob kurze Töne über den Watch-Lautsprecher bei aktivem Stummmodus bzw. im
   Hintergrund abgespielt werden.

## Phasen

1. ✅ Spezifikation
2. ✅ `ShotClockCore` testgetrieben (24 Tests; `swift test` braucht ohne Xcode
   `-Xswiftc -plugin-path -Xswiftc /Library/Developer/CommandLineTools/usr/lib/swift/host/plugins/testing`)
3. ⏳ Xcode installieren, Watch-App-Projekt anlegen (nur Watch, ohne iOS-Companion)
4. Spike Hintergrundbetrieb + Töne + Action-Taste auf der Ultra
5. Hauptansicht, Feedback, Doppeltippen, Always-On
6. Einstellungen (Belegung der Action-Taste), App-Icon, Barrierefreiheit
7. Test am Tisch → ggf. TestFlight / App Store
