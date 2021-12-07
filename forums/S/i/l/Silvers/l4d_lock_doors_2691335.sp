/*
*	Lock Doors
*	Copyright (C) 2021 Silvers
*
*	This program is free software: you can redistribute it and/or modify
*	it under the terms of the GNU General Public License as published by
*	the Free Software Foundation, either version 3 of the License, or
*	(at your option) any later version.
*
*	This program is distributed in the hope that it will be useful,
*	but WITHOUT ANY WARRANTY; without even the implied warranty of
*	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
*	GNU General Public License for more details.
*
*	You should have received a copy of the GNU General Public License
*	along with this program.  If not, see <https://www.gnu.org/licenses/>.
*/



#define PLUGIN_VERSION 		"1.4"

/*=======================================================================================
	Plugin Info:

*	Name	:	[L4D & L4D2] Lock Doors
*	Author	:	SilverShot
*	Descrp	:	Replicates an old feature Valve removed, allowing players to lock and unlock doors. Also sets open/closed/locked doors health.
*	Link	:	https://forums.alliedmods.net/showthread.php?t=322899
*	Plugins	:	https://sourcemod.net/plugins.php?exact=exact&sortby=title&search=1&author=Silvers

========================================================================================
	Change Log:

1.4 (21-Jun-2021)
	- Added door handle animation and sound when attempting to open a locked door. Requested by "The Renegadist".

1.3 (18-Aug-2020)
	- Added cvar "l4d_lock_doors_range" to set the distance players must be to lock or unlock doors.

1.2 (10-May-2020)
	- Extra checks to prevent "IsAllowedGameMode" throwing errors.
	- Various changes to tidy up code.

1.1 (08-Apr-2020)
	- Changed the lock sound and increased volume.
	- Fixed server start or when the plugin was enabled again. Thanks to "Cuba" for reporting.

1.0 (07-Apr-2020)
	- Initial release.

======================================================================================*/

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#define CVAR_FLAGS			FCVAR_NOTIFY
#define SOUND_LOCK			"doors/default_locked.wav" // door_lock_1
#define SOUND_LOCKED		"doors/latchlocked2.wav"
#define SOUND_UNLOCK		"doors/door_latch3.wav"


ConVar g_hCvarAllow, g_hCvarMPGameMode, g_hCvarModes, g_hCvarModesOff, g_hCvarModesTog, g_hCvarHealthL, g_hCvarHealthO, g_hCvarHealthS, g_hCvarHealthT, g_hCvarKeys, g_hCvarRange, g_hCvarText, g_hCvarVoca;
float g_fCvarHealthL, g_fCvarHealthO, g_fCvarHealthS, g_fCvarRange;
int g_iCvarKeys, g_iCvarText, g_iCvarVoca, g_iCvarHealthT;

bool g_bCvarAllow, g_bMapStarted, g_bLeft4Dead2;
float g_fLastUse[MAXPLAYERS+1];
int g_iDoors[2048];


// Vocalize for Left 4 Dead 2
static const char g_Coach[][] =
{
	"closethedoor01", "closethedoor02", "closethedoor03", "closethedoor04", "closethedoor05", "closethedoor06", "closethedoorc101", "closethedoorc102"
};
static const char g_Ellis[][] =
{
	"closethedoor01", "closethedoor02", "closethedoor03", "closethedoorc101", "closethedoorc102"
};
static const char g_Nick[][] =
{
	"closethedoor01", "closethedoor02", "closethedoor03", "closethedoor04", "closethedoor05", "closethedoor06", "closethedoor07", "closethedoor08", "closethedoor09", "closethedoorc101", "closethedoorc102"
};
static const char g_Rochelle[][] =
{
	"closethedoor01", "closethedoor02", "closethedoor03", "closethedoor04", "closethedoor05", "closethedoorc101", "closethedoorc102", "closethedoorc103", "closethedoorc104", "closethedoorc105"
};

