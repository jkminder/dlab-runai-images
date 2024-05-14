#!/bin/sh

set -e

# start sshd
service ssh start

# Setup GASPAR USER
GASPAR_USER=$(awk -F '-' '{ print $3 }' /var/run/secrets/kubernetes.io/serviceaccount/namespace)

if ! id -u $GASPAR_USER > /dev/null 2>&1; then
    GASPAR_UID=$(ldapsearch -H ldap://scoldap.epfl.ch -x -b "ou=users,o=epfl,c=ch" "(uid=$GASPAR_USER)" uidNumber | egrep ^uidNumber | awk '{ print $2 }')
    GASPAR_GID=$(ldapsearch -H ldap://scoldap.epfl.ch -x -b "ou=users,o=epfl,c=ch" "(uid=$GASPAR_USER)" gidNumber | egrep ^gidNumber | awk '{ print $2 }')
    GASPAR_SUPG=$(ldapsearch -LLL -H ldap://scoldap.epfl.ch -x -b ou=groups,o=epfl,c=ch \(memberUid=${GASPAR_USER}\) gidNumber | grep 'gidNumber:' | awk '{ print $2 }' | paste -s -d' ' -)

    # Create Groups
    for gid in $GASPAR_SUPG; do
        groupadd -g $gid $(ldapsearch -LLL -H ldap://scoldap.epfl.ch -x -b ou=groups,o=epfl,c=ch \(gidNumber=$gid\) cn | egrep ^cn | awk '{ print $2 }')
    done

    # Create DLAB Home Directory
    SCRATCH=/dlabscratch1/dlabscratch1
    if [ -d "$SCRATCH" ]; then
        USER_HOME=$SCRATCH/$GASPAR_USER
    else
        USER_HOME=/home/${GASPAR_USER}
        mkdir -p $USER_HOME
    fi

    # Create User and add to groups
    useradd -u ${GASPAR_UID} -d $USER_HOME -s /bin/bash ${GASPAR_USER} -g ${GASPAR_GID}     
    usermod -aG $(echo $GASPAR_SUPG | tr ' ' ',') ${GASPAR_USER}
    if ! [ -d "$SCRATCH" ]; then
        chown -R ${GASPAR_USER}:${GASPAR_GID} $USER_HOME
    fi

    # passwordless sudo
    echo "${GASPAR_USER} ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
    # HACKYYYY: set automatic bash login 
    echo "exec gosu ${GASPAR_USER} /bin/bash" > /root/.bashrc


    # .bashrc for user
    chown ${GASPAR_USER}:${GASPAR_GID} /tmp/.bashrc
        su ${GASPAR_USER} -c "if [ ! -f "$USER_HOME/.bashrc" ]; then cp /tmp/.bashrc '$USER_HOME/.bashrc'; fi"
    fi

if [ -z "$1" ]; then
    exec gosu ${GASPAR_USER} /bin/bash
else
    exec gosu ${GASPAR_USER} "$@"
fi