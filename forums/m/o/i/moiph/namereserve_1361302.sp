/**
 * Name Reserve by Moiph
 * Allows names specified via config to be "reserved". If a user
 * joins with one of the reserved names, they will be renamed 
 * unless there's a steamid match for authorization for that name to be used.
 *
 * This program is free software; you can redistribute it and/or modify it under
 * the terms of the GNU General Public License, version 3.0, as published by the
 * Free Software Foundation.
 * 
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
 * details.
 *
 * You should have received a copy of the GNU General Public License along with
 * this program.  If not, see <http://www.gnu.org/licenses/>.
*/

#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

// Constants
#define PLUGIN_VERSION "1.2.2"
#define MAX_PLAYERS 256

// Configs
#define CONFIG_NAMES "configs/namereserve.cfg"

// Punishment types
enum PunishType
{
    Suffix = 0,
    Rename = 1,
    Kick = 2
}

// Key values
new Handle:g_kvNames = INVALID_HANDLE;

// Convars
new Handle:g_cvAdminsFlag = INVALID_HANDLE;
new Handle:g_cvBadName = INVALID_HANDLE;
new Handle:g_cvKickDelay = INVALID_HANDLE;
new Handle:g_cvKickMsg = INVALID_HANDLE;
new Handle:g_cvKickWarnAmount = INVALID_HANDLE;
new Handle:g_cvKickWarnMsg = INVALID_HANDLE;
new Handle:g_cvNameSuffix = INVALID_HANDLE;
new Handle:g_cvPunishType = INVALID_HANDLE;
new Handle:g_cvRenameMsg = INVALID_HANDLE;
new Handle:g_cvShowRenameMsg = INVALID_HANDLE;

// Various globals
new g_sdkVersion = SOURCE_SDK_UNKNOWN;
new int:g_warningsIssued[MAX_PLAYERS+1];
new Float:g_kickTimeRemaining[MAX_PLAYERS+1];
new String:g_reservedNames[MAX_PLAYERS+1][255];
new Float:g_kickTimerDelay = -1.0;

// Some timers
new Handle:g_informRenameTimers[MAX_PLAYERS+1];
new Handle:g_kickTimers[MAX_PLAYERS+1];

// Plugin Info
public Plugin:myinfo = 
{
    name = "Name Reserve",
    author = "Moiph",
    description = "Prevent non whitelisted users from using a reserved list of names.",
    version = PLUGIN_VERSION,
    url = "svarrenglossen.com"
};

/**
 * General setup
 */
public OnPluginStart()
{
    g_sdkVersion = GuessSDKVersion();

    g_kvNames = CreateKeyValues("Names");

    // convars
    CreateConVar("sm_namereserve_version", PLUGIN_VERSION, "NameReserve version", FCVAR_PLUGIN|FCVAR_REPLICATED|FCVAR_NOTIFY);

    g_cvAdminsFlag = CreateConVar("sm_namereserve_adminsflag", "b", "Admin flag for reserved name use immunity. Empty string means all admins are checked and must have steam ids listed in the config. (b is the generic flag)", FCVAR_PLUGIN);
    g_cvBadName = CreateConVar("sm_namereserve_badname", "I tried to use a bad name ;_;", "If PunishType is set to rename, this is the name the user will be changed to.", FCVAR_PLUGIN);
    g_cvKickDelay = CreateConVar("sm_namereserve_kickdelay", "60", "If PunishType is set to kick, this value is used as the delay before kicking the user.", FCVAR_PLUGIN);
    g_cvKickMsg = CreateConVar("sm_namereserve_kickmsg", "Using a reserved name", "Set this to the kick message a user will see (if PunishType is set to kick)", FCVAR_PLUGIN);
    g_cvKickWarnAmount = CreateConVar("sm_namereserve_kickwarnamount", "1", "If PunishType is set to kick, this value is used as the amount of times the user will be issued warnings that they're going to get kicked. (This will be evenly divided out of kickDelay, so if you set kickDelay to 10 and this to 5, the user will be warned every 2 seconds until kicked)", FCVAR_PLUGIN);
    g_cvKickWarnMsg = CreateConVar("sm_namereserve_kickwarnmsg", "If you don't change your name, you're gonna be kicked ({rn} is reserved)", "Message displayed to the user with each warning when a kick is pending. {rn} will be replaced by the reserved name.", FCVAR_PLUGIN);
    g_cvNameSuffix = CreateConVar("sm_namereserve_namesuffix", " (imposter)", "The text to append to a user's name if it's reserved", FCVAR_PLUGIN);
    g_cvPunishType = CreateConVar("sm_namereserve_punishtype", "0", "The punishment type to use when someone uses a reserved name. (0 = append suffix, 1= rename, 2 = kick)", FCVAR_PLUGIN);
    g_cvRenameMsg = CreateConVar("sm_namereserve_renamemsg", "You were renamed to avoid admin confusion <3 ({rn} is reserved)", "The message shown to the user to let them know they've been renamed. {rn} will be replaced with the reserved name.", FCVAR_PLUGIN);
    g_cvShowRenameMsg = CreateConVar("sm_namereserve_showrenamemsg", "1", "Whether or not to inform the user that they've been renamed", FCVAR_PLUGIN);

    // config setup
    AutoExecConfig(true, "namereserve");

    // monitor name changes
    HookEvent("player_changename", Event_PlayerChangename);
}

