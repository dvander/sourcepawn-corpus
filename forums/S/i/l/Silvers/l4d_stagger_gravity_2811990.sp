/*
*	Stagger Animation - Gravity Allowed
*	Copyright (C) 2023 Silvers
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



#define PLUGIN_VERSION 		"1.3"

/*======================================================================================
	Plugin Info:

*	Name	:	[L4D & L4D2] Stagger Animation - Gravity Allowed
*	Author	:	SilverShot
*	Descrp	:	Allows gravity when players are staggering, otherwise they would float in the air until the animation completes. Also allows staggering over a ledge and falling.
*	Link	:	https://forums.alliedmods.net/showthread.php?t=344297
*	Plugins	:	https://sourcemod.net/plugins.php?exact=exact&sortby=title&search=1&author=Silvers

========================================================================================
	Change Log:

1.3 (24-Nov-2023)
	- Changes to prevent shoving and shooting/shoving/moving whilst stumbling. Thanks to "ProjectSky" for reporting.
	- Fixed possibly creating the "info_gamemode" entity before map start, depending on cvars.
	- Fixed unhook event errors when turning the plugin off.

1.2 (23-Nov-2023)
	- Fixed the plugin sometimes crashing the server on map change. Thanks to "chungocanh12" for reporting.

1.1 (07-Nov-2023)
	- Changed method of getting stagger duration. Reading memory was from the old test version, better to use GetEntDataFloat.

1.0 (25-Oct-2023)
	- Initial release.

0.1 (08-Dec-2022)
	- Initial creation.

======================================================================================*/


#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <left4dhooks>

#define CVAR_FLAGS			FCVAR_NOTIFY
#define BLOCK_TIME			0.3		// How long to block shooting/shoving/moving when staggering


ConVar g_hCvarAllow, g_hCvarMPGameMode, g_hCvarModes, g_hCvarModesOff, g_hCvarModesTog, g_hCvarAir, g_hCvarCmd, g_hCvarStop, g_hCvarType;
bool g_bCvarAllow, g_bMapStarted, g_bRoundStarted, g_bLeft4Dead2;
int g_iCvarAir, g_iCvarCmd, g_iCvarStop, g_iCvarType, g_iClassTank;

bool g_bStagger[MAXPLAYERS+1], g_bFrameStagger[MAXPLAYERS+1], g_bBlockXY[MAXPLAYERS+1];
float g_vStart[MAXPLAYERS+1][3], g_fDist[MAXPLAYERS+1], g_fTtime[MAXPLAYERS+1], g_fTimeBlock[MAXPLAYERS+1];



