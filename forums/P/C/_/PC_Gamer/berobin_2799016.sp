#pragma semicolon 1

#include <sdkhooks>
#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>
#include <tf2items>
#include <multicolors>
#include <adminmenu>

#define PLUGIN_VERSION "1.7.9a"

#pragma newdecls required

#define TEAM_CLASSNAME "tf_team"

//bool//
bool g_bEnable;
bool g_bIsRobin[MAXPLAYERS+1];
bool g_bMusicPrecached;
bool g_bMusicPlayed;
bool g_bForceSoldier;
bool g_bCanChangeClass;
bool g_bCanChangeTeam;
bool g_bCanAttackEveryone;
bool g_bConserveBuildings;
bool g_bIsSoldier[MAXPLAYERS+1];
bool g_bIsRenamedClient[MAXPLAYERS+1];
bool g_bCanBeRobin[MAXPLAYERS+1];
bool g_bCanBeRobin2[MAXPLAYERS+1];
bool g_bIsInThirdPerson[MAXPLAYERS+1];
bool g_bIsInSpawn[MAXPLAYERS+1];
bool g_bBuildingsDisabled[MAXPLAYERS+1];
bool g_bWaitingForPlayers;
bool g_bIsMusicEmpty = true;
bool g_bChangeName;
////////

//Handle//
Handle g_hTimer;
Handle g_Hhud;
Handle g_hSDKTeamAddPlayer;
Handle g_hSDKTeamRemovePlayer;
//////////

//Convar//
ConVar g_hEnable;
ConVar g_hMusic;
ConVar g_hSoundDuration;
ConVar g_hForceSoldier;
ConVar g_hCanChangeClass;
ConVar g_hCanChangeTeam;
ConVar g_hCanAttackEveryone;
ConVar g_hConserveBuildings;
ConVar g_hChangeName;
//////////

//Others//
char g_cMusic[256];
float g_fSoundDuration;
char g_SaveName[MAXPLAYERS+1][MAX_NAME_LENGTH];
char g_SaveNameDebug[MAXPLAYERS+1][MAX_NAME_LENGTH];
int g_iLastClientClass[MAXPLAYERS+1];
int g_iLastClientTeam[MAXPLAYERS+1];
TopMenu g_hTopMenu;
//////////

public Plugin myinfo =
{
	name = "[TF2] Be Robin Walker",
	author = "Whai",	
	description = "Get PowerPlay and Valve Rocket Launcher to destroy everything, even the server",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=311751"
}

public void OnPluginStart()
{
	RegisterCmds();
	RegisterCvars();
	RegisterCmdLisners();
	HookEvents();

	HookUserMessage(GetUserMessageId("SayText2"), UserMessageRename, true);			//Hide name change
	
	LoadTranslations("common.phrases");
	
	AutoExecConfig(true, "be-robinwalker");
	
	g_Hhud = CreateHudSynchronizer();
	
	TopMenu topmenu;
	if(LibraryExists("adminmenu") && ((topmenu = GetAdminTopMenu()) != null))
		OnAdminMenuReady(topmenu);

	Handle hGameData = LoadGameConfigFile("tf2.changeteam");

	StartPrepSDKCall(SDKCall_Entity);
	PrepSDKCall_SetFromConf(hGameData, SDKConf_Virtual, "CTeam::AddPlayer");
	PrepSDKCall_AddParameter(SDKType_CBasePlayer, SDKPass_Pointer);
	g_hSDKTeamAddPlayer = EndPrepSDKCall();
	if(g_hSDKTeamAddPlayer == INVALID_HANDLE)
		SetFailState("Could not find CTeam::AddPlayer!");

	StartPrepSDKCall(SDKCall_Entity);
	PrepSDKCall_SetFromConf(hGameData, SDKConf_Virtual, "CTeam::RemovePlayer");
	PrepSDKCall_AddParameter(SDKType_CBasePlayer, SDKPass_Pointer);
	g_hSDKTeamRemovePlayer = EndPrepSDKCall();
	if(g_hSDKTeamRemovePlayer == INVALID_HANDLE)
		SetFailState("Could not find CTeam::RemovePlayer!");

	delete hGameData;

}

public void OnLibraryRemoved(const char[] strName)
{
	if(!strcmp(strName, "adminmenu"))
		g_hTopMenu = null;
		
}

void RegisterCmds()
{
	RegAdminCmd("sm_berobinwalker", Command_RobinWalker, ADMFLAG_SLAY, "Enable the effect");

	RegAdminCmd("sm_condump_on", Command_Robin, ADMFLAG_SLAY, "Enable the effect"); 
	RegAdminCmd("sm_condump_off", Command_NotRobin, ADMFLAG_SLAY, "Disable the effect");
	
	RegAdminCmd("sm_robinmenu", Command_MenuRobin, ADMFLAG_SLAY, "Display Robin menu");
	RegAdminCmd("sm_beromenu", Command_RobinMenu, ADMFLAG_SLAY, "Display a menu to toggle a player to Robin Walker");
	
	RegConsoleCmd("sm_resettp", Command_ResetTP, "Set firstperson view to the target");
	RegConsoleCmd("sm_robineffects", Command_CondMenu, "Display effects menu");
}

