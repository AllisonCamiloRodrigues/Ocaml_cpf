(* ===================================================== *)
(* PESSOA 1 — CONFIGURAÇÃO DO SISTEMA *)
(* RESPONSÁVEL: ANNA *)
(* ===================================================== *)

open Lwt.Syntax

(* Carrega variáveis do arquivo .env *)
let () =
  Dotenv.export ();

  print_endline "Arquivo .env carregado!"

(* Busca TOKEN do Telegram *)
let telegram_token =
  match Sys.getenv_opt "TELEGRAM_TOKEN" with
  | Some token ->
      print_endline "TOKEN encontrado!";
      token
  | None ->
      failwith "TOKEN nao encontrado!"


(* ===================================================== *)
(* PESSOA 2 — RECEBER MENSAGENS DO TELEGRAM *)
(* RESPONSÁVEL: RAYANNE *)
(* ===================================================== *)

open Yojson.Basic.Util

(* Monta URL do getUpdates *)
let get_updates_url ultimo_update =

  "https://api.telegram.org/bot"
  ^ telegram_token
  ^ "/getUpdates?offset="
  ^ string_of_int ultimo_update


(* ===================================================== *)
(* PESSOA 3 — MANIPULAÇÃO DO JSON E VALIDAÇÃO CPF *)
(* RESPONSÁVEL: ALLISON *)
(* ===================================================== *)

(* Remove tudo que nao for numero *)
let limpar_cpf cpf =

  cpf
  |> String.to_seq
  |> List.of_seq
  |> List.filter (fun c -> c >= '0' && c <= '9')
  |> List.to_seq
  |> String.of_seq


(* Verifica se todos os caracteres sao iguais *)
let cpf_repetido cpf =

  cpf = "00000000000"
  || cpf = "11111111111"
  || cpf = "22222222222"
  || cpf = "33333333333"
  || cpf = "44444444444"
  || cpf = "55555555555"
  || cpf = "66666666666"
  || cpf = "77777777777"
  || cpf = "88888888888"
  || cpf = "99999999999"


(* Converte caractere para inteiro *)
let char_para_int c =

  (Char.code c) - (Char.code '0')


(* Calcula digito verificador *)
let calcular_digito cpf tamanho =

  let soma = ref 0 in

  for i = 0 to tamanho - 1 do

    let numero =
      char_para_int cpf.[i]
    in

    soma :=
      !soma + (numero * (tamanho + 1 - i))

  done;

  let resto =
    (!soma * 10) mod 11
  in

  if resto = 10 then
    0
  else
    resto


(* Validação completa do CPF *)
let validar_cpf cpf =

  let cpf_limpo =
    limpar_cpf cpf
  in

  if String.length cpf_limpo <> 11 then
    false

  else if cpf_repetido cpf_limpo then
    false

  else (

    let digito1 =
      calcular_digito cpf_limpo 9
    in

    let digito2 =
      calcular_digito cpf_limpo 10
    in

    let digito1_original =
      char_para_int cpf_limpo.[9]
    in

    let digito2_original =
      char_para_int cpf_limpo.[10]
    in

    digito1 = digito1_original
    &&
    digito2 = digito2_original
  )


(* ===================================================== *)
(* PESSOA 4 — ENVIAR MENSAGENS *)
(* RESPONSÁVEL: TITO *)
(* ===================================================== *)

let enviar_resposta chat_id texto =

  let url =
    "https://api.telegram.org/bot"
    ^ telegram_token
    ^ "/sendMessage"
  in

  let parametros =
    [
      ("chat_id", [string_of_int chat_id]);
      ("text", [texto])
    ]
  in

  let headers =
    Cohttp.Header.init_with
      "Content-Type"
      "application/x-www-form-urlencoded"
  in

  let body =
    Cohttp_lwt.Body.of_form parametros
  in

  Cohttp_lwt_unix.Client.post
    ~headers
    ~body
    (Uri.of_string url)


(* ===================================================== *)
(* LOOP PRINCIPAL *)
(* ===================================================== *)

let rec loop ultimo_update =

  let url =
    get_updates_url ultimo_update
  in

  let* (_, body) =
    Cohttp_lwt_unix.Client.get
      (Uri.of_string url)
  in

  let* resposta =
    Cohttp_lwt.Body.to_string body
  in

  let json =
    Yojson.Basic.from_string resposta
  in

  (* Verifica se "result" existe *)
  let resultados_json =
    json |> member "result"
  in

  match resultados_json with

  | `Null ->

      let* () =
        Lwt_unix.sleep 2.0
      in

      loop ultimo_update

  | _ ->

      let resultados =
        resultados_json |> to_list
      in

      match resultados with

      | [] ->

          let* () =
            Lwt_unix.sleep 2.0
          in

          loop ultimo_update

      | _ ->

          let ultima =
            List.hd (List.rev resultados)
          in

          let update_id =
            ultima
            |> member "update_id"
            |> to_int
          in

          let texto =
            ultima
            |> member "message"
            |> member "text"
            |> to_string
          in

          let chat_id =
            ultima
            |> member "message"
            |> member "chat"
            |> member "id"
            |> to_int
          in

          print_endline "======================";
          print_endline ("Mensagem recebida: " ^ texto);

          let cpf_limpo =
            limpar_cpf texto
          in

          (* Responde apenas se tiver 11 numeros *)
          if String.length cpf_limpo = 11 then (

            let resposta_bot =

              if validar_cpf texto then
                "CPF valido!"
              else
                "CPF invalido!"

            in

            print_endline ("Resposta do bot: " ^ resposta_bot);

            let* (_, body_resposta) =
              enviar_resposta chat_id resposta_bot
            in

            let* resposta_api =
              Cohttp_lwt.Body.to_string body_resposta
            in

            print_endline "Resposta da API:";
            print_endline resposta_api;

            print_endline "Mensagem enviada!";

            let* () =
              Lwt_unix.sleep 2.0
            in

            loop (update_id + 1)

          ) else (

            print_endline "Mensagem ignorada.";

            let* () =
              Lwt_unix.sleep 2.0
            in

            loop (update_id + 1)

          )


(* ===================================================== *)
(* INICIAR BOT *)
(* ===================================================== *)

let () =

  print_endline "======================";
  print_endline "BOT INICIADO...";
  print_endline "======================";

  Lwt_main.run (
    loop 0
  )