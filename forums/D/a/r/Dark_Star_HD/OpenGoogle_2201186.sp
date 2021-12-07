#include <sourcemod>

public Plugin:myinfo = 
{
name = "OpenGoogle",
author = "Dark Star HD",
description = "Open Google whits !google",
version = "1.0",
url = "www.stylze-gaming.net"
}

new Handle:g_href = INVALID_HANDLE;
public OnPluginStart()
{
RegConsoleCmd("google", GoogleOn);
g_href = CreateConVar("sm_google", "http://google.de", "href link to your steamgroup");
}
public Action:GoogleOn(client,args)
{
decl String:href[255];
GetConVarString(g_href, href, sizeof(href));
ShowMOTDPanel(client, "Google", href, MOTDPANEL_TYPE_URL);
return Plugin_Continue;
}