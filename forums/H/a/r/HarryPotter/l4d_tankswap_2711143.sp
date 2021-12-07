#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <left4dhooks>

#define PLUGIN_VERSION "1.3"

char SURRENDER_BUTTON_STRING[]      = "RELOAD"; // what is shown in the Notification as Button to press
int SURRENDER_BUTTON                       = IN_RELOAD; // Sourcemod Button definition. Alternatives: IN_DUCK, IN_USE

float CONTROL_DELAY_SAFETY             = 0.3;
float CONTROL_RETRY_DELAY              = 2.0;
int TEAM_INFECTED                          = 3;
int ZOMBIECLASS_TANK                       = 5;

ConVar cvar_SurrenderTimeLimit               = null;
ConVar cvar_SurrenderChoiceType              = null;
Handle surrenderMenu                         = null;

bool withinTimeLimit                         = false;
int primaryTankPlayer                            = -1;
int tankAttemptsFailed                         = 0;
bool g_bIsTankAlive;

public Plugin myinfo = 
{
    name = "L4D Tank Swap",
    author = "AtomicStryker, HarryPotter",
    description = " Allows a primary Tank Player to surrender control to one of his teammates",
    version = PLUGIN_VERSION,
    url = "https://forums.alliedmods.net/showthread.php?t=326155"
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max) 
{
	EngineVersion test = GetEngineVersion();
	
    if(test == Engine_Left4Dead) ZOMBIECLASS_TANK = 5;
    else if (test == Engine_Left4Dead2) ZOMBIECLASS_TANK = 8;
	else
    {
		strcopy(error, err_max, "Plugin only supports Left 4 Dead 1 & 2.");
		return APLRes_SilentFailure;
	}
	
	return APLRes_Success; 
}

public void OnPluginStart()
{
    cvar_SurrenderTimeLimit = CreateConVar("l4d_tankswap_timelimit", "15", " How many seconds can a primary Tank Player surrender control ", FCVAR_NOTIFY);
    cvar_SurrenderChoiceType = CreateConVar("l4d_tankswap_choicetype", "2", " 0 - Disabled; 1 - press Reload Button to call Menu; 2 - Menu appears for every Tank ", FCVAR_NOTIFY);
    
    LoadTranslations("common.phrases");
    
    HookEvent("tank_spawn", TC_ev_TankSpawn);
    HookEvent("round_start", TC_ev_RoundStart);
    HookEvent("entity_killed", TC_ev_EntityKilled);

    AutoExecConfig(true, "l4d_tankswap");
}

public Action TC_ev_RoundStart(Event event, const char[] name, bool dontBroadcast) 
{
	g_bIsTankAlive = false;
}

public Action TC_ev_TankSpawn(Event event, const char[] name, bool dontBroadcast) 
{
    if(g_bIsTankAlive) return Plugin_Continue;
	
    int tankclientid = event.GetInt("userid");
    int tankclient = GetClientOfUserId(event.GetInt("userid"));
    g_bIsTankAlive = true;
    float PlayerControlDelay = FindConVar("director_tank_lottery_selection_time").FloatValue;
    //PrintToChatAll("tankclientid %d",tankclientid);
    if(IsFakeClient(tankclient))
    {
        switch (cvar_SurrenderChoiceType.IntValue)
        {
            case 0:     return Plugin_Continue;
            case 1:     CreateTimer(PlayerControlDelay + CONTROL_DELAY_SAFETY, TS_DisplayNotificationToTank, 0);
            case 2:     CreateTimer(PlayerControlDelay + CONTROL_DELAY_SAFETY, TS_Display_Auto_MenuToTank, 0);
        }
    }
    else
    {
        switch (cvar_SurrenderChoiceType.IntValue)
        {
            case 0:     return Plugin_Continue;
            case 1:     CreateTimer(CONTROL_DELAY_SAFETY, TS_DisplayNotificationToTank, tankclientid);
            case 2:     CreateTimer(CONTROL_DELAY_SAFETY, TS_Display_Auto_MenuToTank, tankclientid);
        }
    }
    return Plugin_Continue;
}

