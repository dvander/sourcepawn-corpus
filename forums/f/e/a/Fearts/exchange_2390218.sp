#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION  "1.0.3"

new Handle:cURL = INVALID_HANDLE;

public Plugin:myinfo = 
{
    name = "CSGO Exchange Menu",
    author = "Fire Friendly Mitch",
    description = "csgo.exchange",
    version = PLUGIN_VERSION,
    url = "http://csgo.exchange"
};

public OnPluginStart()
{
    cURL = CreateConVar("sm_csgoexchange_baseurl", "http://mitchdizzle.github.io/SMPublicPlugins/popup.html", "The url used to show a popup to the client.");
    AutoExecConfig();

    RegConsoleCmd("sm_exchange", Command_Menu);
    RegConsoleCmd("exchange", Command_Menu);
    RegConsoleCmd("sm_inv", Command_Menu);
    RegConsoleCmd("inv", Command_Menu);
}


public Action:Command_Menu(client, args)
{
    if (!client || !IsClientInGame(client) || GetClientTeam(client) == 0) 
    {
        return Plugin_Handled;
    } 
	
    decl String:steam64[32];
    if(args >= 1) {
        decl String:cmdArg[32];
        GetCmdArgString(cmdArg, sizeof(cmdArg));
        new target = FindTarget(client, cmdArg, true, false);
        if(target>0 && IsClientInGame(target)) {
            if(GetClientAuthId(target, AuthId_SteamID64, steam64, sizeof(steam64))) {
                OpenUrl(client, steam64);
            }
        }
	} else {
		decl String:buffer[32];

		new Handle:menu = CreateMenu(RootMenuHandler);
		SetMenuTitle(menu, "CSGO.Exchange");

		AddMenuItem(menu, "home", "Goto: CSGO.Exchange");
		if(GetClientAuthId(client, AuthId_SteamID64, steam64, sizeof(steam64)))
		{
			GetClientName(client, buffer, 32);
			AddMenuItem(menu, steam64, buffer);
		}

		for(new i=1; i<=MaxClients;i++)
		{
			if(i != client && IsClientInGame(i) && 
			   GetClientAuthId(i, AuthId_SteamID64, steam64, sizeof(steam64)))
			{
				GetClientName(i, buffer, 32);
				AddMenuItem(menu, steam64, buffer);
			}
		}

		DisplayMenu(menu, client, MENU_TIME_FOREVER);
	}
    return Plugin_Handled;
}

public RootMenuHandler(Handle:menu, MenuAction:action, client, param2)
{
    if (action == MenuAction_Select)
    {
        decl String:selection[32];
        GetMenuItem(menu, param2, String:selection, 32); 
        OpenUrl(client, selection);
    }
    else if (action == MenuAction_End)
    {
        CloseHandle(menu);
    }
}

OpenUrl(client, const String:selection[])
{
    new Handle:kv = CreateKeyValues("data");
    
    new String:url[255];
    GetConVarString(cURL, url, sizeof(url));
    StrCat(url, sizeof(url), "?url=http://csgo.exchange/");
    if(!StrEqual(selection, "home")) StrCat(url, sizeof(url), "id/");
    StrCat(url, sizeof(url), selection);
    StrCat(url, sizeof(url), "&opt=height=600,width=930");

    KvSetNum(kv, "customsvr", 1);
    KvSetNum(kv, "type", MOTDPANEL_TYPE_URL);      
    KvSetString(kv, "title", "CSGO Exchange");      
    KvSetString(kv, "msg", url);
    KvSetNum(kv, "customsvr", 1);
    ShowVGUIPanel(client, "info", kv, true);
    CloseHandle(kv);
}