#pragma semicolon 1
#pragma newdecls required

#include <sdktools_engine>
#include <sdktools_functions>
#include <sdktools_trace>

static const char
	PL_NAME[]	= "Teleport manager",
	PL_VER[]	= "1.1.0_01.06.2024",

	sGameName[][] =
{
	"Other(unknown) (GAME_OTHER)",
	"Counter-Strike: Global Offensive (GAME_CSGO)",
	"Counter-Strike: Source (GAME_CSS)",
	"Day of Defeat: Source (GAME_DODS)",
	"GarrysMod (GAME_GM)",
	"Half-Life 2: Deathmatch (GAME_HL2DM)",
	"Left 4 Dead (GAME_L4D)",
	"Left 4 Dead 2 (GAME_L4D2)",
	"No More Room in Hell (GAME_NMRIH)",
	"Nuclear Dawn (GAME_ND)",
	"Team Fortress 2: Source (GAME_TF2)"
};

static const int
	ADMIN_LVL	= ADMFLAG_SLAY;

enum
{
	GAME_OTHER,
	GAME_CSGO,
	GAME_CSS,
	GAME_DODS,
	GAME_GM,
	GAME_HL2DM,
	GAME_L4D,
	GAME_L4D2,
	GAME_NMRIH,
	GAME_ND,
	GAME_TF2
};

bool
	bNoticeEnable,
	bPosSaved[MAXPLAYERS+1][4],
	bGPosSaved[MAXPLAYERS+1][4];
int
	g_CollisionOffset,
	iAccess,
	targetid[MAXPLAYERS+1];
float
	g_pos[3],
	fPos[MAXPLAYERS+1][4][3],
	fAng[MAXPLAYERS+1][4][3],
	fGPos[MAXPLAYERS+1][4][3],
	fGAng[MAXPLAYERS+1][4][3];
char
	sPrefix[24];

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	if((g_CollisionOffset = FindSendPropInfo("CBaseEntity", "m_CollisionGroup")) > 0)
		return APLRes_Success;

	FormatEx(error, err_max, "Can't find offset 'CBaseEntity::m_CollisionGroup'");
	return APLRes_Failure;
}

public Plugin myinfo =
{
	name		= PL_NAME,
	version		= PL_VER,
	description	= "All that you need to teleportation =)",
	author		= "Grey83",
	url			= "https://steamcommunity.com/groups/grey83ds"
}

public void OnPluginStart()
{
	LoadTranslations("common.phrases");

	CreateConVar("sm_telemanager_version", PL_VER, PL_NAME, FCVAR_DONTRECORD|FCVAR_NOTIFY|FCVAR_SPONLY);

	ConVar cvar;
	cvar = CreateConVar("sm_telemanager_savelocation_access", "1", "1 - For all, 0 - Only for admins", _, true, _, true, 1.0);
	cvar.AddChangeHook(CVarChange_All);
	CVarChange_All(cvar, NULL_STRING, NULL_STRING);

	cvar = CreateConVar("sm_telemanager_notice", "0", "1/0 = On/Off Show notices to all about teleportation", _, true, _, true, 1.0);
	bNoticeEnable = cvar.BoolValue;
	cvar.AddChangeHook(CVarChange_Notice);

	AutoExecConfig(true, "tele");

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

	sPrefix = "\x01[\x0700FF00TM\x01] \x07CCCCCC";

	char game[12];
	GetGameFolderName(game, sizeof(game));

	int type = GAME_OTHER;
	if(!strcmp(game,"csgo"))
	{
		type = GAME_CSGO;
		sPrefix = "\x01[\x06TM\x01] \x08";
	}
	else if(!strcmp(game,"cstrike"))
		type = GAME_CSS;
	else if(!strcmp(game,"dod"))
		type = GAME_DODS;
	else if(!strcmp(game,"garrysmod"))
		type = GAME_GM;
	else if(!strcmp(game,"hl2mp"))
		type = GAME_HL2DM;
	else if(!strcmp(game,"left4dead"))
		type = GAME_L4D;
	else if(!strcmp(game,"left4dead2"))
		type = GAME_L4D2;
	else if(!strcmp(game,"nmrih"))
	{
		type = GAME_NMRIH;
		sPrefix = "\x01[\x04TM\x01] \x03";
	}
	else if(!strcmp(game,"nucleardawn"))
		type = GAME_ND;
	else if(!strcmp(game,"tf"))
		type = GAME_TF2;

	PrintToServer("%s v.%s has been successfully loaded!\nGame detected as %s", PL_NAME, PL_VER, sGameName[type]);
}

