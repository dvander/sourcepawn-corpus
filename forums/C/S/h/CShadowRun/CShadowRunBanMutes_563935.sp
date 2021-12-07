public Plugin:myinfo = 
{
	name = "CShadowRunBanMutes",
	author = "CShadowRun",
	description = "Ban and Mutes control",
	version = "1.0",
	url = "http://www.CShadowRun.com"
};

#define MAX_PLAYERS 256

#include <sourcemod>
#include <sdktools>

new mutetime[MAX_PLAYERS+1]
new muteref[MAX_PLAYERS+1]
new bool:recordexists[MAX_PLAYERS+1]
new String:mutereason[MAX_PLAYERS+1][1024]
new Handle:mutetimers[MAX_PLAYERS+1]
new Handle:SQL

public OnPluginStart()
{
	RegConsoleCmd("say", Command_Say);
	RegConsoleCmd("say2", Command_Say);
	RegConsoleCmd("say_team", Command_Say);
	HookEvent("player_spawn", Event_PlayerSpawn, EventHookMode_Post);
	RegAdminCmd("csr_mute",Command_Mute,ADMFLAG_KICK,"Mutes player by STEAMID")
	RegAdminCmd("csr_unmute",Command_UnMute,ADMFLAG_KICK,"UnMutes player by STEAMID")
	RegAdminCmd("csr_ban",Command_Ban,ADMFLAG_BAN,"Bans player by STEAMID")
	RegAdminCmd("csr_unban",Command_UnBan,ADMFLAG_BAN,"Unbans player by STEAMID")
	CreateConVar("csr_banmutes_version", "1.0", "CShadowRunBanMutes Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY)
 	SQL_TConnect(OnConnect, "cshadowrunrpg");
}

public OnConnect(Handle:owner, Handle:hndl, const String:error[], any:client)
{
	if (hndl == INVALID_HANDLE)
	{
		PrintToServer("[CShadowRunBanMutes] Database Error: %s", error);
	}
	SQL = hndl
}

public DoNothing(Handle:owner, Handle:hndl, const String:error[], any:client)
{
	if (hndl == INVALID_HANDLE)
	{
		PrintToServer("[CShadowRunBanMutes] Database Error: %s", error);
	}
}

public GetInfo(Handle:owner, Handle:hndl, const String:error[], any:pack)
{
	if (hndl == INVALID_HANDLE)
	{
		PrintToServer("[CShadowRunBanMutes] Database Error: %s", error);
		return
	}
	new client
	new String:id[25];
	ResetPack(Handle:pack)
	client = ReadPackCell(Handle:pack)
	ReadPackString(pack, id, sizeof(id))
		

	if (!SQL_FetchRow(hndl))
	{
		new String:query[1024]
		FormatEx(query,1024,"INSERT INTO banmutes( id, bantime, banref, banreason, mutetime, muteref, mutereason ) VALUES ( '%s', 0, 0, '0', '0', '0', '0' )",id[0]);
		SQL_TQuery(SQL,DoNothing,query);
		return;
	}
	else
	{
		if (IsClientConnected(client) == true)
		{
			new String:checkid[25];
			GetClientAuthString(client, checkid, sizeof(checkid));
			if (StrEqual(id[0], checkid[0]))
			{
				new currenttime = GetTime()
				new bantime = SQL_FetchInt(hndl, 1);
				new banref = SQL_FetchInt(hndl, 2);
				new String:banreason[1024]
				SQL_FetchString(hndl, 3, banreason, sizeof(banreason));
				mutetime[client] = SQL_FetchInt(hndl, 4);
				muteref[client] = SQL_FetchInt(hndl, 5);
				SQL_FetchString(hndl, 6, mutereason[client], 1024);
				if (currenttime < bantime || bantime == -1)
				{
					new seconds = -1
					if (bantime != -1)
					{
						seconds = bantime - currenttime
					}
					new String:friendlytime[1024]
					FriendlyTime(seconds,friendlytime)
					KickClient(client,"You are banned. Reason: %s Banref: %d Bantime:%s",banreason[0],banref,friendlytime[0]);
				}
				if (mutetime[client] != -1)
				{
					if (currenttime < mutetime[client])
					{
						new Handle:packz
						mutetimers[client] = CreateDataTimer(float(mutetime[client] - muteref[client]),UnMuteTimer,packz);
						WritePackString(packz, id[0])
					}
					else
					{
						mutetime[client] = 0
					}
				}
			}
			recordexists[client] = true;
		}
	}
}

public OnClientAuthorized(client, const String:auth[])
{
	if(auth[0] != 'B')
	{
		mutetime[client] = 0
		mutetimers[client] = 0
		new String:query[128]
		FormatEx(query,128,"SELECT * FROM banmutes WHERE id = '%s'",auth[0]);
		new Handle:pack = CreateDataPack()
		WritePackCell(pack,client)
		WritePackString(pack,auth[0])
		SQL_TQuery(SQL,GetInfo,query,pack);
	}
}

public Action:Command_Say(client, args)
{
	if (mutetime[client] != 0)
	{
		new String:text[192];
		GetCmdArgString(text, sizeof(text));
 		new startidx = 0;
		if (text[0] == '"')
		{
			startidx = 1;
			new len = strlen(text);
			if (text[len-1] == '"')
			{
				text[len-1] = '\0';
			}
		}
		if (text[startidx] == '/')
		{
			return Plugin_Handled;
		}			
		new time = -1
		if (mutetime[client] != -1)
		{
			time = GetTime()
			time = mutetime[client] - time
		}
		new String:friendlytime[1024]
		FriendlyTime(time,friendlytime);
		PrintToChat(client,"You are muted.");
		PrintToChat(client,"Reason: %s",mutereason[client][0]);
		PrintToChat(client,"MuteTime:%s MuteRef: %d",friendlytime[0],muteref[client]);
		return Plugin_Handled;
	}
	return Plugin_Continue;
}


public Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (mutetime[client] != 0)
		SetClientListeningFlags(client, VOICE_MUTED);
	else
		SetClientListeningFlags(client, VOICE_NORMAL);
}

