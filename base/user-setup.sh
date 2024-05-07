#!/bin/sh

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

    # usermod change the uid
    usermod -u ${GASPAR_UID} user
    # usermod change the gid
    usermod -g ${GASPAR_GID} user
    # usermod change the home directory
    usermod -d $USER_HOME user
    # usermod add to groups
    usermod -aG $(echo $GASPAR_SUPG | tr ' ' ',') user
fi

# Switch to user
su - user
exec /bin/bash "$@"