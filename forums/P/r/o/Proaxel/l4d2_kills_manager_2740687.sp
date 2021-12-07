#include <sourcemod>
#include <sdkhooks>
#include <sdktools>
#pragma semicolon 1
#pragma newdecls required

#define TEAM_SURVIVOR	2
#define TEAM_INFECTED	3

#define FLAGS_SURVIVOR	1
#define FLAGS_INFECTED	2
#define FLAGS_ALIVE		4
#define FLAGS_DEAD		8
#define FLAGS_BOT		16
#define FLAGS_HUMAN		32

#define FL_WITCH_L4D2	(1<<7)
#define FL_TANK_L4D2	(1<<8)

#define MAXENTITIES		2048

#define PLUGIN_VERSION	"1.2.8"

// ConVar Handle
ConVar g_hCvar_kmgr_enable;
ConVar g_hCvar_kmgr_count_mode;
ConVar g_hCvar_kmgr_prevent_overdamage;
ConVar g_hCvar_kmgr_include_ci;
ConVar g_hCvar_kmgr_stats_show_type;
ConVar g_hCvar_kmgr_stats_show_ci;
ConVar g_hCvar_kmgr_stats_max;
ConVar g_hCvar_kmgr_stats_ignore_bots_damage;

// Variables
int g_iCvar_kmgr_enable;
int g_iCvar_kmgr_count_mode;
int g_iCvar_kmgr_prevent_overdamage;
int g_iCvar_kmgr_include_ci;
int g_iCvar_kmgr_stats_show_type;
int g_iCvar_kmgr_stats_show_ci;
int g_iCvar_kmgr_stats_max;
int g_iCvar_kmgr_stats_ignore_bots_damage;

int g_victimData[MAXENTITIES+1][MAXPLAYERS+1][2];
ArrayList g_hBaseEventsPropArr[MAXPLAYERS+1][MAXPLAYERS+1];

// Const
const int c_mDamage = 0;
const int c_mAttacker = 1;
const int c_mHitgroup = 0;
const int c_mDamagetype = 1;
// ====================================================================================================
//					PLUGIN INFO / START / END
// ====================================================================================================
public Plugin myinfo = 
{
	name = "L4D Kills manager", 
	author = "Axel Juan Nieves, Zheldorg, Proaxel (Headshot Stats Fix)", 
	description = "Sets the real killer of a special infected, based on who inflicted him most damage, instead of last shot.", 
	version = PLUGIN_VERSION, 
	url = "https://forums.alliedmods.net/showthread.php?p=2636372"
};

