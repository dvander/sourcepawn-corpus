#include <sourcemod>
#include <sdktools>
#include <halflife>
#include <cstrike>

new DB;

public Plugin:myinfo = 
{
	name = "JB Round CT Ban",
	author = "GryTrean",
	description = "CTbans for an set amount of time.",
	version = "1.0",
	url = "zawapps.com - Coming Soon!"
}

public OnPluginStart()
{
	new String:error[128] //Array do trzymania errora w razie potrzeby
	DB = SQL_Connect("ctbans", true, error, sizeof(error)) //Laczenie z baza danych
	if(DB == INVALID_HANDLE) //Sprawdza czy laczenie sie powiodlo - JESLI NIE:
	{
		PrintToServer("[CT Ban] Nie moge polaczyc z MySQL: %s", error)
		CloseHandle(DB)
	}
	else //Jesli polaczenie sie powiodlo
	{
		PrintToServer("[CT Ban] Correctly connected with MySQL") //Wyslij log do konsoli
		new quer = SQL_FastQuery(DB, "CREATE TABLE IF NOT EXISTS ctbans (name TEXT, steamid TEXT, time INTEGER, reason TEXT, admin TEXT);"); //Jesli nie ma tabeli, stworz
		if(quer == false) //Jesli tworzenie tabeli sie nie powiodlo
		{
			new String:error[256];
			SQL_GetError(quer, error, sizeof(error));
			PrintToServer("[CT Ban] Problem z tworzeniem tabeli: %s", error)
		}
	}
	
	RegAdminCmd("sm_ctban", ctbanhandle, ADMFLAG_SLAY, "Bans the player for X amount of rounds from the CT team"); //Komenda na banowanie
	RegAdminCmd("sm_ctunban", ctunbanhandle, ADMFLAG_SLAY, "Unbans the player from the CT team"); //Komenda na unbanowywanie
	RegConsoleCmd("sm_ctstatus", ctstatushandle, "Checks if the player has a ban, if yes, gives the reason");
	AddCommandListener(Command_CheckJoin, "jointeam");
	HookEvent("round_start", OnRoundStart);
}

public Action:ctstatushandle(client, args)
{
	new String:steamid[64];
	GetClientAuthString(client, steamid, sizeof(steamid));
	
	new String:query[256];
	Format(query, sizeof(query), "SELECT steamid, reason, time FROM ctbans WHERE steamid='%s'", steamid) //Sprawdza czy gracz jest juz zbanowany
	new Handle:hQuery = SQL_Query(DB, query); //Wykonuje zapytanie
	
	if(hQuery == INVALID_HANDLE)
	{
		new String:error[256];
		SQL_GetError(DB, error, sizeof(error));
		PrintToServer("[CT BAN] Error while looking for CTBAN Reason: %s", error);
	}
	else
	{
		if(SQL_FetchRow(hQuery))
		{
			new String:powod[256];
			SQL_FetchString(hQuery, 1, powod, sizeof(powod));
			
			new time = SQL_FetchInt(hQuery, 2);
			PrintToChat(client, "\x01 \x06[CT BAN] \x01\x03You are \x01\x07BANNED \x01\x03from the CT team for %i rounds. Reason: \x01\x07%s", time, powod);
		}
		else
		{
			PrintToChat(client, "\x01 \x06[CT BAN] \x01\x03You are not banned from the CT Team!");
		}
	}
}

