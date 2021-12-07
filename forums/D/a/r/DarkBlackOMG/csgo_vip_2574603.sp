#include <sourcemod>

public Plugin myinfo = 
{
	name = "Vip Benefits",
	author = "XeroX",
	description = "Request by Nexd",
	version = "1.0.0",
	url = "https://forums.alliedmods.net/showthread.php?t=304766"
};

public void OnPluginStart()
{
	HookEvent("player_spawn", Event_PlayerSpawn);
}

public Action Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	
	if(GetClientTeam(client) == 3 && CheckCommandAccess(client, "sm_vip_benefits", ADMFLAG_CUSTOM6))
	{
		SetEntProp(client, Prop_Send, "m_ArmorValue", 100);
		SetEntProp(client, Prop_Send, "m_bHasHelmet", 1);
		SetEntProp(client, Prop_Send, "m_bHasDefuser", 1);
	} else if(GetClientTeam(client) == 2 && CheckCommandAccess(client, "sm_vip_benefits", ADMFLAG_CUSTOM6))
	{
		SetEntProp(client, Prop_Send, "m_ArmorValue", 100);
		SetEntProp(client, Prop_Send, "m_bHasHelmet", 1);
	}
}