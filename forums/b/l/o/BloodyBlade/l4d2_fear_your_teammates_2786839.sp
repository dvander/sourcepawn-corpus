#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdktools>
#include <colors>
#include include/sdkhooks.inc
#undef REQUIRE_PLUGIN

#define MAXENTITIES 2048

static bool surkillboomerboomtank,tankstumblebydoor,tankkillboomerboomhimself,boomerboomtank;
int surclient, Tankclient;
#define IsWitch(%0) (g_bIsWitch[%0])
bool g_bIsWitch[MAXENTITIES];							// Membership testing for fast witch checking

public Plugin myinfo = 
{
	name = "NoobTeammate",
	author = "NiceT",
	description = "announce your foolish teammates action",
	version = "1.0",
	url = "N/A"
}

public void OnPluginStart()
{
	HookEvent("player_death", Event_PlayerDeath);
	HookEvent("door_open", Event_DoorOpen);
	HookEvent("door_close", Event_DoorClose);
	HookEvent("round_start", Event_RoundStart);
	HookEvent("witch_killed", Event_WitchKilled);
	HookEvent("witch_spawn", Event_WitchSpawn);
}

public Action Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{	
	surkillboomerboomtank = false;
	tankstumblebydoor = false;
	tankkillboomerboomhimself = false;
	boomerboomtank = false;
}

public void Event_DoorOpen(Event event, const char[] name, bool dontBroadcast)
{
	Tankclient = GetTankClient();
	if(Tankclient == -1)	return;
	
	int Surplayer = GetClientOfUserId(event.GetInt("userid"));
	if(Surplayer<=0||!IsClientConnected(Surplayer) || !IsClientInGame(Surplayer)) return;
	//PrintToChatAll("%N open door",Surplayer);
	CreateTimer(0.75, Timer_TankStumbleByDoorCheck, Surplayer);//tank stumble check
}

public void Event_DoorClose(Event event, const char[] name, bool dontBroadcast)
{
	Tankclient = GetTankClient();
	if(Tankclient == -1)	return;
	
	int Surplayer = GetClientOfUserId(event.GetInt("userid"));
	if(Surplayer<=0||!IsClientConnected(Surplayer) || !IsClientInGame(Surplayer)) return;
	//PrintToChatAll("%N close door",Surplayer);
	CreateTimer(0.75, Timer_TankStumbleByDoorCheck, Surplayer);//tank stumble check
}

public Action Timer_TankStumbleByDoorCheck(Handle timer, any client)
{
	if(Tankclient<0 || !IsClientConnected(Tankclient) ||!IsClientInGame(Tankclient)) return;
	if (IsStaggering(Tankclient) && !surkillboomerboomtank && !tankstumblebydoor && !tankkillboomerboomhimself && !boomerboomtank)//tank stumble by door
	{
		CPrintToChatAll("{green}[NT] {olive}%N {default}use door stumble {green}Tank{default}.",client);
		tankstumblebydoor = true;
		CreateTimer(3.0,COLD_DOWN,_);
	}
}

