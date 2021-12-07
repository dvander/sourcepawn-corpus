#include <sourcemod>
#include <tf2_stocks>
#include <sdkhooks>
#include <sdktools>

#pragma newdecls required

#define AutomaticBlu "Player %s was automatically assigned to team BLU"
#define AutomaticRed "Player %s was automatically assigned to team RED"

#define BAN_COMMAND "sm_advban"
#define UNBAN_COMMAND "sm_advunban"
#define BANID_COMMAND "sm_advbanid"
#define UNBANID_COMMAND "sm_advunbanid"
#define SHOW_BANMENU_COMMAND "sm_advshow"
#define SHOW_BANMENU_CHATCOMMAND "advshow"
 
#define PLUGIN_VERSION "3.1"

char KVPath[PLATFORM_MAX_PATH];
Handle DB = INVALID_HANDLE;
bool bInSpawn[MAXPLAYERS + 1] = false;
Handle saveTimerHandle = INVALID_HANDLE;

public Plugin myinfo = {
	name = "[TF2] AdvancedBans",
	author = "Nescau",
	description = "Grants the ability to ban players from a class or a team.",
	version = PLUGIN_VERSION,
	url = "http://steamcommunity.com/id/nescaufsa/"
};

public void OnPluginStart()
{
	BuildPath(Path_SM, KVPath, sizeof(KVPath), "data/bandata.txt");
	
	DB = CreateKeyValues("BanData");	
	FileToKeyValues(DB, KVPath);
	
	saveTimerHandle = CreateTimer(60.0, SaveKeyValues, 0, TIMER_REPEAT); //Saves the keyvalues each minute
	
	LoadTranslations("common.phrases");
	
	CreateConVar("advancedbans_version", PLUGIN_VERSION, "AdvancedBans version.", FCVAR_NOTIFY);
	
	RegAdminCmd(BAN_COMMAND, DoBan, ADMFLAG_BAN, "");
	RegAdminCmd(UNBAN_COMMAND, DoUnban, ADMFLAG_UNBAN, "");
	RegAdminCmd(BANID_COMMAND, DoBanID, ADMFLAG_BAN, "");
	RegAdminCmd(UNBANID_COMMAND, DoUnbanID, ADMFLAG_UNBAN, "");

	RegConsoleCmd(SHOW_BANMENU_COMMAND, SHOWMENU, "");
	
	AddCommandListener(JOINTEAM, "jointeam");
	AddCommandListener(JOINCLASS, "joinclass");
	AddCommandListener(JOINCLASS, "join_class");
	AddCommandListener(AUTOTEAM, "autoteam");
	
	HookEvent("arena_round_start", ROUND_START);
	HookEvent("teamplay_round_start", ROUND_START);
	HookEvent("round_start", ROUND_START);
	HookEvent("teamplay_waiting_begins", ROUND_START);
	HookEvent("player_spawn", PLAYER_SPAWN);
}

public void OnPluginEnd()
{
	if (saveTimerHandle != INVALID_HANDLE)
	{
		KillTimer(saveTimerHandle);
	}
	
	KeyValuesToFile(DB, KVPath);
}

//SmarterSpawns code to verify if the player is inside the spawn when choosing a random class.
public void OnEntityCreated(int entity, const char[] classname)
{
	if (StrEqual(classname, "func_respawnroom", false))
	{
		SDKHook(entity, SDKHook_StartTouch, SpawnStartTouch);
		SDKHook(entity, SDKHook_EndTouch, SpawnEndTouch);
	}
}

public int SpawnStartTouch(int spawn, int client)
{
	if (client > MaxClients || client < 1)
	{
		return;
	}

	if (IsClientConnected(client) && IsClientInGame(client))
	{
		bInSpawn[client] = true;
	}
}

public int SpawnEndTouch(int spawn, int client)
{
	if (client > MaxClients || client < 1)
	{
		return;
	}

	if (IsClientConnected(client) && IsClientInGame(client))
	{
		bInSpawn[client] = false;
	}
}

public Action PLAYER_SPAWN(Event event, const char[] name, bool dontBroadcast)
{
	bInSpawn[GetClientOfUserId(event.GetInt("userid"))] = true;
}

public void OnClientDisconnect(int client)
{
	bInSpawn[client] = false;
}
/////////////////////////////////////////////////////