void RegisterCvars()
{
	CreateConVar("sm_berobin_version", PLUGIN_VERSION, "The Version of Be Robin Walker", FCVAR_SPONLY|FCVAR_NOTIFY);
	
	g_hMusic = CreateConVar("sm_bero_sound", "ui/gamestartup26.mp3", "Music played when Robin Walker appears");
	g_hMusic.AddChangeHook(ConVarChanged);
	
	g_hSoundDuration = CreateConVar("sm_bero_soundtime", "96.5", "The duration of the chosed music", 0, true, 0.0, false);
	g_hSoundDuration.AddChangeHook(ConVarChanged);
	
	g_hEnable = CreateConVar("sm_bero_enable", "1", "Enable/Disable the plugin", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_hEnable.AddChangeHook(ConVarChanged);
	
	g_hForceSoldier = CreateConVar("sm_bero_forcesoldier", "1", "Force the player to be a soldier when he'll be the TF2 creator", 0, true, 0.0, true, 1.0);
	g_hForceSoldier.AddChangeHook(ConVarChanged);
	
	g_hCanChangeClass = CreateConVar("sm_bero_canchangeclass", "0", "If the player can change class while being Robin Walker", 0, true, 0.0, true, 1.0);
	g_hCanChangeClass.AddChangeHook(ConVarChanged);
	
	g_hCanChangeTeam = CreateConVar("sm_bero_canchangeteam", "0", "If the player can change team while being Robin Walker", 0, true, 0.0, true, 1.0);
	g_hCanChangeTeam.AddChangeHook(ConVarChanged);
	
	g_hCanAttackEveryone = CreateConVar("sm_bero_canattackeveryone", "0", "Enable/Disable Robin Walker can attack everyone even his teammates", 0, true, 0.0, true, 1.0);
	g_hCanAttackEveryone.AddChangeHook(ConVarChanged);
	
	g_hConserveBuildings = CreateConVar("sm_bero_conservebuildings", "1", "Enable/Disable Conserve his buildings when he is Robin Walker", 0, true, 0.0, true, 1.0);
	g_hConserveBuildings.AddChangeHook(ConVarChanged);
	
	g_hChangeName = CreateConVar("sm_bero_changename", "0", "Enable/Disable changing name to Robin Walker", 0, true, 0.0, true, 1.0);
	g_hChangeName.AddChangeHook(ConVarChanged);	
}

void RegisterCmdLisners()
{
	AddCommandListener(Player_ChangeClassBlock, "joinclass");
	AddCommandListener(Player_ChangeClassBlock, "join_class");
	AddCommandListener(Player_ChangeClassBlock, "changeteam");
	AddCommandListener(Player_CallMedic, "voicemenu");
	AddCommandListener(Player_ChangeTeamBlock, "jointeam");
	AddCommandListener(Player_ChangeTeamBlock, "changeteam");
}

void HookEvents()
{
	HookEvent("player_death", Player_Died);
	HookEvent("player_spawn", Player_Spawn);
	HookEvent("player_changeclass", Player_ChangeClass);
	HookEvent("player_team", Player_Team, EventHookMode_Pre);
	HookEvent("player_sapped_object", BuildingsSapped);
	HookEvent("teamplay_round_start", RoundStart, EventHookMode_PostNoCopy);
	HookEvent("arena_round_start", RoundStart, EventHookMode_PostNoCopy);
	HookEvent("teamplay_round_win", RoundEnd);
	HookEvent("mvm_wave_failed", WaveFailed);
	HookEvent("post_inventory_application", WeaponReset);
}

public void ConVarChanged(ConVar hConVar, const char[] strOldValue, const char[] strNewValue)
{
	if(hConVar == g_hMusic)
	{
		GetConVarString(g_hMusic, g_cMusic, sizeof(g_cMusic));
		g_bIsMusicEmpty = g_cMusic[0] == '\0';
		if(!g_bIsMusicEmpty)
			g_bMusicPrecached = PrecacheSound(g_cMusic, true);
	}
	
	if(hConVar == g_hSoundDuration)
		g_fSoundDuration = StringToFloat(strNewValue);
		
	if(hConVar == g_hEnable)
		g_bEnable = view_as<bool>(StringToInt(strNewValue));
	
	if(hConVar == g_hForceSoldier)
		g_bForceSoldier = view_as<bool>(StringToInt(strNewValue));
	
	if(hConVar == g_hCanChangeClass)
		g_bCanChangeClass = view_as<bool>(StringToInt(strNewValue));
	
	if(hConVar == g_hCanAttackEveryone)
		g_bCanAttackEveryone = view_as<bool>(StringToInt(strNewValue));
	
	if(hConVar == g_hCanChangeTeam)
		g_bCanChangeTeam = view_as<bool>(StringToInt(strNewValue));
	
	if(hConVar == g_hConserveBuildings)
		g_bConserveBuildings = view_as<bool>(StringToInt(strNewValue));
	
	if(hConVar == g_hChangeName)
		g_bChangeName = view_as<bool>(StringToInt(strNewValue));	
	
}

public void OnConfigsExecuted()
{
	GetConVarString(g_hMusic, g_cMusic, sizeof(g_cMusic));
	g_bIsMusicEmpty = g_cMusic[0] == '\0';
	if(!g_bIsMusicEmpty)
		g_bMusicPrecached = PrecacheSound(g_cMusic, true);

	g_fSoundDuration = g_hSoundDuration.FloatValue;
	g_bEnable = g_hEnable.BoolValue;
	g_bForceSoldier = g_hForceSoldier.BoolValue;
	g_bCanChangeClass = g_hCanChangeClass.BoolValue;
	g_bCanAttackEveryone = g_hCanAttackEveryone.BoolValue;
	g_bCanChangeTeam = g_hCanChangeTeam.BoolValue;
	g_bConserveBuildings = g_hConserveBuildings.BoolValue;
	g_bChangeName = g_hChangeName.BoolValue;
}

public Action Command_RobinWalker(int client, int args)
{
	char arg1[32];
	if (args < 1)
	{
		arg1 = "@me";
	}
	else GetCmdArg(1, arg1, sizeof(arg1));
	char target_name[MAX_TARGET_LENGTH];
	int target_list[MAXPLAYERS], target_count;
	bool tn_is_ml;

	if ((target_count = ProcessTargetString(
					arg1,
					client,
					target_list,
					MAXPLAYERS,
					COMMAND_FILTER_ALIVE|(args < 1 ? COMMAND_FILTER_NO_IMMUNITY : 0),
					target_name,
					sizeof(target_name),
					tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
	for (int i = 0; i < target_count; i++)
	{
		SetRobinPlayer(target_list[i], client, true);
		LogAction(client, target_list[i], "\"%L\" made \"%L\" Robin Walker!", client, target_list[i]);
	}
	return Plugin_Handled;
}

public void OnAdminMenuReady(Handle aTopMenu)
{
	TopMenu hTopMenu = TopMenu.FromHandle(aTopMenu);
	
	if(g_hTopMenu == hTopMenu)
		return;
		
	g_hTopMenu = hTopMenu;
	
	
	TopMenuObject playercommands = g_hTopMenu.FindCategory(ADMINMENU_PLAYERCOMMANDS);
	if(playercommands != INVALID_TOPMENUOBJECT)
		g_hTopMenu.AddItem("sm_beromenu", AdminMenu_BeRobinMenu, playercommands, "sm_beromenu", ADMFLAG_ROOT);

}

void SDK_Team_AddPlayer(int iTeam, int iClient)
{
    if (g_hSDKTeamAddPlayer != INVALID_HANDLE)
    {
        SDKCall(g_hSDKTeamAddPlayer, iTeam, iClient);
    }
}

void SDK_Team_RemovePlayer(int iTeam, int iClient)
{
    if (g_hSDKTeamRemovePlayer != INVALID_HANDLE)
    {
        SDKCall(g_hSDKTeamRemovePlayer, iTeam, iClient);
    }
}

public Action UserMessageRename(UserMsg msg_id, BfRead msg, const int[] players, int playersNum, bool reliable, bool init)
{
	if (g_bChangeName)
	{
		char sMessage[96];
		msg.ReadString(sMessage, sizeof(sMessage));
		msg.ReadString(sMessage, sizeof(sMessage));

		if (StrContains(sMessage, "Name_Change") != -1) {
			return Plugin_Handled;
		}
	}
	
	return Plugin_Continue;
}

//////COMMANDS LISTNERS//////

public Action Player_CallMedic(int client, const char[] command, int argc)
{
	if(g_bIsRobin[client])
	{
		char arguments[4];
		GetCmdArgString(arguments, sizeof(arguments));
		
		if(StrEqual(arguments, "0 0", false))
		{
			if(!g_bIsInThirdPerson[client])
			{
				SetVariantInt(1);
				AcceptEntityInput(client, "SetForcedTauntCam");
				g_bIsInThirdPerson[client] = true;
			}
			else
			{
				SetVariantInt(0);
				AcceptEntityInput(client, "SetForcedTauntCam");
				g_bIsInThirdPerson[client] = false;
			}
			return Plugin_Handled;
		}
	}
	return Plugin_Continue;
}

public Action Player_ChangeClassBlock(int client, const char[] command, int argc)
{
	if(!g_bCanChangeClass && g_bIsRobin[client])
	{
		CPrintToChat(client, "{red}You cannot change class while being Robin Walker");
		return Plugin_Handled;
	}
		
	return Plugin_Continue;
}

public Action Player_ChangeTeamBlock(int client, const char[] command, int argc)
{
	if(!g_bCanChangeTeam && g_bIsRobin[client])
	{
		CPrintToChat(client, "{red}You cannot change team while being Robin Walker");
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

////////EVENTS////////

public Action Player_ChangeClass(Event hEvent, const char[] cName, bool bDontBroadcast)
{
	int iClient = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	int ClassIndex = GetEventInt(hEvent, "class");
	
	if(ClassIndex == 3)
		g_bIsSoldier[iClient] = true;
	
	else
	{
		g_bIsSoldier[iClient] = false;

		if(g_bIsRobin[iClient])
			if(g_bCanChangeClass)
				SetRobinPlayer(iClient, iClient, false);
			
	}
	return Plugin_Handled;
}

public Action Player_Team(Event hEvent, const char[] cName, bool bDontBroadcast)
{
	int iClient = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	
	if(g_bCanChangeTeam && g_bIsRobin[iClient])
	{
		g_bIsRobin[iClient] = false;
		StopMusic();
		CreateTimer(0.1, RemoveCond, GetClientUserId(iClient));
		CreateTimer(0.1, RegenerateClient, GetClientUserId(iClient));
			
		if(g_bIsInThirdPerson[iClient])
			CPrintToChat(iClient, "[SM] Type {green}!resettp {default}to remove the thirdperson view");
			
		char buffer[MAX_NAME_LENGTH];
		Format(buffer, sizeof(buffer), "%s", g_SaveName[iClient]);

		if (g_bChangeName)
		{
			SetClientName(iClient, buffer);
			
			g_bIsRenamedClient[iClient] = false;
		}
	}
	return Plugin_Handled;
}

public Action Player_Died(Event hEvent, const char[] cName, bool bDontBroadcast)
{
	int iClient = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	
	if(g_bIsRobin[iClient])	
	{
		SetRobinPlayer(iClient, iClient, false);
		char buffer[MAX_NAME_LENGTH];
		Format(buffer, sizeof(buffer), "%s", g_SaveName[iClient]);
		
		if (g_bChangeName)
		{
			SetClientName(iClient, buffer);
			g_bIsRenamedClient[iClient] = false;
		}
	}
	return Plugin_Continue;
}

public void Player_Spawn(Event hEvent, const char[] cName, bool bDontBroadcast)
{
	int iClient = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	int ClassIndex = GetEventInt(hEvent, "class");
	
	g_bIsInSpawn[iClient] = true;
	
	if(ClassIndex == view_as<int>(TFClass_Soldier))
		g_bIsSoldier[iClient] = true;
	
	else
	{
		g_bIsSoldier[iClient] = false;

		if(g_bIsRobin[iClient])
			SetRobinPlayer(iClient, iClient, false);
	}
}

public void BuildingsSapped(Event hEvent, const char[] cName, bool bDontBroadcast)
{
	int iClient = GetClientOfUserId(GetEventInt(hEvent, "ownerid"));
	int iObject = GetEventInt(hEvent, "object");
	
	if(g_bConserveBuildings)
	{
		if(g_bBuildingsDisabled[iClient])
		{
			switch(iObject)
			{
				case 0:		//dispenser
				{
					int iDispenser = -1;
					while((iDispenser = FindEntityByClassname(iDispenser, "obj_dispenser")) != INVALID_ENT_REFERENCE)
						if(GetEntPropEnt(iDispenser, Prop_Send, "m_hBuilder") == iClient)
							SetEntProp(iDispenser, Prop_Send, "m_bHasSapper", 0); //Disable the sound about buildings is sapped
				}
				case 1:		//teleporters
				{	//We don't care to know if it's enter or exit teleporter because we know both will be sapped at the same time
					int iTeleporters = -1;
					while((iTeleporters = FindEntityByClassname(iTeleporters, "obj_teleporter")) != INVALID_ENT_REFERENCE)
						if(GetEntPropEnt(iTeleporters, Prop_Send, "m_hBuilder") == iClient)
							SetEntProp(iTeleporters, Prop_Send, "m_bHasSapper", 0); //Disable the sound about buildings is sapped
				}
				case 2:		//sentry
				{
					int iSentry = -1;
					while((iSentry = FindEntityByClassname(iSentry, "obj_sentrygun")) != INVALID_ENT_REFERENCE)
						if(GetEntPropEnt(iSentry, Prop_Send, "m_hBuilder") == iClient)
							SetEntProp(iSentry, Prop_Send, "m_bHasSapper", 0); //Disable the sound about buildings is sapped
				}
			}
		}
	}
}

public void RoundStart(Event hEvent, const char[] cName, bool bDontBroadcast)
{
	if(!IsMannVsMachineMode() && !g_bWaitingForPlayers)
	{
		for(int client; client <= MaxClients; client++)
		{
			if(g_bIsRobin[client])
			{
				SetRobinPlayer(client, client, false);
			}
		}
	}
}

public void RoundEnd(Event hEvent, const char[] cName, bool bDontBroadcast)
{
	if(!IsMannVsMachineMode())
	{
		for(int client; client <= MaxClients; client++)
		{
			if(g_bIsRobin[client])
			{
				SetRobinPlayer(client, client, false);
			}
		}
	}
}

public void WaveFailed(Event hEvent, const char[] cName, bool bDontBroadcast)
{
	if(IsMannVsMachineMode())
	{
		for(int client; client <= MaxClients; client++)
		{
			if(g_bIsRobin[client])
			{
				SetRobinPlayer(client, client, false);
			}
		}
	}
}

public void WeaponReset(Event hEvent, const char[] cName, bool bDontBroadcast)
{
	int iClient = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	
	CreateTimer(0.1, CheckIsRobin, GetClientUserId(iClient));
}

////////////////////////

public void TF2_OnWaitingForPlayersStart()
{
	g_bWaitingForPlayers = true;
}

public void TF2_OnWaitingForPlayersEnd()
{
	g_bWaitingForPlayers = false;
}

public void OnEntityCreated(int entity, const char[] classname)
{
	if(StrEqual(classname, "func_respawnroom", false))
	{
		SDKHook(entity, SDKHook_StartTouch, SpawnStartTouch);
		SDKHook(entity, SDKHook_EndTouch, SpawnEndTouch);
	}
	if(StrEqual(classname, "tf_dropped_weapon", false))
	{
		SDKHook(entity, SDKHook_SpawnPost, DroppedWeaponSpawn);
	}
}

public void OnMapStart()
{
	g_bMusicPlayed = false;
	g_bWaitingForPlayers = false;

	PrecacheSound("weapons/pan/melee_frying_pan_01.wav", true);
}

public void OnClientPutInServer(int client)
{
	g_bIsRobin[client] = false;
	g_bIsSoldier[client] = false;
	g_bIsRenamedClient[client] = false;
	g_bCanBeRobin[client] = false;
	g_bCanBeRobin2[client] = false;
	g_bIsInThirdPerson[client] = false;
	g_bBuildingsDisabled[client] = false;
		
	GetClientName(client, g_SaveNameDebug[client],sizeof(g_SaveNameDebug[]));
}

public void OnMapEnd()
{
	g_bMusicPlayed = false;
	g_bWaitingForPlayers = false;
}

public void OnClientDisconnect(int client)
{
	if(g_bIsRobin[client])
		g_bIsRobin[client] = false;


	g_bIsSoldier[client] = false;
	g_bIsRenamedClient[client] = false;
	g_bCanBeRobin[client] = false;
	g_bCanBeRobin2[client] = false;
	g_bIsInThirdPerson[client] = false;
	g_bIsInSpawn[client] = false;
	g_bBuildingsDisabled[client] = false;
}

/////////*****COMMANDS*****/////////

public Action Command_Robin(int client, int args)
{
	if(g_bEnable)
	{
		if(client == 0)	//for some people who doesn't know, server console index is 0
		{
			ReplyToCommand(client, "[SM] Command not for server console");
			return Plugin_Handled;
		}
		
		if(args != 0)
		{
			ReplyToCommand(client, "[SM] Usage: sm_condump_on <nothing>");
			return Plugin_Handled;
		}
			
		else
			SetRobinPlayer(client, client, true);
			
	}
	else
	{
		ReplyToCommand(client, "[SM] The plugin is not enabled");
		return Plugin_Handled;
	}

	return Plugin_Handled;
}

public Action Command_NotRobin(int client, int args)
{
	if(g_bEnable)
	{
		if(client == 0)
		{
			ReplyToCommand(client, "[SM] Command not for server console");
			return Plugin_Handled;
		}	
		
		SetRobinPlayer(client, client, false);
	}
	else
	{
		ReplyToCommand(client, "[SM] The plugin is not enabled");
		return Plugin_Handled;
	}

	return Plugin_Handled;
}

public Action Command_MenuRobin(int client, int args)
{
	if(g_bEnable)
	{
		if(client == 0)
		{
			ReplyToCommand(client, "[SM] The debug menu can't be displayed on console server");
			return Plugin_Handled;
		}
		
		DisplayRobinMenu(client);
	}
	else
	{
		ReplyToCommand(client, "[SM] The plugin is not enabled");
		return Plugin_Handled;
	}
	
	return Plugin_Handled;
}

public Action Command_RobinMenu(int client, int args)
{
	if(g_bEnable)
	{
		if(client == 0)
		{
			ReplyToCommand(client, "[SM] The menu can't be displayed on console server");
			return Plugin_Handled;
		}

		DisplayBeRobinTargetMenu(client);
	}
	else
	{
		ReplyToCommand(client, "[SM] The plugin is not enabled");
		return Plugin_Handled;
	}

	return Plugin_Handled;
}

public Action Command_ResetTP(int client, int args)
{
	if(g_bEnable)
	{
		if(client == 0)
		{
			ReplyToCommand(client, "[SM] The command have no effect on console server");
			return Plugin_Handled;
		}
		if(args == 0)
		{
			SetVariantInt(0);
			AcceptEntityInput(client, "SetForcedTauntCam");
			g_bIsInThirdPerson[client] = false;
		}
		if(args == 1)
		{
			if(CheckCommandAccess(client, "resettp_target", ADMFLAG_KICK, true))
			{
				char arg1[MAX_NAME_LENGTH];
				
				int target = FindTarget(client, arg1, true);
				
				SetVariantInt(0);
				AcceptEntityInput(target, "SetForcedTauntCam");
				g_bIsInThirdPerson[target] = false;
			}
			else
			{
				ReplyToCommand(client, "[SM] You do not have access to this command");
				return Plugin_Handled;
			}
		}
	}
	else
	{
		ReplyToCommand(client, "[SM] The plugin is not enabled");
		return Plugin_Handled;
	}
	
	return Plugin_Handled;
}

public Action Command_CondMenu(int client, int args)
{
	if(g_bEnable)
	{
		if(client == 0)
		{
			ReplyToCommand(client, "[SM] Cannot display menu in console server");
			return Plugin_Handled;
		}
		if(!g_bIsRobin[client])
		{
			ReplyToCommand(client, "[SM] Can only be used when you are Robin Walker");
			return Plugin_Handled;
		}
		else
			DisplayMenuEffects(client);

	}
	else
	{
		ReplyToCommand(client, "[SM] The plugin is not enabled");
		return Plugin_Handled;
	}
	
	return Plugin_Handled;
}

/////////*****MENUS*****/////////

public void DisplayRobinMenu(int client)
{
	int iNumRobin = GetRobinCount();
	char RobinCount[48], cPrecacheMusic[32], MusicEnabled[32];
		
	Format(RobinCount, sizeof(RobinCount), "Robin Players : %i [Click to reset]", iNumRobin);
	Format(cPrecacheMusic, sizeof(cPrecacheMusic), "Music precached : %s", g_bMusicPrecached ? "yes" : "no");
	Format(MusicEnabled, sizeof(MusicEnabled), "Music is playing : %s", (g_bMusicPlayed ? "Yes" : "No"));
		
	Menu menu = new Menu(MenuHandler);
	menu.SetTitle("Robin Menu");
	menu.AddItem("RobinPlayers", RobinCount);
	menu.AddItem("RenameRobin", "Set default player name");
	menu.AddItem("MusicPrecached", cPrecacheMusic);
	menu.AddItem("MusicEnable", MusicEnabled);
	menu.ExitButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

public void DisplayBeRobinTargetMenu(int client)
{	
	Menu menu = new Menu(MenuHandler_BeRobin);
	menu.SetTitle("Toggle Robin effect Menu");
	
	AddTargetsToMenu(menu, client, true, true);
	
	menu.ExitBackButton = true;
	menu.ExitButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

public void DisplayMenuEffects(int client)
{
	Menu menu = new Menu(MenuConditions);
	menu.SetTitle("Robin Effects Menu");
	menu.AddItem("Add Conditions", "Add Effects");
	menu.AddItem("Remove Conditions", "Remove Effects");
	menu.ExitButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

/////////*****MENUS HANDLES*****/////////

public void AdminMenu_BeRobinMenu(TopMenu hTopMenu, TopMenuAction action, TopMenuObject object_id, int iParam, char[] strBuffer, int iMaxLength)
{
	if (action == TopMenuAction_DisplayOption)
		Format(strBuffer, iMaxLength, "Toggle Robin Player");

	else if (action == TopMenuAction_SelectOption)
		DisplayBeRobinTargetMenu(iParam);
}

public int MenuHandler(Menu hMenu, MenuAction action, int param1, int param2)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			char info[32];
			hMenu.GetItem(param2, info, sizeof(info));
			Menu menu = new Menu(MenuHandle1);
			
			if(StrEqual(info, "RobinPlayers", false))
			{
				int iNumRobin = GetRobinCount();
				if(iNumRobin > 0)
				{
					for(int i = 0; i <= MaxClients; i++)
					{
						if(g_bIsRobin[i])
						{
							SetRobinPlayer(i, param1, false);
							CPrintToChat(param1, "[SM] Robin Walker effect removed to every players");
						}
					}
				}
				else
				{
					PrintCenterText(param1, "Can't find any Robin Walker");
				}
				CreateTimer(0.0, FirstMenu, param1);
			}
			else if(StrEqual(info, "RenameRobin", false))
			{
				menu.SetTitle("Set default name");
				int iPlayerRenamedCount = GetRenamedPlayerCount();
				if(iPlayerRenamedCount > 0)
				{
					for(int i = 0; i <= MaxClients; i++)
					{
						if(g_bIsRenamedClient[i])
						{
							char cName[MAX_NAME_LENGTH], buffer[64];
							GetClientName(i, cName, sizeof(cName));
							Format(buffer, sizeof(buffer), "%s", cName);
							menu.AddItem(cName, buffer);
						}
					}
				}
				else
				{
					PrintCenterText(param1, "Can't find any player renamed by \"Be Robin Walker\" plugin");
					CreateTimer(0.0, FirstMenu, param1);
				}
			}
			else if(StrEqual(info, "MusicPrecached", false))
			{
				if(!g_bMusicPrecached)
				{
					g_bMusicPrecached = PrecacheSound(g_cMusic);
					if(g_bMusicPrecached)
						PrintCenterText(param1, "Sucess ! Music precached");

					else
						PrintCenterText(param1, "Failed to precache the music");
				}

				CreateTimer(0.0, FirstMenu, param1);
			}
			else if(StrEqual(info, "MusicEnable", false))
			{
				CreateTimer(0.0, PlayStopMenu, param1);
			}
			menu.ExitBackButton = true;
			menu.ExitButton = true;
			menu.Display(param1, MENU_TIME_FOREVER);
		}
		case MenuAction_End: delete hMenu;
	}
	return 0;
}

public int MenuHandle1(Menu hMenu, MenuAction action, int param1, int param2)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			char info[32];
			hMenu.GetItem(param2, info, sizeof(info));
			
			for(int i = 0; i <= MaxClients; i++)
			{
				if(g_bIsRenamedClient[i])
				{
					char cName[MAX_NAME_LENGTH];
					GetClientName(i, cName, sizeof(cName));
					
					if(StrEqual(info, cName, false))
					{
						int target = FindTarget(param1, info, true);
						if(target == -1)
						{
							return 0;
						}
						char buffer[64];
						Format(buffer, sizeof(buffer), "%s", g_SaveNameDebug[target]);
						SetClientName(target, buffer);
					}
				}
			}

			if(StrEqual(info, "Disable", false))
			{
				PlaySound(false);
				PrintCenterText(param1, "Music stopped");
				CreateTimer(0.0, PlayStopMenu, param1);
			}
			
			else if(StrEqual(info, "PlayNow", false))
			{
				PlaySound(true);
				PrintCenterText(param1, "Music played");
				CreateTimer(0.0, PlayStopMenu, param1);
			}
			else if(StrEqual(info, "nothing", false))
			{
				DisplayRobinMenu(param1);
			}
		}
		case MenuAction_Cancel:
		{
			if(param2 == MenuCancel_ExitBack)
				DisplayRobinMenu(param1);
		}
		case MenuAction_End: delete hMenu;
	}
	
	return 0;
}

public int MenuHandler_BeRobin(Menu hMenu, MenuAction action, int iParam1, int iParam2)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			char strInfo[32];
			hMenu.GetItem(iParam2, strInfo, sizeof(strInfo));
			
			int iUserID = StringToInt(strInfo);
			int iTarget = GetClientOfUserId(iUserID);

			if(iTarget == 0)
				PrintToChat(iParam1, "[SM] %t", "Player no longer available");

			else if (!CanUserTarget(iParam1, iTarget))
				PrintToChat(iParam1, "[SM] %t", "Unable to target");
				
			else
			{
				ShowActivity2(iParam1, "[SM] ", "Toggled Be Robin on %s", g_SaveNameDebug[iTarget]);
				SetRobinPlayer(iTarget, iParam1, !g_bIsRobin[iTarget]);
			}

			DisplayBeRobinTargetMenu(iParam1);
		}
		case MenuAction_Cancel:
		{
			if (iParam2 == MenuCancel_ExitBack && g_hTopMenu)
				g_hTopMenu.Display(iParam1, TopMenuPosition_LastCategory);
		}
		case MenuAction_End: delete hMenu;
	}
	return 0;
}