public void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	int victim = GetClientOfUserId(event.GetInt("userid"));
	if( IsWitch(event.GetInt("attackerentid")) && victim != 0 && IsClientConnected(victim) && IsClientInGame(victim) && GetClientTeam(victim) == 3 )
	{
		if(!IsFakeClient(victim))//human player
			CPrintToChatAll("{green}[NT]{default} {red}Witch {default}Kill {olive}Her {default}Teammate!!!");
		else
			CPrintToChatAll("{green}[NT]{default} {red}Witch {default}Kill {olive}Her {default}AI Teammate!!!");
		
		return;
	}
	
	int attacker = GetClientOfUserId(event.GetInt("attacker"));
	char weapon[15];
	event.GetString("weapon", weapon, sizeof(weapon));
	char victimname[8];
	event.GetString("victimname", victimname, sizeof(victimname));
	//PrintToChatAll("attacker: %d - victim: %d - weapon:%s - victimname:%s",attacker,victim,weapon,victimname);
	if((attacker == 0 || attacker == victim)
	&& victim != 0 && IsClientConnected(victim) && IsClientInGame(victim) && GetClientTeam(victim) == 3)//SI suicide
	{
		char kill_weapon[15];
		if(StrEqual(weapon,"entityflame")||StrEqual(weapon,"env_fire"))//natural fire
			kill_weapon = "burn himself";
		else if(StrEqual(weapon,"inferno"))//player's fire
			return;
		else if(StrEqual(weapon,"trigger_hurt"))//fall death
			kill_weapon = "suicide";
		else if(StrEqual(weapon,"prop_physics")||StrEqual(weapon, "prop_car_alarm"))//kill by car
			kill_weapon = "kill by car";
		else if(StrEqual(weapon,"pipe_bomb")||StrEqual(weapon,"prop_fuel_barr"))//blast
			kill_weapon = "kill by blast";
		else if(StrEqual(weapon,"world"))//cmd "kill"
			return;
		else kill_weapon = "stuck";//kill by server because stuck
			
		if(GetEntProp(victim, Prop_Send, "m_zombieClass") == 8)//Tank suicide
		{
			if(!IsFakeClient(victim))//human SI player
				CPrintToChatAll("{green}[NT] {green}Tank {olive}%s {default}!",kill_weapon);
			else
				CPrintToChatAll("{green}[NT] {green}Tank {olive}%s {default}!",kill_weapon);
		}
		else if(GetEntProp(victim, Prop_Send, "m_zombieClass") == 2)
			CreateTimer(0.2, Timer_BoomerSuicideCheck, victim);//boomer suicide check	
		else
			if(!IsFakeClient(victim))//human SI player
				CPrintToChatAll("{green}[NT] {red}%N{default} {olive}%s {default}!",victim,kill_weapon);
			else
				CPrintToChatAll("{green}[NT] {red}AI{default} {olive}%s {default}!",kill_weapon);
	
		return;
	}
	else if (attacker==0 && victim == 0 && StrEqual(victimname,"Witch"))
	{
		CPrintToChatAll("{green}[NT] {red}Witch{default} {olive}suicide {default}!");
	}
	
	Tankclient = GetTankClient();
	if(Tankclient == -1)	return;
	
	if( StrEqual(victimname,"Witch") && PlayerIsTank(attacker) )
	{
		char Tank_weapon[15];
		if(StrEqual(weapon,"tank_claw"))
			Tank_weapon = "One-Punch";
		else if(StrEqual(weapon,"tank_rock"))
			Tank_weapon = "Rock";
		else if(StrEqual(weapon,"prop_physics"))
			Tank_weapon = "Car-Flying";
		
		if(!IsFakeClient(attacker))//human Tank player
			CPrintToChatAll("{green}[NT] Tank {default}use {olive}%s {default}Kill {red}witch{default}.",Tank_weapon);
		else
			CPrintToChatAll("{green}[NT] Tank {default}use {olive}%s {default}Kill {red}witch{default}.",Tank_weapon);
		
		return;
	}

	if ( victim == 0 || !IsClientConnected(victim)||!IsClientInGame(victim)) return;
	int victimteam = GetClientTeam(victim);
	int victimzombieclass = GetEntProp(victim, Prop_Send, "m_zombieClass");

	if (victimteam == 3)//infected dead
	{	
		if(attacker != 0 && IsClientConnected(attacker) && IsClientInGame(attacker))//someone kill infected
		{
			int attackerteam = GetClientTeam(attacker);
			if(attackerteam == 2 && victimzombieclass == 2)//sur kill Boomer
			{
				surclient = attacker;
				CreateTimer(0.2, Timer_SurKillBoomerCheck, victim);//sur kill Boomer check	
			}
			else if (PlayerIsTank(attacker))//Tank kill infected
			{
				char Tank_weapon[32];
				//Tank weapon
				if(StrEqual(weapon,"tank_claw"))
					Tank_weapon = "Beat to";
				else if(StrEqual(weapon,"tank_rock"))
					Tank_weapon = "Smash to";
				else if(StrEqual(weapon,"prop_physics"))
					Tank_weapon = "Use the Car";
				else if(StrEqual(weapon, "prop_car_alarm"))
					Tank_weapon = "Use the Alarm Car";
					
				//Tank kill boomer
				if(victimzombieclass == 2)
				{
					DataPack h_Pack;
					CreateDataTimer(0.2,Timer_TankKillBoomerCheck,h_Pack);//tank kill Boomer check
					WritePackCell(h_Pack, victim);
					WritePackString(h_Pack, Tank_weapon);
				}
				else if(victimzombieclass == 1||victimzombieclass == 3 ||victimzombieclass == 4 ||victimzombieclass == 5||victimzombieclass == 6)//Tank kill teammates S.I. (Hunter,Smoker,Jockey,Spitter,Charger)	
				{
					if(!IsFakeClient(victim))//human SI player
						CPrintToChatAll("{green}[NT] {green}Tank {olive}%s {default}Kill His Teammate.",Tank_weapon);
					else
						CPrintToChatAll("{green}[NT] {green}Tank {olive}%s {default}Kill His AI Teammate.",Tank_weapon);
				}
			}
		}
	}
}

public Action Timer_SurKillBoomerCheck(Handle timer, any client)
{
	if(Tankclient<0 || !IsClientConnected(Tankclient) ||!IsClientInGame(Tankclient)) return;
	if(client<0 || !IsClientConnected(client) ||!IsClientInGame(client)) return;
	if(IsStaggering(Tankclient) && !surkillboomerboomtank && !tankstumblebydoor && !tankkillboomerboomhimself && !boomerboomtank)//tank stumble
	{
		if(!IsFakeClient(client))//human boomer player
			CPrintToChatAll("{green}[NT] {olive}%N {default}Kill {red}%N{default}'s Boomer to Stumble {green}Tank{default}.",surclient, client);
		else
			CPrintToChatAll("{green}[NT] {olive}%N {default}Kill {red}AI {default}Boomer to Stumble {green}Tank{default}.",surclient);
		surkillboomerboomtank=true;
		CreateTimer(3.0, COLD_DOWN,_);
	}
}

