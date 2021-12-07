// *************************************************************************
// afk_bot_stand_alone.sp
//
// Copyright (c) 2014-2015  El Diablo <diablo@war3evo.info>
//
//  afk_bot_stand_alone is free software: you may copy, redistribute
//  and/or modify it under the terms of the GNU General Public License as
//  published by the Free Software Foundation, either version 3 of the
//  License, or (at your option) any later version.
//
//  This file is distributed in the hope that it will be useful, but
//  WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
//  General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program.  If not, see <http://www.gnu.org/licenses/>.

//  War3Evo Community Forums: https://war3evo.info/forums/index.php

// Sourcemod Plugin Dev for Hire
// http://war3evo.info/plugin-development-team/

#define g_iPLUGIN_VERSION "1.21"

public Plugin:myinfo=
{
	name="AFK BOT Stand Alone Version",
	author="El Diablo",
	description="AFK BOT Me Plugin",
	version=g_iPLUGIN_VERSION,
};

//Since I use this in War3Evo's War3Source server,
//I kept this in here for compiling that.
#tryinclude <war3source_paused>

#include <tf2_stocks>
// You can comment out smlib and make the Total Requirements less,
// I'm just keeping it as is, to give credits to smlib for some of their
// code.
//#tryinclude <smlib>

//sdkhooks is used to allow the medic bot to auto uber thier targets on damage
#tryinclude <sdkhooks>
#tryinclude <DiabloStocks>
// You'll need my modified copy to have the afk_manager work along side
// this plugin.
#tryinclude <afk_manager>
#tryinclude <colors>
#if !defined _colors_included
#tryinclude <morecolors>
#endif

#if !defined _smlib_entities_included
/**
 * Gets the Classname of an entity.
 * This is like GetEdictClassname(), except it works for ALL
 * entities, not just edicts.
 *
 * @param entity			Entity index.
 * @param buffer			Return/Output buffer.
 * @param size				Max size of buffer.
 * @return
 */
stock Entity_GetClassName(entity, String:buffer[], size)
{
	GetEntPropString(entity, Prop_Data, "m_iClassname", buffer, size);

	if (buffer[0] == '\0') {
		return false;
	}

	return true;
}

/**
 * Checks if an entity matches a specific entity class.
 *
 * @param entity		Entity Index.
 * @param class			Classname String.
 * @return				True if the classname matches, false otherwise.
 */
stock bool:Entity_ClassNameMatches(entity, const String:className[], partialMatch=false)
{
	decl String:entity_className[64];
	Entity_GetClassName(entity, entity_className, sizeof(entity_className));

	if (partialMatch) {
		return (StrContains(entity_className, className) != -1);
	}

	return StrEqual(entity_className, className);
}
#endif

#if !defined _smlib_weapons_included
#define MAX_WEAPONS				48	// Max number of weapons available
/**
 * Checks whether the entity is a valid weapon or not.
 *
 * @param weapon		Weapon Entity.
 * @return				True if the entity is a valid weapon, false otherwise.
 */
stock Weapon_IsValid(weapon)
{
	if (!IsValidEdict(weapon)) {
		return false;
	}

	return Entity_ClassNameMatches(weapon, "weapon_", true);
}

#endif

#if !defined _smlib_client_included
/**
 * Gets the offset for a client's weapon list (m_hMyWeapons).
 * The offset will saved globally for optimization.
 *
 * @param client		Client Index.
 * @return				Weapon list offset or -1 on failure.
 */
stock Client_GetWeaponsOffset(client)
{
	static offset = -1;

	if (offset == -1) {
		offset = FindDataMapOffs(client, "m_hMyWeapons");
	}

	return offset;
}

/**
 * Gets the weapon of a client by the weapon's classname.
 *
 * @param client 		Client Index.
 * @param className		Classname of the weapon.
 * @return				Entity index on success or INVALID_ENT_REFERENCE.
 */
stock Client_GetWeapon(client, const String:className[])
{
	new offset = Client_GetWeaponsOffset(client) - 4;

	for (new i=0; i < MAX_WEAPONS; i++) {
		offset += 4;

		new weapon = GetEntDataEnt2(client, offset);

		if (!Weapon_IsValid(weapon)) {
			continue;
		}

		if (Entity_ClassNameMatches(weapon, className)) {
			return weapon;
		}
	}

	return INVALID_ENT_REFERENCE;
}


/**
 * Changes the active weapon the client is holding.
 * Note: No changing animation will be played !
 *
 * @param client		Client Index.
 * @param className		Weapon Classname.
 * @return				True on success, false on failure.
 */
stock bool:Client_ChangeWeapon(client, const String:className[])
{
	new weapon = Client_GetWeapon(client, className);

	if (weapon == INVALID_ENT_REFERENCE) {
		return false;
	}

	Client_SetActiveWeapon(client,weapon);

	return true;
}

/**
 * Changes the active/current weapon of a player by Index.
 * Note: No changing animation will be played !
 *
 * @param client		Client Index.
 * @param weapon		Index of a valid weapon.
 * @noreturn
 */
stock Client_SetActiveWeapon(client, weapon)
{
	SetEntPropEnt(client, Prop_Data, "m_hActiveWeapon", weapon);
	ChangeEdictState(client, FindDataMapOffs(client, "m_hActiveWeapon"));
}
#endif

#if !defined _diablostocks_included
#define LoopMaxClients(%1) for(new %1=1;%1<=MaxClients;++%1)
#define LoopIngameClients(%1) for(new %1=1;%1<=MaxClients;++%1)\
								if(IsClientInGame(%1))
#define LoopAlivePlayers(%1) for(new %1=1;%1<=MaxClients;++%1)\
								if(IsClientInGame(%1) && IsPlayerAlive(%1))
#define STRING(%1) %1, sizeof(%1)

/**
 * Prints Message to server and all chat
 * For debugging prints
 */
stock DP(const String:szMessage[], any:...)
{

	decl String:szBuffer[1000];

	VFormat(szBuffer, sizeof(szBuffer), szMessage, 2);
	PrintToServer("[DebugP %d] %s",RoundFloat(GetGameTime())%100, szBuffer);
	PrintToChatAll("[DebugP %d] %s",RoundFloat(GetGameTime())%100, szBuffer);

}

