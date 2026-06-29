#pragma semicolon 1

#include <sourcemod>
#include <clientprefs>

#define PLUGIN_VERSION "1.0"

// Plugin Info
public Plugin:myinfo =
{
	name = "AWARD IDS FOR L4D PLAYER STATS (L4D2)",
	author = "muukis",
	description = "DISPLAY AWARD IDS IN LEFT 4 DEAD 2 (FOR TESTING PURPOSE)",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.com/"
};

// Here we go!
public OnPluginStart()
{
	HookEvent("award_earned", event_Award);
}

/*
L4D2:
0 - End of Campaign (Not 100% Sure)
7 - End of Level (Not 100% Sure)
8 - End of Level (Not 100% Sure)
17 - Kill Tank
22 - Random Director Mob
23 - End of Level (Not 100% Sure)
40 - End of Campaign (Not 100% Sure)
67 - Protect Friendly
68 - Give Pain Pills
69 - Give Adrenaline
70 - Give Heatlh (Heal using Med Pack)
71 - End of Level (Not 100% Sure)
72 - End of Campaign (Not 100% Sure)
75 - Save Friendly from Ledge Grasp
76 - Save Friendly from Special Infected
80 - Hero Closet Rescue Survivor
84 - Team Kill
85 - Incap Friendly
86 - Left Friendly for Dead
87 - Friendly Fire 
*/

public Action:event_Award(Handle:event, const String:name[], bool:dontBroadcast)
{
	new PlayerID = GetEventInt(event, "userid");

	if (!PlayerID)
		return;

	new User = GetClientOfUserId(PlayerID);

	if (IsClientBot(User))
		return;

	//new SubjectID = GetEventInt(event, "subjectentid");
	new AwardID = GetEventInt(event, "award");

	if (AwardID == 67) // Protect friendly
		PrintToChat(User, "[TEST] Protect friendly (ID = %i)", AwardID);
	else if (AwardID == 68) // Pills given
		PrintToChat(User, "[TEST] Pills given (ID = %i)", AwardID);
	else if (AwardID == 69) // Adrenaline given
		PrintToChat(User, "[TEST] Adrenaline given (ID = %i)", AwardID);
	else if (AwardID == 85) // Incap friendly
		PrintToChat(User, "[TEST] Incap friendly (ID = %i)", AwardID);
	else if (AwardID == 79) // Respawn friendly
		PrintToChat(User, "[TEST] Respawn friendly (ID = %i)", AwardID);
	else if (AwardID == 80) // Kill Tank with no deaths
		PrintToChat(User, "[TEST] Kill Tank with no deaths (ID = %i)", AwardID);
	else if (AwardID == 86) // Left friendly for dead
		PrintToChat(User, "[TEST] Left friendly for dead (ID = %i)", AwardID);
	else if (AwardID == 94) // Let infected in safe room
		PrintToChat(User, "[TEST] Let infected in safe room (ID = %i)", AwardID);
	else if (AwardID == 98) // Round restart
		PrintToChat(User, "[TEST] Round restart (ID = %i)", AwardID);
	else
		PrintToChat(User, "[TEST] Your actions gave you award (ID = %i)", AwardID);
}

IsClientBot(client)
{
	if (client == 0 || !IsClientConnected(client))
		return true;

	decl String:SteamID[64];
	GetClientAuthString(client, SteamID, sizeof(SteamID));

	if (StrEqual(SteamID, "BOT", false))
		return true;

	return false;
}
