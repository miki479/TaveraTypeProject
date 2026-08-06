extends Node
## Bus di segnali globale.
## REGOLA: qui dentro solo segnali. Zero logica, zero stato.
## I sistemi non si referenziano mai direttamente fra loro.

## Emesso quando un oggetto viene raccolto e agganciato alla mano.
signal item_picked_up(item: Node3D)

## Emesso quando un oggetto viene lasciato cadere nel mondo.
signal item_dropped(item: Node3D)

## Emesso quando un oggetto viene posato su uno slot.
signal item_placed(item: Node3D, slot: Node3D)

## Emesso quando un cliente entra nella taverna.
signal npc_entered(npc: Node3D)

## Emesso quando un cliente decide cosa vuole.
signal npc_ordered(npc: Node3D, item_id: StringName)

## Emesso quando gli viene posato davanti qualcosa: correct dice se era giusto.
signal npc_served(npc: Node3D, item_id: StringName, correct: bool)

## Emesso quando un cliente lascia la taverna, soddisfatto o no.
signal npc_left(npc: Node3D, satisfied: bool)

## Emesso a ogni scatto della pazienza: stage 0, 1, 2.
signal npc_patience_stage_changed(npc: Node3D, stage: int)

## Emesso all'inizio di una giornata di lavoro.
signal day_started(day: int)

## Emesso a ogni minuto di gioco.
signal time_changed(hour: int, minute: int)

## Emesso all'ora di apertura.
signal tavern_opened()

## Emesso all'ora di chiusura: non entra più nessuno.
signal tavern_closed()

## Emesso quando anche l'ultimo cliente è uscito. report contiene
## day, served, satisfied, angry, earned, money.
signal day_ended(report: Dictionary)

## Emesso dal resoconto serale quando il giocatore vuole aprire il giorno dopo.
signal next_day_requested()

## Emesso da chiunque incassi qualcosa, con il punto dove mostrarlo.
signal money_earned(amount: int, at: Vector3)

## Emesso quando il giocatore decide di chiudere prima dell'orario.
signal close_requested()
