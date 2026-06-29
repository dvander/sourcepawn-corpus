#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#define PLUGIN_VERSION 	"1.0.1"
#define CVAR_FLAGS FCVAR_NOTIFY
#define HEIGHT 			400.0
#define MAX_Boomer 		32
#define RANGE 			250.0

public Plugin myinfo =
{
	name = "[L4D1&2] Boomer Rain",
	author = "Die Teetasse",
	description = "Spawns a rain of Boomers.",
	version = PLUGIN_VERSION,
	url = ""
};

PluginData plugin;

enum struct PluginCvars
{
	ConVar CVarPluginOn;
	ConVar CVarExplosion;

	void Init()
	{
		RegAdminCmd("sm_boomer_rain", Command_BoomerRain, ADMFLAG_KICK, "sm_boomer_rain [count] | Will start a Boomer rain above you.");
		RegAdminCmd("sm_Boomer_rain_at", Command_BoomerRainAt, ADMFLAG_KICK, "sm_Boomer_rain_at <x> <y> <z> [count] | Will start a Boomer rain at the position.");
		CreateConVar("sm_Boomer_rain_version", PLUGIN_VERSION, "Boomer Rain Version", CVAR_FLAGS|FCVAR_DONTRECORD);
		this.CVarPluginOn = CreateConVar("l4d2_boomer_rain_plugin_enable", "1", "Plugin on = 1, Plugin off = 0", CVAR_FLAGS);
		this.CVarExplosion = CreateConVar("l4d2_boomer_rain_explosive", "1", "Should the survivors get biled and stumbled?", CVAR_FLAGS);

		this.CVarPluginOn.AddChangeHook(OnConVarPluginOnChange);
		this.CVarExplosion.AddChangeHook(OnConVarChange);
		AutoExecConfig(true, "l4d2_boomer_rain");
	}
}

enum struct PluginData
{
    PluginCvars cvars;
    ConVar CVarSplatRadius;
    bool bHooked;
    bool bPluginOn;
	bool bCVarExplosion;
	bool BoomerIsSpawning;
	float currentTarget[3];

    void Init()
    {
    	this.cvars.Init();
    }
    
    void GetCvarValues()
    {
        this.bCVarExplosion = this.cvars.CVarExplosion.BoolValue;
		this.CVarSplatRadius = FindConVar("z_exploding_splat_radius");
    }
    
    void IsAllowed()
    {
    	this.bPluginOn = this.cvars.CVarPluginOn.BoolValue;
    	if(!this.bHooked && this.bPluginOn)
    	{
    		this.bHooked = true;
    		HookEvent("player_spawn", Event_PlayerSpawn);
    	}
    	else if(this.bHooked && !this.bPluginOn)
    	{
    		this.bHooked = false;
    		UnhookEvent("player_spawn", Event_PlayerSpawn);
    	}
    }
}

public void OnPluginStart()
{	
	plugin.Init();
}

public void OnConfigsExecuted()
{
	plugin.IsAllowed();
	plugin.GetCvarValues();
}

void OnConVarPluginOnChange(ConVar cvar, const char[] oldVal, const char[] newVal)
{
	plugin.IsAllowed();
}

void OnConVarChange(ConVar cvar, const char[] oldVal, const char[] newVal)
{
	plugin.GetCvarValues();
}

Action Command_BoomerRain(int client, int args)
{
	if (client == 0) client = 1;

	float clientOrigin[3];
	GetEntPropVector(client, Prop_Send, "m_vecOrigin", clientOrigin);
	
	if (args == 0) BoomerRain(clientOrigin);
	else
	{
		char tempFloat[16];
		GetCmdArg(1, tempFloat, 16);
		int count = StringToInt(tempFloat);
		BoomerRain(clientOrigin, count);
	}
	return Plugin_Handled;
}

Action Command_BoomerRainAt(int client, int args)
{
	if (args != 3 && args != 4)
	{
		return Plugin_Handled;
	}

	float entityPosition[3];
	char tempFloat[16];

	for (int i = 0; i < 3; i++)
	{
		GetCmdArg(1+i, tempFloat, 16);
		entityPosition[i] = StringToFloat(tempFloat);
	}

	if (args == 3) BoomerRain(entityPosition);
	else
	{
		GetCmdArg(4, tempFloat, 16);
		int count = StringToInt(tempFloat);
		BoomerRain(entityPosition, count);
	}
	return Plugin_Handled;
}