public Action Timer_TankKillBoomerCheck(Handle timer, DataPack h_Pack)
{
	if(Tankclient<0 || !IsClientConnected(Tankclient) ||!IsClientInGame(Tankclient)) return;
	char Tank_weapon[128];
	int client;
	
	ResetPack(h_Pack);
	client = ReadPackCell(h_Pack);
	if(client<0 || !IsClientConnected(client) ||!IsClientInGame(client)) return;
	ReadPackString(h_Pack, Tank_weapon, sizeof(Tank_weapon));
	
	if(IsStaggering(Tankclient) && !surkillboomerboomtank && !tankstumblebydoor && !tankkillboomerboomhimself && !boomerboomtank)//tank stumble
	{
		if(!IsFakeClient(client))//human SI player
			CPrintToChatAll("{green}[NT] {green}Tank {olive}%s Kill {red}%N{default}'s Boomer to Stumble {default}Himself.",Tank_weapon,client);
		else	
			CPrintToChatAll("{green}[NT] {green}Tank {olive}%s Kill {red}AI {default}Boomer to Stumble {default}Himself.",Tank_weapon);
		tankkillboomerboomhimself = true;
		CreateTimer(3.0,COLD_DOWN,_);
	}
	else
	{
		if(!IsFakeClient(client))//human SI player
			CPrintToChatAll("{green}[NT] {green}Tank {olive}%s Kill {default}Boomer.",Tank_weapon);
		else
			CPrintToChatAll("{green}[NT] {green}Tank {olive}%s Kill {default}AI Boomer.",Tank_weapon);
	}
}


public Action Timer_BoomerSuicideCheck(Handle timer, any client)
{	
	if(client<0 || !IsClientConnected(client) ||!IsClientInGame(client)) return;
	
	Tankclient = GetTankClient();
	if(Tankclient<0 || !IsClientConnected(Tankclient) ||!IsClientInGame(Tankclient))
	{
		if(!IsFakeClient(client))//human boomer player
			CPrintToChatAll("{green}[NT] {red}%N{default}'s Boomer Suicide.",client);
		else
			CPrintToChatAll("{green}[NT] {red}AI {default}Boomer Suicide.");
		return;
	}
	
	if (IsStaggering(Tankclient) && !surkillboomerboomtank && !tankstumblebydoor && !tankkillboomerboomhimself && !boomerboomtank)//tank stumble
	{
		if(!IsFakeClient(client))//human boomer player
			CPrintToChatAll("{green}[NT] {default}NoobTeammate {red}%N{default}'s Boomer Stumble {green}Tank{default}.",client);
		else
			CPrintToChatAll("{green}[NT] {default}NoobTeammate {red}AI{default}Boomer Stumble {green}Tank{default}.");
		boomerboomtank = true;
		CreateTimer(3.0,COLD_DOWN,_);
	}
	else
	{
		if(!IsFakeClient(client))//human boomer player
			CPrintToChatAll("{green}[NT] {red}%N{default}'s Boomer Exploded.",client);
		else
			CPrintToChatAll("{green}[NT] {red}AI {default}Boomer Exploded.");
	}
}

static int GetTankClient()
{
	for (int client = 1; client <= MaxClients; client++)
		if(	PlayerIsTank(client) )//Tank player
			return  client;
	return -1;
}

stock bool PlayerIsTank(int client)
{
	if(client != 0 && IsClientConnected(client) && IsClientInGame(client) && IsInfectedAlive(client) && GetClientTeam(client) == 3 && GetEntProp(client, Prop_Send, "m_zombieClass") == 8) 
		return true;
	return false;
}

public Action COLD_DOWN(Handle timer, any client)
{
	surkillboomerboomtank = false;
	tankstumblebydoor = false;
	tankkillboomerboomhimself = false;
	boomerboomtank = false;
}

public void Event_WitchKilled(Event event, const char[] name, bool dontBroadcast)
{
	g_bIsWitch[event.GetInt("witchid")] = false;
}

public void Event_WitchSpawn(Event event, const char[] name, bool dontBroadcast)
{
	g_bIsWitch[event.GetInt("witchid")] = true;
}

public void OnMapStart()
{
	for (int i = MaxClients + 1; i < MAXENTITIES; i++) g_bIsWitch[i] = false;
}

stock bool IsInfectedAlive(int client)
{
	return GetEntProp(client, Prop_Send, "m_iHealth") > 1;
}

static bool IsStaggering(int client)
{
	if(GetEntPropFloat(client, Prop_Send, "m_staggerTimer", 1) > -1.0)
		return true;
	return false;
}
