// vim: set ai et ts=4 sw=4 syntax=sourcepawn :

#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <tf2_stocks>

#define PLUGIN_NAME "BlessCurse"
#define VERSION "1.20"

public Plugin:myinfo = 
{
    name = PLUGIN_NAME,
    author = "Sneakret <sneakret@sneakret.com>",
    description = "Bless or curse players to change damage taken/dealt.",
    version = VERSION,
    url = "http://www.sneakret.com"
};

#define DEFAULT_BLESSING_LEVEL 4.0
#define DEFAULT_CURSE_LEVEL 4.0

GetConnectedPlayers(
    sourceClientEntity,
    String:targetSpecifier[],
    targets[])
{
    new String:targetName[MAX_TARGET_LENGTH];
    new bool:tn_is_ml;
    return ProcessTargetString(
        targetSpecifier,
        sourceClientEntity,
        targets,
        MAXPLAYERS,
        COMMAND_FILTER_CONNECTED,
        targetName,
        sizeof(targetName),
        tn_is_ml);
}

PluginReplyToCommand(entity, String:format[], any:...)
{
    new String:buffer[100];
    VFormat(buffer, sizeof(buffer), format, 3);
    ReplyToCommand(entity, "[%s] %s", PLUGIN_NAME, buffer);
}

bool:IsClientEntity(entity)
{
    return (entity > 0 && entity <= MaxClients);
}

new Float:PlayerBlessCurseLevels[MAXPLAYERS + 1];

HookEntDamage(entity)
{
    SDKHook(entity, SDKHook_OnTakeDamage, OnTakeDamage);
}

public OnPluginStart()
{
    for (new clientEntity = 1; clientEntity < (MaxClients + 1); clientEntity++)
    {
        if (IsClientInGame(clientEntity))
        {
            PlayerBlessCurseLevels[clientEntity] = 1.0;
            HookEntDamage(clientEntity);
        }
    }

    RegAdminCmd(
        "sm_blessed",
        OnShowBlessedCmd,
        ADMFLAG_GENERIC,
        "List blessed/cursed players.");

    RegAdminCmd(
        "sm_cursed",
        OnShowBlessedCmd,
        ADMFLAG_GENERIC,
        "List blessed/cursed players.");

    RegAdminCmd(
        "sm_bless",
        OnBlessCmd,
        ADMFLAG_GENERIC,
        "Bless players.");

    RegAdminCmd(
        "sm_unbless",
        OnUnblessCmd,
        ADMFLAG_GENERIC,
        "Unbless players.");

    RegAdminCmd(
        "sm_curse",
        OnCurseCmd,
        ADMFLAG_GENERIC,
        "Curse players.");

    RegAdminCmd(
        "sm_uncurse",
        OnUncurseCmd,
        ADMFLAG_GENERIC,
        "Uncurse players.");
}

public OnClientPutInServer(clientEntity)
{
    // Reset the newly occupied client slot.
    PlayerBlessCurseLevels[clientEntity] = 1.0;

    HookEntDamage(clientEntity);
}

public Action:OnShowBlessedCmd(sourceClientEntity, argCount)
{
    new blessedCursedCount = 0;

    for (new targetEntity = 1; targetEntity <= MAXPLAYERS; targetEntity++)
    {
        new Float:curseLevel = PlayerBlessCurseLevels[targetEntity];
        if (curseLevel > 1.0)
        {
            blessedCursedCount++;
            PluginReplyToCommand(
                sourceClientEntity,
                "%N (curse level %0.2f)",
                targetEntity,
                curseLevel);
        }
        else if (curseLevel < 1.0)
        {
            blessedCursedCount++;
            PluginReplyToCommand(
                sourceClientEntity,
                "%N (blessing level %0.2f)",
                targetEntity,
                1.0 / curseLevel);
        }
    }

    if (blessedCursedCount == 0)
    {
        PluginReplyToCommand(sourceClientEntity, "No blessed/cursed players.");
    }

    return Plugin_Handled;
}

