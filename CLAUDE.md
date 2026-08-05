# CLAUDE.md — L'Ultimo Boccale

Questo file è il contratto tra noi (Kris e Michele) e te (Claude Code).
Leggilo interamente prima di scrivere qualsiasi riga di codice.
Se una richiesta futura contraddice questo file, fermati e segnalalo invece di improvvisare.

---

## 1. Cos'è il gioco

Gestionale/simulatore in prima persona a tema fiabesco. Il giocatore gestisce una taverna
frequentata da orchi, fate, streghe e maghi. Cucina, serve, gestisce le relazioni con i
clienti e decide se restare aperto di notte (più soldi, più pericolo).

Riferimenti: Supermarket Simulator per il loop e la UI, estetica PS1/PS2.

**Cosa NON è**: non è un gioco fisico caotico stile R.E.P.O./Lethal Company. Gli oggetti
si prendono, restano equipaggiati, si posano. Niente oggetti trascinati con la fisica.

---

## 2. Vincoli tecnici non negoziabili

- **Godot 4.x**, GDScript. Prima di iniziare, verifica la versione esatta del progetto e
  usa solo API di quella versione. Non usare mai API di Godot 3.
- **Niente mani visibili.** L'oggetto equipaggiato fluttua davanti alla camera.
- L'oggetto in mano ha `freeze = true` e collisione disabilitata; al drop viene
  riattaccato al mondo e riattivato.
- Nessuna dipendenza esterna, nessun plugin, senza chiedere prima.
- Target performance: deve girare fluido su hardware modesto. È parte dell'estetica.

---

## 3. Architettura obbligatoria

Queste quattro regole valgono da subito, anche quando sembrano sovradimensionate per il
milestone corrente. Servono a non riscrivere tutto tra tre mesi.

### 3.1 EventBus
Un autoload `EventBus.gd` che contiene **solo segnali, zero logica e zero stato**.
I sistemi comunicano solo attraverso di lui, non si referenziano mai direttamente.

Segnali iniziali (aggiungine solo quando servono davvero):
```gdscript
signal item_picked_up(item: Node3D)
signal item_dropped(item: Node3D)
signal item_placed(item: Node3D, slot: Node3D)
signal npc_entered(npc: Node3D)
signal npc_ordered(npc: Node3D, item_id: StringName)
signal npc_served(npc: Node3D, item_id: StringName, correct: bool)
signal npc_left(npc: Node3D, satisfied: bool)
signal npc_patience_stage_changed(npc: Node3D, stage: int)
```

### 3.2 Tutto il contenuto è una Resource
Nessun dato di gioco hardcodato negli script. Ogni item, ogni razza, ogni ricetta è un
file `.tres`. Aggiungere una razza deve significare creare un file, non modificare codice.

```gdscript
# data/item_data.gd
class_name ItemData extends Resource
@export var id: StringName
@export var display_name: String
@export var scene: PackedScene
@export var base_price: int

# data/race_data.gd
class_name RaceData extends Resource
@export var id: StringName
@export var display_name: String
@export var move_speed: float = 2.5
@export var patience_seconds: float = 60.0
@export var attention_sounds: Array[AudioStream]   # uno per stage: 0, 1, 2
@export var disliked_races: Array[StringName]
```

### 3.3 Identità persistente degli NPC
Ogni NPC ha, **fin da M2**, un `id: StringName` univoco e un `memory: Dictionary` vuoto.
Non servono ancora, ma è lì che finiranno posto preferito, affinità e rancori.
Non rimuoverli perché "non usati".

### 3.4 State machine a nodi per gli NPC
Ogni stato è un nodo figlio di `NpcBrain` con `enter()`, `exit()`, `update(delta)`.
Mai `if/elif` giganti sullo stato. Uno stato nuovo = un file nuovo.

---

## 4. Come lavoriamo insieme

1. **Un milestone alla volta.** Non implementare niente dei milestone successivi, neanche
   "per comodità". Se ti accorgi che serve un aggancio futuro, aggiungi al massimo il campo
   dati e segnalalo, non il sistema.
2. **Prima di scrivere codice per un task, esponi il piano** (file che creerai, file che
   modificherai, segnali nuovi) e aspetta conferma.
