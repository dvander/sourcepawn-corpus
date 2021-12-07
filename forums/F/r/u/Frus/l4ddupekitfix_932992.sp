/* Plugin Template generated by Pawn Studio */

#include <sourcemod>
#include <sdktools>

public Plugin:myinfo = 
{
	name = "L4D Duplicate Medkit Fix",
	author = "Frustian",
	description = "Fixes duplicate medkits in the saferoom",
	version = "1.0",
	url = ""
}
//cvar handles
new Handle:DPenabled;
new Handle:RPenabled;
new Handle:VMenabled;
new Handle:DBenabled;
//Various global variables
new KitsPickedUp; //Stores how many converted pills the survivors picked up
new KitSpawnGiven[4]; //Records the pill spawner IDs that have been used
public OnPluginStart()
{
	CreateConVar("l4d_dupekitfix_version", "1.0", "Dupe Kit Fix Plugin version",FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	DPenabled = CreateConVar("l4d_dupekitfix_enable", "1", "Enable Dupe Kit Fix Plugin",FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	RPenabled = CreateConVar("l4d_dupekitfix_removeonplayer", "1", "If 1, removes duplicate medkits directly from the player after being picked up, otherwise if 0 deletes another medkit near the player when a duplicate kit is picked up.",FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	VMenabled = CreateConVar("l4d_dupekitfix_verbose", "0", "Enable telling the player when they lose their duplicate kit",FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	DBenabled = CreateConVar("l4d_dupekitfix_debug", "0", "Enable telling all players a duplicate kit was removed",FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	HookEvent("round_end", Event_RoundEnd, EventHookMode_PostNoCopy);
	HookEvent("round_start", Event_RoundStart, EventHookMode_PostNoCopy);
	HookEvent("spawner_give_item", Event_SpawnGive, EventHookMode_Post);
}
public OnMapStart()
{
	if (!GetConVarInt(DPenabled))
		return;
	KitsPickedUp = 0;
	for (new i=0;i<3;i++)
		KitSpawnGiven[i] = 0;
}
public OnMapEnd()
{
	if (!GetConVarInt(DPenabled))
		return;
	KitsPickedUp = 0;
	for (new i=0;i<3;i++)
		KitSpawnGiven[i] = 0;
}
public Action:Event_RoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!GetConVarInt(DPenabled))
		return;
	KitsPickedUp = 0;
	for (new i=0;i<3;i++)
		KitSpawnGiven[i] = 0;
}
public Action:Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!GetConVarInt(DPenabled))
		return;
	KitsPickedUp = 0;
	for (new i=0;i<3;i++)
		KitSpawnGiven[i] = 0;
}
public Action:Event_SpawnGive(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!GetConVarInt(DPenabled))
		return;
	new String:item[128];
	GetEventString(event, "item", item, sizeof(item));
	if (!strcmp(item, "weapon_first_aid_kit"))
	{
		if (KitsPickedUp <= 3)
		{
			for (new i=0;i<3;i++)
				if (KitSpawnGiven[i] == GetEventInt(event, "spawner"))
				{
					if (!IsFakeClient(GetClientOfUserId(GetEventInt(event, "userid"))))
						if (GetConVarInt(RPenabled))
							RemovePlayerItem(GetClientOfUserId(GetEventInt(event, "userid")), GetPlayerWeaponSlot(GetClientOfUserId(GetEventInt(event, "userid")), 3));
						else
						{
							RemoveNearbyKit(GetClientOfUserId(GetEventInt(event, "userid")));
							KitsPickedUp++;
							if (GetConVarInt(DBenabled))
								PrintToChatAll("[SM] An extra medkit has been deleted");
							return;
						}
					else
					{
						RemoveNearbyKit(GetClientOfUserId(GetEventInt(event, "userid")));
						KitsPickedUp++;
						if (GetConVarInt(DBenabled))
							PrintToChatAll("[SM] A medkit was removed in lieu of removing a bot's medkit");
						return;
					}
					if (GetConVarInt(VMenabled))
						PrintToChat(GetClientOfUserId(GetEventInt(event, "userid")), "[SM] You picked up a duplicate medkit that was removed.  Please pick up another one");
					if (GetConVarInt(DBenabled))
						PrintToChatAll("[SM] A duplicate medkit was removed from a player");
					return;
				}
			KitSpawnGiven[KitsPickedUp] = GetEventInt(event, "spawner");
			KitsPickedUp++;
			return;
		}
	}
}
public RemoveNearbyKit(client)
{
	new ent = -1;
	decl Float:clientpos[3];
	GetEntPropVector(client, Prop_Send, "m_vecOrigin", clientpos);
	while ((ent = FindEntityByClassname(ent, "weapon_first_aid_kit_spawn")) != -1)
	{
		new kitCheck = true;
		for (new i=0;i<3;i++)
			if (KitSpawnGiven[i] == ent)
				kitCheck = false;
		if(kitCheck)
		{
			decl Float:kitpos[3];
			GetEntPropVector(ent, Prop_Send, "m_vecOrigin", kitpos);
			if (GetVectorDistance(clientpos, kitpos) <= 200.0)
			{
				RemoveEdict(ent);
				return;
			}
		}
	}
}