// Vocalize for Left 4 Dead
static const char g_Bill[][] =
{
	"closethedoor01", "closethedoor02", "closethedoor03", "closethedoor04", "closethedoor05", "closethedoor06", "closethedoor07", "closethedoor08", "closethedoor09", "closethedoor10", "closethedoor11", "closethedoor12", "closethedoor13"
};
static const char g_Francis[][] =
{
	"closethedoor01", "closethedoor02", "closethedoor03", "closethedoor04", "closethedoor05", "closethedoor06", "closethedoor07", "closethedoor08", "closethedoor09", "closethedoor10", "closethedoor11", "closethedoor12"
};
static const char g_Louis[][] =
{
	"closethedoor01", "closethedoor02", "closethedoor03", "closethedoor04", "closethedoor05", "closethedoor06", "closethedoor07"
};
static const char g_Zoey[][] =
{
	"closethedoor01", "closethedoor07", "closethedoor08", "closethedoor11", "closethedoor16", "closethedoor17", "closethedoor19", "closethedoor22", "closethedoor28", "closethedoor29", "closethedoor33", "closethedoor41", "closethedoor42", "closethedoor45", "closethedoor50"
};



// ====================================================================================================
//					PLUGIN INFO / START / END
// ====================================================================================================
public Plugin myinfo =
{
	name = "[L4D & L4D2] Lock Doors",
	author = "SilverShot",
	description = "Replicates an old feature Valve removed, allowing players to lock and unlock doors.",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=322899"
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion test = GetEngineVersion();

	if( test == Engine_Left4Dead ) g_bLeft4Dead2 = false;
	else if( test == Engine_Left4Dead2 ) g_bLeft4Dead2 = true;
	else
	{
		strcopy(error, err_max, "Plugin only supports Left 4 Dead 1 & 2.");
		return APLRes_SilentFailure;
	}

	return APLRes_Success;
}

public void OnPluginStart()
{
	g_hCvarAllow =		CreateConVar("l4d_lock_doors_allow",			"1",				"0=Plugin off, 1=Plugin on.", CVAR_FLAGS );
	g_hCvarModes =		CreateConVar("l4d_lock_doors_modes",			"",					"Turn on the plugin in these game modes, separate by commas (no spaces). (Empty = all).", CVAR_FLAGS );
	g_hCvarModesOff =	CreateConVar("l4d_lock_doors_modes_off",		"",					"Turn off the plugin in these game modes, separate by commas (no spaces). (Empty = none).", CVAR_FLAGS );
	g_hCvarModesTog =	CreateConVar("l4d_lock_doors_modes_tog",		"0",				"Turn on the plugin in these game modes. 0=All, 1=Coop, 2=Survival, 4=Versus, 8=Scavenge. Add numbers together.", CVAR_FLAGS );
	g_hCvarHealthL =	CreateConVar("l4d_lock_doors_health_lock",		"2.0",				"0=Off. Percentage of health to set when the door is locked.", CVAR_FLAGS );
	g_hCvarHealthO =	CreateConVar("l4d_lock_doors_health_open",		"0.5",				"0=Off. Percentage of health to set when the door is open.", CVAR_FLAGS );
	g_hCvarHealthS =	CreateConVar("l4d_lock_doors_health_shut",		"1.0",				"0=Off. Percentage of health to set when the door is shut.", CVAR_FLAGS );
	g_hCvarHealthT =	CreateConVar("l4d_lock_doors_health_total",		"840",				"0=Off. How much health doors have on spawn (840 game default).", CVAR_FLAGS );
	g_hCvarKeys =		CreateConVar("l4d_lock_doors_keys",				"1",				"Which key combination to lock/unlock doors: 1=Shift (walk) + E (use). 2=Ctrl (duck) + E (use).", CVAR_FLAGS );
	g_hCvarRange =		CreateConVar("l4d_lock_doors_range",			"150",				"0=Any distance. How close a player must be to the door they're trying to lock or unlock.", CVAR_FLAGS );
	g_hCvarText =		CreateConVar("l4d_lock_doors_text",				"7",				"0=Off. Display a chat message when: 1=Locking doors. 2=Unlocking doors. 4=To self. 8=To all players. Add numbers together.", CVAR_FLAGS );
	g_hCvarVoca =		CreateConVar("l4d_lock_doors_vocalize",			"1",				"0=Off. 1=-Vocalize when locking doors.", CVAR_FLAGS );
	CreateConVar(					"l4d_lock_doors_version",			PLUGIN_VERSION,		"Lock Doors plugin version.", FCVAR_NOTIFY|FCVAR_DONTRECORD);
	AutoExecConfig(true,			"l4d_lock_doors");

	g_hCvarMPGameMode = FindConVar("mp_gamemode");
	g_hCvarMPGameMode.AddChangeHook(ConVarChanged_Allow);
	g_hCvarModes.AddChangeHook(ConVarChanged_Allow);
	g_hCvarModesOff.AddChangeHook(ConVarChanged_Allow);
	g_hCvarModesTog.AddChangeHook(ConVarChanged_Allow);
	g_hCvarAllow.AddChangeHook(ConVarChanged_Allow);
	g_hCvarHealthL.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarHealthO.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarHealthS.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarHealthT.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarKeys.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarText.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarRange.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarVoca.AddChangeHook(ConVarChanged_Cvars);
}



