extends Node
class_name CoreEventBus
# warning-ignore-all:unused_signal

# --- DEBUG ---
signal logged()


# --- CORE ---
signal game_data_loaded(success, last_save_time) # last_save_time: String
signal game_data_saved(success)
