//========================================================================//
//I take no credit for this code, this code was provided to me by ivailosp//
//========================================================================//

#include <sourcemod>
 
public Plugin:myinfo =
{
	name = "maxplayersaddon",
	author = "Me",
	description = "Allows 8 players per team in versus mode and perhaps other modes as well",
	version = "1.0.0.0",
	url = "http://www.sourcemod.net/"
};
 
public OnPluginStart()
{
	// Perform one-time startup tasks ...

new Handle:surv_l = FindConVar("survivor_limit");
SetConVarBounds(surv_l , ConVarBound_Upper, true, 16.0);

new Handle:zombie_player_l = FindConVar("z_max_player_zombies");
SetConVarBounds(zombie_player_l , ConVarBound_Upper, true, 16.0);
}
