/**
 * vim: set ai et ts=4 sw=4 :
 * File: MaxClass.sp
 * Description: Set max players for each class
 * Author(s): Nican132
 * Versions:
 *      4.0 : by -=|JFH|=-Naris (Murray Wilson)
 *                Use tf2_stocks
 *                Pick random class to switch to
 *                Use ConVars for admin settings
 *                Display class selection menu when switching
 *
 *		4.3 : by cadavor
 * 			Add translations
 *		4.4 : by JameLess
 *			Fixed skin glitching
 *		4.5 : by Thraka
 *			Added the ability to load settings based on the prefix of the map. Example: pl is payload, cp is capture point.
 * 			Logs which section of the config is loading the settings.
 *		4.6 : by Thraka
 *			Added the NO! class sounds when player chooses a class that is full. This was pulled from DJ Tsunami's class restriction plugin
 *		4.7 : by Thraka & Jameless
 *			Request from snelvuur - Added the sm_maxclass_allow_adminsdeadclass cvar. If set to 0, this will not let admins play restricted classes
 *		4.8 : by Jameless
 *			Added the sm_maxclass_admin_flag cvar.  This will allow you to change what flag is immune.
 */

#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <tf2_stocks>

#define PL_VERSION "4.8"

#define DEBUG 0
//To change the flag, look at: http://docs.sourcemod.net/api/index.php?fastload=file&id=28& for the right values
#define TF2L_ADMIN_FLAG Admin_Reservation

public Plugin:myinfo = 
{
	name = "TF Max Players",
	author = "Nican132,cadavor,JameLess,Thraka",
	description = "Set max players for each class",
	version = PL_VERSION,
	url = "http://sourcemod.net/"
};	   

//[amount of players][team][class] max amount
new MaxClass[MAXPLAYERS][TFTeam + TFTeam:1][TFClassType + TFClassType:1];
//[team][class] count array
new CurrentCount[TFTeam + TFTeam:1][TFClassType + TFClassType:1];
new bool:isrunning;
new Handle:IsMaxPlayersOn;
new Handle:ConfigFileName;
new Handle:CheckAdmins;
new Handle:CountAdmins;
new Handle:CVAR_AllowAdminsDeadClass;
new Handle:CVAR_Adminflag;
new maxplayers;

static String:ClassNames[TFClassType][] = {"", "Scout", "Sniper", "Soldier", "Demoman", "Medic", "Heavy Guy", "Pyro", "Spy", "Engineer" };
static String:TF_ClassNames[TFClassType][] = {"", "scout", "sniper", "soldier", "demoman", "medic", "heavyweapons", "pyro", "spy", "engineer" };
new String:g_sSounds[10][24] = {"", "vo/scout_no03.wav",   "vo/sniper_no04.wav", "vo/soldier_no01.wav",
																		"vo/demoman_no03.wav", "vo/medic_no03.wav",  "vo/heavy_no02.wav",
																		"vo/pyro_no01.wav",    "vo/spy_no02.wav",    "vo/engineer_no03.wav"};

