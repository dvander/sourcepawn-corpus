#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <colors>

#define PLUGIN_VERSION "2.2"
#define CVAR_FLAGS FCVAR_NOTIFY
#define TEAM_SURVIVOR 2
#define TEAM_INFECTED 3
#define SURVIVOR_MODELS 8

#define MAX_SURVS 6
#define NAME_IF_MAX_SURVS 20
#define NAME_NORMAL 40

static char sSurvivorNames[SURVIVOR_MODELS][] =
{
	"Bill", 
	"Zoey", 
	"Francis", 
	"Louis", 
	"Nick", 
	"Rochelle", 
	"Coach", 
	"Ellis"
};

static char sSurvivorModels[SURVIVOR_MODELS][] =
{
	"models/survivors/survivor_namvet.mdl", 
	"models/survivors/survivor_teenangst.mdl", 
	"models/survivors/survivor_biker.mdl", 
	"models/survivors/survivor_manager.mdl", 
	"models/survivors/survivor_gambler.mdl", 
	"models/survivors/survivor_producer.mdl", 
	"models/survivors/survivor_coach.mdl", 
	"models/survivors/survivor_mechanic.mdl"
};

public Plugin myinfo = 
{
	name = "[L4D1/2] Assistance System v.2",
	author = "[E]c, Ren89 & thrillkill",
	description = "Show damage dealt to killed infected",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net"
}

int DamageSI[MAXPLAYERS + 1][MAXPLAYERS + 1];
int DamageWitch[MAXPLAYERS + 1][2048];
int zClassTank = 5;

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion engine = GetEngineVersion();
	if (engine == Engine_Left4Dead)
	{
		zClassTank = 5;
	}
	else if(engine == Engine_Left4Dead2)
	{
		zClassTank = 8;
	}
	else
	{
		strcopy(error, err_max, "This plugin only runs in \"Left 4 Dead\" game series");
		return APLRes_SilentFailure;
	}
	return APLRes_Success;
}

PluginData plugin;

enum struct PluginCvars
{
	ConVar cvar_AssistEnable;
	ConVar cvar_AssistSI;
	ConVar cvar_AssistWitch;
	ConVar cvar_Frags;

	void Init()
	{
		CreateConVar("sm_assist_version", PLUGIN_VERSION, "Assistance System Version", CVAR_FLAGS|FCVAR_SPONLY|FCVAR_DONTRECORD);
		this.cvar_AssistEnable = CreateConVar("sm_assist_enable", "1", "Enables this plugin.", CVAR_FLAGS, true, 0.0, true, 1.0);
		this.cvar_AssistSI = CreateConVar("sm_assist_si", "0", "Show SI damage (0: only tank, 1: all infected except tank, 2: all infected)", CVAR_FLAGS, true, 0.0, true, 2.0);
		this.cvar_AssistWitch = CreateConVar("sm_assist_witch", "1", "1: Show witch damage, cr0wn, who startled, remaining health, 0: off", CVAR_FLAGS, true, 0.0, true, 1.0);
		this.cvar_Frags = CreateConVar("sm_assist_frags", "1", "1: Show frags and tank(s) remaining health at the round end, 0: off", CVAR_FLAGS, true, 0.0, true, 1.0);

		AutoExecConfig(true, "l4d2_assist_v2");
		
		this.cvar_AssistEnable.AddChangeHook(OnConVarPluginOnChange);
		this.cvar_AssistSI.AddChangeHook(ConVarChanged_Cvars);
		this.cvar_AssistWitch.AddChangeHook(ConVarChanged_Cvars);
		this.cvar_Frags.AddChangeHook(ConVarChanged_Cvars);

		LoadTranslations("l4d2_assist.phrases");
	}
}

enum struct PluginData
{
	PluginCvars cvars;
	bool bHooked;
	bool bPluginOn;
	bool g_bAssistWitch;
	bool g_bFrags;
	bool g_bHealthAndFragsPrinted;
	int g_iAssistSI;
	int Frags[MAXPLAYERS + 1];

	void Init()
	{
		this.cvars.Init();
	}

	void GetCvarValues()
	{
		this.g_iAssistSI = this.cvars.cvar_AssistSI.IntValue;
		this.g_bAssistWitch = this.cvars.cvar_AssistWitch.BoolValue;
		this.g_bFrags = this.cvars.cvar_Frags.BoolValue;
	}

