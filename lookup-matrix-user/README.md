# lookup-matrix-user

Quickly lookup some basic info about a user on a MAS enabled server.

To get started, create a config file

```env
serverName="example.com"
synapseEndpoint="https://synapse.example.com"
masEndpoint="https://account.example.com"
adminToken="mpt_abcd"
```

By default, the script will look for `config.env` in the same directory as the
script. Alternatively set the full path to your config file as
`LOOKUP_MATRIX_USER_CONFIG_FILE` in your env.

`adminToken` must be a MAS personal token with both MAS and Synapse Admin
permissions.

You can then lookup your users by localpart, Matrix ID, or email

```bash
./lookup-matrix-user.sh twilight
./lookup-matrix-user.sh @twilight:example.com
./lookup-matrix-user.sh twilight@example.com
```
