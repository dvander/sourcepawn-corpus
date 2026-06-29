#include <sourcemod>
#include <sdktools>
#include <cstrike>
#pragma newdecls required
#pragma semicolon 1

/***************************************************
 * GLOBALS
 **************************************************/
 int g_iTakeKnifeUserIds[MAXPLAYERS+1] = {-1, ...};
 bool g_bClientIsWaitingForTimer[MAXPLAYERS+1];
 bool g_bBlockItemEquip[MAXPLAYERS+1];
 bool g_bBlockTakeKnife[MAXPLAYERS+1];

/***************************************************
 * PLUGIN STUFF
 **************************************************/

public Plugin myinfo =
{
	name = "Knife Swapper",
	author = "Neuro Toxin",
	description = "Allows players to give, take and swap knives with each other!",
	version = "1.6.5",
	url = "www.aus-tg.com",
}

public void OnPluginStart()
{
	RegisterCommands();
	Convar_Create();
	Convar_Hook();
	HookEvents();
}

public void OnConfigsExecuted()
{
	Convar_Load();
}

/***************************************************
 * CONVAR STUFF
 **************************************************/

Handle hcvar_knifeswapper_swapknife = null;
bool cvar_knifeswapper_swapknife = true;

Handle hcvar_knifeswapper_giveknife = null;
bool cvar_knifeswapper_giveknife = true;

Handle hcvar_knifeswapper_takeknife = null;
bool cvar_knifeswapper_takeknife = true;

Handle hcvar_knifeswapper_usetimer = null;
bool cvar_knifeswapper_usetimer = true;

Handle hcvar_knifeswapper_time = null;
int cvar_knifeswapper_time = true;

Handle hcvar_knifeswapper_forcespawn = null;
bool cvar_knifeswapper_forcespawn = false;

Handle hcvar_knifeswapper_allow_multitarget = null;
bool cvar_knifeswapper_allow_multitarget = false;

Handle hcvar_knifeswapper_flag = null;
char cvar_knifeswapper_flag[2] = "";

Handle hcvar_knifeswapper_kniferequired = null;
bool cvar_knifeswapper_kniferequired = false;

Handle hcvar_knifeswapper_disablecmdmessages = null;
bool cvar_knifeswapper_disablecmdmessages = false;

Handle hcvar_knifeswapper_saveselection = null;
bool cvar_knifeswapper_saveselection = true;

Handle hcvar_knifeswapper_blockknife = null;
bool cvar_knifeswapper_blockknife = true;

Handle hcvar_knifeswapper_spawndelay = null;
float cvar_knifeswapper_spawndelay = 0.0;

stock void Convar_Create()
{
	hcvar_knifeswapper_swapknife = CreateConVar("knifeswapper_swapknife", "0", "Enables !swapknife command.");
	hcvar_knifeswapper_giveknife = CreateConVar("knifeswapper_giveknife", "0", "Enables !giveknife command.");
	hcvar_knifeswapper_takeknife = CreateConVar("knifeswapper_takeknife", "1", "Enables !takeknife command.");
	hcvar_knifeswapper_usetimer = CreateConVar("knifeswapper_usetimer", "0", "Players can only use the commands at the start of each round.");
	hcvar_knifeswapper_time = CreateConVar("knifeswapper_time", "30", "How long (seconds) players can use the commands on round start.", _, true, 1.0, true, 60.0);
	hcvar_knifeswapper_forcespawn = CreateConVar("knifeswapper_forcespawn", "0", "Forces a knife to spawn after round start if the player didn't receive one already.");
	hcvar_knifeswapper_allow_multitarget = CreateConVar("knifeswapper_allow_multitarget", "1", "Allows multi targeting on the !giveknife command.");
	hcvar_knifeswapper_flag = CreateConVar("knifeswapper_flag", "", "Only clients with the selected flag will be able to use knife commands.");
	hcvar_knifeswapper_kniferequired = CreateConVar("knifeswapper_kniferequired", "0", "Clients who dont have a knife cant receive one via any plugin commands.");
	hcvar_knifeswapper_disablecmdmessages = CreateConVar("knifeswapper_disablecmdmessages", "0", "Hides plugin commands so they dont display in chat.");
	hcvar_knifeswapper_saveselection = CreateConVar("knifeswapper_saveselection", "1", "Saves your !takeknife selection and takes the knife each spawn.");
	hcvar_knifeswapper_blockknife = CreateConVar("knifeswapper_blockknife", "1", "Allows players to block having their knife taken.");
	hcvar_knifeswapper_spawndelay = CreateConVar("knifeswapper_spawndelay", "0.0", "The delay between the OnSpawned Event until a players receives their saved knife.");
}

