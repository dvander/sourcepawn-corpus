#include <market>
#include <sdktools>
#include <multicolors>

new Handle:g_hTeam, Handle:g_hBuyZone, Handle:g_hBuyTime;
new g_iRoundStartTime;

public Plugin:myinfo =
{
    name = "Gun Menu", 
    author = "8GuaWong", 
    description = "Gun Menu", 
    version = "1.0.5", 
    url = "http://www.blackmarke7.org"
};

public OnPluginStart()
{
	RegConsoleCmd("sm_guns", Gun);
	g_hTeam = CreateConVar("sm_guns_team", "1", "Teams that can use the command 1- any, 2-terrorist, 3-counter terrorist");
	g_hBuyZone = CreateConVar("sm_guns_buyzone", "1", "1- have to be in buyzone, 0- don't have to be in buyzone");
	g_hBuyTime = CreateConVar("sm_guns_buytime", "1", "1- obey mp_buytime, 0- ignore mp_buytime");
	HookEvent("player_spawn", PlayerSpawn);
	HookEvent("round_start", RoundStart);
	LoadTranslations("gun_menu.phrases");
}

public Action:RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	g_iRoundStartTime = GetTime();
}

public Action:PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (IsPlayerAlive(client) && (GetConVarInt(g_hTeam) == 1 || GetClientTeam(client) == GetConVarInt(g_hTeam)))
		CPrintToChat(client, "[{green}GUNS{default}] %T", "Announcement", client);
}

public Action:Gun(client, args)
{
	if (!IsClientInGame(client) || !IsPlayerAlive(client))
	{
		CPrintToChat(client, "[{green}GUNS{default}] %T", "Have to be alive", client);
		return Plugin_Handled;
	}
	
	if (GetConVarInt(g_hTeam) != 1 && GetClientTeam(client) != GetConVarInt(g_hTeam))
	{
		CPrintToChat(client, "[{green}GUNS{default}] %T", "Wrong Team", client);
		return Plugin_Handled;
	}
	
	if (GetConVarBool(g_hBuyTime) && GetTime() - g_iRoundStartTime > GetConVarInt(FindConVar("mp_buytime")))
	{
		CPrintToChat(client, "[{green}GUNS{default}] %T", "Past time", client);
		return Plugin_Handled;		
	}
		
	if (GetConVarBool(g_hBuyZone) && !GetEntProp(client, Prop_Send, "m_bInBuyZone"))
	{
		CPrintToChat(client, "[{green}GUNS{default}] %T", "Have to be in buy zone", client);
		return Plugin_Handled;
	}

	decl String:buffer[64];
	Format(buffer, sizeof(buffer), "%T", "Rebuy", client);
	Market_Send(client,"",buffer);
	
	return Plugin_Handled;
}

public bool:Market_OnWeaponSelected(client, String:weaponid[])
{
	if (GetConVarBool(g_hBuyTime) && GetTime() - g_iRoundStartTime > GetConVarInt(FindConVar("mp_buytime")))
	{
		CPrintToChat(client, "[{green}GUNS{default}] %T", "Past time", client);
		return false;		
	}
		
	if (GetConVarBool(g_hBuyZone) && !GetEntProp(client, Prop_Send, "m_bInBuyZone"))
	{
		CPrintToChat(client, "[{green}GUNS{default}] %T", "Have to be in buy zone", client);
		return false;
	}
	return true;
}