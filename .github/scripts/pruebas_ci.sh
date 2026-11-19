#!/bin/bash
# Corre game/tests/*_test.tscn con Godot sin pantalla.
# Fase 1: pruebas rápidas + las relacionadas con los archivos que cambió el PR → comentario «🤖 Pruebas rápidas: …».
# Fase 2: todas las demás → comentario final «🤖 Pruebas: …» (el que espera Madara), con el tiempo total.
# Una prueba pasa si imprime "RESULTADO: TODO OK", sale con 0 y no se cuelga.
# game/tests/ci_omitir.txt: pruebas que no se pueden correr en la nube (p. ej. necesitan las animaciones Mixamo).
INICIO=$(date +%s)
cd game || exit 1
LIMIT=${LIMIT:-400}; PARALLEL=${PARALLEL:-$(( $(nproc) * 2 ))}; OUT=$(mktemp -d)
RAPIDAS="movement save pause iron_pass"
OMITIR=$(grep -v '^\s*#' tests/ci_omitir.txt 2>/dev/null | awk '{print $1}' | grep -v '^$' || true)
TODAS=$(ls tests/*_test.tscn | sed 's#tests/##; s#_test.tscn##' | sort)
omitida() { echo "$OMITIR" | grep -qx "$1"; }

# Pruebas relacionadas: las que mencionan algún script o escena que cambió el PR.
CAMBIOS=$(git diff --name-only "origin/${BASE:-main}"...HEAD 2>/dev/null | grep -E '\.(gd|tscn|tres)$' || true)
REL=""
for f in $CAMBIOS; do b=$(basename "$f" | sed 's/\.[a-z]*$//')
  case "$f" in game/tests/*_test.*) REL="$REL $(basename "$f" | sed 's/_test\..*//')";; esac
  REL="$REL $(grep -l -- "$b" tests/*_test.gd tests/*_test.tscn 2>/dev/null | sed 's#tests/##; s#_test\..*##')"
done
FASE1=$(for t in $RAPIDAS $REL; do echo "$t"; done | sort -u | while read -r t; do [ -f "tests/${t}_test.tscn" ] && ! omitida "$t" && echo "$t"; done)
FASE2=$(for t in $TODAS; do echo "$FASE1" | grep -qx "$t" || omitida "$t" || echo "$t"; done)

run_one() {
  local t=$1 log="$OUT/$1.log"
  timeout "$LIMIT" godot --headless --path . "res://tests/${t}_test.tscn" > "$log" 2>&1
  local code=$?
  if [ $code -eq 0 ] && grep -q "RESULTADO: TODO OK" "$log"; then echo ok > "$OUT/$t.r"
  elif [ $code -eq 124 ]; then echo "se colgó (más de ${LIMIT} s)" > "$OUT/$t.r"
  else echo "$(grep -E 'FALLO|SCRIPT ERROR|ERROR|RESULTADO' "$log" | head -3 | tr '\n' ' ' | cut -c1-300)" > "$OUT/$t.r"; fi
}
export -f run_one; export OUT LIMIT
correr() { echo "$1" | grep -v '^$' | xargs -P "$PARALLEL" -I{} bash -c 'run_one {}'; }
contar() { OK=0; MAL=0; LISTA=""; for t in $1; do r=$(cat "$OUT/$t.r" 2>/dev/null || echo "sin resultado")
  if [ "$r" = ok ]; then OK=$((OK+1)); else MAL=$((MAL+1)); LISTA="$LISTA\n- **$t**: $r"; fi; done; }
tiempo() { local s=$(( $(date +%s) - INICIO )); echo "$((s / 60)) min $((s % 60)) s"; }
comentar() { [ -n "$PR" ] && gh pr comment "$PR" --body-file "$1" >/dev/null 2>&1 || true; cat "$1"; }

# Fase 1
correr "$FASE1"; contar "$FASE1"
{
  if [ $MAL -eq 0 ]; then echo "🤖 Pruebas rápidas: ✅ pasaron las $OK (las rápidas y las relacionadas con este cambio) en $(tiempo). Faltan las demás."
  else echo "🤖 Pruebas rápidas: ❌ fallaron $MAL de $((OK+MAL)) en $(tiempo)."; echo; printf "Fallaron:%b\n" "$LISTA"; fi
} > ../rapidas.md
comentar ../rapidas.md

# Fase 2
correr "$FASE2"; CORRIDAS=$(printf "%s\n%s\n" "$FASE1" "$FASE2" | grep -v '^$'); contar "$CORRIDAS"
for t in $CORRIDAS; do r=$(cat "$OUT/$t.r" 2>/dev/null); [ "$r" = ok ] || echo "::error title=Prueba $t::$r"; done
N_OMIT=$(echo "$OMITIR" | grep -c . || true)
{
  if [ $MAL -eq 0 ]; then echo "🤖 Pruebas: ✅ pasaron las $OK pruebas automáticas del juego en $(tiempo)."
  else echo "🤖 Pruebas: ❌ fallaron $MAL de $((OK+MAL)) pruebas automáticas (en $(tiempo))."; fi
  echo
  [ $MAL -gt 0 ] && printf "Fallaron:%b\n\n" "$LISTA"
  [ "$N_OMIT" -gt 0 ] && echo "No se corren en la nube ($N_OMIT): $(echo $OMITIR | tr '\n' ' ') — ver \`game/tests/ci_omitir.txt\`."
} > ../resultado.md
comentar ../resultado.md
[ $MAL -eq 0 ]