// ====================================================================================================
//					CVARS
// ====================================================================================================
public void OnConfigsExecuted()
{
	IsAllowed();
}

public void ConVarChanged_Allow(Handle convar, const char[] oldValue, const char[] newValue)
{
	IsAllowed();
}

public void ConVarChanged_Cvars(Handle convar, const char[] oldValue, const char[] newValue)
{
	GetCvars();
}

void GetCvars()
{
	g_fCvarHealthL = g_hCvarHealthL.FloatValue;
	g_fCvarHealthO = g_hCvarHealthO.FloatValue;
	g_fCvarHealthS = g_hCvarHealthS.FloatValue;
	g_iCvarHealthT = g_hCvarHealthT.IntValue;
	g_iCvarKeys = g_hCvarKeys.IntValue;
	g_iCvarText = g_hCvarText.IntValue;
	g_fCvarRange = g_hCvarRange.FloatValue;
	g_iCvarVoca = g_hCvarVoca.IntValue;
}

void IsAllowed()
{
	bool bCvarAllow = g_hCvarAllow.BoolValue;
	bool bAllowMode = IsAllowedGameMode();
	GetCvars();

	if( g_bCvarAllow == false && bCvarAllow == true && bAllowMode == true )
	{
		g_bCvarAllow = true;

		ResetPlugin();
		SearchForDoors();

		HookEvent("round_start",	Event_RoundStart);
	}

	else if( g_bCvarAllow == true && (bCvarAllow == false || bAllowMode == false) )
	{
		g_bCvarAllow = false;

		UnhookEvent("round_start",	Event_RoundStart);
	}
}

int g_iCurrentMode;
bool IsAllowedGameMode()
{
	if( g_hCvarMPGameMode == null )
		return false;

	int iCvarModesTog = g_hCvarModesTog.IntValue;
	if( iCvarModesTog != 0 )
	{
		if( g_bMapStarted == false )
			return false;

		g_iCurrentMode = 0;

		int entity = CreateEntityByName("info_gamemode");
		if( IsValidEntity(entity) )
		{
			DispatchSpawn(entity);
			HookSingleEntityOutput(entity, "OnCoop", OnGamemode, true);
			HookSingleEntityOutput(entity, "OnSurvival", OnGamemode, true);
			HookSingleEntityOutput(entity, "OnVersus", OnGamemode, true);
			HookSingleEntityOutput(entity, "OnScavenge", OnGamemode, true);
			ActivateEntity(entity);
			AcceptEntityInput(entity, "PostSpawnActivate");
			if( IsValidEntity(entity) ) // Because sometimes "PostSpawnActivate" seems to kill the ent.
				RemoveEdict(entity); // Because multiple plugins creating at once, avoid too many duplicate ents in the same frame
		}

		if( g_iCurrentMode == 0 )
			return false;

		if( !(iCvarModesTog & g_iCurrentMode) )
			return false;
	}

	char sGameModes[64], sGameMode[64];
	g_hCvarMPGameMode.GetString(sGameMode, sizeof(sGameMode));
	Format(sGameMode, sizeof(sGameMode), ",%s,", sGameMode);

	g_hCvarModes.GetString(sGameModes, sizeof(sGameModes));
	if( sGameModes[0] )
	{
		Format(sGameModes, sizeof(sGameModes), ",%s,", sGameModes);
		if( StrContains(sGameModes, sGameMode, false) == -1 )
			return false;
	}

	g_hCvarModesOff.GetString(sGameModes, sizeof(sGameModes));
	if( sGameModes[0] )
	{
		Format(sGameModes, sizeof(sGameModes), ",%s,", sGameModes);
		if( StrContains(sGameModes, sGameMode, false) != -1 )
			return false;
	}

	return true;
}