public void OnPluginStart()
{
	// ConVars
	CreateConVar("l4d2_killsmgr_version", PLUGIN_VERSION, "", FCVAR_DONTRECORD);
	g_hCvar_kmgr_enable =					CreateConVar("l4d2_killsmgr_enable", "1", "Enable/Disable this plugin.", 0);
	g_hCvar_kmgr_count_mode =				CreateConVar("l4d2_killsmgr_count_mode", "1", "Kills count mode. 0:last-shoot based(game default), 1:damage based.", 0);
	g_hCvar_kmgr_prevent_overdamage =		CreateConVar("l4d2_killsmgr_prevent_overdamage", "1", "Prevents last shooter stealing your kill if last shoot caused most damage than infected's remaining health. Recomended to enable this.", 0);
	g_hCvar_kmgr_include_ci =				CreateConVar("l4d2_killsmgr_include_bosses", "510", "Which L4D2's bosses will be affected by this plugin? (independent from statistics) 2=SMOKER, 4=BOOMER, 8=HUNTER, 16=SPITTER, 32=JOCKEY, 64=CHARGER, 128=WITCH, 256=TANK, 510=ALL", 0);
	g_hCvar_kmgr_stats_show_type =			CreateConVar("l4d2_killsmgr_stats_show_type", "3", "Type of statistics notification,0=Do'n show statistics 1=CenterText, 2=HintBox, 3=Chat", 0, true, 0.0, true, 3.0);
	g_hCvar_kmgr_stats_show_ci =			CreateConVar("l4d2_killsmgr_stats_show_bosses", "510", "Which L4D2's bosses will show statistics. 2=SMOKER, 4=BOOMER, 8=HUNTER, 16=SPITTER, 32=JOCKEY, 64=CHARGER, 128=WITCH, 256=TANK, 510=ALL", 0);
	g_hCvar_kmgr_stats_max =				CreateConVar("l4d2_killsmgr_stats_max", "0", "Maximum amount of attackers shown in each statistic message. 0=All players", 0);
	g_hCvar_kmgr_stats_ignore_bots_damage =	CreateConVar("l4d2_killsmgr_stats_ignore_bots_damage", "0", "Exclude damage done by bots? (bosses can still receive damage amd die) 0=Disabled(dont ignore), 1:Ignore on statistics, 2=Ignore on scoreboard, 3=ignored on both statistics and scoreboard", 0);

	g_hCvar_kmgr_enable.AddChangeHook(ConVarChanged_Cvars);
	g_hCvar_kmgr_count_mode.AddChangeHook(ConVarChanged_Cvars);
	g_hCvar_kmgr_prevent_overdamage.AddChangeHook(ConVarChanged_Cvars);
	g_hCvar_kmgr_include_ci.AddChangeHook(ConVarChanged_Cvars);
	g_hCvar_kmgr_stats_show_type.AddChangeHook(ConVarChanged_Cvars);
	g_hCvar_kmgr_stats_show_ci.AddChangeHook(ConVarChanged_Cvars);
	g_hCvar_kmgr_stats_max.AddChangeHook(ConVarChanged_Cvars);
	g_hCvar_kmgr_stats_ignore_bots_damage.AddChangeHook(ConVarChanged_Cvars);

	// Config File
	AutoExecConfig(true, "l4d2_killsmgr");

	// Read Plugin ConVar
	GetCvars();

	HookEvent("witch_spawn", event_witch_spawn, EventHookMode_Pre);
	HookEvent("player_death", event_player_death, EventHookMode_Pre); //hook special infected deaths
	HookEvent("witch_killed", event_witch_killed, EventHookMode_Pre);
	HookEvent("round_start", round_reset, EventHookMode_PostNoCopy);
	HookEvent("round_end", round_reset, EventHookMode_PostNoCopy);
}

public void ConVarChanged_Cvars(ConVar convar, const char[] oldValue, const char[] newValue)
{
	GetCvars();
}

stock void GetCvars()
{
	g_iCvar_kmgr_enable =						g_hCvar_kmgr_enable.IntValue;
	g_iCvar_kmgr_count_mode =					g_hCvar_kmgr_count_mode.IntValue;
	g_iCvar_kmgr_prevent_overdamage = 			g_hCvar_kmgr_prevent_overdamage.IntValue;
	g_iCvar_kmgr_include_ci =					g_hCvar_kmgr_include_ci.IntValue;
	g_iCvar_kmgr_stats_show_type = 				g_hCvar_kmgr_stats_show_type.IntValue;
	g_iCvar_kmgr_stats_show_ci = 				g_hCvar_kmgr_stats_show_ci.IntValue;
	g_iCvar_kmgr_stats_max =					g_hCvar_kmgr_stats_max.IntValue;
	g_iCvar_kmgr_stats_ignore_bots_damage =		g_hCvar_kmgr_stats_ignore_bots_damage.IntValue;
}

public void OnClientPutInServer(int client)
{
	//this is not a convenient place to check if plugin is enabled...
	SDKHook(client, SDKHook_OnTakeDamageAlive, OnTakeDamage);
}

