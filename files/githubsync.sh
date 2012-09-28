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

PATH="/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin"
WORKDIR="/var/local/run/githubsync"
MODDIR="${WORKDIR}/modules"
PMDIR="${WORKDIR}/puppetmaster"
OUTPUT=$(mktemp)
DATE=$(date +%Y-%m-%d_%s)


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

  mod="$1"
  local msg="Updated ${mod} module, using ${0}."

  test -n "${mod}" || return 1
  cd "${PMDIR}" || return 1

  git remote add "up-${mod}" "${MODDIR}/${mod}"
  git-subtree pull -q -m "${msg}" -P "modules/${mod}" "up-${mod}" master && \
    echo "Successfully updated module ${mod}"

  if [ $? != 0 ]; then
    echo "Failed running: git-subtree pull -P modules/${mod} up-${mod} master"
    git reset --hard
    return 1
  else
    git push origin $DATE:master && \
    echo "Pushed updated module ${mod} to ${ORIGIN}"
  fi
}


# clone puppetmaster
if test -d "${PMDIR}"; then
  (cd "${PMDIR}" && git remote update origin)
else
  git clone -q $ORIGIN $PMDIR
fi

(cd "${PMDIR}" && git branch $DATE origin/master && git checkout $DATE) || \
  (echo "Failed checking out latest commits from ${ORIGIN}" && exit 1)

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
    echo -e "\nFailed fetching module ${mod} from github.\n" >> $OUTPUT
    continue
  fi

  if ! compute_diff $local $github 2>&1 > /dev/null; then

    msg="Failed to update module ${mod}, manual investigation required."
    update_module $mod || echo -e "\n\n${msg}" >> $OUTPUT

    # diff once again, output to status file
    if ! compute_diff $local $github 2>&1 > /dev/null; then
      echo -e "\nModule '${mod}' differs from github, manual synchronisation required:\n" >> $OUTPUT
      compute_diff $local $github >> $OUTPUT
    fi
  fi
done

mv $OUTPUT "${WORKDIR}/current-status.txt"
