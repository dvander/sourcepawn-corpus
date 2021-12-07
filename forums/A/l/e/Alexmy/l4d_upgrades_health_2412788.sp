#pragma semicolon 1
#include <sourcemod>
#pragma newdecls required

Handle cvarHealth = null, cvarArmor = null, cvarPlayerSpawn = null;

public Plugin myinfo =
{
    name = "[L4D & L4D2] Upgrades Health and Armor",
    author = "AlexMy",
    description = "",
    version ="1.5",
    url = "https://forums.alliedmods.net/showthread.php?p=2412788",
}

public void OnPluginStart()
{
	cvarHealth       = CreateConVar("sm_MaxHealth", "150", "Health in the rounds or after the return of the spectators", FCVAR_NOTIFY);
	cvarArmor        = CreateConVar("sm_MaxArmor", "400", "Armor in the rounds or after the return of the spectators",   FCVAR_NOTIFY);
	
	cvarPlayerSpawn  = CreateConVar("sm_update_afk_hp", "0", "A player will gain health if you come from the AFK 1:ON, 0:OFF",   FCVAR_NOTIFY);
	
	AutoExecConfig(true, "l4d_hp and Armor");
	
	HookEvent("player_spawn",       Event_PlayerSpawn);
	HookEvent("player_first_spawn", Event_PlayerFirstSpawn, EventHookMode_Post);
}

public void Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	if(GetConVarInt(cvarPlayerSpawn))
	{
		CreateTimer(4.0, timer_Spawn, GetClientOfUserId(event.GetInt("userid")), TIMER_FLAG_NO_MAPCHANGE);
	}
}
public void Event_PlayerFirstSpawn(Event event, const char[] name, bool dontBroadcast)
{
	CreateTimer(4.0, timer_Spawn, GetClientOfUserId(event.GetInt("userid")), TIMER_FLAG_NO_MAPCHANGE);
}

public Action timer_Spawn(Handle timer, any client)
{
	if (IsClientInGame(client) && !IsFakeClient(client))
	{
		SetEntData(client, FindDataMapOffs(client, "m_iHealth"), GetConVarInt(cvarHealth), 4, true);
		SetEntData(client, FindDataMapOffs(client, "m_ArmorValue"), GetConVarInt(cvarArmor), 4, true);
	}
	return Plugin_Stop;
}