public Action SaveKeyValues(Handle timer, any empty)
{
	KeyValuesToFile(DB, KVPath);
}

public void OnClientPutInServer(int client)
{
	int autokick = 0;
	
	for (int i = 1; i <= 3; i++)
	{
		if (IsClientTeamBanned(client, i))
		{
			autokick++;
		}
	}
	
	if (autokick == 3)
	{
		KickClient(client, "You're banned from all teams, please contact the administrator.");
	}
}

/////////////////////////////[ Console CMDs ]/////////////////////////////

public Action DoBan(int client, int args)
{
	if (args == 3)
	{
		char targetName[MAX_NAME_LENGTH];
		GetCmdArg(1, targetName, sizeof(targetName));
		
		int target = FindTarget(client, targetName, true);
		
		if (target != -1)
		{
			char classTeamArg[36];
			GetCmdArg(2, classTeamArg, sizeof(classTeamArg));
			
			int classTeamIndex = GetClassNum(classTeamArg);
			bool bClass = true;
			
			if (classTeamIndex == -1)
			{
				classTeamIndex = GetTeamNum(classTeamArg);
				bClass = false;
			}
			
			if (classTeamIndex != -1)
			{
				char banTime[16];
				GetCmdArg(3, banTime, sizeof(banTime));
				
				if (String_IsInteger(banTime))
				{
					int iBanTime = StringToInt(banTime);
					GetClientName(target, targetName, sizeof(targetName));
					
					if (bClass)
					{
						if (!IsClientClassBanned(target, classTeamIndex))
						{
							DoClassBan(target, classTeamIndex, iBanTime);
							ReplyToCommand(client, "[SM] %s was successfully banned from accessing %s.", targetName, classTeamArg);
						}
						
						else
						{
							ReplyToCommand(client, "[SM] %s is already banned from accessing %s.", targetName, classTeamArg);
						}
					}
					
					else
					{
						if (!IsClientTeamBanned(target, classTeamIndex))
						{
							DoTeamBan(target, classTeamIndex, iBanTime);
							ReplyToCommand(client, "[SM] %s was successfully banned from joining %s.", targetName, classTeamArg);
						}
						
						else
						{
							ReplyToCommand(client, "[SM] %s is already banned from joining %s.", targetName, classTeamArg);
						}
					}
				}
				
				else
				{
					ReplyToCommand(client, "[SM] The time parameter should have only numbers.");
				}
			}
			
			else
			{
				ReplyToCommand(client, "[SM] Class or team not found.");
			}
		}
	}
	
	else
	{
		ReplyToCommand(client, "[SM] Usage: %s <player> <class name or team name> <ban time>.", BAN_COMMAND);
	}
}

public Action DoBanID(int client, int args)
{
	if (args == 3)
	{
		char targetID[MAX_NAME_LENGTH];
		char classTeamArg[36];
		
		GetCmdArg(1, targetID, sizeof(targetID));
		GetCmdArg(2, classTeamArg, sizeof(classTeamArg));
		
		int classTeamIndex = GetClassNum(classTeamArg);
		bool bClass = true;
		
		if (classTeamIndex == -1)
		{
			classTeamIndex = GetTeamNum(classTeamArg);
			bClass = false;
		}
		
		if (classTeamIndex != -1)
		{
			char banTime[16];
			GetCmdArg(3, banTime, sizeof(banTime));
			
			if (String_IsInteger(banTime))
			{
				int iBanTime = StringToInt(banTime);
				
				if (bClass)
				{
					if (!IsClientClassBannedID(targetID, classTeamIndex))
					{
						DoClassBanID(targetID, classTeamIndex, iBanTime);
						ReplyToCommand(client, "[SM] The player with ID %s was successfully banned from accessing %s.", targetID, classTeamArg);
					}
					
					else
					{
						ReplyToCommand(client, "[SM] The player with ID %s is already banned from accessing %s.", targetID, classTeamArg);
					}
				}
				
				else
				{
					if (!IsClientTeamBannedID(targetID, classTeamIndex))
					{
						DoTeamBanID(targetID, classTeamIndex, iBanTime);
						ReplyToCommand(client, "[SM] The player with ID %s was successfully banned from joining %s.", targetID, classTeamArg);
					}
					
					else
					{
						ReplyToCommand(client, "[SM] The player with ID %s is already banned from joining %s.", targetID, classTeamArg);
					}
				}
			}
			
			else
			{
				ReplyToCommand(client, "[SM] The time parameter should have only numbers.");
			}
		}
		
		else
		{
			ReplyToCommand(client, "[SM] Class or team not found.");
		}
	}
	
	else
	{
		ReplyToCommand(client, "[SM] Usage: %s <SteamID> <class name or team name> <ban time>.", BANID_COMMAND);
	}
}

