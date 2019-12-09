{ stdenv, symlinkJoin, writeTextFile, emacs, moreutils }:
let
  sessionScript = writeTextFile {
    name = "emacs-session";
    executable = true;
    destination = "/bin/emacs-session";
    text = ''
#!/bin/sh -eu

test_for_session() {
  eval_in_session "$1" "server-name" &>/dev/null
}

look_for_session() {
  test_for_session "$1" \
    || (echo "Emacs session $1 not found" && exit 1)
}

ensure_session() {
  look_for_session "$1" &>/dev/null \
    || create_new_session "$1"
}

create_new_session() {
  ${moreutils}/bin/chronic ${emacs}/bin/emacs --daemon="$1"
}

eval_in_session() {
  LISP="''${2:-}"
  if [ -z "$LISP" ]; then
    echo "No expression to evaluate"
    exit 1
  fi
  ${emacs}/bin/emacsclient -s "$1" -e "$LISP"
}

session_uptime() {
  look_for_session "$1"
  eval_in_session "$1" "(emacs-uptime)"
}

session_list() {
  # Quite inaccurate
  ${emacs}/bin/emacsclient -e "server-socket-dir" \
    | xargs -I{} find {} -type s \
    | xargs -n 1 basename
}

session_client() {
  SESSION="$1"
  shift
  ${emacs}/bin/emacsclient -s "$SESSION" "$@"
}

close_session() {
  ${emacs}/bin/emacsclient -s "$1" -e "(kill-emacs)"
}


COMMAND="''${1:-}"
shift

case $COMMAND in
  list)
    session_list
    exit $?
    ;;
esac


SESSION_VAR="''${EMACS_SESSION:-}"
SESSION_ARG="''${1:-}"

if [ -z "''${SESSION_VAR}" -a -z "''${SESSION_ARG}" ]; then
  echo "Need EMACS_SESSION or an argument"
  exit 1
fi

if [ ! -z "''${SESSION_VAR}" ]; then
  SESSION="$SESSION_VAR"
elif [ ! -z "''${SESSION_ARG}" ]; then
  SESSION="$SESSION_ARG"
  shift
fi

case $COMMAND in
  ensure)
    ensure_session "$SESSION"
    ;;
  client)
    session_client "$SESSION" "$@"
    ;;
  eval)
    eval_in_session "$SESSION" "$1"
    ;;
  uptime)
    session_uptime "$SESSION"
    ;;
  close)
    close_session "$SESSION"
    ;;
  *)
    echo "Supported commands: list ensure client eval uptime close"
    exit 1
    ;;
esac
    '';
  };
in
  symlinkJoin {
      name = "emacs-session";
      paths = [ emacs sessionScript ];
      buildInputs = [ emacs moreutils ];
  }
