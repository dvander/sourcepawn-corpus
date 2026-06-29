//========================================================================//
//I take no credit for this code, this code was provided to me by ivailosp//
//========================================================================//

#include <sourcemod>
 
public Plugin:myinfo =
{
	name = "maxplayersaddon_14",
	author = "Me",
	description = "Allows 14 survivors in coop mode and perhaps other modes as well",
	version = "1.0.0.0",
	url = "http://www.sourcemod.net/"
};
 
public OnPluginStart()
{
	// Perform one-time startup tasks ...

new Handle:surv_l = FindConVar("survivor_limit");
SetConVarBounds(surv_l , ConVarBound_Upper, true, 14.0);

}