// ====================================================================================================
//					PLUGIN INFO / START / END
// ====================================================================================================
public Plugin myinfo =
{
	name = "[L4D & L4D2] Stagger Animation - Gravity Allowed",
	author = "SilverShot",
	description = "Allows gravity when players are staggering, otherwise they would float in the air until the animation completes. Also allows staggering over a ledge and falling.",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=344297"
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

public void OnAllPluginsLoaded()
{
    if( GetFeatureStatus(FeatureType_Native, "Left4DHooks_Version") != FeatureStatus_Available || Left4DHooks_Version() < 1139 )
		SetFailState("\n==========\nThis plugin requires 'Left 4 DHooks' version 1.139 or newer. Please update that plugin.\n==========");
}

public void OnPluginStart()
{
	g_hCvarAllow = CreateConVar(		"l4d_stagger_gravity_allow",		"1",			"0=Plugin off, 1=Plugin on.", CVAR_FLAGS );
	g_hCvarModes = CreateConVar(		"l4d_stagger_gravity_modes",		"",				"Turn on the plugin in these game modes, separate by commas (no spaces). (Empty = all).", CVAR_FLAGS );
	g_hCvarModesOff = CreateConVar(		"l4d_stagger_gravity_modes_off",	"",				"Turn off the plugin in these game modes, separate by commas (no spaces). (Empty = none).", CVAR_FLAGS );
	g_hCvarModesTog = CreateConVar(		"l4d_stagger_gravity_modes_tog",	"0",			"Turn on the plugin in these game modes. 0=All, 1=Coop, 2=Survival, 4=Versus, 8=Scavenge. Add numbers together.", CVAR_FLAGS );
	g_hCvarAir =		CreateConVar(	"l4d_stagger_gravity_air",			"255",			"Allow staggering when in the air for these types: 1=Survivors, 2=Smoker, 4=Boomer, 8=Hunter, 16=Spitter, 32=Jockey, 64=Charger, 128=Tank, 255=All.", CVAR_FLAGS );
	g_hCvarCmd =		CreateConVar(	"l4d_stagger_gravity_cmd",			"1",			"When using the command should players: 1=Stagger backwards. 2=Stagger forwards. 3=Stagger in random direction.", CVAR_FLAGS );
	g_hCvarStop =		CreateConVar(	"l4d_stagger_gravity_stop",			"0",			"Stop staggering after falling off a ledge for these types: 1=Survivors, 2=Smoker, 4=Boomer, 8=Hunter, 16=Spitter, 32=Jockey, 64=Charger, 128=Tank, 255=All.", CVAR_FLAGS );
	g_hCvarType =		CreateConVar(	"l4d_stagger_gravity_type",			"255",			"Enable gravity when staggering for these types: 1=Survivors, 2=Smoker, 4=Boomer, 8=Hunter, 16=Spitter, 32=Jockey, 64=Charger, 128=Tank, 255=All.", CVAR_FLAGS );
	CreateConVar(						"l4d_stagger_gravity_version",		PLUGIN_VERSION,	"Stagger Animation - Gravity Allowed plugin version.", FCVAR_NOTIFY|FCVAR_DONTRECORD);
	AutoExecConfig(true,				"l4d_stagger_gravity");

	g_hCvarMPGameMode = FindConVar("mp_gamemode");
	g_hCvarMPGameMode.AddChangeHook(ConVarChanged_Allow);
	g_hCvarModes.AddChangeHook(ConVarChanged_Allow);
	g_hCvarModesOff.AddChangeHook(ConVarChanged_Allow);
	g_hCvarModesTog.AddChangeHook(ConVarChanged_Allow);
	g_hCvarAllow.AddChangeHook(ConVarChanged_Allow);
	g_hCvarAir.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarCmd.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarStop.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarType.AddChangeHook(ConVarChanged_Cvars);

	g_iClassTank = g_bLeft4Dead2 ? 8 : 5;

	RegAdminCmd("sm_stagger", CmdStagger, ADMFLAG_ROOT, "[#userid|name] stagger the targeted clients, or no args = self.");

	LoadTranslations("common.phrases");
}



// ====================================================================================================
//					CVARS
// ====================================================================================================
public void OnConfigsExecuted()
{
	IsAllowed();
}

void ConVarChanged_Allow(Handle convar, const char[] oldValue, const char[] newValue)
{
	IsAllowed();
}

void ConVarChanged_Cvars(Handle convar, const char[] oldValue, const char[] newValue)
{
	GetCvars();
}

void GetCvars()
{
	g_iCvarAir = g_hCvarAir.IntValue;
	g_iCvarCmd = g_hCvarCmd.IntValue;
	g_iCvarStop = g_hCvarStop.IntValue;
	g_iCvarType = g_hCvarType.IntValue;
}

void IsAllowed()
{
	bool bCvarAllow = g_hCvarAllow.BoolValue;
	bool bAllowMode = IsAllowedGameMode();
	GetCvars();

	if( g_bCvarAllow == false && bCvarAllow == true && bAllowMode == true )
	{
		g_bCvarAllow = true;
		HookEvent("round_start",	Event_RoundStart, EventHookMode_PostNoCopy);
		HookEvent("round_end",		Event_RoundEnd, EventHookMode_PostNoCopy);
		HookEvent("player_spawn",	Event_PlayerSpawn);
	}

	else if( g_bCvarAllow == true && (bCvarAllow == false || bAllowMode == false) )
	{
		g_bCvarAllow = false;
		UnhookEvent("round_start",	Event_RoundStart, EventHookMode_PostNoCopy);
		UnhookEvent("round_end",	Event_RoundEnd, EventHookMode_PostNoCopy);
		UnhookEvent("player_spawn",	Event_PlayerSpawn);
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

void OnGamemode(const char[] output, int caller, int activator, float delay)
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
//					EVENTS
// ====================================================================================================
public void OnMapStart()
{
	g_bMapStarted = true;
	g_bRoundStarted = true;
}

public void OnMapEnd()
{
	g_bMapStarted = false;
	ResetPlugin();
}

void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	g_bRoundStarted = true;
}

void Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	g_bRoundStarted = false;
	ResetPlugin();
}

void Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	ResetVars(client);
}