stock bool:ValidPlayer(client,bool:check_alive=false,bool:alivecheckbyhealth=false) {
	if(client>0 && client<=MaxClients && IsClientConnected(client) && IsClientInGame(client))
	{
		if(check_alive && !IsPlayerAlive(client))
		{
			return false;
		}
		if(alivecheckbyhealth&&GetClientHealth(client)<1) {
			return false;
		}
		return true;
	}
	return false;
}

stock Float:TF2_GetClassSpeed(TFClassType:class)
{
		switch (class)
		{
				case TFClass_Scout:     return 400.0;
				case TFClass_Soldier:   return 240.0;
				case TFClass_DemoMan:   return 280.0;
				case TFClass_Medic:     return 320.0;
				case TFClass_Pyro:      return 300.0;
				case TFClass_Spy:       return 300.0;
				case TFClass_Engineer:  return 300.0;
				case TFClass_Sniper:    return 300.0;
				case TFClass_Heavy:     return 230.0;
		}
		return 0.0;
}
stock Float:TF_GetUberLevel(client)
{
	new index = GetPlayerWeaponSlot(client, 1);
	if (index > 0)
		return GetEntPropFloat(index, Prop_Send, "m_flChargeLevel")*100.0;
	else
		return 0.0;
}
stock TF2_GetCurrentWeaponClass(client, String:name[], maxlength)
{
	if( client > 0 )
	{
		new index = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
		if (index > 0)
			GetEntityNetClass(index, name, maxlength);
	}
}
stock TF2_GetHealingTarget(client)
{
	new String:classname[64];
	TF2_GetCurrentWeaponClass(client, classname, sizeof(classname));

	if( StrEqual(classname, "CWeaponMedigun") )
	{
		new index = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
		if( GetEntProp(index, Prop_Send, "m_bHealing") == 1 )
		{
			return GetEntPropEnt(index, Prop_Send, "m_hHealingTarget");
		}
	}

	return -1;
}
#endif

enum PlayerDataInfo
{
	bool:AFK,
	bool:AFK_uber,
	ControllerID,
	bool:PlayerSpawned,
	bool:HasAFKPlayer,
	Float:TimeSpawned,
	bool:Teleported
}

float AllPos[MAXPLAYERS + 1][3];

float angleOffset[MAXPLAYERS+1];

float PlayerSpawned_loc[MAXPLAYERS + 1][3];

int g_Player[MAXPLAYERS + 1][PlayerDataInfo];

Handle g_ConVar_AllowMovement;
bool gB_ConVar_AllowMovement=true;

Handle g_ConVar_AllowRespawn;
bool gB_ConVar_AllowRespawnDeadPlayer=true;

Handle g_ConVar_Maximum;
int gI_ConVar_Maximum=2;

Handle g_ConVar_AllowNonAdminsAfk;
bool gB_ConVar_AllowNonAdminsAfk=true;

Handle g_ConVar_Kick_Round_End;
Handle g_ConVar_Kick_Round_Start;

bool gB_ConVar_Kick_Round_Start = false;
bool gB_ConVar_Kick_Round_End = false;

Handle g_ConVar_Kick_Protection;
char Kick_Protection_Flag_String[32];

Handle g_ConVar_Kick_Protection_Enable;
bool gB_ConVar_Kick_Protection_Enable = true;

Handle g_ConVar_Back_Menu;
bool gB_ConVar_Back_Menu = false;