public int MenuConditions(Menu hMenu, MenuAction action, int param1, int param2)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			char info[32];
			hMenu.GetItem(param2, info, sizeof(info));
			
			if(StrEqual(info, "Add Conditions", false))
				ConditionsMenu(param1, true);
				
			else if(StrEqual(info, "Remove Conditions", false))
				ConditionsMenu(param1, false);
				
		}
		case MenuAction_End: delete hMenu;
	}
	return 0;
}

public int AddEffectsMenu(Menu hMenu, MenuAction action, int param1, int param2)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			char info[32];
			hMenu.GetItem(param2, info, sizeof(info));
			
			if(StrEqual(info, "1", false))
			{
				TF2_AddCondition(param1, TFCond_UberchargedCanteen, TFCondDuration_Infinite);
			}
			else if(StrEqual(info, "2", false))
			{
				TF2_AddCondition(param1, TFCond_CritCanteen, TFCondDuration_Infinite);
				TF2_AddCondition(param1, TFCond_CritDemoCharge, TFCondDuration_Infinite);
			}
			else if(StrEqual(info, "3", false))
			{
				TF2_AddCondition(param1, TFCond_UberBulletResist, TFCondDuration_Infinite);
			}
			else if(StrEqual(info, "4", false))
			{
				TF2_AddCondition(param1, TFCond_UberBlastResist, TFCondDuration_Infinite);
			}
			else if(StrEqual(info, "5", false))
			{
				TF2_AddCondition(param1, TFCond_UberFireResist, TFCondDuration_Infinite);
			}
			else if(StrEqual(info, "6", false))
			{
				TF2_AddCondition(param1, TFCond_MegaHeal, TFCondDuration_Infinite);
			}
			else if(StrEqual(info, "7", false))
			{
				TF2_AddCondition(param1, TFCond_UberchargedCanteen, TFCondDuration_Infinite);
				TF2_AddCondition(param1, TFCond_CritCanteen, TFCondDuration_Infinite);
				TF2_AddCondition(param1, TFCond_CritDemoCharge, TFCondDuration_Infinite);
				TF2_AddCondition(param1, TFCond_UberBulletResist, TFCondDuration_Infinite);
				TF2_AddCondition(param1, TFCond_UberBlastResist, TFCondDuration_Infinite);
				TF2_AddCondition(param1, TFCond_UberFireResist, TFCondDuration_Infinite);
				TF2_AddCondition(param1, TFCond_MegaHeal, TFCondDuration_Infinite);
				TF2_SetPlayerPowerPlay(param1, true);		//To have the fire effect and devil laugh
			}
			AddConditions(param1);
		}
		case MenuAction_Cancel : 
		{
			if(param2 == MenuCancel_ExitBack) 
				DisplayMenuEffects(param1);
		}
		case MenuAction_End: delete hMenu;
	}
	return 0;
}