public Action DoUnban(int client, int args)
{
	if (args == 2)
	{
		char targetName[MAX_NAME_LENGTH];
		GetCmdArg(1, targetName, sizeof(targetName));
		
		int target = FindTarget(client, targetName, true);
		
		if (target != -1)
		{
			char classTeamArg[36];
			GetCmdArg(2, classTeamArg, sizeof(classTeamArg));
			
			int classTeamIndex = GetClassNum(classTeamArg);
			bool bClass = true;
			
			if (classTeamIndex == -1)
			{
				classTeamIndex = GetTeamNum(classTeamArg);
				bClass = false;
			}
			
			if (classTeamIndex != -1)
			{
				GetClientName(target, targetName, sizeof(targetName));
				
				if (bClass)
				{
					if (IsClientClassBanned(target, classTeamIndex))
					{
						ExecUnban_Class(target, classTeamIndex);
						ReplyToCommand(client, "[SM] %s was successfully unbanned and can now access %s.", targetName, classTeamArg);
					}
					
					else
					{
						ReplyToCommand(client, "[SM] %s is not banned from accessing %s.", targetName, classTeamArg);
					}
				}
				
				else
				{
					if (IsClientTeamBanned(target, classTeamIndex))
					{
						ExecUnban_Team(target, classTeamIndex);
						ReplyToCommand(client, "[SM] %s was successfully unbanned from joining %s.", targetName, classTeamArg);
					}
					
					else
					{
						ReplyToCommand(client, "[SM] %s is not banned from joining %s.", targetName, classTeamArg);
					}
				}
			}
			
			else
			{
				ReplyToCommand(client, "[SM] Class or team not found.");
			}
		}
	}
	
	else
	{
		ReplyToCommand(client, "[SM] Usage: %s <player> <class name or team name>.", UNBAN_COMMAND);
	}
}

public Action DoUnbanID(int client, int args)
{
	if (args == 2)
	{
		char targetID[MAX_NAME_LENGTH];
		char classTeamArg[36];
		
		GetCmdArg(1, targetID, sizeof(targetID));
		GetCmdArg(2, classTeamArg, sizeof(classTeamArg));
		
		int classTeamIndex = GetClassNum(classTeamArg);
		bool bClass = true;
		
		if (classTeamIndex == -1)
		{
			classTeamIndex = GetTeamNum(classTeamArg);
			bClass = false;
		}
		
		if (classTeamIndex != -1)
		{
			if (bClass)
			{
				if (IsClientClassBannedID(targetID, classTeamIndex))
				{
					ExecUnban_ClassID(targetID, classTeamIndex);
					ReplyToCommand(client, "[SM] The player with ID %s was successfully unbanned and can now access %s.", targetID, classTeamArg);
				}
				
				else
				{
					ReplyToCommand(client, "[SM] The player with ID %s is not banned from accessing %s.", targetID, classTeamArg);
				}
			}
			
			else
			{
				if (IsClientTeamBannedID(targetID, classTeamIndex))
				{
					ExecUnban_TeamID(targetID, classTeamIndex);
					ReplyToCommand(client, "[SM] The player with ID %s was successfully unbanned from joining %s.", targetID, classTeamArg);
				}
				
				else
				{
					ReplyToCommand(client, "[SM] The player with ID %s is not banned from joining %s.", targetID, classTeamArg);
				}
			}
		}
		
		else
		{
			ReplyToCommand(client, "[SM] Class or team not found.");
		}
	}
	
	else
	{
		ReplyToCommand(client, "[SM] Usage: %s <SteamID> <class name or team name>.", UNBANID_COMMAND);
	}
}

