#define PLUGIN_VERSION 		"1.2"

/*======================================================================================
	Plugin Info:

*	Name	:	[L4D2] Real Zoey Unlock
*	Author	:	SilverShot
*	Descrp	:	Unlocks Zoey. No bugs. No crashes. No fakes. The Real Deal.
*	Link	:	https://forums.alliedmods.net/showthread.php?t=308483
*	Plugins	:	https://sourcemod.net/plugins.php?exact=exact&sortby=title&search=1&author=Silvers

========================================================================================
	Change Log:

1.2 (10-May-2020)
	- Added better error log message when gamedata file is missing.
	- Changed command "sm_zoe" to allow targeting other players.
	- Various changes to tidy up code.

1.1.1 (22-June-2018)
	- Restricted to Windows only.

1.1 (22-June-2018)
	- Changed to support any future game updates without breaking.

1.0 (21-June-2018)
	- Initial release.

======================================================================================*/
/*
	0	server.dll + 0x201f55		UTIL_PlayerByIndex									<< Crash
	1	server.dll + 0x25481e		SurvivorResponseCachedInfo (windows splits in 2)	<< Patch call
	2	server.dll + 0x258598		SurvivorResponseCachedInfo::Update(int a1)			_ZN26SurvivorResponseCachedInfo6UpdateEv
	3	server.dll + 0x268398		CDirector::Update(void)								_ZN9CDirector6UpdateEv
*/

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>

#define GAMEDATA			"l4d2_zoey_unlock"
#define MODEL_ZOEY			"models/survivors/survivor_teenangst.mdl"



public Plugin myinfo =
{
	name = "[L4D2] Zoey Unlock",
	author = "SilverShot",
	description = "Unlocks Zoey. No bugs. No crashes. No fakes. The Real Deal.",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=308483"
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	if( GetEngineVersion() != Engine_Left4Dead2 )
	{
		strcopy(error, err_max, "Plugin only supports Left 4 Dead 2.");
		return APLRes_SilentFailure;
	}
	return APLRes_Success;
}

public void OnPluginStart()
{
	char sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof(sPath), "gamedata/%s.txt", GAMEDATA);
	if( FileExists(sPath) == false ) SetFailState("\n==========\nMissing required file: \"%s\".\nRead installation instructions again.\n==========", sPath);

	Handle hGameData = LoadGameConfigFile(GAMEDATA);
	if( hGameData == null ) SetFailState("Failed to load \"%s.txt\" gamedata.", GAMEDATA);

	int offset = GameConfGetOffset(hGameData, "ZoeyUnlock_Offset");
	if( offset == -1 ) SetFailState("Plugin is for Windows only.");
	Address patch = GameConfGetAddress(hGameData, "ZoeyUnlock");
	delete hGameData;

	if( !patch ) SetFailState("Error finding the 'ZoeyUnlock' signature.");

	int byte = LoadFromAddress(patch + view_as<Address>(offset), NumberType_Int8);
	if( byte == 0xE8 )
	{
		for( int i = 0; i < 5; i++ )
			StoreToAddress(patch + view_as<Address>(offset + i), 0x90, NumberType_Int8);
	}
	else if( byte != 0x90 )
	{
		SetFailState("Error: the 'ZoeyUnlock_Offset' is incorrect.");
	}

	CreateConVar("l4d2_zoey_unlock_version", PLUGIN_VERSION, "Zoey Unlock plugin version.", FCVAR_NOTIFY|FCVAR_DONTRECORD);
	RegAdminCmd("sm_zoe", sm_zoe, ADMFLAG_ROOT, "Changes your survivor character into Zoey.");
}

public void OnMapStart()
{
	PrecacheModel(MODEL_ZOEY);
}

public Action sm_zoe(int client, int args)
{
	if( args )
	{
		char arg1[32], target_name[MAX_TARGET_LENGTH];
		GetCmdArg(1, arg1, sizeof(arg1));

		int target_list[MAXPLAYERS], target_count;
		bool tn_is_ml;

		if( (target_count = ProcessTargetString(
			arg1,
			client,
			target_list,
			MAXPLAYERS,
			COMMAND_FILTER_ALIVE, /* Only allow alive players */
			target_name,
			sizeof(target_name),
			tn_is_ml)) <= 0 )
		{
			ReplyToTargetError(client, target_count);
			return Plugin_Handled;
		}

		int team;
		for( int i = 0; i < target_count; i++ )
		{
			team = GetClientTeam(target_list[i]);
			if( team == 2 )
			{
				SetEntityModel(target_list[i], MODEL_ZOEY);
				SetEntProp(target_list[i], Prop_Send, "m_survivorCharacter", 5);
			}
		}
		client = 0;
	}

	if( client && GetClientTeam(client) == 2 )
	{
		SetEntityModel(client, MODEL_ZOEY);
		SetEntProp(client, Prop_Send, "m_survivorCharacter", 5);
	}
	return Plugin_Handled;
}