public Action event_witch_spawn(Event event, char[] event_name, bool dontBroadcast) // Pre HookEvent
{
	if (!g_iCvar_kmgr_enable) return Plugin_Continue;	
	int witch = event.GetInt("witchid");
	if (IsWitch(witch))
		SDKHook(witch, SDKHook_OnTakeDamageAlive, OnWitchTakeDamage);
	return Plugin_Continue;
}

public Action OnWitchTakeDamage(int witch, int &attacker, int &inflictor, float &damage, int &damagetype) // SDKHook
{
	if (!g_iCvar_kmgr_enable) 									return Plugin_Continue;
	if (!IsWitch(witch)) 										return Plugin_Continue;
	if (!IsValidClientInGame(attacker)) 						return Plugin_Continue;
	if (GetClientTeam(attacker)!= TEAM_SURVIVOR) 				return Plugin_Continue;
	if (damagetype == DMG_BURN || damagetype == DMG_SLOWBURN)	return Plugin_Continue;
	if (g_iCvar_kmgr_include_ci & FL_WITCH_L4D2 == 0) 			return Plugin_Continue;  //check if witch is not allowed in l4d2_killsmgr_include_bosses, then collect damage statistics but don't change event...
	
	int pre_health = GetEntProp(witch, Prop_Data, "m_iHealth");
	if (pre_health <= 0)										return Plugin_Handled;
	
	bool bEventChanged = false;
	if (g_iCvar_kmgr_prevent_overdamage) // For the witch, this check does not make much sense, but it removes the extra damage from the final statistics.
	{
		if (float(pre_health) - damage < 0)
		{
			damage = float(pre_health);
			bEventChanged = true;
		}
	}	
	if (IsFakeClient(attacker))
	{
		//storing data to statistics...
		if  (g_iCvar_kmgr_stats_ignore_bots_damage == 0 || g_iCvar_kmgr_stats_ignore_bots_damage == 2) //0: allow statistics, allow scoreboard
		{
			g_victimData[witch][attacker][c_mDamage] += RoundToCeil(damage);
			g_victimData[witch][attacker][c_mAttacker] = attacker;
		}
		//don't add damage to witch to scoreboard statistics...
		if (g_iCvar_kmgr_stats_ignore_bots_damage == 3 || g_iCvar_kmgr_stats_ignore_bots_damage == 2) //3: no statistics, no scoreboard
		{
			int damage2witch = GetEntProp(attacker, Prop_Send, "m_checkpointDamageToWitch");
			if (damage2witch < 0)
				damage2witch = 0;
			damage2witch -= RoundToCeil(damage);
			SetEntProp(attacker, Prop_Send, "m_checkpointDamageToWitch",  damage2witch);
		}
	}
	else
	{
		g_victimData[witch][attacker][c_mDamage] += RoundToCeil(damage);
		g_victimData[witch][attacker][c_mAttacker] = attacker;
	}
	if (bEventChanged)
		return Plugin_Changed;
	else
		return Plugin_Continue;
}

public Action event_witch_killed(Event event, char[] event_name, bool dontBroadcast) // Pre HookEvent
{
	if (!g_iCvar_kmgr_enable) return Plugin_Continue;
	
	int victim = event.GetInt("witchid");
	int attacker = GetClientOfUserId(event.GetInt("userid"));
	
	if (IsWitch(victim)) 
	{	
		if (g_iCvar_kmgr_count_mode == 0 || g_iCvar_kmgr_include_ci & FL_WITCH_L4D2 == 0) 
		{
			if (g_iCvar_kmgr_stats_show_type)
			{
				sortDamagers(victim);
				show_statisctics(victim);
			}
		}
		else
		{
			int new_killer = sortDamagers(victim);
			
			if (IsValidClientInGame(new_killer))
			{
				if (IsValidClientInGame(attacker))
				{
					SetEntProp(attacker, Prop_Send, "m_checkpointZombieKills", GetEntProp(attacker, Prop_Send, "m_checkpointZombieKills") - 1); // Check point
					SetEntProp(attacker, Prop_Send, "m_missionZombieKills", GetEntProp(attacker, Prop_Send, "m_missionZombieKills") - 1); // Mission total
				}
				SetEntProp(new_killer, Prop_Send, "m_checkpointZombieKills", GetEntProp(new_killer, Prop_Send, "m_checkpointZombieKills") + 1); // Check point
				SetEntProp(new_killer, Prop_Send, "m_missionZombieKills", GetEntProp(new_killer, Prop_Send, "m_missionZombieKills") + 1); // Mission total
			}
			if (g_iCvar_kmgr_stats_show_type)
				show_statisctics(victim);
		}
	}
	//cleaning operations...
	cleanVictimArray(victim);
	return Plugin_Continue;
}