public void CVarChange_All(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	iAccess = cvar.BoolValue ? 0x7ffe : 0;	// all flags from ADMFLAG_GENERIC to ADMFLAG_ROOT or none
}

public void CVarChange_Notice(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	bNoticeEnable = cvar.BoolValue;
}

public void OnClientDisconnect(int client)
{
	for(int i; i <= sizeof(bPosSaved[]); i++) bPosSaved[client][i] = bGPosSaved[client][i] = false;
}

public Action OffNoBlockPlayer(Handle timer, int target)
{
	if((target = GetClientOfUserId(target)) && IsPlayerAlive(target)) SetEntData(target, g_CollisionOffset, 5, 4, true);
	return Plugin_Stop;
}

public Action Cmd_TeleMenu(int client, int args)
{
	int num = countAlive(client);
	Menu menu = new Menu(TeleMenuHandler);
	menu.SetTitle("Teleport:");
	menu.AddItem("0", "player to the point where I look");
	if(num > 0)
	{
		if(IsPlayerAlive(client)) menu.AddItem("1", "me to the player");
		menu.AddItem("2", "player to me");
		if(num > 1) menu.AddItem("3", "player to another");
	}
	SetMenuExitButton(menu, true);
	menu.Display(client, 0);

	return Plugin_Handled;
}

public int TeleMenuHandler(Menu menu, MenuAction action, int client, int param2)
{
	switch(action)
	{
		case MenuAction_End:
			CloseHandle(menu);
		case MenuAction_Select:
		{
			char sInfo[4];
			menu.GetItem(param2, sInfo, sizeof(sInfo));

			switch(StringToInt(sInfo))
			{
				case 0: Menu_Any2Aim(client);
				case 1: Menu_Me2Player(client);
				case 2: Menu_Player2Me(client);
				case 3: Menu_Player2Player(client);
			}
		}
	}
	return 0;
}

public Action Cmd_Tele_P2A(int client, int args)
{
	if(!client)
		PrintToServer("[TM] Command is in-game only");
	else if(!IsPlayerAlive(client) && !countAlive(client))
		PrintToChat(client, "%sNot enough alive players on the server", sPrefix);
	else Menu_Any2Aim(client);

	return Plugin_Handled;
}

void Menu_Any2Aim(int client)
{
	char id[12], name[MAX_NAME_LENGTH];
	Menu menu = new Menu(MenuHandlerP2A);
	menu.SetTitle("Select Player to Teleport");
	for(int i; ++i <= MaxClients;)	if(IsClientInGame(i) && IsPlayerAlive(i))
	{
		FormatEx(id, sizeof(id), "%i", GetClientUserId(i));
		GetClientName(i, name, sizeof(name));
		menu.AddItem(id, name);
	}
	menu.ExitBackButton = true;
	menu.Display(client, 0);
}

public int MenuHandlerP2A(Menu menu, MenuAction action, int client, int option)
{
	if(action == MenuAction_Select)
	{
		char id[12];
		menu.GetItem(option, id, sizeof(id));
		int target = GetClientOfUserId(StringToInt(id));
		if(!target || !SetTeleportEndPoint(client))
		{
			Menu_Any2Aim(client);
			return 0;
		}

		TeleportEntity(target, g_pos, NULL_VECTOR, NULL_VECTOR);
		if(bNoticeEnable) PrintToChatAll("%s \x04%N \x03teleported", sPrefix, target);
		else PrintToChat(client, "%sYou teleported \x04%N", sPrefix, target);
		Menu_Any2Aim(client);
		if(!IsPlayerAlive(target))
			return 0;

		SetEntData(target, g_CollisionOffset, 2, 4, true);
		CreateTimer(5.0, OffNoBlockPlayer, GetClientUserId(target));
	}
	else if(action == MenuAction_End) CloseHandle(menu);
	return 0;
}

