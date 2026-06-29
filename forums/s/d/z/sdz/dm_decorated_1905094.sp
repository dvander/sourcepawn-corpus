//Includes
#include <sourcemod>
#include <smlib>
#include <sdktools>
#include <morecolors>


//Terminator
#pragma semicolon 1


//Variables
static KillSpree[33];

//Cvars
new Handle:StockMode = INVALID_HANDLE;



public Plugin:myinfo = 
{
	name = "Deathmatch Decorated",
	author = "EasSidezz",
	description = "A Less boring deathmatch plugin",
	version = "1.0",
	url = "sourcemod.net"
}

public OnClientConnected(Client)
{
	//CPrintToChatAll("Player {green}%s has connected!", Client);
}

public OnPluginStart()
{
	RegAdminCmd("sm_health", Command_Health, ADMFLAG_CUSTOM4, "-Set the health of a targeted player");
	RegAdminCmd("sm_suit", Command_Suit, ADMFLAG_CUSTOM4, "-Set the suit of a targeted player");
	RegConsoleCmd("sm_spree", Command_GetStreak, "-View your current Killing Spree");
	RegAdminCmd("sm_setspree", Command_SetStreak, ADMFLAG_CUSTOM6, "-Set a player's Killspree");
	
	//Hooked Events
	HookEvent("player_spawn", Event_PlayerSpawn);
	HookEvent("player_death", Event_PlayerDeath);

	StockMode = CreateConVar("dm_mode", "1", "Decides if players spawn with all weapons and unlimited sprint, 0 = Off, 1 = On (Default: 0)", FCVAR_PLUGIN); 
}

stock bool:IsIngame(Client)
{
	if(IsClientInGame(Client) != -1) return true;
	else return false;
}

public Action:GiveWeapons(Handle:Timer, any:Client)
{
	if(GetConVarInt(StockMode) != 0)
	{
		GivePlayerItem(Client, "weapon_357");
		GivePlayerItem(Client, "weapon_ar2");
		GivePlayerItem(Client, "weapon_shotgun");
		GivePlayerItem(Client, "weapon_frag");
		GivePlayerItem(Client, "weapon_crossbow");
		return Plugin_Handled;
	}
	else
	{
		return Plugin_Handled;
	}
}

//Set Health
public Action:Command_Health(Client, Args)
{	
	//Argument 1 Starting: FindTarget
	decl String:Player[32];
	GetCmdArg(1, Player, sizeof(Player));
	new Target = FindTarget(Client, Player);
	
	//Argument 2 Starting: Set Health
	decl String:HP[32];
	GetCmdArg(2, HP, sizeof(HP));
	decl newHealth;
	newHealth = StringToInt(HP);
	SetEntityHealth(Target, newHealth);
	
	//Cannot find target
	if(Target == -1)
	{
		return Plugin_Handled;
	}
	if(Args != 2)
	{
		CPrintToChat(Client, "{green}[DM] {default}- sm_health <player> <health>");
		return Plugin_Handled;
	}
	decl String:TargetName[MAX_NAME_LENGTH];
	GetClientName(Target, TargetName, sizeof(TargetName));
	new TargetHealth = GetClientHealth(Target);
	CPrintToChat(Client, "{green}[DM] {default}- You set the health of {green}%s to {salmon}%d{default}!", TargetName, TargetHealth);
	//Return:
	return Plugin_Handled;
}

public Action:Command_Suit(Client, Args)
{
	//Argument 1 Starting: FindTarget
	decl String:Player[32];
	GetCmdArg(1, Player, sizeof(Player));
	new Target = FindTarget(Client, Player);
	
	//Arguement 2 Starting: Set Suit
	decl String:Suit[32];
	GetCmdArg(2, Suit, sizeof(Suit));
	decl newSuit;
	newSuit = StringToInt(Suit);
	Client_SetArmor(Target, newSuit);
	
	//Invalid Target
	if(Target == -1)
	{
		//Return 
		return Plugin_Handled;
	}
	if(Args != 2)
	{
		CPrintToChat(Client, "{green}[DM] {default}- sm_suit <player> <suit>");
		return Plugin_Handled;
	}
	
	//Print Target Info:
	decl String:TargetName[MAX_NAME_LENGTH];
	GetClientName(Target, TargetName, sizeof(TargetName));
	new TargetSuit = Client_GetArmor(Target);
	//Print
	CPrintToChat(Client, "{green}[DM] {default}- You set the suit of {green}%s to {cyan}%d{default}!", TargetName, TargetSuit);
	//Return
	return Plugin_Handled;
}

//Get Current Streak
public Action:Command_GetStreak(Client, Args)
{
	CPrintToChat(Client, "{green}[DM] {default}- Your current kill spree is: {green}%d{default}", KillSpree[Client]);
	return Plugin_Handled;
}