public void OnGamemode(const char[] output, int caller, int activator, float delay)
{
	if( strcmp(output, "OnCoop") == 0 )
		g_iCurrentMode = 1;
	else if( strcmp(output, "OnSurvival") == 0 )
		g_iCurrentMode = 2;
	else if( strcmp(output, "OnVersus") == 0 )
		g_iCurrentMode = 4;
	else if( strcmp(output, "OnScavenge") == 0 )
		g_iCurrentMode = 8;
}



// ====================================================================================================
//					DOOR STUFF
// ====================================================================================================
void SearchForDoors()
{
	int entity = -1;

	while( (entity = FindEntityByClassname(entity, "prop_door_rotating")) != INVALID_ENT_REFERENCE )
	{
		if( GetEntProp(entity, Prop_Data, "m_bLocked") == 0 )
		{
			g_iDoors[entity] = EntIndexToEntRef(entity);

			// Hooks
			HookSingleEntityOutput(entity, "OnFullyOpen", Door_Movement);
			HookSingleEntityOutput(entity, "OnFullyClosed", Door_Movement);

			// Health
			SetDoorHealth(entity, true);
		}
	}
}

void SetDoorHealth(int entity, bool spawned = false)
{
	bool closed;
	int health;

	if( spawned && g_iCvarHealthT )				health = g_iCvarHealthT;
	else										health = GetEntProp(entity, Prop_Data, "m_iHealth");

	if( spawned )
	{
		if( g_iCvarHealthT )					SetEntProp(entity, Prop_Data, "m_iHealth", g_iCvarHealthT);
	}
	else if( g_fCvarHealthO || g_fCvarHealthS )
	{
		closed = GetEntProp(entity, Prop_Data, "m_eDoorState") == 0;

		if( closed && g_fCvarHealthS )			SetEntProp(entity, Prop_Data, "m_iHealth", RoundFloat(health * (g_fCvarHealthS * 2)));
		else if( !closed && g_fCvarHealthO )	SetEntProp(entity, Prop_Data, "m_iHealth", RoundFloat(health * g_fCvarHealthO));
	}
}

public void Door_Movement(const char[] output, int caller, int activator, float delay)
{
	SetDoorHealth(caller);
}



// ====================================================================================================
//					EVENTS
// ====================================================================================================
public void OnEntityCreated(int entity, const char[] classname)
{
	if( g_bCvarAllow && strcmp(classname, "prop_door_rotating") == 0 )
	{
		SDKHook(entity, SDKHook_SpawnPost, SpawnPost);
	}
}

void SpawnPost(int entity)
{
	if( GetEntProp(entity, Prop_Data, "m_bLocked") == 0 )
	{
		g_iDoors[entity] = EntIndexToEntRef(entity);

		// Hooks
		HookSingleEntityOutput(entity, "OnFullyOpen", Door_Movement);
		HookSingleEntityOutput(entity, "OnFullyClosed", Door_Movement);

		// SetVariantString("OnLockedUse !self:SetAnimation:KnobTurnFail:0:-1");
		// AcceptEntityInput(entity, "AddOutput");

			// static int aa;
			// SetVariantString("OnLockedUse silvers_point_cmd:Command:say test:0:-1");
			// AcceptEntityInput(entity, "AddOutput");

			// Testing outputs
			// if( aa == 0 )
			// {
				// entity = CreateEntityByName("point_servercommand");
				// DispatchKeyValue(entity, "targetname", "silvers_point_cmd");
				// DispatchSpawn(entity);
			// }

		// Health
		SetDoorHealth(entity, true);
	}
}

public Action Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	ResetPlugin();
}

public void OnMapStart()
{
	g_bMapStarted = true;

	PrecacheSound(SOUND_LOCK);
	PrecacheSound(SOUND_LOCKED);
	PrecacheSound(SOUND_UNLOCK);
}

public void OnMapEnd()
{
	g_bMapStarted = false;

	ResetPlugin();
}

