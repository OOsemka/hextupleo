#!/bin/bash
#
[ "$BASH" ] && function whence
{
	type -p "$@"
}
#
PATH_SCRIPT="$(cd $(/usr/bin/dirname $(whence -- $0 || echo $0));pwd)"

repostub="${PATH_SCRIPT}/repos.txt"
repolist="/tmp/repos.txt"
http="/var/www/html/repos/"

if [ -f ${repolist} ]; then
	echo "Re-using file with all of the enabled repos : ${repolist}"
else
	if [ -f ${repostub} ]; then
		echo "Using ${repostub} as source for repos ( ${repolist} )"
		/bin/cp -afv ${repostub}  ${repolist}
	else
		echo "Creating file with all enabled repos : ${repolist}"
		yum repolist | grep rhel- | awk {'print $1'} | sed 's/\/.*//g' | sed 's/!//g' > ${repolist}
	fi
fi

mkdir -p $http

echo "Downloading repos"
for i in $(cat ${repolist})
do
	echo "Downloading $i"
	reposync -d -n -r $i -p $http
done



echo "Building Local Repositories"
for i in $(cat ${repolist})
do
	echo "Building $http$i/."
	createrepo $http$i/.
done

echo "Grabbing local repo server value from ansible playbook"
repo_server=$(awk '/repo_server:/ { print $2}' vars/install-vars.yml)
if [ "x${repo_server}" = "x" ]; then
	repo_server="http://AAA.BBB.CCC.DDD/repos/"
fi

echo "Creating repo file"
rm -rf local.repo
for i in $(cat ${repolist})
do
	echo "[$i]
name=$i
baseurl=${repo_server}/$i/
enabled=1
gpgcheck=0" >> local.repo
done
