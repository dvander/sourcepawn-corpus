/*
*	Hud Splatter
*	Copyright (C) 2022 Silvers
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



#define PLUGIN_VERSION		"1.5"

/*======================================================================================
	Plugin Info:

*	Name	:	[L4D2] Hud Splatter
*	Author	:	SilverShot
*	Descp	:	Splat effects on players screen.
*	Link	:	https://forums.alliedmods.net/showthread.php?t=137445
*	Plugins	:	https://sourcemod.net/plugins.php?exact=exact&sortby=title&search=1&author=Silvers

========================================================================================
	Change Log:

1.5 (11-Dec-2022)
	- Changes to fix compile warnings on SourceMod 1.11.

1.4 (21-Sep-2021)
	- Fixed targeting single or multiple people being flipped.
	- Fixed missing translations when targeting players.

1.3 (20-Jul-2021)
	- Added feature to target individual clients. Thanks to "Lux" for the "TE_SetupParticleAttachment" method and code.
	- Changed command "sm_splat" to allow targeting clients.
	- Menu still displays the effects to everyone.

1.2 (10-May-2020)
	- Added PrecacheParticle function.
	- Various changes to tidy up code.

1.1 (05-May-2018)
	- Converted plugin source to the latest syntax utilizing methodmaps. Requires SourceMod 1.8 or newer.

1.0 (05-Sep-2010)
	- Initial release.

========================================================================================

	This plugin was made using source code from the following plugins.
	If I have used your code and not credited you, please let me know.

*	Thanks to "L. Duke" for " TF2 Particles via TempEnts" tutorial
	https://forums.alliedmods.net/showthread.php?t=75102

*	Thanks to "Muridias" for updating "L. Duke"s code
	https://forums.alliedmods.net/showpost.php?p=836836&postcount=28

*	Thanks to "Lux" for the "TE_SetupParticleAttachment" method and code
	https://github.com/LuxLuma/Lux-Library/blob/master/scripting/include/lux_library.inc
	
======================================================================================*/

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

char g_Particles[19][] =
{
	"screen_adrenaline",					// Adrenaline
	"screen_adrenaline_b",
	"screen_hurt",
	"screen_hurt_b",
	"screen_blood_splatter",				// Blood
	"screen_blood_splatter_a",
	"screen_blood_splatter_b",
	"screen_blood_splatter_melee_b",
	"screen_blood_splatter_melee",
	"screen_blood_splatter_melee_blunt",
	"smoker_screen_effect",					// Infected
	"smoker_screen_effect_b",
	"screen_mud_splatter",
	"screen_mud_splatter_a",
	"screen_bashed",						// Misc
	"screen_bashed_b",
	"screen_bashed_d",
	"burning_character_screen",
	"storm_lightning_screenglow"
	// boomer_vomit_screeneffect			// Doesn't work :(
};

ConVar g_hAllow;
bool g_bCvarAllow;
Handle g_hTimerStop[MAXPLAYERS+1];



// ====================================================================================================
//					PLUGIN INFO / START / END
// ====================================================================================================
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

public Plugin myinfo =
{
	name = "[L4D2] Hud Splatter",
	author = "SilverShot",
	description = "Splat effects on players screen.",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=137445"
}

public void OnPluginStart()
{
	LoadTranslations("common.phrases");

	// Cvars
	g_hAllow = CreateConVar("l4d2_hud_splatter",	"1",				"0=Disables plugin, 1=Enables plugin", FCVAR_NOTIFY);
	CreateConVar("l4d2_hud_splatter_version",		PLUGIN_VERSION,		"Hud Splatter plugin version.", FCVAR_NOTIFY|FCVAR_DONTRECORD);
	AutoExecConfig(true, "l4d2_hud_splatter");

	g_hAllow.AddChangeHook(ConVarChanged_Enable);
	g_bCvarAllow = g_hAllow.BoolValue;

	// Console Commands
	RegAdminCmd("sm_splat_menu",	Command_SplatMenu,	ADMFLAG_KICK,	"Splat menu.");
	RegAdminCmd("sm_splat",			Command_Splatter,	ADMFLAG_KICK,	"Usage: sm_splat <#userid|name> <1-19>");
}

void ConVarChanged_Enable(Handle convar, const char[] oldValue, const char[] newValue)
{
	g_bCvarAllow = g_hAllow.BoolValue;
}

public void OnMapStart()
{
	for( int i = 0; i < sizeof(g_Particles); i++ )
	{
		PrecacheParticle(g_Particles[i]);
	}
}