public Action TS_DisplayNotificationToTank(Handle timer, int clientid)
{
    primaryTankPlayer = GetClientOfUserId(clientid);
    if(primaryTankPlayer == 0 || !IsClientInGame(primaryTankPlayer))
        primaryTankPlayer = FindHumanTankPlayer();

    if (!primaryTankPlayer)
    {
        tankAttemptsFailed++;
        if (tankAttemptsFailed < 5)
        {
            CreateTimer(CONTROL_RETRY_DELAY, TS_DisplayNotificationToTank);
        }
        return Plugin_Stop;
    }
    
    withinTimeLimit = true;
    float SurrenderTimeLimit = cvar_SurrenderTimeLimit.FloatValue;
    CreateTimer(SurrenderTimeLimit, TS_TimeLimitIsOver);
    PrintToChat(primaryTankPlayer, "\x04[Tank Swap]\x01 You can \x03surrender Tank Control\x01 during the next \x04%i seconds\x01 to one of your teammates by pressing \x04%s\x01", RoundFloat(SurrenderTimeLimit), SURRENDER_BUTTON_STRING);
    return Plugin_Stop;
}

public Action TS_TimeLimitIsOver(Handle timer)
{
    withinTimeLimit = false;
    if (surrenderMenu != null)
    {
        surrenderMenu = null;
    }
    
    return Plugin_Stop;
}

static int FindHumanTankPlayer()
{
    for (int i = 1; i <= MaxClients; i++)
    {
        if (!IsClientInGame(i)) continue;
        if (GetClientTeam(i) != TEAM_INFECTED) continue;
        if (!IsPlayerTank(i)) continue;
        if (GetClientHealth(i) < 1 || !IsPlayerAlive(i)) continue;
        
        return i;
    }
    
    return 0;
}

bool IsPlayerTank (int client)
{
    return (GetEntProp(client, Prop_Send, "m_zombieClass") == ZOMBIECLASS_TANK);
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon)
{
    if (!withinTimeLimit) return Plugin_Continue;
    if (client != primaryTankPlayer) return Plugin_Continue;
    
    if (buttons & SURRENDER_BUTTON)
    {
        withinTimeLimit = false;
        CallSurrenderMenu();
        return Plugin_Handled;
    }
    
    return Plugin_Continue;
}

static void CallSurrenderMenu()
{
    surrenderMenu = CreateMenu(TS_MenuCallBack);
    SetMenuTitle(surrenderMenu, " Who shall be Tank instead ");
    
    char name[MAX_NAME_LENGTH], number[10];
    int electables;
    
    AddMenuItem(surrenderMenu, "0", "Anyone but me!");
    
    for (int i = 1; i <= MaxClients; i++)
    {
        if (i == primaryTankPlayer) continue;
        if (!IsClientInGame(i)) continue;
        if (GetClientTeam(i) != TEAM_INFECTED) continue;
        if (IsFakeClient(i)) continue;
        
        
        Format(name, sizeof(name), "%N", i);
        Format(number, sizeof(number), "%i", i);
        AddMenuItem(surrenderMenu, number, name);
        
        electables++;
    }

    
    if (electables > 0) //only do all that if there is someone to swap to
    {
        SetMenuExitButton(surrenderMenu, false);
        DisplayMenu(surrenderMenu, primaryTankPlayer, cvar_SurrenderTimeLimit.IntValue);
    }
}

public int TS_MenuCallBack(Handle menu, MenuAction action, int param1, int param2)
{
    if (action == MenuAction_End) CloseHandle(menu);

    if (action != MenuAction_Select) return; // only allow a valid choice to pass
    
    char number[4];
    GetMenuItem(menu, param2, number, sizeof(number));
    
    int choice = StringToInt(number);
    if (!choice)
    {
        choice = GetRandomEligibleTank();
        if (GetClientHealth(choice) > 1 && !IsPlayerGhost(choice))
        {
            L4D_ReplaceWithBot(choice);
        }
        L4D_ReplaceTank(primaryTankPlayer, choice);
        
        PrintToChatAll("\x04[Tank Swap]\x01 Tank Control was surrendered randomly to: \x03%N\x01", choice);
    }
    else
    {
        if (GetClientHealth(choice) > 1 && !IsPlayerGhost(choice))
        {
            L4D_ReplaceWithBot(choice);
        }
        L4D_ReplaceTank(primaryTankPlayer, choice);
        
    }
}