stock void Convar_Load()
{
	cvar_knifeswapper_swapknife = GetConVarBool(hcvar_knifeswapper_swapknife);
	cvar_knifeswapper_giveknife = GetConVarBool(hcvar_knifeswapper_giveknife);
	cvar_knifeswapper_takeknife = GetConVarBool(hcvar_knifeswapper_takeknife);
	cvar_knifeswapper_usetimer = GetConVarBool(hcvar_knifeswapper_usetimer);
	cvar_knifeswapper_time = GetConVarInt(hcvar_knifeswapper_time);
	cvar_knifeswapper_forcespawn = GetConVarBool(hcvar_knifeswapper_forcespawn);
	cvar_knifeswapper_allow_multitarget = GetConVarBool(hcvar_knifeswapper_allow_multitarget);
	GetConVarString(hcvar_knifeswapper_flag, cvar_knifeswapper_flag, sizeof(cvar_knifeswapper_flag));
	cvar_knifeswapper_kniferequired = GetConVarBool(hcvar_knifeswapper_kniferequired);
	cvar_knifeswapper_disablecmdmessages = GetConVarBool(hcvar_knifeswapper_disablecmdmessages);
	cvar_knifeswapper_saveselection = GetConVarBool(hcvar_knifeswapper_saveselection);
	cvar_knifeswapper_blockknife = GetConVarBool(hcvar_knifeswapper_blockknife);
	cvar_knifeswapper_spawndelay = GetConVarFloat(hcvar_knifeswapper_spawndelay);
}

stock void Convar_Hook()
{
	HookConVarChange(hcvar_knifeswapper_swapknife, Convar_OnChanged);
	HookConVarChange(hcvar_knifeswapper_giveknife, Convar_OnChanged);
	HookConVarChange(hcvar_knifeswapper_takeknife, Convar_OnChanged);
	HookConVarChange(hcvar_knifeswapper_usetimer, Convar_OnChanged);
	HookConVarChange(hcvar_knifeswapper_time, Convar_OnChanged);
	HookConVarChange(hcvar_knifeswapper_forcespawn, Convar_OnChanged);
	HookConVarChange(hcvar_knifeswapper_allow_multitarget, Convar_OnChanged);
	HookConVarChange(hcvar_knifeswapper_flag, Convar_OnChanged);
	HookConVarChange(hcvar_knifeswapper_kniferequired, Convar_OnChanged);
	HookConVarChange(hcvar_knifeswapper_disablecmdmessages, Convar_OnChanged);
	HookConVarChange(hcvar_knifeswapper_saveselection, Convar_OnChanged);
	HookConVarChange(hcvar_knifeswapper_blockknife, Convar_OnChanged);
	HookConVarChange(hcvar_knifeswapper_spawndelay, Convar_OnChanged);
}

