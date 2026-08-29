class_name EconomyComponent
extends Node

signal balance_changed(balance: int)

var _balance := 0

func configure(starting_energy: int) -> void:
    _balance = maxi(0, starting_energy)
    balance_changed.emit(_balance)

func get_balance() -> int:
    return _balance

func try_spend(amount: int) -> bool:
    if amount < 0 or amount > _balance:
        return false
    _balance -= amount
    balance_changed.emit(_balance)
    return true

func add_energy(amount: int) -> void:
    if amount <= 0:
        return
    _balance += amount
    balance_changed.emit(_balance)