public OnPluginStart()
{
	CreateConVar("eldiablo_afkbot",g_iPLUGIN_VERSION,"War3evo AFK BOT",FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	RegAdminCmd("afkon",afk_on,ADMFLAG_KICK);
	RegAdminCmd("afkoff",afk_off,ADMFLAG_KICK);

	HookEvent("player_spawn", Player_Spawn);
	HookEvent("player_death", Player_Death);
	HookEvent("object_deflected", event_deflect, EventHookMode_Pre);

	// applies sdkhooks to players (experts use only)
	RegAdminCmd("reloadafkplayers",Cmd_reloadafkplayers,ADMFLAG_ROOT);

	RegConsoleCmd("sm_afk", Cmd_Player_Request_AFK);
	RegConsoleCmd("sm_back", Cmd_afkoff);
	RegConsoleCmd("sm_afkoff", Cmd_afkoff);

	RegConsoleCmd("voicemenu", Cmd_VoiceMenu);

	RegAdminCmd("forceclass", Cmd_forceclass,ADMFLAG_ROOT);
	RegAdminCmd("forceafkon",Cmd_forceafkon,ADMFLAG_ROOT);
	RegAdminCmd("forceafkoff",Cmd_forceafkoff,ADMFLAG_ROOT);
	RegAdminCmd("kickafkplayers",Cmd_kickafkplayers,ADMFLAG_KICK);


	HookEvent("teamplay_round_start", HookRoundStart, EventHookMode_Post);
	HookEvent("teamplay_waiting_begins", HookRoundStart, EventHookMode_Post);

	HookEvent("teamplay_round_win", HookRoundEnd, EventHookMode_Post);
	HookEvent("teamplay_waiting_ends", HookRoundEnd, EventHookMode_Post);
	HookEvent("teamplay_round_stalemate", HookRoundEnd, EventHookMode_Post);

	g_ConVar_Back_Menu=CreateConVar("afkbot_back_menu","0","1 - enable, 0 - disable\nRequire players to use a menu to get out of afk medic bot.");
	HookConVarChange(g_ConVar_Back_Menu, ConVarChanged);


	g_ConVar_AllowNonAdminsAfk=CreateConVar("afkbot_Allow_Non_Admins_AFK_Command","1","0 - disable, 1 - enable.\nIf enabled, Non Admins will be allowed to type !afk to go afk player medic bot.");
	HookConVarChange(g_ConVar_AllowNonAdminsAfk, ConVarChanged);

	// Does not work yet
	g_ConVar_AllowMovement=CreateConVar("afkbot_allow_movement","1","0 - disable, 1 - enable.\nIf enabled, player will be allowed to use movement buttons to control afkbot.");
	HookConVarChange(g_ConVar_AllowMovement, ConVarChanged);

	g_ConVar_Maximum=CreateConVar("afkbot_maximum","2","The maximum allowed per team of afk bots.");
	HookConVarChange(g_ConVar_Maximum, ConVarChanged);

	g_ConVar_Kick_Protection_Enable=CreateConVar("afkbot_kick_Protection_Enable","1","Kick protection.  1 - enable, 0 - disable");
	HookConVarChange(g_ConVar_Kick_Protection_Enable, ConVarChanged);

	g_ConVar_Kick_Protection=CreateConVar("afkbot_kick_Protection_Admin_Flag","a","The admin flag a-z for kick protection.");
	HookConVarChange(g_ConVar_Kick_Protection, ConVarChanged);

	g_ConVar_Kick_Round_End=CreateConVar("afkbot_kick_afk_players_round_start","1","Kick afk bots when round starts.");
	HookConVarChange(g_ConVar_Kick_Round_End, ConVarChanged);

	g_ConVar_Kick_Round_Start=CreateConVar("afkbot_kick_afk_players_round_end","1","Kick afk bots when round ends.");
	HookConVarChange(g_ConVar_Kick_Round_Start, ConVarChanged);

	g_ConVar_AllowRespawn=CreateConVar("afkbot_allow_respawn_dead_players","1","0 - disable, 1 - enable.\nIf enabled, plugin will respawn dead players to be afkbot.");
	HookConVarChange(g_ConVar_AllowRespawn, ConVarChanged);
}

public OnConfigsExecuted()
{
	gB_ConVar_AllowMovement = GetConVarBool(g_ConVar_AllowMovement);
	gB_ConVar_AllowRespawnDeadPlayer = GetConVarBool(g_ConVar_AllowRespawn);
	gI_ConVar_Maximum = GetConVarInt(g_ConVar_Maximum);
	gB_ConVar_AllowNonAdminsAfk = GetConVarBool(g_ConVar_AllowNonAdminsAfk);
	gB_ConVar_Kick_Round_Start = GetConVarBool(g_ConVar_Kick_Round_Start);
	gB_ConVar_Kick_Round_End = GetConVarBool(g_ConVar_Kick_Round_End);
	gB_ConVar_Back_Menu = GetConVarBool(g_ConVar_Back_Menu);

	char szFlag[32];
	GetConVarString(g_ConVar_Kick_Protection, STRING(szFlag));
	strcopy(STRING(Kick_Protection_Flag_String),szFlag);

	gB_ConVar_Kick_Protection_Enable = GetConVarBool(g_ConVar_Kick_Protection_Enable);
}

public HookRoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(gB_ConVar_Kick_Round_Start)
	{
		Cmd_kickafkplayers(-1,0);
	}
}

public HookRoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(gB_ConVar_Kick_Round_End)
	{
		Cmd_kickafkplayers(-1,0);
	}
}

public ConVarChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	if(cvar == g_ConVar_AllowMovement)
	{
		gB_ConVar_AllowMovement = StringToInt(newVal)? true:false;
	}
	else if(cvar == g_ConVar_AllowRespawn)
	{
		gB_ConVar_AllowRespawnDeadPlayer = StringToInt(newVal)? true:false;
	}
	else if(cvar == g_ConVar_Maximum)
	{
		gI_ConVar_Maximum = StringToInt(newVal);
	}
	else if(cvar == g_ConVar_AllowNonAdminsAfk)
	{
		gB_ConVar_AllowNonAdminsAfk = StringToInt(newVal)? true:false;
	}
	else if(cvar == g_ConVar_Kick_Round_Start)
	{
		gB_ConVar_Kick_Round_Start = StringToInt(newVal)? true:false;
	}
	else if(cvar == g_ConVar_Kick_Round_End)
	{
		gB_ConVar_Kick_Round_End = StringToInt(newVal)? true:false;
	}
	else if(cvar == g_ConVar_Kick_Protection)
	{
		strcopy(STRING(Kick_Protection_Flag_String),newVal);
	}
	else if(cvar == g_ConVar_Kick_Protection_Enable)
	{
		gB_ConVar_Kick_Protection_Enable = StringToInt(newVal)? true:false;
	}
	else if(cvar == g_ConVar_Back_Menu)
	{
		gB_ConVar_Back_Menu = StringToInt(newVal)? true:false;
	}
}

public OnPluginEnd()
{
#if defined _sdkhooks_included
	LoopIngameClients(target)
	{
		SDKUnhook(target,SDKHook_OnTakeDamage,SDK_Forwarded_OnTakeDamage);
	}
#endif
}

public Action:Cmd_reloadafkplayers(client, args)
{
#if defined _sdkhooks_included
	LoopIngameClients(target)
	{
		SDKHook(target,SDKHook_OnTakeDamage, SDK_Forwarded_OnTakeDamage);
	}
	ReplyToCommand(client,"SDKHook_OnTakeDamage");
#endif
}

public Action:Cmd_afkoff(client, args)
{
	if(ValidPlayer(client))
	{
		if(!gB_ConVar_Back_Menu)
		{
			afk_off(client,0);
		}
		else
		{
			PrintToChat(client,"In order to prevent automated !back from players,\nyou must answer the question in the menu.");
			ShowQuestionMenu(client);
		}
	}
	return Plugin_Handled;
}

