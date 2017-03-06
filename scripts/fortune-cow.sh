if [ -z "$(which cowsay)" -o -z "$(which fortune)" ]; then
  return
fi

COWS=$(cowsay -l | tail -n +2)
N_COWS=$(echo $COWS | wc -w)
R_COW=$(( RANDOM % N_COWS ))

for COWF in $COWS; do
  if [[ $R_COW < 1 ]]; then
    break;
  fi
  R_COW=$(( R_COW - 1 ))
done

fortune | cowsay -f $COWF