void BoomerRain(const float rainOrigin[3], const int BoomerCount = 10)
{
	if (!plugin.bCVarExplosion) plugin.CVarSplatRadius.SetInt(0);

	Handle data = CreateStack(3);
	PushStackCell(data, 1);
	PushStackCell(data, BoomerCount);
	PushStackArray(data, rainOrigin);
	
	CreateTimer(0.1, Timer_RepeatTimer, data);
}

Action Timer_RepeatTimer(Handle timer, Handle stack)
{
	float position[3];
	int count = 0, current = 0;

	PopStackArray(stack, position);
	PopStackCell(stack, count);
	PopStackCell(stack, current);
	CloseHandle(stack);

	CreateBoomer();
	plugin.BoomerIsSpawning = true;
	CopyVector(position, plugin.currentTarget);

	current++;
	if (current > count)
	{
		if (!plugin.bCVarExplosion) CreateTimer(5.0, Timer_ResetConVar);
		return Plugin_Stop;
	}
	
	Handle data = CreateStack(3);
	PushStackCell(data, current);
	PushStackCell(data, count);
	PushStackArray(data, position);
	CreateTimer(0.5, Timer_RepeatTimer, data);
	return Plugin_Stop;
}

Action Timer_ResetConVar(Handle timer, int client)
{	
	ResetConVar(plugin.CVarSplatRadius);
	return Plugin_Stop;
}

void CreateBoomer()
{
	int bot = CreateFakeClient("InfBot");
	if (bot > 0)
	{
		ChangeClientTeam(bot, 3);
		CreateTimer(0.1, Timer_KickFakeClient, bot);
		CheatCommand("z_spawn_old", "Boomer auto");
	}
}

void Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	if (plugin.BoomerIsSpawning)
	{
		int client = GetClientOfUserId(GetEventInt(event, "userid"));
		if (client > 0 && IsClientInGame(client) && IsFakeClient(client) && GetClientTeam(client) == 3 && GetEntProp(client, Prop_Send, "m_zombieClass") == 2)
		{
			CreateTimer(0.01, Timer_TeleportBoomer, client);
		}
		plugin.BoomerIsSpawning = false;
	}
}

Action Timer_TeleportBoomer(Handle timer, int client)
{	
	float min, max, pos[3];
	min = plugin.currentTarget[0] - RANGE;
	max = plugin.currentTarget[0] + RANGE;
	pos[0] = GetRandomFloat(min, max);
	min = plugin.currentTarget[1] - RANGE;
	max = plugin.currentTarget[1] + RANGE;
	pos[1] = GetRandomFloat(min, max);
	pos[2] = plugin.currentTarget[2] + HEIGHT;

	TeleportEntity(client, pos, NULL_VECTOR, NULL_VECTOR);
	return Plugin_Stop;
}

Action Timer_KickFakeClient(Handle timer, int client)
{
	if (client > 0 && IsClientInGame(client) && IsFakeClient(client))
	{
		KickClient(client);
	}
	return Plugin_Stop;
}

void CheatCommand(const char[] command, const char[] parameter = "", int cheatPlayer = -1)
{
	if (cheatPlayer == -1)
	{
		for (int i = 1; i < MaxClients; i++)
		{
			if (IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i) == 2)
			{
				cheatPlayer = i;
			}
			break;
		}

		if (cheatPlayer == -1) return;
	}
	else if (!IsClientInGame(cheatPlayer)) return;		
	
	int userFlags = GetUserFlagBits(cheatPlayer);
	SetUserFlagBits(cheatPlayer, ADMFLAG_ROOT);
	int commandFlags = GetCommandFlags(command);
	SetCommandFlags(command, commandFlags & ~FCVAR_CHEAT);
	FakeClientCommand(cheatPlayer, "%s %s", command, parameter);
	SetCommandFlags(command, commandFlags);
	SetUserFlagBits(cheatPlayer, userFlags);	
}

void CopyVector(float a[3], float b[3])
{
	for (int i = 0; i < 3; i++)
	{
	    b[i] = a[i];
	}
}