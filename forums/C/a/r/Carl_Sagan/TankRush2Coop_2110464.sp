#include <sourcemod>
#include <sdktools>

#pragma semicolon 1

#define VERSION "1.0"
#define PREFIX "\x04[Tank Rush]\x03"

public Plugin:myinfo = 
{
	name = "Tank Rush 2",
	author = "Carl Sagan",
	description = "Spawns an endless amount of tanks.",
	version = VERSION,
	url = "urbanlyadjusted.com"
}

new Handle:tr_enable;
new Handle:tr_spawninterval;
new Handle:tr_givehealth;
new Handle:tr_tankhealth;

new Handle:directornobosses;
new Handle:directornomobs;
new Handle:directornospecials;
new Handle:commonlimit;
new Handle:tankhealth;

new Handle:KillTanksTimer;

new timertick;
new defaultclimit;
new defaulthealth;
new wason;
new first;

public OnPluginStart()
{
	CreateConVar("tr_version",VERSION,"Version of the plugin.",FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_DONTRECORD);
	tr_enable = CreateConVar("tr_enable","1","Enable or disable the plugin.",FCVAR_PLUGIN,true,0.0,true,1.0);
	tr_spawninterval = CreateConVar("tr_spawninterval","12","Interval in seconds between tank spawns.",FCVAR_PLUGIN,true,1.0);
	tr_givehealth = CreateConVar("tr_givehealth","1","Enable or disable tank kills giving the survivors health.",FCVAR_PLUGIN,true,0.0,true,1.0);
	tr_tankhealth = CreateConVar("tr_tankhealth","4000","Amount of health tanks will spawn with.",FCVAR_PLUGIN,true,1.0);
	
	directornobosses = FindConVar("director_no_bosses");
	directornomobs = FindConVar("director_no_mobs");
	directornospecials = FindConVar("director_no_specials");
	commonlimit = FindConVar("z_common_limit");
	tankhealth = FindConVar("z_tank_health");
	
	HookEvent("tank_killed",Event_BotTankKill);
	HookEvent("player_death",Event_PlayerTankKill);
	HookEvent("finale_start",Event_FinaleStart);
	
	CreateTimer(1.0,Timer_Update,_,TIMER_REPEAT);
	AutoExecConfig(true,"TankRush2");
}

public OnClientPostAdminCheck(client)
{
	if (IsClientInGame(client) && !IsFakeClient(client))
	{
		PrintToChat(client,"%s Welcome to Tank Rush!",PREFIX);
	}
}

public Action:Timer_Update(Handle:timer)
{
	new client;
	if (!first)
	{
		defaulthealth = GetConVarInt(tankhealth);
		defaultclimit = GetConVarInt(commonlimit);
		first = 1;
	}
	if (GetConVarBool(tr_enable))
	{
		wason = 1;
		SetConVarInt(directornobosses,1);
		SetConVarInt(directornomobs,1);
		SetConVarInt(directornospecials,1);
		SetConVarInt(commonlimit,0);
		SetConVarInt(tankhealth,GetConVarInt(tr_tankhealth));
	}
	else
	{
		if (wason)
		{
			client = GetRandomClient();
			if (client)
			{
				new flags3 = GetCommandFlags("director_start");
				SetCommandFlags("director_start",flags3 & ~FCVAR_CHEAT);
				FakeClientCommand(client,"director_start");
					
				SetCommandFlags("director_start", flags3|FCVAR_CHEAT);
				SetConVarInt(directornobosses,0);
				SetConVarInt(directornomobs,0);
				SetConVarInt(directornospecials,0);
				SetConVarInt(commonlimit,defaultclimit);
				SetConVarInt(tankhealth,defaulthealth);
				wason = 0;
			}
		}
	}
	
	if (GetConVarBool(tr_enable))
	{
		client = GetRandomClient();
		if (client)
		{
			new flags2 = GetCommandFlags("director_stop");
			SetCommandFlags("director_stop",flags2 & ~FCVAR_CHEAT);
			FakeClientCommand(client,"director_stop");

			SetCommandFlags("director_stop",flags2|FCVAR_CHEAT);

			timertick += 1;
			if (timertick >= GetConVarInt(tr_spawninterval))
			{
				new flags = GetCommandFlags("z_spawn_old");
				SetCommandFlags("z_spawn_old",flags & ~FCVAR_CHEAT);
				FakeClientCommand(client,"z_spawn_old tank auto");			
				SetCommandFlags("z_spawn_old",flags|FCVAR_CHEAT);

				timertick = 0;
			}
		}
	}
}

public Action:Event_BotTankKill(Handle:event, String:event_name[], bool:dontBroadcast)
{
	if (GetConVarBool(tr_givehealth))
	{
		new flags = GetCommandFlags("give");
		SetCommandFlags("give",flags & ~FCVAR_CHEAT);
		for (new x = 1; x <= MaxClients; x++)
		{
			if (IsClientInGame(x))
			{
				if (GetClientTeam(x) == 2)
				{
					FakeClientCommand(x,"give health");
				}
			}
		}
		SetCommandFlags("give",flags|FCVAR_CHEAT);
	}
}

public Action:Event_PlayerTankKill(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event,"userid"));
	if (IsValidDeadTank(client) && GetClientTeam(client) == 3)
	{
		new class = GetEntProp(client,Prop_Send,"m_zombieClass");
		if (class == 8)
		{
			if (GetConVarBool(tr_givehealth))
			{
				new flags = GetCommandFlags("give");
				SetCommandFlags("give",flags & ~FCVAR_CHEAT);
				for (new x = 1; x <= MaxClients; x++)
				{
					if (IsClientInGame(x))
					{
						if (GetClientTeam(x) == 2)
						{
							FakeClientCommand(x,"give health");
						}
					}
				}
				SetCommandFlags("give",flags|FCVAR_CHEAT);
			}
		}
	}
}

public Action:Timer_KillTanks(Handle:timer)
{
	PrintToChatAll("%s Tanks failed so the survivors will progress!",PREFIX);
	for (new x = 1; x <= MaxClients; x++)
	{
		if (IsClientInGame(x) && GetClientTeam(x) == 3)
		{
			ForcePlayerSuicide(x);
		}
	}
}

public Action:Event_FinaleStart(Handle:event, String:event_name[], bool:dontBroadcast)
{
	KillTanksTimer = CreateTimer(300.0,Timer_KillTanks,_,TIMER_REPEAT);
	PrintToChatAll("%s Finale started! Tanks have 5 minutes to kill the survivors.",PREFIX);
}

public OnMapStart()
{
	ResetRound();
}

public OnMapEnd()
{
	ResetRound();
}

stock ResetRound()
{
	if (KillTanksTimer != INVALID_HANDLE)
	{
		CloseHandle(KillTanksTimer);
		KillTanksTimer = INVALID_HANDLE;
	}
}

stock GetRandomClient()
{
	for (new x = 1; x <= MaxClients; x++ )
		if (IsClientInGame(x) && !IsFakeClient(x) )
			return x;
	return 0;
}

stock IsValidDeadTank(client)
{
	if (client == 0)
		return false;
	if (!IsClientInGame(client))
		return false;
	if (IsPlayerAlive(client))
		return false;
	return true;
}