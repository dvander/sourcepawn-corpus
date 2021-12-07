/**
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

// Add table layout here
/*

DROP TABLE IF EXISTS `mysql_bans`;
CREATE TABLE IF NOT EXISTS `mysql_bans` (
  `id` int(11) NOT NULL auto_increment,
  `steam_id` varchar(32) NOT NULL,
  `player_name` varchar(65) NOT NULL,
  `ipaddr` varchar(24) NOT NULL,
  `ban_length` int(1) NOT NULL default '0',
  `ban_reason` varchar(100) NOT NULL,
  `banned_by` varchar(100) NOT NULL,
  `timestamp` timestamp NOT NULL default CURRENT_TIMESTAMP on update CURRENT_TIMESTAMP,
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
#define PLUGIN_VERSION "2.0"

//////////////////////////////////////////////////////////////////
// Plugin Info
//////////////////////////////////////////////////////////////////
public Plugin:myinfo = 
{
	name = "MySQL Bans",
	author = "Team MX | MoggieX",
	description = "Ban using a MySQL DB over multiple servers",
	version = PLUGIN_VERSION,
	url = "http://www.Afterbuy.co.uk"
};

//////////////////////////////////////////////////////////////////
// Handles
//////////////////////////////////////////////////////////////////
new Handle:ErrorChecking;
new Handle:AdminChecking;
new Handle:StoreAllBans;

//////////////////////////////////////////////////////////////////
// Set vars on plugin start
//////////////////////////////////////////////////////////////////
public OnPluginStart()
{
// Load phrases
	LoadTranslations("mysqlbans.phrases");

// Reg commands
	RegAdminCmd("mysql_ban",Command_Ban,ADMFLAG_BAN,"Bans player by STEAMID")
	RegAdminCmd("mysql_addban",Command_AddBan,ADMFLAG_BAN,"Bans player by STEAMID")
	RegAdminCmd("mysql_unban",Command_UnBan,ADMFLAG_BAN,"Unbans player by STEAMID")
	RegAdminCmd("mysql_ipban",Command_BanIp,ADMFLAG_BAN,"Unbans player by IP")

// Create convars
	CreateConVar("mysql_bans_version", "0.1", "MySQL Bans Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY)
	AdminChecking = CreateConVar("mysql_bans_admin_check","1","Check Admins if banned? Speeds things up a touch 0= Do Not - 1 = Do Check", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	ErrorChecking = CreateConVar("mysql_bans_error_check","1","Shows Error Messages in-game chat, 0= don't show, 1 = show", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	StoreAllBans = CreateConVar("mysql_bans_store_all_bans","1","Store ALL bans in DB, 0=only store mysql bans, 1 = store ALL bans", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);

	VerifyTable();
}

//////////////////////////////////////////////////////////////////
// Player checking on connection (post admin check)
//////////////////////////////////////////////////////////////////
public OnClientPostAdminCheck(client)
{

// Check if a BOT if = then bailout

	if(IsFakeClient(client))
	return true;

// Check if a ADMIN if = then bailout - again another way of speeding this up as admins will not be banned

	if (GetConVarInt(AdminChecking) == 1)
	{
		/* Error Checking */	
		if (GetConVarInt(ErrorChecking) == 1)
		{
			LogAction(client, -1, "[MySQL Bans] Player was admin checked");
			PrintToServer("\x04[MySQL Bans]\x03 Player was admin checked");
			PrintToChatAll("\x04[MySQL Bans]\x03 Player was admin checked");
		}
		
		/* do stuff */
		new AdminId:AdminID = GetUserAdmin(client)
		if(AdminID != INVALID_ADMIN_ID)

   		return true;
	}

// OK, now thats over lets get thier data for processing!

	/* Error Checking */
	if (GetConVarInt(ErrorChecking) == 1)
	{
	LogAction(client, -1, "[MySQL Bans] Player is NOT a BOT or an ADMIN");
	PrintToServer("\x04[MySQL Bans]\x03 Player is NOT a BOT or an ADMIN");
	PrintToChatAll("\x04[MySQL Bans]\x03 Player is NOT a BOT or an ADMIN");
	}