void ResetPlugin()
{
	for( int i = 1; i <= MaxClients; i++ )
	{
		ResetVars(i);
	}
}

void ResetVars(int client)
{
	g_bStagger[client] = false;
	g_bFrameStagger[client] = false;
	g_bBlockXY[client] = false;
	g_vStart[client] = view_as<float>({ 0.0, 0.0, 0.0 });
	g_fDist[client] = 0.0;
	g_fTtime[client] = 0.0;
	g_fTimeBlock[client] = 0.0;
}



// ====================================================================================================
//					COMMAND
// ====================================================================================================
Action CmdStagger(int client, int args)
{
	if( !client )
	{
		ReplyToCommand(client, "Command can only be used %s", IsDedicatedServer() ? "in game on a dedicated server." : "in chat on a Listen server.");
		return Plugin_Handled;
	}

	if( args == 0 )
	{
		float vPos[3], vDir[3];
		GetClientAbsOrigin(client, vPos);

		switch( g_iCvarCmd )
		{
			case 1:
			{
				GetClientEyeAngles(client, vDir);
				MoveForward(vPos, vDir, vDir, 50.0);
			}
			case 2:
			{
				GetClientEyeAngles(client, vDir);
				MoveForward(vPos, vDir, vDir, -50.0);
			}
			case 3:
			{
				vDir[1] = GetRandomFloat(-180.0, 180.0);
				MoveForward(vPos, vDir, vDir, 50.0);
			}
		}

		L4D_StaggerPlayer(client, client, vDir);

		return Plugin_Handled;
	}

	char arg1[32];
	GetCmdArg(1, arg1, sizeof(arg1));

	char target_name[MAX_TARGET_LENGTH];
	int target_list[MAXPLAYERS], target_count;
	bool tn_is_ml;

	if( (target_count = ProcessTargetString(
		arg1,
		client,
		target_list,
		MAXPLAYERS,
		COMMAND_FILTER_ALIVE,
		target_name,
		sizeof(target_name),
		tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}

	int target;
	float vPos[3], vDir[3];

	for( int i = 0; i < target_count; i++ )
	{
		target = target_list[i];

		GetClientAbsOrigin(target, vPos);

		switch( g_iCvarCmd )
		{
			case 1:
			{
				GetClientEyeAngles(target, vDir);
				MoveForward(vPos, vDir, vDir, 50.0);
			}
			case 2:
			{
				GetClientEyeAngles(target, vDir);
				MoveForward(vPos, vDir, vDir, -50.0);
			}
			case 3:
			{
				vDir[1] = GetRandomFloat(-180.0, 180.0);
				MoveForward(vPos, vDir, vDir, 50.0);
			}
		}

		L4D_StaggerPlayer(client, target, vDir);
	}

	return Plugin_Handled;
}

void MoveForward(const float vPos[3], const float vAng[3], float vReturn[3], float fDistance)
{
	float vDir[3];
	GetAngleVectors(vAng, vDir, NULL_VECTOR, NULL_VECTOR);
	vReturn = vPos;
	vReturn[0] += vDir[0] * fDistance;
	vReturn[1] += vDir[1] * fDistance;
}



// ====================================================================================================
//					FORWARDS
// ====================================================================================================
public Action L4D_OnMotionControlledXY(int client, int activity)
{
	if( !g_bCvarAllow || !g_bRoundStarted ) return Plugin_Continue;

	int class = -1;

	// Verify allowed
	if( g_iCvarType != 255 )
	{
		if( GetClientTeam(client) == 3 )
		{
			class = GetEntProp(client, Prop_Send, "m_zombieClass");
			if( class == g_iClassTank ) class = 7;
		}
		else
		{
			class = 0;
		}

		if( !(g_iCvarType & (1 << class)) ) return Plugin_Continue;
	}

	// Verify air stagger
	if( GetEntPropEnt(client, Prop_Send, "m_hGroundEntity") == -1 )
	{
		g_bBlockXY[client] = true;

		if( g_iCvarAir != 255 )
		{
			if( class == -1 )
			{
				if( GetClientTeam(client) == 3 )
				{
					class = GetEntProp(client, Prop_Send, "m_zombieClass");
					if( class == g_iClassTank ) class = 7;
				}
				else
				{
					class = 0;
				}
			}

			if( !(g_iCvarAir & (1 << class)) ) return Plugin_Continue;
		}

		SetAttack(client);
		g_bStagger[client] = true;
		return Plugin_Handled;
	}
	else
	{
		if( g_bStagger[client] )
		{
			float vPos[3];
			GetClientAbsOrigin(client, vPos);
			GetEntPropVector(client, Prop_Send, "m_staggerStart", g_vStart[client]);

			float dist = GetVectorDistance(g_vStart[client], vPos);
			g_fDist[client] = GetEntPropFloat(client, Prop_Send, "m_staggerDist");
			g_fDist[client] -= dist;

			g_fTtime[client] = GetEntPropFloat(client, Prop_Send, "m_staggerTimer", 1);

			L4D_CancelStagger(client);
			g_bStagger[client] = false;

			// Continue stagger after falling
			if( g_iCvarStop != 255 )
			{
				if( class == -1 )
				{
					if( GetClientTeam(client) == 3 )
					{
						class = GetEntProp(client, Prop_Send, "m_zombieClass");
						if( class == g_iClassTank ) class = 7;
					}
					else
					{
						class = 0;
					}
				}

				if( g_iCvarStop & (1 << class) )
				{
					return Plugin_Continue; // Not allowed
				}
			}

			RequestFrame(OnFrameStagger, GetClientUserId(client));

			SetAttack(client);
			return Plugin_Handled;
		}

		if( g_fTimeBlock[client] == 0.0 )
		{
			g_fTimeBlock[client] = GetGameTime() + 0.5;

			SetAttack(client);
			return Plugin_Handled;
		}

		if( g_fTimeBlock[client] - GetGameTime() > 0.0 )
		{
			SetAttack(client);
			return Plugin_Handled;
		}
	}

	if( g_bBlockXY[client] )
	{
		SetAttack(client);
		return Plugin_Handled;
	}

	return Plugin_Continue;
}

public Action L4D2_OnStagger(int client, int source)
{
	if( !g_bCvarAllow || !g_bRoundStarted ) return Plugin_Continue;

	// Verify air stagger
	if( g_iCvarAir != 255 )
	{
		if( GetEntPropEnt(client, Prop_Send, "m_hGroundEntity") == -1 )
		{
			int class;

			if( GetClientTeam(client) == 3 )
			{
				class = GetEntProp(client, Prop_Send, "m_zombieClass");
				if( class == g_iClassTank ) class = 7;
			}

			if( !(g_iCvarAir & (1 << class)) ) return Plugin_Handled; // Not allowed
		}
	}

	return Plugin_Continue;
}

public void L4D2_OnPounceOrLeapStumble_Post(int client, int attacker)
{
	// Verify air stagger
	if( g_bCvarAllow && g_bRoundStarted && g_iCvarAir )
	{
		if( GetEntPropEnt(client, Prop_Send, "m_hGroundEntity") == -1 )
		{
			int class;

			if( GetClientTeam(client) == 3 )
			{
				class = GetEntProp(client, Prop_Send, "m_zombieClass");
				if( class == g_iClassTank ) class = 7;
			}

			if( g_iCvarAir & (1 << class) )
			{
				L4D_StaggerPlayer(client, attacker, NULL_VECTOR);
			}
		}
	}
}

public Action L4D_OnCancelStagger(int client)
{
	if( !g_bCvarAllow || !g_bRoundStarted ) return Plugin_Continue;

	float starttime = GetEntPropFloat(client, Prop_Send, "m_staggerTimer", 1);

	// Maybe fallen off a ledge that wants to cancel the stagger, block the cancel
	if( g_bFrameStagger[client] )
	{
		g_bFrameStagger[client] = false;
		return Plugin_Handled;
	}

	if( GetGameTime() < starttime )
	{
		// We should still be staggering but maybe fell off a ledge, let it cancel and start stagger again nexxt frame
		g_bStagger[client] = false;

		// Continue stagger after falling
		if( g_iCvarStop != 255 )
		{
			int class;

			if( GetClientTeam(client) == 3 )
			{
				class = GetEntProp(client, Prop_Send, "m_zombieClass");
				if( class == g_iClassTank ) class = 7;
			}

			if( g_iCvarStop & (1 << class) )
			{
				return Plugin_Continue; // Not allowed
			}
		}

		g_bFrameStagger[client] = true;
		RequestFrame(OnFrameStagger, GetClientUserId(client));
	}
	else
	{
		g_bBlockXY[client] = false;
	}

	return Plugin_Continue;
}

public Action OnPlayerRunCmd(int client, int &buttons)
{
	if( g_bCvarAllow && g_bRoundStarted && g_bFrameStagger[client] && buttons & (IN_FORWARD|IN_BACK|IN_MOVELEFT|IN_MOVERIGHT) )
	{
		buttons &= ~IN_FORWARD;
		buttons &= ~IN_BACK;
		buttons &= ~IN_MOVELEFT;
		buttons &= ~IN_MOVERIGHT;
		return Plugin_Changed;
	}

	return Plugin_Continue;
}

void SetAttack(int client)
{
	int weapon;
	weapon = GetPlayerWeaponSlot(client, 0);
	if( weapon != -1 )
	{
		SetEntPropFloat(weapon, Prop_Send, "m_flNextPrimaryAttack", GetGameTime() + BLOCK_TIME);
		SetEntPropFloat(weapon, Prop_Send, "m_flNextSecondaryAttack", GetGameTime() + BLOCK_TIME);
	}

	weapon = GetPlayerWeaponSlot(client, 1);
	if( weapon != -1 )
	{
		SetEntPropFloat(weapon, Prop_Send, "m_flNextPrimaryAttack", GetGameTime() + BLOCK_TIME);
		SetEntPropFloat(weapon, Prop_Send, "m_flNextSecondaryAttack", GetGameTime() + BLOCK_TIME);
	}

	SetEntPropFloat(client, Prop_Send, "m_flNextShoveTime", GetGameTime() + BLOCK_TIME);
	SetEntPropFloat(client, Prop_Send, "m_jumpSupressedUntil", GetGameTime() + BLOCK_TIME);
}

void OnFrameStagger(int client)
{
	client = GetClientOfUserId(client);
	if( client && IsClientInGame(client) )
	{
		L4D_StaggerPlayer(client, client, g_vStart[client]);
		SetEntPropFloat(client, Prop_Send, "m_staggerDist", g_fDist[client]);
		SetEntPropFloat(client, Prop_Send, "m_staggerTimer", g_fTtime[client], 1);
	}
}