/**
 * Loads the reserved name list from config.
 */
public OnMapStart()
{
    decl String:file[128];

    BuildPath(Path_SM, file, sizeof(file), CONFIG_NAMES);
    FileToKeyValues(g_kvNames, file);
}

/**
 * When a user connects, check their name and if necessary,
 * rename them.
 */
public OnClientPostAdminCheck(client)
{
    decl String:name[255];
    decl String:newName[255];
    decl String:nameSuffix[64];

    // pull some data from the player
    GetClientName(client, name, sizeof(name));

    if (IsRenameNeeded(client))
    {
        LogAction(0, client, "No matching SteamID found for %s, taking action", name);

        // Determine punishment type
        if (PunishType:GetConVarInt(g_cvPunishType) == Kick)
        {
            g_warningsIssued[client] = int:0;
            g_kickTimeRemaining[client] = GetConVarFloat(g_cvKickDelay);
            g_kickTimers[client] = CreateTimer(GetKickTimerDelay(), KickUser, client);
        }
        else
        {
            if (PunishType:GetConVarInt(g_cvPunishType) == Rename)
            {
                GetConVarString(g_cvBadName, newName, sizeof(newName));
            }
            else
            {
                GetConVarString(g_cvNameSuffix, nameSuffix, sizeof(nameSuffix));
                Format(newName, sizeof(newName), "%s%s", name, nameSuffix);
            }

            // OrangeBox, L4D
            if (g_sdkVersion > SOURCE_SDK_EPISODE1)
            {
                SetClientInfo(client, "name", newName);
            }
            // CSS
            else
            {
                ClientCommand(client, "name %s", newName);
            }

            // Set a timer to inform the user in 15 seconds
            if (GetConVarBool(g_cvShowRenameMsg))
            {
                g_informRenameTimers[client] = CreateTimer(15.0, InformUserOfRename, client);
            }
        }
    }
}

/**
 * If a user disconnects before a rename timer has fired, kill
 * that timer since it's now invalid.
 */
public OnClientDisconnect(client)
{
    if (g_informRenameTimers[client] != INVALID_HANDLE)
    {
        KillTimer(g_informRenameTimers[client]);
        g_informRenameTimers[client] = INVALID_HANDLE;
    }
}

/**
 * When the informRenameTimer goes off for a user, send them
 * a message to let them know they've been renamed.
 *
 * @param handle	The timer that was fired.
 * @param client	Player's index.
 *
 * @noreturn
 */
public Action:InformUserOfRename(Handle:timer, any:client)
{
    decl String:renameMsg[255];
    GetConVarString(g_cvRenameMsg, renameMsg, sizeof(renameMsg));
    ReplaceString(renameMsg, sizeof(renameMsg), "{rn}", g_reservedNames[client]);

    PrintToChat(client, "\x04[NR]\x01 %s", renameMsg);
    g_informRenameTimers[client] = INVALID_HANDLE;
}

/**
 * The callback for the kickUser timer.  This will either
 * send a message to the user, warning them of an impending
 * kick, or if they've hit the warning limit they'll actually
 * be kicked.
 *
 * @param handle	The timer that was fired.
 * @param client	Player's index.
 */
public Action:KickUser(Handle:timer, any:client)
{
    if (g_warningsIssued[client] == int:GetConVarInt(g_cvKickWarnAmount))
    {
        decl String:kickMsg[255];
        GetConVarString(g_cvKickMsg, kickMsg, sizeof(kickMsg));

        KickClient(client, "%s", kickMsg);
    }
    else
    {
        new Float:delay = GetKickTimerDelay();
        decl String:kickWarnMsg[255];
        GetConVarString(g_cvKickWarnMsg, kickWarnMsg, sizeof(kickWarnMsg));

        ReplaceString(kickWarnMsg, sizeof(kickWarnMsg), "{rn}", g_reservedNames[client]);

        g_kickTimeRemaining[client] = g_kickTimeRemaining[client] - delay;
        g_warningsIssued[client]++;

        PrintToChat(client, "\x04[NR]\x01 %s (%2.0fs remaining)", kickWarnMsg, g_kickTimeRemaining[client]);

        g_kickTimers[client] = CreateTimer(delay, KickUser, client);
    }
}