public void Convar_OnChanged(Handle cvar, const char[] oldVal, const char[] newVal)
{
	if (cvar == hcvar_knifeswapper_swapknife)
		cvar_knifeswapper_swapknife = StringToInt(newVal) == 1 ? true : false;
	else if (cvar == hcvar_knifeswapper_giveknife)
		cvar_knifeswapper_giveknife = StringToInt(newVal) == 1 ? true : false;
	else if (cvar == hcvar_knifeswapper_takeknife)
		cvar_knifeswapper_takeknife = StringToInt(newVal) == 1 ? true : false;
	else if (cvar == hcvar_knifeswapper_usetimer)
		cvar_knifeswapper_usetimer = StringToInt(newVal) == 1 ? true : false;
	else if (cvar == hcvar_knifeswapper_time)
		cvar_knifeswapper_time = StringToInt(newVal);
	else if (cvar == hcvar_knifeswapper_forcespawn)
		cvar_knifeswapper_forcespawn = StringToInt(newVal) == 1 ? true : false;
	else if (cvar == hcvar_knifeswapper_allow_multitarget)
		cvar_knifeswapper_allow_multitarget = StringToInt(newVal) == 1 ? true : false;
	else if (cvar == hcvar_knifeswapper_flag)
		cvar_knifeswapper_flag[0] = newVal[0];
	else if (cvar == hcvar_knifeswapper_kniferequired)
		cvar_knifeswapper_kniferequired = StringToInt(newVal) == 1 ? true : false;
	else if (cvar == hcvar_knifeswapper_disablecmdmessages)
		cvar_knifeswapper_disablecmdmessages = StringToInt(newVal) == 1 ? true : false;
	else if (cvar == hcvar_knifeswapper_saveselection)
		cvar_knifeswapper_saveselection = StringToInt(newVal) == 1 ? true : false;
	else if (cvar == hcvar_knifeswapper_blockknife)
		cvar_knifeswapper_blockknife = StringToInt(newVal) == 1 ? true : false;
	else if (cvar == hcvar_knifeswapper_spawndelay)
		cvar_knifeswapper_spawndelay = StringToFloat(newVal);
}

/***************************************************
 * EVENT STUFF
 **************************************************/

public void OnClientConnected(int client)
{
	g_iTakeKnifeUserIds[client] = -1;
	g_bClientIsWaitingForTimer[client] = false;
	g_bBlockTakeKnife[client] = false;
}

stock void HookEvents()
{
	HookEvent("round_start", OnPostRoundStart, EventHookMode_PostNoCopy);
	HookEvent("player_spawn", OnPostPlayerSpawn, EventHookMode_PostNoCopy);
}

public void OnPostRoundStart(Handle event, const char[] name, bool dontBroadcast)
{
	StartCommandTimer();
}

public Action OnPostPlayerSpawn(Handle event, const char[] name, bool dontBroadcast)
{
	int userid = GetEventInt(event, "userid");
	int client = GetClientOfUserId(userid);
	
	if (client == 0)
		return Plugin_Continue;
	
	if (g_bClientIsWaitingForTimer[client])
		return Plugin_Continue;
		
	g_bClientIsWaitingForTimer[client] = true;
	CreateTimer(cvar_knifeswapper_spawndelay, OnPostPlayerSpawnPost, userid);
	return Plugin_Continue;
}

public Action OnPostPlayerSpawnPost(Handle timer, any userid)
{
	int client = GetClientOfUserId(userid);
	if (client == 0)
		return Plugin_Continue;
	
	g_bClientIsWaitingForTimer[client] = false;
	
	if (!IsClientInGame(client))
		return Plugin_Continue;
	
	if (cvar_knifeswapper_forcespawn) // this needs to make sure only one knife is given to a player!
		ForceSpawnPlayerKnife(client);
	
	if (!cvar_knifeswapper_saveselection)
		return Plugin_Continue;
		
	if (g_iTakeKnifeUserIds[client] == -1)
		return Plugin_Continue;
	
	int target = GetClientOfUserId(g_iTakeKnifeUserIds[client]);
	if (target == 0)
	{
		g_iTakeKnifeUserIds[client] = -1;
		return Plugin_Continue;
	}
	
	if (g_bBlockTakeKnife[target])
		// Keep the selection in case the target unblocks taking their knife
		return Plugin_Continue;
	
	if (!IsPlayerAlive(target))
		return Plugin_Continue;
		
	int team = GetClientTeam(target);
	if (team != CS_TEAM_CT && team != CS_TEAM_T)
		return Plugin_Continue;
	
	GivePlayerKnife(target, client, client, false);
	return Plugin_Continue;
}

