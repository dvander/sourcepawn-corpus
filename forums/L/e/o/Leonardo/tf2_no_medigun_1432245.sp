#pragma semicolon 1

#define AUTOLOAD_EXTENSIONS
#define REQUIRE_EXTENSIONS
#include <sourcemod>
#include <tf2items>

public Plugin:myinfo = {
	name = "[TF2] Simple Medigun Disabler",
	author = "Leonardo",
	description = "...",
	version = "1.0.0",
	url = "http://xpenia.pp.ru"
};

public Action:TF2Items_OnGiveNamedItem(iClient, String:sClassName[], iItemDefinitionIndex, &Handle:hItemOverride)
{
	if(StrEqual(sClassName, "tf_weapon_medigun", false))
		return Plugin_Handled;
	return Plugin_Continue;
}