# lookup-matrix-user

Quickly lookup some basic info about a user on a MAS enabled server.

To get started, create a config file

```env
serverName="example.com"
synapseEndpoint="https://synapse.example.com"
masEndpoint="https://account.example.com"
synapseAdminToken="mct_abcd"
masClientId="0000000000000000000SYNAPSE"
masClientSecret="secret"
```

By default, the script will look for `config.env` in the same directory as the
script. Alternatively set the full path to your config file as
`LOOKUP_MATRIX_USER_CONFIG_FILE` in your env.

You can then lookup your users by localpart, Matrix ID, or email

```bash
./lookup-matrix-user.sh twilight
./lookup-matrix-user.sh @twilight:example.com
./lookup-matrix-user.sh twilight@example.com
```

The script will store your MAS Admin Token in the file
`$scriptDirectory/masToken` to not re-authenticate every time the script runs.