public Action JOINCLASS(int client, const char[] command, int args)
{
	char arg1[32];
	GetCmdArg(1, arg1, 32);
	
	if (StrEqual(arg1, "random", false))
	{
		int notBanned[9];
		int notBannedCount = 0;
		
		for (int loop = 1; loop <= 9; loop++)
		{
			if (!IsClientClassBanned(client, loop))
			{
				notBanned[notBannedCount] = loop;
				notBannedCount++;
			}
		}
		
		if (notBannedCount > 0)
		{
			if (IsPlayerAlive(client) && !bInSpawn[client])
			{
				ForcePlayerSuicide(client);
			}
			
			TF2_SetPlayerClass(client, GetClassNumTFClassType(notBanned[GetRandomInt(0, notBannedCount - 1)]));
			
			if (IsPlayerAlive(client) && bInSpawn[client])
			{
				TF2_RespawnPlayer(client);
			}
			
			return Plugin_Handled;
		}
		
		else //Player is banned from all teams because notBannedCount == 0.
		{
			TryChangePlayerToSpec(client);
		}
	}
	
	else
	{
		int classnum = GetClassNum(arg1);
	
		if (classnum != -1 && IsClientClassBanned(client, classnum))
		{
			PrintTextBannedClass(client, classnum);
			return Plugin_Handled;
		}
	}
	
	return Plugin_Continue;
}

public Action JOINTEAM(int client, const char[] command, int args)
{
	char name[MAX_NAME_LENGTH];
	GetClientName(client, name, sizeof(name));
	int classBanTest;
	
	for (int loop = 1; loop <= 9; loop++)
	{
		if(IsClientClassBanned(client, loop))
		{
			classBanTest++;
		}
	}
	
	if (classBanTest < 9)
	{
		char arg1[32];
		GetCmdArg(1, arg1, 32);
		
		if (StrEqual(arg1, "auto", false))
		{
			AutoTeam_Function(client);
			return Plugin_Handled;
		}
		
		else
		{
			int TeamNum = GetTeamNum(arg1);
			
			if (IsClientTeamBanned(client, TeamNum))
			{
				PrintTextBannedTeam(client, TeamNum);
				return Plugin_Handled;
			}
			
			int cCountBlue = GetTeamClientCount(view_as<int>(TFTeam_Blue));
			int cCountRed = GetTeamClientCount(view_as<int>(TFTeam_Red));
			TFTeam ClientTeam = TF2_GetClientTeam(client);
			
			if ((view_as<int>(ClientTeam)) != TeamNum)
			{
				if (TeamNum == 3 && cCountBlue < cCountRed)
				{
					ChangeClientTeam(client, 3);
					ChangeClientToNotBannedClass(client);
					return Plugin_Handled;
				}
				
				else if (TeamNum == 2 && cCountRed < cCountBlue)
				{
					ChangeClientTeam(client, 2);
					ChangeClientToNotBannedClass(client);
					return Plugin_Handled;
				}
			}
		}
	}
	
	else
	{
		PrintCenterText(client, "You're banned from all classes, write !%s in the chat to see more information.", SHOW_BANMENU_CHATCOMMAND);
		TryChangePlayerToSpec(client);
		return Plugin_Handled;
	}
	
	return Plugin_Continue;
}

public Action AUTOTEAM(int client, const char[] command, int args)
{
	AutoTeam_Function(client);
	return Plugin_Handled;
}


