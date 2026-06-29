#include <sourcemod>

#define PLUGIN_VERSION "1.1"

new Handle: cvar_enabled
new Handle: cvar_money
new Handle: cvar_frags
new g_iAccount

public Plugin: myinfo =
{
	name = "Extra Hostage Rescue",
	author = "fezh",
	description = "Extra stuff rescuing hostages",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/"
}

public OnPluginStart()
{
	cvar_enabled = CreateConVar("sm_hostage_extras", "1", "Turn Plugin On/Off", FCVAR_PLUGIN)
	cvar_money = CreateConVar("sm_hostagerescue_money", "1000", "Extra money per hostage rescue", FCVAR_PLUGIN)
	cvar_frags = CreateConVar("sm_hostagerescue_frags", "2", "Extra frags per hostage rescue", FCVAR_PLUGIN)

	CreateConVar("sm_hostagerescue_version", PLUGIN_VERSION, "Extra Hostage Rescue Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY)

	g_iAccount = FindSendPropOffs("CCSPlayer", "m_iAccount")

	HookEvent("hostage_rescued", EventHostageRescued, EventHookMode_Post)
}

public Action: EventHostageRescued(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!GetConVarInt(cvar_enabled))
		return Plugin_Continue;

	new client = GetClientOfUserId(GetEventInt(event, "userid"))

	if (!client || !IsClientConnected(client))
		return Plugin_Continue;

	new iMoney = GetMoney(client) + GetConVarInt(cvar_money)
	new iFrags = GetClientFrags(client) + GetConVarInt(cvar_frags)

	SetMoney(client, iMoney)
	SetEntProp(client, Prop_Data, "m_iFrags", iFrags)

	return Plugin_Continue;
}

public GetMoney(client)
{
	if (g_iAccount != -1)
		return GetEntData(client, g_iAccount);

	return 0;
}

public SetMoney(client, amount)
{
	if (g_iAccount != -1)
	{
		SetEntData(client, g_iAccount, amount);
	}
}