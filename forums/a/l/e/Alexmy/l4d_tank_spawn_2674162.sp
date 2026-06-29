#pragma semicolon 1
#include <sourcemod>
#pragma newdecls required

bool    /*q_stop,*/                          stop,                             stop_enter,                   g_stop_weapon;
int     g_iTankHP;
Handle  sm_SpawnTankRoundStartHP = null, sm_SpawnTankFinaleStartHP = null, sm_FirstTank_Random_1 = null, sm_NextTank_Random_1 = null;
char    s_ModelName[64],                 map[64];
Handle  Timer_1 = null,                  Timer_2 = null,                   sm_AdditionalTank = null,     sm_FirstTank_Random_2 = null;
Handle  sm_NextTank_Random_2 = null,     sm_EnableWeapon = null;

public Plugin myinfo = 
{
	name = "[L4D] Tank Spawn.",
	author = "AlexMy",
	description = "",
	version = "1.5",
	url = "https://forums.alliedmods.net/showthread.php?p=2412274"
};

public void OnPluginStart()
{
	sm_SpawnTankRoundStartHP  = CreateConVar("sm_SpawnTankRoundStartHP",  "30000",   "The health of the tank on a normal map!",              FCVAR_NOTIFY);
	
	sm_AdditionalTank         = CreateConVar("sm_AdditionalTank",         "1",       "Additional Tank? 1:Off. 0:On.",                        FCVAR_NOTIFY);
	
	sm_FirstTank_Random_1     = CreateConVar("sm_FirstTank_Random_1",     "60.0",    "Random time the first tank on a normal map.",          FCVAR_NOTIFY);
	sm_FirstTank_Random_2     = CreateConVar("sm_FirstTank_Random_2",     "120.0",   "Random time the first tank on a normal map.",          FCVAR_NOTIFY);
	
	sm_NextTank_Random_1      = CreateConVar("sm_NextTank_Random_1",      "120.0",   "A random time the next tank.",                         FCVAR_NOTIFY);
	sm_NextTank_Random_2      = CreateConVar("sm_NextTank_Random_2",      "240.0",   "A random time the next tank.",                         FCVAR_NOTIFY);
	
	sm_EnableWeapon           = CreateConVar("sm_EnableWeapon",           "1",       "The team will get locked weapons?     0:Off. 1:On.",   FCVAR_NOTIFY);
	
	sm_SpawnTankFinaleStartHP = CreateConVar("sm_SpawnTankFinaleStartHP", "30000",   "Health tank in the final offensive.",                  FCVAR_NOTIFY);
	
	AutoExecConfig(true, "l4d_tank spawn");
	
	//HookEvent("player_left_checkpoint", Event_RoundTank,  EventHookMode_Post);
	HookEvent("tank_killed",            EventTankKilled,  EventHookMode_Post);
	
	HookEvent("player_spawn",           EventPlayerSpawn, EventHookMode_Post);
	
	HookEvent("tank_spawn",             Event_TankSpawn,  EventHookMode_Post);
	
	HookEvent("finale_start",           EventFinaleStart, EventHookMode_Post);
	
	HookEvent("round_start",            Event_RoundStart, EventHookMode_Post);
	HookEvent("round_end",              Event_RoundEnd,   EventHookMode_Post);
	
	cleaner();
}
public void OnMapStart()
{
	SetConVarInt(FindConVar("director_no_bosses"), GetConVarInt(sm_AdditionalTank), true, false);
	
	if (Timer_1 != null)
	{
		delete(Timer_1);
		Timer_1 = null;
	}
	Timer_1 = CreateTimer(GetRandomInt(0, 1) ? GetConVarFloat(sm_FirstTank_Random_1) : GetConVarFloat(sm_FirstTank_Random_2), SpawnTank, _, TIMER_FLAG_NO_MAPCHANGE);
}