// ====================================================================================================
//					SPLAT
// ====================================================================================================
void SplatPlayer(int client, int type, bool bAffectAll)
{
	int iParticleStringIndex = GetParticleIndex(g_Particles[type]);
	if( iParticleStringIndex == INVALID_STRING_INDEX )
	{
		return;
	}

	// OLD METHOD:
	// AttachParticle(client, g_Particles[type]);

	// NEW METHOD
	TE_SetupParticleAttachment(iParticleStringIndex, 1, client, true);
	if( bAffectAll )
		TE_SendToAll();
	else
		TE_SendToClient(client);

	if( type < 4 )
	{
		if( bAffectAll )
		{
			delete g_hTimerStop[0];
			g_hTimerStop[0] = CreateTimer(10.0, TimerStop, 0);
		} else {
			delete g_hTimerStop[client];
			g_hTimerStop[client] = CreateTimer(10.0, TimerStop, GetClientUserId(client));
		}
	}
}

Action TimerStop(Handle timer, any client)
{
	if( client )
	{
		client = GetClientOfUserId(client);
		if( client && IsClientInGame(client) )
		{
			TE_SetupStopAllParticles(client);
			TE_SendToClient(client);
			g_hTimerStop[client] = null;
		}
	} else {
		for( int i = 1; i <= MaxClients; i++ )
		{
			if( IsClientInGame(i) )
			{
				TE_SetupStopAllParticles(i);
				TE_SendToClient(i);
			}
		}

		g_hTimerStop[client] = null;
	}

	return Plugin_Continue;
}

public void OnClientDisconnect(int client)
{
	delete g_hTimerStop[client];
}



// ====================================================================================================
//					COMMANDs
// ====================================================================================================
Action Command_SplatMenu(int client, int args)
{
	if( g_bCvarAllow ) Menu_Select(client);
	return Plugin_Handled;
}

Action Command_Splatter(int client, int args)
{
	if( !g_bCvarAllow ) return Plugin_Handled;

	if( args != 2 )
	{
		ReplyToCommand(client, "Usage: sm_splat <#userid|name> <1-19>");
		return Plugin_Handled;
	}

	// Type
	char arg2[4];
	GetCmdArg(2, arg2, sizeof(arg2));
	int type = StringToInt(arg2);

	if( type < 1 || type > 19 )
	{
		ReplyToCommand(client, "Usage: sm_splat <#userid|name> <1-19>");
		return Plugin_Handled;
	}

	// Target
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
		0,
		target_name,
		sizeof(target_name),
		tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}

	// Do
	int target;
	for( int i = 0; i < target_count; i++ )
	{
		target = target_list[i];

		SplatPlayer(target, type -1, false);
	}

	return Plugin_Handled;
}



// ====================================================================================================
//					MENU MAIN
// ====================================================================================================
// 1. Menu_Select
void Menu_Select(int client)
{
	Menu menu = new Menu(MenuHandler_Select);
	menu.SetTitle("Select Splatter (Affects everyone):");

	menu.AddItem("1", "Adrenaline");
	menu.AddItem("2", "Blood");
	menu.AddItem("3", "Infected");
	menu.AddItem("4", "Miscellaneous");

	menu.ExitButton = true;
	menu.Display(client, 60);
}

int MenuHandler_Select(Menu menu, MenuAction action, int param1, int param2)
{
	if( action == MenuAction_End ) return 0;

	if( action == MenuAction_Select )
	{
		switch( param2 )
		{
			case 0: Menu_Adren(param1);
			case 1: Menu_Blood(param1);
			case 2: Menu_Infected(param1);
			case 3: Menu_Misc(param1);
		}
	}

	return 0;
}



// ====================================================================================================
//					MENUS SELECT
// ====================================================================================================
// Adrenaline
void Menu_Adren(int client)
{
	Menu menu = new Menu(MenuHandler_Adren);
	menu.SetTitle("Adrenaline Edges");

	menu.AddItem("1", "Adrenaline (red)");
	menu.AddItem("2", "Adrenaline (dark)");
	menu.AddItem("3", "Hurt (red)");
	menu.AddItem("4", "Hurt (dark)");

	menu.ExitBackButton = true;
	menu.Display(client, 60);
}

int MenuHandler_Adren(Menu menu, MenuAction action, int param1, int param2)
{
	if( action == MenuAction_End )
	{
		delete menu;
	}
	else if( action == MenuAction_Cancel )
	{
		Menu_Select(param1);
	}
	else if( action == MenuAction_Select )
	{
		Menu_Adren(param1);
		SplatPlayer(param1, param2, true);
	}

	return 0;
}

