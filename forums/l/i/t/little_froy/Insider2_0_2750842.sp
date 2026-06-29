#define PATH    "Insider2.0"

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

forward Action L4D_OnFirstSurvivorLeftSafeArea(int client)

#define BURN_TIME       (120.0)
#define EACH            (4)

bool Insider[MAXPLAYERS+1] = {false, ...};

bool Started = false;

ConVar C_insider_tankonly = null;
bool Tank_only = false;

public bool IsPlayerFalling(int client)
{
	return GetEntProp(client, Prop_Send, "m_isHangingFromLedge") != 0;
}
public bool IsPlayerFallen(int client)
{
	return GetEntProp(client, Prop_Send, "m_isIncapacitated") != 0;
}
public bool IsPlayerAlright(int client)
{
	return !(IsPlayerFalling(client) || IsPlayerFallen(client));
}

public int GetClientHealthMax(int client)
{
    return GetEntProp(client, Prop_Data, "m_iMaxHealth");
}

public int GetIncapHealthMax()
{
    return GetConVarInt(FindConVar("survivor_incap_health"));
}

public int GetLimpHealth()
{
    return GetConVarInt(FindConVar("survivor_limp_health"));
}

float GetTempHealth(int client)
{
	float Buffer = GetEntPropFloat(client, Prop_Send, "m_healthBuffer");
	Buffer -= (GetGameTime() - GetEntPropFloat(client, Prop_Send, "m_healthBufferTime")) * GetConVarFloat(FindConVar("pain_pills_decay_rate"));
	return Buffer < 0.0 ? 0.0 : Buffer;
}

void SetTempHealth(int client, float Buffer)
{
	SetEntPropFloat(client, Prop_Send, "m_healthBuffer", Buffer < 0.0 ? 0.0 : Buffer);
	SetEntPropFloat(client, Prop_Send, "m_healthBufferTime", GetGameTime());
}

public void fixTempHealth(int client)
{
    if(GetClientHealth(client) + GetTempHealth(client) > GetClientHealthMax(client))
	{
		SetTempHealth(client, float(GetClientHealthMax(client) - GetClientHealth(client)));
	}
}

public int Get_count()
{
    int cnt = 0;
    for(int i = 1; i <= MaxClients; i++)
    {
        if(IsValidEntity(i))
        {
            if(IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i))
            {
                cnt++;
            }
        }
    }
    return cnt;
}

public int Get_count_insider()
{
    int cnt = 0;
    for(int i = 1; i <= MaxClients; i++)
    {
        if(IsValidEntity(i))
        {
            if(IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i))
            {
                if(Insider[i] == true)
                {
                    cnt++;
                }
            }
        }
    }
    return cnt;
}

public void ReStartRound()
{
    PrintToChatAll("Ghost Win, Restart Round.");
    PrintToChatAll("内鬼获得胜利，重新开始游戏");
    for(int i = 1; i <= MaxClients; i++)
    {
        if(IsValidEntity(i))
        {
            if(IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i))
            {
                if(IsPlayerAlright(i))
                {
                    SetEntProp(i, Prop_Send, "m_isIncapacitated", 1);
                }
            }
        }
    }
}

public void OnGameFrame()
{
    if(Started == true)
    {
        int alives = Get_count();
        int insiders = Get_count_insider();
        if(insiders >= alives)
        {
            ReStartRound();
            Started = false;
        }
    }
}

public void First_tip(int client)
{
    PrintToChat(client, "You are the insider!");
    PrintToChat(client, "你被选为了内鬼生还者！");
    PrintToChat(client, "attack %s to heal them, also get heal when hurted by them", Tank_only ? "tank" : "special infecteds");
    PrintToChat(client, "攻击%s以治疗他们，自身受到他们攻击时回血", Tank_only ? "坦克" : "特感");
}

public void Been_tip(int client)
{
    PrintToChat(client, "You are already the insider!");
    PrintToChat(client, "你已经内鬼生还者了！");
    PrintToChat(client, "attack %s to heal them, also get heal when hurted by them", Tank_only ? "tank" : "special infecteds");
    PrintToChat(client, "攻击%s以治疗他们，自身受到他们攻击时回血", Tank_only ? "坦克" : "特感");   
}