public ShowQuestionMenu(client)
{
	Handle MenuHandle = CreateMenu(DonatorMenu_Select);
	SetMenuExitButton(MenuHandle,true);

	new String:CurrentMapName[256];
	GetCurrentMap(CurrentMapName, sizeof(CurrentMapName));

	SetMenuTitle(MenuHandle,"[AFK] READ CAREFULLY (Changes Randomly)\nChoose One:");

	int randnum = GetRandomInt(0, 50);

	if(randnum<10)
	{
		AddMenuItem(MenuHandle,"removeit","Get me out of AFK!",ITEMDRAW_DEFAULT);
		AddMenuItem(MenuHandle,"none","No Answer",ITEMDRAW_DEFAULT);
		AddMenuItem(MenuHandle,"none","No Answer",ITEMDRAW_DEFAULT);
	}
	else if(randnum>=10 && randnum<20)
	{
		AddMenuItem(MenuHandle,"none","No Answer",ITEMDRAW_DEFAULT);
		AddMenuItem(MenuHandle,"removeit","Get me out of AFK!",ITEMDRAW_DEFAULT);
		AddMenuItem(MenuHandle,"none","No Answer",ITEMDRAW_DEFAULT);
	}
	else if(randnum>=20 && randnum<30)
	{
		AddMenuItem(MenuHandle,"none","No Answer",ITEMDRAW_DEFAULT);
		AddMenuItem(MenuHandle,"none","No Answer",ITEMDRAW_DEFAULT);
		AddMenuItem(MenuHandle,"removeit","Get me out of AFK!",ITEMDRAW_DEFAULT);
	}
	else if(randnum>=30 && randnum<40)
	{
		AddMenuItem(MenuHandle,"none","No Answer",ITEMDRAW_DEFAULT);
		AddMenuItem(MenuHandle,"none","No Answer",ITEMDRAW_DEFAULT);
		AddMenuItem(MenuHandle,"none","No Answer",ITEMDRAW_DEFAULT);
		AddMenuItem(MenuHandle,"removeit","Get me out of AFK!",ITEMDRAW_DEFAULT);
	}
	else if(randnum>=40 && randnum<51)
	{
		AddMenuItem(MenuHandle,"none","No Answer",ITEMDRAW_DEFAULT);
		AddMenuItem(MenuHandle,"none","No Answer",ITEMDRAW_DEFAULT);
		AddMenuItem(MenuHandle,"none","No Answer",ITEMDRAW_DEFAULT);
		AddMenuItem(MenuHandle,"none","No Answer",ITEMDRAW_DEFAULT);
		AddMenuItem(MenuHandle,"removeit","Get me out of AFK!",ITEMDRAW_DEFAULT);
	}
	DisplayMenu(MenuHandle,client,20);
}

public DonatorMenu_Select(Handle:menu,MenuAction:action,client,selection)
{
	if(action==MenuAction_Select)
	{
		char SelectionInfo[32];
		char SelectionDispText[256];
		new SelectionStyle;
		GetMenuItem(menu,selection,SelectionInfo,sizeof(SelectionInfo),SelectionStyle, SelectionDispText,sizeof(SelectionDispText));
		//new target=StringToInt(SelectionInfo);

		if(StrEqual(SelectionInfo,"removeit"))
		{
			afk_off(client,0);
		}
	}
	if(action==MenuAction_End)
	{
		CloseHandle(menu);
	}
}

public Action:Cmd_forceafkoff(client, args)
{
	decl String:command[32];
	GetCmdArg(1,command,sizeof(command));
	//ReplyToCommand(client,"command %s",command);
	int newint = StringToInt(command);
	int target = GetClientOfUserId(newint);
	if(ValidPlayer(target))
	{
		afk_off(target,0);
	}
	return Plugin_Handled;
}

public Action:Cmd_kickafkplayers(client, args)
{
	decl String:sTargetName[32];
	int countplayers = 0;
	LoopIngameClients(target)
	{
		if(g_Player[target][AFK])
		{
			if(gB_ConVar_Kick_Protection_Enable && GetUserFlagBits(target) & ReadFlagString(Kick_Protection_Flag_String))
			{
				if(client > -1)
				{
					GetClientName(target,STRING(sTargetName));
					ReplyToCommand(client,"%s is kick protected.",sTargetName);
				}
				continue;
			}

			ClearVariables(target);
			KickClient(target, "You was kicked for being AFK.");
			GetClientName(target,STRING(sTargetName));
			if(client > -1)
			{
				ReplyToCommand(client,"%s was kicked.",sTargetName);
			}
			countplayers++;
		}
	}
	if(client > -1)
	{
		if(countplayers<=0)
		{
			ReplyToCommand(client,"Nobody is marked afk medic bot to kick.");
		}
	}
	return Plugin_Handled;
}

public Action:Cmd_forceafkon(client, args)
{
	decl String:command[32];
	GetCmdArg(1,command,sizeof(command));
	ReplyToCommand(client,"command %s",command);
	int newint = StringToInt(command);
	int target = GetClientOfUserId(newint);
	if(ValidPlayer(target))
	{
		afk_on(target,0);
	}
	return Plugin_Handled;
}

public Action:Cmd_forceclass(client, args)
{
	decl String:command[32];
	GetCmdArg(1,command,sizeof(command));
	ReplyToCommand(client,"command %s",command);
	int newint = StringToInt(command);
	int target = GetClientOfUserId(newint);
	if(ValidPlayer(target))
	{
		TF2_SetPlayerClass(target, TFClass_Medic);
		TF2_RespawnPlayer(target);
	}
	return Plugin_Handled;
}

