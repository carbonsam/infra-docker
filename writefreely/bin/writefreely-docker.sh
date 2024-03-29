#! /bin/sh

set -e

cd /data

WRITEFREELY=/writefreely/writefreely

if [ -e ./config.ini ] && [ -e ./writefreely.db ] && [ -e ./keys/email.aes256 ]; then
    BACKUP="writefreely.$(date +%s).db"
    cp writefreely.db "${BACKUP}"
    ${WRITEFREELY} db migrate
    ## This is for the 0.12->0.13 migration
    ${WRITEFREELY} keys generate || true
    if cmp writefreely.db "${BACKUP}"; then
        rm "${BACKUP}"
    else
        echo "Database backed up at /data/${BACKUP}"
    fi
    exec ${WRITEFREELY}
fi

if [ -e ./config.ini ]; then
    if [ ! -s ./writefreely.db ]; then
        ${WRITEFREELY} db init
    fi
    if [ ! -e ./keys/email.aes256 ]; then
        ${WRITEFREELY} keys generate
    fi

    BACKUP="writefreely.$(date +%s).db"
    cp writefreely.db "${BACKUP}"
    ${WRITEFREELY} db migrate
    if cmp writefreely.db "${BACKUP}"; then
        rm "${BACKUP}"
    else
        echo "Database backed up at /data/${BACKUP}"
    fi
    exec ${WRITEFREELY}

fi

WRITEFREELY_BIND_PORT="${WRITEFREELY_BIND_PORT:-8080}"
WRITEFREELY_BIND_HOST="${WRITEFREELY_BIND_HOST:-0.0.0.0}"
WRITEFREELY_SITE_NAME="${WRITEFREELY_SITE_NAME:-A Writefreely blog}"

cat >./config.ini <<EOF
[server]
hidden_host          =
port                 = ${WRITEFREELY_BIND_PORT}
bind                 = ${WRITEFREELY_BIND_HOST}
tls_cert_path        =
tls_key_path         =
templates_parent_dir = /writefreely
static_parent_dir    = /writefreely
pages_parent_dir     = /writefreely
keys_parent_dir      =

[database]
type     = sqlite3
filename = writefreely.db
username =
password =
database =
host     = localhost
port     = 3306

[app]
site_name         = ${WRITEFREELY_SITE_NAME}
site_description  =
host              = ${WRITEFREELY_HOST:-http://${WRITEFREELY_BIND_HOST}:${WRITEFREELY_BIND_PORT}}
theme             = write
disable_js        = false
webfonts          = true
landing           =
single_user       = ${WRITEFREELY_SINGLE_USER:-false}
open_registration = ${WRITEFREELY_OPEN_REGISTRATION:-false}
min_username_len  = ${WRITEFREELY_MIN_USERNAME_LEN:-3}
max_blogs         = ${WRITEFREELY_MAX_BLOG:-1}
federation        = ${WRITEFREELY_FEDERATION:-true}
public_stats      = ${WRITEFREELY_PUBLIC_STATS:-false}
private           = ${WRITEFREELY_PRIVATE:-false}
local_timeline    = ${WRITEFREELY_LOCAL_TIMELINE:-false}
user_invites      = ${WRITEFREELY_USER_INVITES}
wf_modesty        = ${WRITEFREELY_MODESTY:-false}
EOF

${WRITEFREELY} --init-db
${WRITEFREELY} --gen-keys

if [ -n "${WRITEFREELY_ADMIN_USER}" ] && [ -n "${WRITEFREELY_ADMIN_PASSWORD}" ]; then
    ${WRITEFREELY} --create-admin "${WRITEFREELY_ADMIN_USER}:${WRITEFREELY_ADMIN_PASSWORD}"
fi

exec ${WRITEFREELY}
