#include <sourcemod>
#include <sdkhooks>
#include <sdktools>
#pragma semicolon 1
#pragma newdecls required

//GAMEMODE constants for future use:
//#define GAMEMODE_COOP		1
//#define GAMEMODE_VERSUS		2
//#define GAMEMODE_SURVIVAL	3

#define TEAM_SURVIVOR	2
#define TEAM_INFECTED	3

#define FLAGS_SURVIVOR	1
#define FLAGS_INFECTED	2
#define FLAGS_ALIVE		4
#define FLAGS_DEAD		8
#define FLAGS_BOT		16
#define FLAGS_HUMAN		32

#define FL_WITCH_L4D1	(1<<4)
#define FL_WITCH_L4D2	(1<<7)
#define FL_TANK_L4D1	(1<<5)
#define FL_TANK_L4D2	(1<<8)

#define MAXENTITIES		2048

#define PLUGIN_VERSION	"1.2.0"

int left4dead;
Handle l4d_killsmgr_enable;
Handle l4d_killsmgr_include_bosses;
Handle l4d_killsmgr_count_mode;
Handle l4d_killsmgr_stats_enable;
Handle l4d_killsmgr_stats_max;
Handle l4d_killsmgr_stats_bosses;
Handle l4d_killsmgr_stats_ignore_bots_damage;
Handle l4d_killsmgr_stats_type;
Handle l4d_killsmgr_prevent_overdamage;

int g_victimData[MAXPLAYERS+1][MAXPLAYERS+1][2];
int g_witchesData[MAXENTITIES+1][MAXPLAYERS+1][2];
Handle g_damageEvents[MAXPLAYERS+1][MAXPLAYERS+1];

public Plugin myinfo = 
{
	name = "L4D Kills manager", 
	author = "Axel Juan Nieves", 
	description = "Sets the real killer of a special infected, based on who inflicted him most damage, instead of last shot.", 
	version = PLUGIN_VERSION, 
	url = "https://forums.alliedmods.net/showthread.php?p=2636372"
};

public void OnPluginStart()
{
	//Require Left 4 Dead 1/2:
	char GameName[64];
	GetGameFolderName(GameName, sizeof(GameName));
	if ( StrEqual(GameName, "left4dead", false) )
		left4dead = 1;
	else if ( StrEqual(GameName, "left4dead2", false) )
		left4dead = 2;
	else
		SetFailState("Plugin supports Left 4 Dead 1/2 only.");
	
	CreateConVar("l4d_killsmgr_version", PLUGIN_VERSION, "", FCVAR_DONTRECORD);
	l4d_killsmgr_enable = CreateConVar("l4d_killsmgr_enable", "1", "Enable/Disable this plugin.", 0);
	l4d_killsmgr_count_mode = CreateConVar("l4d_killsmgr_count_mode", "1", "Kills count mode. 0:last-shoot based(game default), 1:damage based.", 0);
	l4d_killsmgr_stats_ignore_bots_damage = CreateConVar("l4d_killsmgr_stats_ignore_bots_damage", "0", "Exclude damage done by bots? (bosses can still receive damage amd die) 0=Disabled(dont ignore), 1:Ignore on statistics, 2=Ignore on scoreboard, 3=ignored on both statistics and scoreboard", 0);
	if (left4dead==1)
		l4d_killsmgr_include_bosses = CreateConVar("l4d_killsmgr_include_bosses_l4d1", "62", "Which L4D1's bosses will be affected by this plugin? (independent from this plugin) 2=SMOKER, 4=BOOMER, 8=HUNTER, 16=WITCH, 32=TANK, 62=ALL", 0);
	else
		l4d_killsmgr_include_bosses = CreateConVar("l4d_killsmgr_include_bosses_l4d2", "510", "Which L4D2's bosses will be affected by this plugin? (independent from statistics) 2=SMOKER, 4=BOOMER, 8=HUNTER, 16=SPITTER, 32=JOCKEY, 64=CHARGER, 128=WITCH, 256=TANK, 510=ALL", 0);
	
	l4d_killsmgr_stats_enable = CreateConVar("l4d_killsmgr_stats_enable", "1", "Shows damage statistics.", 0);
	l4d_killsmgr_stats_max = CreateConVar("l4d_killsmgr_stats_max", "0", "Maximum amount of attackers shown in each statistic message. 0=All players", 0);
	l4d_killsmgr_stats_type = CreateConVar("l4d_killsmgr_stats_type", "3", "Type of statistics notification, 1=CenterText, 2=HintBox, 3=Chat", 0, true, 1.0, true, 3.0);
	if (left4dead==1)
		l4d_killsmgr_stats_bosses = CreateConVar("l4d_killsmgr_stats_bosses_l4d1", "62", "Which L4D1's bosses will show statistics. 2=SMOKER, 4=BOOMER, 8=HUNTER, 16=WITCH, 32=TANK, 62=ALL", 0);
	else
		l4d_killsmgr_stats_bosses = CreateConVar("l4d_killsmgr_stats_bosses_l4d2", "510", "Which L4D2's bosses will show statistics. 2=SMOKER, 4=BOOMER, 8=HUNTER, 16=SPITTER, 32=JOCKEY, 64=CHARGER, 128=WITCH, 256=TANK, 510=ALL", 0);
	l4d_killsmgr_prevent_overdamage = CreateConVar("l4d_killsmgr_prevent_overdamage", "1", "Prevents last shooter stealing your kill if last shoot caused most damage than infected's remaining health. Recomended to enable this.", 0);
	
	//------------------------------------------------------------------------------------------------------------------------------------------------------------------
	
	//------------------------------------------------------------------------------------------------------------------------------------------------------------------
	
	//------------------------------------------------------------------------------------------------------------------------------------------------------------------
	
	AutoExecConfig(true, "l4d_killsmgr");
	HookEvent("player_death", event_player_death, EventHookMode_Pre); //hook special infected deaths
	
	HookEvent("witch_killed", event_witch_killed, EventHookMode_Pre);
	HookEvent("round_start", round_reset, EventHookMode_PostNoCopy);
	HookEvent("round_end", round_reset, EventHookMode_PostNoCopy);
	HookEvent("player_transitioned", round_reset, EventHookMode_PostNoCopy);
}

