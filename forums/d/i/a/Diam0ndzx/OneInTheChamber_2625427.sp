#pragma semicolon 1

#define DEBUG

#define PLUGIN_AUTHOR "Diam0ndz"
#define PLUGIN_VERSION "1.0"

/* Default includes */
#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <sdkhooks>

/* Includes that I put in */
#include "include/nextmap.inc"

#pragma newdecls required

EngineVersion g_Game;

ConVar oitc_maxRounds;
ConVar oitc_maxPoints;

float Points[MAXPLAYERS + 1];
int Round;

char nextmap[128];

/* Plugin info */
public Plugin myinfo = 
{
	name = "One In The Chamber",
	author = PLUGIN_AUTHOR,
	description = "One shot, one kill. Waste your bullet and you have to knife someone to get it back.",
	version = PLUGIN_VERSION,
	url = "https://steamcommunity.com/id/Diam0ndz/"
};

public void OnPluginStart()
{
	g_Game = GetEngineVersion();
	if(g_Game != Engine_CSGO && g_Game != Engine_CSS)
	{
		SetFailState("This plugin is for CSGO/CSS only.");	
	}
	
	oitc_maxPoints = CreateConVar("oitc_maxpoints", "25", "The maximum amount of points to gain before winning the game");
	oitc_maxRounds = CreateConVar("oitc_maxrounds", "3", "The maximum amount of rounds before switching the map");
	
	HookEvent("player_spawned", Event_PlayerSpawned); //Different events to hook
	HookEvent("player_death", Event_PlayerDeath);
	HookEvent("round_poststart", Event_RoundPostStart);
	HookEvent("player_hurt", Event_PlayerHurt);
	
	//RegAdminCmd("sm_setpoints", SetPoints, ADMFLAG_ROOT, "Set the points of a client in the One in the Chamber plugin");
	RegConsoleCmd("sm_setpoints", SetPoints, "Set the points of a client in the One in the Chamber plugin", ADMFLAG_ROOT);
	
	AutoExecConfig(true, "oitc", _);
}

public void OnMapStart()
{
	ServerCommand("mp_randomspawn 1"); //Different server commands optimal for One in the Chamber
	ServerCommand("mp_death_drop_gun 0"); 
	ServerCommand("mp_death_drop_defuser 0");
	ServerCommand("mp_death_drop_grenade 0");
	ServerCommand("mp_freezetime 2");
	ServerCommand("mp_warmuptime 0");
	ServerCommand("mp_roundtime_defuse 5");
	ServerCommand("mp_do_warmup_period 0");
	ServerCommand("mp_roundtime_hostage 5");
	ServerCommand("mp_teammates_are_enemies 1");
	ServerCommand("mp_ignore_round_win_conditions 1");
	ServerCommand("mp_maxrounds %i", GetConVarInt(oitc_maxRounds));
}

public void OnClientPutInServer(int client)
{
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage); //Hook when you take damage
	Points[client] = 0.0; //Set points to 0
	Round = 1;
}

public Action Event_RoundPostStart(Event event, const char[] name, bool dontBroadcast)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		StripAndGive(i);
		Points[i] = 0.0;
	}
}

public Action Event_PlayerSpawned(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	StripAndGive(client);
}

public Action Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	CreateTimer(0.5, RespawnClient, client);
}

public Action Event_PlayerHurt(Event event, const char[] name, bool dontBroadcast)
{
    int userid = GetEventInt(event, "attacker");
    int attacker = GetClientOfUserId(userid);
    SetEventInt(event, "health", 0);
    StripAndGive(attacker);
    Points[attacker] += 1;
    if(Points[attacker] >= GetConVarFloat(oitc_maxPoints))
    {
        RequestFrame(Frame_PlayerHurt, userid);
    }
    else
    {
        PrintHintText(attacker, "Points : %.2f/%.2f", Points[attacker], GetConVarFloat(oitc_maxPoints));
    }
}

public Action SetPoints(int client, int args)
{
	if (args < 1 || args > 2)
	{
		ReplyToCommand(client, "Usage: sm_setpoints <name> <points(0-24)>");
		return Plugin_Handled;
	}
	char name[32];
	int target = -1;
	GetCmdArg(1, name, sizeof(name));
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if(!IsClientConnected(i))
		{
			continue;
		}
		char other[32];
		GetClientName(i, other, sizeof(other));
		if(StrEqual(name, other))
		{
			target = i;
		}
	}
	
	if(target == -1)
	{
		ReplyToCommand(client, "No player found with username %s", name);
		return Plugin_Handled;
	}
	
	char pointsToGive[32];
	float pointNum = -1.0;
	GetCmdArg(2, pointsToGive, sizeof(pointsToGive));
	pointNum = StringToFloat(pointsToGive);
	if(pointNum > 24 || pointNum < 0)
	{
		ReplyToCommand(client, "Point value must be between 0 and 24!");
		return Plugin_Handled;
	}
	Points[target] = pointNum;
	PrintToChatAll(" \x06%N \x0Bset \x06%N's \x0Bpoints to \x06%.2f", client, target, pointNum);
	return Plugin_Handled;
}

