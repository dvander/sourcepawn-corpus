
/*
	[CS:GO] Disable end match nextmap vote
	30.3.2021

	- Works until Valve update breaks signature
	+ Bonus. Disable end match choreographed scene
		sm_endmatch_choreographed_scene

	https://forums.alliedmods.net/showthread.php?t=331633
	
	ps.
	logic_choreographed_scene is client side entity ?
	
	
	
	https://forums.alliedmods.net/showpost.php?p=2758397&postcount=16
	21.9.2021
	- Removed sm_endmatch_choreographed_scene part from plugin. Maybe DHooks2 Version 2.2.0-detours17 have changed... ?
*/

#include <dhooks>

public Plugin myinfo =
{
	name = "[CS:GO] Disable end match nextmap vote",
	author = "Bacardi",
	description = "Don't bring in-game map vote when mp_endmatch_votenextmap 0",
	version = "21.9.2021",
	url = "https://forums.alliedmods.net/showpost.php?p=2758397&postcount=16"
};


ConVar mp_endmatch_votenextmap;
//ConVar sm_endmatch_choreographed_scene;
Handle hCreateEndMatchMapGroupVoteOptions;
//Handle hcharacterscenes;

public void OnPluginStart()
{

	mp_endmatch_votenextmap = FindConVar("mp_endmatch_votenextmap");
	
	if(mp_endmatch_votenextmap == null) SetFailState("Can't find Console Variable: mp_endmatch_votenextmap");

	//sm_endmatch_choreographed_scene = CreateConVar("sm_endmatch_choreographed_scene", "1.0", "When disabled, show only scoreboard, don't show choreographed scene at end of match", _, true, 0.0, true, 1.0);

	GameData temp = new GameData("csgo_endmatch_votenextmap.games");

	if(temp == null) SetFailState("Why you no has csgo_endmatch_votenextmap.games.txt gamedata?");

	hCreateEndMatchMapGroupVoteOptions = DHookCreateFromConf(temp, "CreateEndMatchMapGroupVoteOptions_function");
	//hcharacterscenes = DHookCreateFromConf(temp, "characterscenes_function");

	delete temp;

	// Fail when DHooks function builded wrong or Signature not work
	if (!DHookEnableDetour(hCreateEndMatchMapGroupVoteOptions, false, CreateEndMatchMapGroupVoteOptions))
		SetFailState("Failed to detour CreateEndMatchMapGroupVoteOptions_function. Fix gamedata file!");

	//if (!DHookEnableDetour(hcharacterscenes, false, characterscenes))
	//	SetFailState("Failed to detour hcharacterscenes. Fix gamedata file!");


	delete hCreateEndMatchMapGroupVoteOptions;
	//delete hcharacterscenes;
}

public MRESReturn CreateEndMatchMapGroupVoteOptions()
{
	// Skip real function.
	if(!mp_endmatch_votenextmap.BoolValue) return MRES_Supercede;


	return MRES_Ignored;
}


//public MRESReturn characterscenes()
//{
//	// Skip real function.
//	if(!sm_endmatch_choreographed_scene.BoolValue) return MRES_Supercede;
//
//	return MRES_Ignored;
//}

