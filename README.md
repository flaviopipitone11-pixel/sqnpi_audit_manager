# SQNPI Audit Manager 🌿

[![Flutter](https://img.shields.io/badge/Flutter-v3.29.0-blue.svg)](https://flutter.dev)
[![Riverpod](https://img.shields.io/badge/Riverpod-v2.6.1-red.svg)](https://riverpod.dev)
[![SQNPI](https://img.shields.io/badge/Compliance-SQNPI-green.svg)](https://www.reterurale.it/produzioneintegrata)

**SQNPI Audit Manager** è una soluzione professionale cross-platform (macOS & Mobile) progettata per la gestione completa dei processi di audit relativi allo standard **SQNPI** (Sistema di Qualità Nazionale Produzione Integrata).

L'applicazione permette agli ispettori di pianificare, eseguire e documentare le visite di controllo direttamente sul campo, anche in assenza di connessione internet.

## ✨ Funzionalità Principali

*   📅 **Gestione Visite**: Pianificazione e monitoraggio dello stato degli audit (Pianificata, In Corso, Completata, Sincronizzata).
*   🗺️ **Mappa Territoriale Interattiva**: Visualizzazione geolocalizzata delle aziende e delle visite, con supporto per cache offline delle mappe.
*   📋 **Checklist Dinamiche**: Gestione di checklist complesse basate sulle fasi colturali (Post-Raccolta, Bilancio di Massa, Tracciabilità).
*   📸 **Allegati & Annotazioni**: Cattura di foto e documenti con annotazioni grafiche integrate e compressione automatica.
*   📄 **Generazione PDF**: Creazione di report professionali (modello M904) pronti per la condivisione.
*   📊 **Dashboard Admin**: Statistiche avanzate e gestione anagrafica aziende con importazione dati da Excel.
*   📝 **Note Personali**: Sistema di appunti per l'ispettore con supporto a promemoria e pin.

## 🚀 Tecnologie Utilizzate

*   **Framework**: Flutter (Dart)
*   **State Management**: Riverpod (Provider, StreamProvider, FutureProvider)
*   **Database**: Drift (SQLite) per la persistenza locale ad alte prestazioni.
*   **Architettura**: Feature-first folder structure (Layered Architecture).
*   **Networking & Cache**: Dio con `dio_cache_interceptor` per l'efficienza dei dati.
*   **Map Engine**: Flutter Map con OpenStreetMap.
*   **Storage**: `http_cache_file_store` per la gestione permanente del filesystem.

## 🛠️ Requisiti & Setup

### Prerequisiti
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (Raccomandata v3.29+)
- Dart SDK 3.x+

### Installazione
1.  Clona il repository:
    ```bash
    git clone [url-del-repo]
    ```
2.  Installa le dipendenze:
    ```bash
    flutter pub get
    ```
3.  Genera il codice Drift (se modifichi lo schema database):
    ```bash
    flutter pub run build_runner build --delete-conflicting-outputs
    ```
4.  Avvia l'applicazione:
    ```bash
    flutter run
    ```

## 📈 Aggiornamenti Recenti (Aprile 2026)

Abbiamo recentemente completato un aggiornamento sistematico dello stack tecnologico:
- **FilePicker v11.0**: Migrazione completa alle nuove API statiche.
- **Dio Cache v4.0**: Nuovo sistema di gestione cache con supporto offline avanzato.
- **Flutter Map v8.2**: Motore cartogafico aggiornato per una maggiore fluidità.
- **FL Chart v1.2**: Dashboard statistiche ottimizzata.

---
*Sviluppato per la gestione professionale dell'Agricoltura Integrata.*
