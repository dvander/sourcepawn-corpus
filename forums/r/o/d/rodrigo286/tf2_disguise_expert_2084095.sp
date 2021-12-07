/*
Description:

Allows players to perform a disguise to fool other players.  (Mr Troll)

This plugin has been rewritten from plugin made by member: Chaosxk
Thread: https://forums.alliedmods.net/showthread.php?p=1863229

The cause of rewriting the plugin? Many bugs and support and add options.

Commands:

!disguise or !dm - Open disguise menu
Hold the crouch button and press the mouse2 button - Disguise
Hold the crouch button and press the mouse1 button - Undisguise

CVARs:

sm_disguisexpert_enabled 0/1 Plugin enabled/disabled (DEF. 1)
sm_disguisexpert_admonly 0/1 Disguise menu for admins only? (DEF. 0)
sm_disguisexpert_allow_weapons 0/1 Allow players shot while disguised? (DEF. 1)
sm_disguisexpert_version - Current plugin version

Credits:

Plugin re-write - Rodrigo286
Original thread - Chaosxk
Little bit code of .cfg structure of [CS:GO] Skins Chooser - Root_
Idea - Vadia111

Changelog:

* Version 1.0.0 *
Initial Release

* Version 1.0.1 *
ConVar FIX
Small optimizations
Small bugs reported by Vadia111

* Version 1.0.2 *
Add ConVars
Small ConVars optimizations
Little bit code optimizations

* Version 1.0.3 *
Add ConVar
Laugh sound spam blocked

* Version 1.0.4 *
Add ConVar to restrict/unrestrict class
Add ConVar to disable/enable Laugh and Disguise announcements
Add command to block/unblock disguise
Edit minimum time for Laugh and Disguise time
Little reported bugs fixed
Some spam breachs fixed
Code check and clean
*/
/* 
	Library includes
*/
#include <sourcemod>
#include <sdkhooks>
#include <tf2_stocks>
/* 
	Internal includes
*/
#include "disguise_expert/disguise_sounds"
#include "disguise_expert/undisguise_sounds"
#include "disguise_expert/laungh_sounds"
#pragma semicolon 1
/* 
	Current plugin version
*/
#define PLUGIN_VERSION "1.0.4"
/* 
	Some defines
*/
#define FADE_SCREEN_TYPE_IN  (0x0001 | 0x0010)
/*
	Variables
*/
new DEnabled;
new OnlyAdmins;
new WPAllowed;
new WLKAllowed;
new DMessages;
new LMessages;
new AllowScout;
new AllowSniper;
new AllowSoldier;
new AllowDemoMan;
new AllowMedic;
new AllowHeavy;
new AllowPyro;
new AllowSpy;
new AllowEngineer;
new NoSpamDAA[MAXPLAYERS+1];
new NoSpamDAC[MAXPLAYERS+1];
/*
	Float
*/
new Float:DGTime;
new Float:LTime;
/*
	Bools
*/
new bool:lWnabled[MAXPLAYERS+1];
new bool:PHasDisguised[MAXPLAYERS+1];
new bool:CanDisguise[MAXPLAYERS+1] = true;
/*
	Strings
*/
new String:disguiseMODEL[MAXPLAYERS+1][PLATFORM_MAX_PATH];
new String:disguiseNAME[MAXPLAYERS+1][PLATFORM_MAX_PATH];
new String:admflag[64];
new String:commands_disguise[][] = {
    "disguise", 
    "dm"
};
/*
	Handles
*/
new Handle:disguisemenu = INVALID_HANDLE;
new Handle:gDEnabled = INVALID_HANDLE;
new Handle:gOnlyAdmins = INVALID_HANDLE;
new Handle:gWPAllowed = INVALID_HANDLE;
new Handle:gadmflag = INVALID_HANDLE;
new Handle:gWLKAllowed = INVALID_HANDLE;
new Handle:gDGTime = INVALID_HANDLE;
new Handle:gLTime = INVALID_HANDLE;
new Handle:CallDTime[MAXPLAYERS+1];
new Handle:CallLTime[MAXPLAYERS+1];
new Handle:gDMessages = INVALID_HANDLE;
new Handle:gLMessages = INVALID_HANDLE;
new Handle:gAllowScout = INVALID_HANDLE;
new Handle:gAllowSniper = INVALID_HANDLE;
new Handle:gAllowSoldier = INVALID_HANDLE;
new Handle:gAllowDemoMan = INVALID_HANDLE;
new Handle:gAllowMedic = INVALID_HANDLE;
new Handle:gAllowHeavy = INVALID_HANDLE;
new Handle:gAllowPyro = INVALID_HANDLE;
new Handle:gAllowSpy = INVALID_HANDLE;
new Handle:gAllowEngineer = INVALID_HANDLE;
new Handle:hTNoSpamDAA = INVALID_HANDLE;
new Handle:hTNoSpamDAC = INVALID_HANDLE;
/* 
	Plugin info
*/
public Plugin:myinfo = 
{
	name = "SM Disguise Expert",
	author = "Rodrigo286",
	description = "Disguise ability for fun gameplay",
	version = PLUGIN_VERSION,
	url = "www.sourcemod.net"
}

