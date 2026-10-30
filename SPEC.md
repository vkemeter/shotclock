# Shotclock – Spezifikation

Eigenständige Apple-Watch-App (ohne iPhone-App), die dem Träger eine persönliche
Shotclock nach WPA-Regeln beim Pool-Billard bereitstellt.

## Zielgruppe & Kontext

- Genau **ein Nutzer**: der Spieler, der die Uhr trägt. Jeder Spieler ist für seine
  eigene Zeit verantwortlich – kein Schiedsrichter-Modus, keine zwei Spieler.
- **Kein Spielstand**, keine Rack-Zähler, keine Statistik.
- Zielgerät: **Apple Watch Ultra**, läuft aber auf jeder Watch mit
  watchOS 27.
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

Die Standardwerte stehen zentral in `RuleSet.wpa`. In den **Einstellungen** lassen sich
Stoßzeit, Break-Bonus, Dauer und Anzahl der Verlängerungen pro Rack, Vibrationszeitpunkt
und Töne-Countdown anpassen (gespeichert, gelten ab dem nächsten Start); „WPA-Standard“
setzt zurück.

## Bedienung

| Aktion | Wirkung |
|---|---|
| **Start / Neustart** | Startet einen neuen Countdown (30 s, ggf. +30 s Break-Bonus). Läuft die Uhr schon, startet sie neu (nächster Stoß). |
| **Stopp** | Aufnahme beendet, Uhr geht in den Ruhezustand. |
| **Verlängerung** | +30 s auf die laufende Zeit, sofern im Rack noch verfügbar. |
| **Neues Rack** | Verlängerung wird wieder verfügbar. |
| **Break-Bonus** | Manueller Schalter: Der nächste Start bekommt +30 s, danach erlischt der Bonus automatisch. |

Eingabewege:

- **Tippen** auf die große Uhr → Start / Neustart
- **Doppeltippen** (Daumen + Zeigefinger) → Start / Neustart (`handGestureShortcut`)
- Buttons für Stopp, Einstellungen, Verlängerung, Neues Rack und Break-Bonus

## Anzeige

- Große Sekunden-Ziffern, Fortschrittsring: grün → gelb (≤ 10 s) → rot (≤ 5 s)
- Zeigt an, ob die Verlängerung im Rack noch verfügbar ist und ob der Break-Bonus aktiv ist
- Always-On-Display: Restzeit bleibt im gedimmten Modus lesbar
- VoiceOver: Die Uhr liest Restzeit, Verlängerungs- und Break-Bonus-Status vor; der
  Break-Bonus-Schalter meldet „an“/„aus“

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
ShotClock/              Watch-App (ShotClock.xcodeproj)
  ShotClockModel        @Observable, treibt ShotClock per Update-Schleife, löst Feedback aus
  FeedbackService       Vibration (WKInterfaceDevice) und erzeugte Töne (AVAudioPlayer)
  RuntimeSession        hält die App im Hintergrund am Leben
  ClockView             Uhr, Stopp, Verlängerung, Neues Rack, Break-Bonus
  SettingsView          anpassbare Regeln
```

## Risiken / Spikes (nur auf echter Hardware prüfbar)

1. **Hintergrundbetrieb:** `HKWorkoutSession` (stabil, braucht HealthKit-Freigabe; ein
   Workout muss nicht gespeichert werden) oder `WKExtendedRuntimeSession` (max. ~1 h,
   Session-Typ muss zum Zweck passen). → ✅ `WKExtendedRuntimeSession` reicht.
2. **Action-Taste:** Drittanbieter-Apps erscheinen in der Action-Tasten-Auswahl nur über
   bestimmte Intents (z. B. `StartWorkoutIntent` bei Workout-Apps). Alternativ:
   App-Shortcut über die Option „Kurzbefehl“. → ✗ `StartWorkoutIntent` allein reicht
   nicht, die App erscheint nicht in der Auswahl. Verworfen (kein Must-have).
3. **Töne:** ob kurze Töne über den Watch-Lautsprecher bei aktivem Stummmodus bzw. im
   Hintergrund abgespielt werden. → ✅ hörbar, auch im Stummmodus.

## Phasen

1. ✅ Spezifikation
2. ✅ `ShotClockCore` testgetrieben (29 Tests)
3. ✅ Watch-App-Projekt (nur Watch, ohne iOS-Companion), Prototyp mit Uhr, Vibration,
   Tönen und `WKExtendedRuntimeSession`
4. ✅ Spike auf der Ultra: Hintergrundbetrieb (`WKExtendedRuntimeSession` reicht) + Töne
   (auch im Stummmodus hörbar)
5. ✅ Hauptansicht, Feedback, Always-On
6. ✅ Einstellungen, App-Icon, Barrierefreiheit (VoiceOver nennt Restzeit, Verlängerung und
   Break-Bonus; Dynamic Type; „Bewegung reduzieren“). Action-Taste verworfen: Die App
   erscheint ohne echtes Training nicht unter „Action-Taste › Training“; kein Must-have.
7. Test am Tisch → ggf. TestFlight / App Store
