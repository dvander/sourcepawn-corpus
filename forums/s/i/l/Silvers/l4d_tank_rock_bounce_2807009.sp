/*
*	Tank Rock Bounces
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



#define PLUGIN_VERSION 		"1.1"

/*======================================================================================
	Plugin Info:

*	Name	:	[L4D & L4D2] Tank Rock Bounces
*	Author	:	SilverShot
*	Descrp	:	Allows the Tanks thrown rock to bounce off objects.
*	Link	:	https://forums.alliedmods.net/showthread.php?t=343303
*	Plugins	:	https://sourcemod.net/plugins.php?exact=exact&sortby=title&search=1&author=Silvers

========================================================================================
	Change Log:

1.1 (27-Jul-2023)
	- Added cvar "l4d_tank_rock_bounce_chance" to set the chance a rock can bounce. Requested by "Aresilya".

1.0 (10-Jul-2023)
	- Initial release.

========================================================================================
	Thanks:

	This plugin was made using source code from the following plugins.
	If I have used your code and not credited you, please let me know.

*	"asherkin" for " [TF2] RocketBounce" - For the bounce calculations code.
	https://forums.alliedmods.net/showthread.php?t=152173

======================================================================================*/

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <left4dhooks>

#define CVAR_FLAGS			FCVAR_NOTIFY
#define TIME_BOUNCE			0.1


ConVar g_hCvarAllow, g_hCvarMPGameMode, g_hCvarModes, g_hCvarModesOff, g_hCvarModesTog, g_hCvarChance, g_hCvarObjects, g_hCvarRepeat, g_hCvarScale, g_hCvarSpeed;
int g_iCvarChance, g_iCvarRepeat;
float g_fBounce[2048], g_fCvarScale, g_fCvarSpeed;
bool g_bCvarAllow, g_bAllowBounce;
int g_iBounces[2048];
StringMap g_hClassnames;



// ====================================================================================================
//					PLUGIN INFO / START / END
// ====================================================================================================
public Plugin myinfo =
{
	name = "[L4D & L4D2] Tank Rock Bounces",
	author = "SilverShot",
	description = "Allows the Tanks thrown rock to bounce off objects.",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=343303"
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion test = GetEngineVersion();
	if( test != Engine_Left4Dead && test != Engine_Left4Dead2 )
	{
		strcopy(error, err_max, "Plugin only supports Left 4 Dead 1 & 2.");
		return APLRes_SilentFailure;
	}
	return APLRes_Success;
}

public void OnPluginStart()
{
	g_hCvarAllow =		CreateConVar(	"l4d_tank_rock_bounce_allow",		"1",			"0=Plugin off, 1=Plugin on.", CVAR_FLAGS );
	g_hCvarModes =		CreateConVar(	"l4d_tank_rock_bounce_modes",		"",				"Turn on the plugin in these game modes, separate by commas (no spaces). (Empty = all).", CVAR_FLAGS );
	g_hCvarModesOff =	CreateConVar(	"l4d_tank_rock_bounce_modes_off",	"",				"Turn off the plugin in these game modes, separate by commas (no spaces). (Empty = none).", CVAR_FLAGS );
	g_hCvarModesTog =	CreateConVar(	"l4d_tank_rock_bounce_modes_tog",	"0",			"Turn on the plugin in these game modes. 0=All, 1=Coop, 2=Survival, 4=Versus, 8=Scavenge. Add numbers together.", CVAR_FLAGS );
	g_hCvarChance =		CreateConVar(	"l4d_tank_rock_bounce_chance",		"100",			"The chance out of 100 that a rock can bounce.", CVAR_FLAGS );
	g_hCvarObjects =	CreateConVar(	"l4d_tank_rock_bounce_objects",		"prop_dynamic,prop_physics,prop_door_rotating,weapon_gascan",			"Entity classnames the rock can bounce off. World is on by default. Separate by commas (no spaces). Empty = world only.", CVAR_FLAGS );
	g_hCvarRepeat =		CreateConVar(	"l4d_tank_rock_bounce_repeat",		"3",			"Number of times a single rock is allowed to bounce before exploding.", CVAR_FLAGS );
	g_hCvarScale =		CreateConVar(	"l4d_tank_rock_bounce_scale",		"0.75",			"Each bounce will scale the velocity by this much. 1.0 = Bounce at full speed. 0.5 = Half velocity each bounce. 0.2 = Very slow after bounce.", CVAR_FLAGS );
	g_hCvarSpeed =		CreateConVar(	"l4d_tank_rock_bounce_speed",		"400.0",		"Minimum speed the rock must be moving to allow bouncing.", CVAR_FLAGS );
	CreateConVar(						"l4d_tank_rock_bounce_version",		PLUGIN_VERSION, "Tank Rock Bounces plugin version.", FCVAR_NOTIFY|FCVAR_DONTRECORD);
	AutoExecConfig(true,				"l4d_tank_rock_bounce");

	g_hCvarMPGameMode = FindConVar("mp_gamemode");
	g_hCvarMPGameMode.AddChangeHook(ConVarChanged_Allow);
	g_hCvarAllow.AddChangeHook(ConVarChanged_Allow);
	g_hCvarModes.AddChangeHook(ConVarChanged_Allow);
	g_hCvarModesOff.AddChangeHook(ConVarChanged_Allow);
	g_hCvarModesTog.AddChangeHook(ConVarChanged_Allow);
	g_hCvarChance.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarObjects.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarRepeat.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarScale.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarSpeed.AddChangeHook(ConVarChanged_Cvars);
}