public Action:ctbanhandle(client, args)
{
	if(args < 3) //Sprawdza czy wszystkie argumenty zostaly podane
	{
		ReplyToCommand(client, "[SM] Correct usage: sm_ctban <player> <rounds> <reason>");
		return Plugin_Handled;
	}
	
	new String:arg1[32]; //Gracz ktory ma zostac zbanowany
	new String:arg2[32]; //Ilosc rund
	new String:arg3[128]; //Powod
	
	GetCmdArg(1, arg1, sizeof(arg1));
	GetCmdArg(2, arg2, sizeof(arg2));
	GetCmdArg(3, arg3, sizeof(arg3));
	
	
	new time = StringToInt(arg2); //Zamienia ilosc rund na INT
	if(time == 0) //Sprawdza, czy ilosc rund to cyfra
	{
		ReplyToCommand(client, "[SM] Correct usage: sm_ctban <player> <rounds> <reason>");
		return Plugin_Handled;
	}
	
	
	new target = FindTarget(client, arg1, true); //Szuka gracza do zbanowania
	if(target == -1) //Jesli nie znalazlo gracza
	{
		ReplyToCommand(client, "[SM] ERROR; Cant target the player");
		return Plugin_Handled;
	}
	
	new String:adminnick[64]; //Nick banujacej osoby
	new String:nick[64]; //Nick zbanowanej osoby
	new String:steamid[128]; //SteamID zbanowanej  osoby
	GetClientName(client, adminnick, sizeof(adminnick));
	GetClientName(target, nick, sizeof(nick));
	GetClientAuthString(target, steamid, sizeof(steamid));
	
	new String:query[256];
	Format(query, sizeof(query), "SELECT steamid FROM ctbans WHERE steamid='%s'", steamid) //Sprawdza czy gracz jest juz zbanowany
	new Handle:hQuery = SQL_Query(DB, query); //Wykonuje zapytanie
	
	if(hQuery != INVALID_HANDLE) //Sprawdza czy zapytanie sie powiodlo
	{
		if(SQL_FetchRow(hQuery) == true) //Sprawdza czy zapytanie jest prawdziwe -- Czy gracz ma juz bana; Jesli tak
		{
			ReplyToCommand(client, "[CT BAN] This player is already banned!")
			return Plugin_Handled;
		}
		else //Jesli gracz nie ma jeszcze bana, zbanuj
		{
			Format(query, sizeof(query), "INSERT INTO ctbans(name, steamid, time, reason, admin) VALUES('%s', '%s', '%i', '%s', '%s')", nick, steamid, time, arg3, adminnick);
			hQuery = SQL_Query(DB, query); //Zbanuj gracza
			if(hQuery == INVALID_HANDLE) //Jesli wstawianie informacji do tabeli sie nie powiodlo
			{
				ReplyToCommand(client, "[CT BAN] Can't ban this player..."); //Wyslij komunikat
				new String:error[256];
				SQL_GetError(DB, error, sizeof(error));
				PrintToServer("[CT BAN] Problem while CTBanning player: %s", error);
			}
			else
			{
				PrintToChatAll("\x01 \x06[CT BAN] \x01\x3Player \x01\x05%s \x01\x03was CTBanned by \x01\x07%s \x01\x03for \x01\x05%i \x01\x03rounds!", nick, adminnick, time)
				PrintToChatAll("\x01 \x5[REASON] \x01\x03%s", arg3)
				if(GetClientTeam(target) == 3)
				{
					ChangeClientTeam(target, 2);
					ForcePlayerSuicide(target);
				}
			}
		}
	}
}

public Action:ctunbanhandle(client, args)
{
	if(args < 1)
	{
		ReplyToCommand(client, "[SM] Correct usage: sm_ctunban <client>");
		return Plugin_Handled;
	}	
	
	new String:arg1[32];
	GetCmdArg(1, arg1, sizeof(arg1));
	
	new target = FindTarget(client, arg1, true); //Szuka gracza do zbanowania
	if(target == -1) //Jesli nie znalazlo gracza
	{
		ReplyToCommand(client, "[SM] ERROR; Cant find player");
		return Plugin_Handled;
	}
	
	new String:steamid[64];
	GetClientAuthString(target, steamid, sizeof(steamid));
	
	new String:targetnick[256];
	new String:adminnick[256];
	GetClientName(target, targetnick, sizeof(targetnick));
	GetClientName(client, adminnick, sizeof(adminnick));
	
	new String:query[256];
	Format(query, sizeof(query), "DELETE FROM ctbans WHERE steamid='%s'", steamid);
	
	new Handle:hQuery = SQL_Query(DB, query);
	if(hQuery == INVALID_HANDLE)
	{
		new String:error[256];
		SQL_GetError(DB, error, sizeof(error));
		ReplyToCommand(client, "[SM] Cant unban the player: %s", error);
		PrintToServer("[CT BAN] Problem while unbanning player: %s", error);
	}
	else
	{
		ReplyToCommand(client, "[CT BAN] The player was UNBANNED from the CT Team");
		PrintToChatAll("\x01 \x06[CT BAN] \x01\x3Player \x01\x05%s \x01\x03was unbanned from the CT Team by \x01\x07%s", targetnick, adminnick)
	}
}

