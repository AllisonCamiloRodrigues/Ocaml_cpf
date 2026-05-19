let token =
  match Sys.getenv_opt "TELEGRAM_TOKEN" with
  | Some t -> t
  | None -> failwith "Token não encontrado"

let dados =
  Uri.encoded_of_query [
    ("chat_id", ["8735206230"]);
    ("text", ["Olá! Me chamo ART. Digite um CPF válido para que eu possa fazer a verificação."])
  ]

let body =
  Cohttp_lwt.Body.of_string dados

let headers =
  Cohttp.Header.init_with
    "Content-Type"
    "application/x-www-form-urlencoded"

let () =
  Lwt_main.run (
    Cohttp_lwt_unix.Client.post
      ~headers
      ~body
      (Uri.of_string
        (Printf.sprintf
          "https://api.telegram.org/bot%s/sendMessage"
          token))
  )