// Delcare & log some stuff

 	decl String:steam_id[32];	// Steam ID
 	decl String:player_name[65];	// Player name
	decl String:ipaddr[24];		// IP Address
 	decl ban_length;		// Checking thier ban length
 	decl String:ban_reason[100];	// Reason for ban
 	decl String:error[255];		// Error!
 	decl Float:ban_remaining;	// Amount of time left in ban
 
// Get Client Auth & IP
 	GetClientName(client, player_name, sizeof(player_name));
 	GetClientIP(client, ipaddr, sizeof(ipaddr));
 
// Check if on LAN and if so bail out

	// why is this like this? I have no idea!
 	steam_id[0] = '\0';

 	if (GetClientAuthString(client, steam_id, sizeof(steam_id)))
 	{
  		if (StrEqual(steam_id, "STEAM_ID_LAN"))
  		{
			/* Error Checking */
			if (GetConVarInt(ErrorChecking) == 1)
			{
			   	LogAction(client, -1, "[MySQL Bans] User Steam ID empty. You are on a LAN");
				PrintToServer("\x04[MySQL Bans]\x03 User Steam ID empty. You are on a LAN");
				PrintToChatAll("\x04[MySQL Bans]\x03 User Steam ID empty. You are on a LAN");
			}

   			//return true;
  		}
	 }

// print data to server

	/* Error Checking */
	if (GetConVarInt(ErrorChecking) == 1)
	{
		LogAction(client, -1, "[MySQL Bans] Player In Server <%s>,<%s>,<%s>", player_name, ipaddr, steam_id);
		PrintToServer("\x04[MySQL Bans]\x03 Player In Server <%s>,<%s>,<%s>", player_name, ipaddr, steam_id);
		PrintToChatAll("\x04[MySQL Bans]\x03 Player In Server <%s>,<%s>,<%s>", player_name, ipaddr, steam_id);
	}


 	new Handle:db = SQL_Connect("default", true, error, sizeof(error));
 	if (db == INVALID_HANDLE)
 	{
		/* Error Checking */
 		if (GetConVarInt(ErrorChecking) == 1)
		{
			LogAction(client, -1, "[MySQL Bans] Could Not Connect to Database, error: %s", error);
			PrintToServer("\x04[MySQL Bans]\x03 Could Not Connect to Database, error: %s", error);
			PrintToChatAll("\x04[MySQL Bans]\x03 Could Not Connect to Database, error: %s", error);
		}
  		CloseHandle(db);
  		return true;
 	}
 