// Blood
void Menu_Blood(int client)
{
	Menu menu = new Menu(MenuHandler_Blood);
	menu.SetTitle("Blood Splatter");

	menu.AddItem("1", "Edge Faded");
	menu.AddItem("2", "Center Big");
	menu.AddItem("3", "Center Small");
	menu.AddItem("4", "Center (melee)");
	menu.AddItem("5", "Edge Big (melee)");
	menu.AddItem("6", "Edge Small (melee)");

	menu.ExitBackButton = true;
	menu.Display(client, 60);
}

int MenuHandler_Blood(Menu menu, MenuAction action, int param1, int param2)
{
	if( action == MenuAction_End )
	{
		delete menu;
	}
	else if( action == MenuAction_Cancel )
	{
		Menu_Select(param1);
	}
	else if( action == MenuAction_Select )
	{
		Menu_Blood(param1);
		SplatPlayer(param1, param2 + 4, true);
	}

	return 0;
}

// Infected
void Menu_Infected(int client)
{
	Menu menu = new Menu(MenuHandler_Infected);
	menu.SetTitle("Infected");

	menu.AddItem("1", "Water (Smoker FX)");
	menu.AddItem("2", "Flakes (Smoker FX)");
	menu.AddItem("3", "Mud Splatter 1");
	menu.AddItem("4", "Mud Splatter 2");

	menu.ExitBackButton = true;
	menu.Display(client, 60);
}

int MenuHandler_Infected(Menu menu, MenuAction action, int param1, int param2)
{
	if( action == MenuAction_End )
	{
		delete menu;
	}
	else if( action == MenuAction_Cancel )
	{
		Menu_Select(param1);
	}
	else if( action == MenuAction_Select )
	{
		Menu_Infected(param1);
		SplatPlayer(param1, param2 + 10, true);
	}

	return 0;
}

// Misc
void Menu_Misc(int client)
{
	Menu menu = new Menu(MenuHandler_Misc);
	menu.SetTitle("Miscellaneous");

	menu.AddItem("1", "Big Bash");
	menu.AddItem("2", "Bashed");
	menu.AddItem("3", "Stars");
	menu.AddItem("4", "Flames");
	menu.AddItem("5", "Lightning Flash");

	menu.ExitBackButton = true;
	menu.Display(client, 60);
}

int MenuHandler_Misc(Menu menu, MenuAction action, int param1, int param2)
{
	if( action == MenuAction_End )
	{
		delete menu;
	}
	else if( action == MenuAction_Cancel )
	{
		Menu_Select(param1);
	}
	else if( action == MenuAction_Select )
	{
		Menu_Misc(param1);
		SplatPlayer(param1, param2 + 14, true);
	}

	return 0;
}



// ====================================================================================================
//					PARTICLES
// ====================================================================================================
int PrecacheParticle(const char[] sEffectName)
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
 * Stops all particle effects emitted on an entity, such as attachment followers.
 * Note: Currently no way to target particles.
 *
 * @param iEntIndex		Entity index to stop all particles from emitting on.
 *
 * @error			Invalid effect index.
 **/
void TE_SetupStopAllParticles(int iEntIndex)
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
		iEffectIndex = __FindStringIndex2(FindStringTable("EffectDispatch"), "ParticleEffectStop");
		if(iEffectIndex == INVALID_STRING_INDEX)
			SetFailState("Unable to find EffectDispatch/ParticleEffectStop indexes");
	}

	TE_WriteNum("m_iEffectName", iEffectIndex);
	TE_WriteNum("m_nHitBox", 0);

	TE_WriteNum("entindex", iEntIndex);
	TE_WriteNum("m_nAttachmentIndex", 0);
	TE_WriteNum("m_fFlags", 1);
	TE_WriteVector("m_vAngles", vecDummy);
	TE_WriteFloat("m_flMagnitude", 0.0);
	TE_WriteFloat("m_flScale", 0.0);
	TE_WriteFloat("m_flRadius", 0.0);
	TE_WriteNum("m_nDamageType", 0);
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
int GetParticleIndex(char[] sParticleName)
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
int __FindStringIndex2(int tableidx, const char[] str)
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

// OLD METHOD:
/*
stock void AttachParticle(int client, char[] particleType)
{
    int entity = CreateEntityByName("info_particle_system");

    if( IsValidEdict(entity) )
    {
		DispatchKeyValue(entity, "effect_name", particleType);
		DispatchSpawn(entity)

		SetVariantString("!activator");
		AcceptEntityInput(entity, "SetParent", client);

		ActivateEntity(entity);
		AcceptEntityInput(entity, "start");

		SetVariantString("OnUser1 !self:Kill::10.0:1");
		AcceptEntityInput(entity, "AddOutput");
		AcceptEntityInput(entity, "FireUser1");

    }
}
*/