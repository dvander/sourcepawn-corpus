#include <tf2_stocks>
#include <sdktools>
#include <sdkhooks>

new g_Steps[][2] = {
	{127, 156}, // General
	{1001, 1038}, // Scout
	{1101, 1138}, // Sniper
	{1201, 1238}, // Soldier
	{1301, 1338}, // Demoman
	{1401, 1439}, // Medic
	{1501, 1539}, // Heavy
	{1601, 1639}, // Pyro
	{1701, 1737}, // Spy
	{1801, 1838}, // Engineer
	{1901, 1921}, // Halloween
	{2001, 2008}, // Replay
	{2101, 2101}, // Christmas
	{2201, 2212}, // Foundry
	{2301, 2335}, // MvM
	{2401, 2412} // Doomsday
};

new String:g_StepNames[][] = {
	"General",
	"Scout",
	"Sniper",
	"Soldier",
	"Demoman",
	"Medic",
	"Heavy",
	"Pyro",
	"Spy",
	"Engineer",
	"Halloween",
	"Replay",
	"Christmas",
	"Foundry",
	"MvM",
	"Doomsday"
};


new TFClassType:g_RequiredClass[] = {
	TFClass_Unknown,
	TFClass_Scout,
	TFClass_Sniper,
	TFClass_Soldier,
	TFClass_DemoMan,
	TFClass_Medic,
	TFClass_Heavy,
	TFClass_Pyro,
	TFClass_Spy,
	TFClass_Engineer,
	TFClass_Unknown,
	TFClass_Unknown,
	TFClass_Unknown,
	TFClass_Unknown,
	TFClass_Unknown,
	TFClass_Unknown
};

public Plugin:myinfo =
{
	name = "[TF2] Achievement Mod",
	author = "Kuroiwa",
	description = "Provides !givemeall and !giveitems commands that rewards clients with achievements.",
	version = "1.0",
	url = "http://sourcemod.net"
};

new g_Step[MAXPLAYERS + 1];

public OnPluginStart() 
{
	CreateConVar("sm_achmod_version", "1.0", "Achievement Mod Plugin Version", FCVAR_NOTIFY|FCVAR_DONTRECORD);
	
	RegConsoleCmd("sm_givemeall", Command_GiveMeAll, "Unlocks all achievements for you.");
	RegConsoleCmd("sm_giveitems", Command_GiveItems, "Unlocks item achievements for you.");
}

public Action:Command_GiveItems(client, args)
{
	UnlockNamed(client, 1036, "scout1");// Scout
	UnlockNamed(client, 1037, "scout2");
	UnlockNamed(client, 1038, "scout3");
	 
	UnlockNamed(client, 1136, "Sniper Milestone 1");
	UnlockNamed(client, 1137, "Sniper Milestone 2");
	UnlockNamed(client, 1138, "Sniper Milestone 3");
	 
	UnlockNamed(client, 1236, "Soldier Milestone 1");
	UnlockNamed(client, 1237, "Soldier Milestone 2");
	UnlockNamed(client, 1238, "Soldier Milestone 3");
	 
	UnlockNamed(client, 1336, "Demoman Milestone 1");
	UnlockNamed(client, 1337, "Demoman Milestone 2");
	UnlockNamed(client, 1338, "Demoman Milestone 3");
	 
	UnlockNamed(client, 1437, "Milestone 1");
	UnlockNamed(client, 1438, "Milestone 2");
	UnlockNamed(client, 1439, "Milestone 3");
	 
	UnlockNamed(client, 1537, "Milestone 1"); // Heavy
	UnlockNamed(client, 1538, "Milestone 2");
	UnlockNamed(client, 1539, "Milestone 3");
	 
	UnlockNamed(client, 1637, "Milestone 1"); // Pyro
	UnlockNamed(client, 1638, "Milestone 2");
	UnlockNamed(client, 1639, "Milestone 3");
	 
	UnlockNamed(client, 1735, "Spy Milestone 1"); // Spy
	UnlockNamed(client, 1736, "Spy Milestone 2");
	UnlockNamed(client, 1737, "Spy Milestone 3");
	 
	UnlockNamed(client, 1801, "Engineer Milestone 1"); // Engy
	UnlockNamed(client, 1802, "Engineer Milestone 2");
	UnlockNamed(client, 1803, "Engineer Milestone 3");
	 
	UnlockNamed(client, 2004, "Star of My Own Show");
	UnlockNamed(client, 2006, "Local Cinema Star");
	 
	UnlockNamed(client, 2212, "Foundry Milestone");
	
	UnlockNamed(client, 2412, "Doomsday Milestone");
	
	UnlockNamed(client, 156, "Fresh Pair Of Eyes");
	 
	return Plugin_Handled;
}

public Action:Command_GiveMeAll(client, args)
{
	if(g_Step[client] > 0) 
	{
		return Plugin_Handled;
	}
	
	if(!IsPlayerAlive(client))
	{
		PrintToChat(client, "[SM] You must be alive to use !givemeall command");
		return Plugin_Handled;
	}
	
	TF2_RespawnPlayer(client);
	
	
	g_Step[client] = 0;
	CreateTimer(0.5, Timer_PrepNextStep, GetClientUserId(client));
	return Plugin_Handled;
}

public Action:Timer_PrepNextStep(Handle:timer, any:userid) 
{
	new client = GetClientOfUserId(userid);
	if(!client) {
		return;
	}
	
	TF2_RemoveAllWeapons(client);
	SetEntityMoveType(client, MOVETYPE_NONE);
	
	if(g_RequiredClass[g_Step[client]] != TFClass_Unknown) {
		TF2_SetPlayerClass(client, g_RequiredClass[g_Step[client]]);
	}
	
	PrintHintText(client, "Unlocking %s achievements...", g_StepNames[g_Step[client]]);
	
	CreateTimer(1.0, Timer_DoNextStep, userid);
}

public Action:Timer_DoNextStep(Handle:timer, any:userid)
{
	new client = GetClientOfUserId(userid);
	if(!client) {
		return;
	}
	
	for(new i = g_Steps[g_Step[client]][0]; i <= g_Steps[g_Step[client]][1]; i++) {
		Unlock(client, i);
	}
	
	if(++g_Step[client] >= sizeof(g_Steps)) {
		PrintToChat(client, "[SM] All achievements has been unlocked.");
		g_Step[client] = 0;
		ForcePlayerSuicide(client);
		SDKHooks_TakeDamage(client, 0, 0, 5000.0);
	} else {
		CreateTimer(4.0, Timer_PrepNextStep, userid);
	}
}

UnlockNamed(client, id, String:achname[]) {
	new Handle:bf = StartMessageOne("AchievementEvent", client, USERMSG_RELIABLE);
	BfWriteShort(bf, id);
	EndMessage();
}

Unlock(client, id) {
	new Handle:bf = StartMessageOne("AchievementEvent", client, USERMSG_RELIABLE);
	BfWriteShort(bf, id);
	EndMessage();
}