// Form the SQL and add the parameters to it.
// Think this can be improved by only search for steam ID only, then searching again if a match found

 	decl String:query[255];
 	Format(query, 
  	sizeof(query),
 	
	// OLD query
	//"SELECT steam_id, ban_length, ban_reason FROM mysql_bans WHERE steam_id = '%s'", steam_id);

	// New query - this one gets the IP and also now checks Steam ID AND IP
	"SELECT ban_reason, ban_length, TIME_TO_SEC(TIMEDIFF(ADDTIME(timestamp,SEC_TO_TIME(ban_length*60)),CURRENT_TIMESTAMP))/60 FROM mysql_bans WHERE steam_id = '%s' OR ipaddr = '%s'", steam_id, ipaddr);

	/* Error Checking */
	if (GetConVarInt(ErrorChecking) == 1)
	{
  		LogAction(client, -1, "[MySQL Bans] Query String: <%s>", query);
		PrintToServer("\x04[MySQL Bans]\x03 Query String: <%s>", query);
		PrintToChatAll("\x04[MySQL Bans]\x03 Query String: <%s>", query);
	}

 	// make a new handle to stuff the query in
 	new Handle:hQuery;

	// bail out if there is an issue
 	if ((hQuery = SQL_Query(db, query)) == INVALID_HANDLE)
	{
		/* Error Checking */
		if (GetConVarInt(ErrorChecking) == 1)
		{
			LogAction(client, -1, "[MySQL Bans] Lookup failed for <%s>,<%s>,<%s>", player_name, ipaddr, steam_id);
			PrintToServer("\x04[MySQL Bans]\x03 Lookup failed for <%s>,<%s>,<%s>", player_name, ipaddr, steam_id);
			PrintToChatAll("\x04[MySQL Bans]\x03 Lookup failed for <%s>,<%s>,<%s>", player_name, ipaddr, steam_id);
		}

		CloseHandle(db);
		return true;
	}

	// the lucky lad wasn't banned
	if (!SQL_FetchRow(hQuery))
	{
		/* Error Checking */
		if (GetConVarInt(ErrorChecking) == 1)
		{
			LogAction(client, -1, "[MySQL Bans] <%s>,<%s>,<%s> NOT found in bans database. Play nice now!>", player_name, ipaddr, steam_id);
			PrintToServer("\x04[MySQL Bans]\x03 <%s>,<%s>,<%s> NOT found in bans database. Play nice now!>", player_name, ipaddr, steam_id);
			PrintToChatAll("\x04[MySQL Bans]\x03 <%s>,<%s>,<%s> NOT found in bans database. Play nice now!>", player_name, ipaddr, steam_id);
		}
	}

	// Must have been a match, so lets deal with the bann'ee
	else
	{
		ban_length = SQL_FetchInt(hQuery,1);
		ban_remaining = (ban_length > 0) ? SQL_FetchFloat(hQuery,2) : 0.0;
		if (ban_remaining > 0)
		{
			SQL_FetchString(hQuery,0,ban_reason,sizeof(ban_reason));

			LogAction(client, -1, "[MySQL Bans] Player is <%s>,<%s>,<%s> BANNED & has been removed", player_name, ipaddr, steam_id);

			/* Error Checking */
			if (GetConVarInt(ErrorChecking) == 1)
			{
				PrintCenterTextAll("[MySQL Bans] Player is <%s>,<%s>,<%s> BANNED & has been removed", player_name, ipaddr, steam_id);
				PrintToServer("[MySQL Bans] Player is <%s>,<%s>,<%s> BANNED & has been removed", player_name, ipaddr, steam_id);
				PrintToChatAll("[MySQL Bans] Player is <%s>,<%s>,<%s> BANNED & has been removed", player_name, ipaddr, steam_id);
			}

			// kick em with a reason and length of time
			if (ban_length == 0)
				KickClient(client,"You have been Banned for %s", ban_reason);
			else
			{
				if (ban_remaining < 60.0)
					KickClient(client,"You have been Banned for %s\nyou have %2.1f minutes left", ban_reason, ban_remaining);
				else
				{
					ban_remaining /= 60.0; // convert to hours
					if (ban_remaining < 24.0)
						KickClient(client,"You have been Banned for %s\nyou have %2.1f hours left", ban_reason, ban_remaining);
					else
					{
						ban_remaining /= 24.0;
						if (ban_remaining < 7.0)
							KickClient(client,"You have been Banned for %s\nyou have %2.1f days left", ban_reason, ban_remaining);
						else
						{
							ban_remaining /= 7.0;
							if (ban_remaining < 4.0)
								KickClient(client,"You have been Banned for %s\nyou have %2.1f weeks left", ban_reason, ban_remaining);
							else
							{
								ban_remaining /= 4.0;
								KickClient(client,"You have been Banned for %s\nyou have %2.1f months left", ban_reason, ban_remaining);
							}
						}
					}
				}
			}
		}
	}
	CloseHandle(hQuery);
	CloseHandle(db);
	return true;
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
	if (strncmp(authid, "STEAM_0:", 8) != 0)
	{
		ReplyToCommand(client, "[SM] %t", "Invalid SteamID");
		return Plugin_Handled;
	}

	new minutes = StringToInt(time);

// My log message
 	LogAction(client, -1, "[MySQL Bans] \"%L\" added ban (minutes \"%d\") (id \"%s\") (reason \"%s\")", client, minutes, authid, reason);
	
 	if (GetConVarInt(ErrorChecking) > 0)
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
	if (GetConVarInt(ErrorChecking) == 1)
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
	if (strncmp(arg, "STEAM_0:", 8) == 0)
	{
		ban_flags |= BANFLAG_AUTHID;
	}

// Ignoring IP bans for now as I'm not that bright =)
	else
	{
		ban_flags |= BANFLAG_IP;
	}