public OnPluginStart()
{
	LoadTranslations("maxclass.phrases");

	CreateConVar("sm_tf_maxclass", PL_VERSION, "TF2 max class", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	IsMaxPlayersOn = CreateConVar("sm_maxclass_allow","1","Enable/Disable max class blocking");
	CheckAdmins = CreateConVar("sm_maxclass_exclude_admins","0","Enable/Disable admin exclusion");
	CountAdmins = CreateConVar("sm_maxclass_count_admins","0","Enable/Disable admins counting towards class limits");
	ConfigFileName = CreateConVar("sm_maxclass_config","MaxClass.txt","config file name");
	CVAR_AllowAdminsDeadClass = CreateConVar("sm_maxclass_allow_adminsdeadclass","1","Enable/Disable admins to choose restricted classes (0 in config)");
	CVAR_Adminflag = CreateConVar("sm_maxclass_admin_flag","a","Flag for admin immunity");
	
	HookEvent("player_changeclass", PlayerChangeClass, EventHookMode_Pre);
	HookEvent("player_spawn", PlayerSpawn, EventHookMode_Pre);
	HookEvent("teamplay_teambalanced_player", PlayerTeamBalanced, EventHookMode_Pre);

	RegAdminCmd("sm_classlimit", Command_PrintTable, ADMFLAG_CUSTOM4, "Re-reads and prints the limits");
	//RegConsoleCmd("sm_classlimit", Command_PrintTable)

	AutoExecConfig(true, "maxclass");
}


public OnMapStart()
{
	maxplayers = GetMaxClients();

	StartReadingFromTable();
	
	decl i, String:sSound[32];
	for(i = 1; i < sizeof(g_sSounds); i++)
	{
		Format(sSound, sizeof(sSound), "sound/%s", g_sSounds[i]);
		PrecacheSound(g_sSounds[i]);
		AddFileToDownloadsTable(sSound);
	}
}

public Action:PlayerTeamBalanced(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!isrunning)
		return;

	if (!GetConVarBool(IsMaxPlayersOn))
		return;

	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (client <= 0)
		return;

	new TFTeam:team = TFTeam:GetEventInt(event, "team");
	if (team < TFTeam_Red ||  team > TFTeam_Blue)
		return;

	new TFClassType:class = TF2_GetPlayerClass(client);
	if (class == TFClass_Unknown)
		return;
	
	new clientcount = GetClientCount(true);
		
	if (GetConVarBool(CheckAdmins))
	{
		if (CheckForAdmin(client))
		{
			if (MaxClass[clientcount][team][class] == 0)
			{
				if (GetConVarBool(CVAR_AllowAdminsDeadClass))				
					return;
				
			}
			else
				return;
		}
	}

#if DEBUG == 1
	LogMessage("Teambalanced: %N", client);
#endif

	if (MaxClass[clientcount][team][class] <= -1)
		return;

	RecountClasses();

	if (CurrentCount[team][class] > MaxClass[clientcount][team][class])
	{
		PrintToChat(client, "\x04[MaxClass]\x01 %t", "Class Overflow", ClassNames[class]);
		PrintCenterText(client, "%t", "Class Overflow", ClassNames[class]);
		
		SwitchClientClass(client, FindUnusedClass(team, clientcount));
		TF2_RegeneratePlayer(client);
	}
}

public Action:PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!isrunning)
		return;

	if (!GetConVarBool(IsMaxPlayersOn))
		return;

	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (!client)
		return;

	new TFTeam:team = TFTeam:GetClientTeam(client);
	if (team < TFTeam_Red ||  team > TFTeam_Blue)
		return;

	new TFClassType:class = TF2_GetPlayerClass(client);
	if (class == TFClass_Unknown)
		return;

	new clientcount = GetClientCount(true);
	
	if (GetConVarBool(CheckAdmins))
	{
		if (CheckForAdmin(client))
		{
			if (MaxClass[clientcount][team][class] == 0)
			{
				if (GetConVarBool(CVAR_AllowAdminsDeadClass))				
					return;
				
			}
			else
				return;
		}
	}

	if (MaxClass[clientcount][team][class] <= -1)
		return;

#if DEBUG == 1
	LogMessage("PlayerSpawn: %N", client);
#endif

	RecountClasses();

	if (CurrentCount[team][class] > MaxClass[clientcount][team][class])
	{
		PrintToChat(client, "\x04[MaxClass]\x01 %t", "Class Overflow", ClassNames[class]);
		PrintCenterText(client, "%t", "Class Overflow", ClassNames[class]);
		EmitSoundToClient(client, g_sSounds[class]);
		
		SwitchClientClass(client, FindUnusedClass(team, clientcount));
		TF2_RegeneratePlayer(client);
	}
}

