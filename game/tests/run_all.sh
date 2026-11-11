#!/bin/bash
# Ejecuta las pruebas automáticas y termina con un resumen claro ("31/31 OK" o la lista de las que fallan).
#   bash game/tests/run_all.sh           → todas (4 a la vez), antes de cada commit
#   bash game/tests/run_all.sh rapido    → solo las rápidas, tras cada cambio pequeño
#   bash game/tests/run_all.sh ai save   → solo esas (nombre sin "_test")
# Las pruebas se encuentran solas: cualquier tests/*_test.tscn. Una prueba FALLA si no imprime
# "RESULTADO: TODO OK", si sale con un código distinto de 0 o si se pasa del tiempo (se colgó).
cd /g/Game/game || exit 1
G=/g/Herramientas/Godot/Godot_v4.7.2-stable_win64_console.exe
PARALLEL=${PARALLEL:-4}
LIMIT=${LIMIT:-400}
QUICK="movement combat save pause iron_pass combo_settle"
OUT=$(mktemp -d)

if [ "$1" = "rapido" ]; then
  TESTS=$QUICK
elif [ $# -gt 0 ]; then
  TESTS="$*"
else
  TESTS=$(ls tests/*_test.tscn | sed 's#tests/##; s#_test.tscn##' | sort)
fi

run_one() {
  local t=$1
  local log="$OUT/$t.log"
  timeout "$LIMIT" "$G" --headless --path . "res://tests/${t}_test.tscn" > "$log" 2>&1
  local code=$?
  if [ $code -eq 0 ] && grep -q "RESULTADO: TODO OK" "$log"; then
    echo "ok" > "$OUT/$t.result"
  elif [ $code -eq 124 ]; then
    echo "SE COLGÓ (más de ${LIMIT} s)" > "$OUT/$t.result"
  else
    echo "FALLO: $(grep -E 'FALLO|SCRIPT ERROR|RESULTADO' "$log" | head -5 | tr '\n' ' ')" > "$OUT/$t.result"
  fi
}
export -f run_one
export G OUT LIMIT

START=$(date +%s)
echo "$TESTS" | tr ' ' '\n' | grep -v '^$' | xargs -P "$PARALLEL" -I{} bash -c 'run_one {}'

TOTAL=0; PASSED=0; FAILED=""
for t in $TESTS; do
  TOTAL=$((TOTAL + 1))
  r=$(cat "$OUT/$t.result" 2>/dev/null || echo "NO SE EJECUTÓ")
  if [ "$r" = "ok" ]; then
    PASSED=$((PASSED + 1))
  else
    FAILED="$FAILED\n  ✗ $t: $r"
  fi
done

# La auditoría de animación va aparte (necesita fotogramas fijos) y solo en la batería completa.
if [ $# -eq 0 ]; then
  TOTAL=$((TOTAL + 1))
  if timeout "$LIMIT" "$G" --headless --fixed-fps 60 --path . res://tests/anim_audit.tscn 2>&1 | grep -q "RESULTADO: TODO OK"; then
    PASSED=$((PASSED + 1))
  else
    FAILED="$FAILED\n  ✗ anim_audit"
  fi
fi

echo "Tiempo: $(( $(date +%s) - START )) s"
if [ "$PASSED" -eq "$TOTAL" ]; then
  echo "RESULTADO: $PASSED/$TOTAL OK"
  rm -rf "$OUT"
  exit 0
fi
echo -e "RESULTADO: $PASSED/$TOTAL OK — fallan:$FAILED"
echo "(registros completos en $OUT)"
exit 1
