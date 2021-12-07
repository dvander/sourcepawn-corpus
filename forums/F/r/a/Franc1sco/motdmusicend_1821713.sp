#pragma semicolon 1
#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "b0.3"


new Handle:Musica = INVALID_HANDLE;

new String:nada[128] = "about:blank";

public Plugin:myinfo =
{
	name = "SM Motd Music End",
	author = "Franc1sco Steam: franug",
	description = "plays music on map end by MOTD",
	version = PLUGIN_VERSION,
	url = "www.servers-cfg.foroactivo.com"
};

public OnPluginStart()
{
	CreateConVar("sm_motdmusicend_version", PLUGIN_VERSION, "version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);

	Musica = CreateConVar("sm_motdmusicend_url", "http://www.clanesunidos.com/web/", "Url with music");
	
  	HookEvent("player_spawn", OnPlayerSpawn);
    	HookEvent("round_end", Event_RoundEnd);
}

public Action:OnPlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
        new client = GetClientOfUserId(GetEventInt(event, "userid"));

	CheckFilter(client);
 
	DoUrl(client, nada);
}

public Action:Event_RoundEnd(Handle: event , const String: name[] , bool: dontBroadcast)
{
  new time;
  if (GetMapTimeLeft(time) && time == 0)  // only in map end
  {
  	decl String:cancion[128];
  	GetConVarString(Musica, cancion, sizeof(cancion));
  	for (new i = 1; i < GetMaxClients(); i++)
  	{
		if (IsClientInGame(i) && GetClientTeam(i) != 1)
		{
            		DoUrl(i, cancion);
		}
  	}
  }
}

public Action:DoUrl(client, String:url[128])
{
	new Handle:setup = CreateKeyValues("data");
	
	KvSetString(setup, "title", "Musicspam");
	KvSetNum(setup, "type", MOTDPANEL_TYPE_URL);
	KvSetString(setup, "msg", url);
	
	ShowVGUIPanel(client, "info", setup, false);
	CloseHandle(setup);
	return Plugin_Handled;
}

CheckFilter(client)
{
	QueryClientConVar(client, "cl_disablehtmlmotd", CheckQuery2, client);
}

public CheckQuery2(QueryCookie:cookie, client, ConVarQueryResult:result, const String:cvarName[], const String:cvarValue[])
{
	if (!StrEqual(cvarValue, "0") && IsClientInGame(client))
	{
		PrintToChat(client, "\x04[SM_MotdMusicEnd] \x01You must put in console this: \x03cl_disablehtmlmotd 0");
	}
}