3. **File corti.** Se uno script supera ~150 righe, proponi come spezzarlo.
4. **Commit atomici** con messaggi in italiano, uno per feature completata.
5. Se una richiesta è ambigua, **fai domande invece di scegliere per noi**.
6. Alla fine di ogni task scrivi cosa dobbiamo verificare a mano in editor per considerarlo
   fatto ("Definition of Done" concreto e testabile).
7. Aggiorna la sezione **Stato attuale** in fondo a questo file a ogni task completato.

---

## 5. Struttura dei file

```
res://
  autoload/
    event_bus.gd
    game_state.gd
  player/
    player.tscn
    player.gd
    interactor.gd
    hand.gd
  interactables/
    interactable.gd
    pickup.gd
    place_slot.gd
  npc/
    npc.tscn
    npc.gd
    npc_brain.gd
    states/
  data/
    item_data.gd
    race_data.gd
    items/
    races/
  world/
    tavern.tscn
  assets/
    models/
    textures/
    audio/
```

Naming: file e cartelle in `snake_case`, classi in `PascalCase`, segnali al passato
(`npc_served`), booleani con prefisso `is_`/`has_`.

---

## 6. Roadmap

Contesto per capire dove stiamo andando. **Implementa solo il milestone richiesto.**

| # | Nome | Contenuto |
|---|------|-----------|
| M1 | La stanza | Movimento FPS, interazione, prendi/posa oggetti, look PS1 |
| M2 | Il cliente | Un NPC che entra, ordina, aspetta, viene servito, esce |
| M3 | Il giorno | Ciclo giorno/notte, orari, flusso di clienti, resoconto serale |
| M4 | La cucina | Produzione: ingredienti, calderone, ricette da Resource |
| M5 | L'affinità | Punteggio -100/+100 per NPC, dialoghi, effetti visibili |
| M6 | La notte | Turno notturno: guadagni maggiori, clientela peggiore, rischi |
| M7 | Progressione | Dashboard acquisti, arredi, debito con scadenze |

**Deciso in anticipo per M7** (Michele, 2026-08-05): la fase di costruzione della taverna
(mobili, decorazioni, buff) va **fra il resoconto serale e l'apertura del giorno dopo**.
L'aggancio esiste già da M3 e non va rifatto: `day_ended` apre la pausa, il giocatore
compra e arreda, e solo alla fine qualcuno emette `next_day_requested`. Durante la pausa
il mondo è vivo e ci si può camminare dentro, quindi i mobili si possono piazzare in prima
persona come gli oggetti.

Fuori scope fino a nuovo ordine: dipendenti, corte dei maghi, minigiochi di carte,
affinità NPC-NPC, multiplayer.

---

## 7. TASK M1 — La stanza

**Obiettivo**: una stanza vuota in cui muoversi e manipolare oggetti, con l'aspetto giusto.

Da implementare:
1. `player.tscn`: CharacterBody3D con camera, movimento WASD, mouse look, sprint, crouch no.
   Mouse catturato, ESC lo libera.
2. `interactor.gd`: RayCast3D dalla camera, portata 2.5m. Rileva nodi che estendono
   `Interactable` e mostra un prompt UI minimale al centro ("E — Raccogli").
3. `interactable.gd`: classe base con `interaction_prompt: String` e `func interact(player)`.
4. `pickup.gd`: estende Interactable. Alla raccolta l'oggetto viene riparentato al nodo
   `Hand` (Marker3D davanti alla camera), `freeze = true`, collisione off.
   Un solo oggetto in mano alla volta.
5. `hand.gd`: gestisce l'oggetto equipaggiato. Tasto G o click destro per droppare
   (riparenta al mondo, riabilita fisica, piccolo impulso in avanti).
6. `place_slot.gd`: Area3D su una superficie. Se guardo lo slot con un oggetto valido in
   mano, prompt "E — Posa" e l'oggetto si aggancia esattamente alla posizione dello slot.
7. Shader/post-process PS1: vertex snapping, affine texture mapping, render a bassa
   risoluzione con upscale nearest-neighbor, nebbia. Il valore di risoluzione e l'intensità
   dello snapping devono essere esposti come parametri modificabili in editor.
8. `world/tavern.tscn`: stanza greybox con un bancone, due place slot, tre boccali.

