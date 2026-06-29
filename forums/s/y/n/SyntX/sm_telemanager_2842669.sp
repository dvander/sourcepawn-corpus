#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#undef REQUIRE_PLUGIN 
#include <adminmenu> 

#define PLUGIN_VERSION		"1.0.0"
#define PLUGIN_NAME			"Teleport manager"
#define ADMIN_LVL			ADMFLAG_SLAY

#define GAME_OTHER		0
#define GAME_CSGO		1
#define GAME_CSS		2
#define GAME_DODS		3
#define GAME_GM			4
#define GAME_HL2DM		5
#define GAME_L4D		6
#define GAME_L4D2		7
#define GAME_NMRIH		8
#define GAME_ND			9
#define GAME_TF2		10
/*
Handle hTopMenu = INVALID_HANDLE;
TopMenuObject g_SpecObject;
*/
int num;
ConVar g_hNoticeEnable;
bool g_bNoticeEnable;
int g_GameType, g_CollisionOffset;
char g_sGameName[11][] = {
	"Other (unknown) (GAME_OTHER)",
	"Counter-Strike: Global Offensive (GAME_CSGO)",
	"Counter-Strike: Source (GAME_CSS)",
	"Day of Defeat: Source (GAME_DODS)",
	"GarrysMod (GAME_GM)",
	"Half-Life 2: Deathmatch  (GAME_HL2DM)",
	"Left 4 Dead (GAME_L4D)",
	"Left 4 Dead 2 (GAME_L4D2)",
	"No More Room in Hell (GAME_NMRIH)",
	"Nuclear Dawn (GAME_ND)",
	"Team Fortress 2: Source (GAME_TF2)"
};
float g_pos[3];
int targetid[MAXPLAYERS + 1];

bool g_bLateLoad = false;
ConVar g_hForAll;
bool g_bForAll;
float g_fPos[MAXPLAYERS+1][4][3];
float g_fAng[MAXPLAYERS+1][4][3];
bool g_bPosSaved[MAXPLAYERS+1][4];
float g_fGPos[MAXPLAYERS+1][4][3];
float g_fGAng[MAXPLAYERS+1][4][3];
bool g_bGPosSaved[MAXPLAYERS+1][4];
char g_sPrefix[PLATFORM_MAX_PATH];
bool g_bIsAdmin[MAXPLAYERS + 1];

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	g_bLateLoad = late;
	return APLRes_Success; 
}

public Plugin myinfo = 
{
	name = PLUGIN_NAME,
	author = "Grey83",
	description = "All that you need to teleportation =)",
	version = PLUGIN_VERSION,
	url = ""
};

