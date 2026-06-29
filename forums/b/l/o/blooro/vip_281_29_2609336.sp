#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <colors>

public Plugin:myinfo =
{
	name = "VIP",
	author = "SzYma",
	description = "",
	version = "1.0.2",
	url = "http://3Mod.pl/"
};

public OnPluginStart()
{
	HookEvent("player_spawn", Event_OnPlayerSpawn);
	HookEvent("player_team", Event_TagTable);
	HookEvent("player_spawn", Event_TagTable);
}

public Event_OnPlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new team = GetClientTeam(client);
	new money = GetEntProp(client, Prop_Send, "m_iAccount");
	
	if (client > 0 && IsPlayerAlive(client))
	{
		if (IsPlayerGenericAdmin(client))
		{
			PrintToChat(client, "\x01[\x043Mod\x01] Otrzymałeś kevlar, hełm, +5hp, +200$, zestaw do rozbrajania, spadochron oraz zestaw granatów, bo jestes VIP'em.");
			SetEntityHealth(client, 105);  //hp
			SetEntProp(client, Prop_Send, "m_ArmorValue", 100, 4); //armor
			SetEntProp(client, Prop_Send, "m_bHasHelmet", 1); //helm
			SetEntProp(client, Prop_Send, "m_iAccount", money + 200); //200$ plus
			
			GivePlayerItem(client, "weapon_smokegrenade"); //smoke
			GivePlayerItem(client, "weapon_flashbang"); //flash
			GivePlayerItem(client, "weapon_hegrenade"); //grenade
			GivePlayerItem(client, "weapon_flashbang"); //flash
			
			if(team == CS_TEAM_CT)
			{
				GivePlayerItem(client, "item_defuser"); //kombinerki
			}		
		}
	}
}

public Action:Event_TagTable(Handle:event, String:name[], bool:dontBroadcast) 
{ 
    new client = GetClientOfUserId(GetEventInt(event, "userid")); 
    if (IsPlayerGenericAdmin(client))
    {
        CS_SetClientClanTag(client, "[VIP]"); 
    }
}

/*
@param client id

return bool
*/
bool:IsPlayerGenericAdmin(client)
{
	return CheckCommandAccess(client, "generic_admin", ADMFLAG_RESERVATION, false);
}