**Definition of Done**: posso girare per la stanza, raccogliere un boccale, vederlo davanti
alla camera, posarlo esattamente su un sottobicchiere del bancone, riprenderlo, dropparlo a
terra. L'immagine ha l'aspetto PS1 e i parametri sono regolabili senza toccare codice.

---

## 8. TASK M2 — Il cliente

**Da fare solo dopo che M1 è approvato.**

**Obiettivo**: il loop minimo di servizio, con un solo prodotto e una sola razza.

Da implementare:
1. `npc.tscn`: CharacterBody3D + NavigationAgent3D, `id`, `memory: Dictionary`,
   `race: RaceData`. NavigationRegion3D nella taverna.
2. `npc_brain.gd` + stati: `Enter` → `GoToCounter` → `WaitAtCounter` → `Leave`.
3. Ordine: arrivato al bancone emette `npc_ordered`. Una icona 3D sopra la testa (billboard)
   mostra cosa vuole. Nessun dialogo, nessun testo.
4. Servizio: se il giocatore posa l'item richiesto nel place slot davanti all'NPC, emette
   `npc_served` con `correct = true/false`. Se corretto, l'NPC "beve" (timer), paga
   (`GameState.money += prezzo`) e passa a `Leave`.
5. **Sistema pazienza e richiamo attenzione** (questo è il cuore del milestone):
   - Timer di pazienza da `RaceData.patience_seconds`, parte quando l'NPC arriva al bancone.
   - Tre stage: al 66%, al 33% e a 0 della pazienza. A ogni passaggio emetti
     `npc_patience_stage_changed` e riproduci `attention_sounds[stage]` da un AudioStreamPlayer3D
     **posizionale** sull'NPC, accompagnato da un'animazione o un piccolo movimento del corpo.
   - Per l'orco: colpo sul bancone, poi due colpi forti, poi ruggito.
   - A pazienza zero l'NPC se ne va insoddisfatto: `npc_left` con `satisfied = false`.
   - I valori degli stage devono stare in RaceData, non nel codice dell'NPC.
6. Uno spawner che fa entrare un NPC ogni N secondi, con N esposto in editor.

**Definition of Done**: sono in magazzino, sento un colpo sul bancone alle mie spalle, torno
di là, vedo l'icona del boccale sopra la testa dell'orco, glielo poso davanti, lui beve,
paga e se ne va. Se lo ignoro abbastanza a lungo, i colpi si fanno più insistenti e alla
fine se ne va arrabbiato.

---

## 9. Asset esterni disponibili

Cartella collegata: `C:\Users\mikel\Desktop\Taverna Project asset` (fuori dal repo).

- **`Human/Humanoid.blend`** — mesh umanoide di Quaternius, 203 vertici, in posa a T.
  Livello di dettaglio giusto per il look PS1. **Non ha scheletro né animazioni**: è una
  statua. Le due mesh dentro il file (`_Overlapping` / `_NotOverlapping`) sono la stessa
  forma con due mappature UV diverse; i due PNG 1024x1024 non sono texture finite ma i
  **fogli UV** su cui dipingere.
- **`Universal Animation Library[Standard]`** — Quaternius, licenza CC0 (uso libero anche
  commerciale). `Unreal-Godot/UAL1_Standard.glb` è la versione per noi. Contiene uno
  **scheletro da 65 ossa** con nomi stile Unreal (`pelvis`, `spine_01..03`, `thigh_l`,
  `calf_l`, `foot_l`, `ball_l`, più tutte le dita) e **43 animazioni**. Il manichino da
  8.546 vertici incluso serve solo da anteprima, non va usato in gioco.
  Animazioni utili alla taverna: `Idle_Loop`, `Walk_Loop`, `Jog_Fwd_Loop`, `Sprint_Loop`,
  `Idle_Talking_Loop`, `Interact`, `PickUp_Table`, `Sitting_Enter/Idle_Loop/Exit`,
  `Spell_Simple_*` (strega), `Dance_Loop`.
- **`40 Free PSX Footsteps`** — già importati nel progetto in `assets/audio/passi/`.

Decisione presa: se il giocatore avrà un corpo in prima persona, saranno **solo le gambe**,
in modo che la regola "niente mani visibili" della sezione 2 resti valida.