public Action:OnBlessCmd(sourceClientEntity, argCount)
{
    if (argCount != 1 && argCount != 2)
    {
        PluginReplyToCommand(
            sourceClientEntity,
            "Usage: sm_bless <targetname/#userid> [blessinglevel=4.0]");
        PluginReplyToCommand(
            sourceClientEntity,
            "Damage dealt by blessed players is multiplied by blessinglevel.");
        PluginReplyToCommand(
            sourceClientEntity,
            "Damage taken by blessed players is divided by curselevel.");
        return Plugin_Handled;
    }

    new Float:blessingLevel = DEFAULT_BLESSING_LEVEL;
    new String:targetSpecifier[MAX_TARGET_LENGTH];
    GetCmdArg(1, targetSpecifier, sizeof(targetSpecifier));
    if (argCount == 2)
    {
        new String:blessingLevelString[10];
        GetCmdArg(2, blessingLevelString, sizeof(blessingLevelString));
        blessingLevel = StringToFloat(blessingLevelString);
        if (blessingLevel <= 1.0)
        {
            PluginReplyToCommand(
                sourceClientEntity,
                "blessinglevel must be a real number greater than 1.");
            return Plugin_Handled;
        }
    }

    decl targets[MAXPLAYERS];
    new targetCount = GetConnectedPlayers(
        sourceClientEntity,
        targetSpecifier,
        targets);

    if (targetCount <= 0)
    {
        PluginReplyToCommand(
            sourceClientEntity,
            "Target (%s) not found.",
            targetSpecifier);

        return Plugin_Handled;
    }

    new blessedCount = 0;

    for (new targetIndex = 0; targetIndex < targetCount; targetIndex++)
    {
        new targetEntity = targets[targetIndex];
        if (PlayerBlessCurseLevels[targetEntity] == 1 / blessingLevel)
        {
            // This player already has the specified blessing level.
            if (targetCount == 1)
            {
                // This is the only target, report it individually.
                PluginReplyToCommand(
                    sourceClientEntity,
                    "%N was already blessed at level %1.2f.",
                    targetEntity,
                    blessingLevel);
            }
        }
        else
        {
            blessedCount++;
            PlayerBlessCurseLevels[targetEntity] = 1 / blessingLevel;
            PluginReplyToCommand(
                sourceClientEntity,
                "Blessed %N.",
                targetEntity);
        }
    }

    if (blessedCount == 0 && targetCount > 1)
    {
        PluginReplyToCommand(sourceClientEntity, "Did not bless anybody.");
    }

    return Plugin_Handled;
}

public Action:OnUnblessCmd(sourceClientEntity, argCount)
{
    if (argCount != 1)
    {
        PluginReplyToCommand(
            sourceClientEntity,
            "Usage: sm_unbless <targetname/#userid>");

        return Plugin_Handled;
    }

    new String:targetSpecifier[MAX_TARGET_LENGTH];
    GetCmdArg(1, targetSpecifier, sizeof(targetSpecifier));

    decl targets[MAXPLAYERS];
    new targetCount = GetConnectedPlayers(
        sourceClientEntity,
        targetSpecifier,
        targets);

    if (targetCount <= 0)
    {
        PluginReplyToCommand(
            sourceClientEntity,
            "Target (%s) not found.",
            targetSpecifier);

        return Plugin_Handled;
    }

    new uncursedCount = 0;
    for (new targetEntity = 0; targetEntity < targetCount; targetEntity++)
    {
        if (PlayerBlessCurseLevels[targets[targetEntity]] < 1.0)
        {
            uncursedCount++;
            PlayerBlessCurseLevels[targets[targetEntity]] = 1.0;
            PluginReplyToCommand(
                sourceClientEntity,
                "Unblessed %N.",
                targets[targetEntity]);
        }
        else
        {
            // This player is not cursed.
            if (targetCount == 1)
            {
                // This is the only target, report it individually.
                PluginReplyToCommand(
                    sourceClientEntity,
                    "%N was not blessed.",
                    targets[targetEntity]);
            }
        }
    }

    if (uncursedCount == 0 && targetCount > 1)
    {
        PluginReplyToCommand(sourceClientEntity, "Did not uncurse anybody.");
    }

    return Plugin_Handled;
}

