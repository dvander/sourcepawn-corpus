#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>

#define DEBUG 0

#define PLUGIN_VERSION "1.0.4b"
#define CVAR_FLAGS FCVAR_NOTIFY|FCVAR_SPONLY

ConVar PluginEnable, SetTankAmount, HealthDecrease, hMaxZombies, disablePrintsConVar;
bool bL4D2 = false, bHooked = false, bDisablePrintsConVar = false, HasHealthReduced[MAXPLAYERS + 1] = {false, ...}, bIsFinale = false;
int zClassTank = 5, DefaultMaxZombies = 0, iSetTankAmount = 0;
float fHealthDecrease = 0.0;

public Plugin myinfo =
{
	name = "L4D Finale Tankstorm",
	author = "AtomicStryker(Edit. by BloodyBlade)",
	description = " Spawns X weaker Tanks instead of a single one during Finale waves ",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=98721"
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
    EngineVersion engine = GetEngineVersion();
    if (engine == Engine_Left4Dead)
    {
        bL4D2 = false;
        zClassTank = 5;
    }
    else if(engine == Engine_Left4Dead2)
    {
        bL4D2 = true;
        zClassTank = 8;
    }
    else
    {
        strcopy(error, err_max, "This plugin only runs in \"Left 4 Dead\" game series");
        return APLRes_SilentFailure;
    }
    return APLRes_Success;
}

public void OnPluginStart()
{	
    CreateConVar("l4d_finaletankstorm_version", PLUGIN_VERSION, " Version of L4D Finale Tank Storm on this server ", CVAR_FLAGS|FCVAR_DONTRECORD);
    PluginEnable = CreateConVar("l4d_finaletankstorm_enable", "1","Enable/Disable plugin", CVAR_FLAGS, true, 0.0, true, 1.0);
    SetTankAmount = CreateConVar("l4d_finaletankstorm_tankcount", "3"," How many tanks shall spawn ", CVAR_FLAGS, true, 2.0, true, 8.0);
    HealthDecrease = CreateConVar("l4d_finaletankstorm_hpsetting", "0.40", " How much Health each of the X Tanks have compared to a standard one. '1.0' would be full health ", CVAR_FLAGS, true, 0.01);
    disablePrintsConVar = CreateConVar("l4d_finaletankstorm_announce", "1", " Does the Plugin announce itself ", CVAR_FLAGS);

    AutoExecConfig(true, "l4d_finaletankstorm");

    PluginEnable.AddChangeHook(OnConVarPluginOnChange);
    SetTankAmount.AddChangeHook(ConVarChanged_Cvars);
    HealthDecrease.AddChangeHook(ConVarChanged_Cvars);
    disablePrintsConVar.AddChangeHook(ConVarChanged_Cvars);
    hMaxZombies = FindConVar("z_max_player_zombies");
    hMaxZombies.AddChangeHook(ConVarChanged_Cvars);
}

public void OnMapStart()
{
	hMaxZombies.SetInt(DefaultMaxZombies);
	ResetBool();
}

public void OnMapEnd()
{
	hMaxZombies.SetInt(DefaultMaxZombies);
	ResetBool();
}

public void OnConfigsExecuted()
{
	IsAllowed();
}

void OnConVarPluginOnChange(ConVar cvar, const char[] oldVal, const char[] newVal)
{
	IsAllowed();
}

void ConVarChanged_Cvars(ConVar cvar, const char[] oldVal, const char[] newVal)
{
    iSetTankAmount = SetTankAmount.IntValue;
    fHealthDecrease = HealthDecrease.FloatValue;
    bDisablePrintsConVar = disablePrintsConVar.BoolValue;
    DefaultMaxZombies = hMaxZombies.IntValue;
}

void IsAllowed()
{
    bool bPluginOn = PluginEnable.BoolValue;
    if(!bHooked && bPluginOn)
    {
        bHooked = true;
        ConVarChanged_Cvars(null, "", "");
        HookEvent("player_death", Events);
        HookEvent("finale_start", Events);
        HookEvent("round_end", Events);
        HookEvent("map_transition", Events);
        HookEvent("finale_win", Events);
    }
    else if(bHooked && !bPluginOn)
    {
        bHooked = false;
        UnhookEvent("player_death", Events);
        UnhookEvent("finale_start", Events);
        UnhookEvent("round_end", Events);
        UnhookEvent("map_transition", Events);
        UnhookEvent("finale_win", Events);
    }
}

Action Events(Event event, char[] name, bool dontBroadcast)
{
    if (strcmp(name, "player_death") == 0)
    {
        if(!bIsFinale) return Plugin_Continue;
        int client = GetClientOfUserId(event.GetInt("userid"));
        if (client == 0) return Plugin_Continue;
        if(!IsTank(client)) return Plugin_Continue;
        HasHealthReduced[client] = false;
        CreateTimer(3.0, PrintLivingTanks);
    }
    else if(strcmp(name, "finale_start") == 0)
    {
        if (!IsFinalMap())
        {
            return Plugin_Continue;
        }

        bIsFinale = true;

        if (bDisablePrintsConVar)
        {
            PrintToChatAll("\x04[Finale Tank Storm Plugin] \x01Finale begins!");
        }

        ResetBool();
    }
    else if(strcmp(name, "round_end") == 0 || strcmp(name, "map_transition") == 0 || strcmp(name, "finale_win") == 0)
    {
        bIsFinale = false;
        ResetBool();
    }
    return Plugin_Continue;
}


