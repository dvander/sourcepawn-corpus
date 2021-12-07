
// enforce semicolons after each code statement
#pragma semicolon 1

#include <sourcemod>

#define VERSION "1.0"



/*****************************************************************


			P L U G I N   I N F O


*****************************************************************/

public Plugin:myinfo = {
	name = "Killer info display",
	author = "Berni, gH0sTy",
	description = "Displays the health and the weapon of the player who has killed you automatically",
	version = VERSION,
	url = "http://forums.alliedmods.net/showthread.php?p=670361"
}



/*****************************************************************


			G L O B A L   V A R S


*****************************************************************/

// ConVar Handles
new Handle:kid_version			= INVALID_HANDLE;
new Handle:kid_printtochat		= INVALID_HANDLE;
new Handle:kid_printtopanel		= INVALID_HANDLE;
new Handle:kid_showdistance		= INVALID_HANDLE;
new Handle:kid_metricdistance	= INVALID_HANDLE;



/*****************************************************************


			F O R W A R D   P U B L I C S


*****************************************************************/

public OnPluginStart() {
	
	// ConVars
	kid_version = CreateConVar("kid_version", VERSION, "Killer info display plugin version", FCVAR_DONTRECORD|FCVAR_REPLICATED|FCVAR_NOTIFY);
	// Set it to the correct version, in case the plugin gets updated...
	SetConVarString(kid_version, VERSION);

	kid_printtochat		= CreateConVar("kid_printtochat",		"1",	"Prints the killer info to the victims chat");
	kid_printtopanel	= CreateConVar("kid_printtopanel",		"0",	"Displays the killer info to the victim as a panel");
	kid_showdistance	= CreateConVar("kid_showdistance",		"1",	"Show the distance to the killer");
	kid_metricdistance	= CreateConVar("kid_metricdistance",	"1",	"Show distance in meters (metric) or ft");

	HookEvent("player_death", Event_PlayerDeath, EventHookMode_Pre);
	AutoExecConfig(true);
	LoadTranslations( "killer_info_display.phrases" ); // add translations support
}



/****************************************************************


			C A L L B A C K   F U N C T I O N S


****************************************************************/

public Action:Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast) {
	
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	
	if (client == 0 || attacker == 0 || client == attacker) {
		return Plugin_Continue;
	}

	decl String:weapon[32];
	GetEventString(event, "weapon", weapon, sizeof(weapon));

	new Float:distance;
	decl String:unit[20];
	decl String:metersMsg[20];
	decl String:ftMsg[20];
	
	if (GetConVarBool(kid_showdistance)) {
		
		decl Float:pos_client[3], Float:pos_killer[3];

		GetClientAbsOrigin(client, pos_client);
		GetClientAbsOrigin(attacker, pos_killer);
		distance = GetVectorDistance(pos_client, pos_killer) / 100.0;
		
		if (GetConVarBool(kid_metricdistance)) {
			Format(metersMsg, sizeof(metersMsg), "%t", "meters");
			strcopy(unit, sizeof(unit), metersMsg);
		}
		else {
			distance /= 0.305;
			Format(ftMsg, sizeof(ftMsg), "%t", "ft");
			strcopy(unit, sizeof(unit), ftMsg);
		}
	}
	
	if (GetConVarBool(kid_printtopanel)) {

		new Handle:panel= CreatePanel();
		decl String:buf[128];
		
		Format(buf, sizeof(buf), "%N %t", attacker, "killed you");
		SetPanelTitle(panel, buf);

		Format(buf, sizeof(buf), "%t %s", "weapon", weapon);
		DrawPanelText(panel, buf);

		Format(buf, sizeof(buf), "%t", "Health left", GetClientHealth(attacker));
		DrawPanelText(panel, buf);
		
		if (GetConVarBool(kid_showdistance)) {
			Format(buf, sizeof(buf), "%t %.1f %s", "distance", distance, unit);
			DrawPanelText(panel, buf);
		}

		SetPanelCurrentKey(panel, 10);
		SendPanelToClient(panel, client, Handler_DoNothing, 10);
	}
	
	if (GetConVarBool(kid_printtochat)) {
		
		decl String:msg[192];
		new String:distanceMsg[64] = "\0";
		
		if (GetConVarBool(kid_showdistance)) {
			Format(distanceMsg, sizeof(distanceMsg), " \x01%t \x04%.1f %s", "at a distance of", distance, unit);
		}

		Format(msg, sizeof(msg), "\x04\01[SM] %t \x04%N \x01%t \x04%s%s \x01%t \x04%d \x01%t", "attacker", attacker, "killed you with", weapon, distanceMsg, "and has", GetClientHealth(attacker), "hp left");
		
		PrintToChat(client, msg);
	}
	
	
	return Plugin_Continue;
}

public Handler_DoNothing(Handle:menu, MenuAction:action, param1, param2) {}

/*****************************************************************


			P L U G I N   F U N C T I O N S


*****************************************************************/