public void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	cleaner();
	GetCurrentMap(map, sizeof(map));
	if(StrEqual(map, "l4d_airport05_runway", false) || StrEqual(map, "l4d_hospital05_rooftop", false) || StrEqual(map, "l4d_river03_port", false))
	{
		/*q_stop = true,*/ stop = true;
	}
	g_iTankHP = GetConVarInt(sm_SpawnTankRoundStartHP);
}
public void Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	cleaner();
}
public void EventPlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	GetEntPropString(client, Prop_Data, "m_ModelName", s_ModelName, sizeof(s_ModelName));
	if (StrContains(s_ModelName, "hulk") != -1)
	{
		SetEntityHealth(client, g_iTankHP);
		Timer_2 = null;
	}
}
public void Event_TankSpawn(Event event, const char[] name, bool dontBroadcast)
{
	if(!GetConVarInt(sm_EnableWeapon) || (g_stop_weapon))return;
	{
		GetCurrentMap(map, sizeof(map));
		if(StrEqual(map, "l4d_hospital01_apartment", false) || StrEqual(map, "l4d_farm01_hilltop", false) || StrEqual(map, "l4d_airport01_greenhouse", false) || StrEqual(map, "l4d_smalltown01_caves", false))
		{
			for(int i = 1; i <= MaxClients; ++i) if (IsClientInGame(i) && GetClientTeam(i) == 2)
			{
				switch(GetRandomInt(0, 2))
				{
					case 0: CheatCommand(i, "give", "autoshotgun",   "");
					case 1: CheatCommand(i, "give", "hunting_rifle", "");
					case 2: CheatCommand(i, "give", "rifle",         "");
				}
			}
			PrintToChat(GetAnyClient(), "\x03Unlocked new \x05Tank\x01... \x03The survivors issued \x05new weapon\x01!!!");
		}
		g_stop_weapon = true;
	}
}
public void EventFinaleStart(Event event, const char[] name, bool dontBroadcast)
{
	g_iTankHP = GetConVarInt(sm_SpawnTankFinaleStartHP);
	stop = true, stop_enter = true/*, q_stop = true*/;
	SetConVarInt(FindConVar("director_no_bosses"), 0, false, false);
}/*
public void Event_RoundTank(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	{
		if(q_stop)return;
		{
			if (Timer_1 != null)
			{
				delete(Timer_1);
				Timer_1 = null;
			}
			Timer_1 = CreateTimer(GetRandomInt(0, 1) ? GetConVarFloat(sm_FirstTank_Random_1) : GetConVarFloat(sm_FirstTank_Random_2), SpawnTank, client, TIMER_FLAG_NO_MAPCHANGE);
			q_stop  = true;
		}
	}
}*/
public Action SpawnTank(Handle timer)
{
	if(stop_enter)return Plugin_Continue;
	{
		int anyclient = GetAnyClient();
		if(anyclient == -1)return Plugin_Continue;
		{
			CheatCommand(anyclient, "z_spawn", "tank", "auto");
		}
	}
	Timer_1 = null;
	return Plugin_Stop;
}
public Action EventTankKilled(Event event, const char[] name, bool dontBroadcast)
{
	//int client = GetClientOfUserId(event.GetInt("userid"));
	//{
		if(stop)return;
		{
			if (Timer_2 != null)
			{
				delete(Timer_2); 
				Timer_2 = null;
			}
			Timer_2 = CreateTimer(GetRandomInt(0, 1) ? GetConVarFloat(sm_NextTank_Random_1) : GetConVarFloat(sm_NextTank_Random_2), SpawnTankNext, _, TIMER_FLAG_NO_MAPCHANGE);
		}
	//}
}
public Action SpawnTankNext(Handle timer)
{
	if(stop_enter)return Plugin_Continue;
	{
		int anyclient = GetAnyClient();
		if(anyclient == -1)return Plugin_Continue;
		{
			CheatCommand(anyclient, "z_spawn", "tank", "auto");
		}
	}
	Timer_2 = null;
	return Plugin_Stop;
}
stock int GetAnyClient()
{
	int i;
	for (i = 1; i <= GetMaxClients(); i++) 
	{
		if (IsClientConnected(i) && IsClientInGame(i) && !IsFakeClient(i))
			return i;
		break;
	}
	return 0;
}
stock void CheatCommand(int client, char [] command, char arguments[]="", char arguments1[]="")
{
	if(client)
	{
		int userflags = GetUserFlagBits(client);
		SetUserFlagBits(client, ADMFLAG_ROOT);
		int flags = GetCommandFlags(command);
		SetCommandFlags(command, flags & ~FCVAR_CHEAT);
		FakeClientCommand(client, "%s %s %s", command, arguments, arguments1);
		SetCommandFlags(command, flags);
		SetUserFlagBits(client, userflags);
	}
}
stock void cleaner()
{
	/*q_stop = false,*/ stop = false, stop_enter = false, g_stop_weapon = false, Timer_1 = null, Timer_2 = null;
}