public int RemoveEffectsMenu(Menu hMenu, MenuAction action, int param1, int param2)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			char info[32];
			hMenu.GetItem(param2, info, sizeof(info));
			
			if(StrEqual(info, "1", false))
			{
				TF2_RemoveCondition(param1, TFCond_UberchargedCanteen);
			}
			else if(StrEqual(info, "2", false))
			{
				TF2_RemoveCondition(param1, TFCond_CritCanteen);
				TF2_RemoveCondition(param1, TFCond_CritDemoCharge);
			}
			else if(StrEqual(info, "3", false))
			{
				TF2_RemoveCondition(param1, TFCond_UberBulletResist);
			}
			else if(StrEqual(info, "4", false))
			{
				TF2_RemoveCondition(param1, TFCond_UberBlastResist);
			}
			else if(StrEqual(info, "5", false))
			{
				TF2_RemoveCondition(param1, TFCond_UberFireResist);
			}
			else if(StrEqual(info, "6", false))
			{
				TF2_RemoveCondition(param1, TFCond_MegaHeal);
			}
			else if(StrEqual(info, "7", false))
			{
				TF2_RemoveCondition(param1, TFCond_UberchargedCanteen);
				TF2_RemoveCondition(param1, TFCond_CritCanteen);
				TF2_RemoveCondition(param1, TFCond_CritDemoCharge);
				TF2_RemoveCondition(param1, TFCond_UberBulletResist);
				TF2_RemoveCondition(param1, TFCond_UberBlastResist);
				TF2_RemoveCondition(param1, TFCond_UberFireResist);
				TF2_RemoveCondition(param1, TFCond_MegaHeal);
				TF2_SetPlayerPowerPlay(param1, false);
			}
			RemoveConditions(param1);
		}
		case MenuAction_Cancel:
		{
			if(param2 == MenuCancel_ExitBack)
				DisplayMenuEffects(param1);
		}
		case MenuAction_End: delete hMenu;
	}
	return 0;
}

