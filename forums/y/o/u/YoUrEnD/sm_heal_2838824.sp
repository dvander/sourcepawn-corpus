#pragma semicolon 1
#include <sourcemod>
#include <sdktools>

public Plugin myinfo =
{
    name        = "Effect Heal",
    author      = "YoUr-EnD",
    description = "Heals with effects",
    version     = "1.0",
    url         = ""
};

//ConVars
ConVar g_cvHealMaxHP;
ConVar g_cvHealSound;
ConVar g_cvHealSprite;
ConVar g_cvHealFlag;
ConVar g_cvHealAmount;
ConVar g_cvHealSpriteScale;

int g_iSpriteModel = -1;

public void OnPluginStart()
{
    RegConsoleCmd("sm_heal", Command_Heal);

    g_cvHealMaxHP       = CreateConVar("sm_heal_maxhp", "100", "Maximum HP after healing.");
    g_cvHealSound       = CreateConVar("sm_heal_sound", "items/smallmedkit1.wav", "Path to healing sound (relative to sound/).");
    g_cvHealSprite      = CreateConVar("sm_heal_sprite", "materials/effects/heal_aura.vmt", "Path to glow sprite (.vmt file from materials/). Leave empty to disable sprite.");
    g_cvHealFlag        = CreateConVar("sm_heal_flag", "", "Admin flag required to use command. Leave empty to allow everyone.");
    g_cvHealAmount      = CreateConVar("sm_heal_amount", "100", "Amount of HP to add when using sm_heal.");
    g_cvHealSpriteScale = CreateConVar("sm_heal_sprite_scale", "0.2", "Glow sprite size for sm_heal visual.");

    AutoExecConfig(true, "sm_heal");
}

public void OnMapStart()
{
    // Load healing sound
    char soundPath[PLATFORM_MAX_PATH];
    g_cvHealSound.GetString(soundPath, sizeof(soundPath));

    if (soundPath[0] != '\0')
    {
        char downloadPath[PLATFORM_MAX_PATH];
        Format(downloadPath, sizeof(downloadPath), "sound/%s", soundPath);
        AddFileToDownloadsTable(downloadPath);
        PrecacheSound(soundPath, true);
    }

    // Load glow sprite
    char spritePath[PLATFORM_MAX_PATH];
    g_cvHealSprite.GetString(spritePath, sizeof(spritePath));
    g_iSpriteModel = -1;

    if (spritePath[0] != '\0')
    {
        // Adding files to downloadtable
        AddFileToDownloadsTable(spritePath);

        char vtfPath[PLATFORM_MAX_PATH];
        strcopy(vtfPath, sizeof(vtfPath), spritePath);
        ReplaceString(vtfPath, sizeof(vtfPath), ".vmt", ".vtf", false);
        AddFileToDownloadsTable(vtfPath);

        int spriteIdx = PrecacheModel(spritePath, true);
        if (spriteIdx > 0)
        {
            g_iSpriteModel = spriteIdx;
        }
    }
}

public Action Command_Heal(int client, int args)
{
    bool isConsole = (client == 0);

    if (args < 1)
    {
        ReplyToCommand(client, "Usage: sm_heal <name|@me|@all|#userid>");
        return Plugin_Handled;
    }

    // Check access permission
    char flagStr[16];
    g_cvHealFlag.GetString(flagStr, sizeof(flagStr));

    if (!isConsole && flagStr[0] != '\0' && !(GetUserFlagBits(client) & ReadFlagString(flagStr)))
    {
        ReplyToCommand(client, "You do not have permission to use this command.");
        return Plugin_Handled;
    }

    // Parse target
    char pattern[64];
    GetCmdArg(1, pattern, sizeof(pattern));

    int targets[MAXPLAYERS + 1], targetCount;
    bool tn_is_ml;
    char targetName[MAX_TARGET_LENGTH];

    targetCount = ProcessTargetString(pattern, client, targets, sizeof(targets), COMMAND_FILTER_ALIVE, targetName, sizeof(targetName), tn_is_ml);
    if (targetCount <= 0)
    {
        ReplyToTargetError(client, targetCount);
        return Plugin_Handled;
    }

    // values from ConVars
    int maxHP   = g_cvHealMaxHP.IntValue;
    int addHP   = g_cvHealAmount.IntValue;
    float scale = g_cvHealSpriteScale.FloatValue;

    char soundPath[PLATFORM_MAX_PATH];
    g_cvHealSound.GetString(soundPath, sizeof(soundPath));

    for (int i = 0; i < targetCount; i++)
    {
        int t = targets[i];

        int currentHP = GetClientHealth(t);
        int newHP = currentHP + addHP;
        if (newHP > maxHP)
            newHP = maxHP;
        if (newHP < 1)
            newHP = 1;

        SetEntityHealth(t, newHP);

        if (soundPath[0] != '\0')
        {
            EmitSoundToClient(t, soundPath);
        }

        if (g_iSpriteModel > 0)
        {
            float position[3];
            GetClientAbsOrigin(t, position);
            position[2] += 50.0;

            int color = 0xFFFFFFFF;
            float life = 1.5;
            float size = (scale > 0.0) ? scale : 1.5;

            TE_SetupGlowSprite(position, g_iSpriteModel, life, size, color);
            TE_SendToAll();
        }
    }

    PrintToChatAll("[Heal] %s has been healed!", targetName);
    return Plugin_Handled;
}