void ResetBool()
{
	for (int i = 1 ; i <= MaxClients ; i++)
	{
		HasHealthReduced[i] = false;
	}
}

public void OnClientAuthorized(int client, const char[] auth) // this catches Tank Spawns the game does by itself, and only these
{
	if (!bHooked || !IsFakeClient(client)) return;
	char name[256];
	GetClientName(client, name, sizeof(name));
	if (StrEqual(name, "Tank") && CountTanks() == 0)// ive added the counttanks check for the "more tanks that human slots" situation
	{
		if(!bIsFinale)
		{
			#if DEBUG
			PrintToChatAll("\x04[Finale Tank Storm Plugin] \x01Its not a Finale yet");
			#endif
			return;
		}

		ReduceTankHealth(client);
		
		float TankDelay = FindConVar("director_tank_lottery_selection_time").FloatValue + 2.0;  
		// this to avoid 'disappearing' tanks. After Lottery strange things happen
		
		CreateTimer(TankDelay, SpawnMoreTanks, client);
		
		hMaxZombies.SetInt(DefaultMaxZombies + iSetTankAmount);
		// this to avoid other tank related oddities. We silently raise max Infected count before spawning another tank	
		
		#if DEBUG
		PrintToChatAll("\x04[Finale Tank Storm Plugin] \x01Spawning Another Tank with Delay %f!", TankDelay);
		#endif
	}
}

Action SpawnMoreTanks(Handle timer, any client)
{
    if (!bHooked || (CountTanks() == iSetTankAmount)) return Plugin_Stop;

    if (bDisablePrintsConVar)
    {
        PrintToChatAll("\x04[Finale Tank Storm Plugin] \x01Spawning %i. of %i Tanks with %i percent Health each!", CountTanks() + 1, iSetTankAmount, RoundFloat(100 * fHealthDecrease));
    }

    if(bL4D2)
    {
        int flags = GetCommandFlags("z_spawn_old");
        SetCommandFlags("z_spawn_old", flags & ~FCVAR_CHEAT);
        ServerCommand("z_spawn_old tank auto");
        SetCommandFlags("z_spawn_old", flags);
    }
    else
    {
        int flags = GetCommandFlags("z_spawn");
        SetCommandFlags("z_spawn", flags & ~FCVAR_CHEAT);
        ServerCommand("z_spawn tank auto");
        SetCommandFlags("z_spawn", flags);
    }

    CreateTimer(3.0, CheckSpawn);
    return Plugin_Stop;
}

Action CheckSpawn(Handle timer)
{
	if (!bHooked) return Plugin_Stop;

	if (CountTanks() < iSetTankAmount)
	{
		#if DEBUG
		PrintToChatAll("\x04[Finale Tank Storm Plugin] \x01We require more Tanks, spawning another!");
		#endif
		CreateTimer(0.5, SpawnMoreTanks, 0);
	}

	return Plugin_Stop;
}

void ReduceTankHealth(int client)
{
    // This reduces the Tanks Health. Multiple Tanks with full power are ownage ... no wait, they own in any case
    int TankHealth = RoundFloat(GetEntProp(client, Prop_Send, "m_iHealth") * fHealthDecrease);
    if(TankHealth > 65535) TankHealth = 65535;
    SetEntProp(client, Prop_Send, "m_iMaxHealth", TankHealth);
    SetEntProp(client, Prop_Send, "m_iHealth", TankHealth);
    HasHealthReduced[client] = true;
}

Action PrintLivingTanks(Handle timer)
{
	if(!bHooked) return Plugin_Stop;

	int Tanks = CountTanks();
	if (bDisablePrintsConVar)
	{
		PrintToChatAll("\x04[Finale Tank Storm Plugin] Tanks left alive: %i", Tanks);
	}

	if (Tanks <= 0)
	{
		hMaxZombies.SetInt(DefaultMaxZombies);
	}

	return Plugin_Stop;
}

stock int CountTanks()
{
	int TanksCount = 0;	
	for (int i = 1 ; i <= MaxClients ; i++)
	{
		if (IsClientInGame(i) && GetClientHealth(i) > 0 && GetClientTeam(i) == 3 && IsTank(i))
		{
			TanksCount++;
			if (!HasHealthReduced[i])
			{
				ReduceTankHealth(i);
			}
		}
	}
	return TanksCount;
}

stock bool IsTank(int client)
{
	return GetEntProp(client, Prop_Send, "m_zombieClass") == zClassTank;
}

// Thanks to "Timocop" (https://forums.alliedmods.net/showpost.php?p=2570943&postcount=7)
stock bool IsFinalMap()
{
	return FindEntityByClassname(-1, "info_changelevel") == -1 && FindEntityByClassname(-1, "trigger_changelevel") == -1;
}
