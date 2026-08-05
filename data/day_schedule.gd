class_name DaySchedule
extends Resource
## Come è fatta una giornata di lavoro: orari, velocità del tempo, affluenza.
## Un file .tres in data/schedules/. Cambiare il ritmo di una giornata non deve
## voler dire toccare il codice.

@export var opening_hour: int = 10
@export var closing_hour: int = 22
## Quanti secondi veri dura un'ora di gioco.
@export var seconds_per_game_hour: float = 40.0

@export_group("Affluenza")
## Quanti clienti entrano in ciascuna ora di apertura.
## Il primo valore è l'ora di apertura. Se la lista è più corta delle ore di
## apertura, per le ore restanti si usa l'ultimo valore.
@export var customers_per_hour: Array[float] = [1.0, 1.0, 2.0, 3.0, 4.0, 3.0, 2.0, 3.0, 5.0, 6.0, 4.0, 2.0]
## Quanti clienti al massimo possono stare dentro contemporaneamente.
@export var max_customers: int = 3
## Quanti secondi veri si aspetta, dopo la chiusura, che la sala si svuoti da
## sola prima di mandare via d'ufficio chi è rimasto. È una rete di sicurezza:
## senza, un cliente incastrato terrebbe la giornata aperta per sempre.
@export var closing_grace_seconds: float = 30.0

## Quanti clienti prevede l'ora indicata.
func customers_at(hour: int) -> float:
	if customers_per_hour.is_empty():
		return 0.0
	var index := clampi(hour - opening_hour, 0, customers_per_hour.size() - 1)
	return customers_per_hour[index]