/////////*****USERFUL FOR MENUS*****/////////

public Action FirstMenu(Handle timer, any client)
{
	DisplayRobinMenu(client);	//After an item selected, return to the previous menu

	return Plugin_Handled;
}

public Action PlayStopMenu(Handle timer, any client)
{
	Menu menu = new Menu(MenuHandle1);
	menu.SetTitle("Music Status : %s", (g_bMusicPlayed ? "Is playing" : "Is not playing"));
	menu.AddItem("PlayNow", "Enable (Play music now)");
	menu.AddItem("Disable", "Disable (Stop music now)");
	menu.ExitBackButton = true;
	menu.ExitButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
	
	return Plugin_Handled;	
}

public void ConditionsMenu(int client, bool OptionAdd)
{
	if(OptionAdd)
		AddConditions(client);
		
	else
		RemoveConditions(client);
}

public void AddConditions(int client)
{
	Menu menu = new Menu(AddEffectsMenu);
	menu.SetTitle("Add Effects");
	menu.AddItem("1", "UberCharge");
	menu.AddItem("2", "Crits");
	menu.AddItem("3", "Vaccinator Bullet");
	menu.AddItem("4", "Vaccinator Blast");
	menu.AddItem("5", "Vaccinator Fire");
	menu.AddItem("6", "Quick-fix (Knockback immunity)");
	menu.AddItem("7", "All Effects");	
	menu.ExitBackButton = true;
	menu.ExitButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

public void RemoveConditions(int client)
{
	Menu menu = new Menu(RemoveEffectsMenu);
	menu.SetTitle("Remove Effects");
	menu.AddItem("1", "UberCharge");
	menu.AddItem("2", "Crits");
	menu.AddItem("3", "Vaccinator Bullet");
	menu.AddItem("4", "Vaccinator Blast");
	menu.AddItem("5", "Vaccinator Fire");
	menu.AddItem("6", "Quick-fix (Knockback immunity)");
	menu.AddItem("7", "All Effects");
	menu.ExitBackButton = true;
	menu.ExitButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

/////////*****USERFUL FOR COMMANDS*****/////////

void SetRobinPlayer(int client, int admin, bool apply)		//Note : admin is the player who issued the command
{	
	if(apply)
	{
		if(!g_bIsRobin[client])
		{
			if(IsPlayerAlive(client))
			{
				if(g_bCanAttackEveryone)
				{
					if(!g_bIsInSpawn[client])
						g_bCanBeRobin2[client] = true;
						
					else
					{
						g_bCanBeRobin2[client] = false;
						
						if(admin == client)
							ReplyToCommand(admin, "[SM] You mustn't be in spawn to be Robin Walker");
							
						else
							ReplyToCommand(admin, "[SM] He mustn't be in spawn to be Robin Walker");
						
					}
				}
				else
					g_bCanBeRobin2[client] = true;
					
				if(g_bCanBeRobin2[client])
				{
					if(g_bForceSoldier)
					{
						if(TF2_GetPlayerClass(client) == TFClass_Engineer)
						{
							int iEnt = -1;
							
							if(g_bConserveBuildings)
							{
								while((iEnt = FindEntityByClassname(iEnt, "obj_*")) != INVALID_ENT_REFERENCE)
								{
									if(GetEntPropEnt(iEnt, Prop_Send, "m_hBuilder") == client)
									{		
										if(g_bCanAttackEveryone)
											AcceptEntityInput(iEnt, "SetBuilder", client);
											
										if(GetEntProp(iEnt, Prop_Send, "m_bHasSapper"))
											SetEntProp(iEnt, Prop_Send, "m_bHasSapper", 0);
											
										SetEntProp(iEnt, Prop_Send, "m_bDisabled", 1);
										SetEntProp(iEnt, Prop_Data, "m_takedamage", 0, 1);
										int flags = GetEntityFlags(iEnt);
										SetEntityFlags(iEnt, flags | FL_NOTARGET);
										SetEntityRenderMode(iEnt, RENDER_TRANSCOLOR);
										SetEntityRenderColor(iEnt, 255, 255, 255, 180);
									}
								}
								g_bBuildingsDisabled[client] = true;
							}
							else
							{
								while((iEnt = FindEntityByClassname(iEnt, "obj_*")) != INVALID_ENT_REFERENCE)
								{
									if(GetEntPropEnt(iEnt, Prop_Send, "m_hBuilder") == client)
									{	
										AcceptEntityInput(iEnt, "Kill");
										g_bBuildingsDisabled[client] = false;
									}
								}
							}
						}
						
						g_iLastClientClass[client] = GetEntProp(client, Prop_Send, "m_iClass");
							
						TF2_SetPlayerClass(client, TFClass_Soldier);
						g_bCanBeRobin[client] = true;
							
					}
					else
					{
						if(g_bIsSoldier[client])
							g_bCanBeRobin[client] = true;
							
						else
						{
							g_bCanBeRobin[client] = false;
								
							if(admin == client)
								ReplyToCommand(admin, "[SM] You must be a soldier to be Robin Walker");
									
							else
								ReplyToCommand(admin, "[SM] He must be a soldier to be Robin Walker");
			
						}
					}
				}
					
				if(g_bCanBeRobin[client] && g_bCanBeRobin2[client])
				{
					GetClientName(client, g_SaveName[client], sizeof(g_SaveName[]));
					char buffer[64];
					Format(buffer, sizeof(buffer), "Robin Walker (%s)", g_SaveName[client]);					
					
					if (g_bChangeName)
					{
						SetClientName(client, buffer);
					}
					
					if(g_bCanAttackEveryone)
					{
						g_iLastClientTeam[client] = GetEntProp(client, Prop_Send, "m_iTeamNum");
						
						if(IsMannVsMachineMode())
							TF2_ChangeClientTeamEx(client, view_as<int>(TFTeam_Spectator));

						else
							TF2_ChangeClientTeamEx(client, view_as<int>(TFTeam_Unassigned));

					}
					
					for(int i = 0; i <= MaxClients; i++)
					{
						if(IsValidClient(i))
						{
							SetHudTextParams(-1.0, 0.2, 5.0, 255, 0, 0, 0);
							ShowSyncHudText(i, g_Hhud, "/!\\ Alert ! \"%s\" became Robin Walker /!\\", g_SaveName[client]);
						}
					}
					
					if(TF2_IsPlayerInCondition(client, TFCond_Zoomed))
						TF2_RemoveCondition(client, TFCond_Zoomed);
					
					SetEntProp(client, Prop_Send, "m_bGlowEnabled", 1);
					CreateTimer(0.0, ReplaceWeapon, GetClientUserId(client));
					CreateTimer(0.1, AddCond, GetClientUserId(client));
					PrintCenterText(client, "Call for MEDIC! to toggle thirdperson/firstperson view");
					CPrintToChat(client, "[SM] Call for {green}MEDIC! {default}to toggle {green}thirdperson/firstperson view");
					CreateTimer(7.0, MenuNotif, GetClientUserId(client));
					
					PlaySound(apply);
					g_bIsRenamedClient[client] = apply;
					g_bIsRobin[client] = apply;
					
				}
			}
			else
				ReplyToCommand(admin, "[SM] Command only for alive players");
		}
		else
		{
			if(client == admin)
				CReplyToCommand(admin, "{red}[SM] You are already the {yellow}TF2 creator");
				
			else
				CReplyToCommand(admin, "{red}[SM] He is already the {yellow}TF2 creator");

			SlapPlayer(admin, 0, false);
			EmitSoundToClient(admin, "weapons/pan/melee_frying_pan_01.wav");
		}
	}
	else
	{
		if(g_bIsRobin[client])
		{
			char buffer[MAX_NAME_LENGTH];
			Format(buffer, sizeof(buffer), "%s", g_SaveName[client]);

			if (g_bChangeName)
			{
				SetClientName(client, buffer);
			}
				
			CreateTimer(0.1, RemoveCond, GetClientUserId(client));
			CreateTimer(0.0, TimerMusic);
			
			SetEntProp(client, Prop_Send, "m_bGlowEnabled", 0);
			
			if(GetEntProp(client, Prop_Send, "m_iTeamNum") == 1 || !GetEntProp(client, Prop_Send, "m_iTeamNum"))
				TF2_ChangeClientTeam(client, view_as<TFTeam>(g_iLastClientTeam[client]));

			if(g_bForceSoldier)
			{
				TF2_SetPlayerClass(client, view_as<TFClassType>(g_iLastClientClass[client]));
				SetEntityHealth(client, 1);
				
				if(g_iLastClientClass[client] == view_as<int>(TFClass_Soldier))
					g_bIsSoldier[client] = true;
					
				else
					g_bIsSoldier[client] = false;
					
			}
			TF2_RegeneratePlayer(client);
			
			if(g_bIsInThirdPerson[client])
				CPrintToChat(client, "[SM] Type {green}!resettp {default}to remove the thirdperson view");
			
			g_bIsRenamedClient[client] = apply;
			g_bIsRobin[client] = apply;
			
			
			if(g_bConserveBuildings)
			{
				if(g_bBuildingsDisabled[client])
				{
					int iEnt = -1;
					while((iEnt = FindEntityByClassname(iEnt, "obj_*")) != INVALID_ENT_REFERENCE)
					{
						if(GetEntPropEnt(iEnt, Prop_Send, "m_hBuilder") == client)
						{
							if(g_bCanAttackEveryone)
								AcceptEntityInput(iEnt, "SetBuilder", client);
								
							RemoveActiveSapper(iEnt);
							
							SetEntProp(iEnt, Prop_Send, "m_bDisabled", 0);
							SetEntProp(iEnt, Prop_Data, "m_takedamage", 2, 1);
							int flags = GetEntityFlags(iEnt);
							SetEntityFlags(iEnt, flags & ~FL_NOTARGET);
							SetEntityRenderMode(iEnt, RENDER_TRANSCOLOR);
							SetEntityRenderColor(iEnt, 255, 255, 255, 255);
						}
					}
					g_bBuildingsDisabled[client] = false;
				}
			}
		}
		else
		{
			if(client == admin)
				CReplyToCommand(admin, "{red}[SM] You are not the {yellow}TF2 creator");
				
			else
				CReplyToCommand(admin, "{red}[SM] He is not the {yellow}TF2 creator");
					
			if(IsPlayerAlive(admin))
			{
				SlapPlayer(admin, 0, false);
				EmitSoundToClient(admin, "weapons/pan/melee_frying_pan_01.wav");
			}
		}
	}
}

/////////*****EP2*****/////////

void StopMusic()
{
	int iNumRobin = GetRobinCount();
	
	if(iNumRobin <= 0)
	{
		PlaySound(false);
		
		for(int i = 0; i <= MaxClients; i++)
		{
			if(IsValidClient(i))
			{
				SetHudTextParams(-1.0, 0.7, 5.0, 0, 0, 255, 0);
				ShowSyncHudText(i, g_Hhud, "Every Robin Walker disappeared !");
			}
		}
	}
}

void PlaySound(bool enabled)
{
	if(enabled)
	{
		if(!g_bIsMusicEmpty)
		{
			if(g_bMusicPrecached)
			{
				if(!g_bMusicPlayed)	//If the music is not already played
				{
					EmitSoundToAll(g_cMusic);
					g_bMusicPlayed = enabled;
					//[example] g_hTimer = CreateTimer(96.0, CanReplaySound, _, TIMER_REPEAT);	= After 96s(the default music(I chosed) duration), can play a sound again and eventually repeat again if atleast a Robin player is still alive
					g_hTimer = CreateTimer(g_fSoundDuration, CanReplaySound, _, TIMER_REPEAT);
				}
			}
		}
	}
	else
	{
		for(int i = 0; i <= MaxClients; i++)
		{
			StopSound(i, SNDCHAN_AUTO, g_cMusic);
			g_bMusicPlayed = enabled;
			delete g_hTimer;
		}
	}
}

// Credit to Benoist3012
void TF2_ChangeClientTeamEx(int iClient, int iNewTeamNum)
{
	int iTeamNum = GetEntProp(iClient, Prop_Send, "m_iTeamNum");

	// Safely swap team
	int iTeam = MaxClients+1;
	while ((iTeam = FindEntityByClassname(iTeam, TEAM_CLASSNAME)) != -1)
	{
		int iAssociatedTeam = GetEntProp(iTeam, Prop_Send, "m_iTeamNum");
		if (iAssociatedTeam == iTeamNum)
			SDK_Team_RemovePlayer(iTeam, iClient);
		else if (iAssociatedTeam == iNewTeamNum)
			SDK_Team_AddPlayer(iTeam, iClient);
	}

	SetEntProp(iClient, Prop_Send, "m_iTeamNum", iNewTeamNum);
}

/////////*****SDKHOOKS*****/////////

public void SpawnStartTouch(int spawn, int client)
{
	if (client > MaxClients || client < 1)
		return;

	if (IsClientConnected(client) && IsClientInGame(client))
		g_bIsInSpawn[client] = true;
}

public void SpawnEndTouch(int spawn, int client)
{
	if (client > MaxClients || client < 1)
		return;

	if (IsClientConnected(client) && IsClientInGame(client))
		g_bIsInSpawn[client] = false;
}

public void DroppedWeaponSpawn(int iEntity)
{
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsValidClient(i))
		{
			if(g_bIsRobin[i])
			{
				if(GetEntProp(iEntity, Prop_Send, "m_iAccountID") == GetSteamAccountID(i) || GetEntProp(iEntity, Prop_Send, "m_iAccountID") == 0)
				{
					AcceptEntityInput(iEntity, "Kill");	
				}
			}
		}
	}
	
}

