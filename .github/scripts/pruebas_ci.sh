#!/bin/bash
# Corre game/tests/*_test.tscn con Godot sin pantalla y deja el resumen en resultado.md.
# Una prueba pasa si imprime "RESULTADO: TODO OK", sale con 0 y no se cuelga.
# game/tests/ci_omitir.txt: pruebas que no se pueden correr en la nube (p. ej. necesitan las animaciones Mixamo).
cd game || exit 1
LIMIT=${LIMIT:-400}; PARALLEL=${PARALLEL:-4}; OUT=$(mktemp -d)
OMITIR=$(grep -v '^\s*#' tests/ci_omitir.txt 2>/dev/null | awk '{print $1}' | grep -v '^$' || true)
TESTS=$(ls tests/*_test.tscn | sed 's#tests/##; s#_test.tscn##' | sort)
run_one() {
  local t=$1 log="$OUT/$1.log"
  timeout "$LIMIT" godot --headless --path . "res://tests/${t}_test.tscn" > "$log" 2>&1
  local code=$?
  if [ $code -eq 0 ] && grep -q "RESULTADO: TODO OK" "$log"; then echo ok > "$OUT/$t.r"
  elif [ $code -eq 124 ]; then echo "se colgó (más de ${LIMIT} s)" > "$OUT/$t.r"
  else echo "$(grep -E 'FALLO|SCRIPT ERROR|ERROR|RESULTADO' "$log" | head -3 | tr '\n' ' ' | cut -c1-300)" > "$OUT/$t.r"; fi
}
export -f run_one; export OUT LIMIT
CORRER=$(for t in $TESTS; do echo "$OMITIR" | grep -qx "$t" || echo "$t"; done)
echo "$CORRER" | grep -v '^$' | xargs -P "$PARALLEL" -I{} bash -c 'run_one {}'
OK=0; MAL=0; LISTA=""
for t in $CORRER; do r=$(cat "$OUT/$t.r" 2>/dev/null || echo "sin resultado")
  if [ "$r" = ok ]; then OK=$((OK+1)); else MAL=$((MAL+1)); LISTA="$LISTA\n- **$t**: $r"; echo "::error title=Prueba $t::$r"; fi; done
N_OMIT=$(echo "$OMITIR" | grep -c . || true)
{
  if [ $MAL -eq 0 ]; then echo "🤖 Pruebas: ✅ pasaron las $OK pruebas automáticas del juego."
  else echo "🤖 Pruebas: ❌ fallaron $MAL de $((OK+MAL)) pruebas automáticas."; fi
  echo
  [ $MAL -gt 0 ] && printf "Fallaron:%b\n\n" "$LISTA"
  [ "$N_OMIT" -gt 0 ] && echo "No se corren en la nube ($N_OMIT): $(echo $OMITIR | tr '\n' ' ') — ver \`game/tests/ci_omitir.txt\`."
} > ../resultado.md
cat ../resultado.md
[ $MAL -eq 0 ]