public void OnClientPutInServer(int client)
{
	//this is not a convenient place to check if plugin is enabled...
	SDKHook(client, SDKHook_OnTakeDamageAlive, OnTakeDamage);
}

public void OnEntityCreated(int entity, const char[] classname)
{
	if (!GetConVarInt(l4d_killsmgr_enable)) return;
	if	( !IsValidEdict(entity) ) return;
	char modelname[255];
	GetEdictClassname(entity, modelname, 64);
	if  ( StrEqual(classname, "witch") )
		SDKHook(entity, SDKHook_OnTakeDamageAlive, OnWitchTakeDamage);
}

public Action OnWitchTakeDamage(int witch, int &attacker, int &inflictor, float &damage, int &damagetype, int &ammotype, int hitbox, int hitgroup)
{
	if ( !GetConVarInt(l4d_killsmgr_enable) ) return Plugin_Continue;
	if ( !IsWitch(witch) ) return Plugin_Continue;
	if ( !IsValidClientInGame(attacker) ) return Plugin_Continue;
	if ( GetClientTeam(attacker)!=TEAM_SURVIVOR ) return Plugin_Continue;
	if ( damagetype==DMG_BURN || damagetype==DMG_SLOWBURN ) return Plugin_Continue;
	
	//check if witch is not allowed in l4d_killsmgr_include_bosses_l4dx, then collect damage statistics but don't change event...
	if (left4dead==1 && GetConVarInt(l4d_killsmgr_include_bosses)&FL_WITCH_L4D1==0)
	{
		return Plugin_Continue;
	}
	else if (left4dead==2 && GetConVarInt(l4d_killsmgr_include_bosses)&FL_WITCH_L4D2==0)
	{
		return Plugin_Continue;
	}
	
	if ( IsFakeClient(attacker) )
	{
		int ignoreBotsDamage = GetConVarInt(l4d_killsmgr_stats_ignore_bots_damage);
		//storing data to statistics...
		if  (ignoreBotsDamage==0||ignoreBotsDamage==2) //0: allow statistics, allow scoreboard
		{
			g_witchesData[witch][attacker][0] += RoundToCeil(damage);
			g_witchesData[witch][attacker][1] = attacker;
		}
		else if ( ignoreBotsDamage==1 ) //1: disallow statistics, allow scoreboard
		{}
		
		if (ignoreBotsDamage==3||ignoreBotsDamage==2) //3: no statistics, no scoreboard
		{
			//don't add damage to witch to scoreboard statistics...
			int damage2witch = GetEntProp(attacker, Prop_Send, "m_checkpointDamageToWitch");
			if (damage2witch<0)
				damage2witch = 0;
			damage2witch -= RoundToCeil(damage);
			SetEntProp(attacker, Prop_Send, "m_checkpointDamageToWitch",  damage2witch);
		}
	}
	else
	{
		g_witchesData[witch][attacker][0] += RoundToCeil(damage);
		g_witchesData[witch][attacker][1] = attacker;
	}
	
	return Plugin_Continue;
}