bool SetTeleportEndPoint(int client)
{
	static float ang[3], orig[3], dist = -35.0;	// default player models have lenght and width less than this number

	GetClientEyePosition(client,orig);
	GetClientEyeAngles(client, ang);

	Handle trace = TR_TraceRayFilterEx(orig, ang, MASK_SHOT, RayType_Infinite, TraceEntityFilterPlayer);
	if(TR_DidHit(trace))
	{
		TR_GetEndPosition(g_pos, trace);
		GetVectorDistance(orig, g_pos, false);
		GetAngleVectors(ang, orig, NULL_VECTOR, NULL_VECTOR);
		g_pos[0] += (orig[0] * dist);
		g_pos[1] += (orig[1] * dist);
//		g_pos[2] += (orig[2] * dist);
	}
	else
	{
		PrintToChat(client, "%s%T", sPrefix, "Could not teleport player", client);
		CloseHandle(trace);
		return false;
	}

	CloseHandle(trace);
	return true;
}

public bool TraceEntityFilterPlayer(int entity, int contentsMask)
{
	return entity > MaxClients || !entity;
}

public Action Cmd_Tele_M2P(int client, int args)
{
	if(!client) PrintToServer("[TM] Command is in-game only");
	else if(!IsPlayerAlive(client)) PrintToChat(client, "%sYou not alive", sPrefix);
	else if(!countAlive(client)) PrintToChat(client, "%sNot enough alive players on the server", sPrefix);
	else Menu_Me2Player(client);

	return Plugin_Handled;
}

void Menu_Me2Player(int client)
{
	char id[12], name[MAX_NAME_LENGTH];
	Menu menu = new Menu(MenuHandlerM2P);
	menu.SetTitle("Select Player to Teleport To");
	for(int i; ++i <= MaxClients;)	if(IsClientInGame(i) && IsPlayerAlive(i) && i != client)
	{
		FormatEx(id, sizeof(id), "%i", i);
		GetClientName(i, name, sizeof(name));
		menu.AddItem(id, name);
	}
	menu.ExitBackButton = true;
	menu.Display(client, 0);
}

public int MenuHandlerM2P(Menu menu, MenuAction action, int client, int param2)
{
	if(action == MenuAction_Select)
	{
		char id[12];
		menu.GetItem(param2, id, sizeof(id));
		int target = GetClientOfUserId(StringToInt(id));
		if(!target)
		{
			Menu_Me2Player(client);
			return 0;
		}

		float vec[3], ang[3];
		GetClientAbsOrigin(target, vec);
		GetClientAbsAngles(client, ang);
		TeleportEntity(client, vec, ang, NULL_VECTOR);
		if(bNoticeEnable) PrintToChatAll("%s \x04%N \x03teleported to \x04%N", sPrefix, client, target);
		else PrintToChat(client, "%sYou teleported to \x04%N", sPrefix, target);
		menu.Display(client, 0);

		if(!IsPlayerAlive(target))
			return 0;

		SetEntData(client, g_CollisionOffset, 2, 4, true);
		SetEntData(target, g_CollisionOffset, 2, 4, true);
		CreateTimer(5.0, OffNoBlockPlayer, GetClientUserId(client));
		CreateTimer(5.0, OffNoBlockPlayer, GetClientUserId(target));
	}
	else if(action == MenuAction_End) CloseHandle(menu);
	return 0;
}

public Action Cmd_Tele_P2M(int client, int args)
{
	if(!client) PrintToServer("[TM] Command is in-game only");
	else if(!countAlive(client)) PrintToChat(client, "%sNot enough alive players on the server", sPrefix);
	else Menu_Player2Me(client);

	return Plugin_Handled;
}

void Menu_Player2Me(int client)
{
	char id[12], name[MAX_NAME_LENGTH];
	Menu menu = new Menu(MenuHandlerP2M);
	menu.SetTitle("Select Player to Teleport to You");
	for(int i; ++i <= MaxClients;) if(i != client && IsClientInGame(i) && IsPlayerAlive(i))
	{
		FormatEx(id, sizeof(id), "%i", i);
		GetClientName(i, name, sizeof(name));
		menu.AddItem(id, name);
	}
	menu.ExitBackButton = true;
	menu.Display(client, 0);
}