void AutoTeam_Function(int client)
{
	if (TF2_GetClientTeam(client) != TFTeam_Red && TF2_GetClientTeam(client) != TFTeam_Blue)
	{
		char name[MAX_NAME_LENGTH];
		GetClientName(client, name, sizeof(name));
		int test;
		
		for (int a = 1;a <= 9;a++)
		{
			if(IsClientClassBanned(client, a))
			{
				test++;
			}
		}
		
		if (test < 9)
		{
			if (IsClientTeamBanned(client, 3) && !IsClientTeamBanned(client, 2))
			{
				ChangeClientTeam(client, 2);
				PrintToChatAll(AutomaticRed, name);
				ChangeClientToNotBannedClass(client);
			}
				
			else if (!IsClientTeamBanned(client, 3) && IsClientTeamBanned(client, 2))
			{
				ChangeClientTeam(client, 3);
				PrintToChatAll(AutomaticBlu, name);
				ChangeClientToNotBannedClass(client);
			}
				
			else if (!IsClientTeamBanned(client, 1) && IsClientTeamBanned(client, 2) && IsClientTeamBanned(client, 3))
			{
				TryChangePlayerToSpec(client);
			}
			
			else if (IsClientTeamBanned(client, 1) && IsClientTeamBanned(client, 2) && IsClientTeamBanned(client, 3))
			{
				KickClient(client, "You're banned from all teams, contact the administrator.");
			}
			
			else
			{
				int teamBlue = GetTeamClientCount(view_as<int>(TFTeam_Blue));
				int teamRed = GetTeamClientCount(view_as<int>(TFTeam_Red));
				
				if (teamBlue < teamRed)
				{
					ChangeClientTeam(client, 3);
					ChangeClientToNotBannedClass(client);
					PrintToChatAll(AutomaticBlu, name);
				}
				
				else if (teamRed < teamBlue)
				{
					ChangeClientTeam(client, 2);
					ChangeClientToNotBannedClass(client);
					PrintToChatAll(AutomaticRed, name);
				}
				
				else
				{
					int i = GetRandomInt(1, 2);
					
					if (i == 1)
					{
						ChangeClientTeam(client, 3);
						ChangeClientToNotBannedClass(client);
						PrintToChatAll(AutomaticBlu, name);
					}
					
					else
					{
						ChangeClientTeam(client, 2);
						ChangeClientToNotBannedClass(client);
						PrintToChatAll(AutomaticRed, name);
					}
				}
			}
		}
		
		else
		{
			PrintCenterText(client, "You're banned from all classes, write !%s in the chat to see more information.", SHOW_BANMENU_CHATCOMMAND);
			TryChangePlayerToSpec(client);
		}
	}
}

public Action SHOWMENU(int client, int args)
{
	if (args == 0)
	{
		DisplayBanMenu(client, client);
	}
	
	else if (args == 1)
	{
		if (CheckCommandAccess(client, UNBAN_COMMAND, ADMFLAG_UNBAN))
		{
			char targetName[PLATFORM_MAX_PATH];
			GetCmdArg(1, targetName, sizeof(targetName));
			
			int target = FindTarget(client, targetName, true);
			
			if (target != -1)
			{
				DisplayBanMenu(target, client);
			}
		}
	}
	
	else
	{
		ReplyToCommand(client, "[SM] Usage: %s or %s <player>.", SHOW_BANMENU_COMMAND, SHOW_BANMENU_COMMAND);
	}
}

void DisplayBanMenu(int client, int targetToDisplay)
{
	if (targetToDisplay > 0 && targetToDisplay <= MAXPLAYERS)
	{
		char titleBuffer[MAX_NAME_LENGTH];
		GetClientName(client, titleBuffer, sizeof(titleBuffer));
		
		Format(titleBuffer, sizeof(titleBuffer), "~Ban details for %s~", titleBuffer);
		
		Handle menu = CreateMenu(BanMenuCALLBACK, MenuAction_End);
		SetMenuTitle(menu, titleBuffer);
		
		bool test_team = false;
		bool test_class = false;
		
		for (int loop = 1; loop <= 3; loop++)
		{
			if (IsClientTeamBanned(client, loop))
			{
				test_team = true;
				
				char Num[2];
				IntToString(loop, Num, 2);
				
				char TeamName[16];
				GetTeamString(loop, TeamName, 16);
				
				String_ToUpper(TeamName);
				
				int time = GetTeamBanTime(client, loop);
				
				char Message[255];
				Format(Message, 255, "%s:", TeamName);
				
				if (time == -1)
				{
					Format(Message, 255, "%s Permanently banned.", Message);
				}
				
				else if (time == 0)
				{
					Format(Message, 255, "%s Auto unban in one minute.", Message);
				}
				
				else if (time > 0)
				{
					Format(Message, 255, "%s %d minute(s) to unban.", Message, time);
				}
					
				AddMenuItem(menu, Num, Message, ITEMDRAW_DISABLED);
			}
		}
		
		for (int loop = 1; loop <= 9; loop++)
		{
			if (IsClientClassBanned(client, loop))
			{
				test_class = true;
				
				char Num[2];
				IntToString(loop + 3, Num, 2);
				
				char ClassName[16];
				GetClassString(loop, ClassName, 16);
				
				String_ToUpper(ClassName);
				
				int time = GetClassBanTime(client, loop);
				
				char Message[255];
				Format(Message, 255, "%s:", ClassName);
				
				if (time == -1)
				{
					Format(Message, 255, "%s Permanently banned.", Message);
				}
				
				else if (time == 0)
				{
					Format(Message, 255, "%s Auto unban in one minute.", Message);
				}
				
				else if (time > 0)
				{
					Format(Message, 255, "%s %d minute(s) to unban.", Message, time);
				}
					
				AddMenuItem(menu, Num, Message, ITEMDRAW_DISABLED);
			}
		}
		
		if (!test_team)
		{
			AddMenuItem(menu, "z1", "Not banned from any team.", ITEMDRAW_DISABLED);
		}
		
		if (!test_class)
		{
			AddMenuItem(menu, "z2", "Not banned from any class.", ITEMDRAW_DISABLED);
		}
			
		DisplayMenu(menu, targetToDisplay, MENU_TIME_FOREVER);
	}
	
	else
	{
		ReplyToCommand(targetToDisplay, "[SM] You need to be in-game to use this function.");
	}
}