public void OnPluginStart()
{
	LoadTranslations("common.phrases");

	CreateConVar("sm_telemanager_version", PLUGIN_VERSION, PLUGIN_NAME, FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	g_hForAll = CreateConVar("sm_telemanager_savelocation_access", "1", "1 - For all, 0 - Only for admins", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_hNoticeEnable = CreateConVar("sm_telemanager_notice", "0", "1/0 = On/Off Show notices to all about teleportation", FCVAR_NONE, true, 0.0, true, 1.0);

	RegAdminCmd("sm_tmenu", Cmd_TeleMenu, ADMIN_LVL, "Admin's teleport menu");
	RegAdminCmd("sm_tele", Cmd_Tele_P2A, ADMIN_LVL, "Teleport player to the point where You look");
	RegAdminCmd("sm_teleme", Cmd_Tele_M2P, ADMIN_LVL, "Teleport You to the player");
	RegAdminCmd("sm_tele2me", Cmd_Tele_P2M, ADMIN_LVL, "Teleport player to You");
	RegAdminCmd("sm_tele2other", Cmd_Tele_P2P, ADMIN_LVL, "Teleport player to other");

	RegAdminCmd("sm_gs", Cmd_GlobalSave, ADMIN_LVL, "Save a global location for all ppl");
	RegAdminCmd("sm_gt", Cmd_GlobalTele, ADMIN_LVL, "Teleports all alive to the global location");
	RegAdminCmd("sm_ga", Cmd_GlobalAlliesTele, ADMIN_LVL, "Teleports all alive allies to the global location");
	RegAdminCmd("sm_gr", Cmd_GlobalRemove, ADMIN_LVL, "Removes Your the global locations");

	RegConsoleCmd("sm_s", Cmd_SaveClientLocation, "Saves Your current location for Your current team");
	RegConsoleCmd("sm_t", Cmd_TeleClient, "Teleports You to the Your personal location that You have previously saved");

	g_bForAll = g_hForAll.BoolValue;
	g_bNoticeEnable = g_hNoticeEnable.BoolValue;
	g_hForAll.AddChangeHook(OnSettingsChange);
	g_hNoticeEnable.AddChangeHook(OnSettingsChange);

	GameDetect();

	switch (g_GameType)
	{
		case 8: g_sPrefix = "\x01[\x04TM\x01] \x03";
		case 7: g_sPrefix = "\x01[\x05TM\x01] \x01";
		case 1: g_sPrefix = "\x01[\x06TM\x01] \x08";
		default: g_sPrefix = "\x01[\x0700FF00TM\x01] \x07CCCCCC";
	}

	AutoExecConfig(true, "tele");

	g_CollisionOffset = FindSendPropInfo("CBaseEntity", "m_CollisionGroup");

	if(g_bLateLoad)
	{
		for (int i = 1; i <= MaxClients; i++)
		{
			if(IsClientConnected(i)) OnClientPostAdminCheck(i);
		}
	}

	PrintToServer("%s v.%s has been successfully loaded!\nGame detected as %s", PLUGIN_NAME, PLUGIN_VERSION, g_sGameName[g_GameType]);
}

void GameDetect()
{
	char gamename[12];
	GetGameFolderName(gamename, sizeof(gamename));

	if(strcmp(gamename,"csgo")==0) g_GameType = GAME_CSGO;
	else if(strcmp(gamename,"cstrike")==0) g_GameType = GAME_CSS;
	else if(strcmp(gamename,"dod")==0) g_GameType = GAME_DODS;
	else if(strcmp(gamename,"garrysmod")==0) g_GameType = GAME_GM;
	else if(strcmp(gamename,"hl2mp")==0) g_GameType = GAME_HL2DM;
	else if(strcmp(gamename,"left4dead")==0) g_GameType = GAME_L4D;
	else if(strcmp(gamename,"left4dead2")==0) g_GameType = GAME_L4D2;
	else if(strcmp(gamename,"nmrih")==0) g_GameType = GAME_NMRIH;
	else if(strcmp(gamename,"nucleardawn")==0) g_GameType = GAME_ND;
	else if(strcmp(gamename,"tf")==0) g_GameType = GAME_TF2;
	else g_GameType = GAME_OTHER;
}

public void OnSettingsChange(ConVar hCVar, const char[] sOldValue, const char[] sNewValue)
{
	if (hCVar == g_hForAll) g_bForAll = view_as<bool>(StringToInt(sNewValue));
	else if (hCVar == g_hNoticeEnable) g_bNoticeEnable = view_as<bool>(StringToInt(sNewValue));
}

public void OnClientPutInServer(int client)
{
	for (int i = 0; i <= 3; i++) g_bPosSaved[client][i] = false;
}

public void OnClientPostAdminCheck(int client)
{
	if (1 <= client <= MaxClients) g_bIsAdmin[client] = CheckCommandAccess(client, "sm_admin", ADMFLAG_GENERIC);
	if (g_bIsAdmin[client]) for (int i = 0; i <= 3; i++) g_bGPosSaved[client][i] = false;
}

public Action OffNoBlockPlayer(Handle timer, int target) 
{
	SetEntData(target, g_CollisionOffset, 5, 4, true);
	return Plugin_Stop;
}

public Action Cmd_TeleMenu(int client, int args)
{
	if (!client) 
	{
		PrintToServer("[TM] Command is in-game only");
		return Plugin_Handled;
	}
	
	countAlive(client);
	Menu menu = new Menu(TeleMenuHandler);
	menu.SetTitle("Teleport:");
	menu.AddItem("0", "player to the point where I look");
	if (IsPlayerAlive(client) && num > 0) menu.AddItem("1", "me to the player");
	if (num > 0) menu.AddItem("2", "player to me");
	if (num > 1) menu.AddItem("3", "player to another");
	menu.ExitButton = true;
	menu.Display(client, 0);
	
	return Plugin_Handled;
}

void countAlive(int client)
{
	num = 0;
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && IsPlayerAlive(i) && i != client) num++;
	}
}

