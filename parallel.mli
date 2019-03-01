module Scheduler : sig

  module Daemon : sig
    val check_entry_point : unit -> unit
  end

  type t

  val create : ?number_of_workers:int -> ?bucket_multiplier:int -> unit -> t

  val map_reduce
    :  t
    -> ?bucket_size:int
    -> init:'a
    -> map:('a -> 'b list -> 'c)
    -> reduce:('c -> 'a -> 'a)
    -> 'b list
    -> 'a

  val iter : t -> f:('a list -> unit) -> 'a list -> unit

  val single_job : t -> f:('a -> 'b) -> 'a -> 'b

  val mock : unit -> t

  val destroy : t -> unit

  val longest_processing_time_first: int -> ('a * int) list -> 'a list list
end

module Memory : module type of Memory
