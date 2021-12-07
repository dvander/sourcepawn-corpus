#include <sourcemod>
#include <sdktools>

#pragma semicolon 1

#define cDefault				0x01
#define cLightGreen 			0x03
#define cGreen					0x04
#define cDarkGreen  			0x05
#define CHAT_TAG "\x04[Hunter]\x01"

#define DOD_TEAM_ALLIES 2
#define DOD_TEAM_AXIS 3
#define DOD_TEAM_SPEC 1
#define TRANS 15

new Handle:c_Enabled   		= INVALID_HANDLE;
new bool:hunter_live = false; 

//convar handles
new Handle:c_friendlyfire = INVALID_HANDLE;
new Handle:c_limitteams = INVALID_HANDLE;
new Handle:c_timelimit = INVALID_HANDLE;


//current convar values
new d_mp_friendlyfire = 0;
new d_mp_limitteams = 1;
new d_mp_timelimit = 0;

 
public Plugin:myinfo =
{
	name = "Hunter or Hunted",
	author = "GamingRobot32",
	description = "Invisable players try to kill all the visable ones",
	version = "1.0.0.0",
	url = "http://www.gamingrobot.net"
};
 
public OnPluginStart()
{
  LoadTranslations("common.phrases");
  
  c_Enabled = CreateConVar("sm_hunter",  "0", "<0/1> Enable Hunter or Hunted");
  RegAdminCmd("sm_hunter_live", Command_HunterStart, ADMFLAG_SLAY, "sm_btshuffle, pick a random player to be it");
  HookConVarChange(c_Enabled, ConVarChange_HuntEnabled);
  HookEvent("player_spawn", Event_PlayerSpawn);
  HookEvent("player_death", Event_PlayerDeath);
  HookEvent("dod_round_start", Event_RoundStart);
  HookEvent("dod_round_win", Event_RoundWin);
  AddCommandListener(CMD_Listener, "jointeam");
}

public Action:CMD_Listener(client, const String:command[], argc)
{
	if(GetConVarBool(c_Enabled) && hunter_live)
	{
		decl String:arg[3], team;
		arg[0] = '\0';
		GetCmdArg(1, arg, sizeof(arg));
		team = StringToInt(arg);
		if(team == DOD_TEAM_ALLIES || team == DOD_TEAM_AXIS){
			PrintToChat(client,"%s You cannont swich teams until round end", CHAT_TAG);
			return Plugin_Handled;
		}
	}
	return Plugin_Continue;
}

public Action:Command_HunterStart(client, args)
{
	if(GetConVarBool(c_Enabled))
	{
		PrintToChatAll("%s Round LIVE", CHAT_TAG);
		hunter_live = true;
	}
}

public ConVarChange_HuntEnabled(Handle:convar, const String:oldValue[], const String:newValue[])
{			
	if(StringToInt(newValue) == 1)
	{
		PrintToChatAll("%s Hunter or Hunted Enabled", CHAT_TAG);
		//GET CURRENT CONVAR VALUES
		c_friendlyfire = FindConVar("mp_friendlyfire");
		c_limitteams = FindConVar("mp_limitteams");
		c_timelimit = FindConVar("mp_timelimit");
		d_mp_friendlyfire = GetConVarInt(c_friendlyfire);
		d_mp_limitteams = GetConVarInt(c_limitteams);
		d_mp_timelimit = GetConVarInt(c_timelimit);
		//SET NEW VALUES
		SetConVarInt(c_friendlyfire, 1);
		SetConVarInt(c_limitteams, 0);
		SetConVarInt(c_timelimit, 0);
		
		ServerCommand("mp_clan_restartround 1");
	}
	else if(StringToInt(newValue) == 0)
	{
		PrintToChatAll("%s Hunter or Hunted Disabled", CHAT_TAG);
		//PUT CONVARS BACK
		SetConVarInt(c_friendlyfire, d_mp_friendlyfire);
		SetConVarInt(c_limitteams, d_mp_limitteams);
		SetConVarInt(c_timelimit, d_mp_timelimit);
		
		for (new i = 1; i <= GetClientCount(); i++)
		{
			SetEntityRenderMode(i,  RENDER_NORMAL);
			SetEntityRenderColor(i, 255, 255, 255, 255);
		}
		ServerCommand("mp_clan_restartround 1");
	}
}

public Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(GetConVarBool(c_Enabled))
	{
		new spawn = GetClientOfUserId(GetEventInt(event, "userid"));
		if (GetClientTeam(spawn) == DOD_TEAM_AXIS){
			for (new i = 0, s; i < 5; i++)
			{
				if ((s = GetPlayerWeaponSlot(spawn, i)) != -1)
				{
					RemoveWeapon(spawn, s);
				}
			}
			//new knife = GivePlayerItem(spawn, "weapon_spade");
			new knife = GivePlayerItem(spawn, "weapon_amerknife");
			if(IsValidEntity(knife)){
				SetEntityRenderMode(knife,  RENDER_TRANSCOLOR);
				SetEntityRenderColor(knife, TRANS, TRANS, TRANS, TRANS);
			}
			if(IsValidEntity(spawn)){
				SetEntityRenderMode(spawn,  RENDER_TRANSCOLOR);
				SetEntityRenderColor(spawn, TRANS, TRANS, TRANS, TRANS);
			}
		}
		else
		{
			SetEntityRenderMode(spawn,  RENDER_NORMAL);
			SetEntityRenderColor(spawn, 255, 255, 255, 255);
		}
	}
}

public Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(GetConVarBool(c_Enabled) && hunter_live)
	{
		new dead = GetClientOfUserId(GetEventInt(event, "userid"));
		ChangeClientTeam(dead,DOD_TEAM_SPEC);
	
		//check if everyone is dead, if so restart
		new alliescount =0;
		new axiscount =0;
		for (new i = 1; i <= GetClientCount(); i++)
		{
			if (GetClientTeam(i) == DOD_TEAM_ALLIES)
			{
				alliescount++;
			}
			if (GetClientTeam(i) == DOD_TEAM_AXIS)
			{
				axiscount++;
			}
		}
		if(alliescount == 0){
			//axis won
			PrintToChatAll("%s Predators Won!", CHAT_TAG);
			PrintToChatAll("%s Restarting Round!", CHAT_TAG);
			hunter_live = false;
			ServerCommand("mp_clan_restartround 1");
		}
		if(axiscount == 0){
			//allies won
			PrintToChatAll("%s Humans Won!", CHAT_TAG);
			PrintToChatAll("%s Restarting Round!", CHAT_TAG);
			hunter_live = false;
			ServerCommand("mp_clan_restartround 1");
		}
		
	}
}

public Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(GetConVarBool(c_Enabled))
	{
		if(!hunter_live){
			for (new i = 1; i <= GetClientCount(); i++)
			{
				ChangeClientTeam(i,DOD_TEAM_ALLIES);
			}
			PrintToChatAll("%s Pick players to go axis to be Predators then sm_hunter_live", CHAT_TAG);
		}
	}
}

public Event_RoundWin(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(GetConVarBool(c_Enabled))
	{
		hunter_live = false;
	}
}

RemoveWeapon(client, weapon)
{
	if (IsValidEdict(weapon))
	{
		RemovePlayerItem(client, weapon);
		RemoveEdict(weapon);
	}
}