public Action event_witch_killed(Handle event, char[] event_name, bool dontBroadcast)
{
	if (!GetConVarInt(l4d_killsmgr_enable)) return Plugin_Continue;
	int victim = GetEventInt(event, "witchid");
	int attacker = GetClientOfUserId(GetEventInt(event, "userid"));
	int witchFlag = (left4dead==1) ? FL_WITCH_L4D1 : FL_WITCH_L4D2;
	
	if ( !IsWitch(victim) ) 
	{
		//cleaning operations...
		cleanVictimArray(victim);
		return Plugin_Continue;
	}
	
	if ( GetConVarInt(l4d_killsmgr_count_mode)==0 || GetConVarInt(l4d_killsmgr_include_bosses)&witchFlag==0 ) 
	{
		//now, statistics will be shown in mode "0" too (if configured to do so).
		if (GetConVarInt(l4d_killsmgr_stats_enable))
		{
			sortDamagers(victim);
			show_statisctics(victim);
		}
		cleanVictimArray(victim);
		cleanDamageEvents(victim);
		return Plugin_Continue;
	}
	
	int new_killer = sortDamagers(victim);
	
	if (IsValidClientInGame(new_killer))
	{
		if (GetConVarInt(l4d_killsmgr_stats_enable))
			show_statisctics(victim);
		
		//OBSOLETE. We cannot edit this event like "player_death".
		//SetEventInt(event, "userid", GetClientUserId(new_killer));
		//SetEventInt(event, "witchid", victim);
		//SetEventBool(event, "oneshot", true);
		//FireEvent(event);
		//AcceptEntityInput(victim, "Kill"); //remove witch
		
		//Alternative method:
		//reduce real killer's score by 1...
		if (IsValidClientInGame(attacker))
		{
			SetEntProp(attacker, Prop_Send, "m_checkpointZombieKills", GetEntProp(attacker, Prop_Send, "m_checkpointZombieKills") - 1); // Check point
			//SetEntProp(attacker, Prop_Send, "m_checkpointPZKills", GetEntProp(attacker, Prop_Send, "m_checkpointPZKills") - 1); // Check point
			SetEntProp(attacker, Prop_Send, "m_missionZombieKills", GetEntProp(attacker, Prop_Send, "m_missionZombieKills") - 1); // Mission total
		}
		
		//and increase newkiller's by 1...
		SetEntProp(new_killer, Prop_Send, "m_checkpointZombieKills", GetEntProp(new_killer, Prop_Send, "m_checkpointZombieKills") + 1); // Check point
		//SetEntProp(new_killer, Prop_Send, "m_checkpointPZKills", GetEntProp(new_killer, Prop_Send, "m_checkpointPZKills") + 1); // Check point
		SetEntProp(new_killer, Prop_Send, "m_missionZombieKills", GetEntProp(new_killer, Prop_Send, "m_missionZombieKills") + 1); // Mission total

		//cleaning operations...
		cleanVictimArray(victim);
		return Plugin_Continue;
	}
	else //SOME UNEXPECTED OCCURRED...
	{
		/*if (!IsValidClientIndex(new_killer))
		{
			#if DEBUG
				PrintToChatAll("ERROR: event_witch_killed::!IsValidClientIndex(new_killer=%i)", new_killer);
			#endif
		}
		#if DEBUG
			PrintToChatAll("ERROR: event_witch_killed::IsValidClientInGame(new_killer=%i)", new_killer);
		#endif*/
	}
	//cleaning operations...
	cleanVictimArray(victim);
	return Plugin_Continue;
}