public OnPluginStart()
{
// #----------------------------------------------HOOK PLAYER SPAWN--------------------------------------------------#
	HookEvent("player_spawn", OnPlayerSpawn);
// #---------------------------------------------HOOK CALL MEDIC CMD-------------------------------------------------#
	AddCommandListener(Listener_Voice, "voicemenu");
// #---------------------------------------------CVARS CONFIGURATION-------------------------------------------------#
	CreateConVar("sm_disguisexpert_version", PLUGIN_VERSION, "\"SM Disguise Expert\" version", FCVAR_NONE|FCVAR_SPONLY|FCVAR_NOTIFY);
	gDEnabled = CreateConVar("sm_disguisexpert_enabled", "1", "Plugin enabled?", FCVAR_NONE, true, 0.0, true, 1.0);
	gOnlyAdmins = CreateConVar("sm_disguisexpert_admonly", "0", "Disguise menu for admins only?", FCVAR_NONE, true, 0.0, true, 1.0);
	gWPAllowed = CreateConVar("sm_disguisexpert_allow_weapons", "1", "Allow players shot while disguised?", FCVAR_NONE, true, 0.0, true, 1.0);
	gWLKAllowed = CreateConVar("sm_disguisexpert_allow_walk", "1", "Allow players walk while disguised?", FCVAR_NONE, true, 0.0, true, 1.0);
	gadmflag = CreateConVar("sm_disguisexpert_flag", "b", "If admonly is enabled, put here a flag for filter users", FCVAR_NONE);
	gDGTime = CreateConVar("sm_disguisexpert_disguise_time", "10.0", "Time to disguise again after undisguise?", FCVAR_NONE, true, 0.5, true, 300.0);
	gLTime = CreateConVar("sm_disguisexpert_laungh_time", "8.0", "Time to laugh while disguised?", FCVAR_NONE, true, 0.5, true, 30.0);
	gDMessages = CreateConVar("sm_disguisexpert_disguise_announcements", "1", "Enable disguise announcements?", FCVAR_NONE, true, 0.0, true, 1.0);
	gLMessages = CreateConVar("sm_disguisexpert_laungh_announcements", "1", "Enabled laungh announcements?", FCVAR_NONE, true, 0.0, true, 1.0);
	gAllowScout = CreateConVar("sm_disguisexpert_allow_scout", "1", "Allow scout use disguise?", FCVAR_NONE, true, 0.0, true, 1.0);
	gAllowSniper = CreateConVar("sm_disguisexpert_allow_sniper", "1", "Allow sniper use disguise?", FCVAR_NONE, true, 0.0, true, 1.0);
	gAllowSoldier = CreateConVar("sm_disguisexpert_allow_soldier", "1", "Allow soldier use disguise?", FCVAR_NONE, true, 0.0, true, 1.0);
	gAllowDemoMan = CreateConVar("sm_disguisexpert_allow_demoman", "1", "Allow demoman use disguise?", FCVAR_NONE, true, 0.0, true, 1.0);
	gAllowMedic = CreateConVar("sm_disguisexpert_allow_medic", "1", "Allow medic use disguise?", FCVAR_NONE, true, 0.0, true, 1.0);
	gAllowHeavy = CreateConVar("sm_disguisexpert_allow_heavy", "1", "Allow heavy use disguise?", FCVAR_NONE, true, 0.0, true, 1.0);
	gAllowPyro = CreateConVar("sm_disguisexpert_allow_pyro", "1", "Allow pyro use disguise?", FCVAR_NONE, true, 0.0, true, 1.0);
	gAllowSpy = CreateConVar("sm_disguisexpert_allow_spy", "1", "Allow spy use disguise?", FCVAR_NONE, true, 0.0, true, 1.0);
	gAllowEngineer = CreateConVar("sm_disguisexpert_allow_engineer", "1", "Allow engineer use disguise?", FCVAR_NONE, true, 0.0, true, 1.0);
	AutoExecConfig(true, "sm_disguise_expert");

	HookConVarChange(gDEnabled, ConVarChange);
	HookConVarChange(gOnlyAdmins, ConVarChange);
	HookConVarChange(gWPAllowed, ConVarChange);
	HookConVarChange(gadmflag, ConVarChange);
	HookConVarChange(gWLKAllowed, ConVarChange);
	HookConVarChange(gDGTime, ConVarChange);
	HookConVarChange(gLTime, ConVarChange);
	HookConVarChange(gDMessages, ConVarChange);
	HookConVarChange(gLMessages, ConVarChange);
	HookConVarChange(gAllowScout, ConVarChange);
	HookConVarChange(gAllowSniper, ConVarChange);
	HookConVarChange(gAllowSoldier, ConVarChange);
	HookConVarChange(gAllowDemoMan, ConVarChange);
	HookConVarChange(gAllowMedic, ConVarChange);
	HookConVarChange(gAllowHeavy, ConVarChange);
	HookConVarChange(gAllowPyro, ConVarChange);
	HookConVarChange(gAllowSpy, ConVarChange);
	HookConVarChange(gAllowEngineer, ConVarChange);

	DEnabled = GetConVarBool(gDEnabled);
	OnlyAdmins = GetConVarBool(gOnlyAdmins);
	WPAllowed = GetConVarBool(gWPAllowed);
	GetConVarString(gadmflag, admflag, sizeof(admflag));
	WLKAllowed = GetConVarBool(gWLKAllowed);
	DGTime = GetConVarFloat(gDGTime);
	LTime = GetConVarFloat(gLTime);
	DMessages = GetConVarBool(gDMessages);
	LMessages = GetConVarBool(gLMessages);
	AllowScout = GetConVarBool(gAllowScout);
	AllowSniper = GetConVarBool(gAllowSniper);
	AllowSoldier = GetConVarBool(gAllowSoldier);
	AllowDemoMan = GetConVarBool(gAllowDemoMan);
	AllowMedic = GetConVarBool(gAllowMedic);
	AllowHeavy = GetConVarBool(gAllowHeavy);
	AllowPyro = GetConVarBool(gAllowPyro);
	AllowSpy = GetConVarBool(gAllowSpy);
	AllowEngineer = GetConVarBool(gAllowEngineer);
// #------------------------------------------------MAKE COMMANDS----------------------------------------------------#
	for (new i = 0; i < sizeof(commands_disguise); i++)
	{
		RegConsoleCmd(commands_disguise[i], CallDisguise);
	}
	RegConsoleCmd("nodisguise", CallDisguiseBlock);
}