// This is a forward from GniEx and a fix for paintkits (this is not used if paintkits is not loaded)
public Action OnGiveNamedItemEx_AllowEquip(int client, int entity)
{
	if (g_bBlockItemEquip[client])
		return Plugin_Stop;
	
	return Plugin_Continue;
}

/***************************************************
 * BLOCKING COMMAND OUTPUT STUFF
 **************************************************/

public Action OnClientSayCommand(int client, const char[] command, const char[] args)
{
	if ((StrContains(args, "!giveknife", false) == 0 ||
			StrContains(args, "!takeknife", false) == 0 ||
			StrContains(args, "!swapknife", false) == 0 ||
			StrContains(args, "!resetknife", false) == 0)
			&& cvar_knifeswapper_disablecmdmessages)
		return Plugin_Handled;
	
	return Plugin_Continue;
}

/***************************************************
 * COMMAND STUFF
 **************************************************/

stock void RegisterCommands()
{
	RegConsoleCmd("swapknife", OnCommandSwapKnife);
	RegConsoleCmd("giveknife", OnCommandGiveKnife);
	RegConsoleCmd("takeknife", OnCommandTakeKnife);
	RegConsoleCmd("resetknife", OnCommandResetKnife);
	RegConsoleCmd("blockknife", OnCommandBlockKnife);
}

public Action OnCommandBlockKnife(int client, int args)
{
	if (!cvar_knifeswapper_blockknife)
	{
		ReplyToCommand(client, "[SM] You dont have permission to access this command.");
		return Plugin_Handled;
	}
	
	g_bBlockTakeKnife[client] = !g_bBlockTakeKnife[client];
	
	if (g_bBlockTakeKnife[client])
		ReplyToCommand(client, "[SM] You have blocked players from taking your knife!");
	else
		ReplyToCommand(client, "[SM] Players may take your knife again!");
		
	return Plugin_Handled;
}

public Action OnCommandResetKnife(int client, int args)
{
	if (!IsClientInGame(client))
		return Plugin_Handled;
		
	if (!IsPlayerAlive(client))
		return Plugin_Handled;
		
	g_iTakeKnifeUserIds[client] = -1;
	
	int team = GetClientTeam(client);
	if (team != CS_TEAM_T && team != CS_TEAM_CT)
		return Plugin_Handled;
	
	int targetactiveweapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	bool playerhasknife = false;
	bool equiptargetnewknife = false;
	bool equiptaser = false;
	int targetknife = GetPlayerWeaponSlot(client, CS_SLOT_KNIFE);
	
	while (targetknife != -1)
	{
		// check for taser
		if (GetEntProp(targetknife, Prop_Send, "m_iItemDefinitionIndex") == 31)
			equiptaser = true;
		else
		{
			playerhasknife = true;
			if (targetactiveweapon == targetknife)
				equiptargetnewknife = true;
		}
		
		RemovePlayerItem(client, targetknife);
		AcceptEntityInput(targetknife, "Kill");
		targetknife = GetPlayerWeaponSlot(client, CS_SLOT_KNIFE);
	}
	
	if (cvar_knifeswapper_kniferequired)
	{
		if (playerhasknife)
			GivePlayerItem(client, "weapon_knife");
	}
	else
		GivePlayerItem(client, "weapon_knife");
	
	if (equiptaser)
		GivePlayerItem(client, "weapon_taser");
		
	if (equiptargetnewknife)
		CreateTimer(0.01, OnEquipPlayerKnifeRequired, GetClientUserId(client));
		
	PrintToChat(client, "[SM] You knife has been reset!");
	return Plugin_Handled;
}

