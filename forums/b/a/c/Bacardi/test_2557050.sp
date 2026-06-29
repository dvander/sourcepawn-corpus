#include <cstrike_weapons>
#include <restrict>

public Plugin:myinfo = 
{
	name = "Weapon Restrict - Admin weapon restriction",
	author = "Bacardi",
	description = "Admin Weapon restrict",
	version = "0.1",
	url = ""
}

public Action Restrict_OnCanBuyWeapon(int client, int team, WeaponID id, CanBuyResult &result)
{
	if(Restrict_GetRestrictValue(team, id) == -1 || !Restrict_ImmunityCheck(client) || Restrict_GetRoundType() != RoundType_None) return Plugin_Continue;
	
	result = Re_Restrict_ImmunityCheck(client, team, id) ? CanBuy_Allow:CanBuy_Block;

	return Plugin_Changed;
}

public Action Restrict_OnCanPickupWeapon(int client, int team, WeaponID id, bool &result)
{
	if(Restrict_GetRestrictValue(team, id) == -1 || !Restrict_ImmunityCheck(client) || Restrict_GetRoundType() != RoundType_None) return Plugin_Continue;

	result = Re_Restrict_ImmunityCheck(client, team, id);
	return Plugin_Changed;
}


// sm_restrict_immunity_level
// sm_restrict_immunity_%s
/*
	"none",			"p228",			"glock",		"scout",		
	"hegrenade",	"xm1014",		"c4",			"mac10",		
	"aug",			"smokegrenade",	"elite",		"fiveseven",
	"ump45",		"sg550",		"galil",		"famas",
	"usp",			"awp",			"mp5navy",		"m249",
	"m3",			"m4a1",			"tmp",			"g3sg1",
	"flashbang",	"deagle",		"sg552",		"ak47",
	"knife",		"p90",			"shield",		"vest",			
	"vesthelm",		"nvgs",			"galilar",		"bizon",
	"mag7",			"negev",		"sawedoff",		"tec9",
	"taser",		"hkp2000",		"mp7",			"mp9",
	"nova",			"p250",			"scar17",		"scar20",
	"sg556",		"ssg08",		"knifegg",		"molotov",
	"decoy",		"incgrenade",	"defuser"
*/

bool Re_Restrict_ImmunityCheck(int client, int team, WeaponID id)
{
	//PrintToServer("Re_Restrict_ImmunityCheck Restrict_ImmunityCheck %i %s", Restrict_ImmunityCheck(client), weaponNames[id]);
	char buffer[60];
	Format(buffer, sizeof(buffer), "sm_restrict_immunity_%s", weaponNames[id]);

	return CheckCommandAccess(client, buffer, ADMFLAG_ROOT);
}