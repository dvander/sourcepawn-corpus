/*
  "special_new_dash"
{
    "slot"           "0"         // Slot zdolności
    "maxdist"        "9999.0"    // Maksymalna odległość
    "initial"        "8.0"       // Początkowy czas odnowienia
    "buttonmode"     "11"        // Tryb przycisku (11 to IN_ATTACK2)
    "charges"        "1"         // Początkowa liczba punktów
    "stack"          "3"         // Maksymalna liczba punktów
    "cooldown"       "6.0"       // Czas odnowienia (w sekundach)
    
    "hud_x"          "-1.0"      // Pozycja X na HUD
    "hud_y"          "0.75"      // Pozycja Y na HUD
    
    "strings"        "New Dash: [%s][%d/%d]" // Tekst na HUD
    
    "plugin_name"    "ff2r_new_dash" // Nazwa subpluginu
}
*/

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <cfgmap>
#include <ff2r>
#include <tf2_stocks>
#include <tf2items>

#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_VERSION "1.00"
#define NOPE_AVI "vo/engineer_no01.mp3"
#define MAXTF2PLAYERS 36

public Plugin myinfo =
{
    name         = "Freak Fortress 2 Rewrite: New Dash",
    author       = "Onimusha",
    description  = "New Dash Mechanic for FF2R",
    version      = PLUGIN_VERSION,
    url          = ""
};

Handle HudDash;
float TP_Cooldown[MAXTF2PLAYERS];
bool TP_InUse[MAXTF2PLAYERS];
bool TP_Enabled[MAXTF2PLAYERS];
int TP_Charges[MAXTF2PLAYERS];
int TP_MaxCharges[MAXTF2PLAYERS];
float TP_HudX[MAXTF2PLAYERS];
float TP_HudY[MAXTF2PLAYERS];
char TP_HudText[MAXTF2PLAYERS][256];
int TP_ButtonMode[MAXTF2PLAYERS];

public void OnPluginStart()
{
    HudDash = CreateHudSynchronizer();
    PrintToServer("FF2R Dash Plugin v%s Loaded!", PLUGIN_VERSION);

    LoadDashConfig();
}

public void OnPluginEnd()
{
    for (int clientIdx = 1; clientIdx <= MaxClients; clientIdx++)
    {
        TP_InUse[clientIdx] = false;
        TP_Enabled[clientIdx] = false;
    }
}

public void LoadDashConfig()
{
    for (int clientIdx = 1; clientIdx <= MaxClients; clientIdx++)
    {
        
        BossData bossData = FF2R_GetBossData(clientIdx);

      
        AbilityData dash = bossData.GetAbility("special_new_dash");

       
        if (!dash.IsMyPlugin())
        {
            TP_Enabled[clientIdx] = false;
            continue;
        }

        
        TP_Charges[clientIdx] = dash.GetInt("charges", 1);
        TP_MaxCharges[clientIdx] = dash.GetInt("stack", 3);
        TP_Cooldown[clientIdx] = GetGameTime() + dash.GetFloat("initial", 8.0);
        TP_HudX[clientIdx] = dash.GetFloat("hud_x", -1.0);
        TP_HudY[clientIdx] = dash.GetFloat("hud_y", 0.75);
        TP_ButtonMode[clientIdx] = dash.GetInt("buttonmode", 11);

       
        dash.GetString("strings", TP_HudText[clientIdx], sizeof(TP_HudText[clientIdx]), "New Dash: [%s][%d/%d]");
    }
}

public void FF2R_OnBossRemoved(int clientIdx)
{
    TP_Cooldown[clientIdx] = GetGameTime();
    TP_Enabled[clientIdx] = false;
}

public void FF2R_OnBossCreated(int clientIdx, BossData cfg, bool setup)
{
    if (!setup || FF2R_GetGamemodeType() != 2)
        return;

    
    if (cfg.GetAbility("special_new_dash").IsMyPlugin())
    {
        TP_Enabled[clientIdx] = true;
        TP_Cooldown[clientIdx] = GetGameTime() + cfg.GetAbility("special_new_dash").GetFloat("initial", 8.0);
    }
}

public Action Tick_Dash(int clientIdx, int &buttons)
{
   
    BossData bossData = FF2R_GetBossData(clientIdx);
    AbilityData dash = bossData.GetAbility("special_new_dash");

   
    if (!dash.GetBool("enabled", true))
        return Plugin_Continue;

    float gameTime = GetGameTime();
    int charges = TP_Charges[clientIdx];
    int maxCharges = TP_MaxCharges[clientIdx];
    int buttonMode = TP_ButtonMode[clientIdx];

    
    if (!(buttons & IN_SCORE))
    {
        float hud_x = TP_HudX[clientIdx];
        float hud_y = TP_HudY[clientIdx];

        char hudText[256];
        Format(hudText, sizeof(hudText), TP_HudText[clientIdx], charges, maxCharges);

        char duration[32];
        if (charges >= maxCharges)
        {
            Format(duration, sizeof(duration), "MAX");
            SetHudTextParams(hud_x, hud_y, 0.1, 255, 255, 255, 255);
        }
        else
        {
            Format(duration, sizeof(duration), "%.1f", TP_Cooldown[clientIdx] - gameTime);
            SetHudTextParams(hud_x, hud_y, 0.1, 255, (charges > 0) ? 255 : 64, (charges > 0) ? 255 : 64, 255);
        }

        ShowSyncHudText(clientIdx, HudDash, hudText, duration, charges, maxCharges);
    }

  
    if (charges < maxCharges && TP_Cooldown[clientIdx] <= gameTime)
    {
        TP_Charges[clientIdx] = charges + 1;
        TP_Cooldown[clientIdx] = gameTime + dash.GetFloat("cooldown", 6.0);
    }

  
    if ((buttons & ReturnButtonMode(buttonMode)) && charges > 0 && !TP_InUse[clientIdx])
    {
        TP_Charges[clientIdx]--;
        TP_InUse[clientIdx] = true;

       
    }

    return Plugin_Continue;
}

stock int ReturnButtonMode(int mode)
{
    switch (mode)
    {
        case 0: return IN_ATTACK;
        case 1: return IN_JUMP;
        case 2: return IN_DUCK;
        case 3: return IN_FORWARD;
        case 4: return IN_BACK;
        case 5: return IN_USE;
        case 6: return IN_CANCEL;
        case 7: return IN_LEFT;
        case 8: return IN_RIGHT;
        case 9: return IN_MOVELEFT;
        case 10: return IN_MOVERIGHT;
        case 11: return IN_ATTACK2;
        case 12: return IN_RUN;
        case 13: return IN_RELOAD;
        case 14: return IN_ALT1;
        case 15: return IN_ALT2;
        case 16: return IN_SCORE;
        case 17: return IN_SPEED;
        case 18: return IN_WALK;
        case 19: return IN_ZOOM;
        case 20: return IN_WEAPON1;
        case 21: return IN_WEAPON2;
        case 22: return IN_BULLRUSH;
        case 23: return IN_GRENADE1;
        case 24: return IN_GRENADE2;
        case 25: return IN_ATTACK3;
        default: return IN_RELOAD;
    }
}
