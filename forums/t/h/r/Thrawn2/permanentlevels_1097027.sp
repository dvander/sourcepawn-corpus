#include <sourcemod>
#include <levelmod>
#include <clientprefs>

new Handle:db_level;
new Handle:db_xp;

new bool:g_bValuesLoaded[MAXPLAYERS+1] = {false,...};

public OnPluginStart()
{
	db_level = RegClientCookie("levelmod_level", "Current player level", CookieAccess_Private);
	db_xp = RegClientCookie("levelmod_xp", "Current player experience points", CookieAccess_Private);
	
	HookEvent("player_spawn",       Event_PlayerSpawn);
}


public Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast) {
	new client = GetClientOfUserId(GetEventInt(event, "userid"))

	loadValues(client);
}

public OnClientPutInServer(client) {
	g_bValuesLoaded[client] = false;
}

public loadValues(client) {
	if (!AreClientCookiesCached(client) || g_bValuesLoaded[client])
		return;

	new String:sLevel[20];
	GetClientCookie(client, db_level, sLevel, sizeof(sLevel));
	new iLevel = StringToInt(sLevel);
	
	if(iLevel > 0) {
		lm_SetClientLevel(client, iLevel);
		LogMessage("DB: %N is level %i", client, iLevel);
	}
	
	new String:sXP[20];
	GetClientCookie(client, db_xp, sXP, sizeof(sXP));
	new iXP = StringToInt(sXP);
	
	if(iXP > 0) {
		lm_SetClientXP(client, iXP);
		LogMessage("DB: %N has xp: %i", client, iXP);
	}
	
	g_bValuesLoaded[client] = true;
} 

public OnClientDisconnect(client)
{		
	new iXP = lm_GetClientXP(client);
	new iLevel = lm_GetClientLevel(client);

	if(iLevel > 0) {
		new String:sXP[20];
		Format(sXP, sizeof(sXP), "%i", iXP);

		new String:sLevel[6];
		Format(sLevel, sizeof(sLevel), "%i", iLevel);

		SetClientCookie(client, db_level, sLevel);
		SetClientCookie(client, db_xp, sXP);
	}
}