public ConVarChange(Handle:convar, const String:oldValue[], const String:newValue[])
{
	DEnabled = GetConVarBool(gDEnabled);
	OnlyAdmins = GetConVarBool(gOnlyAdmins);
	WPAllowed = GetConVarBool(gWPAllowed);
	GetConVarString(gadmflag, admflag, sizeof(admflag));
	WLKAllowed = GetConVarBool(gWLKAllowed);
	DGTime = GetConVarFloat(gDGTime);
	LTime = GetConVarFloat(gLTime);
	DMessages = GetConVarBool(gDMessages);
	LMessages = GetConVarBool(gLMessages);
	AllowScout = GetConVarBool(gAllowScout);
	AllowSniper = GetConVarBool(gAllowSniper);
	AllowSoldier = GetConVarBool(gAllowSoldier);
	AllowDemoMan = GetConVarBool(gAllowDemoMan);
	AllowMedic = GetConVarBool(gAllowMedic);
	AllowHeavy = GetConVarBool(gAllowHeavy);
	AllowPyro = GetConVarBool(gAllowPyro);
	AllowSpy = GetConVarBool(gAllowSpy);
	AllowEngineer = GetConVarBool(gAllowEngineer);
}

public OnMapStart() 
{
// #-------------------------------LOAD DISGUISE SOUNDS------------------------------#
	decl String:DSF[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, DSF, sizeof(DSF), "configs/disguisexpert/disguise_sounds.txt");	
	MDS(DSF);
// #-------------------------------LOAD UNDISGUISE SOUNDS----------------------------#
	decl String:UDSF[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, UDSF, sizeof(UDSF), "configs/disguisexpert/undisguise_sounds.txt");	
	MUNDS(UDSF);
// #---------------------------------LOAD LAUNCH SOUNDS------------------------------#
	decl String:LSF[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, LSF, sizeof(LSF), "configs/disguisexpert/laungh_sounds.txt");	
	MLS(LSF);
// #-------------------------LOAD DISGUISE MODELS AND NAMES--------------------------#
	decl String:bFILE[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, bFILE, sizeof(bFILE), "configs/disguisexpert/disguises.txt");

	new Handle:hndl = OpenFile(bFILE, "r");

	if(hndl == INVALID_HANDLE)
		return;

	decl String:bufferEXPLODE[2][PLATFORM_MAX_PATH];

	while(!IsEndOfFile(hndl) && ReadFileLine(hndl, bFILE, sizeof(bFILE)))
	{
		if (ExplodeString(bFILE, ";", bufferEXPLODE, sizeof(bufferEXPLODE), sizeof(bufferEXPLODE[])) != 2 || !StrContains(bufferEXPLODE[0],"//"))
		{
			continue;
		}

		if(!IsModelPrecached(bufferEXPLODE[0]))
		PrecacheModel(bufferEXPLODE[0], true);
	}

	CloseHandle(hndl);
}

public Action:OnPlayerSpawn(Handle:event,const String:name[],bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));

	if(StrEqual(disguiseMODEL[client], "") || PHasDisguised[client] == false)
		return;

	Undisguise(client);

	if(DMessages != 0)
		PrintToChat(client, "\x03[\x04SM: Disguise Expert\x03] \x01You are undisguised if you spawn.");
}

public OnClientPutInServer(client)
{
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
	PHasDisguised[client] = false;
	CanDisguise[client] = true;
}

public OnClientDisconnect(client)
{
	SDKUnhook(client, SDKHook_OnTakeDamage, OnTakeDamage);
	_CloseHandle(CallDTime[client]);
	_CloseHandle(CallLTime[client]);
}

public OnConfigsExecuted()
{
	new String:bufferFILE[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, bufferFILE, sizeof(bufferFILE), "configs/disguisexpert/disguises.txt");

	new Handle:hndl = OpenFile(bufferFILE, "r");

	if(hndl == INVALID_HANDLE)
	{
		PrintToServer("Couldn't open file \"configs/disguisexpert/disguises.txt\"");
		return;
	}

	disguisemenu = CreateMenu(MenuHandler);
	SetMenuTitle(disguisemenu, "-= Choose you disguise =-");

	decl String:bufferEXPLODE[2][PLATFORM_MAX_PATH];

	while(!IsEndOfFile(hndl) && ReadFileLine(hndl, bufferFILE, sizeof(bufferFILE)))
	{
		if (ExplodeString(bufferFILE, ";", bufferEXPLODE, sizeof(bufferEXPLODE), sizeof(bufferEXPLODE[])) != 2 || !StrContains(bufferEXPLODE[0],"//"))
		{
			continue;
		}

		AddMenuItem(disguisemenu, bufferFILE, bufferEXPLODE[1]);
	}

	CloseHandle(hndl);
}