void ResetPlugin()
{
	for( int i = 0; i <= MaxClients; i++ )
	{
		g_fLastUse[i] = 0.0;
	}

	// Don't reset, because OnEntityCreated uses this and sets reference anyway.
	// for( int i = 0; i < 2048; i++ )
	// {
		// g_iDoors[i] = 0;
	// }
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon)
{
	if( g_bCvarAllow && buttons & IN_USE && GetGameTime() > g_fLastUse[client] )
	{
		if( GetClientTeam(client) == 2 && IsPlayerAlive(client) )
		{
			int entity = GetClientAimTarget(client, false);
			if( entity > MaxClients && g_iDoors[entity] == EntIndexToEntRef(entity) )
			{
				// Door not rotating
				if( GetEntProp(entity, Prop_Data, "m_eDoorState") == 0 )
				{
					// Range text
					if( g_fCvarRange )
					{
						float vPos[3], vEnd[3];
						GetClientAbsOrigin(client, vPos);
						GetEntPropVector(entity, Prop_Data, "m_vecOrigin", vEnd);
						if( GetVectorDistance(vPos, vEnd) > g_fCvarRange ) return;
					}

					// Door locked
					if( GetEntProp(entity, Prop_Data, "m_bLocked") )
					{
						// Attempting to lock/unlock
						if( ((g_iCvarKeys == 1 && buttons & IN_SPEED) || (g_iCvarKeys == 2 && buttons & IN_DUCK)) )
						{
							// Text
							if( g_iCvarText & 2 )
							{
								if( g_iCvarText & 4 )			PrintToChatAll("\x04%N \x01unlocked a door", client);
								else if( g_iCvarText & 8 )		PrintToChat(client, "\x04%N \x01unlocked a door", client);
							}

							// Sound
							PlaySound(entity, 2);

							// Action
							AcceptEntityInput(entity, "InputUnlock");
							SetEntProp(entity, Prop_Data, "m_bLocked", 0);
							ChangeEdictState(entity, 0);

							// Health
							int health = GetEntProp(entity, Prop_Data, "m_iHealth");
							SetEntProp(entity, Prop_Data, "m_iHealth", RoundFloat(health / g_fCvarHealthL) / 2); // Divided by 2 because the door opens and triggers movement hook, which doubles the health thinking it was just closed.

							// Prevent opening
							RequestFrame(OnOpen, EntIndexToEntRef(entity));
						// Pressing use, attempting to open a locked door
						} else {
							PlaySound(entity, 3);

							g_fLastUse[client] = GetGameTime() + 0.3;

							static char model[64];
							GetEntPropString(entity, Prop_Data, "m_ModelName", model, sizeof(model));
							if( strcmp(model, "models/props_downtown/metal_door_112.mdl") && strncmp(model, "models/props_doors/shack", 24) ) // These doors have no animation
							{
								SetVariantString("KnobTurnFail");
								AcceptEntityInput(entity, "SetAnimation");
							}

							return;
						}
					}
					// Not locked
					else
					{
						if( ((g_iCvarKeys == 1 && buttons & IN_SPEED) || (g_iCvarKeys == 2 && buttons & IN_DUCK)) )
						{
							// Text
							if( g_iCvarText & 1 )
							{
								if( g_iCvarText & 4 )			PrintToChatAll("\x04%N \x01locked a door", client);
								else if( g_iCvarText & 8 )		PrintToChat(client, "\x043%N \x01locked a door", client);
							}

							// Sound, vocalize
							if( g_iCvarVoca )
							{
								PlayVocalize(client);
							}

							PlaySound(entity, 1);

							// Action
							AcceptEntityInput(entity, "InputLock");
							SetEntProp(entity, Prop_Data, "m_bLocked", 1);
							ChangeEdictState(entity, 0);

							// Health
							int health = GetEntProp(entity, Prop_Data, "m_iHealth");
							SetEntProp(entity, Prop_Data, "m_iHealth", RoundFloat(health * g_fCvarHealthL));
						}
					}
				}
			}
		}

		g_fLastUse[client] = GetGameTime() + 0.3; // Avoid spamming resources
	}
}

void OnOpen(int entity)
{
	if( EntRefToEntIndex(entity) != INVALID_ENT_REFERENCE )
		AcceptEntityInput(entity, "Close");
}

void PlaySound(int entity, int type)
{
	EmitSoundToAll(type == 1 ? SOUND_LOCK : type == 2 ? SOUND_UNLOCK : SOUND_LOCKED, entity, SNDCHAN_AUTO, type == 1 ? SNDLEVEL_AIRCRAFT : SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_NORMAL, -1, NULL_VECTOR, NULL_VECTOR, true, 0.0);
}



