#define PLUGIN_VERSION 		"1.2"

/*======================================================================================
	Plugin Info:

*	Name	:	[L4D2] Knife Unlock
*	Author	:	SilverShot, Dr!fter
*	Descrp	:	Unlocks the Knife melee weapon. No addons, no anim glitches and functional give knife command.
*	Link	:	https://forums.alliedmods.net/showthread.php?t=185258
*	Plugins	:	https://sourcemod.net/plugins.php?exact=exact&sortby=title&search=1&author=Silvers

========================================================================================
	Change Log:

1.2 (10-May-2020)
	- Added better error log message when gamedata file is missing.
	- Various changes to tidy up code.

1.1 (05-May-2018)
	- Converted plugin source to the latest syntax utilizing methodmaps. Requires SourceMod 1.8 or newer.

1.0 (15-May-2012)
	- Initial release.

========================================================================================

	This plugin was made using source code from the following plugins.
	If I have used your code and not credited you, please let me know.

*	Thanks to "Dr!fter" for "[EXTENSION] MemPatch" and converting this plugin to use sourcemod based functions.
	https://forums.alliedmods.net/showthread.php?t=172187

======================================================================================*/

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>

#define GAMEDATA			"l4d2_knife_unlock"



public Plugin myinfo =
{
	name = "[L4D2] Knife Unlock",
	author = "SilverShot, Dr!fter",
	description = "Unlocks the Knife melee weapon. No addons, no anim glitches and functional give knife command.",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=185258"
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
	CreateConVar("l4d2_knife_unlock_version", PLUGIN_VERSION, "Knife Unlock version.", FCVAR_NOTIFY|FCVAR_DONTRECORD);

	char sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof(sPath), "gamedata/%s.txt", GAMEDATA);
	if( FileExists(sPath) == false ) SetFailState("\n==========\nMissing required file: \"%s\".\nRead installation instructions again.\n==========", sPath);

	Handle hGameData = LoadGameConfigFile(GAMEDATA);
	if( hGameData == null ) SetFailState("Failed to load \"%s.txt\" gamedata.", GAMEDATA);

	Address patchAddr = GameConfGetAddress(hGameData, "KnifePatch");
	delete hGameData;

	if( patchAddr )
	{
		if( LoadFromAddress(patchAddr, NumberType_Int8) == 0x6B && LoadFromAddress(patchAddr + view_as<Address>(4), NumberType_Int8) == 0x65 )
		{
			StoreToAddress(patchAddr, 0x4B, NumberType_Int8); // K
			StoreToAddress(patchAddr + view_as<Address>(4), 0x61, NumberType_Int8); // a
		}
	}
}