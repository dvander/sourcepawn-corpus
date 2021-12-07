#include <sourcemod>
#include <attributes>
#include <clientprefs>

#pragma semicolon 1

#define PLUGIN_VERSION "0.1.0"

new Handle:db_Attribute[ATTRIBUTESIZE] = {INVALID_HANDLE, ...};
new Handle:db_points;

new bool:g_bValuesLoaded[MAXPLAYERS+1] = {false,...};
new bool:g_bDBRegistered = false;

////////////////////////
//P L U G I N  I N F O//
////////////////////////
public Plugin:myinfo =
{
	name = "tAttributes Mod, Permanent (clientprefs)",
	author = "Thrawn",
	description = "A plugin for tAttributes Mod, saves attributes to the clientprefs db.",
	version = PLUGIN_VERSION,
	url = "http://thrawn.de"
}

public OnAllPluginsLoaded() {
	CreateTimer(0.1, LateRegister);
}

public Action:LateRegister(Handle:timer, any:client)
{
	new count = att_GetAttributeCount();
	for(new i = 0; i < count; i++) {
		new eID = att_GetAttributeID(i);

		new String:eName[64];
		att_GetAttributeName(eID,eName);
		Format(eName, sizeof(eName), "attributes_%s", eName);
		LogMessage("Registering Attribute: %s", eName);
		db_Attribute[eID] = RegClientCookie(eName, "Attribute Mod", CookieAccess_Private);
	}

	db_points = RegClientCookie("attributes_available", "Available attribute points to the player ", CookieAccess_Private);

	g_bDBRegistered = true;
	HookEvent("player_spawn", Event_Player_Spawn);
}

/////////////////////////
//L O A D  F R O M  D B//
/////////////////////////
/*
public OnClientCookiesCached(client) {
	if(att_IsEnabled())
		loadValues(client);
}
*/
public Event_Player_Spawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));

	if(att_IsEnabled())
		loadValues(client);
}

public OnClientConnected(client) {
	g_bValuesLoaded[client] = false;
}

stock loadValues(client) {
	if (!AreClientCookiesCached(client) || g_bValuesLoaded[client] || !g_bDBRegistered)
		return;

	LogMessage("DB: Loading %N", client);
	new count = att_GetAttributeCount();
	for(new i = 0; i < count; i++) {
		new eID = att_GetAttributeID(i);

		if(db_Attribute[eID] == INVALID_HANDLE)
			continue;

		new String:sResult[4];
		GetClientCookie(client, db_Attribute[eID], sResult, sizeof(sResult));

		new iResult = StringToInt(sResult);

		if(iResult >= 0) {
			new String:eName[64];
			att_GetAttributeName(eID,eName);

			att_SetClientAttributeValue(client, eID, iResult);
			LogMessage("DB: %N has %s: %i", client, eName, iResult);
		}
	}

	if(count < 1) {
		LogMessage("DB: There were no attributes registered when %N loaded his values. FAIL!", client);
	}

	new String:sPoints[20];
	GetClientCookie(client, db_points, sPoints, sizeof(sPoints));
	new iPoints = StringToInt(sPoints);

	LogMessage("DB: %N has Points: %i", client, iPoints);
	if(iPoints >= 0) {
		att_SetClientAvailablePoints(client, iPoints);
	}

	g_bValuesLoaded[client] = true;
}

public att_OnClientAttributeChange(iClient, iAttributeId, iValue, iAmount) {
	LogMessage("DB: Saving %N (OnChange!)", iClient);

	new String:eName[64] = "";
	att_GetAttributeName(iAttributeId,eName);

	if(db_Attribute[iAttributeId] == INVALID_HANDLE) {
		LogMessage("DB: Writing %N cookie: %s = %i (FAIL, not registered in db)", iClient, eName, iValue);
		return;
	}

	LogMessage("DB: Writing %N cookie: %s = %i (OK)", iClient, eName, iValue);

	new String:sResult[20];
	Format(sResult, sizeof(sResult), "%i", iValue);
	SetClientCookie(iClient, db_Attribute[iAttributeId], sResult);
}

/////////////////////
//S A V E  T O  D B//
/////////////////////
public OnClientDisconnect(client)
{
	LogMessage("DB: Saving %N", client);

	new count = att_GetAttributeCount();
	for(new i = 0; i < count; i++) {
		new eID = att_GetAttributeID(i);

		new iResult = att_GetClientAttributeValue(client, eID);
		new written = false;

		new String:eName[64] = "";
		if(iResult > 0) {
			new String:sResult[20];
			Format(sResult, sizeof(sResult), "%i", iResult);

			att_GetAttributeName(eID,eName);

			if(db_Attribute[eID] == INVALID_HANDLE)
				continue;

			written = true;
			SetClientCookie(client, db_Attribute[eID], sResult);
		}

		LogMessage("DB: Writing %N cookie: %s = %i (%s)", client, eName, iResult, written ? "OK" : "FAIL");
	}

	if(count < 1) {
		LogMessage("DB: There were no attributes registered when %N disconnected. FAIL!", client);
	}

	new iAvailable = att_GetClientAvailablePoints(client);
	new String:sPoints[5];
	Format(sPoints,sizeof(sPoints),"%i",iAvailable);
	SetClientCookie(client, db_points, sPoints);

	LogMessage("DB: Writing %N cookie: available points = %i", client, iAvailable);
}