/////////*****TIMERS*****/////////

public Action RegenerateClient(Handle timer, any iUserId)
{
	int iClient = GetClientOfUserId(iUserId);
	
	if((iClient <= 0 || iClient > MaxClients) && !IsClientInGame(iClient))
		return  Plugin_Stop;
	
	TF2_RegeneratePlayer(iClient);
	
	return Plugin_Continue;
}

public Action MenuNotif(Handle timer, any iUserId)
{
	int iClient = GetClientOfUserId(iUserId);
	
	if((iClient <= 0 || iClient > MaxClients) && !IsClientInGame(iClient))
		return  Plugin_Stop;
	
	CPrintToChat(iClient, "[SM] Type {green}!robineffects {default}to have a menu that add/remove {green}effects (conditions)");
	
	return Plugin_Continue;
}

public Action CanReplaySound(Handle timer)
{
	g_bMusicPlayed = false;
	
	int iNumRobin = GetRobinCount();
	bool bCanRepeat = (iNumRobin > 0);

	if(bCanRepeat)	//Repeat the music if there is atleast 1 player that is Robin Walker
	{
		if(!g_bIsMusicEmpty)
		{
			if(g_bMusicPrecached)
			{
				EmitSoundToAll(g_cMusic);
				g_bMusicPlayed = true;
			}
		}
		return Plugin_Continue;
	}
	return Plugin_Stop;
}

