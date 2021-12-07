/**
 * vim: set ai et ts=4 sw=4 syntax=sourcepawn :
 * =============================================================================
 * MySQL Based Ban Plugin
 * Ban & unban players globally from a single command on multiple servers
 * =============================================================================
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
 *
 * As a special exception, AlliedModders LLC gives you permission to link the
 * code of this program (as well as its derivative works) to "Half-Life 2," the
 * "Source Engine," the "SourcePawn JIT," and any Game MODs that run on software
 * by the Valve Corporation.  You must obey the GNU General Public License in
 * all respects for all other code used.  Additionally, AlliedModders LLC grants
 * this exception to all derivative works.  AlliedModders LLC defines further
 * exceptions, found in LICENSE.txt (as of this writing, version JULY-31-2007),
 * or <http://www.sourcemod.net/license.php>.
 *
 **/
//////////////////////////////////////////////////////////////////
// MySQL SQL Table Creation
//////////////////////////////////////////////////////////////////

// Table layout
/*

DROP TABLE IF EXISTS `mysql_bans`;
CREATE TABLE IF NOT EXISTS `mysql_bans` (
  `id` int(11) auto_increment,
  `steam_id` varchar(32),
  `player_name` varchar(65),
  `ipaddr` varchar(24),
  `ban_length` int(1) default '0',
  `ban_reason` varchar(100),
  `banned_by` varchar(65),
  `banned_by_id` varchar(32),
  `timestamp` timestamp default CURRENT_TIMESTAMP on update CURRENT_TIMESTAMP,
  PRIMARY KEY  (`id`),
  UNIQUE KEY `steam_id` (`steam_id`)
  UNIQUE KEY `ipaddr` (`ipaddr`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1 AUTO_INCREMENT=3 ;

*/
//////////////////////////////////////////////////////////////////
// Includes
//////////////////////////////////////////////////////////////////
#include <sourcemod>
#include <sdktools>
#undef REQUIRE_PLUGIN
#define PLUGIN_VERSION "4.8"

//////////////////////////////////////////////////////////////////
// Plugin Info
//////////////////////////////////////////////////////////////////
public Plugin:myinfo = 
{
    name = "MySQL Bans",
    author = "Team MX | MoggieX, refactored by -=|JFH|=-Naris",
    description = "Ban using a MySQL DB over multiple servers",
    version = PLUGIN_VERSION,
    url = "http://www.Afterbuy.co.uk"
};

//////////////////////////////////////////////////////////////////
// Handles
//////////////////////////////////////////////////////////////////
new Handle:ErrorChecking = INVALID_HANDLE;
new Handle:AdminChecking = INVALID_HANDLE;
new Handle:StoreAllBans  = INVALID_HANDLE;
new Handle:UnbanLocally  = INVALID_HANDLE;
new Handle:BanLocally    = INVALID_HANDLE;
new Handle:db            = INVALID_HANDLE;

//////////////////////////////////////////////////////////////////
// Client Status
//////////////////////////////////////////////////////////////////
enum status { undefined=0, notbanned, unbanned, banned };
new status:ClientStatus[MAXPLAYERS+1] = { undefined, ... };

