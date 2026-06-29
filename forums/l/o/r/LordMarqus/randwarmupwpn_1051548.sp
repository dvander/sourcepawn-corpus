/*
*/

#include <sourcemod>
#include <sdktools>
#include <gungame>

#define WPN_NUMBER 26

new String:WeaponStings[][] =
{
	"glock",
	"usp",
	"p228",
	"deagle",
	"fiveseven",
	"elite",
	"tmp",
	"mac10",
	"m3",
	"xm1014",
	"mp5navy",
	"ump45",
	"p90",
	"galil",
	"famas",
	"ak47",
	"scout",
	"sg552",
	"m4a1",
	"sg550",
	"aug",
	"m249",
	"g3sg1",
	"awp",
	"knife",
	"hegrenade"
};

new g_wpnNumber;

public Plugin:myinfo = 
{
	name = "RandomWarmupWeapon GG:SM",
	author = "LordMarqus",
	description = "Randomize weapons in warmup round (for GG:SM).",
	version = "1.0",
	url = "http://www.sourcemod.net/"
}

public OnPluginStart()
{
	g_wpnNumber = GetRandomInt(0, WPN_NUMBER - 1);
}

public OnMapStart()
{
	g_wpnNumber = GetRandomInt(0, WPN_NUMBER - 1);
	GG_SetWeaponLevelByName(1, WeaponStings[g_wpnNumber]);
}

public GG_OnWarmupEnd()
{
	GG_SetWeaponLevelByName(1, WeaponStings[0]);
}