// ====================================================================================================
//					VOCALIZE SCENE
// ====================================================================================================
void PlayVocalize(int client)
{
	// Declare variables
	int surv, max;
	static char model[40];

	// Get survivor model
	GetEntPropString(client, Prop_Data, "m_ModelName", model, sizeof(model));

	switch( model[29] )
	{
		case 'c': { Format(model, sizeof(model), "coach");		surv = 1; }
		case 'b': { Format(model, sizeof(model), "gambler");	surv = 2; }
		case 'h': { Format(model, sizeof(model), "mechanic");	surv = 3; }
		case 'd': { Format(model, sizeof(model), "producer");	surv = 4; }
		case 'v': { Format(model, sizeof(model), "NamVet");		surv = 5; }
		case 'e': { Format(model, sizeof(model), "Biker");		surv = 6; }
		case 'a': { Format(model, sizeof(model), "Manager");	surv = 7; }
		case 'n': { Format(model, sizeof(model), "TeenGirl");	surv = 8; }
		default:
		{
			int character = GetEntProp(client, Prop_Send, "m_survivorCharacter");

			if( g_bLeft4Dead2 )
			{
				switch( character )
				{
					case 0:	{ Format(model, sizeof(model), "gambler");		surv = 2; } // Nick
					case 1:	{ Format(model, sizeof(model), "producer");		surv = 4; } // Rochelle
					case 2:	{ Format(model, sizeof(model), "coach");		surv = 1; } // Coach
					case 3:	{ Format(model, sizeof(model), "mechanic");		surv = 3; } // Ellis
					case 4:	{ Format(model, sizeof(model), "NamVet");		surv = 5; } // Bill
					case 5:	{ Format(model, sizeof(model), "TeenGirl");		surv = 8; } // Zoey
					case 6:	{ Format(model, sizeof(model), "Biker");		surv = 6; } // Francis
					case 7:	{ Format(model, sizeof(model), "Manager");		surv = 7; } // Louis
				}
			} else {
				switch( character )
				{
					case 0:	 { Format(model, sizeof(model) ,"TeenGirl");	surv = 8; } // Zoey
					case 1:	 { Format(model, sizeof(model) ,"NamVet");		surv = 5; } // Bill
					case 2:	 { Format(model, sizeof(model) ,"Biker");		surv = 6; } // Francis
					case 3:	 { Format(model, sizeof(model) ,"Manager");		surv = 7; } // Louis
				}
			}
		}
	}

	// Failed for some reason? Should never happen.
	if( surv == 0 )
		return;

	// Lock
	switch( surv )
	{
		case 1: max = sizeof(g_Coach);		// Coach
		case 2: max = sizeof(g_Nick);		// Nick
		case 3: max = sizeof(g_Ellis);		// Ellis
		case 4: max = sizeof(g_Rochelle);	// Rochelle
		case 5: max = sizeof(g_Bill);		// Bill
		case 6: max = sizeof(g_Francis);	// Francis
		case 7: max = sizeof(g_Louis);		// Louis
		case 8: max = sizeof(g_Zoey);		// Zoey
	}

	// Random number
	int random = GetRandomInt(0, max - 1);

	// Select random vocalize
	static char sTemp[40];
	switch( surv )
	{
		case 1: Format(sTemp, sizeof(sTemp), g_Coach[random]);
		case 2: Format(sTemp, sizeof(sTemp), g_Nick[random]);
		case 3: Format(sTemp, sizeof(sTemp), g_Ellis[random]);
		case 4: Format(sTemp, sizeof(sTemp), g_Rochelle[random]);
		case 5: Format(sTemp, sizeof(sTemp), g_Bill[random]);
		case 6: Format(sTemp, sizeof(sTemp), g_Francis[random]);
		case 7: Format(sTemp, sizeof(sTemp), g_Louis[random]);
		case 8: Format(sTemp, sizeof(sTemp), g_Zoey[random]);
	}

	// Create scene location and call
	Format(sTemp, sizeof(sTemp), "scenes/%s/%s.vcd", model, sTemp);
	VocalizeScene(client, sTemp);
}

// Taken from:
// [Tech Demo] L4D2 Vocalize ANYTHING
// https://forums.alliedmods.net/showthread.php?t=122270
// author = "AtomicStryker"
void VocalizeScene(int client, const char[] scenefile)
{
	int entity = CreateEntityByName("instanced_scripted_scene");
	DispatchKeyValue(entity, "SceneFile", scenefile);
	DispatchSpawn(entity);
	SetEntPropEnt(entity, Prop_Data, "m_hOwner", client);
	ActivateEntity(entity);
	AcceptEntityInput(entity, "Start", client, client);
}