public Action Cmd_Tele_P2A(int client, int args)
{
	if (!client) 
	{
		PrintToServer("[TM] Command is in-game only");
		return Plugin_Handled;
	}
	
	countAlive(client);
	if (!IsPlayerAlive(client) && !num) 
		PrintToChat(client, "%sNot enough alive players on the server", g_sPrefix);
	else 
		Menu_Any2Aim(client);

	return Plugin_Handled;
}

public Action Cmd_Tele_M2P(int client, int args)
{
	if (!client) 
	{
		PrintToServer("[TM] Command is in-game only");
		return Plugin_Handled;
	}
	
	countAlive(client);
	if (!IsPlayerAlive(client)) 
		PrintToChat(client, "%sYou not alive", g_sPrefix);
	else if (!num) 
		PrintToChat(client, "%sNot enough alive players on the server", g_sPrefix);
	else 
		Menu_Me2Player(client);

	return Plugin_Handled;
}

public Action Cmd_Tele_P2M(int client, int args)
{
	if (!client) 
	{
		PrintToServer("[TM] Command is in-game only");
		return Plugin_Handled;
	}
	
	countAlive(client);
	if (!num) 
		PrintToChat(client, "%sNot enough alive players on the server", g_sPrefix);
	else 
		Menu_Player2Me(client);

	return Plugin_Handled;
}

public Action Cmd_Tele_P2P(int client, int args)
{
	if (!client) 
	{
		PrintToServer("[TM] Command is in-game only");
		return Plugin_Handled;
	}
	
	countAlive(client);
	if (num < 2) 
		PrintToChat(client, "%sNot enough alive players on the server", g_sPrefix);
	else 
		Menu_Player2Player(client);

	return Plugin_Handled;
}

public void TeleMenuHandler(Menu menu, MenuAction action, int client, int param2)
{
	switch (action)
	{
		case MenuAction_End: delete menu;

		case MenuAction_Select:
		{
			char sInfo[32];
			menu.GetItem(param2, sInfo, sizeof(sInfo));

			switch (StringToInt(sInfo))
			{
				case 0: Menu_Any2Aim(client);
				case 1: Menu_Me2Player(client);
				case 2: Menu_Player2Me(client);
				case 3: Menu_Player2Player(client);
			}
		}
	}
}

void Menu_Any2Aim(int client)
{
	char name[65];
	Menu menu = new Menu(MenuHandlerP2A);
	menu.SetTitle("Select Player to Teleport");
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && IsPlayerAlive(i))
		{
			GetClientName(i, name, sizeof(name));
			menu.AddItem(name, name);
		}
	}
	menu.ExitBackButton = true;
	menu.Display(client, 0);
}

void Menu_Me2Player(int client)
{
	char name[65];
	Menu menu = new Menu(MenuHandlerM2P);
	menu.SetTitle("Select Player to Teleport To");
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && IsPlayerAlive(i) && i != client)
		{
			GetClientName(i, name, sizeof(name));
			menu.AddItem(name, name);
		}
	}
	menu.ExitBackButton = true;
	menu.Display(client, 0);
}

void Menu_Player2Me(int client)
{
	char name[65];
	Menu menu = new Menu(MenuHandlerP2M);
	menu.SetTitle("Select Player to Teleport to You");
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && IsPlayerAlive(i) && i != client)
		{
			GetClientName(i, name, sizeof(name));
			menu.AddItem(name, name);
		}
	}
	menu.ExitBackButton = true;
	menu.Display(client, 0);
}

void Menu_Player2Player(int client)
{
	char name[65];
	Menu menu = new Menu(MenuHandlerP2P);
	menu.SetTitle("Select Player to Teleport To");
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && IsPlayerAlive(i) && i != client)
		{
			GetClientName(i, name, sizeof(name));
			menu.AddItem(name, name);
		}
	}
	menu.ExitBackButton = true;
	menu.Display(client, 0);
}