public Action:CallDisguise(client, args)
{
	if(IsClientInGame(client))
	{
		if(DEnabled != 1)
		{
			if(DMessages != 0)
				PrintToChat(client, "\x03[\x04SM: Disguise Expert\x03] \x01Disguise menu is temporarily disabled, sorry.");

			return;
		}

		if(TF2_GetPlayerClass(client) == TFClass_Scout && AllowScout == 0)
		{
			if(DMessages != 0)	
				PrintToChat(client, "\x03[\x04SM: Disguise Expert\x03] \x01Disguise temporarily dont allowed for you class.");

			return;
		}

		if(TF2_GetPlayerClass(client) == TFClass_Sniper && AllowSniper == 0)
		{
			if(DMessages != 0)	
				PrintToChat(client, "\x03[\x04SM: Disguise Expert\x03] \x01Disguise temporarily dont allowed for you class.");

			return;
		}

		if(TF2_GetPlayerClass(client) == TFClass_Soldier && AllowSoldier == 0)
		{
			if(DMessages != 0)	
				PrintToChat(client, "\x03[\x04SM: Disguise Expert\x03] \x01Disguise temporarily dont allowed for you class.");

			return;
		}

		if(TF2_GetPlayerClass(client) == TFClass_DemoMan && AllowDemoMan == 0)
		{
			if(DMessages != 0)	
				PrintToChat(client, "\x03[\x04SM: Disguise Expert\x03] \x01Disguise temporarily dont allowed for you class.");

			return;
		}

		if(TF2_GetPlayerClass(client) == TFClass_Medic && AllowMedic == 0)
		{
			if(DMessages != 0)	
				PrintToChat(client, "\x03[\x04SM: Disguise Expert\x03] \x01Disguise temporarily dont allowed for you class.");

			return;
		}

		if(TF2_GetPlayerClass(client) == TFClass_Heavy && AllowHeavy == 0)
		{
			if(DMessages != 0)	
				PrintToChat(client, "\x03[\x04SM: Disguise Expert\x03] \x01Disguise temporarily dont allowed for you class.");

			return;
		}

		if(TF2_GetPlayerClass(client) == TFClass_Pyro && AllowPyro == 0)
		{
			if(DMessages != 0)	
				PrintToChat(client, "\x03[\x04SM: Disguise Expert\x03] \x01Disguise temporarily dont allowed for you class.");

			return;
		}

		if(TF2_GetPlayerClass(client) == TFClass_Spy && AllowSpy == 0)
		{
			if(DMessages != 0)	
				PrintToChat(client, "\x03[\x04SM: Disguise Expert\x03] \x01Disguise temporarily dont allowed for you class.");

			return;
		}

		if(TF2_GetPlayerClass(client) == TFClass_Engineer && AllowEngineer == 0)
		{
			if(DMessages != 0)	
				PrintToChat(client, "\x03[\x04SM: Disguise Expert\x03] \x01Disguise temporarily dont allowed for you class.");

			return;
		}

		if(OnlyAdmins == 1 && !IsClientAdmin(client))
		{
			if(DMessages != 0)	
				PrintToChat(client, "\x03[\x04SM: Disguise Expert\x03] \x01Disguise allowed only for admins, sorry.");

			return;
		}

		if(disguisemenu != INVALID_HANDLE)
		{
			DisplayMenu(disguisemenu, client, 0);
		}
		else
		{
			PrintToConsole(client, "[SM DISGUISE] Could not open Allow.");
		}
	}
}

public Action:CallDisguiseBlock(client, args)
{
	if(IsClientInGame(client))
	{
		if(DEnabled != 1)
		{
			if(DMessages != 0)
				PrintToChat(client, "\x03[\x04SM: Disguise Expert\x03] \x01Disguise menu is temporarily disabled, sorry.");

			return;
		}

		if(CanDisguise[client] == true)
		{
			CanDisguise[client] = false;

			if(DMessages != 0)
				PrintToChat(client, "\x03[\x04SM: Disguise Expert\x03] \x01You block disguise mode.");
		}
		else if(CanDisguise[client] == false)
		{
			CanDisguise[client] = true;

			if(DMessages != 0)
				PrintToChat(client, "\x03[\x04SM: Disguise Expert\x03] \x01You unblock disguise mode.");
		}
	}
}  

