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
