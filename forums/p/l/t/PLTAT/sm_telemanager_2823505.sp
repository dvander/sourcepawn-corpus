#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#undef REQUIRE_PLUGIN 
#include <adminmenu> 

#define PLUGIN_VERSION		"1.0.0"
#define PLUGIN_NAME		"Teleport manager"
#define ADMIN_LVL			ADMFLAG_SLAY

#define GAME_OTHER		0
#define GAME_CSGO		1
#define GAME_CSS			2
#define GAME_DODS		3
#define GAME_GM			4
#define GAME_HL2DM		5
#define GAME_L4D			6
#define GAME_L4D2			7
#define GAME_NMRIH		8
#define GAME_ND			9
#define GAME_TF2			10
/*
new Handle:hTopMenu = INVALID_HANDLE;
new TopMenuObject:g_SpecObject;
*/
new num;
new Handle:hNoticeEnable = INVALID_HANDLE, bool:bNoticeEnable;
new g_GameType, g_CollisionOffset;
new String:sGameName[11][] = {
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
new Float:g_pos[3];
new targetid[MAXPLAYERS + 1];

new bool:bLateLoad = false,
	Handle:hForAll, bool:bForAll,
	Float:fPos[MAXPLAYERS+1][4][3], Float:fAng[MAXPLAYERS+1][4][3],
	bool:bPosSaved[MAXPLAYERS+1][4], 
	Float:fGPos[MAXPLAYERS+1][4][3], Float:fGAng[MAXPLAYERS+1][4][3],
	bool:bGPosSaved[MAXPLAYERS+1][4],
	String:sPrefix[PLATFORM_MAX_PATH],
	bool:bIsAdmin[MAXPLAYERS + 1];

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	bLateLoad = late;
	return APLRes_Success; 
}

public Plugin:myinfo = 
{
	name = PLUGIN_NAME,
	author = "Grey83",
	description = "All that you need to teleportation =)",
	version = PLUGIN_VERSION,
	url = ""
};

public OnPluginStart()
{
	LoadTranslations("common.phrases");

	CreateConVar("sm_telemanager_version", PLUGIN_VERSION, PLUGIN_NAME, FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	hForAll = CreateConVar("sm_telemanager_savelocation_access", "1", "1 - For all, 0 - Only for admins", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	hNoticeEnable = CreateConVar("sm_telemanager_notice", "0", "1/0 = On/Off Show notices to all about teleportation", FCVAR_NONE, true, 0.0, true, 1.0);

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

	bForAll = GetConVarBool(hForAll);
	bNoticeEnable = GetConVarBool(hNoticeEnable);
	HookConVarChange(hForAll, OnSettingsChange);
	HookConVarChange(hNoticeEnable, OnSettingsChange);

	GameDetect();

	switch (g_GameType)
	{
		case 8: sPrefix = "\x01[\x04TM\x01] \x03";
		case 7: sPrefix = "\x01[\x05TM\x01] \x01";
		case 1: sPrefix = "\x01[\x06TM\x01] \x08";
		default: sPrefix = "\x01[\x0700FF00TM\x01] \x07CCCCCC";
	}

	AutoExecConfig(true, "tele");

	g_CollisionOffset = FindSendPropInfo("CBaseEntity", "m_CollisionGroup");

	if(bLateLoad)
	{
		for (new i = 1; i <= MaxClients; i++)
		{
			if(IsClientConnected(i)) OnClientPostAdminCheck(i);
		}
	}

	PrintToServer("%s v.%s has been successfully loaded!\nGame detected as %s", PLUGIN_NAME, PLUGIN_VERSION, sGameName[g_GameType]);
}

GameDetect()
{
	new String:gamename[12];
	GetGameFolderName(gamename,sizeof(gamename));

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

public OnSettingsChange(Handle:hCVar, const String:sOldValue[], const String:sNewValue[])
{
	if (hCVar == hForAll) bForAll = bool:StringToInt(sNewValue);
	else if (hCVar == hNoticeEnable) bNoticeEnable = bool:StringToInt(sNewValue);
}

public OnClientPutInServer(client)
{
	for (new i = 0; i <= 3; i++) bPosSaved[client][i] = false;
}

public OnClientPostAdminCheck(client)
{
	if (1 <= client <= MaxClients) bIsAdmin[client] = CheckCommandAccess(client, "sm_admin", ADMFLAG_GENERIC);
	if (bIsAdmin[client]) for (new i = 0; i <= 3; i++) bGPosSaved[client][i] = false;
}

public Action:OffNoBlockPlayer(Handle:timer, any:target) {SetEntData(target, g_CollisionOffset, 5, 4, true);}

public Action:Cmd_TeleMenu(client, args)
{
	countAlive(client);
	new Handle:menu = CreateMenu(TeleMenuHandler);
	SetMenuTitle(menu, "Teleport:");
	AddMenuItem(menu, "0", "player to the point where I look");
	if (IsPlayerAlive(client) && num > 0) AddMenuItem(menu, "1", "me to the player");
	if (num > 0) AddMenuItem(menu, "2", "player to me");
	if (num > 1) AddMenuItem(menu, "3", "player to another");
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, 0);
	
	return Plugin_Handled;
}

countAlive(client)
{
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && IsPlayerAlive(i) && i != client) num++;
	}
}