public int BanMenuCALLBACK(Handle menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

/////////////////////////////[ Events ]/////////////////////////////

public Action ROUND_START(Event event, const char[] name, bool dontBroadcast)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i))
		{
			TFTeam team = TF2_GetClientTeam(i);
			
			if (IsClientTeamBanned(i, view_as<int>(team)))
			{
				ChangeClientToNotBannedTeam(i);
				ChangeClientToNotBannedClass(i);
			}
		}
	}
}

/////////////////////////////[ Helpers ]/////////////////////////////

int GetClassNum(char [] class)
{
	if (StrEqual(class, "scout", false) || StrEqual(class, "1", false))
		return 1;
	else if (StrEqual(class, "soldier", false) || StrEqual(class, "2", false))
		return 2;
	else if (StrEqual(class, "pyro", false) || StrEqual(class, "3", false))
		return 3;
	else if (StrEqual(class, "demoman", false) || StrEqual(class, "4", false))
		return 4;
	else if (StrEqual(class, "heavy", false) || StrEqual(class, "heavyweapons", false) || StrEqual(class, "5", false))
		return 5;
	else if (StrEqual(class, "engineer", false) || StrEqual(class, "6", false))
		return 6;
	else if (StrEqual(class, "medic", false) || StrEqual(class, "7", false))
		return 7;
	else if (StrEqual(class, "sniper", false) || StrEqual(class, "8", false))
		return 8;
	else if (StrEqual(class, "spy", false) || StrEqual(class, "9", false))
		return 9;
		
	return -1;
}

int GetTeamNum(char [] team)
{
	if (StrEqual(team, "spectator", false) || StrEqual(team, "spectate", false) || StrEqual(team, "1", false))
		return 1;
	else if (StrEqual(team, "red", false) || StrEqual(team, "2", false))
		return 2;
	else if (StrEqual(team, "blu", false) || StrEqual(team, "blue", false) || StrEqual(team, "3", false))
		return 3;
		
	return -1;
}

void GetClassString(int class, char [] classname, int length)
{
	switch (class) {
		case 1: strcopy(classname, length, "scout");
		case 2: strcopy(classname, length, "soldier");
		case 3: strcopy(classname, length, "pyro");
		case 4: strcopy(classname, length, "demoman");
		case 5: strcopy(classname, length, "heavy");
		case 6: strcopy(classname, length, "engineer");
		case 7: strcopy(classname, length, "medic");
		case 8: strcopy(classname, length, "sniper");
		case 9: strcopy(classname, length, "spy");
	}
}

void GetTeamString(int team, char [] teamname, int length)
{
	switch (team) {
		case 1: strcopy(teamname, length, "spectator");
		case 2: strcopy(teamname, length, "red");
		case 3: strcopy(teamname, length, "blue");
	}
}

TFClassType GetClassNumTFClassType(int class)
{
	switch (class)
	{
		case 1: return TFClass_Scout;
		case 2: return TFClass_Soldier;
		case 3: return TFClass_Pyro;
		case 4: return TFClass_DemoMan;
		case 5: return TFClass_Heavy;
		case 6: return TFClass_Engineer;
		case 7: return TFClass_Medic;
		case 8: return TFClass_Sniper;
		case 9: return TFClass_Spy;
	}
	
	return TFClass_Unknown;
}

bool String_IsInteger(const char[] str)
{	
	for (int loop = 0; loop < strlen(str); loop++)
	{
		if (!IsCharNumeric(str[loop]))
		{
			return false;
		}
	}
	
	return true;
}

