include module type of Parallel_intf.Std.SharedMem
  with type handle = Parallel_intf.Std.SharedMem.handle

val get_heap_handle: unit -> handle

(* Between 0.0 and 1.0 *)
val heap_use_ratio: unit -> float
val slot_use_ratio: unit -> float

val worker_garbage_control: Gc.control