public Action:Cmd_Tele_P2A(client, args)
{
	countAlive(client);
	if (!client) PrintToServer("[TM] Command is in-game only");
	else if (!IsPlayerAlive(client) && !num) PrintToChat(client, "%sNot enough alive players on the server", sPrefix);
	else Menu_Any2Aim(client);

	return Plugin_Handled;
}

public Action:Cmd_Tele_M2P(client, args)
{
	countAlive(client);
	if (!client) PrintToServer("[TM] Command is in-game only");
	else if (!IsPlayerAlive(client)) PrintToChat(client, "%sYou not alive", sPrefix);
	else if (!num) PrintToChat(client, "%sNot enough alive players on the server", sPrefix);
	else Menu_Me2Player(client);

	return Plugin_Handled;
}

public Action:Cmd_Tele_P2M(client, args)
{
	countAlive(client);
	if (!client) PrintToServer("[TM] Command is in-game only");
	else if (!num) PrintToChat(client, "%sNot enough alive players on the server", sPrefix);
	else Menu_Player2Me(client);

	return Plugin_Handled;
}

public Action:Cmd_Tele_P2P(client, args)
{
	countAlive(client);
	if (!client) PrintToServer("[TM] Command is in-game only");
	else if (num < 2) PrintToChat(client, "%sNot enough alive players on the server", sPrefix);
	else Menu_Player2Player(client);

	return Plugin_Handled;
}

public TeleMenuHandler(Handle:hHandle, MenuAction:action, client, param2)
{
	switch (action)
	{
		case MenuAction_End: CloseHandle(hHandle);

		case MenuAction_Select:
		{
			new String:sInfo[32];
			GetMenuItem(hHandle, param2, sInfo, sizeof(sInfo));

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

Menu_Any2Aim(client)
{
	new String:name[65];
	new Handle:telemenuaim = CreateMenu(MenuHandlerP2A);
	SetMenuTitle(telemenuaim, "Select Player to Teleport");
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && IsPlayerAlive(i))
		{
			GetClientName(i, name, sizeof(name));
			AddMenuItem(telemenuaim, name, name);
		}
	}
	SetMenuExitBackButton(telemenuaim, true);
	DisplayMenu(telemenuaim, client, 0);
}

Menu_Me2Player(client)
{
	new String:name[65];
	new Handle:telemenu = CreateMenu(MenuHandlerM2P);
	SetMenuTitle(telemenu, "Select Player to Teleport To");
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && IsPlayerAlive(i) && i != client)
		{
			GetClientName(i, name, sizeof(name));
			AddMenuItem(telemenu, name, name);
		}
	}
	SetMenuExitBackButton(telemenu, true);
	DisplayMenu(telemenu, client, 0);
}

Menu_Player2Me(client)
{
	new String:name[65];
	new Handle:telemenume = CreateMenu(MenuHandlerP2M);
	SetMenuTitle(telemenume, "Select Player to Teleport to You");
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && IsPlayerAlive(i) && i != client)
		{
			GetClientName(i, name, sizeof(name));
			AddMenuItem(telemenume, name, name);
		}
	}
	SetMenuExitBackButton(telemenume, true);
	DisplayMenu(telemenume, client, 0);
}

