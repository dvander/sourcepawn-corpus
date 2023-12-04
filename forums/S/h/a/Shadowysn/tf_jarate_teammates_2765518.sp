/*
 *
 * =============================================================================
 * SourceMod (C)2004-2007 AlliedModders LLC.  All rights reserved.
 * =============================================================================
 *
 * This program is free software you can redistribute it and/or modify it under
 * the terms of the GNU General Public License, version 3.0, as published by the
 * Free Software Foundation.
 * 
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY without even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
 * details.
 *
 * You should have received a copy of the GNU General Public License along with
 * this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * As a special exception, AlliedModders LLC gives you permission to link the
 * code of this program (as well as its derivative works) to "Half-Life 2," the
 * "Source Engine," the "SourcePawn JIT," and any Game MODs that run on software
 * by the Valve Corporation.  You must obey the GNU General Public License in
 * all respects for all other code used.  Additionally, AlliedModders LLC grants
 * this exception to all derivative works.  AlliedModders LLC defines further
 * exceptions, found in LICENSE.txt (as of this writing, version JULY-31-2007),
 * or <http://www.sourcemod.net/license.php>.
 *
 */
#define PLUGIN_NAME "[TF2] Jarate Teammates"
#define PLUGIN_AUTHOR "simoneaolson, Shadowysn (new-syntax)"
#define PLUGIN_DESC "Jarate teammates for fun!"
#define PLUGIN_VERSION "1.06"
#define PLUGIN_URL "https://forums.alliedmods.net/showpost.php?p=2765518&postcount=28"
#define PLUGIN_NAME_SHORT "Jarate Teammates"
#define PLUGIN_NAME_TECH "tf_jar_teammates"

#include <sourcemod>
#include <tf2_stocks>
#include <sdkhooks>

#pragma semicolon 1
#pragma newdecls required

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion ev = GetEngineVersion();
	if (ev == Engine_TF2)
	{
		return APLRes_Success;
	}
	strcopy(error, err_max, "Plugin only supports Team Fortress 2.");
	return APLRes_SilentFailure;
}

static ConVar Cv_PluginEnabled, Cv_Distance, Cv_Time, Cv_OnlyAdmins, Cv_Flag;
bool jarated[MAXPLAYERS+1], g_bEnabled, g_bOnlyAdmins;
int g_flag;
float g_distance, g_time;

public Plugin myinfo =
{
	name = PLUGIN_NAME,
	author = PLUGIN_AUTHOR,
	description = PLUGIN_DESC,
	version = PLUGIN_VERSION,
	url = PLUGIN_URL
}

public void OnPluginStart()
{	
	static char desc_str[64];
	Format(desc_str, sizeof(desc_str), "%s version.", PLUGIN_NAME_SHORT);
	static char cmd_str[64];
	Format(cmd_str, sizeof(cmd_str), "%s_version", PLUGIN_NAME_TECH);
	ConVar version_cvar = CreateConVar(cmd_str, PLUGIN_VERSION, desc_str, FCVAR_NOTIFY|FCVAR_REPLICATED|FCVAR_DONTRECORD);
	if (version_cvar != null)
		SetConVarString(version_cvar, PLUGIN_VERSION);
	
	Format(cmd_str, sizeof(cmd_str), "%s_enabled", PLUGIN_NAME_TECH);
	Cv_PluginEnabled = CreateConVar(cmd_str, "1", "Enable/Disable the plugin.", FCVAR_NONE, true, 0.0, true, 1.0);
	Cv_PluginEnabled.AddChangeHook(CC_JT_Enabled);
	Format(cmd_str, sizeof(cmd_str), "%s_distance", PLUGIN_NAME_TECH);
	Cv_Distance = CreateConVar(cmd_str, "750.0", "Max distance a teammate can be from jarate to be coated.", FCVAR_NONE, true, 300.0, true, 1000.0);
	Cv_Distance.AddChangeHook(CC_JT_Distance);
	Format(cmd_str, sizeof(cmd_str), "%s_time", PLUGIN_NAME_TECH);
	Cv_Time = CreateConVar(cmd_str, "7.0", "Time in seconds to cover teammate in jarate.", FCVAR_NONE, true, 3.0, true, 12.0);
	Cv_Time.AddChangeHook(CC_JT_Time);
	Format(cmd_str, sizeof(cmd_str), "%s_admins", PLUGIN_NAME_TECH);
	Cv_OnlyAdmins = CreateConVar(cmd_str, "0", "Set if only admins can jarate teammates.", FCVAR_NONE, true, 0.0, true, 1.0);
	Cv_OnlyAdmins.AddChangeHook(CC_JT_OnlyAdmins);
	Format(cmd_str, sizeof(cmd_str), "%s_flag", PLUGIN_NAME_TECH);
	Cv_Flag = CreateConVar(cmd_str, "0", "ASCII code of admin flag to use ex: 'c' = 99 (int)", FCVAR_NONE);
	Cv_Flag.AddChangeHook(CC_JT_Flag);
	
	AutoExecConfig(true, "tf_jar_teammates");
	SetCvars();
	
	HookEvent("player_hurt", PlayerHurt, EventHookMode_Pre);
}