public Action OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &ammotype, int hitbox, int hitgroup) // SDKHook
{
	if (!g_iCvar_kmgr_enable) 						return Plugin_Continue;
	if (!IsValidClientInGame(victim))				return Plugin_Continue;
	if (!IsValidClientInGame(attacker))				return Plugin_Continue;
	if (GetClientTeam(victim)!= TEAM_INFECTED)		return Plugin_Continue;
	if (GetClientTeam(attacker) == TEAM_INFECTED)	return Plugin_Continue; //don't count infected's friendly fire.	
	if (attacker == victim || inflictor == victim)	return Plugin_Continue; //don't count self-inflicted damage.	
	int pre_health = GetClientHealth(victim);
	if (pre_health <= 0)							return Plugin_Handled;
	bool bVictimIsTank = !!((1 << GetEntProp(victim, Prop_Send, "m_zombieClass")) & FL_TANK_L4D2);
	if (bVictimIsTank) 
	{
		//ignore flame damage:
		if (damagetype == DMG_BURN)								return Plugin_Continue;	
		//ignore tank's incapacitated damage (dying animation):
		if (GetEntProp(victim, Prop_Send, "m_isIncapacitated")) return Plugin_Continue;
	}
	//we need to create based on current damage data, which will replace death event...	
	char weaponname[32];
	GetClientWeapon(attacker, weaponname, sizeof(weaponname));
	ArrayList hEventPropsArr = null;
	if (g_hBaseEventsPropArr[victim][attacker] == null)
	{
		hEventPropsArr = new ArrayList(ByteCountToCells(32));
		hEventPropsArr.PushString(weaponname);
		int iBuffPropArr[2];
		iBuffPropArr[0] = hitgroup;
		iBuffPropArr[1] = damagetype;
		hEventPropsArr.PushArray(iBuffPropArr, 2);
	}
	else
	{
		hEventPropsArr = g_hBaseEventsPropArr[victim][attacker];
		hEventPropsArr.SetString(0, weaponname);
		int iBuffPropArr[2];
		iBuffPropArr[0] = hitgroup;
		iBuffPropArr[1] = damagetype;
		hEventPropsArr.SetArray(1, iBuffPropArr, 2);
	}

	bool bEventChanged = false;
	if (g_iCvar_kmgr_prevent_overdamage)
	{
		if (float(pre_health) - damage < 0)
		{
			damage = float(pre_health);
			bEventChanged = true;
		}
	}
	if (IsFakeClient(attacker)) //damage by bots
	{
		//storing data to statistics...
		if (g_iCvar_kmgr_stats_ignore_bots_damage == 0 || g_iCvar_kmgr_stats_ignore_bots_damage == 2) //0: allow statistics, allow scoreboard
		{
			g_victimData[victim][attacker][c_mDamage] += RoundToCeil(damage); //count damage
			g_victimData[victim][attacker][c_mAttacker] = attacker; //userid must be stored as value because sorting
			g_hBaseEventsPropArr[victim][attacker] = hEventPropsArr;
		}	
		if (bVictimIsTank && (g_iCvar_kmgr_stats_ignore_bots_damage == 3 || g_iCvar_kmgr_stats_ignore_bots_damage == 2)) //3: no statistics, no scoreboard (only tank-victim)
		{
			//don't add bot's damage to tank to scoreboard...
			int damage2tank = GetEntProp(attacker, Prop_Send, "m_checkpointDamageToTank");
			if (damage2tank<0)
				damage2tank = 0;
			damage2tank -= RoundToCeil(damage);
			SetEntProp(attacker, Prop_Send, "m_checkpointDamageToTank",  damage2tank);
		}
	}
	else //damage by human players
	{
		g_victimData[victim][attacker][c_mDamage] += RoundToCeil(damage); //always count human damage
		g_victimData[victim][attacker][c_mAttacker] = attacker; //userid must be stored as value because sorting
		g_hBaseEventsPropArr[victim][attacker] = hEventPropsArr; //we need this ArrayList to store this event's full data...
	}
	if (bEventChanged)
		return Plugin_Changed;
	else
		return Plugin_Continue;
}