Menu_Player2Player(client)
{
	new String:name[65];
	new Handle:playertarget = CreateMenu(MenuHandlerP2P);
	SetMenuTitle(playertarget, "Select Player to Teleport To");
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && IsPlayerAlive(i) && i != client)
		{
			GetClientName(i, name, sizeof(name));
			AddMenuItem(playertarget, name, name);
		}
	}
	SetMenuExitBackButton(playertarget, true);
	DisplayMenu(playertarget, client, 0);
}

public MenuHandlerP2A(Handle:telemenuaim, MenuAction:action, client, option)
{
	if (action == MenuAction_Select) 
	{
		new String:target[64];
		new String:loopname[64];
		GetMenuItem(telemenuaim, option, target, sizeof(target));
		
		for (new i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i))
			{
				GetClientName(i, loopname, sizeof(loopname));
				if (SetTeleportEndPoint(client) && StrEqual(loopname, target, true) && IsClientInGame(i))
				{
					TeleportEntity(i, g_pos, NULL_VECTOR, NULL_VECTOR);
					if (bNoticeEnable) PrintToChatAll("%s \x04%N \x03teleported", sPrefix, i, target);
					else PrintToChat(client, "%sYou teleported \x04%N", sPrefix, i);
//					ShowActivity2(client, sPrefix, "%t", "Player teleported", client, nameclient2);
					DisplayMenu(telemenuaim, client, 0);
					SetEntData(i, g_CollisionOffset, 2, 4, true);
					CreateTimer(5.0, OffNoBlockPlayer, i);
				}
			}
		}
	}
}

public MenuHandlerM2P(Handle:telemenu, MenuAction:action, client, param2)
{
	if(action == MenuAction_Select) 
	{
		new String:nameclient2[64];
		new String:loopname[64];
		new Float:vec[3];
		GetMenuItem(telemenu, param2, nameclient2, sizeof(nameclient2));
		
		for (new i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i))
			{
				GetClientName(i, loopname, sizeof(loopname));
				if ((StrEqual(loopname, nameclient2, true)) && (IsClientInGame(i)))
				{
					GetClientAbsOrigin(i, vec);
					TeleportEntity(client, vec, NULL_VECTOR, NULL_VECTOR);
					if (bNoticeEnable) PrintToChatAll("%s \x04%N \x03teleported to \x04%s", sPrefix, client, nameclient2);
					else PrintToChat(client, "%sYou teleported to \x04%s", sPrefix, nameclient2);
//					ShowActivity2(client, sPrefix, "%t", "You teleported to", client, nameclient2);
					DisplayMenu(telemenu, client, 0);
					SetEntData(client, g_CollisionOffset, 2, 4, true);
					SetEntData(i, g_CollisionOffset, 2, 4, true);
					CreateTimer(5.0, OffNoBlockPlayer, client);
					CreateTimer(5.0, OffNoBlockPlayer, i);
				}
			}
		}
	}
}

public MenuHandlerP2M(Handle:telemenume, MenuAction:action, client, param2)
{
	if (action == MenuAction_Select) 
	{
		new String:nameclient2[64];
		new String:loopname[64];
		new Float:vec[3];
		GetMenuItem(telemenume, param2, nameclient2, sizeof(nameclient2));
		
		for (new i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i))
			{
				GetClientName(i, loopname, sizeof(loopname));
				if ((StrEqual(loopname, nameclient2, true)) && (IsClientInGame(i)))
				{
					GetClientAbsOrigin(client, vec);
					TeleportEntity(i, vec, NULL_VECTOR, NULL_VECTOR);
					if (bNoticeEnable) PrintToChatAll("%s \x04%N \x03teleported to \x04%N", sPrefix, client, nameclient2, client);
					else PrintToChat(client, "%sYou teleported \x04%s \x03to yourself", sPrefix, nameclient2);
//					ShowActivity2(client, sPrefix, "%t", "Player teleported to other", nameclient2, client);
					DisplayMenu(telemenume, client, 0);
					SetEntData(client, g_CollisionOffset, 2, 4, true);
					SetEntData(i, g_CollisionOffset, 2, 4, true);
					CreateTimer(5.0, OffNoBlockPlayer, client);
					CreateTimer(5.0, OffNoBlockPlayer, i);
				}
			}
		}
	}
}