public void OnAllPluginsLoaded()
{
	if( Left4DHooks_Version() < 1134 ) // Forwards "L4D_TankRock_BounceTouch*" were only added in 1.134
	{
		SetFailState("This plugin requires \"Left 4 DHooks\" version 1.134 or newer. Please update.");
	}
}

void ResetPlugin()
{
	for( int i = 1; i < 2048; i++ )
	{
		g_iBounces[i] = 0;
		g_fBounce[i] = 0.0;
	}
}

public void OnMapEnd()
{
	ResetPlugin();
}

void Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	ResetPlugin();
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
	delete g_hClassnames;
	g_hClassnames = new StringMap();

	char sTemp[512];
	g_hCvarObjects.GetString(sTemp, sizeof(sTemp));
	if( sTemp[0] )
	{
		StrCat(sTemp, sizeof(sTemp), ",");

		int index, last;
		while( (index = StrContains(sTemp[last], ",")) != -1 )
		{
			sTemp[last + index] = 0;

			g_hClassnames.SetValue(sTemp[last], true);
			sTemp[last + index] = ',';
			last += index + 1;
		}
	}

	g_iCvarChance = g_hCvarChance.IntValue;
	g_iCvarRepeat = g_hCvarRepeat.IntValue;
	g_fCvarScale = g_hCvarScale.FloatValue;
	g_fCvarSpeed = g_hCvarSpeed.FloatValue;
}

void IsAllowed()
{
	bool bCvarAllow = g_hCvarAllow.BoolValue;
	bool bAllowMode = IsAllowedGameMode();
	GetCvars();

	if( g_bCvarAllow == false && bCvarAllow == true && bAllowMode == true )
	{
		g_bCvarAllow = true;

		HookEvent("round_end", Event_RoundEnd, EventHookMode_PostNoCopy);
	}

	else if( g_bCvarAllow == true && (bCvarAllow == false || bAllowMode == false) )
	{
		ResetPlugin();

		g_bCvarAllow = false;

		UnhookEvent("round_end", Event_RoundEnd, EventHookMode_PostNoCopy);
	}
}

int g_iCurrentMode;
public void L4D_OnGameModeChange(int gamemode)
{
	g_iCurrentMode = gamemode;
}

