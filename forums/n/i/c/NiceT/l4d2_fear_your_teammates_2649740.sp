#include <sourcemod>
#include <sdktools>
#include <colors>
#include include/sdkhooks.inc
#undef REQUIRE_PLUGIN

#pragma semicolon 1
#define MAXENTITIES 2048
#define GAMEDATA_FILE "staggersolver"
new Handle:g_hGameConf;
new Handle:g_hIsStaggering;
static bool:surkillboomerboomtank,tankstumblebydoor,tankkillboomerboomhimself,boomerboomtank;
new surclient;
new Tankclient;
#define IsWitch(%0) (g_bIsWitch[%0])
new	bool:g_bIsWitch[MAXENTITIES];							// Membership testing for fast witch checking

public Plugin:myinfo = 
{
	name = "NoobTeammate",
	author = "NiceT",
	description = "announce your foolish teammates action",
	version = "1.0",
	url = "N/A"
}

public OnPluginStart()
{
	g_hGameConf = LoadGameConfigFile(GAMEDATA_FILE);
	if (g_hGameConf == INVALID_HANDLE)
		SetFailState("[Stagger Solver] Could not load game config file.");

	StartPrepSDKCall(SDKCall_Player);

	if (!PrepSDKCall_SetFromConf(g_hGameConf, SDKConf_Signature, "IsStaggering"))
		SetFailState("[Stagger Solver] Could not find signature IsStaggering.");
	PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
	g_hIsStaggering = EndPrepSDKCall();
	if (g_hIsStaggering == INVALID_HANDLE)
		SetFailState("[Stagger Solver] Failed to load signature IsStaggering");

	CloseHandle(g_hGameConf);
	
	HookEvent("player_death", Event_PlayerDeath);
	HookEvent("door_open", Event_DoorOpen);
	HookEvent("door_close", Event_DoorClose);
	HookEvent("round_start", Event_RoundStart);
	HookEvent("witch_killed", Event_WitchKilled);
	HookEvent("witch_spawn", Event_WitchSpawn);
}
public Action:Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{	
	surkillboomerboomtank = false;
	tankstumblebydoor = false;
	tankkillboomerboomhimself = false;
	boomerboomtank = false;
}

public Event_DoorOpen(Handle:event, const String:name[], bool:dontBroadcast)
{
	Tankclient = GetTankClient();
	if(Tankclient == -1)	return;
	
	new Surplayer = GetClientOfUserId(GetEventInt(event, "userid"));
	if(Surplayer<=0||!IsClientConnected(Surplayer) || !IsClientInGame(Surplayer)) return;
	//PrintToChatAll("%N open door",Surplayer);
	CreateTimer(0.75, Timer_TankStumbleByDoorCheck, Surplayer);//tank stumble check
}

public Event_DoorClose(Handle:event, const String:name[], bool:dontBroadcast)
{
	Tankclient = GetTankClient();
	if(Tankclient == -1)	return;
	
	new Surplayer = GetClientOfUserId(GetEventInt(event, "userid"));
	if(Surplayer<=0||!IsClientConnected(Surplayer) || !IsClientInGame(Surplayer)) return;
	//PrintToChatAll("%N close door",Surplayer);
	CreateTimer(0.75, Timer_TankStumbleByDoorCheck, Surplayer);//tank stumble check
}

public Action:Timer_TankStumbleByDoorCheck(Handle:timer, any:client)
{
	if(Tankclient<0 || !IsClientConnected(Tankclient) ||!IsClientInGame(Tankclient)) return;
	if (SDKCall(g_hIsStaggering, Tankclient) && !surkillboomerboomtank && !tankstumblebydoor && !tankkillboomerboomhimself && !boomerboomtank)//tank stumble by door
	{
		CPrintToChatAll("{green}[NT] {olive}%N {default}use door stumble {green}Tank{default}.",client);
		tankstumblebydoor = true;
		CreateTimer(3.0,COLD_DOWN,_);
	}
}

public Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new victim = GetClientOfUserId(GetEventInt(event, "userid"));
	if( IsWitch(GetEventInt(event, "attackerentid")) && victim != 0 && IsClientConnected(victim) && IsClientInGame(victim) && GetClientTeam(victim) == 3 )
	{
		if(!IsFakeClient(victim))//human player
			CPrintToChatAll("{green}[NT]{default} {red}Witch {default}Kill {olive}Her {default}Teammate!!!");
		else
			CPrintToChatAll("{green}[NT]{default} {red}Witch {default}Kill {olive}Her {default}AI Teammate!!!");
		
		return;
	}
	
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	decl String:weapon[15];
	GetEventString(event, "weapon", weapon, sizeof(weapon));
	decl String:victimname[8];
	GetEventString(event, "victimname", victimname, sizeof(victimname));
	//PrintToChatAll("attacker: %d - victim: %d - weapon:%s - victimname:%s",attacker,victim,weapon,victimname);
	if((attacker == 0 || attacker == victim)
	&& victim != 0 && IsClientConnected(victim) && IsClientInGame(victim) && GetClientTeam(victim) == 3)//SI suicide
	{
		decl String:kill_weapon[15];
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
		decl String:Tank_weapon[15];
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
	new victimteam = GetClientTeam(victim);
	new victimzombieclass = GetEntProp(victim, Prop_Send, "m_zombieClass");
		
	if (victimteam == 3)//infected dead
	{	
		if(attacker != 0 && IsClientConnected(attacker) && IsClientInGame(attacker))//someone kill infected
		{
			new attackerteam = GetClientTeam(attacker);
			if(attackerteam == 2 && victimzombieclass == 2)//sur kill Boomer
			{
				surclient = attacker;
				CreateTimer(0.2, Timer_SurKillBoomerCheck, victim);//sur kill Boomer check	
			}
			else if (PlayerIsTank(attacker))//Tank kill infected
			{
				decl String:Tank_weapon[32];
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
					new Handle:h_Pack;
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
public Action:Timer_SurKillBoomerCheck(Handle:timer, any:client)
{
	if(Tankclient<0 || !IsClientConnected(Tankclient) ||!IsClientInGame(Tankclient)) return;
	if(client<0 || !IsClientConnected(client) ||!IsClientInGame(client)) return;
	if(SDKCall(g_hIsStaggering, Tankclient) && !surkillboomerboomtank && !tankstumblebydoor && !tankkillboomerboomhimself && !boomerboomtank)//tank stumble
	{
		if(!IsFakeClient(client))//human boomer player
			CPrintToChatAll("{green}[NT] {olive}%N {default}Kill {red}%N{default}'s Boomer to Stumble {green}Tank{default}.",surclient, client);
		else
			CPrintToChatAll("{green}[NT] {olive}%N {default}Kill {red}AI {default}Boomer to Stumble {green}Tank{default}.",surclient);
		surkillboomerboomtank=true;
		CreateTimer(3.0,COLD_DOWN,_);
	}
}

public Action:Timer_TankKillBoomerCheck(Handle:timer, Handle:h_Pack)
{
	if(Tankclient<0 || !IsClientConnected(Tankclient) ||!IsClientInGame(Tankclient)) return;
	decl String:Tank_weapon[128];
	new client;
	
	ResetPack(h_Pack);
	client = ReadPackCell(h_Pack);
	if(client<0 || !IsClientConnected(client) ||!IsClientInGame(client)) return;
	ReadPackString(h_Pack, Tank_weapon, sizeof(Tank_weapon));
	
	if(SDKCall(g_hIsStaggering, Tankclient) && !surkillboomerboomtank && !tankstumblebydoor && !tankkillboomerboomhimself && !boomerboomtank)//tank stumble
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


public Action:Timer_BoomerSuicideCheck(Handle:timer, any:client)
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
	
	if (SDKCall(g_hIsStaggering, Tankclient) && !surkillboomerboomtank && !tankstumblebydoor && !tankkillboomerboomhimself && !boomerboomtank)//tank stumble
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

static GetTankClient()
{
	for (new client = 1; client <= MaxClients; client++)
		if(	PlayerIsTank(client) )//Tank player
			return  client;
	return -1;
}

stock bool:PlayerIsTank(client)
{
	if(client != 0 && IsClientConnected(client) && IsClientInGame(client) && IsInfectedAlive(client) && GetClientTeam(client) == 3 && GetEntProp(client, Prop_Send, "m_zombieClass") == 8) 
		return true;
	return false;
}

public Action:COLD_DOWN(Handle:timer,any:client)
{
	surkillboomerboomtank = false;
	tankstumblebydoor = false;
	tankkillboomerboomhimself = false;
	boomerboomtank = false;
}

public Event_WitchKilled(Handle:event, const String:name[], bool:dontBroadcast)
{
	g_bIsWitch[GetEventInt(event, "witchid")] = false;
	
}

public Event_WitchSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	g_bIsWitch[GetEventInt(event, "witchid")] = true;
}
public OnMapStart()
{
	for (new i = MaxClients + 1; i < MAXENTITIES; i++) g_bIsWitch[i] = false;
}
stock bool:IsInfectedAlive(client)
{
	return GetEntProp(client, Prop_Send, "m_iHealth") > 1;
}