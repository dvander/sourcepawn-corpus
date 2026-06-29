#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
//#include <sdktools>
//#include <sdkhooks>
//#undef REQUIRE_PLUGIN

#define PLUGIN_NAME			    "l4d_tank_autohp"
#define PLUGIN_VERSION 			"1.0 2026-01-25"

#define TEAM_SPECTATOR		1
#define TEAM_SURVIVOR		2
#define TEAM_INFECTED		3

bool DEBUG = false;
float g_fCvarTankAutoHPScale, g_fCvarTankAutoHPCutoff;
ConVar g_hCvarTankAutoHPScale, g_hCvarTankAutoHPCutoff;
int ZOMBIECLASS_TANK;

bool adjusted[MAXPLAYERS+1] = {false,...}; // true if tank health was already adjusted

public Plugin myinfo =
{
	name = "[L4D/L4D2] Tank AutoHP",
	author = "gvazdas",
	description = "Automatic tank HP scaling for 4+ survivors.",
	version = PLUGIN_VERSION,
	url = ""
}

int get_adjusted_hp(int max_hp, int num_survivors)
{
    int extra_players = num_survivors - 4;
    if (extra_players<=0) return max_hp;
    int set_max_hp = max_hp;
    int extra_hp_per_player = RoundFloat(max_hp*g_fCvarTankAutoHPScale);
    float scale = 1.00;
    float shrink_step = g_fCvarTankAutoHPCutoff/(28.0);
    if (shrink_step==0.0)
    {
        set_max_hp += extra_hp_per_player*extra_players;
    }
    else
    {
        for (int i=1;i<=extra_players;i++)
        {
            set_max_hp += RoundFloat(extra_hp_per_player*scale);
            scale -= shrink_step;
            if (scale<=0.0) break;
        }
    }
    return set_max_hp;
}

public void OnPluginStart()
{
    g_hCvarTankAutoHPScale = CreateConVar("l4d_tank_autohp_scale", "0.2", "Tank HP scaling. This is the extra hp given to the tank per player normalized to the initial tank hp. Larger number gives more HP. 0 to disable plugin.", FCVAR_NOTIFY, true, 0.0, true, 1000.0);
    g_hCvarTankAutoHPScale.AddChangeHook(ConVarChanged_Cvars);
    
    g_hCvarTankAutoHPCutoff = CreateConVar("l4d_tank_autohp_cutoff", "0.75", "In percent, how much the per-player bonus gets reduced by the time we get to the max player count. Larger number makes the per-player bonus shrink faster. 0 to stop shrinking.", FCVAR_NOTIFY, true, 0.0, true, 1000.0);
    g_hCvarTankAutoHPCutoff.AddChangeHook(ConVarChanged_Cvars);
    
    HookEvent("player_spawn", evtPlayerSpawn, EventHookMode_Post);
    HookEvent("player_team", evtPlayerTeam, EventHookMode_Post);
    HookEvent("round_start", evtRoundStart, EventHookMode_PostNoCopy);
    HookEvent("player_bot_replace", EvtBotReplacePlayer, EventHookMode_Pre);
    HookEvent("bot_player_replace", EvtPlayerReplaceBot, EventHookMode_Pre);
    HookEvent("player_death", evtPlayerDeath, EventHookMode_Post);
    
    RegConsoleCmd("l4d_tank_autohp_table", PrintTable, "Print tank health table for current parameters.");
    
    UpdateCvars();
}

public Action PrintTable(int client, int args)
{
    int start_hp = 4000;
    if (args>0)
    {
        start_hp=GetCmdArgInt(1);
        if (start_hp<=0) start_hp = 4000;
	}
	
	PrintToChat(client, "[l4d_tank_autohp] Initial tank HP %d, scale: %f, cutoff: %f", start_hp, g_fCvarTankAutoHPScale, g_fCvarTankAutoHPCutoff);
	for (int i=1;i<=32;i++)
    {
        PrintToChat(client, "%d survivors -> %d HP", i, get_adjusted_hp(start_hp,i));
    }
    
    return Plugin_Continue;
}

public void OnPluginEnd()
{
    UnhookEvent("player_spawn", evtPlayerSpawn, EventHookMode_Post);
    UnhookEvent("player_team", evtPlayerTeam, EventHookMode_Post);
    UnhookEvent("round_start", evtRoundStart, EventHookMode_PostNoCopy);
    UnhookEvent("player_bot_replace", EvtBotReplacePlayer, EventHookMode_Pre);
    UnhookEvent("bot_player_replace", EvtPlayerReplaceBot, EventHookMode_Pre);
    UnhookEvent("player_death", evtPlayerDeath, EventHookMode_Post);
}