public int MenuHandlerP2M(Menu menu, MenuAction action, int client, int param2)
{
	if(action == MenuAction_Select)
	{
		char id[12];
		menu.GetItem(param2, id, sizeof(id));
		int target = GetClientOfUserId(StringToInt(id));
		if(!target)
		{
			Menu_Player2Me(client);
			return 0;
		}

		float vec[3], ang[3];
		GetClientAbsOrigin(client, vec);
		GetClientAbsAngles(client, ang);
		TeleportEntity(target, vec, ang, NULL_VECTOR);
		if(bNoticeEnable) PrintToChatAll("%s \x04%N \x03teleported to \x04%N", sPrefix, client, id);
		else PrintToChat(client, "%sYou teleported \x04%N \x03to yourself", sPrefix, id);
		menu.Display(client, 0);
		if(!IsPlayerAlive(target))
			return 0;

		SetEntData(client, g_CollisionOffset, 2, 4, true);
		SetEntData(target, g_CollisionOffset, 2, 4, true);
		CreateTimer(5.0, OffNoBlockPlayer, GetClientUserId(client));
		CreateTimer(5.0, OffNoBlockPlayer, GetClientUserId(target));
	}
	else if(action == MenuAction_End) CloseHandle(menu);
	return 0;
}

public Action Cmd_Tele_P2P(int client, int args)
{
	if(!client) PrintToServer("[TM] Command is in-game only");
	else if(countAlive(client) < 2) PrintToChat(client, "%sNot enough alive players on the server", sPrefix);
	else Menu_Player2Player(client);

	return Plugin_Handled;
}

void Menu_Player2Player(int client)
{
	char id[12], name[MAX_NAME_LENGTH];
	Menu menu = new Menu(MenuHandlerP2P);
	menu.SetTitle("Select Player to Teleport To");
	for(int i; ++i <= MaxClients;) if(i != client && IsClientInGame(i) && IsPlayerAlive(i))
	{
		FormatEx(id, sizeof(id), "%i", i);
		GetClientName(i, name, sizeof(name));
		menu.AddItem(id, name);
	}
	menu.ExitBackButton = true;
	menu.Display(client, 0);
}

bool IsTargetValid(int client, int target)
{
	return target != client && IsClientInGame(target) && IsPlayerAlive(target);
}

public int MenuHandlerP2P(Menu menu, MenuAction action, int client, int param2)
{
	if(action == MenuAction_Select)
	{
		char id[12];
		menu.GetItem(param2, id, sizeof(id));
		int target = GetClientOfUserId(StringToInt(id));
		if(!target)
		{
			Menu_Player2Player(client);
			return 0;
		}

		targetid[client] = GetClientUserId(target);
		Menu_Player2Player_Sec(client);
	}
	else if(action == MenuAction_End) CloseHandle(menu);
	return 0;
}

void Menu_Player2Player_Sec(int client)
{
	int target = GetClientOfUserId(targetid[client]);
	if(!target)
	{
		Menu_Player2Player(client);
		return;
	}

	Menu menu = new Menu(MenuHandlerSP);
	menu.SetTitle("Select Player to Teleport");
	char id[12], name[64];
	for(int i; ++i <= MaxClients;) if(i != target && IsTargetValid(client, i))
	{
		FormatEx(id, sizeof(id), "%i", i);
		GetClientName(i, name, sizeof(name));
		menu.AddItem(id, name);
	}
	menu.ExitBackButton = true;
	menu.Display(client, 0);
}

public int MenuHandlerSP(Menu menu, MenuAction action, int client, int param2)
{
	if(action == MenuAction_Select)
	{
		int first = GetClientOfUserId(targetid[client]);
		if(!first)
		{
			Menu_Player2Player(client);
			return 0;
		}

		char id[12];
		menu.GetItem(param2, id, sizeof(id));
		int second = GetClientOfUserId(StringToInt(id));
		if(!second)
		{
			Menu_Player2Player_Sec(client);
			return 0;
		}

		float vec[3], ang[3];
		GetClientAbsOrigin(first, vec);
		GetClientAbsAngles(client, ang);
		TeleportEntity(second, vec, ang, NULL_VECTOR);
		if(bNoticeEnable) PrintToChatAll("%s \x04%N \x03teleported to \x04%N", sPrefix, second, first);
		else PrintToChat(client, "%sYou teleported \x04%s \x03to \x04%s", sPrefix, second, first);
		if(!IsPlayerAlive(first) || !IsPlayerAlive(second))
			return 0;

		SetEntData(first, g_CollisionOffset, 2, 4, true);
		SetEntData(second, g_CollisionOffset, 2, 4, true);
		CreateTimer(5.0, OffNoBlockPlayer, GetClientUserId(first));
		CreateTimer(5.0, OffNoBlockPlayer, GetClientUserId(second));
	}
	else if(action == MenuAction_End) CloseHandle(menu);
	return 0;
}

