#!/bin/sh

# help & input params
if [ $# != 3 ]; then
  cat << EOF
Usage: $0 PROTOCOL USERNAME ORIGIN"
Updates every module in puppetmaster git repository located at ORIGIN by
fetching latest commits from USERNAME's github account using PROTOCOL.

Example:
$0 git camptocamp /srv/puppetmaster/staging/puppetmaster
EOF
  exit 1
else
  PROTO=$1
  USERNAME=$2
  ORIGIN=$3

  if [ "$PROTO" = "ssh" ]; then
    URI="git@github.com:${USERNAME}"
  else
    URI="$PROTO://github.com/${USERNAME}"
  fi
fi

if [ $(id -nu) != "githubsync" ]; then
  echo "Should only be run as githubsync user"
  exit 1
fi

WORKDIR="/var/local/run/githubsync"
MODDIR="${WORKDIR}/modules"
PMDIR="${WORKDIR}/puppetmaster"
OUTPUT=$(mktemp)


fetch_from_github () {
  m="$1"

  if test -z $m; then return 1; fi

  uri="${URI}/puppet-${m}"
  dir="${MODDIR}/${m}"

  if test -d $dir; then
    (cd $dir && git config remote.origin.url $uri && git pull -q origin master)
  else
    git clone -q $uri "${MODDIR}/${m}"
  fi
}


compute_diff () {
  local="$1"
  github="$2"

  diff -qr -x '.git' "${local}" "${github}"
}


update_module () {

  mod=$1
  msg="Auto-updated ${mod} run by ${0}."

  test -z "${mod}" || return 1
  cd "${PMDIR}" || return 1

  git remote add "up-${mod}" "${MODDIR}/${mod}"
  git-subtree pull -q -m "${msg}" -P "modules/${mod}" "up-${mod}" master

  if [ $? != 0 ]; then
    echo "FAILED git subtree pull ${mod}"
    git reset --hard
    return 1
  else
    git push -n origin master
  fi
}


# clone puppetmaster
if test -d "${PMDIR}"; then
  (cd "${PMDIR}" && git pull -q origin master)
else
  echo git clone $ORIGIN $PMDIR
  git clone -q $ORIGIN $PMDIR
fi

# initialize status file
echo -n "    @@@ GitHub sync status at: " > $OUTPUT
date >> $OUTPUT

# loop through each module
for mod in $(ls "${PMDIR}/modules/"); do
  local="${PMDIR}/modules/${mod}"
  github="${MODDIR}/${mod}"

  mkdir -p $MODDIR

  fetch_from_github $mod

  if [ $? != 0 ]; then
    echo -n "\nProblem fetching module ${mod} from github.\n" >> $OUTPUT
    continue
  fi

  if ! compute_diff $local $github 2>&1 > /dev/null; then

    msg="Failed to update module ${mod}, manual investigation required."
    update_module $mod || echo -n "\n${msg}\n" >> $OUTPUT

    # diff once again, output to status file
    if ! compute_diff $local $github 2>&1 > /dev/null; then
      echo -n "\nModule '${mod}' DIFFERS from github:\n" >> $OUTPUT
      compute_diff $local $github >> $OUTPUT
    fi
  fi
done

mv $OUTPUT "${WORKDIR}/current-status.txt"