public void OnClientPutInServer(int client)
{
    if (!IsValidClient(client)) return;
    adjusted[client] = false;
}

public void OnClientDisconnect(int client)
{
    if (!IsValidClient(client)) return;
    adjusted[client] = false;
}

void evtPlayerTeam(Event event, const char[] name, bool dontBroadcast)
{
	int userid = event.GetInt("userid");
	CreateTimer(0.1, Timer_CheckAlive, userid, TIMER_FLAG_NO_MAPCHANGE);
}

void evtPlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	int userid = event.GetInt("userid");
	CreateTimer(0.1, Timer_CheckAlive, userid, TIMER_FLAG_NO_MAPCHANGE);
}

Action Timer_CheckAlive(Handle timer, int userid)
{
	int client = GetClientOfUserId(userid);
	if (!IsValidClient(client) || !IsClientInGame(client)) return Plugin_Stop;
	
	if (IsPlayerAlive(client) && GetClientTeam(client)==TEAM_INFECTED)
	{
    	int zClass = GetEntProp(client,Prop_Send,"m_zombieClass");
    	if (zClass==ZOMBIECLASS_TANK) return Plugin_Stop;
	}
	
	adjusted[client] = false;
	
	return Plugin_Stop;
}

void evtRoundStart(Event event, const char[] name, bool dontBroadcast)
{
	for (int i = 1; i <= MAXPLAYERS; i++)
	{
		adjusted[i] = false;
	}
}

void ConVarChanged_Cvars(ConVar convar, const char[] oldValue, const char[] newValue)
{
    UpdateCvars();
}

void UpdateCvars()
{
    g_fCvarTankAutoHPScale = g_hCvarTankAutoHPScale.FloatValue;
    g_fCvarTankAutoHPCutoff = g_hCvarTankAutoHPCutoff.FloatValue;
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion test = GetEngineVersion();
	if( test != Engine_Left4Dead && test != Engine_Left4Dead2 )
	{
		strcopy(error, err_max, "Plugin only supports Left 4 Dead 1 & 2.");
		return APLRes_SilentFailure;
	}
	
	if(test == Engine_Left4Dead) ZOMBIECLASS_TANK = 5;
	else if(test == Engine_Left4Dead2) ZOMBIECLASS_TANK = 8;

	RegPluginLibrary("l4d_tank_autohp");

	return APLRes_Success;
}

Action scale_tank_hp(Handle timer, DataPack pack)
{
    if (g_fCvarTankAutoHPScale<=0.0) return Plugin_Stop;
    pack.Reset();
    int client = pack.ReadCell();
    if ( !IsValidClient(client) || !IsClientInGame(client) ) return Plugin_Stop;
    if (adjusted[client]) return Plugin_Stop;
    if (!IsPlayerAlive(client)) return Plugin_Stop;
    if (GetClientTeam(client)!=TEAM_INFECTED) return Plugin_Stop;
    if (GetEntProp(client,Prop_Send,"m_isIncapacitated")>0) return Plugin_Stop;
    if (GetEntProp(client,Prop_Send,"m_zombieClass")!=ZOMBIECLASS_TANK) return Plugin_Stop;
    
    int allplayers = GetClientCount(false);
    int g_iPlayersInSurvivorTeam, counted_players = 0;
    for (int i=1;i<=MaxClients;i++)
    {
		if (!IsClientConnected(i)) continue;
        counted_players += 1;
		if (IsClientSourceTV(i) || IsClientReplay(i)) continue;
		if (!IsClientInGame(i)) continue;
		if (!IsPlayerAlive(i))
		{
    		adjusted[i] = false;
    		continue;
		}
		if (GetClientTeam(i) == TEAM_SURVIVOR) g_iPlayersInSurvivorTeam += 1;
		if (counted_players>=allplayers) break;
    }
    
    if (g_iPlayersInSurvivorTeam<=4) return Plugin_Stop;
    
    int expected_maxhealth = pack.ReadCell();
    int expected_health = pack.ReadCell();
    int curr_maxhealth = GetEntProp(client,Prop_Data,"m_iMaxHealth");
    if (curr_maxhealth!=expected_maxhealth) return Plugin_Stop;
    
    int curr_health = GetEntProp(client,Prop_Data,"m_iHealth");
    if (curr_health>expected_health) return Plugin_Stop;
    int diff = curr_maxhealth - curr_health;
    
    int set_maxhealth = get_adjusted_hp(curr_maxhealth,g_iPlayersInSurvivorTeam);
    int set_health = set_maxhealth - diff;
    
    SetEntProp(client, Prop_Data, "m_iMaxHealth", set_maxhealth);
    SetEntProp(client, Prop_Data, "m_iHealth", set_health);
    
    if (DEBUG) PrintToServer("[l4d_tank_autohp] %d survivors | Tank HP %d/%d -> %d/%d", g_iPlayersInSurvivorTeam,
                expected_health, expected_maxhealth,
                set_health, set_maxhealth);
    
    adjusted[client] = true;
    
    return Plugin_Stop;
}