public MenuHandler(Handle:menu, MenuAction:action, client, param2) 
{ 
	if(action == MenuAction_Select) 
	{        
		decl String:infoPARAM[256], String:infoEXPLODE[2][256];
		GetMenuItem(disguisemenu, param2, infoPARAM, sizeof(infoPARAM));

		ExplodeString(infoPARAM, ";", infoEXPLODE, sizeof(infoEXPLODE), sizeof(infoEXPLODE[]));

		TrimString(infoEXPLODE[1]);

		if(DMessages != 0)
		{
			PrintCenterText(client, "%s disguise selected!", infoEXPLODE[1]);
			PrintToChat(client, "\x03[\x04SM: Disguise Expert\x03] \x01%s disguise selected, it's time to troll !!", infoEXPLODE[1]);
		}

		FormatEx(disguiseMODEL[client], sizeof(disguiseMODEL[]), infoEXPLODE[0]);	
		FormatEx(disguiseNAME[client], sizeof(disguiseNAME[]), infoEXPLODE[1]);
	}
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon) 
{
	if(IsValidClient(client))
	{
		if((GetEntityFlags(client) & FL_DUCKING) && (GetEntityFlags(client) & FL_ONGROUND) && !(GetEntityFlags(client) & FL_INWATER) && buttons & IN_ATTACK2) 
		{
			if(TF2_GetPlayerClass(client) == TFClass_Scout && AllowScout == 0)
			{
				if(DMessages != 0 && NoSpamDAC[client] == 0)	
					PrintToChat(client, "\x03[\x04SM: Disguise Expert\x03] \x01Disguise temporarily dont allowed for you class.");

				NoSpamDAC[client]++;
				_CloseHandle(hTNoSpamDAC);
				hTNoSpamDAC = CreateTimer(5.0, TNoSpamDAC, client);

				return;
			}

			if(TF2_GetPlayerClass(client) == TFClass_Sniper && AllowSniper == 0)
			{
				if(DMessages != 0 && NoSpamDAC[client] == 0)	
					PrintToChat(client, "\x03[\x04SM: Disguise Expert\x03] \x01Disguise temporarily dont allowed for you class.");

				NoSpamDAC[client]++;
				_CloseHandle(hTNoSpamDAC);
				hTNoSpamDAC = CreateTimer(5.0, TNoSpamDAC, client);

				return;
			}

			if(TF2_GetPlayerClass(client) == TFClass_Soldier && AllowSoldier == 0)
			{
				if(DMessages != 0 && NoSpamDAC[client] == 0)
					PrintToChat(client, "\x03[\x04SM: Disguise Expert\x03] \x01Disguise temporarily dont allowed for you class.");

				NoSpamDAC[client]++;
				_CloseHandle(hTNoSpamDAC);
				hTNoSpamDAC = CreateTimer(5.0, TNoSpamDAC, client);

				return;
			}

			if(TF2_GetPlayerClass(client) == TFClass_DemoMan && AllowDemoMan == 0)
			{
				if(DMessages != 0 && NoSpamDAC[client] == 0)	
					PrintToChat(client, "\x03[\x04SM: Disguise Expert\x03] \x01Disguise temporarily dont allowed for you class.");

				NoSpamDAC[client]++;
				_CloseHandle(hTNoSpamDAC);
				hTNoSpamDAC = CreateTimer(5.0, TNoSpamDAC, client);

				return;
			}

			if(TF2_GetPlayerClass(client) == TFClass_Medic && AllowMedic == 0)
			{
				if(DMessages != 0 && NoSpamDAC[client] == 0)	
					PrintToChat(client, "\x03[\x04SM: Disguise Expert\x03] \x01Disguise temporarily dont allowed for you class.");

				NoSpamDAC[client]++;
				_CloseHandle(hTNoSpamDAC);
				hTNoSpamDAC = CreateTimer(5.0, TNoSpamDAC, client);

				return;
			}

			if(TF2_GetPlayerClass(client) == TFClass_Heavy && AllowHeavy == 0)
			{
				if(DMessages != 0 && NoSpamDAC[client] == 0)	
					PrintToChat(client, "\x03[\x04SM: Disguise Expert\x03] \x01Disguise temporarily dont allowed for you class.");

				NoSpamDAC[client]++;
				_CloseHandle(hTNoSpamDAC);
				hTNoSpamDAC = CreateTimer(5.0, TNoSpamDAC, client);

				return;
			}

			if(TF2_GetPlayerClass(client) == TFClass_Pyro && AllowPyro == 0)
			{
				if(DMessages != 0 && NoSpamDAC[client] == 0)	
					PrintToChat(client, "\x03[\x04SM: Disguise Expert\x03] \x01Disguise temporarily dont allowed for you class.");

				NoSpamDAC[client]++;
				_CloseHandle(hTNoSpamDAC);
				hTNoSpamDAC = CreateTimer(5.0, TNoSpamDAC, client);

				return;
			}

			if(TF2_GetPlayerClass(client) == TFClass_Spy && AllowSpy == 0)
			{
				if(DMessages != 0 && NoSpamDAC[client] == 0)
					PrintToChat(client, "\x03[\x04SM: Disguise Expert\x03] \x01Disguise temporarily dont allowed for you class.");

				NoSpamDAC[client]++;
				_CloseHandle(hTNoSpamDAC);
				hTNoSpamDAC = CreateTimer(5.0, TNoSpamDAC, client);

				return;
			}

			if(TF2_GetPlayerClass(client) == TFClass_Engineer && AllowEngineer == 0)
			{
				if(DMessages != 0 && NoSpamDAC[client] == 0)	
					PrintToChat(client, "\x03[\x04SM: Disguise Expert\x03] \x01Disguise temporarily dont allowed for you class.");

				NoSpamDAC[client]++;
				_CloseHandle(hTNoSpamDAC);
				hTNoSpamDAC = CreateTimer(5.0, TNoSpamDAC, client);

				return;
			}

			if(OnlyAdmins == 1 && !IsClientAdmin(client))
			{
				if(DMessages != 0 && NoSpamDAA[client] == 0)	
					PrintToChat(client, "\x03[\x04SM: Disguise Expert\x03] \x01Disguise allowed only for admins, sorry.");

				NoSpamDAA[client]++;
				_CloseHandle(hTNoSpamDAA);
				hTNoSpamDAA = CreateTimer(5.0, TNoSpamDAA, client);

				return;
			}

			if(StrEqual(disguiseMODEL[client], "") || PHasDisguised[client] == true || CallDTime[client] != INVALID_HANDLE || CanDisguise[client] == false)
				return;

			Disguise(client);
		}
		if((GetEntityFlags(client) & FL_DUCKING) && (GetEntityFlags(client) & FL_ONGROUND) && !(GetEntityFlags(client) & FL_INWATER) && buttons & IN_ATTACK) 
		{
			if(StrEqual(disguiseMODEL[client], "") || PHasDisguised[client] == false || CallDTime[client] != INVALID_HANDLE)
				return;

			Undisguise(client);
			_CloseHandle(CallDTime[client]);
			lWnabled[client] = false;
			_CloseHandle(CallLTime[client]);

			if(DMessages != 0)
				PrintToChat(client, "\x03[\x04SM: Disguise Expert\x03] \x01You can disguise again in %.0f secs...", DGTime);

			CallDTime[client] = CreateTimer(DGTime, cdgTime, client);
		}
	}
}

public Action:TNoSpamDAA(Handle:timer, any:client)
{
	hTNoSpamDAA = INVALID_HANDLE;

	NoSpamDAA[client] = 0;

	return Plugin_Stop;
}

public Action:TNoSpamDAC(Handle:timer, any:client)
{
	hTNoSpamDAC = INVALID_HANDLE;

	NoSpamDAC[client] = 0;

	return Plugin_Stop;
}

public Action:cdgTime(Handle:timer, any:client)
{
	CallDTime[client] = INVALID_HANDLE;

	PHasDisguised[client] = false;

	if(DMessages != 0)
		PrintToChat(client, "\x03[\x04SM: Disguise Expert\x03] \x01You can disguise again now.");
}

