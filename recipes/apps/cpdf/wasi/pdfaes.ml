(* AES (FIPS 197) in OCaml, for one block of 16 bytes.
   The program does not need C stubs, and wasm_of_ocaml can compile it.
   A cooked key is the expanded key: 16 bytes for each round key. *)

let sbox =
  let s = Bytes.create 256 in
  let rotl8 x n = ((x lsl n) lor (x lsr (8 - n))) land 0xff in
  let p = ref 1 and q = ref 1 in
  let continue = ref true in
    while !continue do
      (* Multiply p by 3. *)
      p := !p lxor ((!p lsl 1) land 0xff) lxor (if !p land 0x80 <> 0 then 0x1b else 0);
      (* Divide q by 3. *)
      q := !q lxor (!q lsl 1);
      q := !q lxor (!q lsl 2);
      q := !q lxor (!q lsl 4);
      q := !q land 0xff;
      if !q land 0x80 <> 0 then q := !q lxor 0x09;
      let x = !q lxor rotl8 !q 1 lxor rotl8 !q 2 lxor rotl8 !q 3 lxor rotl8 !q 4 in
        Bytes.set s !p (Char.chr (x lxor 0x63));
        if !p = 1 then continue := false
    done;
    Bytes.set s 0 (Char.chr 0x63);
    Bytes.to_string s

let inv_sbox =
  let s = Bytes.create 256 in
    String.iteri (fun i c -> Bytes.set s (Char.code c) (Char.chr i)) sbox;
    Bytes.to_string s

let sub x = Char.code (String.unsafe_get sbox x)

let inv_sub x = Char.code (String.unsafe_get inv_sbox x)

let xtime x = ((x lsl 1) lxor (if x land 0x80 <> 0 then 0x1b else 0)) land 0xff

let rec mul a b =
  if b = 0 then 0 else (if b land 1 <> 0 then a else 0) lxor mul (xtime a) (b lsr 1)

let rounds key = String.length key / 16 - 1

let cook_key k =
  let nk = String.length k / 4 in
  if nk <> 4 && nk <> 6 && nk <> 8 then invalid_arg "Pdfaes.cook_key";
  let nr = nk + 6 in
  let w = Bytes.create (16 * (nr + 1)) in
    Bytes.blit_string k 0 w 0 (4 * nk);
    let rcon = ref 1 in
    for i = nk to 4 * (nr + 1) - 1 do
      let t = Array.init 4 (fun j -> Char.code (Bytes.get w (4 * (i - 1) + j))) in
      let t =
        if i mod nk = 0 then begin
          let t = [|sub t.(1) lxor !rcon; sub t.(2); sub t.(3); sub t.(0)|] in
            rcon := xtime !rcon;
            t
        end else if nk > 6 && i mod nk = 4 then Array.map sub t
        else t
      in
        for j = 0 to 3 do
          Bytes.set w (4 * i + j)
            (Char.chr (Char.code (Bytes.get w (4 * (i - nk) + j)) lxor t.(j)))
        done
    done;
    Bytes.to_string w

let add_round_key s key r =
  for i = 0 to 15 do
    s.(i) <- s.(i) lxor Char.code (String.unsafe_get key (16 * r + i))
  done

(* The state is in column order, as the input. *)
let shift_rows s inv =
  let t = Array.copy s in
    for c = 0 to 3 do
      for r = 1 to 3 do
        let c' = if inv then (c + 4 - r) mod 4 else (c + r) mod 4 in
          s.(4 * c + r) <- t.(4 * c' + r)
      done
    done

let mix_columns s m =
  for c = 0 to 3 do
    let a = Array.sub s (4 * c) 4 in
      for r = 0 to 3 do
        s.(4 * c + r) <-
          mul a.(0) m.((4 - r) mod 4) lxor mul a.(1) m.((5 - r) mod 4)
          lxor mul a.(2) m.((6 - r) mod 4) lxor mul a.(3) m.((7 - r) mod 4)
      done
  done

let load src off = Array.init 16 (fun i -> Char.code (Bytes.get src (off + i)))

let store s dst off = Array.iteri (fun i x -> Bytes.set dst (off + i) (Char.chr x)) s

let encrypt key src soff dst doff =
  let nr = rounds key and s = load src soff in
    add_round_key s key 0;
    for r = 1 to nr do
      for i = 0 to 15 do s.(i) <- sub s.(i) done;
      shift_rows s false;
      if r < nr then mix_columns s [|2; 3; 1; 1|];
      add_round_key s key r
    done;
    store s dst doff

let decrypt key src soff dst doff =
  let nr = rounds key and s = load src soff in
    add_round_key s key nr;
    for r = nr - 1 downto 0 do
      shift_rows s true;
      for i = 0 to 15 do s.(i) <- inv_sub s.(i) done;
      add_round_key s key r;
      if r > 0 then mix_columns s [|14; 11; 13; 9|]
    done;
    store s dst doff