Da sapere per quando si farà: texture e animazioni sono indipendenti. L'animazione muove
le ossa, le ossa deformano la mesh, la texture segue. Una texture qualsiasi va bene con
qualsiasi animazione, purché sia disegnata **sulla mappa UV di quel modello**.

## 10. Stato attuale

*(Claude aggiorna questa sezione a ogni task completato)*

- [x] **M1 — completato e approvato.**
  Progetto Godot **4.7.1.stable** creato da zero. Presenti: EventBus + GameState autoload,
  `ItemData` come Resource, player FPS con mouse look e sprint, Interactor con prompt,
  sistema prendi/posa/droppa, shader PS1 (vertex snapping + affine mapping) con rendering
  in SubViewport a 320x240 upscalato nearest, taverna greybox con bancone, due slot e tre
  boccali.
  Note: `Interactable` è un **componente** (Node3D figlio del corpo di collisione), perché
  in Godot non può esistere una superclasse comune fra `RigidBody3D` e `Area3D`.
  `ItemData.scene` è volutamente lasciato vuoto per non creare una dipendenza circolare
  fra `boccale.tres` e `boccale.tscn`: si riempirà quando servirà spawnare item da dati.
- [x] **M2 — completato e approvato.**
  Orco che entra, prende posto al bancone, ordina (icona billboard), aspetta con pazienza
  a tre stage con suono posizionale e movimento del corpo, viene servito, beve, paga ed esce.
  Ciclo verificato a tavolino con esecuzione headless: richiami a 15s/30s/45s su 45s di
  pazienza, `money` a 5 dopo il servizio, boccale consumato, posto liberato.
  Note:
  - `CounterSpot.slot` è un `NodePath` e non un riferimento tipizzato: Godot **non**
    risolve gli export tipizzati con una classe di script (`PlaceSlot`) quando la scena è
    scritta a mano fuori dall'editor. Con le classi native (`Marker3D`, `Label`) funziona.
  - `Object.get_meta(nome, null)` stampa comunque un errore: serve `has_meta()` prima.
    Per questo esiste `Interactable.of(body)`.
  - Suoni dell'orco e icona dell'ordine sono placeholder generati, da sostituire.
  - I `SubViewport` hanno `audio_listener_enable_3d = false` di default: senza attivarlo
    **nessun suono 3D si sente**, perché il gioco vive dentro un SubViewport.
  - Se lo shader non compila (es. una uniform globale mancante), aprendo l'editor Godot
    **risalva i materiali svuotandoli** di tutti gli shader_parameter. Se una texture
    sparisce da un materiale, è questo.
- [ ] **M3 — implementato, in attesa della vostra verifica in gioco.**
  Giornata di lavoro: `DaySchedule` come Resource (orari, secondi per ora di gioco,
  affluenza ora per ora, tetto di clienti in sala, tolleranza di chiusura),
  `world/day_cycle.gd` che fa scorrere il tempo e conta com'è andata, spawner che chiede
  all'orologio quanti clienti servono in quest'ora, HUD con giorno/ora/cassa, resoconto
  serale con E per aprire il giorno dopo. Alla chiusura chi non è stato servito se ne va,
  chi sta bevendo finisce.
  Note:
  - L'orologio **si ferma** all'ora di chiusura mentre la sala si svuota: se continua a
    correre mostra orari come 35:53.
  - Più clienti che escono insieme puntavano tutti lo stesso punto sulla porta e si
    bloccavano a vicenda. `LeaveState` ora li fa uscire entro un raggio, non sul punto
    esatto. Restano due reti di sicurezza (timeout dello stato, tolleranza di chiusura):
    una giornata che non finisce blocca il gioco per sempre.
  - Il ciclo giorno/notte **visivo** (luce che cambia, finestre) non c'è: la taverna è una
    scatola chiusa senza finestre. Deciso con Michele: "prima il meccanismo".
- Extra oltre ai milestone (richiesti da Michele):
  razze `strega` e `gnomo` con i loro suoni; spawner che pesca fra più razze; passi del
  giocatore con suono per superficie (`SurfaceData` + gruppi `superficie_*`); attrezzi
  modellati con Blender via script ed esportati in `.obj` (Godot li importa come Mesh):
  spillatore con leva, botte, brocca, piatto, sgabello. Brocca e piatto sono pickup veri.
  La leva dello spillatore per ora è **solo decorazione**: il meccanismo è M4.