Disguise(client)
{
// #--------------------DISGUISED BOOL----------------#
	PHasDisguised[client] = true;
// #------------------FADE PLAYER SCREEN--------------#
	FadeScreen(client, 50, 50, 50, 255, 100, FADE_SCREEN_TYPE_IN);
// #----------------EMIT DISGUISE SOUND---------------#
	new randomDSScout  = GetRandomInt(0, DSCountScout -1);
	new randomDSSniper  = GetRandomInt(0, DSCountSniper  - 1);
	new randomDSSoldier  = GetRandomInt(0, DSCountSoldier  - 1);
	new randomDSDemoMan  = GetRandomInt(0, DSCountDemoMan  - 1);
	new randomDSMedic  = GetRandomInt(0, DSCountMedic  - 1);
	new randomDSHeavy  = GetRandomInt(0, DSCountHeavy  - 1);
	new randomDSPyro  = GetRandomInt(0, DSCountPyro  - 1);
	new randomDSSpy  = GetRandomInt(0, DSCountSpy  - 1);
	new randomDSEngineer  = GetRandomInt(0, DSCountEngineer  - 1);

	if(TF2_GetPlayerClass(client) == TFClass_Scout)
		EmitSoundToAll(DSScout[randomDSScout], client, _, _, _, 1.0);

	if(TF2_GetPlayerClass(client) == TFClass_Sniper)
		EmitSoundToAll(DSSniper[randomDSSniper], client, _, _, _, 1.0);

	if(TF2_GetPlayerClass(client) == TFClass_Soldier)
		EmitSoundToAll(DSSoldier[randomDSSoldier], client, _, _, _, 1.0);

	if(TF2_GetPlayerClass(client) == TFClass_DemoMan)
		EmitSoundToAll(DSDemoMan[randomDSDemoMan], client, _, _, _, 1.0);

	if(TF2_GetPlayerClass(client) == TFClass_Medic)
		EmitSoundToAll(DSMedic[randomDSMedic], client, _, _, _, 1.0);

	if(TF2_GetPlayerClass(client) == TFClass_Heavy)
		EmitSoundToAll(DSHeavy[randomDSHeavy], client, _, _, _, 1.0);

	if(TF2_GetPlayerClass(client) == TFClass_Pyro)
		EmitSoundToAll(DSPyro[randomDSPyro], client, _, _, _, 1.0);

	if(TF2_GetPlayerClass(client) == TFClass_Spy)
		EmitSoundToAll(DSSpy[randomDSSpy], client, _, _, _, 1.0);

	if(TF2_GetPlayerClass(client) == TFClass_Engineer)
		EmitSoundToAll(DSEngineer[randomDSEngineer], client, _, _, _, 1.0);
// #------------------CHANGE PLAYER MODELS------------#
	SetVariantString(disguiseMODEL[client]); 
	AcceptEntityInput(client, "SetCustomModel");
	SetVariantInt(1); 
	AcceptEntityInput(client, "SetCustomModelRotates");
// #------------------SET TAUNT CAM-------------------#
	SetVariantInt(1);
	AcceptEntityInput(client, "SetForcedTauntCam");
// #------------------HIDE WEAPONS--------------------#
	for(new i = 0; i < 3; i++) 
	{
		new weaponIndex = GetPlayerWeaponSlot(client, i);
		if(weaponIndex != -1) 
		{
			SetEntityRenderMode(weaponIndex, RENDER_TRANSCOLOR);
			SetEntityRenderColor(weaponIndex, _, _, _, 0);
		}
	}
// #-----------------REMOVE RAGDOLL-------------------#
	new hideBody = -1;
	while ((hideBody = FindEntityByClassname(hideBody, "tf_ragdoll")) != -1) 
	{
		new iOwner = GetEntProp(hideBody, Prop_Send, "m_iPlayerIndex");
		if(iOwner == client) 
		{
			AcceptEntityInput(hideBody, "Kill");
		}
	}
// #-----------------REMOVE MISC ITENS----------------#
	new removeHat = -1;
	while ((removeHat = FindEntityByClassname(removeHat, "tf_wearable")) != -1) 
	{
		new i = GetEntPropEnt(removeHat, Prop_Send, "m_hOwnerEntity");
		if(i == client) 
		{
			SetEntityRenderMode(removeHat, RENDER_TRANSCOLOR);
			SetEntityRenderColor(removeHat, _, _, _, 0);
		}
	}	
	new removeCan = -1;
	while((removeCan = FindEntityByClassname(removeCan, "tf_powerup_bottle")) != -1) 
	{
		new i = GetEntPropEnt(removeCan, Prop_Send, "m_hOwnerEntity");
		if(i == client) 
		{
			SetEntityRenderMode(removeCan, RENDER_TRANSCOLOR);
			SetEntityRenderColor(removeCan, _, _, _, 0);
		}
	}
//  #----------------FREEZE PLAYER--------------------#
	if(WLKAllowed == 0)
		SetEntityMoveType(client, MOVETYPE_NONE);
}