stock int sortDamagers(int victim)
{	
	if (IsWitch(victim))
		SortCustom2D(g_witchesData[victim], MAXPLAYERS+1, SortByDamageDesc);
	else
		SortCustom2D(g_victimData[victim], MAXPLAYERS+1, SortByDamageDesc);
	
	/*#if DEBUG
		PrintToChatAll("SortDamagers(victim=%i) = %i", victim, g_victimData[victim][0][1]);
		PrintToServer("-------------------------------------------------------------------");
		PrintToServer("RESULT AFTER SORTING:");
		PrintToServer("-------------------------------------------------------------------");
		PrintToChatAll("SortDamagers(victim=%i) = %i", victim, g_victimData[victim][0][1]);
		for (int i=0; i<=MAXPLAYERS; i++)
		{
			PrintToServer("g_victimData[victim=%i][i=%i][0] = %i", victim, i, g_victimData[victim][i][0]);
			PrintToServer("g_victimData[victim=%i][i=%i][1] = %i", victim, i, g_victimData[victim][i][1]);
			PrintToServer("-------------------------------------------------------------------");
		}
	#endif*/
	//so we will return the higher attacker id...
	if (IsWitch(victim))
		return g_witchesData[victim][0][1];
	else
		return g_victimData[victim][0][1];
}

public int SortByDamageDesc(int[] x, int[] y, int[][] array, Handle data)
{
	if (x[0] > y[0]) 
        return -1;
    /*else if (x[1] < y[1]) 
        return 1;    
    return 0;*/
	return  x[0] < y[0];
}

stock void show_statisctics(int victim)
{
	if (!GetConVarInt(l4d_killsmgr_enable)) return;
	char victimName[64], attackerName[64];
	char statistics[2048] = "";
	
	int count;
	int data[MAXPLAYERS+1][2];
	
	//select which array we will work in (special infected or witches)...
	if (IsWitch(victim))
	{
		//check if l4d1's witch must show statistics...
		if (left4dead==1 && GetConVarInt(l4d_killsmgr_stats_bosses)&FL_WITCH_L4D1==0 )
		{
			//PrintToChatAll("cvar flags:%i, witch flags: %i, COMPARISON: %i", GetConVarInt(l4d_killsmgr_stats_bosses), (1<<FL_WITCH_L4D1), GetConVarInt(l4d_killsmgr_stats_bosses)&(1<<FL_WITCH_L4D1));
			return;
		}
		//check if l4d1's witch must show statistics...
		else if (left4dead==2 && GetConVarInt(l4d_killsmgr_stats_bosses)&FL_WITCH_L4D2==0 )
			return;
		
		//cloning witches array into "data"...
		for (int i=0; i<=MAXPLAYERS; i++)
		{
			data[i][0] = g_witchesData[victim][i][0];
			data[i][1] = g_witchesData[victim][i][1];
		}
		FormatEx(statistics, sizeof(statistics), "[KILLS MGR] Witch:");
	}
	else
	{
		//check if this infected is allowed in l4d_killsmgr_stats_bosses_l4dx...
		if ( GetConVarInt(l4d_killsmgr_stats_bosses)&(1<<GetEntProp(victim, Prop_Send, "m_zombieClass"))==0 )
		{
			//PrintToChatAll(  "stat_bosses: %i. FLAG=%i. COMPARISON: %i", GetConVarInt(l4d_killsmgr_stats_bosses), 1<<GetEntProp(victim, Prop_Send, "m_zombieClass"), GetConVarInt(l4d_killsmgr_stats_bosses)&(1<<GetEntProp(victim, Prop_Send, "m_zombieClass"))  );
			return;
		}
		
		//cloning infected's array into "data"...
		for (int i=0; i<=MAXPLAYERS; i++)
		{
			data[i][0] = g_victimData[victim][i][0];
			data[i][1] = g_victimData[victim][i][1];
		}
		GetClientName(victim, victimName, sizeof(victimName));
		FormatEx(statistics, sizeof(statistics), "[KILLS MGR] %s:", victimName);
	}
	
	//let's start to collect statistics...
	for (int i=0; i<MAXPLAYERS; i++)
	{
		//data[i][1] is the victim's attacker
		//data[i][0] is the damage done by attacker
		if ( data[i][0]==0 )
		{
			//PrintToChatAll("show_statisctics(victim=%i)::data[i=%i][0] = %i BREAK;", victim, i, data[i][0]);
			break;
		}
		count++;
		GetClientName(data[i][1], attackerName, sizeof(attackerName));
		
		//appling amount limit specified on l4d_killsmgr_stats_max...
		if ( GetConVarInt(l4d_killsmgr_stats_max)>0 )
		{
			if (count>GetConVarInt(l4d_killsmgr_stats_max))
				break;
		}
		
		//APPENDING ATTACKERS TO STATISTICS...
		//first (higher) attacker in the list...
		if (count==1)
		{
			//print higher attacker in special color:
			FormatEx(statistics, sizeof(statistics), "%s %s(%i)", statistics, attackerName, data[i][0]);
		}
		//other attackers...
		else
		{
			//add separator (comma):
			FormatEx(statistics, sizeof(statistics), "%s, ", statistics);
			
			//print attacker in normal color:
			FormatEx(statistics, sizeof(statistics), "%s%s(%i)", statistics, attackerName, data[i][0]);
		}
	}
	if (count)
	{
		//show statistics:
		if (GetConVarInt(l4d_killsmgr_stats_type)==1)
			PrintCenterTextAll(statistics);
		else if (GetConVarInt(l4d_killsmgr_stats_type)==2)
			PrintHintTextToAll(statistics);
		else
			PrintToChatAll(statistics);
		
		//PrintToChatAll("1 2 3 4 5 6"); //testing colors from \x01 to \x06 
	}
}

