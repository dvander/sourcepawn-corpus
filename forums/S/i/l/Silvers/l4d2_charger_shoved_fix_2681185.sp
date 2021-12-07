#define PLUGIN_VERSION 		"1.2"

/*=======================================================================================
	Plugin Info:

*	Name	:	[L4D2] Charger Shoved Fix
*	Author	:	SilverShot
*	Descrp	:	Prevents the Charger from slowing down when shoved while charging
*	Link	:	https://forums.alliedmods.net/showthread.php?t=321044
*	Plugins	:	https://sourcemod.net/plugins.php?exact=exact&sortby=title&search=1&author=Silvers

========================================================================================
	Change Log:

1.2 (10-May-2020)
	- Various changes to tidy up code.

1.1 (24-Jan-2020)
	- Fixed errors from not verifying if the shoved person was a Charger.

1.0 (22-Jan-2020)
	- Initial release.

======================================================================================*/

#pragma semicolon 1
#pragma newdecls required

#include <sdktools>
#include <sdkhooks>

float vVel[MAXPLAYERS+1][3];



// ====================================================================================================
//					PLUGIN INFO / START / END
// ====================================================================================================
public Plugin myinfo =
{
	name = "[L4D2] Charger Shoved Fix",
	author = "SilverShot",
	description = "Prevents the Charger from slowing down when shoved while charging.",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=321044"
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion test = GetEngineVersion();
	if( test != Engine_Left4Dead2 )
	{
		strcopy(error, err_max, "Plugin only supports Left 4 Dead 2.");
		return APLRes_SilentFailure;
	}
	return APLRes_Success;
}

public void OnPluginStart()
{
	HookEvent("player_shoved", Event_PlayerShoved);
	CreateConVar("l4d2_charger_shoved_fix_version", PLUGIN_VERSION, "Charger Shoved Fix plugin version.", FCVAR_NOTIFY);
}

public void Event_PlayerShoved(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if( GetClientTeam(client) == 3 && GetEntProp(client, Prop_Send, "m_zombieClass") == 6 )
	{
		int ability = GetEntPropEnt(client, Prop_Send, "m_customAbility"); // ability_charge
		if( ability > 0 && IsValidEdict(ability) && GetEntProp(ability, Prop_Send, "m_isCharging") )
		{
			GetEntPropVector(client, Prop_Data, "m_vecVelocity", vVel[client]);
			SDKHook(client, SDKHook_PreThink, PreThink);
		}
	}
}

public void PreThink(int client)
{
	TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, vVel[client]);
	SDKUnhook(client, SDKHook_PreThink, PreThink);
}