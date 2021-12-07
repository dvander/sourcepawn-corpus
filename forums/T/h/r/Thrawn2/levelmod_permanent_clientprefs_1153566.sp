#include <sourcemod>
#include <levelmod>
#include <clientprefs>

#pragma semicolon 1

#define PLUGIN_VERSION "0.1.0"

new Handle:db_level;
new Handle:db_xp;

new bool:g_bValuesLoaded[MAXPLAYERS+1] = {false,...};

////////////////////////
//P L U G I N  I N F O//
////////////////////////
public Plugin:myinfo =
{
	name = "Leveling Mod, Permanent (clientprefs)",
	author = "Thrawn",
	description = "A plugin for Leveling Mod, saves XP and Level to the clientprefs db.",
	version = PLUGIN_VERSION,
	url = "http://thrawn.de"
}

public OnPluginStart()
{
	db_level = RegClientCookie("levelmod_level", "Current player level", CookieAccess_Private);
	db_xp = RegClientCookie("levelmod_xp", "Current player experience points", CookieAccess_Private);
}


/////////////////////////
//L O A D  F R O M  D B//
/////////////////////////
public OnClientCookiesCached(client) {
	loadValues(client);
}

public OnClientPutInServer(client) {
	g_bValuesLoaded[client] = false;
}

stock loadValues(client) {
	if (!AreClientCookiesCached(client) || g_bValuesLoaded[client])
		return;

	new String:sLevel[20];
	GetClientCookie(client, db_level, sLevel, sizeof(sLevel));
	new iLevel = StringToInt(sLevel);

	if(iLevel >= 0) {
		lm_SetClientLevel(client, iLevel);
		LogMessage("DB: %N is level %i", client, iLevel);
	}

	new String:sXP[20];
	GetClientCookie(client, db_xp, sXP, sizeof(sXP));
	new iXP = StringToInt(sXP);

	if(iXP >= 0) {
		lm_SetClientXP(client, iXP);
		LogMessage("DB: %N has xp: %i", client, iXP);
	}

	g_bValuesLoaded[client] = true;
}

public lm_OnClientLevelUp(iClient,iLevel, iAmount, bool:isLevelDown) {
	new iXP = lm_GetClientXP(iClient);

	if(iLevel >= 0) {
		new String:sXP[20];
		Format(sXP, sizeof(sXP), "%i", iXP);

		new String:sLevel[6];
		Format(sLevel, sizeof(sLevel), "%i", iLevel);

		LogMessage("Writing %N cookie: level %i, xp: %i", iClient, iLevel, iXP);
		SetClientCookie(iClient, db_level, sLevel);
		SetClientCookie(iClient, db_xp, sXP);
	}
}

/////////////////////
//S A V E  T O  D B//
/////////////////////
public OnClientDisconnect(client)
{
	new iXP = lm_GetClientXP(client);

	if(iXP >= 0) {
		new String:sXP[20];
		Format(sXP, sizeof(sXP), "%i", iXP);

		LogMessage("Writing client cookie: xp: %i", iXP);
		SetClientCookie(client, db_xp, sXP);
	}
}