/**
 * If a player changes their name to a non-reserved name, kill any existing timers
 * threatening to kick them.
 */
public Event_PlayerChangename(Handle:event, const String:name[], bool:dontBroadcast)
{
    decl String:oldName[255];
    decl String:newName[255];

    new client = GetClientOfUserId(GetEventInt(event, "userid"));
    GetEventString(event, "oldname", oldName, sizeof(oldName));
    GetEventString(event, "newname", newName, sizeof(newName));

    // Congratulations user, you've complied!
    if (!IsRenameNeeded(client))
    {
        if (g_kickTimers[client] != INVALID_HANDLE)
        {
            KillTimer(g_kickTimers[client]);
            g_kickTimers[client] = INVALID_HANDLE;
        }
    }
}

/**
 * Helper method to determine if a user needs to be renamed;
 * It checks for a reserved name and if they're allowed to use it.
 *
 * @param client	The player's index.
 * @return		True if a rename is needed, false otherwise.
 */
IsRenameNeeded(client)
{
    // First check if it's an immune admin... if so skip all this and return false.
    if (IsImmuneAdmin(client))
    {
        return false;
    }

    // Tsk tsk, not immune...
    
    decl String:name[255];
    decl String:reservedId[64];
    decl String:steamId[64];
    decl String:section[255];
    decl String:isPartial[8];
    new String:adminFlag[8] = "";

    GetClientAuthString(client, steamId, sizeof(steamId));
    GetClientName(client, name, sizeof(name));

    new bool:foundNameMatch = false;
    new bool:isRenameNeeded = false;

    KvGotoFirstSubKey(g_kvNames);

    do
    {
        KvGetSectionName(g_kvNames, section, sizeof(section));

        // Do a contains check so we can flag partial matches
        if (StrContains(name, section, false) != -1)
        {
            KvGetString(g_kvNames, "isPartial", isPartial, sizeof(isPartial));

            if (StrEqual(isPartial, "1") || StrEqual(name, section, false))
            {
                KvGetString(g_kvNames, "adminFlag", adminFlag, sizeof(adminFlag));
                foundNameMatch = true;
                break;
            }
        }
    } while (KvGotoNextKey(g_kvNames));

    KvRewind(g_kvNames);
    KvJumpToKey(g_kvNames, section);

    // if we found a match and they're not immune on this name (already checked global flag,
    // need to check name specific flag
    if (foundNameMatch && !IsImmuneAdmin(client, adminFlag))
    {
        LogAction(0, client, "Reserved name (%s) found, checking authorization for user %s", name, steamId);

        isRenameNeeded = true;
        g_reservedNames[client] = section;

        KvGotoFirstSubKey(g_kvNames);

        do
        {
            // See if the user is in the whitelist for this name
            KvGetString(g_kvNames, "id", reservedId, sizeof(reservedId));
            if (StrEqual(steamId, reservedId))
            {
                isRenameNeeded = false;
                break;
            }
        } while (KvGotoNextKey(g_kvNames));
    }

    return isRenameNeeded;
}

/**
 * Checks to see if the player is an immune admin.
 *
 * @param client	The player's index.
 * @param cfgFlag	The admin flag to check.  If empty, checks the global cvar.
 * @return		True if the player is admin immune from name restrictions, false otherwise.
 */
IsImmuneAdmin(client, const String:cfgFlag[] = "")
{
    decl String:adminsFlag[8];
    decl AdminFlag:flag;

    new AdminId:admin = GetUserAdmin(client);

    if (StrEqual(cfgFlag, ""))
    {
        GetConVarString(g_cvAdminsFlag, adminsFlag, sizeof(adminsFlag));
    }
    else
    {
        strcopy(adminsFlag, sizeof(adminsFlag), cfgFlag);
    }
    FindFlagByChar(adminsFlag[0], flag);

    // non empty string? valid id? valid flag? Pass all those and they're immune!
    if (!StrEqual(adminsFlag, "") && admin != INVALID_ADMIN_ID && GetAdminFlag(admin, flag))
    {
        return true;
    }

    return false;
}

/**
 * Gets the kick timer delay.
 * 
 * @return	The kick timer delay.
 */
Float:GetKickTimerDelay()
{
    if (g_kickTimerDelay == -1.0)
    {
        g_kickTimerDelay = GetConVarFloat(g_cvKickDelay);
        new kickWarnAmount = GetConVarInt(g_cvKickWarnAmount);
        if (g_kickTimerDelay > 0.0 && kickWarnAmount > 0)
        {
            // add 1 to the warnamount to get our delay --
            // e.g. they specifcy a warn amount of "1", and our configured delay is 60.
            // 60 / (1 + 1) = 30
            g_kickTimerDelay = g_kickTimerDelay / (kickWarnAmount + 1);
        }
    }

    return g_kickTimerDelay;
}