public Action event_player_death(Event event, char[] event_name, bool dontBroadcast) // Pre HookEvent
{
	if (!g_iCvar_kmgr_enable) return Plugin_Continue;
	int victim = GetClientOfUserId(event.GetInt("userid"));
	if (IsValidClientInGame(victim))
	{
		//check if infected is allowed in l4d2_killsmgr_include_bosses...
		if (g_iCvar_kmgr_count_mode == 0 || g_iCvar_kmgr_include_ci & (1 << GetEntProp(victim, Prop_Send, "m_zombieClass")) == 0) 
		{
			if (g_iCvar_kmgr_stats_show_type)
			{
				sortDamagers(victim);
				show_statisctics(victim);
			}
		}
		else
		{
			int new_killer = sortDamagers(victim);
			int org_killer = GetClientOfUserId(event.GetInt("attacker"));
			if (IsValidClientInGame(new_killer))
			{
				char weaponname[32], attackerName[64];
				int PropArray[2];
				GetClientName(new_killer, attackerName, sizeof(attackerName));
				g_hBaseEventsPropArr[victim][new_killer].GetString(0, weaponname, sizeof(weaponname));
				g_hBaseEventsPropArr[victim][new_killer].GetArray(1, PropArray, 2);
				
				//Proaxel: attempted headshot fix. Force headshot to true if the killing blow was a headshot and the person that got the killing blow is the same person that did the most damage, 
				//if not then do it however the original author was doing it
				bool topDmgHeadshot = false;
				if(event.GetBool("headshot") && IsValidClientInGame(org_killer) && org_killer == new_killer)
					topDmgHeadshot = true;
				
				//Modifying death event...
				event.SetInt("attacker", GetClientUserId(new_killer));
				event.SetString("attackername", attackerName);
				event.SetInt("attackerentid", 0);
				event.SetString("weapon", weaponname);
				//Proaxel: Determine Headshot from earlier
				if(topDmgHeadshot)
					event.SetBool("headshot", true);
				else
					event.SetBool("headshot", (PropArray[c_mHitgroup] == 1)?true:false);
				event.SetBool("attackerisbot", IsFakeClient(new_killer));
				event.SetBool("abort", false);
				event.SetInt("type", PropArray[c_mDamagetype]);
			}
			if (g_iCvar_kmgr_stats_show_type)
			{
				show_statisctics(victim);
			}
			//cleaning operations...
			cleanArrEventsPropArr(victim);
			cleanVictimArray(victim);
			return Plugin_Changed; //says event edited
		}
	}
	//cleaning operations...
	cleanArrEventsPropArr(victim);
	cleanVictimArray(victim);
	return Plugin_Continue;
}

