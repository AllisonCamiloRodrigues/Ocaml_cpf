(* Biblioteca para carregar variáveis do .env *)
open Dotenv

(* Carrega o arquivo .env *)
let () = Dotenv.export ()

(* Pega o TOKEN do Telegram *)
let telegram_token =
  try Sys.getenv "TELEGRAM_TOKEN"
  with Not_found ->
    failwith "TOKEN não encontrado no arquivo .env"

(* Exibe mensagem de confirmação *)
let () =
  print_endline "Sistema configurado com sucesso!";
  print_endline ("TOKEN carregado: " ^ telegram_token)