//////////////////////////////////////////////////////////////////
// Set vars on plugin start
//////////////////////////////////////////////////////////////////
public OnPluginStart()
{
    // Load phrases
    LoadTranslations("common.phrases");
    LoadTranslations("basebans.phrases");
    LoadTranslations("mysqlbans.phrases");

    // Reg commands
    RegAdminCmd("mysql_ban",Command_Ban,ADMFLAG_BAN,"Bans player by STEAMID");
    RegAdminCmd("mysql_addban",Command_AddBan,ADMFLAG_BAN,"Bans player by STEAMID");
    RegAdminCmd("mysql_unban",Command_UnBan,ADMFLAG_BAN,"Unbans player by STEAMID");
    RegAdminCmd("mysql_ipban",Command_BanIp,ADMFLAG_BAN,"Unbans player by IP");
    RegAdminCmd("mysql_banip",Command_BanIp,ADMFLAG_BAN,"Unbans player by IP");

    // Create convars
    CreateConVar("mysql_bans_version", PLUGIN_VERSION, "MySQL Bans Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
    AdminChecking = CreateConVar("mysql_bans_admin_check","1","Check Admins if banned? 1=Skip ban checks for admins, 0=Check admins for bans", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
    ErrorChecking = CreateConVar("mysql_bans_error_check","1","Shows Error Messages, 0=don't show, 1=show in logs, 2=show in-game chat", FCVAR_PLUGIN|FCVAR_SPONLY);
    StoreAllBans = CreateConVar("mysql_bans_store_all_bans","1","Store ALL bans in DB, 0=only store mysql bans, 1=store ALL bans", FCVAR_PLUGIN|FCVAR_SPONLY);
    BanLocally = CreateConVar("mysql_bans_local_ban","1","Also Ban players locally (using banned_user/ip.cfg), 1=also ban locally, 0=only store bans in DB", FCVAR_PLUGIN|FCVAR_SPONLY);
    UnbanLocally = CreateConVar("mysql_bans_local_unban","1","Also Unban players locally (using banned_user/ip.cfg), 1=unban players when they connect and aren't in the ban DB, 0=don't check for unbans when connecting", FCVAR_PLUGIN|FCVAR_SPONLY);

    if (ConnectToDatabase())
        VerifyTable();
}

public OnMapStart()
{
    // Connect to the database, if required
 	if (db == INVALID_HANDLE)
        ConnectToDatabase();
}

public OnMapEnd()
{
    // Close the Database Handle/Connection
    if (db != INVALID_HANDLE)
    {
        CloseHandle(db);
        db = INVALID_HANDLE;
    }
}

//////////////////////////////////////////////////////////////////
// Connect to the database
//////////////////////////////////////////////////////////////////
bool:ConnectToDatabase(client=0)
{
    decl String:error[256];
    if (SQL_CheckConfig("mysqlbans"))
        db = SQL_Connect("mysqlbans", true, error, sizeof(error));
    else
        db = SQL_Connect("default", true, error, sizeof(error));

    if (db == INVALID_HANDLE)
    {
        /* Error Checking */
        new check = GetConVarInt(ErrorChecking);
        if (check >= 1)
        {
            LogAction(client, -1, "[MySQL Bans] Could Not Connect to Database, error: %s", error);
            PrintToServer("\x04[MySQL Bans]\x03 Could Not Connect to Database, error: %s", error);

            if (check >= 2)
                PrintToChatAll("\x04[MySQL Bans]\x03 Could Not Connect to Database, error: %s", error);
        }
    }
    return (db != INVALID_HANDLE);
}

//////////////////////////////////////////////////////////////////
// Reset client status on connection
//////////////////////////////////////////////////////////////////
public bool:OnClientConnect(client, String:rejectmsg[], maxlen) 
{
    ClientStatus[client] = undefined;
    return true;
}

//////////////////////////////////////////////////////////////////
// Reset client status on disconnection
//////////////////////////////////////////////////////////////////
public OnClientDisconnect(client)
{
    ClientStatus[client] = undefined;
}

//////////////////////////////////////////////////////////////////
// Player checking on authorization
//////////////////////////////////////////////////////////////////
public OnClientAuthorized(client, const String:auth[])
{
    // Check if a BOT if = then bailout
    if (IsFakeClient(client))
        return;

    if (GetConVarBool(UnbanLocally))
    {
        // Get Client Name & IP
        decl String:player_name[65];
        GetClientName(client, player_name, sizeof(player_name));

        decl String:ipaddr[24];
        GetClientIP(client, ipaddr, sizeof(ipaddr));

        CheckBan(client, auth, ipaddr, player_name);
    }
}

//////////////////////////////////////////////////////////////////
// Player checking on connection (post admin check)
//////////////////////////////////////////////////////////////////
public OnClientPostAdminCheck(client)
{
    // Check if a BOT if = then bailout
    if (IsFakeClient(client))
        return;

    new check = GetConVarInt(ErrorChecking);

    // Check if a ADMIN if = then bailout - again another way of speeding this up as admins will not be banned
    if (GetConVarInt(AdminChecking) == 1)
    {
        /* Error Checking */	
        if (check >= 1)
        {
            LogAction(client, -1, "[MySQL Bans] Player was admin checked");
            PrintToServer("\x04[MySQL Bans]\x03 Player was admin checked");

            if (check >= 2)
                PrintToChatAll("\x04[MySQL Bans]\x03 Player was admin checked");
        }

        /* do stuff */
        new AdminId:AdminID = GetUserAdmin(client);
        if (AdminID != INVALID_ADMIN_ID)
            return;
    }

    // Check if on LAN and get Steam ID
    decl String:steam_id[32];
    if (GetClientAuthString(client, steam_id, sizeof(steam_id)))
    {
        if (StrEqual(steam_id, "STEAM_ID_LAN"))
        {
            steam_id[0] = '\0';

            /* Error Checking */
            if (check >= 1)
            {
                LogAction(client, -1, "[MySQL Bans] User Steam ID empty. You are on a LAN");
                PrintToServer("\x04[MySQL Bans]\x03 User Steam ID empty. You are on a LAN");

                if (check >= 2)
                    PrintToChatAll("\x04[MySQL Bans]\x03 User Steam ID empty. You are on a LAN");
            }
        }
    }
    else
        steam_id[0] = '\0';

    if (GetConVarBool(UnbanLocally))
    {
        if (ClientStatus[client] == banned)
            KickBannedClient(client, 0, 0.0, "", steam_id)

        return;
    }

    // OK, now thats over lets get thier data for processing!

    /* Error Checking */
    if (check >= 1)
    {
        LogAction(client, -1, "[MySQL Bans] Player is NOT a BOT or an ADMIN");
        PrintToServer("\x04[MySQL Bans]\x03 Player is NOT a BOT or an ADMIN");

        if (check >= 2)
            PrintToChatAll("\x04[MySQL Bans]\x03 Player is NOT a BOT or an ADMIN");
    }

    // Delcare & log some stuff

    decl String:player_name[65];	// Player name
    decl String:ipaddr[24];		    // IP Address

    // Get Client Auth & IP
    GetClientName(client, player_name, sizeof(player_name));
    GetClientIP(client, ipaddr, sizeof(ipaddr));

    // print data to server

    /* Error Checking */
    if (check >= 1)
    {
        LogAction(client, -1, "[MySQL Bans] Player In Server <%s>,<%s>,<%s>", player_name, ipaddr, steam_id);
        PrintToServer("\x04[MySQL Bans]\x03 Player In Server <%s>,<%s>,<%s>", player_name, ipaddr, steam_id);

        if (check >= 2)
            PrintToChatAll("\x04[MySQL Bans]\x03 Player In Server <%s>,<%s>,<%s>", player_name, ipaddr, steam_id);
    }
    CheckBan(client, steam_id, ipaddr, player_name);
}

CheckBan(client, const String:steam_id[], const String:ipaddr[], const String:player_name[])
{
    // Form the SQL and add the parameters to it.
    // Think this can be improved by only search for steam ID only, then searching again if a match found

    decl String:query[255];
    Format(query, sizeof(query),

    // OLD query
    //"SELECT steam_id, ban_length, ban_reason FROM mysql_bans WHERE steam_id = '%s'", steam_id);

	// New query - this one gets the IP and also now checks Steam ID AND IP
	"SELECT ban_reason, ban_length, TIME_TO_SEC(TIMEDIFF(ADDTIME(timestamp,SEC_TO_TIME(ban_length*60)),CURRENT_TIMESTAMP))/60 FROM mysql_bans WHERE steam_id = '%s' OR ipaddr = '%s'", steam_id, ipaddr);

    /* Error Checking */
    new check = GetConVarInt(ErrorChecking);
    if (check >= 1)
    {
        LogAction(client, -1, "[MySQL Bans] Query String: <%s>", query);
        PrintToServer("\x04[MySQL Bans]\x03 Query String: <%s>", query);

        if (check >= 2)
            PrintToChatAll("\x04[MySQL Bans]\x03 Query String: <%s>", query);
    }

    // Execute the query in a Thread and check the results in the SQL_CheckPlayer() callback.
    new Handle:data = CreateDataPack();
    WritePackCell(data, client);
    WritePackString(data, player_name);
    WritePackString(data, ipaddr);
    WritePackString(data, steam_id);
    WritePackString(data, query);
    SQL_TQuery(db, SQL_CheckBan, query, data);
}

public SQL_CheckBan(Handle:owner, Handle:hndl, const String:error[], any:data)
{
    ResetPack(data);
    new client = ReadPackCell(data);

    decl String:player_name[65];	// Player name
    ReadPackString(data, player_name, sizeof(player_name));

    decl String:ipaddr[24];		    // IP Address
    ReadPackString(data, ipaddr, sizeof(ipaddr));

    decl String:steam_id[32];	    // Steam ID
    ReadPackString(data, steam_id, sizeof(steam_id));

    CloseHandle(data);

    new check = GetConVarInt(ErrorChecking);

	// bail out if there is an issue
    if (hndl == INVALID_HANDLE || error[0] != '\0')
    {
        /* Error Checking */
        if (check >= 1)
        {
            LogAction(client, -1, "[MySQL Bans] Lookup failed for <%s>,<%s>,<%s>", player_name, ipaddr, steam_id);
            PrintToServer("\x04[MySQL Bans]\x03 Lookup failed for <%s>,<%s>,<%s>", player_name, ipaddr, steam_id);

            if (check >= 2)
                PrintToChatAll("\x04[MySQL Bans]\x03 Lookup failed for <%s>,<%s>,<%s>", player_name, ipaddr, steam_id);
        }
        return;
    }

    // the lucky lad wasn't banned
    if (!SQL_FetchRow(hndl))
    {
        ClientStatus[client] = notbanned;
        if (GetConVarBool(UnbanLocally))
        {
            // Remove any local bans
            if (strncmp(steam_id, "STEAM_", 6) != 0 && steam_id[7] == ':')
                RemoveBan(steam_id, BANFLAG_AUTHID, "mysql_unban", client);
            else
                RemoveBan(ipaddr, BANFLAG_IP, "mysql_unban", client);
        }

        /* Error Checking */
        if (check >= 1)
        {
            LogAction(client, -1, "[MySQL Bans] <%s>,<%s>,<%s> NOT found in bans database. Play nice now!>", player_name, ipaddr, steam_id);
            PrintToServer("\x04[MySQL Bans]\x03 <%s>,<%s>,<%s> NOT found in bans database. Play nice now!>", player_name, ipaddr, steam_id);

            if (check >= 2)
                PrintToChatAll("\x04[MySQL Bans]\x03 <%s>,<%s>,<%s> NOT found in bans database. Play nice now!>", player_name, ipaddr, steam_id);
        }
    }

    // Must have been a match, so lets deal with the bann'ee
    else
    {
        do // In case there is more than 1 row (perhaps 1 by steam_id & 1 by ip)
        {
            new ban_length = SQL_FetchInt(hndl,1); // Checking thier ban length
            new Float:ban_remaining = (ban_length > 0) ? SQL_FetchFloat(hndl,2) : 0.0; // Amount of time left in ban
            if (ban_length <= 0 || ban_remaining > 0.0)
            {
                decl String:ban_reason[100];	// Reason for ban
                SQL_FetchString(hndl,0,ban_reason,sizeof(ban_reason));

                ClientStatus[client] = banned;
                LogAction(client, -1, "[MySQL Bans] Player <%s>,<%s>,<%s> is BANNED for %s", player_name, ipaddr, steam_id, ban_reason);

                /* Error Checking */
                if (check >= 1)
                {
                    PrintCenterTextAll("[MySQL Bans] Player <%s>,<%s>,<%s> is BANNED for %s", player_name, ipaddr, steam_id, ban_reason);
                    PrintToServer("[MySQL Bans] Player <%s>,<%s>,<%s> is BANNED for %s", player_name, ipaddr, steam_id, ban_reason);

                    if (check >= 2)
                        PrintToChatAll("[MySQL Bans] Player <%s>,<%s>,<%s> is BANNED for %s", player_name, ipaddr, steam_id, ban_reason);
                }

                if (IsClientInGame(client))
                    KickBannedClient(client, ban_length, ban_remaining, ban_reason, steam_id);

                break;
            }
            else
            {
                ClientStatus[client] = unbanned;
                if (GetConVarBool(UnbanLocally))
                {
                    // Remove any local bans
                    if (strncmp(steam_id, "STEAM_", 6) != 0 && steam_id[7] == ':')
                        RemoveBan(steam_id, BANFLAG_AUTHID, "mysql_unban", client);
                    else
                        RemoveBan(ipaddr, BANFLAG_IP, "mysql_unban", client);
                }

                /* Error Checking */
                if (check >= 1)
                {
                    LogAction(client, -1, "[MySQL Bans] <%s>,<%s>,<%s> ban expired. Play nice now!>", player_name, ipaddr, steam_id);
                    PrintToServer("\x04[MySQL Bans]\x03 <%s>,<%s>,<%s> ban expired. Play nice now!>", player_name, ipaddr, steam_id);

                    if (check >= 2)
                        PrintToChatAll("\x04[MySQL Bans]\x03 <%s>,<%s>,<%s> ban expired. Play nice now!>", player_name, ipaddr, steam_id);
                }
            }
        } while (SQL_FetchRow(hndl));
    }
}

KickBannedClient(client, ban_length, Float:ban_remaining, const String:ban_reason[], const String:authid[])
{
    decl String:message[100];

    if (IsClientInGame(client))
    {
        LogAction(client, -1, "[MySQL Bans] Player <%N>,<%s> has been removed", client, authid);

        /* Error Checking */
        new check = GetConVarInt(ErrorChecking);
        if (check >= 1)
        {
            PrintCenterTextAll("[MySQL Bans] Player <%N>,<%s> has been removed", client, authid);
            PrintToServer("[MySQL Bans] Player <%N>,<%s> has been removed", client, authid);

            if (check >= 2)
                PrintToChatAll("[MySQL Bans] Player <%N>,<%s> has been removed", client, authid);
        }

        // kick em with a reason and length of time
        if (ban_reason[0] == '\0')
            strcopy(message, sizeof(message),"You have been Banned");
        else if (ban_length <= 0)
            Format(message, sizeof(message),"You have been Banned for %s", ban_reason);
        else
        {
            if (ban_remaining < 60.0)
                Format(message, sizeof(message),"You have been Banned for %s\nyou have %2.1f minutes left", ban_reason, ban_remaining);
            else
            {
                ban_remaining /= 60.0; // convert to hours
                if (ban_remaining < 24.0)
                    Format(message, sizeof(message),"You have been Banned for %s\nyou have %2.1f hours left", ban_reason, ban_remaining);
                else
                {
                    ban_remaining /= 24.0;
                    if (ban_remaining < 7.0)
                        Format(message, sizeof(message),"You have been Banned for %s\nyou have %2.1f days left", ban_reason, ban_remaining);
                    else
                    {
                        ban_remaining /= 7.0;
                        if (ban_remaining < 4.0)
                            Format(message, sizeof(message),"You have been Banned for %s\nyou have %2.1f weeks left", ban_reason, ban_remaining);
                        else
                        {
                            ban_remaining /= 4.0;
                            Format(message, sizeof(message),"You have been Banned for %s\nyou have %2.1f months left", ban_reason, ban_remaining);
                        }
                    }
                }
            }
        }

        if (GetConVarBool(BanLocally))
            BanClient(client, ban_length, BANFLAG_AUTO, ban_reason, message, "mysql_kick", 0);
        else
            KickClient(client, message);
    }
    else
    {
        LogAction(0, -1, "[MySQL Bans] Player <%d>,<%s> has been removed", client, authid);

        /* Error Checking */
        new check = GetConVarInt(ErrorChecking);
        if (check >= 1)
        {
            PrintCenterTextAll("[MySQL Bans] Player <%d>,<%s> has been removed", client, authid);
            PrintToServer("[MySQL Bans] Player <%d>,<%s> has been removed", client, authid);

            if (check >= 2)
                PrintToChatAll("[MySQL Bans] Player <%d>,<%s> has been removed", client, authid);
        }

        if (GetConVarBool(BanLocally))
            BanIdentity(authid, ban_length, BANFLAG_AUTO, ban_reason, "mysql_kick", 0);
    }
}

//////////////////////////////////////////////////////////////////
// ADD Ban Command - mysql_addban
//////////////////////////////////////////////////////////////////
public Action:Command_AddBan(client, args)
{
    if (args < 2)
    {
        ReplyToCommand(client, "[MySQL Bans] Usage: mysql_addban <time> <steamid> [reason]");
        return Plugin_Handled;
    }

    decl String:arg_string[256];
    new String:reason[128];
    new String:time[50];
    new String:authid[50];

    GetCmdArgString(arg_string, sizeof(arg_string));

    new len, total_len;

    /* Get time */
    if ((len = BreakString(arg_string, time, sizeof(time))) == -1)
    {
        /* Missing time */
        ReplyToCommand(client, "[MySQL Bans] %t", "Invalid Time");
        return Plugin_Handled;
    }	
    total_len += len;

    /* Get steamid */
    if ((len = BreakString(arg_string[total_len], authid, sizeof(authid))) != -1)
    {
        /* Get reason */
        total_len += len;
        BreakString(arg_string[total_len], reason, sizeof(reason));
    }

    /* Verify steamid */
    if (strncmp(authid, "STEAM_", 6) != 0 && authid[7] == ':')
    {
        ReplyToCommand(client, "[SM] %t", "Invalid SteamID");
        return Plugin_Handled;
    }

    new minutes = StringToInt(time);

    // My log message
    LogAction(client, -1, "[MySQL Bans] \"%L\" added ban (minutes \"%d\") (id \"%s\") (reason \"%s\")", client, minutes, authid, reason);

    new check = GetConVarInt(ErrorChecking);
    if (check > 0)
    {
        // Print commands
        PrintCenterTextAll("[MySQL Bans] [STARTING TO] \"%L\" added ban (minutes \"%d\") (id \"%s\") (reason \"%s\")", client, minutes, authid, reason);
        PrintToServer("[MySQL Bans] [STARTING TO] \"%L\" added ban (minutes \"%d\") (id \"%s\") (reason \"%s\")", client, minutes, authid, reason);
        //PrintToChatAll("[MySQL Bans] [STARTING TO] \"%L\" added ban (minutes \"%d\") (id \"%s\") (reason \"%s\")", client, minutes, authid, reason);
    }

    // now post the entry to the database
    InsertBan(-1, minutes, BANFLAG_AUTO, reason, client, authid);

    LogAction(client, -1, "[MySQL Bans] Auth %s, Ban time %s, Reason %s, Client %s put into database", authid, minutes, reason, client);

    /* Error Checking */
    if (check >= 1)
    {
        PrintCenterTextAll("[MySQL Bans] [Putting into DB] Auth %s, Ban time %s, Reason %s, Client %s", authid, minutes, reason, client);
        PrintToServer("[MySQL Bans] [Putting into DB] Auth %s, Ban time %s, Reason %s, Client %s", authid, minutes, reason, client);
    }

    ReplyToCommand(client, "[MySQL Bans]: %t", "Ban Added");
    return Plugin_Handled;
}

//////////////////////////////////////////////////////////////////
// UN Banning a Player - mysql_unban - Now unbans matching IP's
//////////////////////////////////////////////////////////////////
public Action:Command_UnBan(client, args)
{
    // Bse of this borrowed from the core SM ban .sp files
	if (args < 1)
	{
		ReplyToCommand(client, "[MySQL] Usage: mysql_unban <steamid>");
		return Plugin_Handled;
	}

	decl String:arg[50];
	GetCmdArgString(arg, sizeof(arg));

	ReplaceString(arg, sizeof(arg), "\"", "");	

	new ban_flags;
	if (strncmp(arg, "STEAM_", 6) != 0 && arg[7] == ':')
	{
		ban_flags |= BANFLAG_AUTHID;
	}

    // Ignoring IP bans for now as I'm not that bright =)
	else
	{
		ban_flags |= BANFLAG_IP;
	}

// <<<<<<<<<<<< START UN BAN

	// now I'm happy its been error trapped and we have a match! Some lucky n00blets is goign to be unbanned
	if (GetConVarBool(BanLocally) || GetConVarBool(UnbanLocally))
	{
		RemoveBan(arg, ban_flags, "mysql_unban", client);
	}

	DeleteBan(arg, client);

	ReplyToCommand(client, "[MySQL Bans] %t", "Removed Matching Bans", arg);
	return Plugin_Handled;
}

//////////////////////////////////////////////////////////////////
// Banning a Player - mysql_ban
//////////////////////////////////////////////////////////////////
public Action:Command_Ban(client, args)
{
    if (args < 2)
    {
        ReplyToCommand(client, "[MySQL Bans] Usage: mysql_ban <#userid|name> <minutes|0> [reason]");
        return Plugin_Handled;
    }

    // hell lets use whats already been written in the base [SM] files

    decl len, next_len;
    decl String:Arguments[256];
    GetCmdArgString(Arguments, sizeof(Arguments));

    decl String:arg[65];	
    len = BreakString(Arguments, arg, sizeof(arg));

    new target = FindTarget(client, arg, true);
    if (target == -1)
    {
        return Plugin_Handled;
    }

    decl String:s_time[12];
    if ((next_len = BreakString(Arguments[len], s_time, sizeof(s_time))) != -1)
    {
        len += next_len;
    }
    else
    {
        len = 0;
        Arguments[0] = '\0';
    }

    new time = StringToInt(s_time);

    // OK now I have used the sm_ban code to tidy the data up, lets pass to the PrepareBan function to do the core function
    PrepareBan(client, target, time, Arguments[len]);

    return Plugin_Handled;
}

//////////////////////////////////////////////////////////////////
// Banning a Player by IP - mysql_banip
//////////////////////////////////////////////////////////////////
public Action:Command_BanIp(client, args)
{
    if (args < 2)
    {
        ReplyToCommand(client, "[MySQL Bans] Usage: mysql_banip <ip|#userid|name> <time> [reason]");
        return Plugin_Handled;
    }

    decl len, next_len;
    decl String:Arguments[256];
    decl String:arg[50], String:time[20];

    GetCmdArgString(Arguments, sizeof(Arguments));
    len = BreakString(Arguments, arg, sizeof(arg));

    if ((next_len = BreakString(Arguments[len], time, sizeof(time))) != -1)
    {
        len += next_len;
    }
    else
    {
        len = 0;
        Arguments[0] = '\0';
    }

    if (StrEqual(arg, "0"))
    {
        ReplyToCommand(client, "[SM] %t", "Cannot ban that IP");
        return Plugin_Handled;
    }

    decl String:target_name[MAX_TARGET_LENGTH];
    decl target_list[1], bool:tn_is_ml;
    new found_client = -1;

    if (ProcessTargetString(
                arg,
                client, 
                target_list, 
                1, 
                COMMAND_FILTER_CONNECTED|COMMAND_FILTER_NO_MULTI,
                target_name,
                sizeof(target_name),
                tn_is_ml) > 0)
    {
        found_client = target_list[0];
    }

    new bool:has_rcon;

    if (client == 0 || (client == 1 && !IsDedicatedServer()))
    {
        has_rcon = true;
    }
    else
    {
        new AdminId:id = GetUserAdmin(client);
        has_rcon = (id == INVALID_ADMIN_ID) ? false : GetAdminFlag(id, Admin_RCON);
    }

    new hit_client = -1;
    if (found_client != -1
        && !IsFakeClient(found_client)
        && (has_rcon || CanUserTarget(client, found_client)))
    {
        GetClientIP(found_client, arg, sizeof(arg));
        hit_client = found_client;
    }

    if (hit_client == -1 && !has_rcon)
    {
        ReplyToCommand(client, "[SM] %t", "No Access");
        return Plugin_Handled;
    }

    new minutes = StringToInt(time);

    // data ready now for a ban client, minutes, arg, Arguments[len]

    InsertBan(hit_client, minutes, BANFLAG_IP, Arguments[len], client, arg);

    if (GetConVarInt(ErrorChecking) >= 1)
    {
        PrintCenterTextAll("[MySQL Bans] <%N> was banned by IP <%s> for <%d> minutes due to %s, by <%N>",
                           hit_client, arg, minutes, Arguments[len], client);

        PrintToServer("[MySQL Bans] <%N> was banned by IP <%s> for <%d> minutes due to %s, by <%N>",
                      hit_client, arg, minutes, Arguments[len], client);
    }

    if (GetConVarBool(BanLocally))
    {
        BanIdentity(arg, minutes, BANFLAG_IP, Arguments[len], "mysql_banip", client);
    }

    if (hit_client != -1)
    {
        KickClient(hit_client, "Banned: %s", Arguments[len]);
    }

    ReplyToCommand(client, "[MySQL Bans] %t", "Ban added");

    return Plugin_Handled;
}

//////////////////////////////////////////////////////////////////
// Helper Functions
//////////////////////////////////////////////////////////////////
PrepareBan(client, target, time, const String:reason[])
{
    // declare the details
    decl String:authid[64]; 
    decl String:name[32];
    GetClientAuthString(target, authid, sizeof(authid));
    GetClientName(target, name, sizeof(name));

    InsertBan(target, time, BANFLAG_AUTO, reason, client, "");

    PrintToChatAll("\x04[MySQL Bans]\x01 %N  banned: %N for %s", client, target, reason);

    if (client > 0 && IsClientInGame(client))
        ReplyToCommand(client, "[MySQL Bans]: %t", "Ban added");

    if (GetConVarBool(BanLocally))
    {
        // Now that they are banned in the database, lets also, for safe keeping,
        // put the user into the banned_user.cfg file for good measure!
        BanClient( target, time, BANFLAG_AUTO, reason, reason, "mysql_ban", client);
    }
    else
        KickClient(target, "Banned: %s", reason);
}

public Action:OnBanClient(client, time, flags, const String:reason[], const String:kick_message[], const String:command[], any:source)
{
	if (GetConVarInt(StoreAllBans) == 1)
	{
		if (strncmp(command, "mysql_", 6) != 0)
			InsertBan(client, time, flags, reason, source, "");
	}
	return Plugin_Continue;
}

public Action:OnBanIdentity(const String:identity[], time, flags, const String:reason[], const String:command[], any:source)
{
	if (GetConVarInt(StoreAllBans) == 1)
	{
		if (strncmp(command, "mysql_", 6) != 0)
			InsertBan(0, time, flags, reason, source, identity);
	}
	return Plugin_Continue;
}

public Action:OnRemoveBan(const String:identity[], flags, const String:command[], any:source)
{
	if (GetConVarInt(StoreAllBans) == 1)
	{
		if (strncmp(command, "mysql_", 6) != 0)
			DeleteBan(identity, source);
	}
	return Plugin_Continue;
}

bool:VerifyTable()
{
    // Error capturing
    if (db == INVALID_HANDLE)
    {
        if (!ConnectToDatabase())
            return false;
    }

    SQL_LockDatabase(db);

    decl String:query[512];
    Format(query,sizeof(query), "%s%s%s%s%s%s%s%s%s%s%s%s%s%s",
            "CREATE TABLE IF NOT EXISTS `mysql_bans` (",
            "  `id` int(11) auto_increment,",
            "  `steam_id` varchar(32),",
            "  `player_name` varchar(65),",
            "  `ipaddr` varchar(24),",
            "  `ban_length` int(1) default '0',",
            "  `ban_reason` varchar(100),",
            "  `banned_by` varchar(65),",
            "  `banned_by_id` varchar(32),",
            "  `timestamp` timestamp default CURRENT_TIMESTAMP on update CURRENT_TIMESTAMP,",
            "  PRIMARY KEY  (`id`),",
            "  UNIQUE KEY `steam_id` (`steam_id`),",
            "  UNIQUE KEY `ipaddr` (`ipaddr`)",
            ")");

    new bool:success = SQL_FastQuery(db, query);
    if(!success)
    {
        decl String:error[256];
        SQL_GetError(db, error, sizeof(error));
        LogError("Unable to verify mysql_bans table:%s", error);
    }

    SQL_UnlockDatabase(db);
    return success;
}

InsertBan(client, time, flags, const String:reason[], any:source, const String:identity[])
{
    // Error capturing
    if (db == INVALID_HANDLE)
    {
        if (!ConnectToDatabase(source))
            return;
    }

    //  Now we know we can connect, lets build the query

    decl String:authid[64]; 
    if ((flags & BANFLAG_AUTO) != 0)
    {
        if (strlen(identity) > 0)
            strcopy(authid, sizeof(authid), identity);
        else
            GetClientAuthString(client, authid, sizeof(authid));

        if (strncmp(authid, "STEAM_", 6) != 0 && authid[7] == ':')
            flags |= BANFLAG_IP;
        //else
        //	flags |= BANFLAG_AUTHID;
    }
    else
        authid[0] = '\0';

    decl String:columns[64];
    decl String:values[128];
    if ((flags & BANFLAG_IP) != 0)
    {
        if (strlen(identity) > 0)
            strcopy(authid, sizeof(authid), identity);
        else if (client > 0)
            GetClientIP(client, authid, sizeof(authid));
        else
        {
            LogAction(client, -1, "Insufficient criteria to create a ban!");
            return;
        }

        strcopy(columns, sizeof(columns), "ipaddr");
        Format(values, sizeof(values), "'%s'", authid);
    }
    else //if ((flags & BANFLAG_AUTHID) != 0)
    {
        if (authid[0] == '\0')
        {
            if (strlen(identity) > 0)
                strcopy(authid, sizeof(authid), identity);
            else if (client > 0)
                GetClientAuthString(client, authid, sizeof(authid));
            else
            {
                LogAction(client, -1, "Insufficient criteria to create a ban!");
                return;
            }
        }

        strcopy(columns, sizeof(columns), "steam_id");
        Format(values, sizeof(values), "'%s'", authid);
    }

    if (client > 0 && IsClientInGame(client))
    {
        decl String:player_name[65];
        GetClientName(client, player_name, sizeof(player_name));

        decl String:escName[sizeof(player_name)*2+1];
        if (!SQL_EscapeString(db, player_name, escName, sizeof(escName)))
        {
            LogError("Unable to Escape %s!", player_name);
            strcopy(escName, sizeof(escName), player_name);
        }

        StrCat(columns, sizeof(columns),", player_name");
        Format(values, sizeof(values), "%s, '%s'", values, escName);
    }

    if (source > 0 && IsClientInGame(source))
    {
        new AdminId:adminId = GetUserAdmin(source);
        if (adminId != INVALID_ADMIN_ID)
        {
            decl String:adminName[64]; 
            GetAdminUsername(adminId, adminName, sizeof(adminName));
            if (adminName[0] != '\0')
            {
                StrCat(columns, sizeof(columns),", banned_by");
                Format(values, sizeof(values), "%s, '%s'", values, adminName);
            }
            else
            {
                StrCat(columns, sizeof(columns),", banned_by");
                Format(values, sizeof(values), "%s, '%N'", values, source);
            }
        }
        else
        {
            StrCat(columns, sizeof(columns),", banned_by");
            Format(values, sizeof(values), "%s, '%N'", values, source);
        }

        decl String:adminAuthId[64]; 
        GetClientAuthString(source, adminAuthId, sizeof(adminAuthId));
        if (adminAuthId[0] != '\0')
        {
            StrCat(columns, sizeof(columns),", banned_by_id");
            Format(values, sizeof(values), "%s, '%s'", values, adminAuthId);
        }
    }

    if (reason[0] != '\0')
    {
        StrCat(columns, sizeof(columns),", ban_reason");
        Format(values, sizeof(values), "%s, '%s'", values, reason);
    }

    decl String:query[255];
    Format(query, sizeof(query),
           "REPLACE INTO mysql_bans (%s, ban_length, timestamp) VALUES (%s, %d, CURRENT_TIMESTAMP)",
           columns, values, time);

    // run query
    // Execute the query in a Thread and check the results in the SQL_InsertBan() callback.
    new Handle:data = CreateDataPack();
    WritePackCell(data, client);
    WritePackCell(data, source);
    WritePackCell(data, time);
    WritePackString(data, authid);
    WritePackString(data, reason);
    WritePackString(data, query);
    SQL_TQuery(db, SQL_InsertBan, query, data);
}

public SQL_InsertBan(Handle:owner, Handle:hndl, const String:error[], any:data)
{
    ResetPack(data);
    new client = ReadPackCell(data);
    if (client > 0 && !IsClientInGame(client))
        client = 0;

    new source = ReadPackCell(data);
    if (source > 0 && !IsClientInGame(source))
        source = 0;

    new time = ReadPackCell(data);

    decl String:authid[64]; authid[0] = '\0';
    ReadPackString(data, authid, sizeof(authid));

    decl String:reason[128]; reason[0] = '\0';
    ReadPackString(data, reason, sizeof(reason));

    if (hndl == INVALID_HANDLE || error[0] != '\0')
    {
        decl String:query[255]; query[0] = '\0';
        ReadPackString(data, query, sizeof(query));

        LogAction(client, -1, "ISSUE! %s %s", error, query);
        LogError("Unable to REPLACE ban into DB,%s, query=%s", error, query);
    }
    else
    {
        // log actions
        if (client > 0)
        {
            LogAction(source, -1, "[MySQL Bans] [Put into DB] Auth %s, Name %N Ban time %d, Reason %s, Client %N", authid, client, time, reason, source);
        }
        else
        {
            LogAction(source, -1, "[MySQL Bans] [Put into DB] Auth %s, Ban time %d, Reason %s, Client %N", authid, time, reason, source);
        }
    }

    CloseHandle(data);
}

DeleteBan(const String:identity[], any:source)
{
    // Test connection
    if (db == INVALID_HANDLE)
    {
        if (!ConnectToDatabase(source))
            return;
    }

    // lets make the query
    decl String:query[255];
    Format(query, sizeof(query),
            "DELETE FROM mysql_bans WHERE steam_id = '%s' OR ipaddr = '%s'", identity, identity);

    new Handle:data = CreateDataPack();
    WritePackCell(data, source);
    WritePackString(data, identity);
    SQL_TQuery(db, SQL_DeleteBan, query, data);
}

public SQL_DeleteBan(Handle:owner, Handle:hndl, const String:error[], any:data)
{
    ResetPack(data);
    new source = ReadPackCell(data);
    if (source > 0 && !IsClientInGame(source))
        source = 0;

    decl String:identity[64];
    ReadPackString(data, identity, sizeof(identity));

    CloseHandle(data);

    if (hndl == INVALID_HANDLE || error[0] != '\0')
    {
        LogAction(source, -1, "[MySQL Bans] Player NOT Found. ID: '%s', Lookup Failed", identity);

        /* Error Checking */
        if (GetConVarInt(ErrorChecking) >= 1)
        {
            PrintCenterTextAll("[MySQL Bans] [UB2] Player NOT banned. ID: '%s', Lookup Failed", identity);
            PrintToServer("[MySQL Bans] [UB2] Player NOT banned. ID: '%s', Lookup Failed", identity);
        }
    }
    else
    {
        LogAction(source, -1, "[MySQL Bans] \"%L\" removed ban (filter \"%s\")", source, identity);
    }
}