public void Who()
{
    int Count = Get_count();
    int list = 0;
    if(Count <= EACH)
    {
        list = 1
    }
    else
    {
        list = Count / EACH;
    }
    int selected = 0;
    for(;;)
    {
        if(selected == list)
        {
            break;
        }
        int Pre = GetRandomInt(1, MaxClients);
        if(!IsValidEntity(Pre))
        {
            continue;
        }
        if(!IsClientInGame(Pre))
        {
            continue;
        }
        if(GetClientTeam(Pre) != 2)
        {
            continue;
        }
        if(!IsPlayerAlive(Pre))
        {
            continue;
        }
        if(Insider[Pre] == true)
        {
            continue;
        }
        Insider[Pre] = true;
        if(!IsFakeClient(Pre))
        {
            First_tip(Pre);
        }
        selected++;
    }
}

public bool IsOKInsider(int client)
{
    if(client)
    {
        if(IsValidEntity(client))
        {
            if(IsClientInGame(client) && GetClientTeam(client) == 2 && IsPlayerAlive(client))
            {
                return true;
            }
        }
    }
    return false;
}

public bool IsOKSpec(int client)
{
    if(client)
    {
        if(IsValidEntity(client))
        {
            if(IsClientInGame(client) && GetClientTeam(client) == 3 && IsPlayerAlive(client))
            {
                return true;
            }
        }
    }
    return false;
}

public Action OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype)
{ 
    if(attacker == 0 || attacker > MaxClients || victim == 0 || victim > MaxClients)
    {
        return Plugin_Continue;
    }
    if(Insider[victim] == true && IsOKInsider(victim) && IsOKSpec(attacker))
    {
        if(Tank_only == true)
        {
            if(GetEntProp(attacker, Prop_Send, "m_zombieClass") != 8)
            {
                return Plugin_Continue;
            }
        }
        if(IsPlayerAlright(victim))
        {
            int dmg = RoundFloat(damage);
            damage = 0.0;
            int max = GetClientHealthMax(victim);
            int now = GetClientHealth(victim);
            if(now + dmg >= max)
            {
                SetEntityHealth(victim, max);
                fixTempHealth(victim);
            }
            else
            {
                SetEntityHealth(victim, now + dmg);
                fixTempHealth(victim);
            }
            if(GetEntProp(attacker, Prop_Send, "m_zombieClass") == 8)
            {
                IgniteEntity(attacker, BURN_TIME, false, 0.0, false);
            }
            return Plugin_Handled;
        }
        else
        {
            int dmg = RoundFloat(damage);
            damage = 0.0;
            int max = GetIncapHealthMax();
            int now = GetClientHealth(victim);
            if(now + dmg >= max)
            {
                SetEntityHealth(victim, max);
            }
            else
            {
                SetEntityHealth(victim, now + dmg);
            }
            if(GetEntProp(attacker, Prop_Send, "m_zombieClass") == 8)
            {
                IgniteEntity(attacker, BURN_TIME, false, 0.0, false);
            }
            return Plugin_Handled;
        }
    }
    if(Insider[attacker] == true && IsOKInsider(attacker) && IsOKSpec(victim))
    {
        if(Tank_only == true)
        {
            if(GetEntProp(victim, Prop_Send, "m_zombieClass") != 8)
            {
                return Plugin_Continue;
            }
        }
        int dmg = RoundFloat(damage);
        damage = 0.0;
        int max = GetClientHealthMax(victim);
        int now = GetClientHealth(victim);
        if(now + dmg >= max)
        {
            SetEntityHealth(victim, max);
        }
        else
        {
            SetEntityHealth(victim, now + dmg);
        }
        return Plugin_Handled;
    }
	return Plugin_Continue;
}

public void Burn(int victim, int attacker)
{
    if(Insider[victim] == true)
    {
        if(IsOKInsider(victim) && IsOKSpec(attacker))
        {
            IgniteEntity(attacker, BURN_TIME, false, 0.0, false);
        }
    }
}

public void ResetAll()
{
    Started = false;
    for(int i = 1; i <= MaxClients; i++)
    {
        Insider[i] = false;
    }
}

public void OnClientPutInServer(int client)
{
	if(client >= 1 && client <= MaxClients)
	{
		SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
	}
}