	void IsAllowed()
	{
		this.bPluginOn = this.cvars.cvar_AssistEnable.BoolValue;
		if(!this.bHooked && this.bPluginOn)
		{
			this.bHooked = true;
			HookEvent("player_spawn", Events);
			HookEvent("player_hurt", Events);
			HookEvent("player_death", Events);
			HookEvent("witch_spawn", Events);
			HookEvent("infected_hurt", Events);
			HookEvent("witch_killed", Events);
			HookEvent("round_start", Events);
			HookEvent("round_end", Events);
			HookEvent("map_transition", Events);
			HookEvent("finale_win", Events);
			HookEvent("witch_harasser_set", Events);
			HookEvent("player_incapacitated", Events);
		}
		else if(this.bHooked && !this.bPluginOn)
		{
			this.bHooked = false;
			UnhookEvent("player_spawn", Events);
			UnhookEvent("player_hurt", Events);
			UnhookEvent("player_death", Events);
			UnhookEvent("witch_spawn", Events);
			UnhookEvent("infected_hurt", Events);
			UnhookEvent("witch_killed", Events);
			UnhookEvent("round_start", Events);
			UnhookEvent("round_end", Events);
			UnhookEvent("map_transition", Events);
			UnhookEvent("finale_win", Events);
			UnhookEvent("witch_harasser_set", Events);
			UnhookEvent("player_incapacitated", Events);
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

void ConVarChanged_Cvars(ConVar cvar, const char[] oldVal, const char[] newVal)
{
	plugin.GetCvarValues();
}

Action Events(Event event, char[] name, bool dontBroadcast)
{
    if (strcmp(name, "player_spawn") == 0)
    {
        int client = GetClientOfUserId(event.GetInt("userid"));
        if (IsValidClient(client, TEAM_INFECTED))
        {
            ClearDmgSI(client);
        }
    }
    else if(strcmp(name, "player_hurt") == 0)
    {
        int attacker = GetClientOfUserId(event.GetInt("attacker"));
        int victim = GetClientOfUserId(event.GetInt("userid"));
        if (IsValidClient(attacker, TEAM_SURVIVOR) && IsValidClient(victim, TEAM_INFECTED))
        {
            switch(plugin.g_iAssistSI)
            {
                case 0: if (!IsTank(victim)) return Plugin_Handled;
                case 1: if (IsTank(victim)) return Plugin_Handled;
            }

            int DamageHealth = event.GetInt("dmg_health");
            if (DamageHealth < 1024)
            {
                DamageSI[attacker][victim] += DamageHealth;
            }
        }
    }
    else if(strcmp(name, "player_death") == 0)
    {
        int victim = GetClientOfUserId(event.GetInt("userid"));
        if (IsClient(victim))
        {
            int team = GetClientTeam(victim);
            if (team == TEAM_SURVIVOR)
            {
                if (plugin.g_bAssistWitch && !IsFakeClient(victim))
                {
                    int witch = event.GetInt("attackerentid");
                    if (IsValidEntity(witch) && IsValidEdict(witch))
                    {
                        char class[64];
                        GetEdictClassname(witch, class, sizeof(class));
                        if (StrEqual(class, "witch")) 
                        {
                            CPrintToChat(victim, "%t", "WITCH_REMAINING_HEALTH", GetEntProp(witch, Prop_Data, "m_iHealth"));
                        }
                    }
                }
                ClearDmgSI(victim);
            }
            else if (team == TEAM_INFECTED)
            {
                bool IsVictimTank = IsTank(victim);
                if (plugin.g_bFrags && !IsVictimTank)
                {
                    int attacker = GetClientOfUserId(event.GetInt("attacker"));
                    if (IsValidClient(attacker, TEAM_SURVIVOR))
                    {
                        plugin.Frags[attacker]++;
                        if (!IsFakeClient(attacker)) PrintHintText(attacker, "%t", "FRAGS_HINT", plugin.Frags[attacker]);
                    }
                }

                switch(plugin.g_iAssistSI)
                {
                    case 0:
                    {
                        if (!IsVictimTank)
                        {
                            ClearDmgSI(victim);
                            return Plugin_Handled;
                        }
                    }
                    case 1:
                    {
                        if (IsVictimTank)
                        {
                            ClearDmgSI(victim);
                            return Plugin_Handled;
                        }
                    }
                }

                int survivors, players[MAXPLAYERS + 1][2];
                for (int i = 1; i <= MaxClients; i++)
                {
                    if (DamageSI[i][victim] <= 0 || !IsClientInGame(i) || GetClientTeam(i) != TEAM_SURVIVOR) continue;
                    players[survivors][0] = i;
                    players[survivors][1] = DamageSI[i][victim];
                    survivors++;
                }

                if (survivors == 0) return Plugin_Handled;
                SortCustom2D(players, survivors, SortByDamage);
                char sMessage[256] = "";

                for (int i; i < survivors; i++)
                {
                    int attacker = players[i][0];
                    char sTempMessage[64];
                    Format(sTempMessage, sizeof(sTempMessage), "%t", "DAMAGE_STRING", (i > 0 ? ", " : ""), attacker, DamageSI[attacker][victim]);
                    StrCat(sMessage, sizeof(sMessage), sTempMessage);
                    DamageSI[attacker][victim] = 0;
                }
                CPrintToChatAll("%t", "TANK_KILLED", victim, sMessage);
            }
        }
        else ClearDmgSI(victim);
    }
    else if(strcmp(name, "witch_spawn") == 0)
    {
        if (plugin.g_bAssistWitch)
        {
            int witch = event.GetInt("witchid");
            if (IsValidEntity(witch) && IsValidEdict(witch)) ClearDmgWitch(witch);
        }
    }
    else if(strcmp(name, "round_start") == 0)
    {
        ClearDmgAll();
        plugin.g_bHealthAndFragsPrinted = false;
    }
    else if(strcmp(name, "infected_hurt") == 0)
    {
        if (plugin.g_bAssistWitch)
        {
            int witch = event.GetInt("entityid");
            char class[64];
            GetEdictClassname(witch, class, sizeof(class));
            if (StrEqual(class, "witch", false))
            {
                int attacker = GetClientOfUserId(event.GetInt("attacker"));
                if (IsValidClient(attacker, TEAM_SURVIVOR))
                {
                    int damage = event.GetInt("amount");
                    DamageWitch[attacker][witch] += damage;
                }
            }
        }
    }
    else if(strcmp(name, "witch_harasser_set") == 0)
    {
        if (plugin.g_bAssistWitch)
        {
            int target = GetClientOfUserId(event.GetInt("userid"));
            if (IsValidClient(target, TEAM_SURVIVOR))
            {
                if (IsFakeClient(target))
                {
                    CPrintToChatAll("%t", "WITCH_STARTLED_BOT", target);
                }
                else
                {
                    int iNumMatch = -1;
                    char sSubjectModel[64];
                    GetClientModel(target, sSubjectModel, sizeof(sSubjectModel));
                    for (int i = 0; i < SURVIVOR_MODELS; i++)
                    {
                        if (StrEqual(sSubjectModel, sSurvivorModels[i]))
                        {
                            iNumMatch = i;
                            break;
                        }
                    }
                    if (iNumMatch == -1) CPrintToChatAll("%t", "WITCH_STARTLED", target, "Unknown");
                    else CPrintToChatAll("%t", "WITCH_STARTLED", target, sSurvivorNames[iNumMatch]);
                }
            }
        }
    }
    else if(strcmp(name, "witch_killed") == 0)
    {
        if (plugin.g_bAssistWitch)
        {
            int witch = event.GetInt("witchid");
            if (IsValidEntity(witch) && IsValidEdict(witch))
            {
                int attacker = GetClientOfUserId(event.GetInt("userid"));
                if (IsValidClient(attacker, TEAM_SURVIVOR))
                {
                    if (event.GetBool("oneshot"))
                    {
                        CPrintToChatAll("%t", "WITCH_CROWNED", attacker);
                        ClearDmgWitch(witch);
                    }
                    else
                    {
                        int survivors, players[33][2];
                        for (int i = 1; i <= MaxClients; i++)
                        {
                            if (DamageWitch[i][witch] > 0 && IsClientInGame(i) && GetClientTeam(i) == TEAM_SURVIVOR)
                            {
                                players[survivors][0] = i;
                                players[survivors][1] = DamageWitch[i][witch];
                                survivors++;
                            }
                        }

                        if (survivors == 0) return Plugin_Handled;
                        SortCustom2D(players, survivors, SortByDamage);
                        char sMessage[256] = "";

                        for (int i; i < survivors; i++)
                        {
                            int client = players[i][0];
                            char sTempMessage[64];
                            Format(sTempMessage, sizeof(sTempMessage), "%t", "DAMAGE_STRING", (i > 0 ? ", " : ""), client, DamageWitch[client][witch]);
                            StrCat(sMessage, sizeof(sMessage), sTempMessage);
                            DamageWitch[client][witch] = 0;
                        }
                        CPrintToChatAll("%t", "WITCH_KILLED", sMessage);
                    }
                }
                else ClearDmgWitch(witch);
            }
        }
    }
    else if(strcmp(name, "player_incapacitated") == 0)
    {
        if (plugin.g_bAssistWitch)
        {
            int victim = GetClientOfUserId(event.GetInt("userid"));
            if (IsValidClient(victim, TEAM_SURVIVOR) && !IsFakeClient(victim))
            {
                int witch = event.GetInt("attackerentid");
                if (IsValidEntity(witch) && IsValidEdict(witch))
                {
                    char class[64];
                    GetEdictClassname(witch, class, sizeof(class));
                    if (StrEqual(class, "witch"))
                    {
                        CPrintToChat(victim, "%t", "WITCH_REMAINING_HEALTH", GetEntProp(witch, Prop_Data, "m_iHealth"));
                    }
                }
            }
        }
    }
    else if(strcmp(name, "round_end") == 0 || strcmp(name, "map_transition") == 0 || strcmp(name, "finale_win") == 0)
    {
        if (!plugin.g_bHealthAndFragsPrinted)
        {
            plugin.g_bHealthAndFragsPrinted = true;
            if (plugin.g_bFrags)
            {
                char sMessage[256], sTempMessage[64];
                int Tanks = 0, survivors = 0, players[MAXPLAYERS+1][2];
                for (int i = 1; i <= MaxClients; i++)
                {
                    if (!IsClientInGame(i)) continue;
                    switch(GetClientTeam(i))
                    {
                        case TEAM_SURVIVOR:
                        {
                            if (plugin.Frags[i] > 0)
                            {
                                players[survivors][0] = i;
                                players[survivors][1] = plugin.Frags[i];
                                survivors++;
                            }
                        }
                        case TEAM_INFECTED:
                        {
                            if (IsTank(i) && IsPlayerAlive(i))
                            {
                                Tanks++;
                                Format(sTempMessage, sizeof(sTempMessage), "%t", "TANK_HEALTH_STRING", (Tanks > 1 ? ", " : ""), i, GetClientHealth(i));
                                StrCat(sMessage, sizeof(sMessage), sTempMessage);
                            }
                        }
                    }
                }

                if (Tanks) CPrintToChatAll("%t", "TANK_REMAINING_HEALTH", sMessage);

                if (survivors)
                {
                    sMessage = "", sTempMessage = "";
                    int len = (survivors > MAX_SURVS ? NAME_IF_MAX_SURVS : NAME_NORMAL);
                    SortCustom2D(players, survivors, SortByDamage);

                    for (int i; i < survivors; i++)
                    {
                        int attacker = players[i][0];
                        char[] sName = new char[len];
                        GetClientName(attacker, sName, len);
                        Format(sTempMessage, sizeof(sTempMessage), "%t", "FRAGS_STRING", (i > 0 ? ", " : ""), sName, plugin.Frags[attacker]);
                        StrCat(sMessage, sizeof(sMessage), sTempMessage);
                    }
                    CPrintToChatAll("%t", "FRAGS", sMessage);
                }
            }
            ClearDmgAll();
        }
    }
    return Plugin_Continue;
}

int SortByDamage(int[] x, int[] y, const int[][] array, Handle hndl)
{
	if (x[1] > y[1]) return -1;
	else if (x[1] == y[1]) return 0;
	return 1;
}

void ClearDmgSI(int victim)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		DamageSI[i][victim] = 0;
	}
}

void ClearDmgWitch(int entity)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		DamageWitch[i][entity] = 0;
	}
}

void ClearDmgAll()
{
	for (int i = 1; i <= MaxClients; i++)
	{
		plugin.Frags[i] = 0;
		int x;
		for (x = 1; x <= MaxClients; x++)
		{
			DamageSI[i][x] = 0;
		}
		for (x = MaxClients+1; x < 2048; x++)
		{
			DamageWitch[i][x] = 0;
		}
	}
}

public void OnEntityDestroyed(int entity) //escaped or burned
{
	if (plugin.bHooked && plugin.g_bAssistWitch)
	{
		if (IsValidEntity(entity) && IsValidEdict(entity))
		{
			char class[64];
			GetEdictClassname(entity, class, sizeof(class));
			if (StrEqual(class, "witch"))
            {
                ClearDmgWitch(entity);
            }
		}
	}
}

stock bool IsClient(int client)
{
	return client > 0 && client <= MaxClients && IsClientInGame(client);
}

stock bool IsValidClient(int client, int team)
{
	return IsClient(client) && GetClientTeam(client) == team;
}

stock bool IsTank(int client)
{
	return GetEntProp(client, Prop_Send, "m_zombieClass") == zClassTank;
}

public void OnClientDisconnect(int client)
{
	if(client > 0)
    {
        plugin.Frags[client] = 0;
    }
}
