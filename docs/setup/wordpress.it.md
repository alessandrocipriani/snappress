# Collegare WordPress

SnapPress pubblica sul tuo sito tramite la **REST API** di WordPress, autenticandosi con una **Application Password**. Non serve installare plugin.

## Requisiti del sito

- **WordPress 5.6 o successivo** (le Application Passwords sono incluse nel core da questa versione).
- **HTTPS attivo.** Senza HTTPS WordPress disattiva le Application Passwords.
- **REST API raggiungibile.** Prova ad aprire `https://tuosito.it/wp-json/` nel browser: deve comparire un testo JSON. Se vedi un errore, controlla plugin di sicurezza, firewall o impostazioni dell'hosting.
- **Un utente con ruolo Autore, Editore o Amministratore.** Consigliato: crea un utente dedicato (es. `snappress`) con ruolo **Autore**, così l'app non usa l'account amministratore.

## 1. Crea l'Application Password

1. Accedi al pannello di WordPress con l'utente che userai.
2. Vai in **Utenti → Profilo**.
3. Scorri fino alla sezione **Password applicazione**.
4. Nel campo del nome scrivi `SnapPress` (o il nome del telefono) e premi **Aggiungi nuova password applicazione**.
5. **Copia subito la password** mostrata (formato `abcd efgh ijkl mnop qrst uvwx`): WordPress non la mostrerà più.

Ogni password si può revocare singolarmente dalla stessa pagina, ad esempio se perdi il telefono.

## 2. Inserisci i dati in SnapPress

In **Impostazioni → Connessioni → WordPress**:

| Campo | Cosa inserire |
|---|---|
| Indirizzo del sito | `https://tuosito.it` (senza `/wp-admin`) |
| Nome utente | Il nome utente di accesso (non l'etichetta della password) |
| Application Password | La password copiata, con o senza spazi |

Premi **Testa connessione**: SnapPress verifica le credenziali e i permessi dell'utente.

## Problemi comuni

| Sintomo | Causa probabile | Soluzione |
|---|---|---|
| Non vedo la sezione "Password applicazione" | Sito senza HTTPS, WordPress precedente alla 5.6, o funzione disattivata da un plugin | Attiva HTTPS, aggiorna WordPress, controlla le impostazioni del plugin di sicurezza (Wordfence, Solid Security, …) |
| Errore 401 "rest_not_logged_in" | Il server non inoltra l'intestazione `Authorization` | Su Apache aggiungi al `.htaccess`: `SetEnvIf Authorization "(.*)" HTTP_AUTHORIZATION=$1`, oppure chiedi all'hosting |
| Errore 401 "invalid_username" | Nome utente sbagliato | Usa il nome di accesso, non il nome visualizzato né l'email |
| Errore 403 "rest_cannot_create" | Ruolo dell'utente insufficiente | Assegna almeno il ruolo Autore |
| Errore 403 o pagina HTML del firewall | Firewall o hosting blocca `/wp-json/` | Autorizza `/wp-json/wp/v2/` nel plugin di sicurezza o nel pannello dell'hosting |
| Upload immagine rifiutato (413) | Immagine troppo grande per il server | SnapPress ridimensiona le immagini; in alternativa aumenta `upload_max_filesize` |

## Cosa fa SnapPress sul tuo sito

1. Carica l'immagine nella **Libreria media** (`POST /wp-json/wp/v2/media`) con il testo alternativo.
2. Crea l'articolo (`POST /wp-json/wp/v2/posts`) come bozza, pubblicato o programmato, con l'immagine in evidenza, categorie e tag scelti.

L'URL pubblico dell'immagine caricata viene poi usato anche per Instagram.