public Action L4D_OnFirstSurvivorLeftSafeArea(int client)
{
    Who();
    Started = true;
    return Plugin_Continue;
}

public void Evnet_round(Event event, const char[] name, bool dontBroadcast)
{
	ResetAll();
}

public void Event_hunter(Event event, const char[] name, bool dontBroadcast)
{
    if(Tank_only == true)
    {
        return;
    }
	int victim = GetClientOfUserId(GetEventInt(event, "victim"));
	int attacker = GetClientOfUserId(GetEventInt(event, "userid"));
	if(victim == 0 || attacker == 0)
	{
		return;
	}
	Burn(victim, attacker);
}

public void Event_smoker(Event event, const char[] name, bool dontBroadcast)
{
    if(Tank_only == true)
    {
        return;
    }
	int victim = GetClientOfUserId(GetEventInt(event, "victim"));
	int attacker = GetClientOfUserId(GetEventInt(event, "userid"));
	if(victim == 0 || attacker == 0)
	{
		return;
	}
	Burn(victim, attacker);
}

public void Event_jockey(Event event, const char[] name, bool dontBroadcast)
{
    if(Tank_only == true)
    {
        return;
    }
	int victim = GetClientOfUserId(GetEventInt(event, "victim"));
	int attacker = GetClientOfUserId(GetEventInt(event, "userid"));
	if(victim == 0 || attacker == 0)
	{
		return;
	}
	Burn(victim, attacker);
}

public void Event_charger(Event event, const char[] name, bool dontBroadcast)
{
    if(Tank_only == true)
    {
        return;
    }
	int victim = GetClientOfUserId(GetEventInt(event, "victim"));
	int attacker = GetClientOfUserId(GetEventInt(event, "userid"));
	if(victim == 0 || attacker == 0)
	{
		return;
	}
	Burn(victim, attacker);
}

public void Event_player_bot(Event event, const char[] name, bool dontBroadcast)
{
	int player = GetClientOfUserId(GetEventInt(event, "player"));
	int bot = GetClientOfUserId(GetEventInt(event, "bot"));
    if(GetClientTeam(bot) == 2)
    {
        Insider[bot] = Insider[player];
        Insider[player] = false;
    }
}

public void Event_bot_player(Event event, const char[] name, bool dontBroadcast)
{
	int bot = GetClientOfUserId(GetEventInt(event, "bot"));
    int player = GetClientOfUserId(GetEventInt(event, "player"));
    if(GetClientTeam(player) == 2)
    {
        Insider[player] = Insider[bot];
        Insider[bot] = false;
    }
    if(Insider[player] == true && IsClientInGame(player) && IsPlayerAlive(player) && GetClientTeam(player) == 2 && !IsFakeClient(player))
    {
        Been_tip(player);
    }
}

public void Event_defibrillator(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(GetEventInt(event, "subject"));
    if(Insider[client] == true && IsClientInGame(client) && IsPlayerAlive(client) && GetClientTeam(client) == 2 && !IsFakeClient(client))
    {
        Been_tip(client);
    }
}

public void Event_rescued(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(GetEventInt(event, "victim"));
    if(Insider[client] == true && IsClientInGame(client) && IsPlayerAlive(client) && GetClientTeam(client) == 2 && !IsFakeClient(client))
    {
        Been_tip(client);   
    }
}

public void Internal_changed()
{
	Tank_only = GetConVarBool(C_insider_tankonly);
}

public void ConvarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	Internal_changed();
}

public void OnConfigsExecuted()
{
	Internal_changed();
}

public void OnPluginStart()
{
    HookEvent("player_bot_replace", Event_player_bot);
    HookEvent("bot_player_replace", Event_bot_player);
    HookEvent("defibrillator_used", Event_defibrillator);
    HookEvent("survivor_rescued", Event_rescued);
	HookEvent("lunge_pounce", Event_hunter);
	HookEvent("tongue_grab", Event_smoker);
	HookEvent("jockey_ride", Event_jockey);
	HookEvent("charger_pummel_start", Event_charger);
    HookEvent("round_start", Evnet_round);
    C_insider_tankonly = CreateConVar("insider_tank_only", "0", "only enable with tank and insiders ?", FCVAR_SPONLY);
    C_insider_tankonly.AddChangeHook(ConvarChanged);
    AutoExecConfig(true, PATH);
}