public MenuHandlerP2P(Handle:playertarget, MenuAction:action, client, param2)
{
	if (action == MenuAction_Select) 
	{
		new String:nameclient2[64];
		new String:loopname[64];
		new String:name[64];
		GetMenuItem(playertarget, param2, nameclient2, sizeof(nameclient2));
		
		for (new i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i))
			{
				GetClientName(i, loopname, sizeof(loopname));
				if ((StrEqual(loopname, nameclient2, true)) && (IsClientInGame(i)))
				{
					targetid[client] = i;
					new Handle:player2tp = CreateMenu(MenuHandlerSP);
					SetMenuTitle(player2tp, "Select Player to Teleport");
					for (new k = 1; k <= MaxClients; k++)
					{
						if (IsClientInGame(k) && IsPlayerAlive(k) && k != client)
						{
							GetClientName(k, name, sizeof(name));
							AddMenuItem(player2tp, name, name);
						}
					}
					SetMenuExitButton(player2tp, true);
					DisplayMenu(player2tp, client, 0);
				}
			}
		}
	}
}

public MenuHandlerSP(Handle:player2tp, MenuAction:action, client, param2)
{
	if (action == MenuAction_Select) 
	{
		new String:nameclient1[64];
		new String:nameclient2[64];
		new String:loopname[64];
		new Float:vec[3];
		new iFirst = targetid[client];
		GetClientName(iFirst, nameclient1, sizeof(nameclient1));
		GetMenuItem(player2tp, param2, nameclient2, sizeof(nameclient2));
		
		for (new i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i) && i != iFirst && i != client)
			{
				GetClientName(i, loopname, sizeof(loopname));
				if ((StrEqual(loopname, nameclient2, true)) && (IsClientInGame(i)))
				{
					GetClientAbsOrigin(targetid[client], vec);
					TeleportEntity(i, vec, NULL_VECTOR, NULL_VECTOR);
					if (bNoticeEnable) PrintToChatAll("%s \x04%s \x03teleported to \x04%s", nameclient2, nameclient1);
					else PrintToChat(client, "%sYou teleported \x04%s \x03to \x04%s", nameclient2, nameclient1);
//					ShowActivity2(client, sPrefix, "%t", "Player teleported to other", nameclient2, client);
					SetEntData(i, g_CollisionOffset, 2, 4, true);
					CreateTimer(5.0, OffNoBlockPlayer, i);
					SetEntData(iFirst, g_CollisionOffset, 2, 4, true);
					CreateTimer(5.0, OffNoBlockPlayer, iFirst);
				}
			}
		}
	}
}

public bool:TraceEntityFilterPlayer(entity, contentsMask)
{
	return entity > MaxClients || !entity;
} 

SetTeleportEndPoint(client)
{
	decl Float:vAngles[3];
	decl Float:vOrigin[3];
	decl Float:vBuffer[3];
	decl Float:vStart[3];
	decl Float:Distance;

	GetClientEyePosition(client,vOrigin);
	GetClientEyeAngles(client, vAngles);

	new Handle:trace = TR_TraceRayFilterEx(vOrigin, vAngles, MASK_SHOT, RayType_Infinite, TraceEntityFilterPlayer);
		
	if(TR_DidHit(trace))
	{
	 	TR_GetEndPosition(vStart, trace);
		GetVectorDistance(vOrigin, vStart, false);
		Distance = -35.0;
   	 	GetAngleVectors(vAngles, vBuffer, NULL_VECTOR, NULL_VECTOR);
		g_pos[0] = vStart[0] + (vBuffer[0]*Distance);
		g_pos[1] = vStart[1] + (vBuffer[1]*Distance);
		g_pos[2] = vStart[2] + (vBuffer[2]*Distance);
	}
	else
	{
		PrintToChat(client, "%s%T", sPrefix, "Could not teleport player");
		CloseHandle(trace);
		return false;
	}

	CloseHandle(trace);
	return true;
}