Undisguise(client)
{
// #--------------------DISGUISED BOOL----------------#
	PHasDisguised[client] = false;
// #------------------FADE PLAYER SCREEN--------------#
	FadeScreen(client, 50, 50, 50, 255, 100, FADE_SCREEN_TYPE_IN);
// #----------------EMIT DISGUISE SOUND---------------#
	new randomUDSScout  = GetRandomInt(0, UDSCountScout -1);
	new randomUDSSniper  = GetRandomInt(0, UDSCountSniper  - 1);
	new randomUDSSoldier  = GetRandomInt(0, UDSCountSoldier  - 1);
	new randomUDSDemoMan  = GetRandomInt(0, UDSCountDemoMan  - 1);
	new randomUDSMedic  = GetRandomInt(0, UDSCountMedic  - 1);
	new randomUDSHeavy  = GetRandomInt(0, UDSCountHeavy  - 1);
	new randomUDSPyro  = GetRandomInt(0, UDSCountPyro  - 1);
	new randomUDSSpy  = GetRandomInt(0, UDSCountSpy  - 1);
	new randomUDSEngineer  = GetRandomInt(0, UDSCountEngineer  - 1);

	if(TF2_GetPlayerClass(client) == TFClass_Scout)
		EmitSoundToAll(UDSScout[randomUDSScout], client, _, _, _, 1.0);

	if(TF2_GetPlayerClass(client) == TFClass_Sniper)
		EmitSoundToAll(UDSSniper[randomUDSSniper], client, _, _, _, 1.0);

	if(TF2_GetPlayerClass(client) == TFClass_Soldier)
		EmitSoundToAll(UDSSoldier[randomUDSSoldier], client, _, _, _, 1.0);

	if(TF2_GetPlayerClass(client) == TFClass_DemoMan)
		EmitSoundToAll(UDSDemoMan[randomUDSDemoMan], client, _, _, _, 1.0);

	if(TF2_GetPlayerClass(client) == TFClass_Medic)
		EmitSoundToAll(UDSMedic[randomUDSMedic], client, _, _, _, 1.0);

	if(TF2_GetPlayerClass(client) == TFClass_Heavy)
		EmitSoundToAll(UDSHeavy[randomUDSHeavy], client, _, _, _, 1.0);

	if(TF2_GetPlayerClass(client) == TFClass_Pyro)
		EmitSoundToAll(UDSPyro[randomUDSPyro], client, _, _, _, 1.0);

	if(TF2_GetPlayerClass(client) == TFClass_Spy)
		EmitSoundToAll(UDSSpy[randomUDSSpy], client, _, _, _, 1.0);

	if(TF2_GetPlayerClass(client) == TFClass_Engineer)
		EmitSoundToAll(UDSEngineer[randomUDSEngineer], client, _, _, _, 1.0);
// #------------------CHANGE PLAYER MODELS------------#
	SetVariantString(""); 
	AcceptEntityInput(client, "SetCustomModel");
	SetVariantInt(0); 
	AcceptEntityInput(client, "SetCustomModelRotates");
// #------------------REMOVE TAUNT CAM-------------------#
	SetVariantInt(0); 
	AcceptEntityInput(client, "SetForcedTauntCam");
// #------------------SHOW WEAPONS--------------------#
	for(new i = 0; i < 3; i++) 
	{
		new weaponIndex = GetPlayerWeaponSlot(client, i);
		if(weaponIndex != -1) 
		{
			SetEntityRenderMode(weaponIndex, RENDER_NORMAL);
			SetEntityRenderColor(weaponIndex, 255, 255, 255, 255);
		}
	}
// #-----------------ADD MISC ITENS----------------#
	new addHat = -1;
	while ((addHat = FindEntityByClassname(addHat, "tf_wearable")) != -1) 
	{
		new i = GetEntPropEnt(addHat, Prop_Send, "m_hOwnerEntity");
		if(i == client) 
		{
			SetEntityRenderMode(addHat, RENDER_NORMAL);
			SetEntityRenderColor(addHat, 255, 255, 255, 255);
		}
	}

	new addCan = -1;
	while((addCan = FindEntityByClassname(addCan, "tf_powerup_bottle")) != -1) 
	{
		new i = GetEntPropEnt(addCan, Prop_Send, "m_hOwnerEntity");
		if(i == client) 
		{
			SetEntityRenderMode(addCan, RENDER_NORMAL);
			SetEntityRenderColor(addCan, _, _, _, 0);
		}
	}
//  #----------------UNFREEZE PLAYER--------------------#
	if(WLKAllowed == 0)
		SetEntityMoveType(client, MOVETYPE_WALK);
}

public Action:Listener_Voice(client, const String:command[], argc)
{
	if(IsValidClient(client))
	{
		if(lWnabled[client] == true)
			return Plugin_Handled;

		decl String:arguments[4];
		GetCmdArgString(arguments, sizeof(arguments));
		if (StrEqual(arguments, "0 0") && PHasDisguised[client] == true && CallLTime[client] == INVALID_HANDLE) 
		{
			if(PHasDisguised[client] == false)
				return Plugin_Continue;

			_CloseHandle(CallLTime[client]);
			CallLTime[client] = CreateTimer(LTime, clTime, client);
			lWnabled[client] = true;

			if(LMessages != 0)
				PrintToChat(client, "\x03[\x04SM: Disguise Expert\x03] \x01You can laugh again in %.0f secs...", LTime);

			// #-----------------EMIT LAUGH SOUND----------------#
			new randomLSScout  = GetRandomInt(0, LSCountScout -1);
			new randomLSSniper  = GetRandomInt(0, LSCountSniper  - 1);
			new randomLSSoldier  = GetRandomInt(0, LSCountSoldier  - 1);
			new randomLSDemoMan  = GetRandomInt(0, LSCountDemoMan  - 1);
			new randomLSMedic  = GetRandomInt(0, LSCountMedic  - 1);
			new randomLSHeavy  = GetRandomInt(0, LSCountHeavy  - 1);
			new randomLSPyro  = GetRandomInt(0, LSCountPyro  - 1);
			new randomLSSpy  = GetRandomInt(0, LSCountSpy  - 1);
			new randomLSEngineer  = GetRandomInt(0, LSCountEngineer  - 1);

			if(TF2_GetPlayerClass(client) == TFClass_Scout)
				EmitSoundToAll(LSScout[randomLSScout], client, _, _, _, 1.0);

			if(TF2_GetPlayerClass(client) == TFClass_Sniper)
				EmitSoundToAll(LSSniper[randomLSSniper], client, _, _, _, 1.0);

			if(TF2_GetPlayerClass(client) == TFClass_Soldier)
				EmitSoundToAll(LSSoldier[randomLSSoldier], client, _, _, _, 1.0);

			if(TF2_GetPlayerClass(client) == TFClass_DemoMan)
				EmitSoundToAll(LSDemoMan[randomLSDemoMan], client, _, _, _, 1.0);

			if(TF2_GetPlayerClass(client) == TFClass_Medic)
				EmitSoundToAll(LSMedic[randomLSMedic], client, _, _, _, 1.0);

			if(TF2_GetPlayerClass(client) == TFClass_Heavy)
				EmitSoundToAll(LSHeavy[randomLSHeavy], client, _, _, _, 1.0);

			if(TF2_GetPlayerClass(client) == TFClass_Pyro)
				EmitSoundToAll(LSPyro[randomLSPyro], client, _, _, _, 1.0);

			if(TF2_GetPlayerClass(client) == TFClass_Spy)
				EmitSoundToAll(LSSpy[randomLSSpy], client, _, _, _, 1.0);

			if(TF2_GetPlayerClass(client) == TFClass_Engineer)
				EmitSoundToAll(LSEngineer[randomLSEngineer], client, _, _, _, 1.0);

			return Plugin_Handled;
		} 
	}

	return Plugin_Continue;
}  