public Action OnCommandSwapKnife(int client, int args)
{
	if (!cvar_knifeswapper_swapknife)
		return Plugin_Handled;
		
	if (!PlayerHasCorrectFlags(client))
	{
		ReplyToCommand(client, "[SM] You dont have permission to access this command.");
		return Plugin_Handled;
	}
		
	if (cvar_knifeswapper_usetimer)
	{
		if (HasCommandTimerElapsed())
		{
			ReplyToCommand(client, "[SM] You can only use this command during the first %d second(s) of each round.");
			return Plugin_Handled;
		}
	}
		
	if (!IsClientInGame(client))
		return Plugin_Handled;
		
	if (!IsPlayerAlive(client))
		return Plugin_Handled;
	
	int team = GetClientTeam(client);
	if (team != CS_TEAM_T && team != CS_TEAM_CT)
		return Plugin_Handled;
	
	int knife = GetPlayerWeaponSlot(client, CS_SLOT_KNIFE);
	if (knife == -1)
	{
		ReplyToCommand(client, "[SM] Knife not found!");
		return Plugin_Handled;
	}
	
	char target[32];
	GetCmdArg(1, target, sizeof(target));
	
	if (StrEqual("", target))
	{
		ReplyToCommand(client, "[SM] Usage: !swapknife <player>.");
		return Plugin_Handled;
	}
	
	int targets[1];
	char targetname[64];
	bool is_ml;
	
	int result = ProcessTargetString(target, 0, targets, sizeof(targets), COMMAND_FILTER_NO_MULTI,
		targetname, sizeof(targetname), is_ml);
	
	if (result != 1)
	{
		if (result == 0)
			ReplyToCommand(client, "[SM] No matching target found.");
		else
			ReplyToCommand(client, "[SM] Targeting error: %d.", result);
		return Plugin_Handled;
	}
	
	if (targets[0] == client)
	{
		ReplyToCommand(client, "[SM] You cant swap your own knife!");
		return Plugin_Handled;
	}
	
	if (!IsClientInGame(targets[0]))
	{
		ReplyToCommand(client, "[SM] Target is not in game!");
		return Plugin_Handled;
	}
		
	if (!IsPlayerAlive(targets[0]))
	{
		ReplyToCommand(client, "[SM] Target is not alive!");
		return Plugin_Handled;
	}
	
	if (cvar_knifeswapper_kniferequired && !PlayerHasKnife(targets[0]))
	{
		ReplyToCommand(client, "[SM] Target does not have a knife to switch!");
		return Plugin_Handled;
	}
	
	if (g_bBlockTakeKnife[targets[0]])
	{
		ReplyToCommand(client, "[SM] Target has blocked players from taking their knife!");
		return Plugin_Handled;
	}
	
	SwapPlayerKnife(client, targets[0]);	
	return Plugin_Handled;
}