void String_ToUpper(char[] str)
{
	for (int loop = 0; loop < strlen(str); loop++)
	{
		if (!IsCharNumeric(str[loop]) && !IsCharUpper(str[loop]))
		{
			str[loop] = CharToUpper(str[loop]);
		}
	}
}

void ChangeClientToNotBannedClass(int client)
{
	for (int i=1; i<=10; i++)
	{
		if (i == 10)
		{
			TryChangePlayerToSpec(client);
		} 
		
		else
		{
			if (!IsClientClassBanned(client, i))
			{
				TF2_SetPlayerClass(client, view_as<TFClassType>(i));
				
				if (IsPlayerAlive(client))
				{
					TF2_RespawnPlayer(client);
				}
					
				break;
			}
		}
	}
}

void ChangeClientToNotBannedTeam(int client)
{
	if (!IsClientTeamBanned(client, 3))
	{
		ChangeClientTeam(client, 3);
	}
	
	else if (!IsClientTeamBanned(client, 2))
	{
		ChangeClientTeam(client, 2);
	}
	
	else if (!IsClientTeamBanned(client, 1))
	{
		ChangeClientTeam(client, 1);
	}
	
	else
	{
		KickClient(client, "You're banned from all teams. Please contact the administrator for more information.");
	}
}

void PrintTextBannedClass(int client, int class)
{
	char ClassName[16];
	GetClassString(class, ClassName, 16);
	int time = GetClassBanTime(client, class);

	if (time == -1)
	{
		PrintCenterText(client, "You're permanently banned from selecting %s.", ClassName);
	}
	
	else if (time == 0)
	{
		PrintCenterText(client, "You're banned from selecting %s. You'll be able to access it in one minute.", ClassName);
	}
	
	else if (time > 0)
	{
		PrintCenterText(client, "You're banned from selecting %s. You'll be able to access it in %d minute(s).", ClassName, time);
	}
}

void PrintTextBannedTeam(int client, int team)
{
	char TeamName[16];
	GetTeamString(team, TeamName, 16);
	int time = GetTeamBanTime(client, team);
	
	if (time == -1)
	{
		PrintCenterText(client, "You're permanently banned from joining %s.", TeamName);
	}
	
	else if (time == 0)
	{
		PrintCenterText(client, "You're banned from joining %s. You'll be able to access it in one minute.", TeamName);
	}
	
	else if (time > 0)
	{
		PrintCenterText(client, "You're banned from joining %s. You'll be able to access it in %d minute(s).", TeamName, time);
	}
}

void TryChangePlayerToSpec(int client)
{
	if (!IsClientTeamBanned(client, 1))
	{
		ChangeClientTeam(client, 1);
	}
	
	else
	{
		if (!IsClientTeamBanned(client, 2))
		{
			ChangeClientTeam(client, 3);
		}
		
		else if (!IsClientTeamBanned(client, 3))
		{
			ChangeClientTeam(client, 2);
		}
		
		else
		{
			KickClient(client, "You're banned from all teams. Please contact the administrator for more information.");
		}
	}
}

/////////////////////////////[ Ban control functions ]/////////////////////////////

void DoClassBan(int client, int class, int time)
{
	char SID[32];
	GetClientAuthId(client, AuthId_Steam3, SID, 32);
	
	DoClassBanID(SID, class, time);
	
	if (TF2_GetPlayerClass(client) == GetClassNumTFClassType(class))
	{
		ChangeClientToNotBannedClass(client);
		ForcePlayerSuicide(client);
	}
}

void DoClassBanID(char[] SID, int class, int time)
{
	if (time == 0)
	{
		time = -1;
	} 
	
	else 
	{
		int systime = GetTime();
		time = time * 60;
		time = time + systime;
	}
	
	if(KvJumpToKey(DB, SID, true))
	{			
		char ClassName[16];
		GetClassString(class, ClassName, 16);
		
		KvSetNum(DB, ClassName, time);
	}
	
	KvRewind(DB);
}

void DoTeamBan(int client, int team, int time)
{
	char SID[32];
	GetClientAuthId(client, AuthId_Steam3, SID, 32);
	
	DoTeamBanID(SID, team, time);
	
	if (TF2_GetClientTeam(client) == (view_as<TFTeam>(team)))
	{
		ChangeClientToNotBannedTeam(client);
		ForcePlayerSuicide(client);
	}
}

