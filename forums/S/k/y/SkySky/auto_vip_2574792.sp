#include <sourcemod>
#include <sdkhooks>
#include <sdktools>
#include <cstrike>

#define FLAG_LETTERS_SIZE 26

#define MAX_PLAYERS 32 // maksymalna ilosc graczy na serwerze


new AdminFlag:g_FlagLetters[FLAG_LETTERS_SIZE];
Handle sql;																	
new Handle:sm_testvip_flags = INVALID_HANDLE;
new Handle:sm_testvip_days = INVALID_HANDLE;
char dbError[512];	


public Plugin:myinfo = 
{
	name = "VIP mysql",
	author = "Sky",
	description = "VIP automatic",
	version = "0.2",
	//url = "<- URL ->"
}

public OnPluginStart()
{
	CreateConVar("auto_vip", "0.2", "AUTO-DELETE FLAGS FOR TIME", FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	HookEvent("player_spawn", PlayerSpawn);
	g_FlagLetters = CreateFlagLetters();
	sm_testvip_flags = CreateConVar("sm_testvip_flags", "ar", "What flags get user ?");
	sm_testvip_days = CreateConVar("sm_testvip_days", "10", "How long time(days) user get flags");
	RegConsoleCmd("sm_testvip", testvip);
	DataBaseConnect();
}



public Action:PlayerSpawn(Handle:event_spawn, String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event_spawn, "userid"));
	if(!IsValidClient(client) || IsFakeClient(client))
		return;
	
	
	
	WriteToDatabase(client);
	GiveFlagBySteamid(client);
	UpdateTimeDatabase(client);
	GetDateBySteamid(client);// Every spawn Update/Delete flag,date to user
	
	
	
}


public Action:GiveFlagBySteamid(client)
{
	
	new String:tmp[1024];
	decl String:player_authid[32];
	
	if (GetClientAuthString(client, player_authid, sizeof(player_authid)))
	{
		Format(tmp, sizeof(tmp), "SELECT `flags` FROM `autovip` WHERE steamid = '%s';", player_authid);
		SQL_TQuery(sql, GiveFlagBySteamidContinue, tmp, client);
	}
	
	
}				

public GiveFlagBySteamidContinue(Handle:owner, Handle:query, const String:error[], any:client)
{
	decl String:player_authid[32];
	
	if(query == INVALID_HANDLE)
	{
		LogError("Load error: %s", error);
		return;
	}
	
	
	if(SQL_GetRowCount(query))
	{
		new String:flags[64];
		
		
		while(SQL_MoreRows(query))
		{ 
			
			while(SQL_FetchRow(query))
			{
				flags[client] = SQL_FetchString(query, 0, flags, sizeof(flags));
				
				
				SQL_FetchString(query, 0, flags, sizeof(flags));
				
				
				if (GetClientAuthString(client, player_authid, sizeof(player_authid)))
				{
					
					for (new i = 0; i < strlen(flags); ++i)
					{
						if (flags[i] < 'a' || flags[i] > 'z')
							continue;
						
						if (g_FlagLetters[flags[i]-'a'] < Admin_Reservation)
							continue;
						
						
						
						/*new AdminId:admin;
						admin = AdminId:FindAdminByIdentity(dupkey, player_authid);
						SetAdminFlag(AdminId:admin, g_FlagLetters[flags[i]-'a'], true);*/
						
						AddUserFlags(client, g_FlagLetters[flags[i]-'a'])
						
					}
					
				}	
			}
		}
	}
	
	
}


public Action:GetDateBySteamid(client)
{
	
	new String:tmp[1024];
	decl String:player_authid[32];
	
	if (GetClientAuthString(client, player_authid, sizeof(player_authid)))
	{
		Format(tmp, sizeof(tmp), "SELECT UNIX_TIMESTAMP(`date`), UNIX_TIMESTAMP(`expirationdate`) FROM `autovip` WHERE steamid = '%s';", player_authid);
		SQL_TQuery(sql, GetDateBySteamidContinue, tmp, client);
	}
	
	
}	


public Action:testvip(client, args)
{
	
	
	new String:tmp[1024];
	decl String:player_authid[32];
	
	if (GetClientAuthString(client, player_authid, sizeof(player_authid)))
	{
		Format(tmp, sizeof(tmp), "SELECT `verify` FROM `autovip` WHERE steamid = '%s';", player_authid);
		SQL_TQuery(sql, testvipcointinue, tmp, client);
	}
	
}