public Action OnCommandGiveKnife(int client, int args)
{
	if (!IsClientInGame(client))
		return Plugin_Handled;
		
	if (!cvar_knifeswapper_giveknife)
	{
		ReplyToCommand(client, "[SM] !giveknife is currently disabled.");
		return Plugin_Handled;
	}
	
	if (!PlayerHasCorrectFlags(client))
	{
		ReplyToCommand(client, "[SM] You dont have permission to access this command.");
		return Plugin_Handled;
	}
		
	if (cvar_knifeswapper_usetimer)
	{
		if (HasCommandTimerElapsed())
		{
			ReplyToCommand(client, "[SM] You can only use this command during the first %d second(s) of each round.", cvar_knifeswapper_time);
			return Plugin_Handled;
		}
	}
	
	if (!IsPlayerAlive(client))
	{
		ReplyToCommand(client, "[SM] You need to be alive to use !giveknife.");
		return Plugin_Handled;
	}
	
	int team = GetClientTeam(client);
	if (team != CS_TEAM_T && team != CS_TEAM_CT)
	{
		ReplyToCommand(client, "[SM] Invalid team.");
		return Plugin_Handled;
	}
	
	char target[32];
	GetCmdArg(1, target, sizeof(target));
	
	if (StrEqual("", target))
	{
		ReplyToCommand(client, "[SM] Usage: !giveknife <player>.");
		return Plugin_Handled;
	}
	
	int targets[64];
	char targetname[64];
	bool is_ml;
	
	int result;
	if (cvar_knifeswapper_allow_multitarget)
		result = ProcessTargetString(target, 0, targets, sizeof(targets), COMMAND_FILTER_ALIVE,
			targetname, sizeof(targetname), is_ml);
	else
		result = ProcessTargetString(target, 0, targets, sizeof(targets), COMMAND_FILTER_NO_MULTI,
			targetname, sizeof(targetname), is_ml);
	
	if (result != 1)
	{
		if (result == 0)
		{
			ReplyToCommand(client, "[SM] No matching target found.");
			return Plugin_Handled;
		}
		else if (!cvar_knifeswapper_allow_multitarget)
		{
			ReplyToCommand(client, "[SM] Targeting error: %d.", result);
			return Plugin_Handled;
		}		
	}
	
	int givecount = 0;
	for (int targetclient = 0; targetclient < result; targetclient++)
	{
		if (targets[targetclient] == client)
		{
			if (cvar_knifeswapper_allow_multitarget)
				continue;
				
			ReplyToCommand(client, "[SM] You cant swap your own knife!");
			return Plugin_Handled;
		}
		
		if (!IsClientInGame(targets[targetclient]))
		{
			if (cvar_knifeswapper_allow_multitarget)
				continue;
				
			ReplyToCommand(client, "[SM] Target is not in game!");
			return Plugin_Handled;
		}
			
		if (!IsPlayerAlive(targets[targetclient]))
		{
			if (cvar_knifeswapper_allow_multitarget)
				continue;
				
			ReplyToCommand(client, "[SM] Target is not alive!");
			return Plugin_Handled;
		}
		
		team = GetClientTeam(targets[targetclient]);
		if ((team != CS_TEAM_T && team != CS_TEAM_CT))
		{
			if (cvar_knifeswapper_allow_multitarget)
				continue;
				
			ReplyToCommand(client, "[SM] Target is on an invalid team.");
			return Plugin_Handled;
		}
		
		if (GivePlayerKnife(client, targets[targetclient], client, result == 1) == Plugin_Stop)
			break;
			
		givecount++;
	}
	
	if (result > 1)
		ReplyToCommand(client, "[SM] You gave your knife to %d player(s)", givecount);
	
	return Plugin_Handled;
}