public Action:clTime(Handle:timer, any:client)
{
	CallLTime[client] = INVALID_HANDLE;

	if(PHasDisguised[client] == false)
	{
		lWnabled[client] = false;
		return Plugin_Stop;
	}

	if(LMessages != 0)
		PrintToChat(client, "\x03[\x04SM: Disguise Expert\x03] \x01You can laugh again now.");

	lWnabled[client] = false;

	return Plugin_Continue;
}

public Action:OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype, &weapon, Float:damageForce[3], Float:damagePosition[3])
{
	if(IsValidClient(attacker))
	{
		if(DEnabled == 0 || WPAllowed == 1)
			return Plugin_Continue;

		if(PHasDisguised[attacker] == true)
		{
			damage = 0.0;
			return Plugin_Changed;
		}
	}
	
	return Plugin_Continue;
}

stock FadeScreen(client, red, green, blue, alpha, duration, type) {
	new Handle:msg = StartMessageOne("Fade", client);
	BfWriteShort(msg, 255);
	BfWriteShort(msg, duration);
	BfWriteShort(msg, type);
	BfWriteByte(msg, red);
	BfWriteByte(msg, green);
	BfWriteByte(msg, blue);
	BfWriteByte(msg, alpha);
	EndMessage();
}

public IsValidClient(client) 
{ 
    if ( !( 1 <= client <= MaxClients ) || !IsClientInGame(client) ) 
        return false; 
     
    return true; 
}

stock _CloseHandle(&Handle:handle)
{
    if(handle != INVALID_HANDLE)
    {
        CloseHandle(handle);
        handle = INVALID_HANDLE;
    }
}

public IsClientAdmin(client) 
{
	if(StrEqual(admflag, "a"))
		if(GetAdminFlag(GetUserAdmin(client), Admin_Reservation))
			return true; 

	if(StrEqual(admflag, "b"))
		if(GetAdminFlag(GetUserAdmin(client), Admin_Generic))
			return true; 

	if(StrEqual(admflag, "c"))
		if(GetAdminFlag(GetUserAdmin(client), Admin_Kick))
			return true; 

	if(StrEqual(admflag, "d"))
		if(GetAdminFlag(GetUserAdmin(client), Admin_Ban))
			return true; 

	if(StrEqual(admflag, "e"))
		if(GetAdminFlag(GetUserAdmin(client), Admin_Unban))
			return true; 

	if(StrEqual(admflag, "f"))
		if(GetAdminFlag(GetUserAdmin(client), Admin_Slay))
			return true; 

	if(StrEqual(admflag, "g"))
		if(GetAdminFlag(GetUserAdmin(client), Admin_Changemap))
			return true; 

//	if(StrEqual(admflag, "h"))
//		if(GetAdminFlag(GetUserAdmin(client), Admin_Cvars)) (SM BUG? ADMINFLAG_CVAR DONT WORK)
//			return true; 

	if(StrEqual(admflag, "i"))
		if(GetAdminFlag(GetUserAdmin(client), Admin_Config))
			return true; 

	if(StrEqual(admflag, "j"))
		if(GetAdminFlag(GetUserAdmin(client), Admin_Chat))
			return true; 

	if(StrEqual(admflag, "k"))
		if(GetAdminFlag(GetUserAdmin(client), Admin_Vote))
			return true; 

	if(StrEqual(admflag, "l"))
		if(GetAdminFlag(GetUserAdmin(client), Admin_Password))
			return true; 

	if(StrEqual(admflag, "m"))
		if(GetAdminFlag(GetUserAdmin(client), Admin_RCON))
			return true; 

	if(StrEqual(admflag, "n"))
		if(GetAdminFlag(GetUserAdmin(client), Admin_Cheats))
			return true; 

	if(StrEqual(admflag, "o"))
		if(GetAdminFlag(GetUserAdmin(client), Admin_Custom1))
			return true; 

	if(StrEqual(admflag, "p"))
		if(GetAdminFlag(GetUserAdmin(client), Admin_Custom2))
			return true; 

	if(StrEqual(admflag, "q"))
		if(GetAdminFlag(GetUserAdmin(client), Admin_Custom3))
			return true; 

	if(StrEqual(admflag, "r"))
		if(GetAdminFlag(GetUserAdmin(client), Admin_Custom4))
			return true; 

	if(StrEqual(admflag, "s"))
		if(GetAdminFlag(GetUserAdmin(client), Admin_Custom5))
			return true; 

	if(StrEqual(admflag, "t"))
		if(GetAdminFlag(GetUserAdmin(client), Admin_Custom6))
			return true; 

	return false; 
}