public Action Cmd_GlobalSave(int client, int args)
{
	if(!client) ReplyToCommand(client, "[SM] %t", "Command is in-game only");
	else
	{
		if(IsPlayerAlive(client))
		{
			int team = GetClientTeam(client);
			GetClientAbsOrigin(client, fGPos[client][team]);
			GetClientAbsAngles(client, fGAng[client][team]);
			bGPosSaved[client][team] = true;
			PrintToChat(client, "%sYou just saved global location for team #%d, Use '!gt' to teleport all alive players\nor '!ga' to teleport all alive allies to this location.", sPrefix, team);
		}
		else PrintToChat(client, "%sYou cant save while you're not alive!", sPrefix);
	}

	return Plugin_Handled;
}

public Action Cmd_GlobalTele(int client, int args)
{
	if(!client) ReplyToCommand(client, "[SM] %t", "Command is in-game only");
	else
	{
		int team = GetClientTeam(client);
		if(bGPosSaved[client][team])
		{
			int num;
			for(int i; ++i <= MaxClients;)	if(IsClientInGame(i) && IsPlayerAlive(i))
			{
				TeleportEntity(i, fGPos[client][team], fGAng[client][team], NULL_VECTOR);
				SetEntData(i, g_CollisionOffset, 2, 4, true);
				CreateTimer(5.0, OffNoBlockPlayer, i);
				num++;
			}
			if(num) PrintToChat(client, "%sYou succesfuly teleported %d alive players to a global location.", sPrefix, num);
		}
		else PrintToChat(client, "%sYou didn't save global location", sPrefix);
	}

	return Plugin_Handled;
}

public Action Cmd_GlobalAlliesTele(int client, int args)
{
	if(!client) ReplyToCommand(client, "[SM] %t", "Command is in-game only");
	else
	{
		int team = GetClientTeam(client);
		if(bGPosSaved[client][team])
		{
			int numA = 0;
			for(int i; ++i <= MaxClients;) if(IsClientInGame(i) && GetClientTeam(i) == team && IsPlayerAlive(i))
			{
				TeleportEntity(i, fGPos[client][team], fGAng[client][team], NULL_VECTOR);
				SetEntData(i, g_CollisionOffset, 2, 4, true);
				CreateTimer(5.0, OffNoBlockPlayer, i);
				numA++;
			}
			if(numA) PrintToChat(client, "%sYou succesfuly teleported %d alive allies to a global location", sPrefix, numA);
		}
		else PrintToChat(client, "%sYou didn't save global location for this team", sPrefix);
	}

	return Plugin_Handled;
}

public Action Cmd_GlobalRemove(int client, int args)
{
	if(!client) ReplyToCommand(client, "[SM] %t", "Command is in-game only");
	else
	{
		for(int i; i < 4;) bGPosSaved[client][i++] = false;
		PrintToChat(client, "%sAll Your global locations was removed.", sPrefix);
	}

	return Plugin_Handled;
}

public Action Cmd_SaveClientLocation(int client, int args)
{
	if(!client) ReplyToCommand(client, "[SM] %t", "Command is in-game only");
	else if(iAccess && !(GetUserFlagBits(client) & iAccess)) PrintToChat(client, "%sYou don't have access to this command.", sPrefix);
	else
	{
		int team = GetClientTeam(client);
		if(IsPlayerAlive(client))
		{
			bPosSaved[client][team] = true;
			GetClientAbsOrigin(client, fPos[client][team]);
			GetClientAbsAngles(client, fAng[client][team]);
			PrintToChat(client, "%sYou just saved your location. Use '!t' to get to this saved location.", sPrefix);
		}
		else PrintToChat(client, "%sYou cant save while you're not alive!", sPrefix);
	}

	return Plugin_Handled;
}

public Action Cmd_TeleClient(int client, int args)
{
	if(!client) ReplyToCommand(client, "[SM] %t", "Command is in-game only");
	else if(iAccess && !(GetUserFlagBits(client) & iAccess)) PrintToChat(client, "%sYou don't have access to this command.", sPrefix);
	else
	{
		int team = GetClientTeam(client);
		if(!bPosSaved[client][team]) PrintToChat(client, "%sYou didnt save any location for this team.", sPrefix);
		else TeleportEntity(client, fPos[client][team], fAng[client][team], NULL_VECTOR);
	}

	return Plugin_Handled;
}

int countAlive(int client)
{
	int num;
	for(int i; ++i <= MaxClients;) if(i != client && IsClientInGame(i) && IsPlayerAlive(i)) num++;
	return num;
}