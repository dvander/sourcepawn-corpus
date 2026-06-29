#pragma semicolon 1

#include <sdkhooks>
#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>
#include <tf2items>
#include <multicolors>
#include <adminmenu>

#define PLUGIN_VERSION "Private Version 13"

#pragma newdecls required


//bool//
bool bEnable;
bool bIsRobin[MAXPLAYERS+1];
bool bMusicPrecached;
bool bSoundPrecached; //no touchy
bool bMusicPlayed;
bool bForceSoldier;
bool bCanChangeClass;
bool bCanChangeTeam;
bool bCanAttackEveryone;
bool bConserveBuildings;
bool bisSoldier[MAXPLAYERS+1];
bool bIsRenamedClient[MAXPLAYERS+1];
bool bCanBeRobin[MAXPLAYERS+1];
bool bCanBeRobin2[MAXPLAYERS+1];
bool bIsThirdPerson[MAXPLAYERS+1];
bool IsInSpawn[MAXPLAYERS+1];
bool bBuildingsDisabled[MAXPLAYERS+1];
bool bWaitingForPlayers;
////////

//Handle//
Handle hTimer;
Handle Hhud;
//////////

//Convar//
ConVar hEnable;
ConVar hMusic;
ConVar hSoundDuration;
ConVar hForceSoldier;
ConVar hCanChangeClass;
ConVar hCanChangeTeam;
ConVar hCanAttackEveryone;
ConVar hConserveBuildings;
//////////

//Others//
char cMusic[32];
float fSoundDuration;
char SaveName[MAXPLAYERS+1][MAX_NAME_LENGTH];
char SaveNameDebug[MAXPLAYERS+1][MAX_NAME_LENGTH];
int iLastClientClass[MAXPLAYERS+1];
int iLastClientTeam[MAXPLAYERS+1];
UserMsg iSay_Text;
TopMenu hTopMenu;
//////////

public Plugin myinfo =
{
	name = "[TF2] Be Painis Cupcake",
	author = "Peanut",	
	description = "Transform into Painis Cupcake and kill everyone, Based on 'Be Robin Walker' by Whai",
	version = PLUGIN_VERSION,
	url = "https://discord.gg/7sRn8Bt"
}

public void OnPluginStart()
{
	RegisterCmds();
	RegisterCvars();
	RegisterCmdLisners();
	HookEvent("player_death", Event_PlayerDeath, EventHookMode_Pre);
	HookEvents();
	
	iSay_Text = GetUserMessageId("SayText2");
	HookUserMessage(iSay_Text, UserMessageRename, true);			//Hide name change
	
	LoadTranslations("common.phrases");
	
	AutoExecConfig(true, "be-painiscupcake");
	
	Hhud = CreateHudSynchronizer();
	
	TopMenu topmenu;
	if(LibraryExists("adminmenu") && ((topmenu = GetAdminTopMenu()) != null))
		OnAdminMenuReady(topmenu);

}

Action Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast) 
{
    int attacker = GetClientOfUserId(event.GetInt("attacker"));
    if (attacker <= 0 || attacker > MaxClients || !IsClientInGame(attacker)) 
    {
        return Plugin_Continue;
    }
    
    if (bIsRobin[attacker]) 
    {
        event.SetString("weapon", "fists");
        return Plugin_Changed;
    }
    
    return Plugin_Continue;
}

public void OnLibraryRemoved(const char[] strName)
{
	if(!strcmp(strName, "adminmenu"))
		hTopMenu = null;
		
}

void RegisterCmds()
{
	RegAdminCmd("sm_cupcake_on", Command_Robin, ADMFLAG_ROOT, "Enable the effect"); 
	RegAdminCmd("sm_cupcake_off", Command_NotRobin, ADMFLAG_ROOT, "Disable the effect");
	
	RegAdminCmd("sm_painismenu", Command_MenuRobin, ADMFLAG_ROOT, "Display Painis menu");
	RegAdminCmd("sm_psckmenu", Command_RobinMenu, ADMFLAG_ROOT, "Display a menu to toggle a player to Painis Cupcake");
	
	RegConsoleCmd("sm_resettp", Command_ResetTP, "Set firstperson view to the target");
	RegConsoleCmd("sm_painiseffects", Command_CondMenu, "Display effects menu");
	
}

