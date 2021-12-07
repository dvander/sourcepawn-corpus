#define PATH    "break_chi2.3"

#include <sourcemod>
#include <sdktools>

native void L4D_StaggerPlayer(int target, int source_ent, float vecSource[3]);

bool CDing[MAXPLAYERS+1] = {false, ...};

Handle H_CD[MAXPLAYERS+1] = {null, ...};

ConVar C_cdtime = null;
float O_CD_time = 0.0;

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

public void OnMapStart()
{
    PrecacheModel("models/props_junk/propanecanister001a.mdl", true);
}

public bool IsOKSurv(int client)
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

public void Create_bomb(int client)
{
    float vec[3];
    GetClientEyePosition(client, vec);
	int entity = CreateEntityByName("prop_physics");
	DispatchKeyValue(entity, "model", "models/props_junk/propanecanister001a.mdl");
	DispatchSpawn(entity);
	SetEntData(entity, GetEntSendPropOffs(entity, "m_CollisionGroup"), 1, 1, true);
	TeleportEntity(entity, vec, NULL_VECTOR, NULL_VECTOR);
	AcceptEntityInput(entity, "break");
}

public bool IsPlayerClose(int client, int index)
{
    float vec1[3];
    float vec2[3];
    GetClientAbsOrigin(client, vec1);
    GetClientAbsOrigin(index, vec2);
    if(GetVectorDistance(vec1, vec2) < 300.0)
    {
        return true;
    }
    else
    {
        return false;
    }
}

public void Stagger_player(int client)
{
    for(int i = 1; i <= MaxClients; i++)
    {
        if(i != client)
        {
            if(IsOKSurv(i) || IsOKSpec(i))
            {
                if(IsPlayerClose(client, i))
                {
                    L4D_StaggerPlayer(i, client, NULL_VECTOR);
                }
            }
        }
    }
}

public void UseTip(int client)
{
    PrintToChat(client, "你的爆气解控进入%0.f秒的冷却时间！", O_CD_time);
    PrintToChat(client, "You Break Chi Escaping is waiting for CD %0.f seconds!", O_CD_time);
}

public void CDTip(int client)
{
    PrintToChat(client, "你的爆气解控已冷却完成！");
    PrintToChat(client, "You Break Chi Escaping CD is done!");
}

public Action Timer_cd(Handle timer, int client)
{
    CDing[client] = false;
    H_CD[client] = null;
    if(IsValidEntity(client))
    {
        if(IsClientInGame(client))
        {
            if(!IsFakeClient(client))
            {
                if(GetClientTeam(client) == 2)
                {
                    CDTip(client);
                }
            }
        }
    }
    return Plugin_Stop;
}

public void Break_chi(int client)
{
    if(CDing[client] == false)
    {
        Create_bomb(client);
        Stagger_player(client);
        CDing[client] = true;
        H_CD[client] = CreateTimer(O_CD_time, Timer_cd, client, 0);
        UseTip(client);
    }
}

public Action OnPlayerRunCmd(int client, int &buttons)
{
    if(client)
    {
        if(IsValidEntity(client))
        {
            if(IsClientInGame(client))
            {
                if(!IsFakeClient(client) && GetClientTeam(client) == 2 && IsPlayerAlive(client) && IsPlayerAlright(client))
                {
                    if(buttons & IN_RELOAD && buttons & IN_USE)
                    {
                        Break_chi(client);
                    }
                }
            }
        }
    }
	return Plugin_Continue;
}

public void KillTheTimer(int client)
{
    if(H_CD[client] != null)
    {
        KillTimer(H_CD[client]);
        H_CD[client] = null;
    }   
}

public void ResetAll()
{
    for(int i = 1; i <= MaxClients; i++)
    {
        CDing[i] = false;
        KillTheTimer(i);
    }   
}

public void Event_player_bot(Event event, const char[] name, bool dontBroadcast)
{
	int player = GetClientOfUserId(GetEventInt(event, "player"));
	int bot = GetClientOfUserId(GetEventInt(event, "bot"));
    if(GetClientTeam(bot) == 2)
    {
        CDing[player] = true;
        CDing[bot] = true;
        KillTheTimer(player);
        KillTheTimer(bot);
    }
}

public void Event_bot_player(Event event, const char[] name, bool dontBroadcast)
{
	int bot = GetClientOfUserId(GetEventInt(event, "bot"));
    int player = GetClientOfUserId(GetEventInt(event, "player"));
    if(GetClientTeam(player) == 2)
    {
        CDing[player] = true;
        CDing[bot] = true;
        KillTheTimer(player);
        KillTheTimer(bot);
        H_CD[player] = CreateTimer(O_CD_time, Timer_cd, player, 0);
        if(IsValidEntity(player))
        {
            if(IsClientInGame(player))
            {
                if(!IsFakeClient(player))
                {
                    UseTip(player);
                }
            }
        }
    }
}

public void Evnet_round(Event event, const char[] name, bool dontBroadcast)
{
	ResetAll();
}

public void Internal_changed()
{
	O_CD_time = GetConVarFloat(C_cdtime);
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
    HookEvent("round_start", Evnet_round);
    C_cdtime = CreateConVar("bc_cdtime", "32.0", "the skill CD time", FCVAR_SPONLY, true, 4.0);
    C_cdtime.AddChangeHook(ConvarChanged);
    AutoExecConfig(true, PATH);
}