(* ===================================================== *)
(* PESSOA 1 — CONFIGURAÇÃO DO SISTEMA *)
(* RESPONSÁVEL: ANNA *)
(* ===================================================== *)

(* Biblioteca para programação assíncrona *)
open Lwt.Syntax

(* Carrega o arquivo .env *)
let () =
  Dotenv.export ();

  print_endline "Arquivo .env carregado!"

(* Pega o TOKEN do Telegram *)
let telegram_token =
  match Sys.getenv_opt "TELEGRAM_TOKEN" with
  | Some token ->
      print_endline "TOKEN encontrado!";
      token
  | None ->
      failwith "TOKEN nao encontrado!"