bool IsAllowedGameMode()
{
	if( g_hCvarMPGameMode == null )
		return false;

	if( g_iCurrentMode == 0 ) g_iCurrentMode = L4D_GetGameModeType();

	int iCvarModesTog = g_hCvarModesTog.IntValue;

	if( iCvarModesTog && !(iCvarModesTog & g_iCurrentMode) )
		return false;

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



// ====================================================================================================
//					BOUNCE
// ====================================================================================================
public Action L4D_TankRock_BounceTouch(int tank, int rock, int entity)
{
	if( !g_bCvarAllow ) return Plugin_Continue;

	bool pass;

	if( g_iBounces[rock] < g_iCvarRepeat )
	{
		if( GetGameTime() - g_fBounce[rock] < TIME_BOUNCE ) // Ignore multiple touches
		{
			g_bAllowBounce = true;
			return Plugin_Handled;
		}

		if( g_iCvarChance != 100 && GetRandomInt(0, 100) > g_iCvarChance ) return Plugin_Continue;

		if( entity == 0 )
		{
			pass = true;
		}
		else if( g_hClassnames.Size > 0 )
		{
			char sTemp[64];
			GetEdictClassname(entity, sTemp, sizeof(sTemp));

			if( g_hClassnames.ContainsKey(sTemp) )
			{
				pass = true;
			}
		}

		if( pass )
		{
			float vVelocity[3];
			GetEntPropVector(rock, Prop_Data, "m_vecAbsVelocity", vVelocity);

			// PrintToChatAll("Speed %f", GetVectorLength(vVelocity));

			if( GetVectorLength(vVelocity) > g_fCvarSpeed )
			{
				g_iBounces[rock]++;
				g_bAllowBounce = true;
				g_fBounce[rock] = GetGameTime();
				return Plugin_Handled;
			}
		}
	}

	return Plugin_Continue;
}

public void L4D_TankRock_BounceTouch_Post(int tank, int rock, int entity)
{
	g_iBounces[rock] = 0;
	g_fBounce[rock] = 0.0;
}

public void L4D_TankRock_BounceTouch_PostHandled(int tank, int rock, int entity)
{
	if( !g_bCvarAllow || !g_bAllowBounce ) return;

	float vOrigin[3];
	GetEntPropVector(rock, Prop_Data, "m_vecOrigin", vOrigin);

	float vAngles[3];
	GetEntPropVector(rock, Prop_Data, "m_angRotation", vAngles);

	float vVelocity[3];
	GetEntPropVector(rock, Prop_Data, "m_vecAbsVelocity", vVelocity);

	Handle trace = TR_TraceRayFilterEx(vOrigin, vAngles, MASK_SHOT, RayType_Infinite, TEF_ExcludeEntity, rock);

	if(! TR_DidHit(trace) )
	{
		delete trace;
		return;
	}

	float vNormal[3];
	TR_GetPlaneNormal(trace, vNormal);

	//PrintToServer("Surface Normal: [%.2f, %.2f, %.2f]", vNormal[0], vNormal[1], vNormal[2]);

	delete trace;

	float dotProduct = GetVectorDotProduct(vNormal, vVelocity);

	ScaleVector(vNormal, dotProduct);
	ScaleVector(vNormal, 2.0);

	float vBounceVec[3];
	SubtractVectors(vVelocity, vNormal, vBounceVec);

	float vNewAngles[3];
	GetVectorAngles(vBounceVec, vNewAngles);

	//PrintToServer("Angles: [%.2f, %.2f, %.2f] -> [%.2f, %.2f, %.2f]", vAngles[0], vAngles[1], vAngles[2], vNewAngles[0], vNewAngles[1], vNewAngles[2]);
	//PrintToServer("Velocity: [%.2f, %.2f, %.2f] |%.2f| -> [%.2f, %.2f, %.2f] |%.2f|", vVelocity[0], vVelocity[1], vVelocity[2], GetVectorLength(vVelocity), vBounceVec[0], vBounceVec[1], vBounceVec[2], GetVectorLength(vBounceVec));

	ScaleVector(vBounceVec, g_fCvarScale);
	TeleportEntity(rock, NULL_VECTOR, vNewAngles, vBounceVec);

	MoveForward(vOrigin, vAngles, vOrigin, 5.0); // Move away from object, as it can cause multiple hits and get stuck
	SetEntPropVector(rock, Prop_Data, "m_vecOrigin", vOrigin); // Setting here instead of TeleportEntity that causes a delay to the object in motion

	g_bAllowBounce = false;
}

bool TEF_ExcludeEntity(int entity, int contentsMask, int data)
{
	return (entity != data);
}

void MoveForward(const float vPos[3], const float vAng[3], float vReturn[3], float fDistance)
{
	fDistance *= -1.0;
	float vDir[3];
	GetAngleVectors(vAng, vDir, NULL_VECTOR, NULL_VECTOR);
	vReturn = vPos;
	vReturn[0] += vDir[0] * fDistance;
	vReturn[1] += vDir[1] * fDistance;
}