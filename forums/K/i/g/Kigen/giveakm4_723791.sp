#include <sourcemod>
#include <sdktools>

new g_InBuyZone;
new bool:g_CanGive[MAXPLAYERS+1] = {true,...};
new const String:g_WeaponNames[][] = {"AK47", "M4A1"};

public Plugin:myinfo =
{
	name = "Give AK/M4",
	author = "Kigen",
	description = "Give AK/M4 to those with Custom1",
	version = "0.1", 
	url = "http://www.codingdirect.com/"
}

public OnPluginStart()
{
	g_InBuyZone = FindSendPropOffs("CCSPlayer", "m_bInBuyZone");
	if ( g_InBuyZone == -1 )
		SetFailState("Couldn't get m_bInBuyZone");
	HookEvent("round_end", Event_RoundEnd);
	RegAdminCmd("sm_giveak", Command_GiveAK, ADMFLAG_CUSTOM1);
	RegAdminCmd("sm_givem4", Command_GiveM4, ADMFLAG_CUSTOM1);
}

public Action:Event_RoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	for(new i=0;i<MAXPLAYERS+1;i++)
		g_CanGive[i] = true;
}

public Action:Command_GiveAK(client, args)
{
	Give(client, 0);
	return Plugin_Handled;
}

public Action:Command_GiveM4(client, args)
{
	Give(client, 1);
	return Plugin_Handled;
}

Give(client, type)
{
	if ( !client || !IsClientInGame(client) || !IsPlayerAlive(client) )
		return;
	if ( !GetEntData(client, g_InBuyZone) )
	{
		PrintToChat(client, "You must be in a buy zone.");
		return;
	}
	if ( !g_CanGive[client] )
	{
		PrintToChat(client, "You can only use this once per round.");
		return;
	}
	decl weapid, String:weapon_name[64];
	weapid = GetPlayerWeaponSlot(client, 0);
	if ( weapid != -1 )
	{
		GetEdictClassname(weapid, weapon_name, sizeof(weapon_name));
		if ( ( !type && StrEqual(weapon_name, "weapon_ak47") ) || ( type && StrEqual(weapon_name, "weapon_m4a1") ) )
		{
			PrintToChat(client, "You already have a %s.", g_WeaponNames[type]);
			return;
		}
	}
	g_CanGive[client] = false;
	if ( type )
		GivePlayerItem(client, "weapon_m4a1");
	else
		GivePlayerItem(client, "weapon_ak47");
	return;
}