public Action TimerMusic(Handle timer)
{
	StopMusic();
	
	return Plugin_Handled;	
}

public Action CheckIsRobin(Handle timer, any iUserId)
{
	int iClient = GetClientOfUserId(iUserId);
	
	if((iClient <= 0 || iClient > MaxClients))
		return  Plugin_Stop;
		
	if(!IsClientInGame(iClient))
		return  Plugin_Stop;
	
	if(g_bIsRobin[iClient])
		CreateTimer(0.1, ReplaceWeapon, iUserId);
		
	return Plugin_Handled;
}

public Action ReplaceWeapon(Handle timer, any iUserId)
{
	int iClient = GetClientOfUserId(iUserId);
	
	TF2_RemoveAllWeapons(iClient);
	TF2Items_GiveWeapon(iClient, "tf_weapon_rocketlauncher", 18, 100, 8, "134 ; 2 ; 2 ; 200 ; 4 ; 201 ; 6 ; 0.25 ; 110 ; 250 ; 31 ; 10 ; 103 ; 1.5 ; 107 ; 2 ; 26 ; 250 ; 97 ; 0.25 ; 76 ; 200");
	SetAmmo(iClient, 0, 4000);
	
	SetEntityHealth(iClient, 450);	//Add +250 health because of the attribe maxhealth added to 250

	return Plugin_Handled;
}

