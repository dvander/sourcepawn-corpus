#include <sourcemod>
#include <cstrike>

//new String:clantag[32];

public Plugin:myinfo = {
    name = "Private Chat",
    author = "hlsavior",
    description = "A private SCNG chat.",
    url = "www.scnggames.com"
};

public OnPluginStart()
{
    RegConsoleCmd("sm_scng", ScngChat, "Use to talk to people in SCNG, usage !scng  <message>");
}

/* dont use global string for this
public OnClientPutInServer(client)
{
    CS_GetClientClanTag(client, clantag, sizeof(clantag));
}
*/

public Action:ScngChat(client, args)
{
    decl String:clantag[32];
    CS_GetClientClanTag(client, clantag, sizeof(clantag));

    if(StrEqual(clantag, "SCNG", false))
    {
        PrintToChat(client, "Only SCNG members can use that command.");
        return Plugin_Handled;
    }else if(StrEqual(clantag, "SCNG", true))
    {
	decl String:arg[128];
    	GetCmdArg(1, arg, sizeof(arg));

	for(new i = 1; i <= MaxClients; i++)
    	{
        	if (IsClientInGame(i))
        	{
			decl String:clantag2[32];
    			CS_GetClientClanTag(i, clantag2, sizeof(clantag2));
			if(StrEqual(clantag, "SCNG", true))
				PrintToChat(i,"%N say: %s", i,arg);
			
		}

        }
    }
    return Plugin_Handled;
}  