void RegisterCvars()
{
	CreateConVar("sm_psck_version", PLUGIN_VERSION, "The Version of Be Painis Cupcake", FCVAR_SPONLY|FCVAR_NOTIFY);
	
	hMusic = CreateConVar("sm_psck_sound", "misc/painistheme.mp3", "Music played when Painis Cupcake appears");
	hMusic.AddChangeHook(ConVarChanged);
	GetConVarString(hMusic, cMusic, sizeof(cMusic));
	
	hSoundDuration = CreateConVar("sm_psck_soundtime", "98.2", "The duration of the chosed music", 0, true, 0.0, false);
	hSoundDuration.AddChangeHook(ConVarChanged);
	
	hEnable = CreateConVar("sm_psck_enable", "1", "Enable/Disable the plugin", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	hEnable.AddChangeHook(ConVarChanged);
	
	hForceSoldier = CreateConVar("sm_psck_forcesoldier", "1", "Force the player to be a soldier when he'll be the Freak", 0, true, 0.0, true, 1.0);
	hForceSoldier.AddChangeHook(ConVarChanged);
	
	hCanChangeClass = CreateConVar("sm_psck_canchangeclass", "0", "If the player can change class while being Painis Cupcake", 0, true, 0.0, true, 1.0);
	hCanChangeClass.AddChangeHook(ConVarChanged);
	
	hCanChangeTeam = CreateConVar("sm_psck_canchangeteam", "0", "If the player can change team while being Painis Cupcake", 0, true, 0.0, true, 1.0);
	hCanChangeTeam.AddChangeHook(ConVarChanged);
	
	hCanAttackEveryone = CreateConVar("sm_psck_canattackeveryone", "1", "Enable/Disable Robin Walker can attack everyone even his teammates", 0, true, 0.0, true, 1.0);
	hCanAttackEveryone.AddChangeHook(ConVarChanged);
	
	hConserveBuildings = CreateConVar("sm_psck_conservebuildings", "1", "Enable/Disable Conserve his buildings when he is Painis Cupcake", 0, true, 0.0, true, 1.0);
	hConserveBuildings.AddChangeHook(ConVarChanged);
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
	if(hConVar == hMusic)
		GetConVarString(hMusic, cMusic, sizeof(cMusic));
	
	if(hConVar == hSoundDuration)
		fSoundDuration = StringToFloat(strNewValue);
		
	if(hConVar == hEnable)
		bEnable = view_as<bool>(StringToInt(strNewValue));
	
	if(hConVar == hForceSoldier)
		bForceSoldier = view_as<bool>(StringToInt(strNewValue));
	
	if(hConVar == hCanChangeClass)
		bCanChangeClass = view_as<bool>(StringToInt(strNewValue));
	
	if(hConVar == hCanAttackEveryone)
		bCanAttackEveryone = view_as<bool>(StringToInt(strNewValue));
	
	if(hConVar == hCanChangeTeam)
		bCanChangeTeam = view_as<bool>(StringToInt(strNewValue));
	
	if(hConVar == hConserveBuildings)
	bConserveBuildings = view_as<bool>(StringToInt(strNewValue));
	
}

public void OnConfigsExecuted()
{
	fSoundDuration = hSoundDuration.FloatValue;
	bEnable = hEnable.BoolValue;
	bForceSoldier = hForceSoldier.BoolValue;
	bCanChangeClass = hCanChangeClass.BoolValue;
	bCanAttackEveryone = hCanAttackEveryone.BoolValue;
	bCanChangeTeam = hCanChangeTeam.BoolValue;
	bConserveBuildings = hConserveBuildings.BoolValue;
}

public void OnAdminMenuReady(Handle topmenu)
{
	TopMenu hTop_Menu = TopMenu.FromHandle(topmenu);
	
	if(hTopMenu == hTop_Menu)
		return;
		
	hTopMenu = hTop_Menu;
	
	
	TopMenuObject playercommands = hTopMenu.FindCategory(ADMINMENU_PLAYERCOMMANDS);
	if(playercommands != INVALID_TOPMENUOBJECT)
		hTopMenu.AddItem("sm_psckmenu", AdminMenu_BeRobinMenu, playercommands, "sm_psckmenu", ADMFLAG_ROOT);

}

public Action UserMessageRename(UserMsg msg_id, BfRead msg, const int[] players, int playersNum, bool reliable, bool init)
{
	char sMessage[96];
	msg.ReadString(sMessage, sizeof(sMessage));
	msg.ReadString(sMessage, sizeof(sMessage));
	if (StrContains(sMessage, "Name_Change") != -1) {
		return Plugin_Handled;
	}
	
	return Plugin_Continue;
}

//////COMMANDS LISTNERS//////

public Action Player_CallMedic(int client, const char[] command, int argc)
{
	if(bIsRobin[client])
	{
		char arguments[4];
		GetCmdArgString(arguments, sizeof(arguments));
		
		if(StrEqual(arguments, "0 0", false))
		{
			if(!bIsThirdPerson[client])
			{
				SetVariantInt(1);
				AcceptEntityInput(client, "SetForcedTauntCam");
				bIsThirdPerson[client] = true;
			}
			else
			{
				SetVariantInt(0);
				AcceptEntityInput(client, "SetForcedTauntCam");
				bIsThirdPerson[client] = false;
			}
			return Plugin_Handled;
		}
	}
	return Plugin_Continue;
}

public Action Player_ChangeClassBlock(int client, const char[] command, int argc)
{
	if(!bCanChangeClass && bIsRobin[client])
	{
		CPrintToChat(client, "{red}You cannot change class while being Painis Cupcake");
		return Plugin_Handled;
	}
		
	return Plugin_Continue;
}

public Action Player_ChangeTeamBlock(int client, const char[] command, int argc)
{
	if(!bCanChangeTeam && bIsRobin[client])
	{
		CPrintToChat(client, "{red}You cannot change team while being Painis Cupcake");
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
		bisSoldier[iClient] = true;
	
	else
	{
		bisSoldier[iClient] = false;

		if(bIsRobin[iClient])
			if(bCanChangeClass)
				SetRobinPlayer(iClient, iClient, false);
			
	}
}

public Action Player_Team(Event hEvent, const char[] cName, bool bDontBroadcast)
{
	int iClient = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	
	if(bCanChangeTeam && bIsRobin[iClient])
	{
		bIsRobin[iClient] = false;
		StopMusic();
		CreateTimer(0.1, RemoveCond, GetClientUserId(iClient));
		CreateTimer(0.1, RegenerateClient, GetClientUserId(iClient));
			
		if(bIsThirdPerson[iClient])
			CPrintToChat(iClient, "[SM] Type {green}!resettp {default}to remove the thirdperson view");
			
		char buffer[MAX_NAME_LENGTH];
		Format(buffer, sizeof(buffer), "%s", SaveName[iClient]);
		SetClientName(iClient, buffer);
		
		bIsRenamedClient[iClient] = false;
	}

}

public Action Player_Died(Event hEvent, const char[] cName, bool bDontBroadcast)
{
	int iClient = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	
	if(bIsRobin[iClient])	
	{
		SetRobinPlayer(iClient, iClient, false);
		char buffer[MAX_NAME_LENGTH];
		Format(buffer, sizeof(buffer), "%s", SaveName[iClient]);
		SetClientName(iClient, buffer);
		bIsRenamedClient[iClient] = false;
	}
	return Plugin_Continue;
}

public Action Player_Spawn(Event hEvent, const char[] cName, bool bDontBroadcast)
{
	int iClient = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	int ClassIndex = GetEventInt(hEvent, "class");
	
	IsInSpawn[iClient] = true;
	
	if(ClassIndex == view_as<int>(TFClass_Soldier))
		bisSoldier[iClient] = true;
	
	else
	{
		bisSoldier[iClient] = false;

		if(bIsRobin[iClient])
			SetRobinPlayer(iClient, iClient, false);
		
	}
	return Plugin_Continue;
}

public Action BuildingsSapped(Event hEvent, const char[] cName, bool bDontBroadcast)
{
	int iClient = GetClientOfUserId(GetEventInt(hEvent, "ownerid"));
	int iObject = GetEventInt(hEvent, "object");
	
	if(bConserveBuildings)
	{
		if(bBuildingsDisabled[iClient])
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

public Action RoundStart(Event hEvent, const char[] cName, bool bDontBroadcast)
{
	if(!IsMannVsMachineMode() && !bWaitingForPlayers)
	{
		for(int client; client <= MaxClients; client++)
		{
			if(bIsRobin[client])
			{
				SetRobinPlayer(client, client, false);
			}
		}
	}
}

public Action RoundEnd(Event hEvent, const char[] cName, bool bDontBroadcast)
{
	if(!IsMannVsMachineMode())
	{
		for(int client; client <= MaxClients; client++)
		{
			if(bIsRobin[client])
			{
				SetRobinPlayer(client, client, false);
			}
		}
	}
}

public Action WaveFailed(Event hEvent, const char[] cName, bool bDontBroadcast)
{
	if(IsMannVsMachineMode())
	{
		for(int client; client <= MaxClients; client++)
		{
			if(bIsRobin[client])
			{
				SetRobinPlayer(client, client, false);
			}
		}
	}
}

public Action WeaponReset(Event hEvent, const char[] cName, bool bDontBroadcast)
{
	int iClient = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	
	CreateTimer(0.1, CheckIsRobin, GetClientUserId(iClient));
}

////////////////////////

public void TF2_OnWaitingForPlayersStart()
{
	bWaitingForPlayers = true;
}

public void TF2_OnWaitingForPlayersEnd()
{
	bWaitingForPlayers = false;
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
	bMusicPrecached = false;
	bMusicPlayed = false;
	bSoundPrecached = false; // no touchy too
	bWaitingForPlayers = false;
	
	PrecacheSound(cMusic, true);
	PrecacheSound("weapons/pan/melee_frying_pan_01.wav", true);
	PrecacheSound("vo/announcer_security_alert.mp3", true);
	
/*
if(IsSoundPrecached(cMusic))
if(IsSoundPrecached("weapons/pan/melee_frying_pan_01.wav")) 
Do not uncomment, these functions are deprecated and i'm not going to edit them
*/
		bMusicPrecached = true;
		bSoundPrecached = true;
	
}

public void OnClientPutInServer(int client)
{
	bIsRobin[client] = false;
	bisSoldier[client] = false;
	bIsRenamedClient[client] = false;
	bCanBeRobin[client] = false;
	bCanBeRobin2[client] = false;
	bIsThirdPerson[client] = false;
	bBuildingsDisabled[client] = false;
	
	GetClientName(client, SaveNameDebug[client],sizeof(SaveNameDebug[]));
}

public void OnMapEnd()
{
	bMusicPrecached = false;
	bMusicPlayed = false;
	//bSoundPrecached = false; Do not uncomment, deprecated function
	bWaitingForPlayers = false;
}

public void OnClientDisconnect(int client)
{
	if(bIsRobin[client])
		bIsRobin[client] = false;


	bisSoldier[client] = false;
	bIsRenamedClient[client] = false;
	bCanBeRobin[client] = false;
	bCanBeRobin2[client] = false;
	bIsThirdPerson[client] = false;
	IsInSpawn[client] = false;
	bBuildingsDisabled[client] = false;
}

/////////*****COMMANDS*****/////////

public Action Command_Robin(int client, int args)
{
	if(bEnable)
	{
		if(client == 0)	//for some people who doesn't know, server console index is 0
		{
			ReplyToCommand(client, "[SM] Command not for server console");
			return Plugin_Handled;
		}
		
		if(args != 0)
		{
			ReplyToCommand(client, "[SM] Usage: sm_cupcake_on <nothing>");
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
	if(bEnable)
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
	if(bEnable)
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
	if(bEnable)
	{
		if(client == 0)
		{
			ReplyToCommand(client, "[SM] The menu can't be displayed on console server");
			return Plugin_Handled;
		}

		DisplayBerobinMenu(client);
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
	if(bEnable)
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
			bIsThirdPerson[client] = false;
		}
		if(args == 1)
		{
			if(CheckCommandAccess(client, "resettp_target", ADMFLAG_KICK, true))
			{
				char arg1[MAX_NAME_LENGTH];
				
				int target = FindTarget(client, arg1, true);
				
				SetVariantInt(0);
				AcceptEntityInput(target, "SetForcedTauntCam");
				bIsThirdPerson[target] = false;
			}
			else
			{
				ReplyToCommand(client, "[SM] You don't have access to this command");
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
	if(bEnable)
	{
		if(client == 0)
		{
			ReplyToCommand(client, "[SM] Cannot display menu in console server");
			return Plugin_Handled;
		}
		if(!bIsRobin[client])
		{
			ReplyToCommand(client, "[SM] Can only be used when you are Painis Cupcake");
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
	char RobinCount[48], MusicPrecached[32], MusicEnabled[32];
		
	Format(RobinCount, sizeof(RobinCount), "Painis Players : %i [Click to reset]", iNumRobin);
	Format(MusicPrecached, sizeof(MusicPrecached), "Music Precached : %s", (bMusicPrecached ? "Yes" : "No"));
	Format(MusicEnabled, sizeof(MusicEnabled), "Music is playing : %s", (bMusicPlayed ? "Yes" : "No"));
		
	Menu menu = new Menu(MenuHandler);
	menu.SetTitle("Painis Menu");
	menu.AddItem("RobinPlayers", RobinCount);
	menu.AddItem("RenameRobin", "Set default player name");
	menu.AddItem("MusicPrecached", MusicPrecached);
	menu.AddItem("MusicEnable", MusicEnabled);
	menu.ExitButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

public Action DisplayBerobinMenu(int client)
{
	char cName[MAX_NAME_LENGTH], buffer[64];
	
	Menu menu = new Menu(MenuTarget);
	menu.SetTitle("Toggle Painis effect Menu");
	
	for(int i = 0; i <= MaxClients; i++)
	{
		if(IsValidClient(i))
		{
			GetClientName(i, cName, sizeof(cName));
			Format(buffer, sizeof(buffer), "%s", cName);
			menu.AddItem(cName, buffer);
		}
	}
	menu.ExitButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

public Action DisplayMenuEffects(int client)
{
	Menu menu = new Menu(MenuConditions);
	menu.SetTitle("Painis Effects Menu");
	menu.AddItem("Add Conditions", "Add Effects");
	menu.AddItem("Remove Conditions", "Remove Effects");
	menu.ExitButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

/////////*****MENUS HANDLES*****/////////

public void AdminMenu_BeRobinMenu(TopMenu hTopmenu, TopMenuAction action, TopMenuObject object_id, int param, char[] strBuffer, int iMaxLength)
{
	if (action == TopMenuAction_DisplayOption)
	{
		Format(strBuffer, iMaxLength, "Toggle Painis Player");
	}
	else if (action == TopMenuAction_SelectOption)
	{
		DisplayBerobinMenu(param);
	}
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
						if(bIsRobin[i])
						{
							SetRobinPlayer(i, param1, false);
							CPrintToChat(param1, "[SM] Painis Cupcake effect removed to every players");
						}
					}
				}
				else
				{
					PrintCenterText(param1, "Can't find any Painis Cupcake");
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
						if(bIsRenamedClient[i])
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
					PrintCenterText(param1, "Can't find any player renamed by \"Be Painis Cupcake\" plugin");
					CreateTimer(0.0, FirstMenu, param1);
				}
			}
			else if(StrEqual(info, "MusicPrecached", false))
			{
				if(bMusicPrecached)
				{
					PrintCenterText(param1, "Music already precached");
					CreateTimer(0.0, FirstMenu, param1);
				}
				else
				{
					menu.SetTitle("Precache the Music ?");
					menu.AddItem("Precache", "Yes");
					menu.AddItem("Nothing", "No");
					
				}
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
				if(bIsRenamedClient[i])
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
						Format(buffer, sizeof(buffer), "%s", SaveNameDebug[target]);
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
			
			else if(StrEqual(info, "Precache", false))
			{
			PrecacheSound(cMusic);
			
			//if(IsSoundPrecached(cMusic))
			//{
			PrintCenterText(param1, "no idea if the sound is precached, the function that used to verify is now deprecated");
			DisplayRobinMenu(param1);
			//}
			//	else
			//	{
			//		PrintCenterText(param1, "Failed to precache the music");
			//		DisplayRobinMenu(param1);
			//	}
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

public int MenuTarget(Menu hMenu, MenuAction action, int param1, int param2)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			char info[32];
			hMenu.GetItem(param2, info, sizeof(info));
			
			int target = FindTarget(param1, info, true);
			if(target == -1)
			{
				return 0;	//don't know if 0 worth like plugin_handled
			}

			if(bIsRobin[target])
				SetRobinPlayer(target, param1, false);
				
			else
				SetRobinPlayer(target, param1, true);
			
			CreateTimer(0.0, BerobinMenu, param1);	//Create a timer because if there is not : after selecting an item, nothing happening and menu disappears
		}
		case MenuAction_Cancel:
		{
			if (param2 == MenuCancel_ExitBack && hTopMenu)
			{
				hTopMenu.Display(param1, TopMenuPosition_LastCategory);
			}
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
				//TF2_SetPlayerPowerPlay(param1, true);		//To have the fire effect and devil laugh
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
				//TF2_SetPlayerPowerPlay(param1, false);
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
}

public Action PlayStopMenu(Handle timer, any client)
{
	Menu menu = new Menu(MenuHandle1);
	menu.SetTitle("Music Status : %s", (bMusicPlayed ? "Is playing" : "Is not playing"));
	menu.AddItem("PlayNow", "Enable (Play music now)");
	menu.AddItem("Disable", "Disable (Stop music now)");
	menu.ExitBackButton = true;
	menu.ExitButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

public Action BerobinMenu(Handle timer, any client)
{
	DisplayBerobinMenu(client);	//After an item selected, return to the previous menu
}

void ConditionsMenu(int client, bool OptionAdd)
{
	if(OptionAdd)
		AddConditions(client);
		
	else
		RemoveConditions(client);
}

public Action AddConditions(int client)
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

public Action RemoveConditions(int client)
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
		if(!bIsRobin[client])
		{
			if(IsPlayerAlive(client))
			{
				if(bCanAttackEveryone)
				{
					if(!IsInSpawn[client])
						bCanBeRobin2[client] = true;
						
					else
					{
						bCanBeRobin2[client] = false;
						
						if(admin == client)
							ReplyToCommand(admin, "[SM] You mustn't be in spawn to be Painis Cupcake");
							
						else
							ReplyToCommand(admin, "[SM] He mustn't be in spawn to be Painis Cupcake");
						
					}
				}
				else
					bCanBeRobin2[client] = true;
					
				if(bCanBeRobin2[client])
				{
					if(bForceSoldier)
					{
						if(TF2_GetPlayerClass(client) == TFClass_Engineer)
						{
							int iEnt = -1;
							
							if(bConserveBuildings)
							{
								while((iEnt = FindEntityByClassname(iEnt, "obj_*")) != INVALID_ENT_REFERENCE)
								{
									if(GetEntPropEnt(iEnt, Prop_Send, "m_hBuilder") == client)
									{		
										if(bCanAttackEveryone)
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
								bBuildingsDisabled[client] = true;
							}
							else
							{
								while((iEnt = FindEntityByClassname(iEnt, "obj_*")) != INVALID_ENT_REFERENCE)
								{
									if(GetEntPropEnt(iEnt, Prop_Send, "m_hBuilder") == client)
									{	
										AcceptEntityInput(iEnt, "Kill");
										bBuildingsDisabled[client] = false;
									}
								}
							}
						}
						
						iLastClientClass[client] = GetEntProp(client, Prop_Send, "m_iClass");
							
						TF2_SetPlayerClass(client, TFClass_Soldier);
						bCanBeRobin[client] = true;
							
					}
					else
					{
						if(bisSoldier[client])
							bCanBeRobin[client] = true;
							
						else
						{
							bCanBeRobin[client] = false;
								
							if(admin == client)
								ReplyToCommand(admin, "[SM] You must be a soldier to be Painis Cupcake");
									
							else
								ReplyToCommand(admin, "[SM] He must be a soldier to be Painis Cupcake");
			
						}
					}
				}
					
				if(bCanBeRobin[client] && bCanBeRobin2[client])
				{
					GetClientName(client, SaveName[client], sizeof(SaveName[]));
					char buffer[64];
					Format(buffer, sizeof(buffer), "Painis Cupcake (%s)", SaveName[client]);
					SetClientName(client, buffer);
					
					if(bCanAttackEveryone)
					{
						iLastClientTeam[client] = GetEntProp(client, Prop_Send, "m_iTeamNum");
						float fOrigin[3], fAngles[3];

						GetClientAbsOrigin(client, fOrigin);
						GetClientEyeAngles(client, fAngles);
						
						if(IsMannVsMachineMode())
						{
						//	TF2_ChangeClientTeam(client, TFTeam_Spectator);
							TF2_ChangeClientTeam(client, TFTeam_Unassigned);
							SetEntProp(client, Prop_Send, "m_iTeamNum", 0);
							TF2_RespawnPlayer(client);
							TeleportEntity(client, fOrigin, fAngles, NULL_VECTOR);
							SetEntProp(client, Prop_Send, "m_iTeamNum", 1);
						}
						else
						{
							TF2_ChangeClientTeam(client, TFTeam_Unassigned);
							TF2_RespawnPlayer(client);
							TeleportEntity(client, fOrigin, fAngles, NULL_VECTOR);
						}
						
						IsInSpawn[client] = false;
					}
					
					for(int i = 0; i <= MaxClients; i++)
					{
						if(IsValidClient(i))
						{
							SetHudTextParams(-1.0, 0.2, 5.0, 255, 0, 0, 0);
							ShowSyncHudText(i, Hhud, "Security Alert! \"%s\" is the Painis Cupcake!", SaveName[client]);
							
						}
					}
					
					if(TF2_IsPlayerInCondition(client, TFCond_Zoomed))
						TF2_RemoveCondition(client, TFCond_Zoomed);
					
					SetEntProp(client, Prop_Send, "m_bGlowEnabled", 1);
					CreateTimer(0.0, ReplaceWeapon, GetClientUserId(client));
					CreateTimer(0.1, AddCond, GetClientUserId(client));
					PrintCenterText(client, "Call for MEDIC! to toggle thirdperson/firstperson view");
					CPrintToChat(client, "[SM] Call for {green}MEDIC! {default}to toggle {green}thirdperson/firstperson view");
					EmitSoundToAll("vo/announcer_security_alert.mp3");
				//	EmitSoundToAll("vo/announcer_security_alert.mp3"); this used to make the alert louder, uncomment if you want a earrape
					CreateTimer(7.0, MenuNotif, GetClientUserId(client));
					
					PlaySound(apply);
					bIsRenamedClient[client] = apply;
					bIsRobin[client] = apply;
					
				}
			}
			else
				ReplyToCommand(admin, "[SM] Command only for alive players");
		}
		else
		{
			if(client == admin)
				CReplyToCommand(admin, "{red}[SM] You are already a {yellow}Freak");
				
			else
				CReplyToCommand(admin, "{red}[SM] He is already the {yellow}Freak");

			if(bSoundPrecached)	// this function no longer works, it's only left here so i don't have to re-code it
			{
				SlapPlayer(admin, 0, false);
				EmitSoundToClient(admin, "weapons/pan/melee_frying_pan_01.wav");
			}
			else
				SlapPlayer(admin, 0, true);

		}
	}
	else
	{
		if(bIsRobin[client])
		{
			char buffer[MAX_NAME_LENGTH];
			Format(buffer, sizeof(buffer), "%s", SaveName[client]);
			SetClientName(client, buffer);
				
			CreateTimer(0.1, RemoveCond, GetClientUserId(client));
			CreateTimer(0.0, TimerMusic);
			
			SetEntProp(client, Prop_Send, "m_bGlowEnabled", 0);
			
			if(GetEntProp(client, Prop_Send, "m_iTeamNum") == 1 || !GetEntProp(client, Prop_Send, "m_iTeamNum"))
			{
				float fOrigin[3], fAngles[3];
				
				GetClientAbsOrigin(client, fOrigin);
				GetClientEyeAngles(client, fAngles);
				
				TF2_ChangeClientTeam(client, view_as<TFTeam>(iLastClientTeam[client]));	
				if(IsMannVsMachineMode())
				{
					TF2_RespawnPlayer(client);
					TeleportEntity(client, fOrigin, fAngles, NULL_VECTOR);
				}
				
				IsInSpawn[client] = false;
			}

			if(bForceSoldier)
			{
				TF2_SetPlayerClass(client, view_as<TFClassType>(iLastClientClass[client]));
				SetEntityHealth(client, 1);
				
				if(iLastClientClass[client] == view_as<int>(TFClass_Soldier))
					bisSoldier[client] = true;
					
				else
					bisSoldier[client] = false;
					
			}
			TF2_RegeneratePlayer(client);
			
			if(bIsThirdPerson[client])
				CPrintToChat(client, "[SM] Type {green}!resettp {default}to remove the thirdperson view");
			
			bIsRenamedClient[client] = apply;
			bIsRobin[client] = apply;
			
			
			if(bConserveBuildings)
			{
				if(bBuildingsDisabled[client])
				{
					int iEnt = -1;
					while((iEnt = FindEntityByClassname(iEnt, "obj_*")) != INVALID_ENT_REFERENCE)
					{
						if(GetEntPropEnt(iEnt, Prop_Send, "m_hBuilder") == client)
						{
							if(bCanAttackEveryone)
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
					bBuildingsDisabled[client] = false;
				}
			}
		}
		else
		{
			if(client == admin)
				CReplyToCommand(admin, "{red}[SM] You are not a {yellow}Freak");
				
			else
				CReplyToCommand(admin, "{red}[SM] He is not the {yellow}Freak");
					
			if(IsPlayerAlive(admin))
			{
				if(bSoundPrecached) 
				// this function does not work anymore it's only being left in the code so i don't have to do something about it existing
				{
					SlapPlayer(admin, 0, false);
					EmitSoundToClient(admin, "weapons/pan/melee_frying_pan_01.wav");
				}
				else
					SlapPlayer(admin, 0, true);
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
				ShowSyncHudText(i, Hhud, "Every Painis Cupcake disappeared !");
			}
		}
	}
}

void PlaySound(bool enabled)
{
	if(enabled)
	{
		if(!bMusicPlayed)	//If the music is not already played
		{	
			if(bMusicPrecached)
			{
				EmitSoundToAll(cMusic);
				bMusicPlayed = enabled;
				//[example] hTimer = CreateTimer(96.0, CanReplaySound, _, TIMER_REPEAT);	= After 96s(the default music(I chosed) duration), can play a sound again and eventually repeat again if atleast a Robin player is still alive 
				hTimer = CreateTimer(fSoundDuration, CanReplaySound, _, TIMER_REPEAT);
			}
			else
				LogError("Cannot precache the sound file...");
				
		}
	}
	else
	{
		for(int i = 0; i <= MaxClients; i++)
		{
			StopSound(i, SNDCHAN_AUTO, cMusic);
			bMusicPlayed = enabled;
			delete hTimer;
		}
	}
}

/////////*****SDKHOOKS*****/////////

public Action SpawnStartTouch(int spawn, int client)
{
	if (client > MaxClients || client < 1)
		return;

	if (IsClientConnected(client) && IsClientInGame(client))
		IsInSpawn[client] = true;
}

public Action SpawnEndTouch(int spawn, int client)
{
	if (client > MaxClients || client < 1)
		return;

	if (IsClientConnected(client) && IsClientInGame(client))
		IsInSpawn[client] = false;
}

public void DroppedWeaponSpawn(int iEntity)
{
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsValidClient(i))
		{
			if(bIsRobin[i])
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
	
	CPrintToChat(iClient, "[SM] Type {green}!painiseffects {default}to have a menu that add/remove {green}effects (conditions)");
	
	return Plugin_Continue;
}

public Action CanReplaySound(Handle timer)
{
	bMusicPlayed = false;
	
	int iNumRobin = GetRobinCount();
	bool bCanRepeat = (iNumRobin > 0);

	if(bCanRepeat)	//Repeat the music if there is atleast 1 player that is Robin Walker
	{
		EmitSoundToAll(cMusic);
		bMusicPlayed = true;
	}
}

public Action TimerMusic(Handle timer)
{
	StopMusic();
}

public Action CheckIsRobin(Handle timer, any iUserId)
{
	int iClient = GetClientOfUserId(iUserId);
	
	if((iClient <= 0 || iClient > MaxClients))
		return  Plugin_Stop;
		
	if(!IsClientInGame(iClient))
		return  Plugin_Stop;
	
	if(bIsRobin[iClient])
		CreateTimer(0.1, ReplaceWeapon, iUserId);
		
	return Plugin_Continue;
}

public Action ReplaceWeapon(Handle timer, any iUserId)
{
	int iClient = GetClientOfUserId(iUserId);
	
	TF2_RemoveAllWeapons(iClient);
	
	//TF2Items_GiveWeapon(iClient, "tf_weapon_shovel", 5, 100, 8, "134 ; 2 ; 2 ; 200 ; 4 ; 201 ; 6 ; 0.25 ; 110 ; 250 ; 31 ; 10 ; 103 ; 1.5 ; 107 ; 2 ; 26 ; 600 ; 97 ; 0.25 ; 76 ; 200");
	TF2Items_GiveWeapon(iClient, "tf_weapon_shovel", 5, 69, 8, "2 ; 200 ; 6 ; 0.25 ; 110 ; 150 ; 31 ; 10 ; 107 ; 2 ; 26 ; 800");
	//SetAmmo(iClient, 0, 4000);
	
	SetEntityHealth(iClient, 1000);	//Add +800 health because of the attribe maxhealth added to 800
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
	//TF2_SetPlayerPowerPlay(iClient, true);
	CreateTimer(0.1, TauntFix, iUserId);
	
	return Plugin_Continue;
}

public Action RemoveCond(Handle timer, any iUserId)
{
	int iClient = GetClientOfUserId(iUserId);
	
	if((iClient <= 0 || iClient > MaxClients) && !IsClientInGame(iClient))
		return  Plugin_Stop;
	
	//TF2_SetPlayerPowerPlay(iClient, false);
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
		if(bIsRobin[i])
			iCount++;
			
	return iCount;
}

stock int GetRenamedPlayerCount()
{
	int iCount;
	
	for(int i = 0; i <= MaxClients; i++)
		if(bIsRenamedClient[i])
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