public Action:PlayerChangeClass(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!isrunning)
		return;

	if (!GetConVarBool(IsMaxPlayersOn))
		return;

	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (!client)
		return;

	new TFClassType:class = TFClassType:GetEventInt(event, "class");
	new TFClassType:oldclass = TF2_GetPlayerClass(client);

	if (class == oldclass)
		return;

	if (class == TFClass_Unknown)
		return;

	new TFTeam:team = TFTeam:GetClientTeam(client);
	if (team < TFTeam_Red ||  team > TFTeam_Blue)
		return;

	new clientcount = GetClientCount(true);
	
	if (GetConVarBool(CheckAdmins))
	{
		if (CheckForAdmin(client))
		{
			if (MaxClass[clientcount][team][class] == 0)
			{
				if (GetConVarBool(CVAR_AllowAdminsDeadClass))				
					return;
				
			}
			else
				return;
		}
	}
	
#if DEBUG == 1
	LogMessage("ChangeClass: %N", client);
#endif

	
	if (MaxClass[clientcount][team][class] <= -1)
		return;

	RecountClasses();

	if (CurrentCount[team][class] >= MaxClass[clientcount][team][class])
	{
		EmitSoundToClient(client, g_sSounds[class]);
		
		if (MaxClass[clientcount][team][class] == 0)
		{
			PrintToChat(client, "\x04[MaxClass]\x01 %t", "Not allowed", ClassNames[class]);
			PrintCenterText(client, "%t", "Not allowed", ClassNames[class]);
		}
		else
		{
			PrintToChat(client, "\x04[MaxClass]\x01 %t", "Classfull", ClassNames[class]);
			PrintCenterText(client, "%t", "Classfull", ClassNames[class]);
		}

		//If the user just connected to server, his class is 0, with is nothing, let's just pick a random class
		if (oldclass == TFClass_Unknown)
			oldclass = FindUnusedClass(team, clientcount);

		SwitchClientClass(client, oldclass);
	}
}

TFClassType:FindUnusedClass(TFTeam:team, clientcount)
{
	// Start with a random class each time
	new TFClassType:pick = TFClassType:GetRandomInt(1,9);
	new TFClassType:c = pick;
	for (;;)
	{
		if ((MaxClass[clientcount][team][c] == -1) || (CurrentCount[team][c] < MaxClass[clientcount][team][c]) )
			return c;
		else
		{
			c++;
			if (c > TFClass_Engineer)	// Wrap back to 1st class
				c = TFClass_Scout;

			if (c == pick) // if we hit the initial class, all classes must be full
				break;
		}
	}
	return TFClass_Unknown;
}

RecountClasses()
{
	for (new TFClassType:c=TFClass_Unknown; c<=TFClass_Engineer; c++)
	{
		CurrentCount[TFTeam_Red][c] = 0;
		CurrentCount[TFTeam_Blue][c] = 0;
	}
	
	new bool:LookForAdmin = GetConVarBool(CheckAdmins) && !GetConVarBool(CountAdmins);

	for (new i=1; i<=maxplayers; i++)
	{
		if (IsClientInGame(i))
		{
			if (LookForAdmin)
			{
				if (CheckForAdmin( i ))
					continue;
			}
			CurrentCount[ TFTeam:GetClientTeam(i) ][ TF2_GetPlayerClass(i) ]++;
		}
	}
}

