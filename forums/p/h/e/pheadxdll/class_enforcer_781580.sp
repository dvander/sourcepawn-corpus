#pragma semicolon 1

#include <sourcemod>
#include <tf2>
#include <tf2_stocks>

#define PLUGIN_VERSION "0.2.1"

new Handle:c_Enabled;
new Handle:c_classBlue;
new Handle:c_classRed;
new Handle:c_adminOveride; 
new Handle:c_randomRounds;

new g_iRandomRed;
new g_iRandomBlue;

new TFClassType:g_iRedClass = TFClass_Unknown;
new TFClassType:g_iBlueClass = TFClass_Unknown;

new const String:g_strClassPrint[][] = {"", "Scout", "Sniper", "Soldier", "Demo", "Medic", "Heavy", "Pyro", "Spy", "Engineer"};

public Plugin:myinfo = 
{
	name = "Class Enforcer",
	author = "linux_lover",
	description = "Restricts RED/BLUE to one class.",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net"
}

public OnPluginStart()
{
	CreateConVar("sm_ce_version", PLUGIN_VERSION, "Class Enforcer Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	c_Enabled      = CreateConVar("sm_ce_enable", "0", "Enable/Disable Class Enforcer");
	c_classBlue    = CreateConVar("sm_ce_blue", "", "Forced class for the Blue team.");
	c_classRed     = CreateConVar("sm_ce_red", "", "Forced class for the Red team.");
	c_adminOveride = CreateConVar("sm_ce_admin", "0", "Enable/Disable admin immunity.");
	c_randomRounds = CreateConVar("sm_ce_random", "0", "Random forced class.");

	HookEvent("player_spawn", PlayerSpawn);
	HookEvent("teamplay_round_win", ChooseRandomClass);
	HookEvent("teamplay_round_stalemate", ChooseRandomClass);

	HookConVarChange(c_randomRounds, ConVarChange_Rounds);
	HookConVarChange(c_classBlue, ConVarChange_Class);
	HookConVarChange(c_classRed, ConVarChange_Class);
}

public OnMapStart()
{
	g_iRandomBlue = GetRandomInt(1, 9);
	g_iRandomRed = GetRandomInt(1, 9);
}

public OnConfigsExecuted()
{
	ParseClassStrings();
}

public ConVarChange_Rounds(Handle:convar, const String:oldValue[], const String:newValue[])
{
	g_iRandomBlue = GetRandomInt(1, 9);
	g_iRandomRed = GetRandomInt(1, 9);
}

public ConVarChange_Class(Handle:convar, const String:oldValue[], const String:newValue[])
{
	ParseClassStrings();
}

public ChooseRandomClass(Handle:event, const String:name[], bool:dontBroadcast)
{
	g_iRandomBlue = GetRandomInt(1, 9);
	g_iRandomRed = GetRandomInt(1, 9);
}

public PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{	
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(!GetConVarBool(c_Enabled) || IsFakeClient(client) || (GetConVarBool(c_adminOveride) && IsValidAdmin(client, "f"))) return;
	
	new TFTeam:team = TFTeam:GetClientTeam(client);
	if(GetConVarInt(c_randomRounds))
	{
		if(team == TFTeam_Red && TF2_GetPlayerClass(client) != TFClassType:g_iRandomRed)
		{
			TF2_SetPlayerClass(client, TFClassType:g_iRandomRed, false, true);
			PrintToChat(client, "\x04[!]\x01 Your team is restricted to %s.", g_strClassPrint[g_iRandomRed]);
			TF2_RespawnPlayer(client);
		}else if(team == TFTeam_Blue && TF2_GetPlayerClass(client) != TFClassType:g_iRandomBlue)
		{
			TF2_SetPlayerClass(client, TFClassType:g_iRandomBlue, false, true);
			PrintToChat(client, "\x04[!]\x01 Your team is restricted to %s.", g_strClassPrint[g_iRandomBlue]);
			TF2_RespawnPlayer(client);
		}
		
		return;
	}
	
	if(team == TFTeam_Red && g_iRedClass == TFClass_Unknown) return;
	if(team == TFTeam_Blue && g_iBlueClass == TFClass_Unknown) return;
	
	if(team == TFTeam_Red && TF2_GetPlayerClass(client) != g_iRedClass)
	{
		TF2_SetPlayerClass(client, g_iRedClass, false, true);
		PrintToChat(client, "\x04[!]\x01 Your team is restricted to %s.", g_strClassPrint[g_iRedClass]);
		TF2_RespawnPlayer(client);
	}else if(team == TFTeam_Blue && TF2_GetPlayerClass(client) != g_iBlueClass)
	{
		TF2_SetPlayerClass(client, g_iBlueClass, false, true);
		PrintToChat(client, "\x04[!]\x01 Your team is restricted to %s.", g_strClassPrint[g_iBlueClass]);
		TF2_RespawnPlayer(client);
	}
}

ParseClassStrings()
{
	new String:strRed[50];
	GetConVarString(c_classRed, strRed, sizeof(strRed));
	
	new String:strBlue[50];
	GetConVarString(c_classBlue, strBlue, sizeof(strBlue));
	
	g_iRedClass = TF2_GetClass(strRed);
	g_iBlueClass = TF2_GetClass(strBlue);
}

stock bool:IsValidAdmin(client, const String:flags[])
{
	new ibFlags = ReadFlagString(flags);
	if((GetUserFlagBits(client) & ibFlags) == ibFlags)
	{
		return true;
	}
	
	if(GetUserFlagBits(client) & ADMFLAG_ROOT)
	{
		return true;
	}
	
	return false;
}