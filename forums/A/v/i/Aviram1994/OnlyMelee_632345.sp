/* Plugin Template generated by Pawn Studio */

#include <sourcemod>
#include <sdktools>

new Handle:cvarEnable;
public Plugin:myinfo = 
{
	name = "Only Melee",
	author = "Aviram Hassan/Sp0on/Aviram1994",
	description = "Enables only melee.",
	version = "1.0",
	url = "<- URL ->"
}

public OnPluginStart()
{
	cvarEnable = CreateConVar("sm_onlymelee", "0", "Enable/Disable the plugin", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	CreateConVar("sm_onlymelee_version", "1.00", "Only Melee plugin's version", FCVAR_REPLICATED, true, 0.0, true, 1.0);
	HookEvent("player_spawn", event_PlayerSpawn);
	HookEvent("teamplay_round_start", Event_RoundStart);
	
}
public Action:Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast) {
	if (GetConVarBool(cvarEnable)) {
		new iRegenerate = -1;
		
		while ((iRegenerate = FindEntityByClassname(iRegenerate, "func_regenerate")) != -1) {
			AcceptEntityInput(iRegenerate, "Disable"); // Thanks to Tsunami for that :3 I <3 U!
		}
	}
}
public Action:event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!GetConVarBool(cvarEnable))
		return;
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	CreateTimer(0.1, timer_Melee, client);
}
public Action:timer_Melee(Handle:timer, any:client)
{
	if (IsClientConnected(client) && IsClientInGame(client) && IsPlayerAlive(client))
	{
		for (new i = 0; i <= 5; i++)
		{
			if (i == 2)
			{
				continue;
			}
			
			TF2_RemoveWeaponSlot(client, i);
		}
		
		ClientCommand(client, "slot3");
		PrintToChat(client,"[Only Melee] Dear player,Your weapons was taken because Only-Melee Plugin is activated");
	}
}

stock TF2_RemoveWeaponSlot(client, slot)
{
	new weaponIndex;
	while ((weaponIndex = GetPlayerWeaponSlot(client, slot)) != -1)
	{
		RemovePlayerItem(client, weaponIndex);
		RemoveEdict(weaponIndex);
	}
}