public Action event_player_death(Handle event, char[] event_name, bool dontBroadcast)
{
	if (!GetConVarInt(l4d_killsmgr_enable)) return Plugin_Continue;
	int victim  = GetClientOfUserId(GetEventInt(event, "userid"));
	if ( !IsValidClientInGame(victim) )
	{
		if ( IsValidClientIndex(victim) )
		{
			cleanDamageEvents(victim);
			cleanVictimArray(victim);
		}
		return Plugin_Continue;
	}
	
	//check if infected is allowed in l4d_killsmgr_include_bosses_l4dx...
	if ( GetConVarInt(l4d_killsmgr_count_mode)==0 || GetConVarInt(l4d_killsmgr_include_bosses)&(1<<GetEntProp(victim, Prop_Send, "m_zombieClass"))==0) 
	{
		//now, statistics will be shown in mode "0" too (if configured to do so).
		if (GetConVarInt(l4d_killsmgr_stats_enable))
		{
			sortDamagers(victim);
			show_statisctics(victim);
		}
		
		cleanVictimArray(victim);
		cleanDamageEvents(victim);
		return Plugin_Continue;
	}
	
	int new_killer = sortDamagers(victim);
	
	if (IsValidClientInGame(new_killer))
	{
		if (GetConVarInt(l4d_killsmgr_stats_enable))
			show_statisctics(victim);
		
		char weaponname[32], attackerName[64];
		
		//Modifying death event...
		//SetEventInt(event, "userid", GetClientUserId(victim));
		//SetEventInt(event, "entityid", 0);
		SetEventInt(event, "attacker", GetClientUserId(new_killer));
		GetClientName(new_killer, attackerName, sizeof(attackerName));
		SetEventString(event, "attackername", attackerName);
		SetEventInt(event, "attackerentid", 0);
		GetEventString(g_damageEvents[victim][new_killer], "weaponname", weaponname, sizeof(weaponname));
		SetEventString(event, "weapon", weaponname);
		SetEventBool(event, "headshot", GetEventBool(g_damageEvents[victim][new_killer], "headshot"));
		SetEventBool(event, "attackerisbot", IsFakeClient(new_killer));
		//GetClientName(victim, victimName, sizeof(victimName)); //victim is always the same, there is no reason to change.
		//SetEventString(event, "victimname", victimName); //victim is always the same, there is no reason to change.
		//SetEventInt(event, "victimisbot", IsFakeClient(victim) );
		SetEventBool(event, "abort", false);
		SetEventInt(event, "type", GetEventInt(event, "type"));
		//FireEvent(event);
		
		//cleaning operations...
		cleanDamageEvents(victim);
		cleanVictimArray(victim);
		return Plugin_Changed;
	}
	
	//cleaning operations...
	cleanDamageEvents(victim);
	cleanVictimArray(victim);
	return Plugin_Continue;
}

