/*=======================================================================================
	Plugin Info:

*	Name	:	[L4D & L4D2] Block Bots Shooting Players
*	Version	:	1.4
*	Author	:	SilverShot
*	Link	:	http://forums.alliedmods.net/showthread.php?p=1278997

=========================================================================================
	Change Log:

*	1.4
	- Fixed array error.

*	1.3.1
	- Removed cvar saving to file!

*	1.3
	- Added version cvar.
	- Now individually blocks shooting from bots.

*	1.2
	- Moved HookEvents to OnPluginStart.
	- Fixed infected players not being shot at.
	- Allowed to work in L4D 1/

*	1.1
	- Added HookEvents to detect when players should be shot at!

*	1.0
	- Initial release.

=======================================================================================*/

#include <sourcemod>
#include <sdktools>

#pragma semicolon 1
#define PLUGIN_VERSION		"1.4"

new bool:bLockFire[MAXPLAYERS+1] = false;
new CanShootAt[MAXPLAYERS+1];


public Plugin:myinfo =
{
	name = "[L4D & L4D2] Block Bots Shooting Players",
	author = "SilverShot",
	description = "Block the survivor bots from shooting at survivor players causing the screen to shake.",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?p=1278997"
}


/*======================================================================================
################			P L U G I N  /  M A P   S T A R T			################
======================================================================================*/
public OnPluginStart()
{
	// Game check.
	decl String:s_GameName[128];
	GetGameFolderName(s_GameName, sizeof(s_GameName));
	if (StrContains(s_GameName, "left4dead") < 0) SetFailState("The plugin 'Block Bots Shooting Players' only supports L4D & L4D2");

	// EVENT HOOKS //
	// Jockey
	HookEvent("jockey_ride", Event_True);
	HookEvent("jockey_ride_end", Event_False);
	// Charger
	HookEvent("charger_carry_start", Event_True);
	HookEvent("charger_carry_end", Event_False);
	HookEvent("charger_pummel_start", Event_True);
	HookEvent("charger_pummel_end", Event_False);
	// Hunter
	HookEvent("lunge_pounce", Event_True);
	HookEvent("pounce_end", Event_False);
	HookEvent("pounce_stopped", Event_False);
	// Smoker
	HookEvent("tongue_grab", Event_True);
	HookEvent("tongue_release", Event_False);
	HookEvent("choke_start", Event_True); // Is this required?
	HookEvent("choke_end", Event_False); // Is this required?
	// Incap
	HookEvent("player_incapacitated", Event_True);
	HookEvent("revive_success", Event_False);
	
	CreateConVar("l4d_block_bots_shooting_players_version", PLUGIN_VERSION, "Block Bots Shooting Players version", FCVAR_NOTIFY|FCVAR_REPLICATED);
}


public OnMapStart()
{
	// Clear array
	for (new i = 0; i < sizeof(CanShootAt); i++) CanShootAt[i] = 0;
}


/*======================================================================================
################				H O O K E D   E V E N T S				################
======================================================================================*/
public Action:Event_True(Handle:hEvent, const String:s_Name[], bool:b_DontBroadcast)
{
	new i_Client = GetClientOfUserId(GetEventInt(hEvent, "victim"));
	CanShootAt[i_Client] = 1;
	bLockFire[i_Client] = false;
}

public Action:Event_False(Handle:hEvent, const String:s_Name[], bool:b_DontBroadcast)
{
	new i_Client = GetClientOfUserId(GetEventInt(hEvent, "victim"));
	CanShootAt[i_Client] = 0;
}


/*======================================================================================
################		O N   P L A Y E R   C M D  -  B L O C K			################
======================================================================================*/
public Action:OnPlayerRunCmd(i_Client, &buttons)
{	
	// Client is attacking
	if (buttons & IN_ATTACK)
	{
		// Make sure client is a valid survivor bot
		if (!IsClientInGame(i_Client) || !IsFakeClient(i_Client) || GetClientTeam(i_Client) != 2) return Plugin_Continue;

		// Our bool not allowing them to shoot so block the attack command
		if (bLockFire[i_Client] == true) return Plugin_Handled;

		// Get what the bot is looking at
		new i_Target = GetClientAimTarget(i_Client, true);

		// Check the target is a survivor player
		if (i_Target > 0 && IsClientInGame(i_Target) && !IsFakeClient(i_Target) && GetClientTeam(i_Target) == 2)
		{
			// The player has been grabbed by infected so let the bots shoot.
			if (CanShootAt[i_Target] == 1) return Plugin_Continue;

			// They are looking at a player and shooting... why???? Stop them shooting!
			bLockFire[i_Client] = true;

			// Allow them to fire again in 2 seconds
			CreateTimer(2.0, tmrUnlock, i_Client);

			// Block attack command
			return Plugin_Handled;
		}
	}

	return Plugin_Continue;
}


public Action:tmrUnlock(Handle:timer, any:i_Client)
{
	bLockFire[i_Client] = false;
}