public Action:Command_SetStreak(Client, Args)
{
	//Find
	decl String:Player[32];
	GetCmdArg(1, Player, sizeof(Player));
	new Target = FindTarget(Client, Player);
	
	//Set Spree
	decl String:Spree[32];
	GetCmdArg(2, Spree, sizeof(Spree));
	new SetSpree = StringToInt(Spree);
	
	decl String:TargetName[MAX_NAME_LENGTH];
	GetClientName(Target, TargetName, sizeof(TargetName));
	//Set
	KillSpree[Target] = SetSpree;
	
	CPrintToChat(Client, "{green}[DM] {default}- You set the kill spree of: {green}%s {default}to {green}%d{default}", TargetName, KillSpree[Client]);
	//Return
	return Plugin_Handled;
}

/*
======================================================
======================================================
=====================EVENTS===========================
======================================================
======================================================
*/

//Spawn Event

public Action:Event_PlayerSpawn(Handle:Event, const String:Name[], bool:dontBroadcast) 
{
	decl Client;
	Client = GetClientOfUserId(GetEventInt(Event, "userid"));

	//Set Color and Render
	SetEntityRenderMode(Client, RENDER_NORMAL);
	SetEntityRenderColor(Client, 255, 255, 255, 255);
	
	//Equip weapons if nonstock
	if(GetConVarInt(StockMode) != 0)
	{
		CreateTimer(0.8, GiveWeapons, Client);
	}
	KillSpree[Client] = 0;
}	

//Death or Killed Event
public Action:Event_PlayerDeath(Handle:Event, const String:Name[], bool:Broadcast)
{
	new Client = GetEventInt(Event, "userid");
	new ClientID = GetClientOfUserId(Client);
	decl String:ClientName[MAX_NAME_LENGTH];
	GetClientName(ClientID, ClientName, sizeof(ClientName));
	
	new AttackerID = GetEventInt(Event, "attacker");
	new Attacker = GetClientOfUserId(AttackerID);
	decl String:AttackerName[MAX_NAME_LENGTH];
	GetClientName(Attacker, AttackerName, sizeof(AttackerName));
	
	decl String:Weapon[32];
	GetClientWeapon(Attacker, Weapon, sizeof(Weapon));
	
	//Ensure that client did not suicide...
	if(AttackerID != Client)
	{
		//Print Cause
		if(StrEqual(Weapon, "weapon_357", false))
		{	
			CPrintToChatAll("{red}%s {default}just put a hole through {blue}%s {default}with a {green}.357{default}.", AttackerName, ClientName);
		}
		else if(StrEqual(Weapon, "weapon_crossbow", false))
		{
			CPrintToChatAll("{red}%s {default}stapled {blue}%s {default}to hell with a {green}Crossbow{default}.", AttackerName, ClientName);
		}
		else if(StrEqual(Weapon, "weapon_frag", false))
		{
			CPrintToChatAll("{red}%s {default}sent {blue}%s {default}to the moon with some {green}Frag Grenades{default}.", AttackerName, ClientName);
		}
		else if(StrEqual(Weapon, "weapon_crowbar", false))
		{
			CPrintToChatAll("{red}%s {default}just beat {blue}%s {default}to death with a {green}Crowbar{default}.", AttackerName, ClientName);
		}
		else if(StrEqual(Weapon, "weapon_physcannon", false))
		{
			CPrintToChatAll("{red}%s {default}laid {blue}%s {default}out with a {green}Thrown Object{default}.", AttackerName, ClientName);
		}
		else if(StrEqual(Weapon, "weapon_shotgun", false))
		{
			CPrintToChatAll("{red}%s {default}made swiss cheese out of {blue}%s {default}with a {green}Shotgun{default}.", AttackerName, ClientName);
		}
		else if(StrEqual(Weapon, "weapon_ar2", false))
		{
			CPrintToChatAll("{red}%s {default}just pumped {blue}%s {default}full of lead with an {green}Assault Rifle{default}.", AttackerName, ClientName);
		}
		else if(StrEqual(Weapon, "weapon_pistol", false))
		{
			CPrintToChatAll("{red}%s {default}shot up {blue}%s {default}with a {green}9mm{default}.", AttackerName, ClientName);
		}
		else if(StrEqual(Weapon, "weapon_stunstick", false))
		{
			CPrintToChatAll("{red}%s {default}sent {blue}%s {default}into shock by beating him with a {green}Stunstick{default}.", AttackerName, ClientName);
		}
		else if(StrEqual(Weapon, "weapon_smg1", false))
		{
			CPrintToChatAll("{red}%s {default}made a lead factory of {blue}%s {default}with an {green}SMG{default}.", AttackerName, ClientName);
		}
		else if(StrEqual(Weapon, "weapon_rpg", false))
		{
			CPrintToChatAll("{red}%s {default}blew {blue}%s {default}to bits with an {green}Rocket Launcher{default}.", AttackerName, ClientName);
		}
	}
}