// <<<<<<<<<<<< START UN BAN

	if (DeleteBan(arg, client))
 	{
		// now I'm happy its been error trapped and we have a match! Some lucky n00blets is goign to be unbanned
		RemoveBan(arg, ban_flags, "mysql_unban", client);
		ReplyToCommand(client, "[MySQL Bans] %t", "Removed Matching Bans", arg);
	}

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
		ReplyToCommand(client, "[MySQL Bans] Usage: mysql_banip <time> <ip|#userid|name> [reason]");
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

	if (GetConVarInt(ErrorChecking) == 1)
	{
		PrintCenterTextAll("[MySQL Bans] <%N> was banned by IP <%s> for <%d> minutes, by <%N>", hit_client, arg, minutes, Arguments[len], client);
		PrintToServer("[MySQL Bans] <%N> was banned by IP <%s> for <%d> minutes, by <%N>", hit_client, arg, minutes, Arguments[len], client);
	}
				
	ReplyToCommand(client, "[MySQL Bans] %t", "Ban added");
	
	BanIdentity(arg, 
				minutes, 
				BANFLAG_IP, 
				Arguments[len], 
				"mysql_banip", 
				client);
				
	if (hit_client != -1)
	{
		KickClient(hit_client, "Banned: %s", Arguments[len]);
	}

	return Plugin_Handled;
}

//////////////////////////////////////////////////////////////////
// Helper Functions
//////////////////////////////////////////////////////////////////
PrepareBan(client, target, time, const String:reason[])
{
	// declare the details
	decl String:authid[64], 
	String:name[32];
	GetClientAuthString(target, authid, sizeof(authid));
	GetClientName(target, name, sizeof(name));

	InsertBan(target, time, BANFLAG_AUTO, reason, client, "");

	PrintToChatAll("\x04[MySQL Bans]\x01 %N  banned: %N for %s", client, target, reason);
		
	// Now that they are banned in the database, lets also for safe keeping put the user into the banned_user.cfg file for good measure!

	BanClient(
		target, 
		time, 
		BANFLAG_AUTO, 
		reason, 
		reason, 
		"mysql_ban",
		client);

	ReplyToCommand(client, "[MySQL Bans]: %t", "Ban added");
	return true;

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
	decl String:error[255];
	new Handle:db = SQL_Connect("default", true, error, sizeof(error));
	if (db == INVALID_HANDLE)
	{
		LogError("[MySQL Bans] Could Not Connect to Database, error: %s", error);
		return false;
	}

	decl String:query[512];
	Format(query,sizeof(query), "%s%s%s%s%s%s%s%s%s%s%s%s%s",
		"CREATE TABLE IF NOT EXISTS `mysql_bans` (",
		"  `id` int(11) NOT NULL auto_increment,",
		"  `steam_id` varchar(32) NOT NULL,",
		"  `player_name` varchar(65) NOT NULL,",
		"  `ipaddr` varchar(24) NOT NULL,",
		"  `ban_length` int(1) NOT NULL default '0',",
		"  `ban_reason` varchar(100) NOT NULL,",
		"  `banned_by` varchar(100) NOT NULL,",
		"  `timestamp` timestamp NOT NULL default CURRENT_TIMESTAMP on update CURRENT_TIMESTAMP,",
		"  PRIMARY KEY  (`id`),",
		"  UNIQUE KEY `steam_id` (`steam_id`),",
		"  UNIQUE KEY `ipaddr` (`ipaddr`)",
		")");

	new bool:success = SQL_FastQuery(db, query);
	if(!success)
	{
		SQL_GetError(db, error, sizeof(error));
		LogError("Unable to verify mysql_bans table:%s", error);
	}

	CloseHandle(db);
	return success;
}