public Action AddCond(Handle timer, any iUserId)
{
	int iClient = GetClientOfUserId(iUserId);
	
	if((iClient <= 0 || iClient > MaxClients) && !IsClientInGame(iClient))
		return  Plugin_Stop;
	
	TF2_AddCondition(iClient, TFCond_MegaHeal, TFCondDuration_Infinite);
	TF2_AddCondition(iClient, TFCond_CritCanteen, TFCondDuration_Infinite);
	TF2_AddCondition(iClient, TFCond_CritDemoCharge, TFCondDuration_Infinite);
	TF2_AddCondition(iClient, TFCond_UberchargedCanteen, TFCondDuration_Infinite);
	TF2_AddCondition(iClient, TFCond_UberBulletResist, TFCondDuration_Infinite);
	TF2_AddCondition(iClient, TFCond_UberBlastResist, TFCondDuration_Infinite);
	TF2_AddCondition(iClient, TFCond_UberFireResist, TFCondDuration_Infinite);
	//TF2_AddCondition(iClient, TFCond, TFCondDuration_Infinite);	You can enable other coditions
	TF2_SetPlayerPowerPlay(iClient, true);
	CreateTimer(0.1, TauntFix, iUserId);
	
	return Plugin_Handled;
}

public Action RemoveCond(Handle timer, any iUserId)
{
	int iClient = GetClientOfUserId(iUserId);
	
	if((iClient <= 0 || iClient > MaxClients) && !IsClientInGame(iClient))
		return  Plugin_Stop;
	
	TF2_SetPlayerPowerPlay(iClient, false);
	TF2_RemoveCondition(iClient, TFCond_MegaHeal);
	TF2_RemoveCondition(iClient, TFCond_CritCanteen);
	TF2_RemoveCondition(iClient, TFCond_CritDemoCharge);
	TF2_RemoveCondition(iClient, TFCond_UberchargedCanteen);
	TF2_RemoveCondition(iClient, TFCond_UberBulletResist);
	TF2_RemoveCondition(iClient, TFCond_UberBlastResist);
	TF2_RemoveCondition(iClient, TFCond_UberFireResist);	
	//TF2_RemoveCondition(iClient, TFCond);
	
	return Plugin_Continue;
}

public Action TauntFix(Handle timer, any iUserId)
{
	int iClient = GetClientOfUserId(iUserId);
	
	if((iClient <= 0 || iClient > MaxClients) && !IsClientInGame(iClient))
		return  Plugin_Stop;
		
	FakeClientCommand(iClient, "taunt");
	
	return Plugin_Continue;
}

/////////*****STOCKS FOR THIS PLUGIN*****/////////

stock bool IsValidClient(int client)
{
	return (1 <= client <= MaxClients) && IsClientInGame(client) && !IsFakeClient(client);
}

stock void RemoveActiveSapper(int building)
{
	int sapper = -1; 
	while ((sapper = FindEntityByClassname(sapper, "obj_attachment_sapper")) != INVALID_ENT_REFERENCE)
	{
		if(IsValidEntity(sapper) && GetEntPropEnt(sapper, Prop_Send, "m_hBuiltOnEntity") == building)
		{
			AcceptEntityInput(sapper, "Kill");
		}
	}	
}

stock void SetAmmo(int client, int wepslot, int newAmmo)		//taken from DarthNinja's "Set Ammo" plugin
{
	/*if (IsValidEntity(weapon))
	{
		int iOffset = GetEntProp(weapon, Prop_Send, "m_iPrimaryAmmoType", 1)*4;
		int iAmmoTable = FindSendPropInfo("CTFPlayer", "m_iAmmo");
		SetEntData(client, iAmmoTable+iOffset, newAmmo, 4, true);
	}*/
	
	
	int iWeapon = GetPlayerWeaponSlot(client, wepslot);
	
	if(!IsValidEntity(iWeapon)) return;
	
	int iType = GetEntProp(iWeapon, Prop_Send, "m_iPrimaryAmmoType");
	if(iType < 0 || iType > 31) return;
	SetEntProp(client, Prop_Send, "m_iAmmo", newAmmo, _, iType);
}

stock int GetRobinCount()
{
	int iCount;
	
	for(int i = 0; i <= MaxClients; i++)
		if(g_bIsRobin[i])
			iCount++;
			
	return iCount;
}

stock int GetRenamedPlayerCount()
{
	int iCount;
	
	for(int i = 0; i <= MaxClients; i++)
		if(g_bIsRenamedClient[i])
			iCount++;
	
	return iCount;
}

stock bool IsMannVsMachineMode()
{
	return view_as<bool>(GameRules_GetProp("m_bPlayingMannVsMachine"));
}


stock int TF2Items_GiveWeapon(int client, char[] strName, int Index, int Level = 1, int Quality = 0, char[] strAtt = "")
{
	Handle hWeapon = TF2Items_CreateItem(OVERRIDE_ALL | FORCE_GENERATION);

	TF2Items_SetClassname(hWeapon, strName);
	TF2Items_SetItemIndex(hWeapon, Index);
	TF2Items_SetLevel(hWeapon, Level);
	TF2Items_SetQuality(hWeapon, Quality);

	char strAtts[32][32];
	int iCount = ExplodeString(strAtt, " ; ", strAtts, 32, 32);
	
	if(iCount > 0)
	{
		TF2Items_SetNumAttributes(hWeapon, iCount / 2);
		int z;
		for(int i = 0; i < iCount; i += 2)
		{
			TF2Items_SetAttribute(hWeapon, z, StringToInt(strAtts[i]), StringToFloat(strAtts[i + 1]));
			z++;
		}
	}
	else
		TF2Items_SetNumAttributes(hWeapon, 0);

		
	if(hWeapon == INVALID_HANDLE)
		return -1;


	int iEntity = TF2Items_GiveNamedItem(client, hWeapon);

	EquipPlayerWeapon(client, iEntity);
	CloseHandle(hWeapon);

	return iEntity;
}