public OnMapStart()
{
	CreateTimer(0.5, doTimer, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
#if defined _afk_manager_included
	CreateTimer(5.0, TellYourInAFKMODE,_,TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
#endif
}

#if defined _afk_manager_included
public Action:TellYourInAFKMODE(Handle:timer,any:userid)
{
	for(int client=1;client<=MaxClients;client++)
	{
		if(g_Player[client][AFK] && ValidPlayer(client))
		{
#if defined _colors_included
			CPrintToChat(client,"{olive}[{green}AFK Manager{olive}] {default}You are set AFK.\nType '{green}!back{default}' in chat to get out of it.");
#else
			PrintToChat(client,"[AFK Manager] You are set AFK.\nType '!back' in chat to get out of it.");
#endif
		}
	}
}
#endif

stock ClearVariables(client,bool:AllVariables=true)
{
	if(AllVariables)
	{
		g_Player[client][AFK]=false;
	}
	g_Player[client][AFK_uber]=false;
	new controllerid = g_Player[client][ControllerID];
	g_Player[client][ControllerID]=0;
	g_Player[client][PlayerSpawned]=false;
	PlayerSpawned_loc[client][0]=0.0;
	PlayerSpawned_loc[client][1]=0.0;
	PlayerSpawned_loc[client][2]=0.0;
	g_Player[controllerid][HasAFKPlayer]=false;
}

stock CountAFKPlayers(client)
{
	int i=0;
	int clientteam;
	if(ValidPlayer(client))
	{
		clientteam = GetClientTeam(client);
	}
	LoopMaxClients(target)
	{
		if(g_Player[target][AFK])
		{
			if(ValidPlayer(target) && GetClientTeam(target)==clientteam)
			{
				i++;
			}
		}
	}
	return i;
}

public Action:afk_on(client,args)
{
	if(ValidPlayer(client))
	{
		g_Player[client][AFK]=true;
		g_Player[client][TimeSpawned]=GetGameTime();
		g_Player[client][PlayerSpawned]=true;

		decl Float:NewLocation[3];
		GetClientAbsOrigin(client, NewLocation);
		PlayerSpawned_loc[client]=NewLocation;
		ReplyToCommand(client,"You are now set away.");
	}
}

public Action:afk_off(client,args)
{
	if(ValidPlayer(client))
	{
		ReplyToCommand(client,"You are now set back.");
		SetEntDataFloat(client,FindSendPropOffs("CTFPlayer","m_flMaxspeed"),TF2_GetClassSpeed(TF2_GetPlayerClass(client)),true);
	}

	ClearVariables(client);
}


public Action:Player_Spawn(Handle:event, String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));

	if(ValidPlayer(client))
	{
		if(g_Player[client][AFK])
		{
			// dont clear being afk
			ClearVariables(client,false);

			g_Player[client][TimeSpawned]=GetGameTime();
			g_Player[client][PlayerSpawned]=true;

			decl Float:NewLocation[3];
			GetClientAbsOrigin(client, NewLocation);
			PlayerSpawned_loc[client]=NewLocation;
		}
		else
		{
			CheckPlayer(client);
		}
	}
	return Plugin_Continue;
}

public Action:Player_Death(Handle:event, String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));

	if(ValidPlayer(client))
	{
		if(g_Player[client][AFK])
		{
			// dont clear being afk
			ClearVariables(client,false);
		}
		LoopIngameClients(inum)
		{
			if(g_Player[inum][ControllerID]==client)
			{
				ClearVariables(inum,false);
				if(ValidPlayer(inum,true))
				{
					g_Player[inum][TimeSpawned]=GetGameTime();
					g_Player[inum][PlayerSpawned]=true;

					decl Float:NewLocation[3];
					GetClientAbsOrigin(inum, NewLocation);
					PlayerSpawned_loc[inum]=NewLocation;
				}
				break;
			}
		}
	}
	return Plugin_Continue;
}

new skip=0;
//new igameframe;
public OnGameFrame()
{
	if(skip==0)
	{
		LoopAlivePlayers(igameframe)
		{
			GetClientAbsOrigin(igameframe,AllPos[igameframe]);
		}
		skip=4;
	}
	skip--;

	if(gB_ConVar_AllowMovement) return;

	/* possible way to stop movement while using afk bot.. doesn't work yet
	LoopAlivePlayers(client)
	{
		if(g_Player[client][AFK])
		{
			SetEntityMoveType(client,MOVETYPE_NONE);
		}
	}*/
}


new los_target;
new ignoreClient;
BOT_LOS(client,target)
{
	los_target=target;
	if(ValidPlayer(client,true)&&ValidPlayer(target,true))
	{
		new Float:PlayerEyePos[3];
		new Float:OtherPlayerPos[3];
		GetClientEyePosition(client,PlayerEyePos); //GetClientEyePosition(
		GetClientEyePosition(target,OtherPlayerPos); //GetClientAbsPosition
		ignoreClient=client;
		TR_TraceRayFilter(PlayerEyePos,OtherPlayerPos,MASK_ALL,RayType_EndPoint,LOSFilter);
		if(TR_DidHit())
		{
			new entity=TR_GetEntityIndex();
			if(entity==target)
			{
				return true;
			}
		}
	}
	return false;
}


public bool:LOSFilter(entity,mask)
{
	return !(entity==ignoreClient || (ValidPlayer(entity,true)&&entity!=los_target));
}

//MOVE FORWARD
Float:moveForward(Float:vel[3],Float:MaxSpeed){
	//move forward. buttons |=IN_FORWARD does nothing.
	vel[0] = MaxSpeed;
	return vel;
}
Float:moveBackwards(Float:vel[3],Float:MaxSpeed){
	//move forward. buttons |=IN_FORWARD does nothing.
	vel[0] = -MaxSpeed;
	return vel;
}


