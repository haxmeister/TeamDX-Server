# TeamDX-Server
TeamDX plugin server for Vendetta Online

Receives JSON messages with a "serverAction" variable and takes action according to it's value. 


## Current list of serverActions:

### sendall
Echos the JSON message to all connected clients including the sender (this could be changed)
example:
```json
{
  serverAction:"sendall",
  clientAction:"whatever"
  name:"Munny"
}
```

### login
Associates a username with the ip/port socket
example:
```json
{
  serverAction:"login",
  user:"Munny"
}
```
The server will respond to this if successful as follows
```json
{
  clientAction:"login", 
  success:1
}
```
If unsuccessful it will respond with an error message. Currently the only error is if a name wasn't provided.
```json
{
  clientAction:"error", 
  msg:"Can\'t log in without player name"
}
```

### logout
Server will close the connection and remove the user from the working list
example:
```json
{
  serverAction:"logout",
  user:"Munny"
}
```
The server will respond with:
```json
{
  clientAction:"logout", 
  msg:"Server has closed the connection."
}
```

