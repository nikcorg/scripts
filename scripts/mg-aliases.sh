alias nf-start="nf start --wrap -j"
alias start-accounts="start-userapp accounts=1"
alias start-nodes="start-platform graph=1,router=1,baskets=1,catalogues=1,checkout=1,directory=1,events=1,products=1,reservations=1,streams=1,themes=1,viewers=1"
alias start-platform="nf-start Procfile.platform"
alias start-profile-components="start-platform profiles=1"
alias start-rails-console="bundle exec rails c"
alias start-userapp-ruby="start-userapp web=1,sidekiq=1,shoryuken=1"
alias start-userapp="nf-start Procfile.userapp"
alias start-utils="nf-start Procfile.utils"
alias start-graph="nf-start Procfile.platform graph=1"

read -r -d '' MIGRATIONTEMPLATE <<'EOT'
exports.up = knex => knex.raw(`
`);

exports.down = knex => knex.raw(`
`);
EOT

function migration() {
  if [ "$1" = "" ]; then
    echo "Filename required"
    return 1
  fi
  local filename="$(date +%Y%m%d%H%M%S)_$1"
  echo "$MIGRATIONTEMPLATE" > $filename
  echo "Created $filename"
  return 0
}