stock void show_statisctics(int victim)
{
	char victimName[64], attackerName[64];
	char statisticsMsg[2048] = "";	
	int count;

	if (IsWitch(victim))
	{
		if (g_iCvar_kmgr_stats_show_ci & FL_WITCH_L4D2 == 0 ) return;
		FormatEx(statisticsMsg, sizeof(statisticsMsg), "Witch:");
	}
	else
	{
		if (g_iCvar_kmgr_stats_show_ci & (1 << GetEntProp(victim, Prop_Send, "m_zombieClass")) == 0) return;	
		GetClientName(victim, victimName, sizeof(victimName));
		FormatEx(statisticsMsg, sizeof(statisticsMsg), "%s:", victimName);
	}

	for (int i=0; i<MAXPLAYERS; i++)
	{
		if (g_victimData[victim][i][c_mAttacker] == 0) break;	

		count++;
		//appling amount limit specified on g_iCvar_kmgr_stats_max...
		if ( g_iCvar_kmgr_stats_max > 0 )
		{
			if (count > g_iCvar_kmgr_stats_max) break;	
		}
		if (IsClientInGame(g_victimData[victim][i][c_mAttacker]))
		{
			GetClientName(g_victimData[victim][i][c_mAttacker], attackerName, sizeof(attackerName));
			//first (higher) attacker in the list...
			if (count == 1)
			{
				//print higher attacker in special color:
				FormatEx(statisticsMsg, sizeof(statisticsMsg), "%s %s(%i)", statisticsMsg, attackerName, g_victimData[victim][i][c_mDamage]);
			}
			//other attackers...
			else
			{
				//print attacker in normal color:
				FormatEx(statisticsMsg, sizeof(statisticsMsg), "%s, %s(%i)", statisticsMsg, attackerName, g_victimData[victim][i][c_mDamage]);
			}
		}
	}
	if (count)
	{
		switch(g_iCvar_kmgr_stats_show_type) //show statistics message:
		{
			case 1:
				PrintCenterTextAll(statisticsMsg);
			case 2:
				PrintHintTextToAll(statisticsMsg);
			default:
				PrintToChatAll(statisticsMsg);
		}
	}
}

stock int sortDamagers(int victim)
{	
	SortCustom2D(g_victimData[victim], MAXPLAYERS+1, SortByDamageDesc);
	return g_victimData[victim][0][c_mAttacker]; //who did the most damage
}

public int SortByDamageDesc(int[] a, int[] b, int[][] array, Handle data)
{
	if (a[0] > b[0]) 
        return -1;
	return  a[0] < b[0];
}

public void round_reset(Handle event, char[] event_name, bool dontBroadcast)
{
	// reset DataVars
	for (int i=1; i<=MAXPLAYERS; i++)
	{	
		cleanArrEventsPropArr(i); //cleaning events array...
	}
	for (int i=1; i<=MAXENTITIES; i++)
	{	
		cleanVictimArray(i); //cleaning operations...
	}
}

stock void cleanArrEventsPropArr(int victim)
{
	for (int i=1; i<=MAXPLAYERS; i++)
	{
		if (g_hBaseEventsPropArr[victim][i])
		{
			delete g_hBaseEventsPropArr[victim][i];
		}
	}
}

stock void cleanVictimArray(int victim)
{
	for (int i=0; i<=MAXPLAYERS; i++)
	{
		g_victimData[victim][i][c_mDamage] = 0;
		g_victimData[victim][i][c_mAttacker] = 0;
	}
}

stock int IsValidClientIndex(int index)
{
	if (index>0 && index<=MaxClients)
	{
		return 1;
	}
	return 0;
}

stock int IsValidClientInGame(int client)
{
	if (IsValidClientIndex(client))
	{
		if (IsClientInGame(client))
			return 1;
	}
	return 0;
}

stock bool IsWitch(int witch)
{
	if ((witch > 0) && IsValidEdict(witch) && IsValidEntity(witch))
	{
		char classname[32];
		GetEdictClassname(witch, classname, sizeof(classname));
		if (StrEqual(classname, "witch"))
		{
			return true;
		}
	}
	return false;
}