public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{														// controlled[client] ---> any number above 0 means true, if you look at controlled[client] number
														//

#if defined _War3Source_Paused_included
	if(W3Paused()) return Plugin_Continue;
#endif

	if(g_Player[client][AFK_uber])
	{
		buttons|=IN_ATTACK2;
		g_Player[client][AFK_uber]=false;
		//return Plugin_Continue;
	}
	if(g_Player[client][AFK])
	{
		new controllerid = g_Player[client][ControllerID];
		if(!ValidPlayer(controllerid,true) && !ValidPlayer(client,true))
		{
			return Plugin_Continue;
		}

		if(TF2_GetPlayerClass(client)!=TFClass_Medic)
		{
			ClearVariables(client,false);
			ForcePlayerSuicide(client);
			TF2_SetPlayerClass(client, TFClass_Medic);
			TF2_RespawnPlayer(client);
			afk_on(client,0);
			return Plugin_Continue;
		}

		// Double check ValidPlayer Just in Case :/
		if(ValidPlayer(controllerid,true) &&
		(TF2_GetPlayerClass(controllerid)==TFClass_Medic
		||TF2_GetPlayerClass(controllerid)==TFClass_Spy)
		)
		{
			// dont clear being afk
			ClearVariables(client,false);

			//CreateTimer(0.5, SpawnLocationTimer, client);
			g_Player[client][TimeSpawned]=GetGameTime();
			g_Player[client][PlayerSpawned]=true;

			decl Float:NewLocation[3];
			GetClientAbsOrigin(client, NewLocation);
			PlayerSpawned_loc[client]=NewLocation;

			return Plugin_Continue;
		}

		// uncomment below if you don't want afk bots to follow players when they
		// are no longer on the ground / or flying.
		//if (!(GetEntityFlags(controllerid) & FL_ONGROUND) || (GetEntityFlags(g_Player[client][ControllerID]) & FL_FLY))
		//{
			//vel[0] = 0.0;

			//return Plugin_Continue;
		//}

		new Float:location_check[3];
		GetClientAbsOrigin( client, location_check );

		new Float:chainDistance;
		chainDistance = GetVectorDistance(location_check,AllPos[controllerid]);

		//Look at Master.//////////////////////////////////////////
		if(ValidPlayer(controllerid,true)){
			new Float:angleVecs[3];
			new Float:angleToMaster[3];

			SubtractVectors(location_check,AllPos[controllerid],angleVecs);
			GetVectorAngles(angleVecs,angleToMaster);

			angleToMaster[1]+=angleOffset[client];
			if(angleToMaster[1] >0){
				angleToMaster[1]= -(180-angleToMaster[1]);
			}else{
				angleToMaster[1]= (180+angleToMaster[1]);
			}
			if(angleToMaster[0] >180){
				angleToMaster[0]-=360;
			}
			angleToMaster[0]=-angleToMaster[0];
			angles=angleToMaster;
		}
		else
		{
			// dont clear being afk
			ClearVariables(client,false);

			//CreateTimer(0.5, SpawnLocationTimer, client);
			g_Player[client][TimeSpawned]=GetGameTime();
			g_Player[client][PlayerSpawned]=true;

			decl Float:NewLocation[3];
			GetClientAbsOrigin(client, NewLocation);
			PlayerSpawned_loc[client]=NewLocation;
		}

		TeleportEntity(client,NULL_VECTOR,angles,NULL_VECTOR);
		////////////////////////////////////////////////////////////
		if(ValidPlayer(controllerid,true)){
			new Float:ControllerSpeed = GetEntDataFloat(controllerid,FindSendPropOffs("CTFPlayer","m_flMaxspeed"));
			ControllerSpeed*=2.0;
			SetEntDataFloat(client,FindSendPropOffs("CTFPlayer","m_flMaxspeed"),ControllerSpeed,true);

			if(chainDistance >700.0){
				// remove master if too far away or not in line of sight
				// to prevent problems with getting stuck inside the warden
				if(!BOT_LOS(client,controllerid))
				{
					// dont clear being afk
					ClearVariables(client,false);

					g_Player[client][TimeSpawned]=GetGameTime();
					g_Player[client][PlayerSpawned]=true;

					decl Float:NewLocation[3];
					GetClientAbsOrigin(client, NewLocation);
					PlayerSpawned_loc[client]=NewLocation;

					return Plugin_Continue;
				}
				chainDistance*=4;
			}
			else if(chainDistance >250.0){
				chainDistance*=3;
			}
			else if(chainDistance >150.0){
				chainDistance*=2;
			}
			if(chainDistance >=150.0){
				//If can't see, attempt to move around to get there.
				if(!BOT_LOS(client,controllerid) && !BOT_LOS(controllerid,client)){
					if(angleOffset[client]<180.0 && angleOffset[client]>=0.0){
						if(IsWallLookingAtWall(client))
						{
							angleOffset[client]+=3.0;
						}
						else
						{
							angleOffset[client]+=0.2;
						}
						vel[1] = chainDistance;
					}else{
						if(angleOffset[client]==180.0){
							if(IsWallLookingAtWall(client))
							{
								angleOffset[client]-=3.0;
							}
							else
							{
								angleOffset[client]=-0.2;
							}
							vel[1] = -chainDistance;
						}
						angleOffset[client]-=1.0;
					}
				}else{
					angleOffset[client]=0.0;
				}
				//Close but getting too far; Run.
				vel = moveForward(vel,chainDistance);
			}
			if(chainDistance >=50.0){
				if(GetClientButtons(controllerid) & IN_JUMP){
					buttons |= IN_JUMP;
				}
			}
			if(chainDistance <125.0){
				vel = moveBackwards(vel,chainDistance);
				angleOffset[client]=0.0;
			}
		}

		if (TF2_GetPlayerClass(client)==TFClass_Medic && GetVectorDistance( AllPos[controllerid], location_check )>=125.0)
		{
			new String:tweapon[256];
			GetClientWeapon(client, tweapon, sizeof(tweapon));
			if (strcmp(tweapon,"tf_weapon_medigun") != 0)
			{
				Client_ChangeWeapon(client,"tf_weapon_medigun");
			}
			buttons |= IN_ATTACK;
		}
		/*
		if(!gB_ConVar_AllowMovement)
		{
			// remove movement commands
			if(buttons & IN_FORWARD) buttons &= ~IN_FORWARD;
			if(buttons & IN_BACK) buttons &= ~IN_BACK;
			if(buttons & IN_LEFT) buttons &= ~IN_LEFT;
			if(buttons & IN_RIGHT) buttons &= ~IN_RIGHT;
			if(buttons & IN_MOVELEFT) buttons &= ~IN_MOVELEFT;
			if(buttons & IN_MOVERIGHT) buttons &= ~IN_MOVERIGHT;
			if(buttons & IN_DUCK) buttons &= ~IN_DUCK;
		}*/
	}
	return Plugin_Continue;
}

#if defined _sdkhooks_included
public OnClientPutInServer(client)
{
	SDKHook(client,SDKHook_OnTakeDamage, SDK_Forwarded_OnTakeDamage);
}

public OnClientDisconnect(client)
{
	ClearVariables(client);
	SDKUnhook(client,SDKHook_OnTakeDamage,SDK_Forwarded_OnTakeDamage);
}


new VictimCheck=-666;
new AttackerCheck=-666;
new InflictorCheck=-666;
new Float:DamageCheck=-666.6;
new DamageTypeCheck=-666;
new WeaponCheck=-666;
new Float:damageForceCheck[3];
new Float:damagePositionCheck[3];
new damagecustomCheck = -666;

