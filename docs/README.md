# E46 Speeduino PWA - Web Bluetooth Dashboard

Progressive Web App do monitorowania silnika przez Bluetooth Low Energy.

## Jak używać

### Windows / Mac / Linux (Chrome/Edge/Opera)
1. Otwórz: https://krided.github.io/ESP32-SENDER/
2. Kliknij **"Connect to E46 Speeduino"**
3. Wybierz urządzenie BLE z listy
4. Widzisz dane live (10 Hz)

### iPhone (Safari NIE działa, potrzebujesz Bluefy)
1. Pobierz **Bluefy Browser** z App Store (~39 zł)
2. Otwórz w Bluefy: https://krided.github.io/ESP32-SENDER/
3. Kliknij Connect → wybierz ESP32
4. Opcjonalnie: Dodaj do ekranu głównego (wygląda jak apka)

### Android (Chrome natywnie)
1. Otwórz Chrome: https://krided.github.io/ESP32-SENDER/
2. Connect → działa bez problemu
3. Dodaj do ekranu głównego dla pełnego ekranu

## Funkcje PWA

- ✅ Identyczny design jak poprzednia strona (gradient, wskaźniki)
- ✅ Alerty pulsują przy przekroczeniu progów
- ✅ Konwersja MAP/Boost kPa → bar
- ✅ Działa offline po pierwszym załadowaniu
- ✅ Można dodać do ekranu głównego (jak native app)
- ✅ Auto-reconnect po utracie połączenia

## Wymagania ESP32

- BLE Server z nazwą: **"E46 Speeduino"**
- Service UUID: `4fafc201-1fb5-459e-8fcc-c5c9c331914b`
- Characteristic UUID: `beb5483e-36e1-4688-b7f5-ea07361b26a8`
- Notifications enabled, wysyłane JSON z danymi silnika

## Lokalne testowanie

Otwórz plik `index.html` w Chrome/Edge z flagą:
```
chrome://flags/#enable-experimental-web-platform-features
```
Lub uruchom lokalny serwer HTTPS (Web Bluetooth wymaga HTTPS):
```
npx http-server -S -p 8080
```

## Troubleshooting

**"Web Bluetooth not supported"**
- Użyj Chrome/Edge/Opera (nie Safari, nie Firefox)
- iPhone: tylko Bluefy Browser

**"No devices found"**
- Sprawdź czy ESP32 nadaje (Serial Monitor: "BLE server started")
- Bluetooth włączony na komputerze/telefonie
- Zasięg ~10m, bądź blisko

**"Connection failed"**
- Restart ESP32
- Wyczyść cache przeglądarki
- Sprawdź UUIDs w kodzie ESP32

## Deploy na GitHub Pages

Już skonfigurowane! Push do `main` → GitHub automatycznie publikuje z folderu `docs/`.
