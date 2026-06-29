#include <sourcemod>

#define Plugin_Version "1.0.0"

public Plugin:myinfo = { name = "Ñonnect motd", author = "Mr.Artos", description = "Opens motd when a client joins the server.", version = Plugin_Version, url = "http://www.sourcemod.com"};

public OnClientPutInServer(client)
{
  if (client < 1 || IsFakeClient(client)) return;
  
  FakeClientCommand (client, "say /motd");
}