public Action TS_Display_Auto_MenuToTank(Handle timer, int clientid)
{
    //PrintToChatAll("TS_Display_Auto_MenuToTank %d",clientid);
    primaryTankPlayer = GetClientOfUserId(clientid);
    if(primaryTankPlayer == 0 || !IsClientInGame(primaryTankPlayer))
        primaryTankPlayer = FindHumanTankPlayer();

    if (!primaryTankPlayer)
    {
        if (HasTeamHumanPlayers(3))
        {
            CreateTimer(CONTROL_RETRY_DELAY, TS_Display_Auto_MenuToTank);
            return Plugin_Stop;
        }
        else
        {
            return Plugin_Stop;
        }
    }

    surrenderMenu = CreateMenu(TS_Auto_MenuCallBack);
    SetMenuTitle(surrenderMenu, " Tank Control Menu ");
    
    char name[MAX_NAME_LENGTH], number[10];
    int electables;
    
    AddMenuItem(surrenderMenu, "0", "I want to stay Tank!");
    AddMenuItem(surrenderMenu, "99", "Anyone but me!");
    
    for (int i = 1; i <= MaxClients; i++)
    {
        if (i == primaryTankPlayer) continue;
        if (!IsClientInGame(i)) continue;
        if (GetClientTeam(i) != TEAM_INFECTED) continue;
        if (IsFakeClient(i)) continue;
        
        Format(name, sizeof(name), "%N", i);
        Format(number, sizeof(number), "%i", i);
        AddMenuItem(surrenderMenu, number, name);
        
        electables++;
    }
    
    if (electables > 0) //only do all that if there is someone to swap to
    {
        SetMenuExitButton(surrenderMenu, false);
        DisplayMenu(surrenderMenu, primaryTankPlayer, 2 * cvar_SurrenderTimeLimit.IntValue);
    }
    
    return Plugin_Stop;
}

bool HasTeamHumanPlayers(int team)
{
    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsClientInGame(i)
        && GetClientTeam(i) == team
        && !IsFakeClient(i))
        {
            return true;
        }
    }
    return false;
}

public int TS_Auto_MenuCallBack(Handle menu, MenuAction action, int param1, int param2)
{
    if (action == MenuAction_End) CloseHandle(menu);
    
    if (action != MenuAction_Select) return; // only allow a valid choice to pass
    
    char number[4];
    GetMenuItem(menu, param2, number, sizeof(number));

    int choice = StringToInt(number);
    if (!choice) 
    {
        PrintToChatAll("\x04[Tank Swap]\x01 \x03%N\x01: I want to stay Tank\x01", primaryTankPlayer);
        return; // "I want to stay Tank"
    }
    else if (choice == 99)  // "Anyone but me"
    {
        choice = GetRandomEligibleTank();
        if (GetClientHealth(choice) > 1 && !IsPlayerGhost(choice))
        {
            L4D_ReplaceWithBot(choice);
        }
        L4D_ReplaceTank(primaryTankPlayer, choice);
        
        PrintToChatAll("\x04[Tank Swap]\x01 Tank Control was surrendered randomly to: \x03%N\x01", choice);
    }
    else    // choice is a specific player id
    {
        if (GetClientHealth(choice) > 1 && !IsPlayerGhost(choice))
        {
            L4D_ReplaceWithBot(choice);
        }
        L4D_ReplaceTank(primaryTankPlayer, choice);
        
        PrintToChatAll("\x04[Tank Swap]\x01 Tank Control was surrendered to: \x03%N\x01", choice);
    }
}

bool IsPlayerGhost (int client)
{
	if (GetEntProp(client, Prop_Send, "m_isGhost"))
		return true;
	return false;
}

static int GetRandomEligibleTank()
{
    int electables;
    int[] pool = new int[MaxClients/2];
    
    for (int i = 1; i <= MaxClients; i++)
    {
        if (i == primaryTankPlayer) continue;
        if (!IsClientInGame(i)) continue;
        if (GetClientTeam(i) != TEAM_INFECTED) continue;
        if (IsFakeClient(i)) continue;
        
        electables++;
        pool[electables] = i;
    }
    
    return pool[ GetRandomInt(1, electables) ];
}

public Action TC_ev_EntityKilled(Event event, const char[] name, bool dontBroadcast) 
{
	decl client;
	if (g_bIsTankAlive && IsPlayerTank((client = GetEventInt(event, "entindex_killed"))))
	{
		CreateTimer(1.5, FindAnyTank, client, TIMER_FLAG_NO_MAPCHANGE);
	}
}

public Action FindAnyTank(Handle timer, int client)
{
	if(!IsTankInGame()){
        g_bIsTankAlive = false;
        tankAttemptsFailed = 0;
	}
}

int IsTankInGame(int exclude = 0)
{
	for (int i = 1; i <= MaxClients; i++)
		if (exclude != i && IsClientInGame(i) && GetClientTeam(i) == 3 && IsPlayerTank(i) && IsInfectedAlive(i) && !IsIncapacitated(i))
			return i;

	return 0;
}

stock bool IsIncapacitated(int client)
{
    if(GetEntProp(client, Prop_Send, "m_isIncapacitated"))
        return true;
    return false;
}

stock bool IsInfectedAlive(int client)
{
	return GetEntProp(client, Prop_Send, "m_iHealth") > 1;
}