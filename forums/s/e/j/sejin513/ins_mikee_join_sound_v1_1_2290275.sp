#pragma semicolon 1
#define PLUGIN_VERSION "1.1"
#define PLUGIN_DESCRIPTION "Mikee Join Sound ._."

public Plugin:myinfo =
{
	name = "＃Lua Mikee Join Sound",
	author = "D.Freddo",
	description = PLUGIN_DESCRIPTION,
	version = PLUGIN_VERSION,
	url = "http://steam.lua.kr"
}

new bool:g_bLateLoad = false;
new Handle:g_hCvarEnabled;
new WelcomeToTheCompany[MAXPLAYERS + 1] = {0, ...};

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	g_bLateLoad = late;
	return APLRes_Success;
}

public OnPluginStart()
{
	CreateConVar("sm_ins_mikee_join_sound", PLUGIN_VERSION, PLUGIN_DESCRIPTION, FCVAR_NOTIFY | FCVAR_PLUGIN | FCVAR_DONTRECORD);
	g_hCvarEnabled = CreateConVar("sm_ins_mikee_join_sound_enabled", "1", "Mikee Join Sound Enable [0/1] ._.", FCVAR_NOTIFY | FCVAR_PLUGIN | FCVAR_DONTRECORD, true, 0.0, true, 1.0);
	HookEvent("player_pick_squad", Event_PlayerPickSquad);
}

public OnMapStart()
{
	if (g_bLateLoad){
		g_bLateLoad = false;
		for (new i = 1; i <= MaxClients; i++)
			if (IsClientInGame(i)) WelcomeToTheCompany[i] = 2;
	}
}

public OnClientPutInServer(client)
{
	WelcomeToTheCompany[client] = 0;
}

public Event_PlayerPickSquad(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (!IsFakeClient(client)){
		if (WelcomeToTheCompany[client] < 2){
			if (GetConVarInt(g_hCvarEnabled) == 1){
				WelcomeToTheCompany[client] = 1;
				ClientCommand(client, "playgamesound Training.Warehouse.Vip.1.1");
				CreateTimer(2.0, WelcomeToTheCompany_rly, client, TIMER_FLAG_NO_MAPCHANGE);
				CreateTimer(6.8, WelcomeToTheCompany_rly, client, TIMER_FLAG_NO_MAPCHANGE);
			}
		}
	}
}

public Action:WelcomeToTheCompany_timer(Handle:timer, any:client)
{
	if ((GetConVarInt(g_hCvarEnabled) < 1) || (!IsClientInGame(client)) || (!WelcomeToTheCompany[client]))
		return Plugin_Stop;

	switch(WelcomeToTheCompany[client]){
		case 2:
			ClientCommand(client, "playgamesound Training.Warehouse.Vip.1.1");
		case 1:
			ClientCommand(client, "playgamesound Training.Warehouse.Vip.1.2");
		case 0:
			ClientCommand(client, "playgamesound Training.Warehouse.Vip.41.3");
	}
	WelcomeToTheCompany[client]--;
	return Plugin_Stop;
}