public Action:SDK_Forwarded_OnTakeDamage(victim,&attacker,&inflictor,&Float:damage,&damagetype,&weapon,Float:damageForce[3], Float:damagePosition[3], damagecustom)
{
	// prevent doubles
	if(VictimCheck==victim
	&&AttackerCheck==attacker
	&&InflictorCheck==inflictor
	&&DamageCheck==damage
	&&DamageTypeCheck==damagetype
	&&WeaponCheck==weapon
	&&damageForceCheck[0]==damageForce[0]
	&&damageForceCheck[1]==damageForce[1]
	&&damageForceCheck[2]==damageForce[2]
	&&damagePositionCheck[0]==damagePosition[0]
	&&damagePositionCheck[1]==damagePosition[1]
	&&damagePositionCheck[2]==damagePosition[2]
	&&damagecustomCheck==damagecustom
	)
	{
		return Plugin_Continue;
	}

	if(ValidPlayer(victim,true))
	{
		// DO CHECKING HERE

		if (g_Player[victim][AFK]
		&& TF2_GetPlayerClass(victim)==TFClass_Medic
		&& TF_GetUberLevel(victim)>=100.00)
		// Uncomment here if you want medics to respawn based on health
		//&& ((RoundToFloor(damage) + 60) >= GetClientHealth(victim)))
		{
			g_Player[victim][AFK_uber]=true;
			return Plugin_Continue;
		}
		for(new healer=1; healer <= MaxClients; healer++)
		{
			if(ValidPlayer(healer, true) && g_Player[healer][AFK] && (TF2_GetPlayerClass(healer) == TFClass_Medic))
			{
				new HealVictim = TF2_GetHealingTarget(healer);
				if (HealVictim == victim)
				{
					// Uncomment here if you want medics to respawn based on health
					//if (TF_GetUberLevel(healer)>=100.00 && (RoundToFloor(damage) + 60 >= GetClientHealth(victim)))
					if (TF_GetUberLevel(healer)>=100.00)
					{
						g_Player[healer][AFK_uber]=true;
					}
				}
			}
		}

		VictimCheck=victim;
		AttackerCheck=attacker;
		InflictorCheck=inflictor;
		DamageCheck=damage;
		DamageTypeCheck=damagetype;
		WeaponCheck=weapon;
		damageForceCheck[0]=damageForce[0];
		damageForceCheck[1]=damageForce[1];
		damageForceCheck[2]=damageForce[2];
		damagePositionCheck[0]=damagePosition[0];
		damagePositionCheck[1]=damagePosition[1];
		damagePositionCheck[2]=damagePosition[2];
		damagecustomCheck=damagecustom;
	}

	return Plugin_Changed;
}

#endif

stock bool:CheckPlayer(client)
{
	new Float:location_check2[3];
	LoopAlivePlayers(inum)
	{
		if(g_Player[inum][AFK] && g_Player[inum][PlayerSpawned])
		{
			if(g_Player[inum][TimeSpawned]<(GetGameTime()-60.0))
			{
				ForcePlayerSuicide(inum);
				return false;
			}

			if(client!=inum &&
			!g_Player[client][HasAFKPlayer]
			&& !g_Player[client][AFK])
			{
				GetClientAbsOrigin( client, location_check2);
				if(ValidPlayer(client,true)
				&& !(TF2_GetPlayerClass(client)==TFClass_Spy
				|| TF2_GetPlayerClass(client)==TFClass_Medic)
				&& GetClientTeam(client)==GetClientTeam(inum)
				&& (GetVectorDistance( AllPos[inum], location_check2 )<350.0 && GetVectorDistance( AllPos[inum], location_check2 )>10.0))
				{
					if(ValidPlayer(client,true))
					{
						g_Player[inum][PlayerSpawned]=false;

						g_Player[inum][ControllerID]=client;

						g_Player[client][HasAFKPlayer]=true;

						return true;
					}
				}
			}
		}
	}
	return false;
}

public Action:doTimer(Handle:thetimer)
{
	LoopAlivePlayers(client)
	{
		CheckPlayer(client);
	}
}

public Action:event_deflect(Handle:event, const String:name[], bool:dontBroadcast)
{
	new owner = GetClientOfUserId(GetEventInt(event, "ownerid"));
	new weaponid = GetEventInt(event, "weaponid");

	if (weaponid != 0) return Plugin_Continue;
	if(g_Player[owner][AFK])
	{
		// dont clear being afk
		ClearVariables(owner,false);

		g_Player[owner][TimeSpawned]=GetGameTime();
		g_Player[owner][PlayerSpawned]=true;

		decl Float:NewLocation[3];
		GetClientAbsOrigin(owner, NewLocation);
		PlayerSpawned_loc[owner]=NewLocation;
	}

	return Plugin_Continue;
}

#if defined _afk_manager_included
public Action:OnPlayerAFK(client)
{
	if(CountAFKPlayers(client)>=gI_ConVar_Maximum) return Plugin_Continue;

	if(ValidPlayer(client))
	{
		if(IsPlayerAlive(client))
		{
			ForcePlayerSuicide(client);
			TF2_SetPlayerClass(client, TFClass_Medic);
			TF2_RespawnPlayer(client);
			afk_on(client,0);
			// prevent sending to spec
			return Plugin_Stop;
		}
		else
		{
			if(gB_ConVar_AllowRespawnDeadPlayer)
			{
				TF2_SetPlayerClass(client, TFClass_Medic);
				TF2_RespawnPlayer(client);
				afk_on(client,0);
				// prevent sending to spec
				return Plugin_Stop;
			}
		}
	}
	return Plugin_Continue;
}
public Action:OnPlayerAFK_Kick(client)
{
	if(CountAFKPlayers(client)>=gI_ConVar_Maximum) return Plugin_Continue;

	if(ValidPlayer(client))
	{
		if(IsPlayerAlive(client))
		{
			ForcePlayerSuicide(client);
			TF2_SetPlayerClass(client, TFClass_Medic);
			TF2_RespawnPlayer(client);
			afk_on(client,0);
			// prevent sending to spec
			return Plugin_Stop;
		}
		else
		{
			if(gB_ConVar_AllowRespawnDeadPlayer)
			{
				TF2_SetPlayerClass(client, TFClass_Medic);
				TF2_RespawnPlayer(client);
				afk_on(client,0);
				// prevent sending to spec
				return Plugin_Stop;
			}
		}
	}

	return Plugin_Continue;
}
#endif