public Action:UnMuteTimer(Handle:timer, Handle:pack)
{
	decl String:str[128]
	ResetPack(pack)
	ReadPackString(pack, str, sizeof(str))
	new client = IdToClient(str); 
	if (client != -1)
	{
		if (mutetimers[client] != 0)
		{
			UnMuteClient(client)
		}
	}
}

public UnMuteClient(client)
{
	PrintHintText(client,"You are now unmuted. Please refrain from breaking the rules in the future.");
	new String:name[64]
	GetClientName(client, name, 64);
	PrintToChatAll("%s is now unmuted.",name);
	SetClientListeningFlags(client, VOICE_NORMAL);
	mutetime[client] = 0
	mutetimers[client] = 0
}

public Action:Command_UnBan(clientz,args)
{
	new String:full[1024]
	GetCmdArgString(full, sizeof(full))
	new startidx = 0
	if (full[0] == '"')
	{
		startidx = 1;
		new len = strlen(full);
		if (full[len-1] == '"')
		{
			full[len-1] = '\0';
		}
	}
	new String:query[1024]
	FormatEx(query,1024,"UPDATE banmutes SET bantime = '0', banref = '0', banreason = '0' WHERE id = '%s'",full[startidx]);
	SQL_TQuery(SQL,DoNothing,query);	
}

public Action:Command_Ban(clientz,args)
{
	new bantime
	new banref
	new String:full[1024]
	GetCmdArgString(full, sizeof(full))
	new len = strlen(full);
	full[len-1] = '\0';
	new String:arg[2][25]
	ExplodeString(full[0]," ",arg,2,25)
	new banreasonl = strlen(arg[0][0]) + strlen(arg[1][0]) + 2
	new client = IdToClient(arg[1][0])
	if (client != -1)
	{
		banref = GetTime()
		new String:friendlytime[1024]
		if (!StrEqual(arg[0][1],"-1",false))
		{
			bantime = banref + (StringToInt(arg[0][1],10) * 60)
			FriendlyTime((bantime - banref),friendlytime)
		}
		else
		{
			bantime = -1
			FriendlyTime(bantime,friendlytime)
		}
		new String:name[32]
		GetClientName(client, name, 32);
		PrintToChatAll("%s has been banned. Reason: %s. Time: %s",name[0],full[banreasonl],friendlytime[0]);
		KickClient(client,"You are banned. Reason: %s Banref: %d Bantime:%s",full[banreasonl],banref,friendlytime[0]);
	}
	new String:query[1024]
	new localbanref = GetTime()
	new localbantime
	if (StringToInt(arg[0][1],10) != -1)
	{
		localbantime = localbanref + (StringToInt(arg[0][1],10) * 60)
	}
	else
	{
		localbantime = -1
	}
	FormatEx(query,1024,"UPDATE banmutes SET bantime = %d, banref = %d, banreason = '%s' WHERE id = '%s'",localbantime,localbanref,full[banreasonl],arg[1][0]);
	SQL_TQuery(SQL,DoNothing,query);
	
}