public void MenuHandlerP2A(Menu menu, MenuAction action, int client, int option)
{
	if (action == MenuAction_Select) 
	{
		char target[64];
		char loopname[64];
		menu.GetItem(option, target, sizeof(target));
		
		for (int i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i))
			{
				GetClientName(i, loopname, sizeof(loopname));
				if (SetTeleportEndPoint(client) && StrEqual(loopname, target, false) && IsClientInGame(i))
				{
					TeleportEntity(i, g_pos, NULL_VECTOR, NULL_VECTOR);
					if (g_bNoticeEnable) 
					{
						PrintToChatAll("%s\x04%N \x03was teleported to \x04%N's \x03crosshair", 
							g_sPrefix, i, client);
					}
					else 
					{
						PrintToChat(client, "%sYou teleported \x04%N \x03to your crosshair", 
							g_sPrefix, i);
					}
                    //ShowActivity2(client, sPrefix, "%t", "Player teleported", client, nameclient2);
					
					menu.Display(client, 0);
					SetEntData(i, g_CollisionOffset, 2, 4, true);
					CreateTimer(5.0, OffNoBlockPlayer, i);
				}
			}
		}
	}
}

public void MenuHandlerM2P(Menu menu, MenuAction action, int client, int param2)
{
	if(action == MenuAction_Select) 
	{
		char nameclient2[64];
		char loopname[64];
		float vec[3];
		menu.GetItem(param2, nameclient2, sizeof(nameclient2));
		
		for (int i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i))
			{
				GetClientName(i, loopname, sizeof(loopname));
				if ((StrEqual(loopname, nameclient2, false)) && (IsClientInGame(i)))
				{
					GetClientAbsOrigin(i, vec);
					TeleportEntity(client, vec, NULL_VECTOR, NULL_VECTOR);
					if (g_bNoticeEnable) 
						PrintToChatAll("%s\x04%N \x03teleported to \x04%s", g_sPrefix, client, nameclient2);
					else 
						PrintToChat(client, "%sYou teleported to \x04%s", g_sPrefix, nameclient2);
					//ShowActivity2(client, sPrefix, "%t", "You teleported to", client, nameclient2);
					
					menu.Display(client, 0);
					SetEntData(client, g_CollisionOffset, 2, 4, true);
					SetEntData(i, g_CollisionOffset, 2, 4, true);
					CreateTimer(5.0, OffNoBlockPlayer, client);
					CreateTimer(5.0, OffNoBlockPlayer, i);
				}
			}
		}
	}
}

public void MenuHandlerP2M(Menu menu, MenuAction action, int client, int param2)
{
	if (action == MenuAction_Select) 
	{
		char nameclient2[64];
		char loopname[64];
		float vec[3];
		menu.GetItem(param2, nameclient2, sizeof(nameclient2));
		
		for (int i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i))
			{
				GetClientName(i, loopname, sizeof(loopname));
				if ((StrEqual(loopname, nameclient2, false)) && (IsClientInGame(i)))
				{
					GetClientAbsOrigin(client, vec);
					TeleportEntity(i, vec, NULL_VECTOR, NULL_VECTOR);
					if (g_bNoticeEnable) 
						PrintToChatAll("%s\x04%s \x03was teleported to \x04%N", g_sPrefix, nameclient2, client);
					else 
						PrintToChat(client, "%sYou teleported \x04%s \x03to yourself", g_sPrefix, nameclient2);
					//ShowActivity2(client, sPrefix, "%t", "Player teleported to other", nameclient2, client);
					
					menu.Display(client, 0);
					SetEntData(client, g_CollisionOffset, 2, 4, true);
					SetEntData(i, g_CollisionOffset, 2, 4, true);
					CreateTimer(5.0, OffNoBlockPlayer, client);
					CreateTimer(5.0, OffNoBlockPlayer, i);
				}
			}
		}
	}
}