public void Frame_PlayerHurt(int userid)
{
    int attacker = GetClientOfUserId(userid);

    if (attacker > 0 && IsClientInGame(attacker))
    {
        PlayerWon(attacker);
    }
}

stock void PlayerWon(int client)
{
	PrintToChatAll(" \x06%N \x0Bwon with \x06%.2f \x0Bpoints !", client, Points[client]);
	PrintCenterTextAll(" \x06%N \x0Bwon with \x06%.2f \x0Bpoints !", client, Points[client]);
	if(Round < GetConVarInt(oitc_maxRounds))
	{
		CS_TerminateRound(8.0, CSRoundEnd_GameStart, true);
		Round += 1;
		Points[client] = 0.0;
		PrintToChatAll(" \x0BCurrently starting round \x06%i \x0Bout of round \x06%i", Round, GetConVarInt(oitc_maxRounds));
	}
	else
	{
		CS_TerminateRound(7.0, CSRoundEnd_GameStart, true);
		PrintCenterTextAll("\x0BThe final round has ended!");
		GetNextMap(nextmap, sizeof(nextmap));
		PrintToChatAll(" \x0BChanging Map to\x06 %s \x0Bin 3 seconds...", nextmap);
		CreateTimer(0.5, Timer_SwitchMap);
	}
}

public Action Timer_SwitchMap(Handle timer)
{
	ServerCommand("sm_map %s", nextmap);
}

public Action CS_OnCSWeaponDrop(int client, int weapon)
{
	return Plugin_Handled;
}

public Action OnTakeDamage(int victim, int&attacker, int&inflictor, float&damage, int&damagetype, int&weapon, float damageForce[3], float damagePosition[3])
{
	if(IsValidClient(victim))
	{
		if(damagetype == DMG_FALL)
		{
			return Plugin_Handled;
		}
		if(weapon != 0)
		{
			damage = 500.0;
			return Plugin_Changed;		
		}
	}
	return Plugin_Continue;
}

public Action StripAndGive(int client)
{
	StripWeapon(client);
	
	GiveWeapon(client);
}

public Action GiveWeapon(int client)
{
	GivePlayerItem(client, "weapon_elite", 0);
	int weapon =  GetEntPropEnt(client, Prop_Data, "m_hActiveWeapon");
	SetAmmo(client, weapon, 1);
	GivePlayerItem(client, "weapon_knife", 0);
}

public Action StripWeapon(int client)
{
	int weapon = -1;
	if(client > 0 && IsClientInGame(client) && IsPlayerAlive(client) && GetClientTeam(client) > 1) 
    {
        weapon = -1;
        for(int slot = 5; slot >= 0; slot--) 
        {
            while((weapon = GetPlayerWeaponSlot(client, slot)) != -1) 
            {
                if(IsValidEntity(weapon)) 
                {
                    RemovePlayerItem(client, weapon);
                }
            }
        }
    }
}

public Action RespawnClient(Handle timer, int client)
{
	CS_RespawnPlayer(client);
	StripAndGive(client);
}

public Action SetAmmo(int client, int weapon, int ammo)
{ 
  if (IsValidEntity(weapon)) {
    //Primary ammo
    SetReserveAmmo(client, weapon, 0);
    
    //Clip
    SetClipAmmo(client, weapon, ammo);
  }
}

public Action CS_OnBuyCommand(int client, const char[] weapon)
{
	return Plugin_Handled;
}

stock int SetReserveAmmo(int client, char weapon, int ammo)
{
  SetEntProp(weapon, Prop_Send, "m_iPrimaryReserveAmmoCount", ammo); //set reserve to 0
    
  int ammotype = GetEntProp(weapon, Prop_Send, "m_iPrimaryAmmoType");
  if(ammotype == -1) return;
  
  SetEntProp(client, Prop_Send, "m_iAmmo", ammo, _, ammotype);
}


stock int SetClipAmmo(int client, char weapon, int ammo)
{
  SetEntProp(weapon, Prop_Send, "m_iClip1", ammo);
  SetEntProp(weapon, Prop_Send, "m_iClip2", ammo);
}

stock bool IsValidClient(int client)
{
	if (client <= 0) return false;
	if (client > MaxClients) return false;
	if (!IsClientConnected(client)) return false;
	return IsClientInGame(client);
}