public Action:OnCurseCmd(sourceClientEntity, argCount)
{
    if (argCount != 1 && argCount != 2)
    {
        PluginReplyToCommand(
            sourceClientEntity,
            "Usage: sm_curse <targetname/#userid> [curselevel=4.0]");
        PluginReplyToCommand(
            sourceClientEntity,
            "Damage inflicted by cursed players is divided by curselevel.");
        PluginReplyToCommand(
            sourceClientEntity,
            "Damage taken is multiplied by curselevel.");
        return Plugin_Handled;
    }

    new Float:curseLevel = DEFAULT_CURSE_LEVEL;
    new String:targetSpecifier[MAX_TARGET_LENGTH];
    GetCmdArg(1, targetSpecifier, sizeof(targetSpecifier));
    if (argCount == 2)
    {
        new String:curseLevelString[10];
        GetCmdArg(2, curseLevelString, sizeof(curseLevelString));
        curseLevel = StringToFloat(curseLevelString);
        if (curseLevel <= 1.0)
        {
            PluginReplyToCommand(
                sourceClientEntity,
                "curselevel must be a real number greater than 1.");
            return Plugin_Handled;
        }
    }

    decl targets[MAXPLAYERS];
    new targetCount = GetConnectedPlayers(
        sourceClientEntity,
        targetSpecifier,
        targets);

    if (targetCount <= 0)
    {
        PluginReplyToCommand(
            sourceClientEntity,
            "Target (%s) not found.",
            targetSpecifier);

        return Plugin_Handled;
    }

    new cursedCount = 0;

    for (new targetIndex = 0; targetIndex < targetCount; targetIndex++)
    {
        new targetEntity = targets[targetIndex];
        if (PlayerBlessCurseLevels[targetEntity] == curseLevel)
        {
            // This player already has the specified curse level.
            if (targetCount == 1)
            {
                // This is the only target, report it individually.
                PluginReplyToCommand(
                    sourceClientEntity,
                    "%N was already cursed at level %1.2f.",
                    targetEntity,
                    curseLevel);
            }
        }
        else
        {
            cursedCount++;
            PlayerBlessCurseLevels[targetEntity] = curseLevel;
            PluginReplyToCommand(
                sourceClientEntity,
                "Cursed %N.",
                targetEntity);
        }
    }

    if (cursedCount == 0 && targetCount > 1)
    {
        PluginReplyToCommand(sourceClientEntity, "Did not curse anybody.");
    }

    return Plugin_Handled;
}

public Action:OnUncurseCmd(sourceClientEntity, argCount)
{
    if (argCount != 1)
    {
        PluginReplyToCommand(
            sourceClientEntity,
            "Usage: sm_uncurse <targetname/#userid>");

        return Plugin_Handled;
    }

    new String:targetSpecifier[MAX_TARGET_LENGTH];
    GetCmdArg(1, targetSpecifier, sizeof(targetSpecifier));

    decl targets[MAXPLAYERS];
    new targetCount = GetConnectedPlayers(
        sourceClientEntity,
        targetSpecifier,
        targets);

    if (targetCount <= 0)
    {
        PluginReplyToCommand(
            sourceClientEntity,
            "Target (%s) not found.",
            targetSpecifier);

        return Plugin_Handled;
    }

    new uncursedCount = 0;
    for (new targetEntity = 0; targetEntity < targetCount; targetEntity++)
    {
        if (PlayerBlessCurseLevels[targets[targetEntity]] > 1)
        {
            uncursedCount++;
            PlayerBlessCurseLevels[targets[targetEntity]] = 1.0;
            PluginReplyToCommand(
                sourceClientEntity,
                "Uncursed %N.",
                targets[targetEntity]);
        }
        else
        {
            // This player is not cursed.
            if (targetCount == 1)
            {
                // This is the only target, report it individually.
                PluginReplyToCommand(
                    sourceClientEntity,
                    "%N was not cursed.",
                    targets[targetEntity]);
            }
        }
    }

    if (uncursedCount == 0 && targetCount > 1)
    {
        PluginReplyToCommand(sourceClientEntity, "Did not uncurse anybody.");
    }

    return Plugin_Handled;
}

public Action:OnTakeDamage(
    victimEntity,
    &attackerEntity,
    &inflictor,
    &Float:damage,
    &damagetype)
{
    new bool:damageChanged = false;

    if (!IsClientEntity(attackerEntity))
    {
        // The attacker isn't a player.
        return Plugin_Continue;
    }

    if (!IsClientEntity(victimEntity))
    {
        // The victim isn't a player.
        return Plugin_Continue;
    }

    if (victimEntity == attackerEntity)
    {
        // The damage is self-inflicted.
        return Plugin_Continue;
    }

    new Float:victimBlessCurseLevel = PlayerBlessCurseLevels[victimEntity];
    new Float:attackerBlessCurseLevel = PlayerBlessCurseLevels[attackerEntity];

    if (victimBlessCurseLevel == attackerBlessCurseLevel)
    {
        // The victim and attacker have the same curse level, so the
        // adjustments cancel each other out.
        return Plugin_Continue;
    }

    if (attackerBlessCurseLevel != 1.0)
    {
        damage /= attackerBlessCurseLevel;
        damageChanged = true;
    }

    if (victimBlessCurseLevel != 1.0)
    {
        // The victim is blessed or cursed.
        // Multiply the damage by the level.
        damage *= victimBlessCurseLevel;
        return Plugin_Changed;
    }

    return damageChanged ? Plugin_Changed : Plugin_Continue;
}