bool:StartReadingFromTable()
{
	decl String:file[PLATFORM_MAX_PATH];
	decl String:config[PLATFORM_MAX_PATH];
	decl String:mapname[32];
	GetConVarString(ConfigFileName, config, sizeof(config));
	BuildPath(Path_SM, file, sizeof(file),"configs/%s", config);

	if (!FileExists(file))
	  BuildPath(Path_SM, file, sizeof(file),"configs/%s", "MaxClass.txt");

	if (!FileExists(file))
	{
		LogError("[MaxClass] Class manager is not running! Could not find file %s", file);
		isrunning = false;
		return false;
	}

	new Handle:kv = CreateKeyValues("MaxClassPlayers");
	FileToKeyValues(kv, file);

	//Get in the first sub-key, first look for the map, then look for default
	GetCurrentMap(mapname, sizeof(mapname));
	if (!KvJumpToKey(kv, mapname))
	{
		// Check for map type!
		SplitString(mapname, "_", mapname, sizeof(mapname));
		
		if (!KvJumpToKey(kv, mapname))
		{
			if (!KvJumpToKey(kv, "default"))
			{
				LogError("[MaxClass] Class manager is not running! Could not find where to read from file");
				isrunning = false;
				return false;
			}
			else
				LogMessage("Loading class config for default");
		}
		else
			LogMessage("Loading class config from map type: %s", mapname);
	}
	else
		LogMessage("Loading class config from map: %s", mapname);
	
	//There is nothing else that can give errors, the pluggin in running!
	isrunning = true;

	new MaxPlayers[TFClassType + TFClassType:1], breakpoint, iStart, iEnd, i, TFTeam:a;
	decl String:buffer[64],String:start[32], String:end[32];
	new redblue[TFTeam];

	//Reset all numbers to -1
	for (i=0; i<10; i++)
	{
		MaxPlayers[i] = -1;
	}

	for (i=0; i<=maxplayers; i++)
	{
		for (a=TFTeam_Unassigned; a <= TFTeam_Blue; a++)
		{
			MaxClass[i][a] = MaxPlayers;
		}
	}


	if (!KvGotoFirstSubKey(kv))
	{
		//If there is nothing in there, what there is to read?
		return true;
	}

	do
	{
		KvGetSectionName(kv, buffer, sizeof(buffer));

		//Collect all data
		MaxPlayers[TFClass_Scout] =	KvGetNum(kv, TF_ClassNames[TFClass_Scout], -1);
		MaxPlayers[TFClass_Sniper] =   KvGetNum(kv, TF_ClassNames[TFClass_Sniper], -1);
		MaxPlayers[TFClass_Soldier] =  KvGetNum(kv, TF_ClassNames[TFClass_Soldier], -1);
		MaxPlayers[TFClass_DemoMan] =  KvGetNum(kv, TF_ClassNames[TFClass_DemoMan], -1);
		MaxPlayers[TFClass_Medic] =	KvGetNum(kv, TF_ClassNames[TFClass_Medic], -1);
		MaxPlayers[TFClass_Heavy] =	KvGetNum(kv, TF_ClassNames[TFClass_Heavy], -1);
		MaxPlayers[TFClass_Pyro] =	 KvGetNum(kv, TF_ClassNames[TFClass_Pyro], -1);
		MaxPlayers[TFClass_Spy] =	  KvGetNum(kv, TF_ClassNames[TFClass_Spy], -1);
		MaxPlayers[TFClass_Engineer] = KvGetNum(kv, TF_ClassNames[TFClass_Engineer], -1);

		//God... I hate having bad english, fix it if it does not find
		if (MaxPlayers[TFClass_Engineer] == -1)
			MaxPlayers[TFClass_Engineer] = KvGetNum(kv, "engenner", -1);

		//Why am I doing the 4 teams if there are only 2?
		redblue[TFTeam_Red] =  KvGetNum(kv, "team2", 1);
		redblue[TFTeam_Blue] =  KvGetNum(kv, "team3", 1);

		if (redblue[TFTeam_Red] == 1)
			redblue[TFTeam_Red] =  KvGetNum(kv, "red", 1);

		if (redblue[TFTeam_Blue] == 1)
			redblue[TFTeam_Blue] =  KvGetNum(kv, "blue", 1);

		if ((redblue[TFTeam_Red] + redblue[TFTeam_Blue]) == 0)
			continue;

		//Just 1 number
		if (StrContains(buffer,"-") == -1)
		{	
			iStart = CheckBoundries(StringToInt(buffer));

			for (a=TFTeam_Unassigned; a<= TFTeam_Blue; a++)
			{
				if (redblue[a] == 1)
					MaxClass[iStart][a] = MaxPlayers;			
			}
			//A range, like 1-5
		}
		else
		{
			//Break the "1-5" into "1" and "5"
			breakpoint = SplitString(buffer,"-",start,sizeof(buffer));
			strcopy(end,sizeof(end),buffer[breakpoint]);
			TrimString(start);
			TrimString(end);

			//make "1" and "5" into integers
			//Check boundries, see if does not go out of the array limits
			iStart = CheckBoundries(StringToInt(start));
			iEnd = CheckBoundries(StringToInt(end));

			//Copy data to the global array for each one in the range
			for (i= iStart; i<= iEnd;i++)
			{
				for (a=TFTeam_Unassigned; a<= TFTeam_Blue; a++)
				{
					if (redblue[a] == 1)
						MaxClass[i][a] = MaxPlayers;			
				}
			}
		}	
	} while (KvGotoNextKey(kv));

	CloseHandle(kv);

	return false;
}