public testvipcointinue(Handle:owner, Handle:query, const String:error[], any:client)
{
	decl String:player_authid[32];
	new String:tmp[1024];
	int day, month, year, endday, endmonth,endyear
	new String:sday[10]; 
	new String:smonth[10]; 
	new String:syear[10]; 
	new Handle:testvip_flagstag = FindConVar("sm_testvip_flags"); 
	new String:testvip_flags[32];
	new dayinmonth[13] = {0, 31, 28, 30, 31, 30, 31, 30, 31, 30, 31, 30, 31};
	
	FormatTime(sday, sizeof(sday), "%d"); // Obtain day 
	FormatTime(smonth, sizeof(smonth), "%m"); // Obtain month 
	FormatTime(syear, sizeof(syear), "%Y"); // Obtain year 
	
	day = StringToInt(sday); 
	month = StringToInt(smonth); 
	year = StringToInt(syear); 
	
	
	
	new testvip_days = GetConVarInt(sm_testvip_days);
	GetConVarString(testvip_flagstag, testvip_flags, sizeof(testvip_flags));
	
	
	endday = day + testvip_days;
	endmonth = month;
	endyear = year;
	
	if (endday > dayinmonth[month]) 
	{
		endday = endday - dayinmonth[month];
		endmonth = endmonth + 1;
	}
	
	if (endmonth == 13) 
	{
		endyear = endyear + 1;
		endmonth = 1;
	}
	
	if(query == INVALID_HANDLE)
	{
		LogError("Load error: %s", error);
		return;
	}
	if(SQL_GetRowCount(query))
	{
		new String:verify[512];
		int verifyint;
		
		while(SQL_MoreRows(query))
		{
			
			while(SQL_FetchRow(query))
			{
				
				SQL_FetchString(query, 0, verify, sizeof(verify));
				
				verifyint = StringToInt(verify);
				
				
				if (verifyint == 0) 
				{
					if (GetClientAuthString(client, player_authid, sizeof(player_authid)))
					{
						
						PrintToChat(client, "\x01[\x04VIP\x01] You activated \x04VIP\x01");
						Format(tmp, sizeof(tmp), "UPDATE `autovip` SET flags = '%s' ,verify = '1', expirationdate = '%i-%i-%i' WHERE steamid = '%s';", testvip_flags,endyear,endmonth,endday,player_authid);
						SQL_TQuery(sql, WriteToDatabase_Handler, tmp, client);
						
					}
				}
				else
				{
					PrintToChat(client, "\x01[\x04VIP\x01] You can't activate again \x04VIP\x01");
				}
			}
		}
	}
	
	
}


public GetDateBySteamidContinue(Handle:owner, Handle:query, const String:error[], any:client)
{
	decl String:player_authid[32];
	new String:tmp[1024];
	
	if(query == INVALID_HANDLE)
	{
		LogError("Load error: %s", error);
		return;
	}
	if(SQL_GetRowCount(query))
	{
		new String:date[512];
		new String:expirationdate[512];
		int dateint,expirationdateint;
		
		while(SQL_MoreRows(query))
		{
			
			while(SQL_FetchRow(query))
			{
				
				
				SQL_FetchString(query, 0, date, sizeof(date));
				SQL_FetchString(query, 1, expirationdate, sizeof(expirationdate));
				
				dateint = StringToInt(date);
				expirationdateint = StringToInt(expirationdate);
				dateint = ((expirationdateint - dateint)/60/60/24);
				
				if (dateint >= 1)
				{
					PrintToChat(client, "\x01[\x04VIP\x01] Your VIP will expire in \x04%i day(s)\x01",dateint);
					
					
					if (GetClientAuthString(client, player_authid, sizeof(player_authid)))
					{
						
						Format(tmp, sizeof(tmp), "UPDATE `autovip` SET howmanydays = '%i' WHERE steamid = '%s';", dateint,player_authid);
						SQL_TQuery(sql, WriteToDatabase_Handler, tmp, client);
						
					}
				} else if (dateint <= 0)
				{
					Format(tmp, sizeof(tmp), "UPDATE `autovip` SET flags = ' ', howmanydays = '0' WHERE steamid = '%s';", player_authid);
					SQL_TQuery(sql, WriteToDatabase_Handler, tmp, client);
				}
			}
		}
	}
	
	
}