public void MenuHandlerP2P(Menu menu, MenuAction action, int client, int param2)
{
	if (action == MenuAction_Select) 
	{
		char nameclient2[64];
		char loopname[64];
		menu.GetItem(param2, nameclient2, sizeof(nameclient2));
		
		for (int i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i))
			{
				GetClientName(i, loopname, sizeof(loopname));
				if ((StrEqual(loopname, nameclient2, false)) && (IsClientInGame(i)))
				{
					targetid[client] = i;
					Menu player2tp = new Menu(MenuHandlerSP);
					player2tp.SetTitle("Select Player to Teleport");
					
					char name[64];
					for (int k = 1; k <= MaxClients; k++)
					{
						if (IsClientInGame(k) && IsPlayerAlive(k) && k != client)
						{
							GetClientName(k, name, sizeof(name));
							player2tp.AddItem(name, name);
						}
					}
					player2tp.ExitButton = true;
					player2tp.Display(client, 0);
				}
			}
		}
	}
}

public void MenuHandlerSP(Menu menu, MenuAction action, int client, int param2)
{
	if (action == MenuAction_Select) 
	{
		char nameclient1[64];
		char nameclient2[64];
		char loopname[64];
		float vec[3];
		int iFirst = targetid[client];
		GetClientName(iFirst, nameclient1, sizeof(nameclient1));
		menu.GetItem(param2, nameclient2, sizeof(nameclient2));
		
		for (int i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i) && i != iFirst && i != client)
			{
				GetClientName(i, loopname, sizeof(loopname));
				if ((StrEqual(loopname, nameclient2, false)) && (IsClientInGame(i)))
				{
					GetClientAbsOrigin(targetid[client], vec);
					TeleportEntity(i, vec, NULL_VECTOR, NULL_VECTOR);
					if (g_bNoticeEnable) 
						PrintToChatAll("%s\x04%s \x03was teleported to \x04%s", g_sPrefix, nameclient2, nameclient1);
					else 
						PrintToChat(client, "%sYou teleported \x04%s \x03to \x04%s", g_sPrefix, nameclient2, nameclient1);
					//ShowActivity2(client, sPrefix, "%t", "Player teleported to other", nameclient2, client);
					
					SetEntData(i, g_CollisionOffset, 2, 4, true);
					CreateTimer(5.0, OffNoBlockPlayer, i);
					SetEntData(iFirst, g_CollisionOffset, 2, 4, true);
					CreateTimer(5.0, OffNoBlockPlayer, iFirst);
				}
			}
		}
	}
}

public bool TraceEntityFilterPlayer(int entity, int contentsMask)
{
	return entity > MaxClients || !entity;
} 

bool SetTeleportEndPoint(int client)
{
	float vAngles[3];
	float vOrigin[3];
	float vBuffer[3];
	float vStart[3];
	float Distance;

	GetClientEyePosition(client, vOrigin);
	GetClientEyeAngles(client, vAngles);

	Handle trace = TR_TraceRayFilterEx(vOrigin, vAngles, MASK_SHOT, RayType_Infinite, TraceEntityFilterPlayer);
		
	if(TR_DidHit(trace))
	{
	 	TR_GetEndPosition(vStart, trace);
		GetVectorDistance(vOrigin, vStart);
		Distance = -35.0;
   	 	GetAngleVectors(vAngles, vBuffer, NULL_VECTOR, NULL_VECTOR);
		g_pos[0] = vStart[0] + (vBuffer[0]*Distance);
		g_pos[1] = vStart[1] + (vBuffer[1]*Distance);
		g_pos[2] = vStart[2] + (vBuffer[2]*Distance);
		
		delete trace;
		return true;
	}
	else
	{
		PrintToChat(client, "%s%T", g_sPrefix, "Could not teleport player");
		delete trace;
		return false;
	}
}

public Action Cmd_GlobalSave(int client, int args)
{
	if(!client) 
	{
		ReplyToCommand(client, "[SM] %t", "Command is in-game only");
		return Plugin_Handled;
	}
	
	if (IsPlayerAlive(client))
	{
		int team = GetClientTeam(client);
		GetClientAbsOrigin(client, g_fGPos[client][team]);
		GetClientAbsAngles(client, g_fGAng[client][team]);
		g_bGPosSaved[client][team] = true;
		PrintToChat(client, "%sYou just saved global location for team #%d, Use '!gt' to teleport all alive players\nor '!ga' to teleport all alive allies to this location.", g_sPrefix, team);
	}
	else PrintToChat(client, "%sYou cant save while you're not alive!", g_sPrefix);

	return Plugin_Handled;
}