public Action OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &ammotype, int hitbox, int hitgroup)
{
	if (!GetConVarInt(l4d_killsmgr_enable)) return Plugin_Continue;
	int victimTeam, pre_health;
	char victimName[64], attackerName[64], weaponname[32];
	if ( !IsValidClientInGame(victim) )
	{
		return Plugin_Continue;
	}
	
	victimTeam = GetClientTeam(victim);
	pre_health = GetClientHealth(victim);
	
	if (pre_health<=0)
	{
		return Plugin_Handled;
	}
	GetClientName(victim, victimName, sizeof(victimName));
	
	if ( victimTeam!=TEAM_INFECTED ) return Plugin_Continue;
	
	//store damage done by everyone (not including self ignite)...
	if (IsValidClientInGame(attacker))
	{
		if (attacker == victim) return Plugin_Continue; //don't count self-inflicted damage.
		if (inflictor == victim) return Plugin_Continue; //don't count self-inflicted damage.
		if ( GetClientTeam(attacker)==TEAM_INFECTED ) return Plugin_Continue; //don't count infected's friendly fire.
		if ( GetConVarInt(l4d_killsmgr_prevent_overdamage) )
		{
			if ( float(pre_health)-damage < 0 )
				damage = float(pre_health);
		}
		
		//we need to create a fake player_death based on current damage data, which will replace real death event...
		Handle event = INVALID_HANDLE;
		if ( g_damageEvents[victim][attacker]==INVALID_HANDLE )
			event = CreateEvent("player_death");
		else
			event = g_damageEvents[victim][attacker];
		
		SetEventInt(event, "userid", GetClientUserId(victim));
		SetEventInt(event, "entityid", 0);
		SetEventInt(event, "attacker", GetClientUserId(attacker));
		GetClientName(attacker, attackerName, sizeof(attackerName));
		SetEventString(event, "attackername", attackerName);
		SetEventInt(event, "attackerentid", 0);
		GetClientWeapon(attacker, weaponname, sizeof(weaponname));
		SetEventString(event, "weapon", weaponname);
		SetEventBool(event, "headshot", (hitgroup==1)?true:false);
		SetEventBool(event, "attackerisbot", IsFakeClient(attacker));
		SetEventString(event, "victimname", victimName);
		SetEventBool(event, "victimisbot", IsFakeClient(victim) );
		SetEventInt(event, "type", damagetype);
		
		int tankFlag;
		if (left4dead==1)
			tankFlag = FL_TANK_L4D1;
		else
			tankFlag = FL_TANK_L4D2;
		
		if ( IsFakeClient(attacker) ) //damage by bots
		{
			if ( (1<<GetEntProp(victim, Prop_Send, "m_zombieClass"))&tankFlag )
			{
				if ( GetEntProp(victim, Prop_Send, "m_isIncapacitated") )
					return Plugin_Continue;
			}
				
			int ignoreBotsDamage = GetConVarInt(l4d_killsmgr_stats_ignore_bots_damage);
			//storing data to statistics...
			if  (ignoreBotsDamage==0||ignoreBotsDamage==2) //0: allow statistics, allow scoreboard
			{
				g_victimData[victim][attacker][0] += RoundToCeil(damage); //count bots damage
				g_victimData[victim][attacker][1] = attacker; //userid must be stored as value because sorting
				g_damageEvents[victim][attacker] = event;
			}
			else if ( ignoreBotsDamage==1 ) //1: disallow statistics, allow scoreboard
			{}
			
			if (ignoreBotsDamage==3||ignoreBotsDamage==2) //3: no statistics, no scoreboard
			{
				if ( (1<<GetEntProp(victim, Prop_Send, "m_zombieClass"))&tankFlag ) 
				{
					//don't add bot's damage to tank to scoreboard...
					int damage2tank = GetEntProp(attacker, Prop_Send, "m_checkpointDamageToTank");
					if (damage2tank<0)
						damage2tank = 0;
					damage2tank -= RoundToCeil(damage);
					SetEntProp(attacker, Prop_Send, "m_checkpointDamageToTank",  damage2tank);
				}
			}
			return Plugin_Changed;
		}
		else //damage by human players
		{
			if ( (1<<GetEntProp(victim, Prop_Send, "m_zombieClass"))&tankFlag  ) 
			{
				//ignore flame damage:
				if ( damagetype==DMG_BURN )
					return Plugin_Continue;
				//ignore tank's incapacitated damage (dying animation):
				if ( GetEntProp(victim, Prop_Send, "m_isIncapacitated") )
					return Plugin_Continue;
			}
			
			g_victimData[victim][attacker][0] += RoundToCeil(damage); //always count human damage
			g_victimData[victim][attacker][1] = attacker; //userid must be stored as value because sorting
			g_damageEvents[victim][attacker] = event; //we need this event to store this event's full data...
			return Plugin_Changed;
		}
	}

	return Plugin_Continue;
}


