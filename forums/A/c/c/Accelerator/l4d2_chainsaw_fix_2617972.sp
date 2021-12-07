// #define PLUGIN_VERSION 		"1.0"
#define PLUGIN_VERSION 		"0.1"

/*======================================================================================
	Plugin Info:

*	Name	:	[L4D2] Chainsaw Crash Fixer
*	Author	:	SilverShot
*	Descrp	:	.
*	Plugins	:	http://sourcemod.net/plugins.php?exact=exact&sortby=title&search=1&author=Silvers

========================================================================================
	Change Log:

1.0 (02-Oct-2018)
	- Initial release.

======================================================================================*/

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <dhooks>

#define GAMEDATA			"l4d2_chainsaw_fix"

bool bSoundBlock;

public Plugin myinfo =
{
	name = "[L4D2] Chainsaw Crash Fixer",
	author = "SilverShot",
	description = ".",
	version = PLUGIN_VERSION,
	url = ""
}

public void OnPluginStart()
{
	CreateConVar("chainsaw_fix_version", PLUGIN_VERSION, "Chainsaw Crash Fixer plugin version.", FCVAR_NOTIFY|FCVAR_DONTRECORD);

	// ====================================================================================================
	// Detour
	// ====================================================================================================
	Handle hGamedata = LoadGameConfigFile(GAMEDATA);
	if( hGamedata == null ) SetFailState("Failed to load \"%s.txt\" gamedata.", GAMEDATA);

	Handle hDetourPitch = DHookCreateFromConf(hGamedata, "CSoundPatch::ChangePitch");
	Handle hDetourAttack = DHookCreateFromConf(hGamedata, "CChainsaw::PrimaryAttack");
	Handle hDetourStopAttack = DHookCreateFromConf(hGamedata, "CChainsaw::StopAttack");
	delete hGamedata;

	if( !hDetourPitch )
		SetFailState("Failed to find \"CSoundPatch::ChangePitch\" signature.");

	if( !hDetourAttack )
		SetFailState("Failed to find \"CChainsaw::PrimaryAttack\" signature.");

	if( !hDetourStopAttack )
		SetFailState("Failed to find \"CChainsaw::StopAttack\" signature.");

	if( !DHookEnableDetour(hDetourPitch, false, CSoundPatch_ChangePitch) )
		SetFailState("Failed to detour \"CSoundPatch::ChangePitch\".");

	if( !DHookEnableDetour(hDetourAttack, false, CChainsaw_PrimaryAttack) )
		SetFailState("Failed to detour \"CChainsaw::PrimaryAttack\".");

	if( !DHookEnableDetour(hDetourStopAttack, false, CChainsaw_StopAttack) )
		SetFailState("Failed to detour post \"CChainsaw::StopAttack\".");
}

// ====================================================================================================
// Detour
// ====================================================================================================
public MRESReturn CSoundPatch_ChangePitch(Handle hReturn, Handle hParams)
{
	if (bSoundBlock)
	{
		DHookSetReturn(hReturn, 0);
		return MRES_Supercede;
	}	

	return MRES_Ignored;
}

public MRESReturn CChainsaw_PrimaryAttack(Handle hReturn, Handle hParams)
{
	bSoundBlock = true;
	return MRES_Ignored;
}

public MRESReturn CChainsaw_StopAttack(Handle hReturn, Handle hParams)
{
	bSoundBlock = false;
	return MRES_Ignored;
}