public Action:Command_UnMute(clientz,args)
{
	new String:full[1024]
	GetCmdArgString(full, sizeof(full))
	new startidx = 0;
	if (full[0] == '"')
	{
		startidx = 1;
		new len = strlen(full);
		if (full[len-1] == '"')
		{
			full[len-1] = '\0';
		}
	}
	new client = IdToClient(full[startidx])
	if (client != -1)
	{
		mutetimers[client] = 0
		UnMuteClient(client);
	}
	new String:query[1024]
	FormatEx(query,1024,"UPDATE banmutes SET mutetime = '0', muteref = '0', mutereason = '0' WHERE id = '%s'",full[startidx]);
	SQL_TQuery(SQL,DoNothing,query);	
}

public Action:Command_Mute(clientz,args)
{
	new String:full[1024]
	GetCmdArgString(full, sizeof(full))
	new len = strlen(full);
	full[len-1] = '\0';
	new String:arg[2][25]
	ExplodeString(full[0]," ",arg,2,25)
	new banreason = strlen(arg[0][0]) + strlen(arg[1][0]) + 2
	new client = IdToClient(arg[1][0])
	if (client != -1)
	{
		muteref[client] = GetTime()
		new String:friendlytime[1024]
		if (!StrEqual(arg[0][1],"-1",false))
		{
			mutetime[client] = muteref[client] + (StringToInt(arg[0][1],10) * 60)
			new Handle:pack
			mutetimers[client] = CreateDataTimer(float(mutetime[client] - muteref[client]),UnMuteTimer,pack);
			WritePackString(pack, arg[1])
			FriendlyTime((mutetime[client] - muteref[client]),friendlytime)
		}
		else
		{
			mutetime[client] = -1
			FriendlyTime(mutetime[client],friendlytime)
		}
		SetClientListeningFlags(client, VOICE_MUTED);
		FormatEx(mutereason[client],1024,"%s",full[banreason])
		PrintHintText(client,"You are muted. Reason: %s\nMuteref: %d\nMutetime:%s",mutereason[client][0],muteref[client],friendlytime[0]);
		new String:name[32]
		GetClientName(client, name, 32);
		PrintToChatAll("%s has been muted. Reason: %s. Time:%s.",name[0],mutereason[client],friendlytime[0]);
	}
	new String:query[1024]
	new tempmuteref = GetTime()
	new tempmutetime
	if (StringToInt(arg[0][1],10) != -1)
	{
		tempmutetime = tempmuteref + (StringToInt(arg[0][1],10) * 60)
	}
	else
	{
		tempmutetime = -1
	}
	FormatEx(query,1024,"UPDATE banmutes SET mutetime = %d, muteref = %d, mutereason = '%s' WHERE id = '%s'",tempmutetime,tempmuteref,full[banreason],arg[1][0]);
	SQL_TQuery(SQL,DoNothing,query);
	
}


public FriendlyTime(seconds,String:friendlytime[])
{
	if (seconds != -1)
	{
		new weeks = seconds / 604800
		seconds -= ((seconds / 604800) * 604800)
		new days = seconds / 86400
		seconds -= ((seconds / 86400) * 86400)
		new hours = seconds / 3600
		seconds -= ((seconds / 3600) * 3600)
		new minutes = seconds / 60
		seconds -= ((seconds / 60) * 60)
		seconds -= ((seconds / 60) * 60)
		FormatEx(friendlytime,1024,"");
		if (weeks > 0)
		{
			FormatEx(friendlytime,1024,"%s %dwks",friendlytime[0],weeks);
		}
		if (days > 0)
		{
			FormatEx(friendlytime,1024,"%s %ddays",friendlytime[0],days);
		}
		if (hours > 0)
		{
			FormatEx(friendlytime,1024,"%s %dhrs",friendlytime[0],hours);
		}
		if (minutes > 0)
		{
			FormatEx(friendlytime,1024,"%s %dmins",friendlytime[0],minutes);
		}
		if (seconds > 0)
		{
			FormatEx(friendlytime,1024,"%s %dsecs",friendlytime[0],seconds);
		}
	}
	else
	{
		FormatEx(friendlytime,1024," Permanant");
	}
}

public IdToClient(String:id[])
{
	new String:playerid[25]
	for (new i = 1; i <= GetMaxClients(); i++)
	{
		if (IsClientInGame(i) == true)
		{
			GetClientAuthString(i, playerid, sizeof(playerid))
			if (StrEqual(playerid[0],id[0]))
			{
				return i
			}
		}
	}
	return -1
}