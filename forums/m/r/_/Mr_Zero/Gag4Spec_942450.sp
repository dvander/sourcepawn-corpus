#pragma semicolon 1
#include <sourcemod>

#define PLUGIN_VERSION	"1.1"
#define L4D_TEAM_SURVIVOR 2
#define L4D_TEAM_SPECTATOR 1

#define IsGameActive() g_bIsGameActive
#define IsInRoundChange() g_bInRoundChange

#define IsPluginEnabled() g_bIsEnabled
#define IsRedirectingSayToSayTeam() g_bShouldRedirectSay
#define GetGagImmunityLevel() g_GagImmunityLevel

#define IsClientGagImmune(%1) (GetGagImmunityLevel() != 0 && GetAdminImmunityLevel(GetUserAdmin(%1)) >= GetGagImmunityLevel())
#define IsClientSurvivor(%1) (GetClientTeam(%1) == L4D_TEAM_SURVIVOR)
#define IsClientSpectator(%1) (GetClientTeam(%1) == L4D_TEAM_SPECTATOR)

#define IsUngagingUponRoundEnd() GetConVarBool(g_hUngagRoundEnd)
#define IsUngagingUponMissionLost() GetConVarBool(g_hUngagLost)
#define IsUngagingUponInSaferoom() GetConVarBool(g_hUngagSafe)
#define IsUngagingUponRescue() GetConVarBool(g_hUngagRescued)

static          Handle: g_hUngagSafe;
static          Handle: g_hUngagLost;
static          Handle: g_hUngagRescued;
static          Handle: g_hUngagRoundEnd;

static          bool:   g_bIsGameActive;
static          bool:   g_bInRoundChange;
static          bool:   g_bIsEnabled;
static          bool:   g_bShouldRedirectSay;
static                  g_GagImmunityLevel;

public Plugin:myinfo = 
{
    name = "Gag4Spec",
    author = "Mr. Zero",
    description = "Prevent spectators from using all chat (say command) while the game is active. Can ungag on different conditions.",
    version = PLUGIN_VERSION,
    url = "http://forums.alliedmods.net/showthread.php?t=104518"
}

public OnPluginStart()
{
    CreateConVar("l4d_g4s_version", PLUGIN_VERSION, "Gag4Spec SourceMod Plugin Version", FCVAR_PLUGIN | FCVAR_NOTIFY | FCVAR_DONTRECORD);

    new Handle:convar = CreateConVar("l4d_g4s_enable", "1", "Sets whether Gag4Spec is active", FCVAR_PLUGIN);
    g_bIsEnabled = GetConVarBool(convar);
    HookConVarChange(convar, OnPluginEnabled_ConVarChanged);

    convar = CreateConVar("l4d_g4s_redirect", "1", "Sets whether say commands gets redirected to say_team, for Spectators, while the game is active. 0 to disable redirect.", FCVAR_PLUGIN);
    g_bShouldRedirectSay = GetConVarBool(convar);
    HookConVarChange(convar, OnRedirectSay_ConVarChanged);

    convar = CreateConVar("l4d_g4s_gagimmunity", "0", "Immunity level required from admin to protect against gagging while game is active. 0 to disable immunity from gagging", FCVAR_PLUGIN);
    g_GagImmunityLevel = GetConVarInt(convar);
    HookConVarChange(convar, OnGagImmunityLvl_ConVarChanged);

    g_hUngagSafe = CreateConVar("l4d_g4s_ungag_safe", "1", "Sets whether Spectators is allowed to all chat while survivors still haven't left saferoom.", FCVAR_PLUGIN);
    g_hUngagLost = CreateConVar("l4d_g4s_ungag_lost", "1", "Sets whether Spectators is allowed to all chat when the survivors looses.", FCVAR_PLUGIN);
    g_hUngagRescued = CreateConVar("l4d_g4s_ungag_rescued", "1", "Sets whether Spectators is allowed to all chat when the rescue vehicle is taking off.", FCVAR_PLUGIN);
    g_hUngagRoundEnd = CreateConVar("l4d_g4s_ungag_roundend", "1", "Sets whether Spectators is allowed to all chat when a round is ending (scores are being displayed).", FCVAR_PLUGIN);

    AutoExecConfig(true, "Gag4Spec");

    HookEvent("player_left_start_area", OnPlayerLeftStartArea_Event);
    HookEvent("player_left_checkpoint", OnPlayerLeftStartArea_Event);
    HookEvent("round_start", OnRoundStart_Event, EventHookMode_PostNoCopy);
    HookEvent("mission_lost", OnSurvivorsLost_Event, EventHookMode_PostNoCopy);
    HookEvent("round_freeze_end", OnRoundEnd_Event, EventHookMode_PostNoCopy);
    HookEvent("finale_vehicle_leaving", OnSurvivorsRescued_Event, EventHookMode_PostNoCopy);

    AddCommandListener(OnSay_Command, "say");
}

public OnPluginEnabled_ConVarChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
    g_bIsEnabled = GetConVarBool(convar);
}

public OnRedirectSay_ConVarChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
    g_bShouldRedirectSay = GetConVarBool(convar);
}

public OnGagImmunityLvl_ConVarChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
    g_GagImmunityLevel = GetConVarInt(convar);
}

public OnPlayerLeftStartArea_Event(Handle:event, const String:name[], bool:dontBroadcast)
{
    if (IsGameActive() || IsInRoundChange())
    {
        return;
    }

    new client = GetClientOfUserId(GetEventInt(event, "userid"));
    if (client <= 0 || client > MaxClients || !IsClientInGame(client) || !IsClientSurvivor(client) || !IsPlayerAlive(client))
    {
        return;
    }

    g_bIsGameActive = true;
}

public OnSurvivorsLost_Event(Handle:event, const String:name[], bool:dontBroadcast)
{
    if (IsUngagingUponMissionLost())
    {
        g_bIsGameActive = false;
    }

    g_bInRoundChange = true;
}

// Note: round_freeze_end triggers AFTER round_start if gamemode is not versus.
public OnRoundEnd_Event(Handle:event, const String:name[], bool:dontBroadcast)
{
    if (IsUngagingUponRoundEnd())
    {
        g_bIsGameActive = false;
    }
}

public OnSurvivorsRescued_Event(Handle:event, const String:name[], bool:dontBroadcast)
{
    if (IsUngagingUponRescue())
    {
        g_bIsGameActive = false;
    }

    g_bInRoundChange = true;
}

public OnRoundStart_Event(Handle:event, const String:name[], bool:dontBroadcast)
{
    if (IsUngagingUponInSaferoom())
    {
        g_bIsGameActive = false;
    }
    else
    {
        g_bIsGameActive = true;
    }

    g_bInRoundChange = false;
}

public Action:OnSay_Command(client, const String:command[], argc)
{
    if (!IsPluginEnabled() || !IsGameActive() || argc == 0 ||
        client <= 0 || client > MaxClients || !IsClientInGame(client) || !IsClientSpectator(client) || IsClientGagImmune(client))
    {
        return Plugin_Continue;
    }

    if (IsRedirectingSayToSayTeam())
    {
        decl String:text[192];
        text[0] = '\0'; // Quick initialize string
        GetCmdArgString(text, 192);
        FakeClientCommandEx(client,"say_team %s", text);
    }

    return Plugin_Handled;
}