void DoTeamBanID(char[] SID, int team, int time)
{
	if (time == 0)
	{
		time = -1;
	}
	
	else 
	{
		int systime = GetTime();
		time = time * 60;
		time = time + systime;
	}
	
	if(KvJumpToKey(DB, SID, true))
	{		
		char TeamName[16];
		GetTeamString(team, TeamName, 16);
		KvSetNum(DB, TeamName, time);
	}
	
	KvRewind(DB);
}

bool IsClientClassBanned(int client, int class)
{
	char SID[32];
	GetClientAuthId(client, AuthId_Steam3, SID, 32);
	
	return IsClientClassBannedID(SID, class);
}

bool IsClientClassBannedID(char[] SID, int class)
{	
	int i;
	int systime = GetTime();
	
	if(KvJumpToKey(DB, SID, false))
	{			
		char ClassName[16];
		GetClassString(class, ClassName, 16);
		
		i = KvGetNum(DB, ClassName, 0);
		
		if (i <= systime && i != -1 && i != 0)
		{
			KvSetNum(DB, ClassName, 0);
			i = 0;
		}
	}
	
	KvRewind(DB);
	
	if (i != 0)
	{
		return true;
	}
	
	return false;
}

bool IsClientTeamBanned(int client, int team)
{
	char SID[32];
	GetClientAuthId(client, AuthId_Steam3, SID, 32);
	
	return IsClientTeamBannedID(SID, team);
}

bool IsClientTeamBannedID(char[] SID, int team)
{
	int i;
	int systime = GetTime();

	if(KvJumpToKey(DB, SID, false))
	{		
		char TeamName[16];
		GetTeamString(team, TeamName, 16);
		
		i = KvGetNum(DB, TeamName, 0);
		
		if (i <= systime && i != -1 && i != 0)
		{
			KvSetNum(DB, TeamName, 0);
			i = 0;
		}
	}
	
	KvRewind(DB);
	
	if (i == -1 || i != 0)
	{
		return true;
	}
	
	return false;
}

int GetClassBanTime(int client, int class)
{
	int i;
	int systime = GetTime();

	char SID[32];
	GetClientAuthId(client, AuthId_Steam3, SID, sizeof(SID));
	
	if(KvJumpToKey(DB, SID, false))
	{		
		char ClassName[16];
		GetClassString(class, ClassName, 16);
		i = KvGetNum(DB, ClassName, 0);
	}
	
	KvRewind(DB);
	
	if (i > 0)
	{
		i = i - systime;
		i = i / 60;
	}
	
	return i;
}

int GetTeamBanTime(int client, int team)
{
	int i;
	int systime = GetTime();

	char SID[32];
	GetClientAuthId(client, AuthId_Steam3, SID, sizeof(SID));
	
	if(KvJumpToKey(DB, SID, false))
	{
		char TeamName[16];
		GetTeamString(team, TeamName, 16);
		
		i = KvGetNum(DB, TeamName, 0);
	}
	
	KvRewind(DB);
	
	if (i > 0)
	{
		i = i - systime;
		i = i / 60;
	}
	
	return i;
}

void ExecUnban_Class(int client, int class)
{
	char SID[32];
	GetClientAuthId(client, AuthId_Steam3, SID, 32);
	
	ExecUnban_ClassID(SID, class);
}

void ExecUnban_ClassID(char[] SID, int class)
{	
	if(KvJumpToKey(DB, SID, false))
	{	
		char ClassName[16];
		GetClassString(class, ClassName, 16);
		
		if (KvGetNum(DB, ClassName, 0) != 0)
		{
			KvSetNum(DB, ClassName, 0);
		}			
	}
	
	KvRewind(DB);
}

void ExecUnban_Team(int client, int team)
{
	char SID[32];
	GetClientAuthId(client, AuthId_Steam3, SID, 32);
	
	ExecUnban_TeamID(SID, team);
}

void ExecUnban_TeamID(char[] SID, int team)
{
	if(KvJumpToKey(DB, SID, false))
	{			
		char TeamName[16];
		GetTeamString(team, TeamName, 16);
		
		if (KvGetNum(DB, TeamName, 0) != 0)
		{
			KvSetNum(DB, TeamName, 0);
		}
	}
	
	KvRewind(DB);
}