public void round_reset(Handle event, char[] event_name, bool dontBroadcast)
{
	reset_vars();
}

stock void reset_vars()
{
	for (int i=1; i<=MAXENTITIES; i++)
	{
		//cleaning events array...
		if (i<=MAXPLAYERS)
		{
			cleanDamageEvents(i);
		}
		//cleaning operations...
		if (i<=MAXPLAYERS)
			cleanInfectedArray(i);
		cleanWitchArray(i);
	}
}

stock void cleanDamageEvents(int victim)
{
	for (int i=1; i<=MAXPLAYERS; i++)
	{
		if (g_damageEvents[victim][i])
		{
			CancelCreatedEvent(g_damageEvents[victim][i]);
		}
		g_damageEvents[victim][i] = INVALID_HANDLE;
	}
}

stock void cleanVictimArray(int victim)
{
	if (IsWitch(victim))
		cleanWitchArray(victim);
	else if (IsValidClientIndex(victim))
		cleanInfectedArray(victim);
	else
		cleanWitchArray(victim);
}

stock void cleanWitchArray(int victim)
{
	for (int i=0; i<=MAXPLAYERS; i++)
	{
		g_witchesData[victim][i][0] = 0;
		g_witchesData[victim][i][1] = 0;
	}	
}

stock void cleanInfectedArray(int victim)
{
	for (int i=0; i<=MAXPLAYERS; i++)
	{
		g_victimData[victim][i][0] = 0;
		g_victimData[victim][i][1] = 0;
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
	if (witch > 0 && IsValidEdict(witch) && IsValidEntity(witch))
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

stock int GetHumanPlayersCount(int flags=0)
{
	int count, success;
	//if both FLAGS_INFECTED and FLAGS_SURVIVOR are omited, both will be enabled.
	if (flags & FLAGS_INFECTED & FLAGS_SURVIVOR == 0)
		flags |= (FLAGS_INFECTED | FLAGS_SURVIVOR);
	
	if (flags & FLAGS_BOT & FLAGS_HUMAN == 0)
		flags |= (FLAGS_BOT | FLAGS_HUMAN);
	
	//if both FLAGS_ALIVE and FLAGS_DEAD are omited, both will be enabled.
	if (flags & FLAGS_ALIVE & FLAGS_DEAD == 0)
		flags |= (FLAGS_ALIVE | FLAGS_DEAD);
	
	//if both FLAGS_BOT and FLAGS_HUMAN are omited, both will be enabled.
	if (flags & FLAGS_BOT & FLAGS_HUMAN == 0)
		flags |= (FLAGS_ALIVE | FLAGS_DEAD);
	
	for (int i=1; i<=MAXPLAYERS; i++)
	{
		success = 0;
		if (!IsValidClientInGame(i))
			continue;
		
		//check alive status...
		if ( IsPlayerAlive(i) && flags&FLAGS_ALIVE) 
			success++;
		else if ( !IsPlayerAlive(i) && flags&FLAGS_DEAD) 
			success++;
		
		//check team...
		if (GetClientTeam(i)==TEAM_INFECTED && flags&FLAGS_INFECTED)
			success++;
		else if (GetClientTeam(i)!=TEAM_INFECTED && flags&FLAGS_SURVIVOR)
			success++;
		
		//check bot...
		if ( IsFakeClient(i) && flags&FLAGS_BOT )
			success++;
		else if ( !IsFakeClient(i) && flags&FLAGS_HUMAN )
			success++;
		
		//check above conditions...
		if (success==3)
			count++;
	}
	return count;
}

stock void GameCheck()
{
	char GameName[16];
	GetConVarString(FindConVar("mp_gamemode"), GameName, sizeof(GameName));

	if (StrEqual(GameName, "coop", false) || StrEqual(GameName, "realism", false))
		g_iGameMode = 1<<GAMEMODE_COOP;
	else if (StrEqual(GameName, "versus", false) || StrEqual(GameName, "teamversus", false) || StrEqual(GameName, "scavenge", false) || StrEqual(GameName, "teamscavenge", false))
		g_iGameMode = 1<<GAMEMODE_VERSUS;
	else if (StrEqual(GameName, "survival", false))
		g_iGameMode = 1<<GAMEMODE_SURVIVAL;
	else
		g_iGameMode = 0;
}