public Action:Cmd_GlobalSave(client, args)
{
	if(!client) ReplyToCommand(client, "[SM] %t", "Command is in-game only");
	else
	{
		if (IsPlayerAlive(client))
		{
			new team = GetClientTeam(client);
			GetClientAbsOrigin(client, fGPos[client][team]);
			GetClientAbsAngles(client, fGAng[client][team]);
			bGPosSaved[client][team] = true;
			PrintToChat(client, "%sYou just saved global location for team #%d, Use '!gt' to teleport all alive players\nor '!ga' to teleport all alive allies to this location.", sPrefix, team);
		}
		else PrintToChat(client, "%sYou cant save while you're not alive!", sPrefix);
	}

	return Plugin_Handled;
}

public Action:Cmd_GlobalTele(client, args)
{
	if(!client) ReplyToCommand(client, "[SM] %t", "Command is in-game only");
	else
	{
		new team = GetClientTeam(client);
		if (bGPosSaved[client][team])
		{
			new numP = 0;
			for (new i = 1; i <= MaxClients; i++)
			{
				if(IsClientInGame(i) && IsPlayerAlive(i))
				{
					TeleportEntity(i, fGPos[client][team], fGAng[client][team], NULL_VECTOR);
					SetEntData(i, g_CollisionOffset, 2, 4, true);
					CreateTimer(5.0, OffNoBlockPlayer, i);
					numP++;
				}
			}
			if (numP) PrintToChat(client, "%sYou succesfuly teleported %d alive players to a global location.", sPrefix, numP);
		}
		else PrintToChat(client, "%sYou didn't save global location", sPrefix);
	}

	return Plugin_Handled;
}

public Action:Cmd_GlobalAlliesTele(client, args)
{
	if(!client) ReplyToCommand(client, "[SM] %t", "Command is in-game only");
	else
	{
		new team = GetClientTeam(client);
		if (bGPosSaved[client][team])
		{
			new numA = 0;
			for (new i = 1; i <= MaxClients; i++)
			{
				if(IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i) == team)
				{
					TeleportEntity(i, fGPos[client][team], fGAng[client][team], NULL_VECTOR);
					SetEntData(i, g_CollisionOffset, 2, 4, true);
					CreateTimer(5.0, OffNoBlockPlayer, i);
					numA++;
				}
			}
			if (numA) PrintToChat(client, "%sYou succesfuly teleported %d alive allies to a global location", sPrefix, numA);
		}
		else PrintToChat(client, "%sYou didn't save global location for this team", sPrefix);
	}

	return Plugin_Handled;
}

public Action:Cmd_GlobalRemove(client,args)
{
	if(!client) ReplyToCommand(client, "[SM] %t", "Command is in-game only");
	else
	{
		for (new i = 0; i <= 3; i++) bGPosSaved[client][i] = false;
		PrintToChat(client, "%sAll Your global locations was removed.", sPrefix);
	}

	return Plugin_Handled;
}

public Action:Cmd_SaveClientLocation(client, args)
{
	if(!client) ReplyToCommand(client, "[SM] %t", "Command is in-game only");
	else if (!bForAll && !bIsAdmin[client]) PrintToChat(client, "%sYou don't have access to this command.", sPrefix);
	else 
	{
		new team = GetClientTeam(client);
		if (IsPlayerAlive(client))
		{
			bPosSaved[client][team] = true;
			GetClientAbsOrigin(client,fPos[client][team]);
			GetClientAbsAngles(client,fAng[client][team]);
			PrintToChat(client, "%sYou just saved your location,Use '!t' to get to this saved location.", sPrefix);
		}
		else PrintToChat(client, "%sYou cant save while you're not alive!", sPrefix);
	}

	return Plugin_Handled;
}

public Action:Cmd_TeleClient(client, args)
{
	if(!client) ReplyToCommand(client, "[SM] %t", "Command is in-game only");
	else if (!bForAll && !bIsAdmin[client]) PrintToChat(client, "%sYou don't have access to this command.", sPrefix);
	else
	{
		new team = GetClientTeam(client);
		if (!bPosSaved[client][team]) PrintToChat(client, "%sYou didnt save any location for this team.", sPrefix);
		else TeleportEntity(client, fPos[client][team], fAng[client][team], NULL_VECTOR);
	}

	return Plugin_Handled;
}