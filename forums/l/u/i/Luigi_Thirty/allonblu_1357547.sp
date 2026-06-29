/*
 * TF2 All on Blue Plugin
 * Written by Luigi Thirty
 *
 * Slays anyone who spawns on Red and forces them to Blu.
 * 
 * INSTRUCTIONS: Set trade_allonblue to 1 to force everyone to the blue team. Will not kill red players until
 *			they respawn.
*/

#pragma semicolon 1
#include <sourcemod>
#include <tf2>

new Handle:g_hEnabled = INVALID_HANDLE;
new Handle:g_hAdminsToo = INVALID_HANDLE;
new Handle:hConVarBalance = INVALID_HANDLE;
new Handle:hConVarLimit = INVALID_HANDLE;
new bool:autoBalanceConVarIsSet;

public Plugin:myinfo =
{
	name = "All On Blue",
	author = "Luigi Thirty",
	description = "Forces all clients to be on one team or the other.",
	version = "1.1.0"
};

public OnPluginStart()
{
	g_hEnabled = CreateConVar("aob_activeteam", "1", "If 1, anyone who spawns on RED will die and respawn on BLU. If 2, anyone who spawns on BLU will die and respawn on RED.");
	g_hAdminsToo = CreateConVar("aob_adminsexempt", "1", "If 1, anyone with the generic admin flag (B) is exempt from enforced team switching.");

	autoBalanceConVarIsSet = false;
	HookEvent("player_spawn", Event_PlayerSpawn, EventHookMode_Pre);

	hConVarBalance = FindConVar("mp_autoteambalance");
	hConVarLimit = FindConVar("mp_teams_unbalance_limit");

}

public Action:Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast) {

	if (GetConVarInt(g_hEnabled) == 1){
		if(autoBalanceConVarIsSet == false) //if autobalance is enabled, turn it off
			setAutoBalanceConVars(0);
		new client = GetClientOfUserId(GetEventInt(event, "userid"));
		new String:playerName[64];
		GetClientName(client, playerName, sizeof(playerName));

		new AdminId:userAdminId = GetUserAdmin(client);

		if(userAdminId == INVALID_ADMIN_ID || GetConVarInt(g_hAdminsToo) == 0){
			if(GetClientTeam(client) == 2){
				ChangeClientTeam(client, 3);
				PrintHintText(client, "You can't spawn on RED. Switching to BLU.");
				return Plugin_Changed;
			}
		} else if(!GetAdminFlag(userAdminId, Admin_Generic)){
			if(GetClientTeam(client) == 2){
				ChangeClientTeam(client, 3);
				PrintHintText(client, "You can't spawn on RED. Switching to BLU.");
				return Plugin_Changed;
			}
		}
	}

	if (GetConVarInt(g_hEnabled) == 2){
		if(autoBalanceConVarIsSet == false) //if autobalance is enabled, turn it off
			setAutoBalanceConVars(0);
		new client = GetClientOfUserId(GetEventInt(event, "userid"));
		new String:playerName[64];
		GetClientName(client, playerName, sizeof(playerName));

		new AdminId:userAdminId = GetUserAdmin(client);

		if(userAdminId == INVALID_ADMIN_ID || GetConVarInt(g_hAdminsToo) == 0){
			if(GetClientTeam(client) == 3){
				ChangeClientTeam(client, 2);
				PrintHintText(client, "You can't spawn on BLU. Switching to RED.");
				return Plugin_Changed;
			}
		} else if(!GetAdminFlag(userAdminId, Admin_Generic)){
			if(GetClientTeam(client) == 3){
				ChangeClientTeam(client, 2);
				PrintHintText(client, "You can't spawn on BLU. Switching to RED.");
				return Plugin_Changed;
			}
		}	
	}

	if (GetConVarInt(g_hEnabled) == 0){
		if(autoBalanceConVarIsSet == true) //if autobalance is disabled, turn it on
			setAutoBalanceConVars(1);
	}

	return Plugin_Continue;
}

public setAutoBalanceConVars(value){
	PrintToServer("Entity count: %d", GetEntityCount());
	PrintToServer("Setting mp_autoteambalance to %d", value);
	SetConVarInt(hConVarBalance, value);
	PrintToServer("Setting mp_teams_unbalance_limit to %d", value);
	SetConVarInt(hConVarLimit, value);

	if(value == 0){
		autoBalanceConVarIsSet = true;
	}
	if(value == 1){
		autoBalanceConVarIsSet = false;
	}
}