bool:InsertBan(client, time, flags, const String:reason[], any:source, const String:identity[])
{
	// Error capturing
	decl String:error[255];
	new Handle:db = SQL_Connect("default", true, error, sizeof(error));
	if (db == INVALID_HANDLE)
	{
		LogAction(source, -1, "[MySQL Bans] Could Not Connect to Database, error: %s", error);

		/* Error Checking */
		if (GetConVarInt(ErrorChecking) == 1)
		{
			PrintCenterTextAll("[MySQL Bans] Could Not Connect to Database, error: %s", error);
			PrintToServer("[MySQL Bans] Could Not Connect to Database, error: %s", error);

		}
		return false;
	}

	//  Now we know we can connect, lets build the search string

	decl String:authid[64]; 
	decl String:query[255];

	if ((flags & BANFLAG_AUTO) != 0)
	{
		if (strlen(identity) > 0)
			strcopy(authid, sizeof(authid), identity);
		else
			GetClientAuthString(client, authid, sizeof(authid));

		if (strncmp(authid, "STEAM_0:", 8) != 0)
			flags |= BANFLAG_IP;
		//else
		//	flags |= BANFLAG_AUTHID;
	}
	else
		authid[0] = '\0';

	if ((flags & BANFLAG_IP) != 0)
	{
		if (strlen(identity) > 0)
			strcopy(authid, sizeof(authid), identity);
		else if (client > 0)
			GetClientIP(client, authid, sizeof(authid));
		else
		{
			LogAction(client, -1, "Insufficient criteria to create a ban!");
			return false;
		}

		if (client > 0)
		{
			Format(query, sizeof(query),
				"REPLACE INTO mysql_bans (player_name, ipaddr, ban_length, ban_reason, banned_by, timestamp) VALUES ('%N', '%s', '%d', '%N', CURRENT_TIMESTAMP)", client, authid, time, reason, source);
		}
		else
		{
			Format(query, sizeof(query),
				"REPLACE INTO mysql_bans (ipaddr, ban_length, ban_reason, banned_by, timestamp) VALUES ('%N', '%s', '%d', '%N', CURRENT_TIMESTAMP)", authid, time, reason, source);
		}
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
				return false;
			}
		}

		if (client > 0)
		{
			Format(query, sizeof(query),
				"REPLACE INTO mysql_bans (steam_id, player_name, ban_length, ban_reason, banned_by, timestamp) VALUES ('%s', '%N', '%d', '%s', '%N', CURRENT_TIMESTAMP)", authid, client, time, reason, source);
		}
		else
		{
			Format(query, sizeof(query),
				"REPLACE INTO mysql_bans (steam_id, ban_length, ban_reason, banned_by, timestamp) VALUES ('%s', '%N', '%d', '%s', '%N', CURRENT_TIMESTAMP)", authid, time, reason, source);
		}
	}

	// run query
	new bool:success = SQL_FastQuery(db, query);
	if (success)
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
	else
	{
		SQL_GetError(db, error, sizeof(error));
		LogAction(client, -1, "ISSUE! %s %s", error, query);
		LogError("Unable to REPLACE ban into DB,%s, query=%s", error, query);
	}

	CloseHandle(db);
	return success;
}

bool:DeleteBan(const String:identity[], any:source)
{
	// declare error var
	decl String:error[255];

	// Open db connection and test it
	new Handle:db = SQL_Connect("default", true, error, sizeof(error));

	// Test connection
	if (db == INVALID_HANDLE)
	{
		LogAction(source, -1, "[MySQL Bans] [Error A1] Could Not Connect to Database, error: %s", error);
		if (GetConVarInt(ErrorChecking) == 1)
		{
			PrintCenterTextAll("[MySQL Bans] Could Not Connect to Database, error: %s", error);
			PrintToServer("[MySQL Bans] [Error DB] Could Not Connect to Database, error: %s", error);
		}
		return false;
	}

	// lets make the query
	decl String:query[255];
	Format(query, 
		sizeof(query),
		"DELETE FROM mysql_bans WHERE steam_id = '%s' OR ipaddr = '%s'", identity, identity);

	new bool:success = SQL_FastQuery(db, query);
	if (success)
	{
		LogAction(source, -1, "[MySQL Bans] \"%L\" removed ban (filter \"%s\")", source, identity);
	}
	else
	{
		LogAction(source, -1, "[MySQL Bans] Player NOT Found. ID: '%s', Lookup Failed", identity);

		/* Error Checking */
		if (GetConVarInt(ErrorChecking) == 1)
		{
			PrintCenterTextAll("[MySQL Bans] [UB2] Player NOT banned. ID: '%s', Lookup Failed", identity);
			PrintToServer("[MySQL Bans] [UB2] Player NOT banned. ID: '%s', Lookup Failed", identity);
		}
	}
	CloseHandle(db);
	return success;
}
