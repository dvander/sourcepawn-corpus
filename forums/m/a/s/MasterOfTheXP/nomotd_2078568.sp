#pragma semicolon 1
#define PLUGIN_VERSION  "1.0"

public Plugin:myinfo = {
	name = "No MOTD",
	author = "MasterOfTheXP",
	description = "Removes the initial MOTD shown upon joining.",
	version = PLUGIN_VERSION,
	url = "http://mstr.ca/"
};

new bool:ClientMOTDBlocked[MAXPLAYERS + 1];

new Handle:cvarForceTeam;

public OnPluginStart()
{
	cvarForceTeam = CreateConVar("sm_nomotd_forceteam", "", "If non-blank, will force clients to the specified team name/number. (e.g. \"red\" or \"blue\" on TF2)");
	CreateConVar("sm_nomotd_version", PLUGIN_VERSION, "Can't touch dis. Even if you can, please don't. :c", FCVAR_NOTIFY|FCVAR_PLUGIN|FCVAR_SPONLY);
	
	HookUserMessage(GetUserMessageId("Train"), UserMessageHook, true);
	
	for (new i = 1; i <= MaxClients; i++)
		ClientMOTDBlocked[i] = IsClientInGame(i);
}

public OnClientDisconnect(client)
	ClientMOTDBlocked[client] = false;

public Action:UserMessageHook(UserMsg:msg_id, Handle:bf, const players[], playersNum, bool:reliable, bool:init) 
{
	if (playersNum == 1)
	{
		if (IsClientConnected(players[0]))
		{
			if (!ClientMOTDBlocked[players[0]] && !IsFakeClient(players[0]))
			{
				ClientMOTDBlocked[players[0]] = true;
				CreateTimer(0.0, KillMOTD, GetClientUserId(players[0]), TIMER_FLAG_NO_MAPCHANGE);
			}
		}
	}
}

public Action:KillMOTD(Handle:timer, any:uid)
{
	new client = GetClientOfUserId(uid);
	if (!client) return;
	ShowVGUIPanel(client, "info", _, false);
	new String:team[64];
	GetConVarString(cvarForceTeam, team, sizeof(team));
	if (!strlen(team)) ShowVGUIPanel(client, "team", _, true);
	else FakeClientCommand(client, "jointeam %s", team);
}