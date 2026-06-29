/*
*	More Screen Blood When Shooting
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



#define PLUGIN_VERSION 		"1.2"

/*======================================================================================
	Plugin Info:

*	Name	:	[L4D2] More Screen Blood When Shooting
*	Author	:	SilverShot
*	Descrp	:	Adds more screen blood when shooting enemies who are nearby.
*	Link	:	https://forums.alliedmods.net/showthread.php?t=334402
*	Plugins	:	https://sourcemod.net/plugins.php?exact=exact&sortby=title&search=1&author=Silvers

========================================================================================
	Change Log:

1.2 (26-Sep-2021)
	- Restricted to weapon and melee damage only. Thanks to "swiftswing1" for reporting.

1.1 (25-Sep-2021)
	- Removed damage type restrictions. All damage will now cause blood splatter including melee weapons.
	- Restriction code left in and commented out, uncomment and recompile if you want to block melee damage.
	- Thanks to "swiftswing1" for reporting.

1.0 (21-Sep-2021)
	- Initial release.

========================================================================================

	This plugin was made using source code from the following plugins.
	If I have used your code and not credited you, please let me know.

*	Thanks to "Lux" for the "TE_SetupParticleAttachment" method and code
	https://github.com/LuxLuma/Lux-Library/blob/master/scripting/include/lux_library.inc

======================================================================================*/

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#define CVAR_FLAGS			FCVAR_NOTIFY


ConVar g_hCvarAllow, g_hCvarMPGameMode, g_hCvarModes, g_hCvarModesOff, g_hCvarModesTog, g_hCvarMultiply, g_hCvarRange, g_hCvarSound, g_hCvarTargets, g_hCvarTypes;
bool g_bCvarAllow, g_bMapStarted, g_bHookedCommon, g_bHookedPlayers;
float g_fLastEmit;

char g_sSounds[6][] =
{
	"player/survivor/splat/zombie_blood_spray_01.wav",
	"player/survivor/splat/zombie_blood_spray_02.wav",
	"player/survivor/splat/zombie_blood_spray_03.wav",
	"player/survivor/splat/zombie_blood_spray_04.wav",
	"player/survivor/splat/zombie_blood_spray_05.wav",
	"player/survivor/splat/zombie_blood_spray_06.wav"
};

char g_sSounds2[3][] =
{
	"player/survivor/splat/blood_spurt1.wav",
	"player/survivor/splat/blood_spurt2.wav",
	"player/survivor/splat/blood_spurt3.wav"
};

/* USING USER MSG VERSION INSTEAD
char g_sParticles[6][] =
{
	"screen_blood_splatter",
	"screen_blood_splatter_a",
	"screen_blood_splatter_b",
	"screen_blood_splatter_melee_b",
	"screen_blood_splatter_melee",
	"screen_blood_splatter_melee_blunt"
};
*/



// ====================================================================================================
//					PLUGIN INFO / START
// ====================================================================================================
public Plugin myinfo =
{
	name = "[L4D2] More Screen Blood When Shooting",
	author = "SilverShot",
	description = "Adds more screen blood when shooting enemies who are nearby.",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=334402"
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
	g_hCvarAllow =			CreateConVar(	"l4d2_more_screen_blood_allow",			"1",				"0=Plugin off, 1=Plugin on.", CVAR_FLAGS );
	g_hCvarModes =			CreateConVar(	"l4d2_more_screen_blood_modes",			"",					"Turn on the plugin in these game modes, separate by commas (no spaces). (Empty = all).", CVAR_FLAGS );
	g_hCvarModesOff =		CreateConVar(	"l4d2_more_screen_blood_modes_off",		"",					"Turn off the plugin in these game modes, separate by commas (no spaces). (Empty = none).", CVAR_FLAGS );
	g_hCvarModesTog =		CreateConVar(	"l4d2_more_screen_blood_modes_tog",		"0",				"Turn on the plugin in these game modes. 0=All, 1=Coop, 2=Survival, 4=Versus, 8=Scavenge. Add numbers together.", CVAR_FLAGS );
	g_hCvarMultiply =		CreateConVar(	"l4d2_more_screen_blood_multiply",		"1",				"How many blood overlays to send at once. The higher the number the more blood shows on the screen at once.", CVAR_FLAGS, true, 1.0, true, 5.0 );
	g_hCvarRange =			CreateConVar(	"l4d2_more_screen_blood_range",			"100",				"How near an enemy is required when shot for blood to spray on the screen.", CVAR_FLAGS );
	g_hCvarSound =			CreateConVar(	"l4d2_more_screen_blood_sound",			"1",				"0=Off. 1=Play a blood spray sound to everyone nearby.", CVAR_FLAGS );
	g_hCvarTargets =		CreateConVar(	"l4d2_more_screen_blood_targets",		"7",				"Who triggers the blood effect. 1=Common Infected. 2=Survivors. 4=Special Infected. Add numbers together.", CVAR_FLAGS );
	g_hCvarTypes =			CreateConVar(	"l4d2_more_screen_blood_types",			"2",				"1=Display effect to person shooting only. 2=Display to everyone nearby.", CVAR_FLAGS );
	CreateConVar(							"l4d2_more_screen_blood_version",		PLUGIN_VERSION,		"More Screen Blood When Shooting plugin version.", FCVAR_NOTIFY|FCVAR_DONTRECORD);
	AutoExecConfig(true,					"l4d2_more_screen_blood");

	g_hCvarMPGameMode = FindConVar("mp_gamemode");
	g_hCvarMPGameMode.AddChangeHook(ConVarChanged_Allow);
	g_hCvarModes.AddChangeHook(ConVarChanged_Allow);
	g_hCvarModesOff.AddChangeHook(ConVarChanged_Allow);
	g_hCvarModesTog.AddChangeHook(ConVarChanged_Allow);
	g_hCvarAllow.AddChangeHook(ConVarChanged_Allow);
	g_hCvarTargets.AddChangeHook(ConVarChanged_Cvars);
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
	HookUnhookEvents();
}

