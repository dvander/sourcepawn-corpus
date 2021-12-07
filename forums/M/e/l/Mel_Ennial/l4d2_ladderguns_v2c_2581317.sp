/*
	~~~ Ladderguns plugin for L4D2 ~~~
	
	~ Changelog ~
	
	v1		- initial release. Only manual mode included.
	v2		- automatic mode; survivors pull out guns when they stop on a ladder.
			- cvars; a cvar to show current version, and a cvar to change laddergun mode (0 = disabled, 1 = manual, 2 = auto).
			- plugin now won't load unless the game is L4D2.
			- plugin info now exists.
	v2a, b	- Cravenge's fix for the tank-related bug reported by MasterMind420. Thanks, guys.
	c		- No more need for the kludge, Cravenge solved my problem.

*/
#pragma semicolon 1
#include <sourcemod>
#include <sdktools>

#define LG_VERSION "2"

#define LG_MODE_MANUAL 1
#define LG_MODE_AUTO 2

/*
Extract from entity_props_stocks.inc, purely for my convenience.
MOVETYPE_NONE = 0,			< never moves
MOVETYPE_ISOMETRIC,			< For players
MOVETYPE_WALK,				< Player only - moving on the ground
MOVETYPE_STEP,				< gravity, special edge handling -- monsters use this
MOVETYPE_FLY,				< No gravity, but still collides with stuff
MOVETYPE_FLYGRAVITY,		< flies through the air + is affected by gravity
MOVETYPE_VPHYSICS,			< uses VPHYSICS for simulation
MOVETYPE_PUSH,				< no clip to world, push and crush
MOVETYPE_NOCLIP,			< No gravity, no collisions, still do velocity/avelocity
MOVETYPE_LADDER,			< Used by players only when going onto a ladder
MOVETYPE_OBSERVER,			< Observer movement, depends on player's observer mode
MOVETYPE_CUSTOM,			< Allows the entity to describe its own physics
*/

//Array to store last movetype, part of Cravenge's tank-bug fix.
MoveType mtLastMoveType[MAXPLAYERS+1];
new Handle:hLadderGunMode = INVALID_HANDLE;

//This following code was taken from Silver's Fireworks plugin. ( https://forums.alliedmods.net/showthread.php?t=153783 )
public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	decl String:sGameName[12];
	GetGameFolderName(sGameName, sizeof(sGameName));
	if( strcmp(sGameName, "left4dead2", false) )
	{
		strcopy(error, err_max, "Plugin only supports Left 4 Dead 2.");
		return APLRes_SilentFailure;
	}
	return APLRes_Success;
}

public Plugin:myinfo = 
{
	name = "[L4D2] Ladder Guns",
	author = "Mel Ennial",
	description = "Allows survivors to use guns, equipment etc. on ladders.",
	version = LG_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=305796"
}
//End import. The irony of using someone else's plugin:myinfo code to put in my own info does not escape me.

public OnPluginStart()
{	
	hLadderGunMode = CreateConVar("ladderguns_mode",
		"1",
		"The Laddergun plugin's current mode. 0 = disabled, 1 = manual (press +use on ladder), 2 = automatic.",
		FCVAR_NOTIFY|FCVAR_REPLICATED);
	CreateConVar("ladderguns_version", LG_VERSION, "The version of the Ladderguns plugin being used.", FCVAR_SPONLY|FCVAR_DONTRECORD);
	
	AutoExecConfig(true, "l4d2_ladderguns");
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
	//If the plugin's been disabled, go home.
	new iMode = GetConVarInt(hLadderGunMode);
	if (LG_MODE_MANUAL > iMode || iMode > LG_MODE_AUTO)
		return Plugin_Continue;
		
	//Only check survivors.
	if (!IsClientInGame(client) || GetClientTeam(client) != 2)
		return Plugin_Continue;
	
	//Thanks Cravenge (again).
	MoveType mtAmbulatoryStyle = GetEntityMoveType(client);
	
	//If the survivor already has their guns drawn while on the ladder, change as soon as they move.
	if (mtAmbulatoryStyle == MOVETYPE_FLY)
	{
		//Cravenge's fix: prevent buggy behaviour if hit by a tank. Version 2b.
		if (mtLastMoveType[client] != MOVETYPE_LADDER) /* fix for tank punches and thrown rocks */
		{
			return Plugin_Continue;
		}
		//End.
		if (IsMoving(client))
		{
			//Survivor has moved! Change their movetype. We need to use MOVETYPE_LADDER on auto mode.
			if (iMode == LG_MODE_MANUAL)
				SetEntityMoveType(client, MOVETYPE_WALK);
			else if (iMode == LG_MODE_AUTO)
				SetEntityMoveType(client, MOVETYPE_LADDER);
		}
		return Plugin_Continue;
	}
	//Now check to see if the survivor is on a ladder. Change to MOVETYPE_FLY if applicable.
	if (mtAmbulatoryStyle == MOVETYPE_LADDER)
	{
		if (iMode == LG_MODE_MANUAL && (buttons & IN_USE))
			SetEntityMoveType(client, MOVETYPE_FLY);
		else if (iMode == LG_MODE_AUTO && !IsMoving(client))
		{
			//Cravenge's fix: prevent buggy behaviour if hit by a tank. Version 2b.
			if (mtLastMoveType[client] == MOVETYPE_FLY) /* fix for never-ending loop when auto mode. */
			{
				return Plugin_Continue;
			}
			//End.
			SetEntityMoveType(client, MOVETYPE_FLY);
		}
	}	
	//Save the last movetype to help stamp out unintended behaviour.
	mtLastMoveType[client] = mtAmbulatoryStyle;	
	return Plugin_Continue;
}

bool:IsMoving(client)
{
	decl Float:fVelocity[3];
	GetEntPropVector(client, Prop_Data, "m_vecAbsVelocity", fVelocity);
	return (GetVectorLength(fVelocity) > 0.0);
}