public Action:DataBaseConnect()
{
	sql = SQL_Connect("autovip", true, dbError, sizeof(dbError));
	if(sql == INVALID_HANDLE)
		PrintToServer("Could not connect: %s", dbError);
	SQL_LockDatabase(sql);
	SQL_FastQuery(sql, "CREATE TABLE IF NOT EXISTS `autovip` (`id` INT(11) NOT NULL AUTO_INCREMENT, `steamid` VARCHAR(48) NOT NULL, `flags` VARCHAR(48) NOT NULL, `dupkey` VARCHAR(48), `date` VARCHAR(15), `expirationdate` VARCHAR(15), `howmanydays` INT(11), `verify` INT(4) DEFAULT 0  NOT NULL, PRIMARY KEY (`id`), UNIQUE KEY `keyid` (`dupkey`,`steamid`)) ENGINE=MyISAM  DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;");
	SQL_UnlockDatabase(sql);
	
}


public Action:WriteToDatabase(client)
{
	
	new String:tmp[1024];
	decl String:player_authid[32];
	
	if (GetClientAuthString(client, player_authid, sizeof(player_authid)))
	{
		
		Format(tmp, sizeof(tmp), "INSERT INTO `autovip` (`steamid`,`dupkey`) VALUES ('%s','%skey');", player_authid,player_authid);
		SQL_TQuery(sql, WriteToDatabase_Handler, tmp, client);
		
	}
}

public Action:UpdateTimeDatabase(client)
{
	int day, month, year
	new String:sday[10]; 
	new String:smonth[10]; 
	new String:syear[10]; 
	
	FormatTime(sday, sizeof(sday), "%d"); // Obtain day 
	FormatTime(smonth, sizeof(smonth), "%m"); // Obtain month 
	FormatTime(syear, sizeof(syear), "%Y"); // Obtain year 
	
	day = StringToInt(sday); 
	month = StringToInt(smonth); 
	year = StringToInt(syear); 
	
	new String:tmp[1024];
	decl String:player_authid[32];
	
	if (GetClientAuthString(client, player_authid, sizeof(player_authid)))
	{
		
		Format(tmp, sizeof(tmp), "UPDATE `autovip` SET date = '%i-%i-%i' WHERE steamid = '%s';", year,month,day,player_authid);
		SQL_TQuery(sql, WriteToDatabase_Handler3, tmp, client);
		
	}
	
}


public WriteToDatabase_Handler(Handle:owner, Handle:query, const String:error[], any:client)
{
	if(query == INVALID_HANDLE)
	{
		LogError("Save error: %s", error);
		return;
	}
}

public WriteToDatabase_Handler2(Handle:owner, Handle:query, const String:error[], any:client)
{
	if(query == INVALID_HANDLE)
	{
		LogError("Save error: %s", error);
		return;
	}
}

public WriteToDatabase_Handler3(Handle:owner, Handle:query, const String:error[], any:client)
{
	if(query == INVALID_HANDLE)
	{
		LogError("Save error: %s", error);
		return;
	}
}



public bool:IsValidClient(client)
{
	if(client >= 1 && client <= MaxClients && IsClientInGame(client))
		return true;
	
	return false;
}


stock AdminFlag:CreateFlagLetters()
{
	new AdminFlag:FlagLetters[FLAG_LETTERS_SIZE];
	
	FlagLetters['a'-'a'] = Admin_Reservation;
	FlagLetters['b'-'a'] = Admin_Generic;
	FlagLetters['c'-'a'] = Admin_Kick;
	FlagLetters['d'-'a'] = Admin_Ban;
	FlagLetters['e'-'a'] = Admin_Unban;
	FlagLetters['f'-'a'] = Admin_Slay;
	FlagLetters['g'-'a'] = Admin_Changemap;
	FlagLetters['h'-'a'] = Admin_Convars;
	FlagLetters['i'-'a'] = Admin_Config;
	FlagLetters['j'-'a'] = Admin_Chat;
	FlagLetters['k'-'a'] = Admin_Vote;
	FlagLetters['l'-'a'] = Admin_Password;
	FlagLetters['m'-'a'] = Admin_RCON;
	FlagLetters['n'-'a'] = Admin_Cheats;
	FlagLetters['o'-'a'] = Admin_Custom1;
	FlagLetters['p'-'a'] = Admin_Custom2;
	FlagLetters['q'-'a'] = Admin_Custom3;
	FlagLetters['r'-'a'] = Admin_Custom4;
	FlagLetters['s'-'a'] = Admin_Custom5;
	FlagLetters['t'-'a'] = Admin_Custom6;
	FlagLetters['z'-'a'] = Admin_Root;
	
	return FlagLetters;
}