CheckBoundries(i)
{
	if (i < 0)
		return 0;
	else if (i > MAXPLAYERS)
		return MAXPLAYERS;
	else
		return i;
}

public Action:Command_PrintTable(client, args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_classlimit <#team>");
		return Plugin_Handled;
	}

	decl String:teamstr[64];
	GetCmdArg(1, teamstr, sizeof(teamstr));
	new i, TFTeam:team = TFTeam:StringToInt(teamstr);

	StartReadingFromTable();

	if (team < TFTeam_Red || team > TFTeam_Blue)
	{
		ReplyToCommand(client, "[SM] %d is not a valid team. 2=red and 3=blue.", team);
		return Plugin_Handled;
	}

	if (client == 0)
		PrintToServer("Players Sco Sni Sol Dem Med Hea Pyr Spy Eng");
	else	
		PrintToConsole(client,"Players Sco Sni Sol Dem Med Hea Pyr Spy Eng");

	for (i=1; i<= maxplayers; i++)
	{
		if (client == 0)
		{
			PrintToServer("%d		 %d   %d   %d   %d   %d   %d   %d   %d   %d",
						  i, MaxClass[i][team][TFClass_Scout], MaxClass[i][team][TFClass_Sniper],
						  MaxClass[i][team][TFClass_Soldier],MaxClass[i][team][TFClass_DemoMan],
						  MaxClass[i][team][TFClass_Medic],MaxClass[i][team][TFClass_Heavy],
						  MaxClass[i][team][TFClass_Pyro],MaxClass[i][team][TFClass_Spy],
						  MaxClass[i][team][TFClass_Engineer]);		
		}
		else
		{
			PrintToConsole(client, "%d		 %d   %d   %d   %d   %d   %d   %d   %d   %d",
						   i, MaxClass[i][team][TFClass_Scout], MaxClass[i][team][TFClass_Sniper],
						   MaxClass[i][team][TFClass_Soldier],MaxClass[i][team][TFClass_DemoMan],
						   MaxClass[i][team][TFClass_Medic],MaxClass[i][team][TFClass_Heavy],
						   MaxClass[i][team][TFClass_Pyro],MaxClass[i][team][TFClass_Spy],
						   MaxClass[i][team][TFClass_Engineer]);
		}
	}

	return Plugin_Handled;
}

stock SwitchClientClass(client, TFClassType:class)
{
#if DEBUG == 1
	LogMessage("Changing class: %N ---- %d", client, class);
#endif
	//FakeClientCommand(client, "joinclass %s", TF_ClassNames[class]);
	//FakeClientCommandEx(client, "joinclass %s", TF_ClassNames[class]); 
	TF2_SetPlayerClass(client, class, false, true);
	ShowVGUIPanel(client, GetClientTeam(client) == 3 ? "class_blue" : "class_red");
}


stock bool:CheckForAdmin( client )
{
	new String:Flag[16];
	GetConVarString(CVAR_Adminflag, Flag, sizeof(Flag));
	if (client == 0 || GetUserFlagBits(client)&ReadFlagString(Flag) > 0 || GetUserFlagBits(client)&ADMFLAG_ROOT > 0)
	{
		return true;
	}
	else return false;
}
