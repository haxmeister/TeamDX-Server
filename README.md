# TeamDX-Server
TeamDX plugin server for Vendetta Online

Recieves JSON messages with an "action" attribute and takes action according to this tribute.

## list of actions:

### sendall
Echos the JSON message to all connected clients including the sender (this could be changed)
example:
```json
{
  action:"sendall",
  name:"Munny"
}
```

### login
Associates a username with the ip/port socket
example:
```json
{
  action:"login",
  user:"Munny"
}
```
The server will respond to this if successful as follows
```json
{
  action:"login", 
  success:1
}
```
If unsuccessful it will respond with an error message. Currently the only error is if a name wasn't provided.
```json
{
  action:"error", 
  msg:"Can\'t log in without player name"
}
```

### logout
Server will close the connection and remove the user from the working list
example:
```json
{
  action:"logout",
  user:"Munny"
}
```
The server will respond with:
```json
{
  action:"logout", 
  msg:"Server has closed the connection."
}
```