void HookUnhookEvents()
{
	// Ugly checks, it'll do.
	if( g_bCvarAllow && !g_bHookedCommon && g_hCvarTargets.IntValue & 1 )
	{
		g_bHookedCommon = true;
		HookEvent("infected_hurt", Event_InfectedHurt);
	}

	if( g_bCvarAllow && !g_bHookedPlayers && (g_hCvarTargets.IntValue & 2 || g_hCvarTargets.IntValue & 4) )
	{
		g_bHookedPlayers = true;
		HookEvent("player_hurt", Event_PlayerHurt);
	}

	if( g_bHookedCommon && (!g_bCvarAllow || g_hCvarTargets.IntValue & 1 == 0) )
	{
		g_bHookedCommon = false;
		UnhookEvent("infected_hurt", Event_InfectedHurt);
	}

	if( g_bHookedPlayers && (!g_bCvarAllow || (g_hCvarTargets.IntValue & 2 == 0 && g_hCvarTargets.IntValue & 4 == 0)) )
	{
		g_bHookedPlayers = false;
		UnhookEvent("player_hurt", Event_PlayerHurt);
	}
}

void IsAllowed()
{
	bool bCvarAllow = g_hCvarAllow.BoolValue;
	bool bAllowMode = IsAllowedGameMode();

	if( g_bCvarAllow == false && bCvarAllow == true && bAllowMode == true )
	{
		g_bCvarAllow = true;

		HookUnhookEvents();
	}

	else if( g_bCvarAllow == true && (bCvarAllow == false || bAllowMode == false) )
	{
		g_bCvarAllow = false;

		HookUnhookEvents();
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
		if( entity != -1 )
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
//					FUNCTION
// ====================================================================================================
public void OnMapStart()
{
	for( int i = 0; i < sizeof(g_sSounds); i++ )
		PrecacheSound(g_sSounds[i]);

	for( int i = 0; i < sizeof(g_sSounds2); i++ )
		PrecacheSound(g_sSounds2[i]);

	/* USING USER MSG VERSION INSTEAD
	for( int i = 0; i < sizeof(g_sParticles); i++ )
		PrecacheParticle(g_sParticles[i]);
	*/

	g_bMapStarted = true;
}

public void OnMapEnd()
{
	g_bMapStarted = false;
	g_fLastEmit = 0.0;
}


public void Event_PlayerHurt(Event event, const char[] name, bool dontBroadcast)
{
	int type = event.GetInt("type");
	if( !(type & (DMG_CLUB|DMG_BULLET|DMG_SLASH)) ) return; // Ignore non weapon damage

	int target = GetClientOfUserId(event.GetInt("userid"));
	if( target )
	{
		int team = GetClientTeam(target);
		if( (team == 2 && g_hCvarTargets.IntValue & 2) || (team == 3 && g_hCvarTargets.IntValue & 4) )
		{
			BloodSprayLogic(target, event);
		}
	}
}

public void Event_InfectedHurt(Event event, const char[] name, bool dontBroadcast)
{
	int type = event.GetInt("type");
	if( !(type & (DMG_CLUB|DMG_BULLET|DMG_SLASH)) ) return; // Ignore non weapon damage

	int target = event.GetInt("entityid");
	if( target )
	{
		BloodSprayLogic(target, event);
	}
}

void BloodSprayLogic(int target, Event event)
{
	// Get position and targets
	static float vPos[3], vLoc[3];
	GetEntPropVector(target, Prop_Data, "m_vecOrigin", vLoc);

	static int clients[MAXPLAYERS+1];
	int numClients;
	int client;

	if( g_hCvarTypes.IntValue == 1 )
	{
		client = event.GetInt("attacker");
		if( client && (client = GetClientOfUserId(client)) )
		{
			GetClientAbsOrigin(client, vPos);
			if( GetVectorDistance(vPos, vLoc) <= g_hCvarRange.FloatValue )
			{
				numClients = 1;
			}
		}
	}
	else
	{
		for( int i = 1; i <= MaxClients; i++ )
		{
			if( IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i) && !IsFakeClient(i) )
			{
				GetClientAbsOrigin(i, vPos);
				if( GetVectorDistance(vPos, vLoc) <= g_hCvarRange.FloatValue )
				{
					clients[numClients++] = i;
				}
			}
		}
	}

	if( numClients )
	{
		// ====================
		// SOUND
		// ====================
		if( g_hCvarSound.IntValue && GetGameTime() - g_fLastEmit >= 0.2 )
		{
			int i = GetRandomInt(0, sizeof(g_sSounds) - 1);
			int x = GetRandomInt(0, sizeof(g_sSounds2) - 1);

			if( g_hCvarSound.IntValue )
			{
				EmitSoundToAll(g_sSounds[i], target, SNDCHAN_AUTO, SNDLEVEL_DISHWASHER);
				EmitSoundToAll(g_sSounds2[x], target, SNDCHAN_AUTO, SNDLEVEL_DISHWASHER, _, _, SNDPITCH_HIGH);
			}
		}



		// ====================
		// EFFECT
		// ====================
		// /* USER MSG VERSION - Can overflow when too many are sent at once, causing client(s) disconnect. Less network usage.
		int max = g_hCvarMultiply.IntValue;
		for( int i = 1; i <= max; i++ )
		{
			SendBloodUserMessage(client, clients, numClients);
		}
		// */



		/* TEMP ENT  VERSION - Can increase network usage, but no risk of clients disconnecting.
		int type = GetRandomInt(0, sizeof(g_sParticles) - 1);
		int iParticleStringIndex = GetParticleIndex(g_sParticles[type]);

		if( g_hCvarTypes.IntValue == 1 )
		{
			TE_SetupParticleAttachment(iParticleStringIndex, 1, client, true);
		}
		else
		{
			int index;

			for( int i = 0; i < numClients; i++ )
			{
				index = clients[i];

				TE_SetupParticleAttachment(iParticleStringIndex, 1, index, true);
				TE_SendToClient(index);
			}
		}
		// */
	}
}

void SendBloodUserMessage(int client, int clients[MAXPLAYERS+1], int numClients)
{
	Handle msg;

	if( g_hCvarTypes.IntValue == 1 )
	{
		msg = StartMessageOne("MeleeSlashSplatter", client, USERMSG_RELIABLE|USERMSG_BLOCKHOOKS); // USERMSG_BLOCKHOOKS because we want to avoid triggering "Blood Screen Effect Block" plugin
	} else {

		msg = StartMessage("MeleeSlashSplatter", clients, numClients, USERMSG_RELIABLE|USERMSG_BLOCKHOOKS); // USERMSG_BLOCKHOOKS because we want to avoid triggering "Blood Screen Effect Block" plugin
	}

	BfWriteByte(msg, 1);
	EndMessage();
}



// ====================================================================================================
//					PARTICLES METHOD
// ====================================================================================================
stock int PrecacheParticle(const char[] sEffectName)
{
	static int table = INVALID_STRING_TABLE;
	if( table == INVALID_STRING_TABLE )
	{
		table = FindStringTable("ParticleEffectNames");
	}

	int index = FindStringIndex(table, sEffectName);
	if( index == INVALID_STRING_INDEX )
	{
		bool save = LockStringTables(false);
		AddToStringTable(table, sEffectName);
		LockStringTables(save);
		index = FindStringIndex(table, sEffectName);
	}

	return index;
}

/**
 * Sets up a particle effect's attachment.
 *
 * @param iParticleIndex 	Particle index.
 * @param sAttachmentName	Name of attachment.
 * @param iEntIndex		Entity index of the particle.
 * @param bFollow		True to make the particle follow attachment points, false otherwise.
 *
 * @error			Invalid effect index.
 **/
stock void TE_SetupParticleAttachment(int iParticleIndex, int iAttachmentIndex, int iEntIndex, bool bFollow=false)
{
	static float vecDummy[3]={0.0, 0.0, 0.0};
	static EngineVersion IsEngine;
	if(IsEngine == Engine_Unknown)
		IsEngine = GetEngineVersion();

	TE_Start("EffectDispatch");

	TE_WriteFloat(IsEngine == Engine_Left4Dead2 ? "m_vOrigin.x"	:"m_vOrigin[0]", vecDummy[0]);
	TE_WriteFloat(IsEngine == Engine_Left4Dead2 ? "m_vOrigin.y"	:"m_vOrigin[1]", vecDummy[1]);
	TE_WriteFloat(IsEngine == Engine_Left4Dead2 ? "m_vOrigin.z"	:"m_vOrigin[2]", vecDummy[2]);
	TE_WriteFloat(IsEngine == Engine_Left4Dead2 ? "m_vStart.x"	:"m_vStart[0]", vecDummy[0]);
	TE_WriteFloat(IsEngine == Engine_Left4Dead2 ? "m_vStart.y"	:"m_vStart[1]", vecDummy[1]);
	TE_WriteFloat(IsEngine == Engine_Left4Dead2 ? "m_vStart.z"	:"m_vStart[2]", vecDummy[2]);

	static int iEffectIndex = INVALID_STRING_INDEX;
	if(iEffectIndex < 0)
	{
		iEffectIndex = __FindStringIndex2(FindStringTable("EffectDispatch"), "ParticleEffect");
		if(iEffectIndex == INVALID_STRING_INDEX)
			SetFailState("Unable to find EffectDispatch/ParticleEffect indexes");
	}

	TE_WriteNum("m_iEffectName", iEffectIndex);
	TE_WriteNum("m_nHitBox", iParticleIndex);
	TE_WriteNum("entindex", iEntIndex);
	TE_WriteNum("m_nAttachmentIndex", iAttachmentIndex);
	TE_WriteNum("m_fFlags", 1);	//needed for attachments to work

	TE_WriteVector("m_vAngles", vecDummy);
	TE_WriteFloat("m_flMagnitude", 0.0);
	TE_WriteFloat("m_flScale", 1.0);
	TE_WriteFloat("m_flRadius", 0.0);

	if(IsEngine == Engine_Left4Dead2)
	{
		TE_WriteNum("m_nDamageType", bFollow ? 5 : 4);
	}
	else
	{
		TE_WriteNum("m_nDamageType", bFollow ? 4 : 3);
	}
}

/**
 * Gets a particle system index or late precaches it.
 * Note: Cache particle systems in OnMapStart() with Precache_Particle_System to avoid them spewing errors.
 *
 * @param sParticleName		Name of the particle system.
 *
 * @return			The particle system index or INVALID_STRING_INDEX on error.
 * @error			Invalid particle stringtable index.
 **/
stock int GetParticleIndex(char[] sParticleName)
{
	static int iParticleTableid = INVALID_STRING_TABLE;
	if(iParticleTableid == INVALID_STRING_TABLE)
	{
		iParticleTableid = FindStringTable("ParticleEffectNames");
		if(iParticleTableid == INVALID_STRING_TABLE)
			SetFailState("Failed to find 'ParticleEffectNames' stringtable.");
	}

	int iParticleStringIndex = __FindStringIndex2(iParticleTableid, sParticleName);
	if(iParticleStringIndex == INVALID_STRING_INDEX)
	{
		iParticleStringIndex = PrecacheParticle(sParticleName);
	}
	return iParticleStringIndex;
}

//Credit smlib https://github.com/bcserv/smlib
/**
 * Rewrite of FindStringIndex, which failed to work correctly in previous tests.
 * Searches for the index of a given string in a stringtable.
 *
 * @param tableidx		Stringtable index.
 * @param str			String to find.
 * @return			The string index or INVALID_STRING_INDEX on error.
 **/
static stock int __FindStringIndex2(int tableidx, const char[] str)
{
	static char buf[1024];

	int numStrings = GetStringTableNumStrings(tableidx);
	for (int i=0; i < numStrings; i++) {
		ReadStringTable(tableidx, i, buf, sizeof(buf));

		if (StrEqual(buf, str)) {
			return i;
		}
	}

	return INVALID_STRING_INDEX;
}