#define HP_EASY 3000
#define HP_NORMAL 4000
#define HP_VERSUS 6000
#define HP_ADVANCED 8000

void swap(int client, int newclient, bool swap_hp = false)
{
    if (client==newclient) return;
    if (!IsValidClient(client) || !IsValidClient(newclient)) return;
    if (swap_hp)
    {
        int health = GetEntProp(client,Prop_Data,"m_iHealth");
        int maxhealth = GetEntProp(client,Prop_Data,"m_iMaxHealth");
        SetEntProp(newclient, Prop_Data, "m_iMaxHealth", maxhealth);
        SetEntProp(newclient, Prop_Data, "m_iHealth", health);
    }
    adjusted[newclient] = adjusted[client];
	adjusted[client] = false;
}

public void L4D_OnReplaceTank(int tank, int newtank)
{
	swap(tank,newtank);
}

Action EvtBotReplacePlayer(Event event, const char[] name, bool dontBroadcast) 
{
    int bot = GetClientOfUserId(event.GetInt("bot"));
    int client = GetClientOfUserId(event.GetInt("player"));
    swap(client,bot);
    return Plugin_Continue;
}

Action EvtPlayerReplaceBot(Event event, const char[] name, bool dontBroadcast)
{
    int bot = GetClientOfUserId(event.GetInt("bot"));
    int client = GetClientOfUserId(event.GetInt("player"));
    swap(bot,client);
    return Plugin_Continue;
}

void evtPlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (!IsValidClient(client)) return;
	char targetName[64];
    GetEntPropString(client, Prop_Data, "m_iName", targetName, sizeof(targetName));
    // Zombie Master plugin compatibility
    if ( strcmp(targetName,"zm_unit_control")==0 || strcmp(targetName,"zm_control")==0 || strcmp(targetName,"zm_client")==0 )
        return;
	int team = GetClientTeam(client);
	if (team!=TEAM_INFECTED)
	{
    	adjusted[client] = false;
    	return;
	}
	int incap = GetEntProp(client,Prop_Send,"m_isIncapacitated");
	if (incap>0) return;
	int zClass = GetEntProp(client,Prop_Send,"m_zombieClass");
	if (zClass!=ZOMBIECLASS_TANK)
	{
    	adjusted[client] = false;
    	return;
	}
	if (adjusted[client]) return;
	int health = GetEntProp(client,Prop_Data,"m_iHealth");
	int max_health = GetEntProp(client,Prop_Data,"m_iMaxHealth");
    if (health>max_health) return;
    //if ( max_health!=HP_EASY && max_health!=HP_NORMAL && max_health!=HP_VERSUS && max_health!=HP_ADVANCED ) return;
    if (DEBUG) PrintToServer("[l4d_tank_autohp] player_spawn %d %s %d %d %d %d/%d", client, targetName, team, incap, zClass, health, max_health);
	DataPack pack;
    CreateDataTimer(0.15,scale_tank_hp,pack,TIMER_FLAG_NO_MAPCHANGE|TIMER_DATA_HNDL_CLOSE);
    pack.WriteCell(client);
    pack.WriteCell(max_health);
    pack.WriteCell(health);
}

bool IsValidClient(int client, bool replaycheck = true)
{
	if (client < 1 || client > MaxClients) return false;
	if (!IsClientInGame(client)) return false;
	if (replaycheck)
	{
		if (IsClientSourceTV(client) || IsClientReplay(client)) return false;
	}
	return true;
}