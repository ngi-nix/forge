(* The interface of CamlZip, with the pure OCaml library decompress in place of zlib.
   Thus, the program does not need C stubs, and wasm_of_ocaml can compile it. *)
exception Error of string * string

let _ =
  Callback.register_exception "Pdfflate.Error" (Error("",""))

type stream =
  {header : bool;
   level : int;
   mutable window : De.window option;
   mutable lz77_window : De.Lz77.window option;
   mutable queue : De.Queue.t option}

let make_stream level header =
  {header; level; window = None; lz77_window = None; queue = None}

let inflate_stream ?(header = true) () = make_stream 6 header

let deflate_stream ?(level = 6) ?(header = true) () = make_stream level header

(* The windows and the queue do not keep data from one use to the next. *)
let inflate_reset _ = ()

let deflate_reset _ = ()

let buffer_size = 1024


let make_io refill flush =
  let inbuf = De.bigstring_create buffer_size
  and outbuf = De.bigstring_create buffer_size
  and b = Bytes.create buffer_size in
  let refill dst =
    let len = refill b in
      for x = 0 to len - 1 do
        Bigarray.Array1.unsafe_set dst x (Bytes.unsafe_get b x)
      done;
      len
  and flush src len =
    for x = 0 to len - 1 do
      Bytes.unsafe_set b x (Bigarray.Array1.unsafe_get src x)
    done;
    flush b len
  in
    inbuf, outbuf, refill, flush

let get r make =
  match r with Some x -> x | None -> make ()

(* Adler-32 with ints only. The sums stay below 2^30,
   thus the result is correct also when ints have 31 bits (wasm_of_ocaml). *)
let adler_base = 65521

let adler_update (a, b) buf len =
  let a = ref a and b = ref b and i = ref 0 in
    while !i < len do
      let n = min 1000 (len - !i) in
        for x = !i to !i + n - 1 do
          a := !a + Char.code (Bytes.unsafe_get buf x);
          b := !b + !a
        done;
        a := !a mod adler_base;
        b := !b mod adler_base;
        i := !i + n
    done;
    (!a, !b)

(* The zlib format (RFC 1950) around the raw deflate data of De.
   Decompression does not examine the Adler-32 value at the end. *)
let compress ?(level = 6) ?(header = true) ?stream refill flush =
  let s = match stream with Some s -> s | None -> make_stream level header in
  let w = get s.lz77_window (fun () -> De.Lz77.make_window ~bits:15)
  and q = get s.queue (fun () -> De.Queue.create 0x1000) in
    s.lz77_window <- Some w;
    s.queue <- Some q;
    let adler = ref (1, 0) in
    let refill =
      if s.header then
        (fun b -> let n = refill b in adler := adler_update !adler b n; n)
      else refill
    in
    let inbuf, outbuf, refill', flush' = make_io refill flush in
      if s.header then flush (Bytes.of_string "\x78\x9c") 2;
      De.Higher.compress ~w ~q ~refill:refill' ~flush:flush' inbuf outbuf;
      if s.header then begin
        let a, b = !adler in
        let t = Bytes.create 4 in
          Bytes.set t 0 (Char.chr (b lsr 8));
          Bytes.set t 1 (Char.chr (b land 0xff));
          Bytes.set t 2 (Char.chr (a lsr 8));
          Bytes.set t 3 (Char.chr (a land 0xff));
          flush t 4
      end

let uncompress ?(header = true) ?stream refill flush =
  let s = match stream with Some s -> s | None -> make_stream 6 header in
  let w = get s.window (fun () -> De.make_window ~bits:15) in
    s.window <- Some w;
    (* Remove the two bytes of the zlib header from the input. *)
    let skip = ref (if s.header then 2 else 0) in
    let rec refill' b =
      let n = refill b in
        if !skip = 0 || n = 0 then n else begin
          let k = min !skip n in
            if k = 2 && Char.code (Bytes.get b 1) land 0x20 <> 0 then
              raise (Error ("Pdfflate.uncompress", "preset dictionary not supported"));
            skip := !skip - k;
            Bytes.blit b k b 0 (n - k);
            if n - k = 0 then refill' b else n - k
        end
    in
    let inbuf, outbuf, refill, flush = make_io refill' flush in
      match De.Higher.uncompress ~w ~refill ~flush inbuf outbuf with
      | Ok () -> ()
      | Error (`Msg m) -> raise (Error ("Pdfflate.uncompress", m))
