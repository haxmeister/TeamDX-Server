# TeamDX-Server
TeamDX plugin server for Vendetta Online

Receives JSON messages with a "serverAction" variable and takes action according to it's value. 


## Current list of serverActions:

### sendall
Echos the JSON message to all connected clients including the sender (this could be changed)
example:
```json
{
  "serverAction":"sendall",
  "clientAction":"whatever",
  "name":"Munny"
}
```

### login
Associates a username with the ip/port socket
example:
```json
{
  "serverAction":"login",
  "user":"Munny"
}
```
The server will respond to this if successful as follows
```json
{
  "clientAction":"login", 
  "result":1
}
```
If unsuccessful it will respond with an error message. Currently the only error is if a name wasn't provided.
```json
{
  "clientAction":"login",
  "result":0, 
  "error":"Can't log in without player name"
}
```

### logout
Server will close the connection and remove the user from the working list
example:
```json
{
  "serverAction":"logout",
  "user":"Munny"
}
```

### Check http://voupr.spenced.com/ for a plugin's version
Server will crawl the given address and look for the table in the top right corner to extract information from the server
your message should look like something like this:
```json
{
  "vouprID":"Actions Command Menu",
  "serverAction":"VVC_Request",
  "url":"https://voupr.spenced.com/plugin.php?name=acm"
}
```
Where the "url" should be a valid link to the appropriate page on http://voupr.spenced.com/ for the plugin in question
If successful the server will respond like this:
```json
{
  "clientAction":"VVC_Update",
  "vouprID":"Actions Command Menu",
  "vouprVersion":"v1.0",
  "vouprLastUpdate":"June 13th, 2021",
  "result":1,
  "error":""
}
```
note that the vouprID field is ignored by the server currently, and is simply returning this field as it was received. 

If unsuccessful it will respond like this:
```json
{
  "clientAction":"VVC_Update",
  "vouprID":"Actions Command Menu",
  "vouprVersion":"",
  "vouprLastUpdate":"",
  "result":0,
  "error":"404 error page does not exist on voupr https://voupr.spenced.com/plugin.php?name=acm"
}
```
Where the client is intended to capture this due to `"result":0` and post the error contained in "error" instead of forwarding it to the VVC_Update function. The error message can vary depending on the type of error.
