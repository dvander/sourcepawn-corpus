//Made by Unreal1 of usegaming.com
#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>

new Respawn_Client[MAXPLAYERS+1];
new	Respawn_ClientQueue[MAXPLAYERS+1];
new clientProtected[MAXPLAYERS+1];
new clienthealth[MAXPLAYERS+1];

new Handle:use_Enabled = INVALID_HANDLE;
new Handle:deathHUD;
new Handle:use_spawntimer = INVALID_HANDLE;
new Handle:use_spawnprotection = INVALID_HANDLE;

new String:elimination_tag[32] = "[TF2] Elimination:";

#define PLUGIN_VERSION "1.02"

public Plugin:myinfo = 
{
	name = "=USE= Elimination",
	author = "Unreal (unreal1@usegaming.com)",
	description = "Respawn when your attacker dies",
	version = PLUGIN_VERSION,
	url = "usegaming.com",
};

public OnPluginStart() 
{
	CreateConVar("sm_useelimination_version", PLUGIN_VERSION, "Plugin Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	use_Enabled = CreateConVar("sm_use_elim_enabled", "1", "Enable/Disable TF2 Elimination", 0, true, 0.0, true, 1.0);
	use_spawntimer = CreateConVar("sm_use_elim_spawntimer", "2.0", "Amount of time to spawn player after his attacker dies Default:2.0");
	use_spawnprotection = CreateConVar("sm_use_elim_protection", "4.0", "Amount of time to protect a player after they spawn Default:4.0");
	RegConsoleCmd("jointeam", Command_jointeam);
	HookEvent("round_start", Event_RoundStart, EventHookMode_PostNoCopy);
	//HookEvent("player_team", Event_PlayerTeam);
	HookEvent("player_death", Event_PlayerDeath);
	HookEvent("player_spawn", Event_PlayerSpawn);
	HookEvent("player_hurt", Event_PlayerHurt);	
	HookEvent("teamplay_round_win", Event_Round_End);
	HookEvent("teamplay_round_stalemate", Event_Round_End);
	deathHUD = CreateHudSynchronizer();
}

public OnClientDisconnect(client) 
{
	OnPlayerDeath(client, -1);
}

public Action:Command_jointeam(client, args) 
{
	if (GetConVarBool(use_Enabled))
	{
	decl String:argstr[16];
	GetCmdArgString(argstr, sizeof(argstr));
	if(StrEqual(argstr, "spectatearena")) 
	{
		return;
	}
	else
	CreateTimer(0.0, Timer_JoinTeam, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
	}
}

public Event_Round_End(Handle:event, const String:name[], bool:dontBroadcast) 
{
	if (GetConVarBool(use_Enabled))
	{
	for(new i=1;i<MAXPLAYERS;i++)
	{
		new client = GetClientOfUserId (i);
		if (IsValidClient(client))
		{
		ClearSyncHud(client, deathHUD);
		TF2_RespawnPlayer(client);
		}
	}
	}
}

/*
public Event_PlayerTeam(Handle:event, const String:name[], bool:dontBroadcast) 
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));

	CreateTimer(0.0, Timer_JoinTeam, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
}
*/

public Action:Timer_JoinTeam(Handle:timer, any:data) {
	new client = GetClientOfUserId(data);

	if (!IsValidClient(client)) {
		return;
	}

	if (!IsPlayerAlive(client)) {
		new team = GetClientTeam(client);
		new target = GetTopRespawnQueue(team==2?3:2);

		if (target <= 0) {
			return;
		}

		AddPlayerToRespawnQueue(client, target);
		SetHudTextParams(-1.0, 0.83, 999.0, 255, 255, 255, 255, 0, 0.2, 0.0, 0.1);
		ShowSyncHudText(client, deathHUD, "%s You joined late, you will respawn when \x03%N\x01 dies.", elimination_tag, target);
	}
}

public Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast) 
{
	if (GetConVarBool(use_Enabled))
	{
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientConnected(i) && IsClientInGame(i)) 
		{
			Respawn_Client[i] = 0;
			Respawn_ClientQueue[i] = 0;
		}
	}
	}
}

public Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast) 
{
	if (GetConVarBool(use_Enabled))
	{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	ClearSyncHud(client, deathHUD);
	SetEntityRenderColor(client, 0, 0, 225, 190);
	CreateTimer(0.0, timer_GetHealth, client);
	clientProtected[client] = 1;
	CreateTimer(GetConVarFloat(use_spawnprotection), timer_PlayerProtect, client);

	if (!IsValidClient(client) || !IsClientInGame(client) || !IsPlayerAlive(client)) 
	{
		return;
	}
	}
}

public Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast) 
{
	if (GetConVarBool(use_Enabled))
	{
	new victim = GetClientOfUserId(GetEventInt(event, "userid")),
	attacker = GetEventInt(event, "attacker");

	if (attacker && !(attacker = GetClientOfUserId(attacker))) 
	{
		attacker = -1;
	}
	
	OnPlayerDeath(victim, attacker);
	}
}

OnPlayerDeath(victim, attacker) 
{

	RespawnPlayersInQueue(victim);

	if (attacker < 0) 
	{
		return;
	}

	if (!attacker || victim == attacker) 
	{
		attacker = GetTopRespawnQueue(GetClientTeam(victim)==2?3:2)
		if (attacker <= 0) 
		{
			RespawnPlayer(victim);
		}
			else 
			{
				SetHudTextParams(-1.0, 0.83, 999.0, 255, 255, 255, 255, 0, 0.2, 0.0, 0.1);
				ShowSyncHudText(victim, deathHUD, "%s You killed yourself, you will respawn when \x03%N\x01 dies.", elimination_tag, attacker);
				AddPlayerToRespawnQueue(victim, attacker);
			}
	}
	else 
	{
		SetHudTextParams(-1.0, 0.83, 999.0, 255, 255, 255, 255, 0, 0.2, 0.0, 0.1);
		ShowSyncHudText(victim, deathHUD, "%s You will respawn when \x03%N\x01 dies.", elimination_tag, attacker);
		AddPlayerToRespawnQueue(victim, attacker);
	}
}

GetTopRespawnQueue(team = -1) 
{
	new top = -1,
		offset = GetRandomInt(0, MaxClients-1);
	for (new i = 1; i <= MaxClients; i++) 
	{
		new client = (i + offset) % MaxClients + 1;
		if ((team == -1 || (IsClientConnected(client) && IsClientInGame(client) && GetClientTeam(client) == team && IsPlayerAlive(client))) &&(Respawn_ClientQueue[client] > top || Respawn_ClientQueue[client] == top)) 
		{
			top = client;
		}
	}

	return top;
}

RespawnPlayersInQueue(queue) 
{
	new team = -1;
	if (IsClientConnected(queue) && IsClientInGame(queue)) 
	{
		team = 5 - GetClientTeam(queue);
		if (team != 2 && team != 3) 
		{
			team = -1;
		}
	}

	for (new i = 1; i <= MaxClients; i++) 
	{
		if (IsClientConnected(i) && IsClientInGame(i)) 
		{
			if (Respawn_Client[i] == queue) 
			{
				RespawnPlayer(i);
				Respawn_Client[i] = -1;
			}
		}
	}

	Respawn_ClientQueue[queue] = 0;
}

AddPlayerToRespawnQueue(client, queue) 
{
	Respawn_Client[client] = queue;
	Respawn_ClientQueue[queue]++;
}

stock RespawnPlayer(client) 
{
	if (client > 0 && client <= MaxClients && IsClientConnected(client) && IsClientInGame(client) && !IsPlayerAlive(client)) 
	{
		CreateTimer(GetConVarFloat(use_spawntimer), Timer_TF2_RespawnPlayer,client);
	}
}

public Action:Timer_TF2_RespawnPlayer(Handle:timer, any:client)
{
	TF2_RespawnPlayer(client);
}

public Action:timer_GetHealth(Handle:timer, any:client)
{
	if(IsClientConnected(client) && IsClientInGame(client))
	{
		clienthealth[client] = GetClientHealth(client);
	}
}

public Action:timer_PlayerProtect(Handle:timer, any:client)
{
	clientProtected[client] = false;
	SetEntityRenderColor(client, 255 , 255 , 225, 255);
}

public Event_PlayerHurt(Handle:event,const String:name[],bool:dontBroadcast)
{
	if (GetConVarBool(use_Enabled))
	{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));

	if (clientProtected[client] == 1)
		{
			SetEntData(client, FindDataMapOffs(client, "m_iMaxHealth"), clienthealth[client], 4, true);
			SetEntData(client, FindDataMapOffs(client, "m_iHealth"), clienthealth[client], 4, true);

		}
	}
}

stock bool:IsValidClient(client, bool:nobots = true)
{ 
    if (client <= 0 || client > MaxClients || !IsClientConnected(client) || (nobots && IsFakeClient(client)))
    {
        return false; 
    }
    return IsClientInGame(client); 
}  