void CC_JT_Enabled(ConVar convar, const char[] oldValue, const char[] newValue)	{ g_bEnabled =	convar.BoolValue;		}
void CC_JT_Distance(ConVar convar, const char[] oldValue, const char[] newValue)	{ g_distance =	convar.FloatValue;	}
void CC_JT_Time(ConVar convar, const char[] oldValue, const char[] newValue)		{ g_time =		convar.FloatValue;	}
void CC_JT_OnlyAdmins(ConVar convar, const char[] oldValue, const char[] newValue)	{ g_bOnlyAdmins =	convar.BoolValue;		}
void CC_JT_Flag(ConVar convar, const char[] oldValue, const char[] newValue)		{ g_flag =		convar.IntValue;		}
void SetCvars()
{
	CC_JT_Enabled(Cv_PluginEnabled, "", "");
	CC_JT_Distance(Cv_Distance, "", "");
	CC_JT_Time(Cv_Time, "", "");
	CC_JT_OnlyAdmins(Cv_OnlyAdmins, "", "");
	CC_JT_Flag(Cv_Flag, "", "");
}

public void OnClientPutInServer(int client)
{
    SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

public void OnMapStart()
{
	PrecacheSound("vo/spy_jaratehit01.wav", true);
	PrecacheSound("vo/spy_jaratehit02.wav", true);
	PrecacheSound("vo/spy_jaratehit03.wav", true);
	PrecacheSound("vo/spy_jaratehit04.wav", true);
	PrecacheSound("vo/spy_jaratehit05.wav", true);
	PrecacheSound("vo/spy_jaratehit06.wav", true);
	for (int i = 1; i < 40; ++i)
	{
		jarated[i] = false;
	}
}

Action PlayerHurt(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (jarated[client])
	{
		SetEventBool(event, "minicrit", false);
		return Plugin_Changed;
	}
	return Plugin_Continue;
}


public Action TF2_CalcIsAttackCritical(int client, int weapon, char[] weaponName, bool &result)
{
	if (g_bEnabled && strcmp(weaponName, "tf_weapon_jar", false) == 0)
	{
		CreateTimer(0.0, FindJar, client);
	}
	return Plugin_Continue;
}

Action FindJar(Handle timer, const int client)
{
	bool go;
	int index = -1; Handle pack;
	
	while ((index = FindEntityByClassname(index, "tf_weapon_jar")) != -1)
	{
		if (IsValidClient(client) && client == GetEntPropEnt(index, Prop_Send, "m_hOwner"))
		{
			// Check if only adminst can jarate teammates
			if (g_bOnlyAdmins)
			{
				if (CheckClientFlags(client)) go = true;
				else go = false;
			}
			else go = true;
			
			if (go)
			{
				if (GetEntProp(index, Prop_Send, "m_iState") == 2)
				{
					CreateTimer(0.1, FindJar, client);
				}
				else
				{
					CreateDataTimer(0.3, JaratePlayers, pack);
					WritePackCell(pack, client);
					WritePackCell(pack, index);
				}
			}
		}
	}
	return Plugin_Continue;
}


Action JaratePlayers(Handle timer, DataPack dataPack)
{
	float jarOrigin[3], throwerOrigin[3], clientOrigin[3]; float distance;
	ResetPack(dataPack);
	int client = ReadPackCell(dataPack), index = ReadPackCell(dataPack), team = GetClientTeam(client);
	
	GetEntPropVector(index, Prop_Send, "m_vecMaxs", jarOrigin);
	GetEntPropVector(client, Prop_Send, "m_vecOrigin", throwerOrigin);
	
	//Convert to absolute origin
	jarOrigin[0] += throwerOrigin[0];
	jarOrigin[1] += throwerOrigin[1];
	jarOrigin[2] += throwerOrigin[2];
	
	for (int i = 1; i < MaxClients; ++i)
	{
		if (client != i && IsValidClient(i) && GetClientTeam(i) == team)
		{	
			GetEntPropVector(i, Prop_Send, "m_vecOrigin", clientOrigin);
			
			distance = GetVectorDistance(jarOrigin, clientOrigin);
			if (distance <= g_distance)
			{
				jarated[i] = true;
				CreateTimer(g_time, jarateFalse);
				TF2_AddCondition(i, TFCond_Jarated, g_time);
				JaratedSpy(i);
			}
		}
	}
	return Plugin_Continue;
}

void JaratedSpy(int client)
{
	if (TF2_GetPlayerClass(client) == TFClass_Spy)
	{
		static char sound[64];
		int num = GetRandomInt(1, 6);
		Format(sound, 64, "vo/spy_jaratehit0%i.wav", num);
		EmitSoundToAll(sound, client, SNDCHAN_VOICE);
	}
}

Action jarateFalse(Handle timer, int client)
{ jarated[client] = false; return Plugin_Continue; }

bool CheckClientFlags(int client)
{
	AdminFlag aFlag;
	AdminId admin = GetUserAdmin(client);
	
	FindFlagByChar(g_flag, aFlag);
	
	if (GetAdminFlag(admin, aFlag)) return true;
	return false;
}


Action OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype)
{
	if (jarated[victim])
	{
		damage *= 0.65;
		return Plugin_Changed;
	}
	return Plugin_Continue;
}

bool IsValidClient(int client, bool replaycheck = true, bool isLoop = false)
{
	if ((isLoop || client > 0 && client <= MaxClients) && IsClientInGame(client) && 
	!GetEntProp(client, Prop_Send, "m_bIsCoaching")) // TF2
	{
		if (replaycheck)
		{
			if (IsClientSourceTV(client) || IsClientReplay(client)) return false;
		}
		return true;
	}
	return false;
}