public Action:Cmd_Player_Request_AFK(client, args)
{
	if(!gB_ConVar_AllowNonAdminsAfk)
	{
		return Plugin_Handled;
	}

	if(ValidPlayer(client))
	{
		if(CountAFKPlayers(client)>=gI_ConVar_Maximum)
		{
			ReplyToCommand(client,"Too many afk player bots at this time, try again later.");
			return Plugin_Handled;
		}

		if(ValidPlayer(client))
		{
			if(IsPlayerAlive(client))
			{
				ForcePlayerSuicide(client);
				TF2_SetPlayerClass(client, TFClass_Medic);
				TF2_RespawnPlayer(client);
				afk_on(client,0);
				// prevent sending to spec
				return Plugin_Stop;
			}
			else
			{
				if(gB_ConVar_AllowRespawnDeadPlayer)
				{
					TF2_SetPlayerClass(client, TFClass_Medic);
					TF2_RespawnPlayer(client);
					afk_on(client,0);
					// prevent sending to spec
					return Plugin_Stop;
				}
			}
		}
	}
	return Plugin_Continue;
}

public Action:Cmd_VoiceMenu(client, args)
{
	if(args < 2) return Plugin_Continue;

	decl String:command[4],String:command2[4];
	GetCmdArg(1,command,sizeof(command));
	GetCmdArg(2,command2,sizeof(command2));
	new cmd1 = StringToInt(command);
	new cmd2 = StringToInt(command2);
	if(ValidPlayer(client,true) && cmd1==0 && cmd2 == 0)
	{
		// calling for medic
		LoopAlivePlayers(inum)
		{
			if(inum != client && g_Player[inum][AFK])
			{
				if(GetVectorDistance( AllPos[client], AllPos[inum] )<350.0)
				{
					// switch controllers
					ClearVariables(inum,false);

					g_Player[inum][PlayerSpawned]=false;

					g_Player[inum][ControllerID]=client;

					g_Player[client][HasAFKPlayer]=true;

					break;
				}
			}
		}
	}
	if(ValidPlayer(client,true) && cmd1==1 && cmd2 == 6)
	{
		LoopAlivePlayers(inum)
		{
			if(inum != client && g_Player[inum][AFK])
			{
				if(g_Player[inum][ControllerID] == client)
				{
					// HIT Uber!
					if (TF_GetUberLevel(inum)>=100.00)
					{
						g_Player[inum][AFK_uber]=true;
						break;
					}
				}
			}
		}
	}
	return Plugin_Continue;
}



public bool IsWallLookingAtWall(client)
{
		bool NearWall = false;

		//Ceiling:
		Handle TraceRay;
		float startpos[3];
		//new Float:Angles[3] =  {270.0, 0.0, 0.0};
		float Angles[3];
		float endpos[3];
		float dir[3];

		// CHECK 1
		//Initialize:
		GetClientEyePosition(client, startpos);
		GetClientEyeAngles(client, Angles);

		Angles[0] = 0.0;
		Angles[2] = 0.0;
		Angles[1] = 30.0;

		GetAngleVectors(Angles, dir, NULL_VECTOR, NULL_VECTOR);

		ScaleVector(dir, 50.0);

		AddVectors(startpos, dir, endpos);

		TraceRay = TR_TraceRayFilterEx(startpos,endpos,MASK_SOLID,RayType_EndPoint,AimTargetFilter);

		//Collision:
		if(TR_DidHit(TraceRay))
		{
			//Declare:
			decl Float:Distance;
			//decl Float:EndOrigin[3];

			//Retrieve:
			//TR_GetEndPosition(EndOrigin, TraceRay);
			TR_GetEndPosition(endpos, TraceRay);

			//Distance:
			Distance = (GetVectorDistance(startpos, endpos));

			if(Distance <= 50.0) NearWall = true;
		}

		CloseHandle(TraceRay);

		if(!NearWall)
		{
			// CHECK 2
			//Initialize:
			GetClientEyePosition(client, startpos);
			GetClientEyeAngles(client, Angles);

			Angles[0] = 0.0;
			Angles[2] = 0.0;
			Angles[1] -= 30.0;

			GetAngleVectors(Angles, dir, NULL_VECTOR, NULL_VECTOR);

			ScaleVector(dir, 50.0);

			AddVectors(startpos, dir, endpos);

			TraceRay = TR_TraceRayFilterEx(startpos,endpos,MASK_SOLID,RayType_EndPoint,AimTargetFilter);

			//Collision:
			if(TR_DidHit(TraceRay))
			{
				//Declare:
				decl Float:Distance;
				//decl Float:EndOrigin[3];

				//Retrieve:
				//TR_GetEndPosition(EndOrigin, TraceRay);
				TR_GetEndPosition(endpos, TraceRay);

				//Distance:
				Distance = (GetVectorDistance(startpos, endpos));

				if(Distance <= 50.0) NearWall = true;
			}

			CloseHandle(TraceRay);
		}
		if(!NearWall)
		{
			// CHECK 2
			//Initialize:
			GetClientEyePosition(client, startpos);
			GetClientEyeAngles(client, Angles);

			Angles[0] = 0.0;
			Angles[2] = 0.0;
			Angles[1] += 30.0;

			GetAngleVectors(Angles, dir, NULL_VECTOR, NULL_VECTOR);

			ScaleVector(dir, 50.0);

			AddVectors(startpos, dir, endpos);

			TraceRay = TR_TraceRayFilterEx(startpos,endpos,MASK_SOLID,RayType_EndPoint,AimTargetFilter);

			//Collision:
			if(TR_DidHit(TraceRay))
			{
				//Declare:
				decl Float:Distance;
				//decl Float:EndOrigin[3];

				//Retrieve:
				//TR_GetEndPosition(EndOrigin, TraceRay);
				TR_GetEndPosition(endpos, TraceRay);

				//Distance:
				Distance = (GetVectorDistance(startpos, endpos));

				if(Distance <= 50.0) NearWall = true;
			}

			CloseHandle(TraceRay);
		}

		return NearWall;
}

public bool:AimTargetFilter(entity,mask)
{
	return !(ValidPlayer(entity));
}