public Action:Command_CheckJoin(client, const String:command[], args)
{
	decl String:teamString[3];
	GetCmdArg(1, teamString, sizeof(teamString));
	new team = StringToInt(teamString);
	
	if(team == 3)
	{
		new String:steamid[32];
		GetClientAuthString(client, steamid, sizeof(steamid));
		
		new String:query[256];
		Format(query, sizeof(query), "SELECT steamid, time FROM ctbans WHERE steamid='%s'", steamid);
		PrintToServer("[CT BAN] Checking if player is banned...")
		
		new Handle:hQuery = SQL_Query(DB, query);
		if(hQuery == INVALID_HANDLE)
		{
			new String:error[256];
			SQL_GetError(DB, error, sizeof(error));
			PrintToServer("[CT BAN] Problem while reading from the database: %s", error);
		}
		else
		{
			if(SQL_FetchRow(hQuery))
			{
				new banTime = SQL_FetchInt(hQuery, 1);
				PrintToChat(client, "\x01 \x06[CT BAN] \x01\x03You are \x01\x07BANNED \x01\x03from the CT Team for \x01\x07%i \x01\x03rounds!", banTime);
				return Plugin_Stop;
			}
		}
	}
}

public OnRoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	for(new i = 1; i < 33; i++)
	{
		if(IsClientConnected(i))
		{
			new String:steamid[64];
			GetClientAuthString(i, steamid, sizeof(steamid));
			
			new String:query[256];
			Format(query, sizeof(query), "SELECT steamid, time FROM ctbans WHERE steamid='%s'", steamid);
			
			new Handle:hQuery = SQL_Query(DB, query);
			if(hQuery == INVALID_HANDLE)
			{
				new String:error[256];
				SQL_GetError(DB, error, sizeof(error));
				PrintToServer("[CT BAN] Error while reading from the databse: %s", error);
			}
			else
			{
				if(SQL_FetchRow(hQuery))
				{
					new banTime = SQL_FetchInt(hQuery, 1);
					banTime = banTime - 1;
					if(banTime == 0)
					{
						new String:targetnick[128];
						GetClientName(i, targetnick, sizeof(targetnick));
						Format(query, sizeof(query), "DELETE FROM ctbans WHERE steamid='%s'", steamid);
						hQuery = SQL_Query(DB, query);
						if(hQuery == INVALID_HANDLE)
						{
							new String:error[256];
							SQL_GetError(DB, error, sizeof(error));
							PrintToServer("[CT BAN] Error while unbanning player: %s", error);
						}
						else
						{
							PrintToChatAll("\x01 \x06[CT BAN] \x01\x3Player \x01\x05%s \x01\x03was unbanned from the CT Team!", targetnick)
						}
					}
					else
					{
						if(GetClientTeam(i) == 3)
						{
							ForcePlayerSuicide(i);
							ChangeClientTeam(i, 2);
							CS_RespawnPlayer(i);
							PrintToChat(i, "\x01 \x06[CT BAN] \x01\x03You are \x01\x05CTBANNED \x01\x03for \x01\x05%i \x01\x03more rounds!", banTime);
						}
						Format(query, sizeof(query), "UPDATE ctbans SET time='%i' WHERE steamid='%s'", banTime, steamid);
						hQuery = SQL_Query(DB, query);
						if(hQuery == INVALID_HANDLE)
						{
							new String:error[256];
							SQL_GetError(DB, error, sizeof(error));
							PrintToServer("[CT BAN] Problem while changing bantime: %s", error);
						}
						else
						{
							PrintToServer("[CT BAN] Changed player bantime...")
						}
					}
				}
			}
		}
	}
}