public Action OnCommandTakeKnife(int client, int args)
{
	if (!IsClientInGame(client))
		return Plugin_Handled;
		
	if (!cvar_knifeswapper_takeknife)
	{
		ReplyToCommand(client, "[SM] !takeknife is currently disabled.");
		return Plugin_Handled;
	}
	
	if (!PlayerHasCorrectFlags(client))
	{
		ReplyToCommand(client, "[SM] You dont have permission to access this command.");
		return Plugin_Handled;
	}
		
	if (cvar_knifeswapper_usetimer)
	{
		if (HasCommandTimerElapsed())
		{
			ReplyToCommand(client, "[SM] You can only use this command during the first %d second(s) of each round.", cvar_knifeswapper_time);
			return Plugin_Handled;
		}
	}
	
	if (!IsPlayerAlive(client))
	{
		ReplyToCommand(client, "[SM] You need to be alive to use !takeknife.");
		return Plugin_Handled;
	}
	
	int team = GetClientTeam(client);
	if (team != CS_TEAM_T && team != CS_TEAM_CT)
	{
		ReplyToCommand(client, "[SM] Invalid team.");
		return Plugin_Handled;
	}
	
	char target[32];
	GetCmdArg(1, target, sizeof(target));
	
	if (StrEqual("", target))
	{
		ReplyToCommand(client, "[SM] Usage: !takeknife <player>.");
		return Plugin_Handled;
	}
	
	int targets[1];
	char targetname[64];
	bool is_ml;
	
	int result = ProcessTargetString(target, 0, targets, sizeof(targets), COMMAND_FILTER_NO_MULTI,
		targetname, sizeof(targetname), is_ml);
	
	if (result != 1)
	{
		if (result == 0)
			ReplyToCommand(client, "[SM] No matching target found.");
		else
			ReplyToCommand(client, "[SM] Targeting error: %d.", result);
		return Plugin_Handled;
	}
	
	if (targets[0] == client)
	{
		ReplyToCommand(client, "[SM] You cant swap your own knife!");
		return Plugin_Handled;
	}
	
	if (!IsClientInGame(targets[0]))
	{
		ReplyToCommand(client, "[SM] Target is not in game!");
		return Plugin_Handled;
	}
		
	if (!IsPlayerAlive(targets[0]))
	{
		ReplyToCommand(client, "[SM] Target is not alive!");
		return Plugin_Handled;
	}
	
	team = GetClientTeam(targets[0]);
	if (team != CS_TEAM_T && team != CS_TEAM_CT)
	{
		ReplyToCommand(client, "[SM] Target is on an invalid team.");
		return Plugin_Handled;
	}
	
	if (g_bBlockTakeKnife[targets[0]])
	{
		ReplyToCommand(client, "[SM] Target has blocked players from taking their knife!");
		return Plugin_Handled;
	}
	
	GivePlayerKnife(targets[0], client, client);
	g_iTakeKnifeUserIds[client] = GetClientUserId(targets[0]);
	return Plugin_Handled;
}

/***************************************************
 * KNIFE STUFF
 **************************************************/

stock Action GivePlayerKnife(int client, int target, int commandclient, bool displaymessage=true)
{
	if (!IsClientInGame(client))
		return Plugin_Stop;

	int knife = GetPlayerWeaponSlot(client, CS_SLOT_KNIFE);
	if (knife == -1)
	{
		ReplyToCommand(commandclient, "[SM] Knife not found!");
		return Plugin_Stop;
	}
	
	if (cvar_knifeswapper_kniferequired && !PlayerHasKnife(target))
		return Plugin_Continue;
	
	g_bBlockItemEquip[client] = true; // paintkits fix
	int newknife = GivePlayerItem(client, "weapon_knife");
	g_bBlockItemEquip[client] = false; // paintkits fix
	if (newknife == -1)
	{
		ReplyToCommand(commandclient, "[SM] Unable to spawn your knife!");
		return Plugin_Stop;
	}
	
	int weaponindex = GetEntProp(newknife, Prop_Send, "m_iItemDefinitionIndex");
	if (weaponindex == 42 || weaponindex == 59) // standard knife || knife t
	{
		if (commandclient == client)
			ReplyToCommand(commandclient, "[SM] You cant give your default knife to another player!");
		else
			ReplyToCommand(commandclient, "[SM] You cant take a default knife from another player!");
		AcceptEntityInput(newknife, "Kill");
		return Plugin_Stop;
	}
	
	bool equiptargetnewknife = false;
	int targetactiveweapon = GetEntPropEnt(target, Prop_Send, "m_hActiveWeapon");
	bool equiptaser = false;
	int targetknife = GetPlayerWeaponSlot(target, CS_SLOT_KNIFE);
	
	while (targetknife != -1)
	{
		// check for taser
		if (GetEntProp(targetknife, Prop_Send, "m_iItemDefinitionIndex") == 31)
			equiptaser = true;
		else
		{
			if (targetactiveweapon == targetknife)
				equiptargetnewknife = true;
		}
		
		RemovePlayerItem(target, targetknife);
		AcceptEntityInput(targetknife, "Kill");
		targetknife = GetPlayerWeaponSlot(target, CS_SLOT_KNIFE);
	}
	
	float targetvec[3];
	GetEntPropVector(target, Prop_Send, "m_vecOrigin", targetvec);
	TeleportEntity(newknife, targetvec, NULL_VECTOR, NULL_VECTOR);
	
	EquipPlayerWeapon(target, newknife);
	if (equiptargetnewknife)
		CreateTimer(0.01, OnEquipPlayerKnifeRequired, GetClientUserId(target));
		
	if (equiptaser)
		GivePlayerItem(target, "weapon_taser");
	
	PrintToChat(target, "\x01[SM] You received a knife from \x04%N", client);
	
	if (displaymessage)
		PrintToChat(client, "\x01[SM] You gave your knife to \x04%N", target);
	return Plugin_Continue;
}