public Action Cmd_GlobalTele(int client, int args)
{
	if(!client) 
	{
		ReplyToCommand(client, "[SM] %t", "Command is in-game only");
		return Plugin_Handled;
	}
	
	int team = GetClientTeam(client);
	if (g_bGPosSaved[client][team])
	{
		int numP = 0;
		for (int i = 1; i <= MaxClients; i++)
		{
			if(IsClientInGame(i) && IsPlayerAlive(i))
			{
				TeleportEntity(i, g_fGPos[client][team], g_fGAng[client][team], NULL_VECTOR);
				SetEntData(i, g_CollisionOffset, 2, 4, true);
				CreateTimer(5.0, OffNoBlockPlayer, i);
				numP++;
			}
		}
		if (numP) PrintToChat(client, "%sYou succesfuly teleported %d alive players to a global location.", g_sPrefix, numP);
	}
	else PrintToChat(client, "%sYou didn't save global location", g_sPrefix);

	return Plugin_Handled;
}

public Action Cmd_GlobalAlliesTele(int client, int args)
{
	if(!client) 
	{
		ReplyToCommand(client, "[SM] %t", "Command is in-game only");
		return Plugin_Handled;
	}
	
	int team = GetClientTeam(client);
	if (g_bGPosSaved[client][team])
	{
		int numA = 0;
		for (int i = 1; i <= MaxClients; i++)
		{
			if(IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i) == team)
			{
				TeleportEntity(i, g_fGPos[client][team], g_fGAng[client][team], NULL_VECTOR);
				SetEntData(i, g_CollisionOffset, 2, 4, true);
				CreateTimer(5.0, OffNoBlockPlayer, i);
				numA++;
			}
		}
		if (numA) PrintToChat(client, "%sYou succesfuly teleported %d alive allies to a global location", g_sPrefix, numA);
	}
	else PrintToChat(client, "%sYou didn't save global location for this team", g_sPrefix);

	return Plugin_Handled;
}

public Action Cmd_GlobalRemove(int client, int args)
{
	if(!client) 
	{
		ReplyToCommand(client, "[SM] %t", "Command is in-game only");
		return Plugin_Handled;
	}
	
	for (int i = 0; i <= 3; i++) g_bGPosSaved[client][i] = false;
	PrintToChat(client, "%sAll Your global locations was removed.", g_sPrefix);

	return Plugin_Handled;
}

public Action Cmd_SaveClientLocation(int client, int args)
{
	if(!client) 
	{
		ReplyToCommand(client, "[SM] %t", "Command is in-game only");
		return Plugin_Handled;
	}
	
	if (!g_bForAll && !g_bIsAdmin[client]) 
		PrintToChat(client, "%sYou don't have access to this command.", g_sPrefix);
	else 
	{
		int team = GetClientTeam(client);
		if (IsPlayerAlive(client))
		{
			g_bPosSaved[client][team] = true;
			GetClientAbsOrigin(client, g_fPos[client][team]);
			GetClientAbsAngles(client, g_fAng[client][team]);
			PrintToChat(client, "%sYou just saved your location,Use '!t' to get to this saved location.", g_sPrefix);
		}
		else PrintToChat(client, "%sYou cant save while you're not alive!", g_sPrefix);
	}

	return Plugin_Handled;
}

public Action Cmd_TeleClient(int client, int args)
{
	if(!client) 
	{
		ReplyToCommand(client, "[SM] %t", "Command is in-game only");
		return Plugin_Handled;
	}
	
	if (!g_bForAll && !g_bIsAdmin[client]) 
		PrintToChat(client, "%sYou don't have access to this command.", g_sPrefix);
	else
	{
		int team = GetClientTeam(client);
		if (!g_bPosSaved[client][team]) 
			PrintToChat(client, "%sYou didnt save any location for this team.", g_sPrefix);
		else 
			TeleportEntity(client, g_fPos[client][team], g_fAng[client][team], NULL_VECTOR);
	}

	return Plugin_Handled;
}