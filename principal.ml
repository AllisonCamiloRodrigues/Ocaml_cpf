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


(* ===================================================== *)
(* PESSOA 2 — RECEBER MENSAGENS DA API *)
(* RESPONSÁVEL: RAYANNE *)
(* ===================================================== *)

(* Monta URL da API *)
let url =
  "https://api.telegram.org/bot"
  ^ telegram_token
  ^ "/getUpdates"


(* ===================================================== *)
(* PESSOA 3 — MANIPULAÇÃO DO JSON *)
(* RESPONSÁVEL: ALLISON *)
(* ===================================================== *)

(* Biblioteca para manipular JSON *)
open Yojson.Basic.Util

(* Função para interpretar resposta da API *)
let mostrar_mensagem resposta =

  print_endline "Convertendo resposta para JSON...";

  (* Converte resposta em JSON *)
  let json =
    Yojson.Basic.from_string resposta
  in

  print_endline "JSON convertido com sucesso!";

  (* Pega lista de mensagens *)
  let resultados =
    json
    |> member "result"
    |> to_list
  in

  (* Verifica se existem mensagens *)
  if resultados = [] then

    print_endline "Nenhuma mensagem encontrada."

  else

    (* Pega última mensagem *)
    let ultima_mensagem =
      List.hd (List.rev resultados)
    in

    print_endline "Última mensagem encontrada!";

    (* Pega texto enviado *)
    let texto =
      ultima_mensagem
      |> member "message"
      |> member "text"
      |> to_string
    in

    (* Pega chat_id *)
    let chat_id =
      ultima_mensagem
      |> member "message"
      |> member "chat"
      |> member "id"
      |> to_int
    in

    (* Mostra informações no terminal *)
    print_endline "---------------------------";

    print_endline ("Mensagem recebida: " ^ texto);

    print_endline
      ("Chat ID: " ^ string_of_int chat_id);

    print_endline "---------------------------";


    (* ===================================================== *)
    (* RESPONSÁVEL CÓDIGO: TITO SOUZA*)
    (* ===================================================== *)

    let mensagem_envio =
      "Olá! Me chamo ART. Digite um CPF válido para que eu possa fazer a verificação."
    in

    let dados_envio =
      Uri.encoded_of_query [
        ("chat_id", [string_of_int chat_id]);
        ("text", [mensagem_envio])
      ]
    in

    let body_envio =
      Cohttp_lwt.Body.of_string dados_envio
    in

    let headers_envio =
      Cohttp.Header.init_with
        "Content-Type"
        "application/x-www-form-urlencoded"
    in

    let url_envio =
      Printf.sprintf
      "https://api.telegram.org/bot%s/sendMessage"
      telegram_token
    in

    Lwt.async (fun () ->

  let* _ =
    Cohttp_lwt_unix.Client.post
      ~headers:headers_envio
      ~body:body_envio
      (Uri.of_string url_envio)
  in

  print_endline "Mensagem enviada!";

  Lwt.return_unit
)


(* ===================================================== *)
(* EXECUÇÃO PRINCIPAL *)
(* ===================================================== *)

let () =

  print_endline "Iniciando requisicao...";
  print_endline ("URL usada: " ^ url);

  Lwt_main.run (

    (* Faz GET na API *)
    let* (_, body) =
      Cohttp_lwt_unix.Client.get
        (Uri.of_string url)
    in

    print_endline "Resposta recebida!";

    (* Converte resposta para texto *)
    let* resposta =
      Cohttp_lwt.Body.to_string body
    in

    (* Mostra JSON bruto *)
    print_endline "JSON recebido:";
    print_endline resposta;

    (* Chama sua função de manipulação JSON *)
    mostrar_mensagem resposta;

    Lwt.return_unit
  )