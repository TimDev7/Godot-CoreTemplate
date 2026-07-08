extends Node
class_name CoreEventBus
# warning-ignore-all:unused_signal

# --- DEBUG ---
signal logged()


# --- CORE ---
signal game_data_loaded(success:bool, last_save_time:int)
signal game_data_saved(success:bool, desc:String)