public Action OnEquipPlayerKnifeRequired(Handle tmr, any userid)
{
	int client = GetClientOfUserId(userid);
	if (client == 0)
		return Plugin_Continue;

	int targetknife = GetPlayerWeaponSlot(client, CS_SLOT_KNIFE);
	if (targetknife == -1)
		return Plugin_Continue;
		
	SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", targetknife);
	return Plugin_Continue;
}

stock void SwapPlayerKnife(int client, int target)
{		
	int knife = GetPlayerWeaponSlot(client, CS_SLOT_KNIFE);
	if (knife == -1)
	{
		ReplyToCommand(client, "[SM] Knife not found!");
		return;
	}
	
	int targetknife = GetPlayerWeaponSlot(target, CS_SLOT_KNIFE);
	if (targetknife == -1)
	{
		ReplyToCommand(client, "[SM] Target does not have a knife!");
		return;
	}
	
	CS_DropWeapon(client, knife, false, true);
	CS_DropWeapon(target, targetknife, false, true);
	
	float clientvec[3]; float targetvec[3];
	GetEntPropVector(client, Prop_Send, "m_vecOrigin", clientvec);
	GetEntPropVector(target, Prop_Send, "m_vecOrigin", targetvec);
	
	TeleportEntity(knife, targetvec, NULL_VECTOR, NULL_VECTOR);
	TeleportEntity(targetknife, clientvec, NULL_VECTOR, NULL_VECTOR);
	
	EquipPlayerWeapon(client, targetknife);
	EquipPlayerWeapon(target, knife);
}

stock void ForceSpawnPlayerKnife(int client)
{
	if (!IsClientInGame(client))
		return;
		
	if (!IsPlayerAlive(client))
		return;
		
	if (GetClientTeam(client) <= CS_TEAM_SPECTATOR)
		return;
		
	int knife = GetPlayerWeaponSlot(client, CS_SLOT_KNIFE);
	if (knife > 0)
		return;
		
	knife = GivePlayerItem(client, "weapon_knife");
}

stock bool PlayerHasCorrectFlags(int client)
{
	if (StrEqual(cvar_knifeswapper_flag, ""))
		return true;
	
	AdminId admin = GetUserAdmin(client);
	if (admin == INVALID_ADMIN_ID)
		return false;
	
	AdminFlag flag;
	if (!FindFlagByChar(cvar_knifeswapper_flag[0], flag))
		return true;
	
	if (!GetAdminFlag(admin, flag))
		return false;

	return true;
}

stock bool IsDefIndexMelee(int defindex)
{
	// As this is called with defindicies from weaponslot_melee
	// if the index isnt a taser, we know its a knife
	if (defindex == 31)
		return false;

	return true;
}

stock bool PlayerHasKnife(int client)
{
	int weapon = GetPlayerWeaponSlot(client, CS_SLOT_KNIFE);
	if (weapon == -1 || weapon == 31)
		return false;
	
	return true;
}

/***************************************************
 * TIMER STUFF
 **************************************************/

bool CommandTimerHasStarted = false;
int CommandTimerStartTime;

stock void StartCommandTimer()
{
	CommandTimerStartTime = GetTime();
	CommandTimerHasStarted = true;
}

stock bool HasCommandTimerElapsed()
{
	if (!CommandTimerHasStarted) // late load block
		return true;
		
	if (GetTime() >=  CommandTimerStartTime + cvar_knifeswapper_time)
		return true;
	else
		return false;
}