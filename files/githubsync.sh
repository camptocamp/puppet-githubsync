#!/bin/sh

# help & input params
if [ $# != 4 ]; then
  cat << EOF
Usage: $0 PROTOCOL USERNAME ORIGIN GIST_ID"
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
  GIST_ID=$4

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

umask 0002

PATH="/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin"
WORKDIR="/var/local/run/githubsync"
MODDIR="${WORKDIR}/modules"
PMDIR="${WORKDIR}/puppetmaster"
OUTPUT=$(mktemp)
OUTPUT_JSON=$(mktemp)
DATE=$(date +%Y-%m-%d_%s)

test -e /etc/profile.d/http_proxy.sh && . /etc/profile.d/http_proxy.sh

default_branch () {
  m="$1"

  curl --netrc -ks "https://api.github.com/repos/camptocamp/puppet-${m}" | jgrep -s "default_branch"
}

fetch_from_github () {
  m="$1"

  if test -z $m; then return 1; fi

  uri="${URI}/puppet-${m}"
  dir="${MODDIR}/${m}"
  branch=$(default_branch "${m}")

  if test -d $dir; then
    (cd $dir && git config remote.origin.url $uri && git pull -q origin $branch)
  else
    git clone -q $uri "${MODDIR}/${m}"
  fi
}


is_identical () {
  local="$1"
  github="$2"

  diff -qr -x '.git' "${local}" "${github}" 2>&1 > /dev/null
}


update_module () {

  mod="$1"
  commitmsg="Updated ${mod} module, using ${0}."

  test -n "${mod}" || return 1
  cd "${PMDIR}" || return 1

  git remote add "up-${mod}" "${MODDIR}/${mod}"
  git subtree pull -q -m "${commitmsg}" -P "modules/${mod}" "up-${mod}" && \
    echo "Successfully updated module ${mod}"

  if [ $? != 0 ]; then
    echo "\n\n    @@@ Running 'git subtree pull -P modules/${mod} up-${mod}' failed, resetting changes." >> $OUTPUT
    echo "Failed to pull changes using git subtree"
    #echo -n "\"${mod}\": {\"status\": \"subtree pull failed\"}" >> $OUTPUT_JSON
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
DATE_JSON=$(date --rfc-2822 -u)
echo -n "{\"files\": { \"`facter fqdn`.json\": { \"content\": \"" >> $OUTPUT_JSON
echo -n "{\\\"date\\\": \\\"${DATE_JSON}\\\", \\\"modules\\\": {" >> $OUTPUT_JSON
for mod in $(ls "${PMDIR}/modules/"); do
  local="${PMDIR}/modules/${mod}"
  github="${MODDIR}/${mod}"

  if [ "x${add_comma}" = "xtrue" ]; then
    echo -n "," >> $OUTPUT_JSON
  fi
  add_comma="true"

  mkdir -p $MODDIR

  # re-download every module at each run
  test -d "$github" && rm -fr "$github"

  fetch_from_github $mod

  if [ $? != 0 ]; then
    /bin/echo -e "\n    @@@ Failed fetching module ${mod} from github.\n" >> $OUTPUT
    echo -n "\\\"${mod}\\\": {\\\"status\\\": \\\"failed fetching\\\"}" >> $OUTPUT_JSON
    continue
  fi

  if is_identical $local $github; then
    echo -n "\\\"${mod}\\\": {\\\"status\\\": \\\"identical\\\"}" >> $OUTPUT_JSON
  else
    update_module $mod

    # diff once again, output to status file
    if is_identical $local $github; then
      echo -n "\\\"${mod}\\\": {\\\"status\\\": \\\"identical\\\"}" >> $OUTPUT_JSON
    else
      /bin/echo -e "\n    @@@ Conflict merging module '${mod}', manual investigation required:\n" >> $OUTPUT
      diff -ur -x '.git' $local $github >> $OUTPUT
      echo -n "\\\"${mod}\\\": {\\\"status\\\": \\\"merge conflict\\\"}" >> $OUTPUT_JSON
    fi
  fi
done
echo -n "}}" >> $OUTPUT_JSON 
echo "\"}}}" >> $OUTPUT_JSON

mv -f $OUTPUT "${WORKDIR}/current-status.txt"
curl  --netrc --request PATCH --data "`cat ${OUTPUT_JSON}`" https://api.github.com/gists/$GIST_ID
rm $OUTPUT_JSON
