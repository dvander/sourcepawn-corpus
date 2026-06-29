/**
 * =============================================================================
 * SourceMod Communication Plugin Extension
 * Provides fucntionality for controlling communication on the server
 *
 * SourceMod (C)2004-2008 AlliedModders LLC.  All rights reserved.
 * and <eVa>StrontiumDog http://www.theville.org
 * =============================================================================
 *
 * This program is free software; you can redistribute it and/or modify it under
 * the terms of the GNU General Public License, version 3.0, as published by the
 * Free Software Foundation.
 * 1
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
 */


#include <sourcemod>
#include <sdktools>
#undef REQUIRE_PLUGIN
#include <adminmenu>

#define ADMIN_LEVEL ADMFLAG_CHAT

new Handle:hDatabase = INVALID_HANDLE
new Handle:hAdminMenu = INVALID_HANDLE
new Handle:g_Cvar_Alltalk = INVALID_HANDLE
new Handle:g_Cvar_Message = INVALID_HANDLE
new Handle:g_Cvar_Deadtalk = INVALID_HANDLE
new Handle:g_Hostname = INVALID_HANDLE

new String:GameName[64]
new String:g_CommsMessage[256]

new bool:g_Hooked = false

new player_muted[MAXPLAYERS+1]
new player_gagged[MAXPLAYERS+1]
new player_silenced[MAXPLAYERS+1]

new comms_type[MAXPLAYERS+1]
new comms_pt[MAXPLAYERS+1]
new String:comms_reason[MAXPLAYERS+1][64]

#define PLUGIN_VERSION "1.6.000"

public Plugin:myinfo = 
{
	name = "Comms Tools",
	author = "<eVa>Dog/AlliedModders LLC",
	description = "Provides better communications control for admins",
	version = PLUGIN_VERSION,
	url = "http://www.theville.org"
}

public OnPluginStart()
{
	CreateConVar("sm_commstools_version", PLUGIN_VERSION, "Version of Comms Tools", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY)
	g_Cvar_Deadtalk = CreateConVar("sm_deadtalk", "0", "Controls how dead communicate. 0 - Off. 1 - Dead players ignore teams. 2 - Dead players talk to living teammates.", 0, true, 0.0, true, 2.0)
	g_Cvar_Message = CreateConVar("sm_commstools_msg", "See http://www.theville.org/admintools/comms_records.php for details", "Message sent when player is muted/gagged/silenced")
	
	g_Cvar_Alltalk = FindConVar("sv_alltalk")
	g_Hostname = FindConVar("hostname")
	
	GetGameFolderName(GameName, sizeof(GameName))
	
	LoadTranslations("common.phrases")
	
	RegAdminCmd("sm_mute", Command_Mute, ADMFLAG_SLAY, "sm_mute <#userid|name>")
	RegAdminCmd("sm_gag", Command_Gag, ADMFLAG_SLAY, "sm_gag <#userid|name>")
	RegAdminCmd("sm_silence", Command_Silence, ADMFLAG_SLAY, "sm_silence <#userid|name>")
	
	RegAdminCmd("sm_pmute", Command_PermaMute, ADMFLAG_SLAY, "sm_pmute <#userid|name> <reason>")
	RegAdminCmd("sm_pgag", Command_PermaGag, ADMFLAG_SLAY, "sm_pgag <#userid|name> <reason>")
	RegAdminCmd("sm_psilence", Command_PermaSilence, ADMFLAG_SLAY, "sm_psilence <#userid|name> <reason>")
	
	RegConsoleCmd("say", Command_Say)
	RegConsoleCmd("say_team", Command_Say)
	
	RegConsoleCmd("voicemenu", Command_VoiceMenu)
	
	if (StrEqual(GameName, "dod"))
	{
		RegConsoleCmd("voice_areaclear", Command_VoiceMenu)
		RegConsoleCmd("voice_attack", Command_VoiceMenu)
		RegConsoleCmd("voice_backup", Command_VoiceMenu)
		RegConsoleCmd("voice_bazookaspotted", Command_VoiceMenu)
		RegConsoleCmd("voice_ceasefire", Command_VoiceMenu)
		RegConsoleCmd("voice_cover", Command_VoiceMenu)
		RegConsoleCmd("voice_coverflanks", Command_VoiceMenu)
		RegConsoleCmd("voice_displace", Command_VoiceMenu)
		RegConsoleCmd("voice_dropweapons", Command_VoiceMenu)
		RegConsoleCmd("voice_enemyahead", Command_VoiceMenu)
		RegConsoleCmd("voice_enemybehind", Command_VoiceMenu)
		RegConsoleCmd("voice_gogogo", Command_VoiceMenu)
		RegConsoleCmd("voice_grenade", Command_VoiceMenu)
		RegConsoleCmd("voice_fallback", Command_VoiceMenu)
		RegConsoleCmd("voice_fireleft", Command_VoiceMenu)
		RegConsoleCmd("voice_fireinhole", Command_VoiceMenu)
		RegConsoleCmd("voice_fireright", Command_VoiceMenu)
		RegConsoleCmd("voice_hold", Command_VoiceMenu)
		RegConsoleCmd("voice_left", Command_VoiceMenu)
		RegConsoleCmd("voice_medic", Command_VoiceMenu)
		RegConsoleCmd("voice_mgahead", Command_VoiceMenu)
		RegConsoleCmd("voice_moveupmg", Command_VoiceMenu)
		RegConsoleCmd("voice_needammo", Command_VoiceMenu)
		RegConsoleCmd("voice_negative", Command_VoiceMenu)
		RegConsoleCmd("voice_niceshot", Command_VoiceMenu)
		RegConsoleCmd("voice_right", Command_VoiceMenu)
		RegConsoleCmd("voice_sniper", Command_VoiceMenu)
		RegConsoleCmd("voice_sticktogether", Command_VoiceMenu)
		RegConsoleCmd("voice_takeammo", Command_VoiceMenu)
		RegConsoleCmd("voice_thanks", Command_VoiceMenu)
		RegConsoleCmd("voice_usebazooka", Command_VoiceMenu)
		RegConsoleCmd("voice_usegrens", Command_VoiceMenu)
		RegConsoleCmd("voice_usesmoke", Command_VoiceMenu)
		RegConsoleCmd("voice_wegothim", Command_VoiceMenu)
		RegConsoleCmd("voice_wtf", Command_VoiceMenu)
		RegConsoleCmd("voice_yessir", Command_VoiceMenu)
	}
	
	if (StrEqual(GameName, "cstrike"))
	{
		RegConsoleCmd("coverme", Command_VoiceMenu)
		RegConsoleCmd("enemydown", Command_VoiceMenu)
		RegConsoleCmd("enemyspot", Command_VoiceMenu)
		RegConsoleCmd("fallback", Command_VoiceMenu)
		RegConsoleCmd("followme", Command_VoiceMenu)
		RegConsoleCmd("getinpos", Command_VoiceMenu)
		RegConsoleCmd("getout", Command_VoiceMenu)
		RegConsoleCmd("go", Command_VoiceMenu)
		RegConsoleCmd("holdpos", Command_VoiceMenu)
		RegConsoleCmd("inposition", Command_VoiceMenu)
		RegConsoleCmd("needbackup", Command_VoiceMenu)
		RegConsoleCmd("negative", Command_VoiceMenu)
		RegConsoleCmd("regroup", Command_VoiceMenu)
		RegConsoleCmd("report", Command_VoiceMenu)
		RegConsoleCmd("reportingin", Command_VoiceMenu)
		RegConsoleCmd("roger", Command_VoiceMenu)
		RegConsoleCmd("sticktog", Command_VoiceMenu)
		RegConsoleCmd("takepoint", Command_VoiceMenu)
		RegConsoleCmd("takingfire", Command_VoiceMenu)
		RegConsoleCmd("sectorclear", Command_VoiceMenu)
		RegConsoleCmd("stormfront", Command_VoiceMenu)
	}
	
	if (StrEqual(GameName, "insurgency"))
	{
		RegConsoleCmd("say2", Command_Say)
	}
	
	HookConVarChange(g_Cvar_Alltalk, ConVarChange_Alltalk)
	HookConVarChange(g_Cvar_Deadtalk, ConVarChange_Deadtalk)
		
	SQL_TConnect(DBConnect, "commsdb")
	
	new Handle:topmenu
	if (LibraryExists("adminmenu") && ((topmenu = GetAdminTopMenu()) != INVALID_HANDLE))
	{
		OnAdminMenuReady(topmenu)
	}
	
	if (PluginExists("basecomm.smx")) 
	{
        LogError("FATAL: This plugin replaces basecomm. Please remove basecomm and try loading this plugin again");
        SetFailState("This plugin replaces basecomm. Please remove basecomm and try loading this plugin again");
    }
}

public OnMapStart()
{
	GetConVarString(g_Cvar_Message, g_CommsMessage, sizeof(g_CommsMessage))
}

public DBConnect(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if (hndl == INVALID_HANDLE)
	{
		LogError("Database failure: %s", error)
		PrintToServer("CommsTools - Unable to connect to database")
		return
	}
	
	hDatabase = hndl
	PrintToServer("CommsTools - Connected Successfully to Database")
	LogAction(0, 0, "CommsTools - Connected Successfully to Database")
}

// Borrowed from Ryan Mannion's Permamute script
stock bool:PluginExists(const String:plugin_name[]) 
{
    new Handle:iter = GetPluginIterator()
    new Handle:plugin = INVALID_HANDLE
    decl String:name[64]

    while (MorePlugins(iter)) 
	{
		plugin = ReadPlugin(iter)
		GetPluginFilename(plugin, name, sizeof(name))
		if (StrEqual(name, plugin_name)) 
		{
		    CloseHandle(iter)
		    return true
		}
    }

    CloseHandle(iter)
    return false
}

public CheckPlayer(Handle:owner, Handle:hQuery, const String:error[], any:client)
{
	if(hQuery != INVALID_HANDLE)
	{
		if(SQL_GetRowCount(hQuery) > 0)
		{
			PrintToServer("[CommsTools] Client %N found in Database", client)
			LogAction(0, client, "[CommsTools] Client %N found in Database", client)
			while(SQL_FetchRow(hQuery))
			{
				player_gagged[client] = SQL_FetchInt(hQuery, 1)
				player_muted[client] = SQL_FetchInt(hQuery, 2)
			}
		}
		CloseHandle(hQuery)
		
		if (player_muted[client] == 1)
		{
			SetClientListeningFlags(client, VOICE_MUTED)
			LogAction(0, client, "Permanently muted \"%L\"", client)
			PrintToChat(client, "[SM]You have been permanently muted. %s", g_CommsMessage)
		}
		
		if (player_gagged[client] == 1)
		{
			LogAction(0, client, "Permanently gagged \"%L\"", client)
			PrintToChat(client, "[SM]You have been permanently gagged. %s", g_CommsMessage)
		}
			
		if (player_gagged[client] && player_muted[client])
			player_silenced[client] = 1
	}
	else
	{
		LogToGame("[SM] Query failed! %s", error);
	}
}

public OnClientPostAdminCheck(client)
{
	player_muted[client] = 0
	player_gagged[client] = 0
	player_silenced[client] = 0
	
	new String:auth[64], String:query[1024]
	GetClientAuthString(client, auth, sizeof(auth))
	
	Format(query, sizeof(query), "SELECT * FROM commsdb WHERE steam_id REGEXP '^STEAM_[0-9]:%s$' LIMIT 1;", auth[8])
	
	if (!IsFakeClient(client))
		SQL_TQuery(hDatabase, CheckPlayer, query, client, DBPrio_High)
				
}

public ConVarChange_Alltalk(Handle:convar, const String:oldValue[], const String:newValue[])
{
	new mode = GetConVarInt(g_Cvar_Deadtalk)
	new maxClients = GetMaxClients()
	
	for (new i = 1; i <= maxClients; i++)
	{
		if (!IsClientInGame(i))
		{
			continue
		}
		
		if (player_muted[i])
		{
			SetClientListeningFlags(i, VOICE_MUTED)
		}
		else if (GetConVarBool(g_Cvar_Alltalk))
		{
			SetClientListeningFlags(i, VOICE_NORMAL)
		}
		else if (!IsPlayerAlive(i))
		{
			if (mode == 1)
			{
				SetClientListeningFlags(i, VOICE_LISTENALL)
			}
			else if (mode == 2)
			{
				SetClientListeningFlags(i, VOICE_TEAM)
			}
		}
	}
}

public ConVarChange_Deadtalk(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if (GetConVarInt(g_Cvar_Deadtalk))
	{
		HookEvent("player_spawn", Event_PlayerSpawn, EventHookMode_Post)
		HookEvent("player_death", Event_PlayerDeath, EventHookMode_Post)
		g_Hooked = true
	}
	else if (g_Hooked)
	{
		UnhookEvent("player_spawn", Event_PlayerSpawn)
		UnhookEvent("player_death", Event_PlayerDeath)
		g_Hooked = false
	}
}

public Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"))
	
	if (player_muted[client])
	{
		SetClientListeningFlags(client, VOICE_MUTED)
	}
	else
	{
		SetClientListeningFlags(client, VOICE_NORMAL)
	}
}

public Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"))
	
	if (player_muted[client])
	{
		SetClientListeningFlags(client, VOICE_MUTED)
		return
	}
	
	if (GetConVarBool(g_Cvar_Alltalk))
	{
		SetClientListeningFlags(client, VOICE_NORMAL)
		return
	}
	
	new mode = GetConVarInt(g_Cvar_Deadtalk)
	if (mode == 1)
	{
		SetClientListeningFlags(client, VOICE_LISTENALL)
	}
	else if (mode == 2)
	{
		SetClientListeningFlags(client, VOICE_TEAM)
	}
}

public AddToDatabase(Handle:owner, Handle:hQuery, const String:error[], any:client)
{
	if (hQuery == INVALID_HANDLE)
	{
		LogToGame("[CommsTools] There was an error writing to the Database, %s",error)
		PrintToServer("[CommsTools] There was an error writing to the Database")
		
		return
	}
	else
	{
		CloseHandle(hQuery)
	}
	
}

PerformMute(any:client, any:target, String:reason[64])
{
	new String:query[1024], String:authid[64]
	GetClientAuthString(target, authid, sizeof(authid))
	
	new thetime = GetTime()
	new String:hostname[128]
	GetConVarString(g_Hostname, hostname, sizeof(hostname))
	ReplaceString(hostname, sizeof(hostname), "'", "")
	
	if (player_muted[target] == 0)
	{
		player_muted[target] = 1
		
		SetClientListeningFlags(target, VOICE_MUTED)
		LogAction(client, target, "\"%L\" permanently muted \"%L\" Reason: \"%s\"", client, target, reason)
		ShowActivity(client, "permanently muted %N Reason: \"%s\"", target, reason) 
	
		new String:clientname[128], String:targetname[128]
		Format(clientname, sizeof(clientname), "%N", client)
		ReplaceString(clientname, sizeof(clientname), "'", "")
		Format(targetname, sizeof(targetname), "%N", target)
		ReplaceString(targetname, sizeof(targetname), "'", "")
	
		Format(query, sizeof(query), "INSERT INTO commsdb (steam_id, mute, admin, time, playername, game, hostname, reason) VALUES('%s', 1, '%s', '%i', '%s', '%s', '%s', '%s') ON DUPLICATE KEY UPDATE mute=1;", authid, clientname, thetime, targetname, GameName, hostname, reason)
		
		PrintToServer("Query: %s", query)
		SQL_TQuery(hDatabase, AddToDatabase, query, client, DBPrio_Low)
		
		PrintToChat(target, "[SM]You have been permanently muted. %s", g_CommsMessage)
	}
	else
	{
		player_muted[target] = 0
		player_silenced[target] = 0
		
		SetClientListeningFlags(target, VOICE_NORMAL)
		LogAction(client, target, "\"%L\" removed \"%L\" from the Muted database", client, target)
		ShowActivity(client, "permanently unmuted %N", target) 
		
		Format(query, sizeof(query), "INSERT INTO commsdb (steam_id, mute) VALUES('%s', 0) ON DUPLICATE KEY UPDATE mute=0;", authid)
		
		PrintToServer("Query: %s", query)
		SQL_TQuery(hDatabase, AddToDatabase, query, client, DBPrio_High)
		PrintToChat(target, "[SM]You have been unmuted. %s", g_CommsMessage)
	}
}

PerformGag(any:client, any:target, String:reason[64])
{
	new String:query[1024], String:authid[64]
	GetClientAuthString(target, authid, sizeof(authid))
	
	new thetime = GetTime()
	new String:hostname[128]
	GetConVarString(g_Hostname, hostname, sizeof(hostname))
	ReplaceString(hostname, sizeof(hostname), "'", "")
	
	if (player_gagged[target] == 0)
	{
		player_gagged[target] = 1
		
		LogAction(client, target, "\"%L\" permanently gagged \"%L\" Reason: \"%s\"", client, target, reason)
		ShowActivity(client, "permanently gagged %N Reason: \"%s\"", target, reason) 
		
		new String:clientname[128], String:targetname[128]
		Format(clientname, sizeof(clientname), "%N", client)
		ReplaceString(clientname, sizeof(clientname), "'", "")
		Format(targetname, sizeof(targetname), "%N", target)
		ReplaceString(targetname, sizeof(targetname), "'", "")
		
	
		Format(query, sizeof(query), "INSERT INTO commsdb (steam_id, gag, admin, time, playername, game, hostname, reason) VALUES('%s', 1, '%s', '%i', '%s', '%s', '%s', '%s') ON DUPLICATE KEY UPDATE gag=1;", authid, clientname, thetime, targetname, GameName, hostname, reason)
		
		PrintToServer("Query: %s", query)
		SQL_TQuery(hDatabase, AddToDatabase, query, client, DBPrio_High)
		PrintToChat(target, "[SM]You have been permanently gagged. %s", g_CommsMessage)
	}
	else
	{
		player_gagged[target] = 0
		player_silenced[target] = 0
		
		LogAction(client, target, "\"%L\" removed \"%L\" from the Gagged database", client, target)
		ShowActivity(client, "permanently ungagged %N", target) 
		
		Format(query, sizeof(query), "INSERT INTO commsdb (steam_id, gag) VALUES('%s', 0) ON DUPLICATE KEY UPDATE gag=0;", authid)
		
		PrintToServer("Query: %s", query)
		SQL_TQuery(hDatabase, AddToDatabase, query, client, DBPrio_High)
		PrintToChat(target, "[SM]You have been ungagged. %s", g_CommsMessage)
	}
}

PerformSilence(any:client, any:target, String:reason[64])
{
	new String:query[1024], String:authid[64]
	GetClientAuthString(target, authid, sizeof(authid))
	
	new thetime = GetTime()
	
	new String:hostname[128]
	GetConVarString(g_Hostname, hostname, sizeof(hostname))
	ReplaceString(hostname, sizeof(hostname), "'", "")
	
	if (player_silenced[target] == 0)
	{
		player_silenced[target] = 1
		player_gagged[target] = 1
		player_muted[target] = 1
		
		SetClientListeningFlags(target, VOICE_MUTED)
		LogAction(client, target, "\"%L\" permanently silenced \"%L\" Reason: \"%s\"", client, target, reason)
		ShowActivity(client, "permanently silenced %N Reason: \"%s\"", target, reason) 
		
		new String:clientname[128], String:targetname[128]
		Format(clientname, sizeof(clientname), "%N", client)
		ReplaceString(clientname, sizeof(clientname), "'", "")
		Format(targetname, sizeof(targetname), "%N", target)
		ReplaceString(targetname, sizeof(targetname), "'", "")
		
		ReplaceString(hostname, sizeof(hostname), "'", "\'")
	
		Format(query, sizeof(query), "INSERT INTO commsdb (steam_id, mute, gag, admin, time, playername, game, hostname, reason) VALUES('%s', 1, 1, '%s', '%i', '%s', '%s', '%s', '%s') ON DUPLICATE KEY UPDATE gag=1,mute=1;", authid, clientname, thetime, targetname, GameName, hostname, reason)
		
		PrintToServer("Query: %s", query)
		SQL_TQuery(hDatabase, AddToDatabase, query, client, DBPrio_High)
		PrintToChat(target, "[SM]You have been permanently silenced. %s", g_CommsMessage)

	}
	else
	{
		player_silenced[target] = 0
		player_gagged[target] = 0
		player_muted[target] = 0
		
		SetClientListeningFlags(target, VOICE_NORMAL)
		LogAction(client, target, "\"%L\" removed \"%L\" from the Silenced database", client, target)
		ShowActivity(client, "permanently unsilenced %N", target) 
		
		Format(query, sizeof(query), "INSERT INTO commsdb (steam_id, mute, gag) VALUES('%s', 0, 0) ON DUPLICATE KEY UPDATE mute=0, gag=0;", authid)
		
		PrintToServer("Query: %s", query)
		SQL_TQuery(hDatabase, AddToDatabase, query, client, DBPrio_High)
		PrintToChat(target, "[SM]You have been unsilenced. %s", g_CommsMessage)
	}
}

PerformTempMute(any:client, any:target)
{
	if (player_muted[target] == 0)
	{
		player_muted[target] = 1
		
		SetClientListeningFlags(target, VOICE_MUTED)
		LogAction(client, target, "\"%L\" muted \"%L\"", client, target)
		ShowActivity(client, " muted %N", target) 
		PrintToChat(target, "[SM]You have been muted.")
	}
	else
	{
		player_muted[target] = 0
		player_silenced[target] = 0
		
		if (GetConVarInt(g_Cvar_Deadtalk) == 1 && !IsPlayerAlive(target))
		{
			SetClientListeningFlags(target, VOICE_LISTENALL)
		}
		else if (GetConVarInt(g_Cvar_Deadtalk) == 2 && !IsPlayerAlive(target))
		{
			SetClientListeningFlags(target, VOICE_TEAM)
		}
		else
		{
			SetClientListeningFlags(target, VOICE_NORMAL)
		}
		LogAction(client, target, "\"%L\" unmuted \"%L\"", client, target)
		ShowActivity(client, " unmuted %N", target) 
		PrintToChat(target, "[SM]You have been unmuted.")
	}
}

PerformTempGag(any:client, any:target)
{
	if (player_gagged[target] == 0)
	{
		player_gagged[target] = 1
		
		LogAction(client, target, "\"%L\" gagged \"%L\"", client, target)
		ShowActivity(client, " gagged %N", target) 
		PrintToChat(target, "[SM]You have been gagged. ")
	}
	else
	{
		player_gagged[target] = 0
		player_silenced[target] = 0
		
		LogAction(client, target, "\"%L\" ungagged \"%L\"", client, target)
		ShowActivity(client, " ungagged %N", target) 
		PrintToChat(target, "[SM]You have been ungagged. ")
	}
}

PerformTempSilence(any:client, any:target)
{
	if (player_silenced[target] == 0)
	{
		player_silenced[target] = 1
		player_gagged[target] = 1
		player_muted[target] = 1
		
		SetClientListeningFlags(target, VOICE_MUTED)
		LogAction(client, target, "\"%L\" silenced \"%L\"", client, target)
		ShowActivity(client, " silenced %N", target) 
		PrintToChat(target, "[SM]You have been silenced. ")
	}
	else
	{
		player_silenced[target] = 0
		player_gagged[target] = 0
		player_muted[target] = 0
		
		if (GetConVarInt(g_Cvar_Deadtalk) == 1 && !IsPlayerAlive(target))
		{
			SetClientListeningFlags(target, VOICE_LISTENALL);
		}
		else if (GetConVarInt(g_Cvar_Deadtalk) == 2 && !IsPlayerAlive(target))
		{
			SetClientListeningFlags(target, VOICE_TEAM);
		}
		else
		{
			SetClientListeningFlags(target, VOICE_NORMAL);
		}	
		LogAction(client, target, "\"%L\" unsilenced \"%L\"", client, target)
		ShowActivity(client, " unsilenced %N", target) 
		PrintToChat(target, "[SM]You have been unsilenced. ")
	}
}

public Action:Command_Say(client, args)
{
	if (client)
	{
		if (player_gagged[client])
		{
			return Plugin_Handled	
		}
	}
	return Plugin_Continue
}

public Action:Command_VoiceMenu(client, args)
{
	if (client)
	{
		if (player_gagged[client])
		{
			return Plugin_Handled	
		}
	}
	return Plugin_Continue
}

public OnLibraryRemoved(const String:name[])
{
	if (StrEqual(name, "adminmenu")) 
	{
		hAdminMenu = INVALID_HANDLE
	}
}

public OnAdminMenuReady(Handle:topmenu)
{
	if (topmenu == hAdminMenu)
	{
		return;
	}
	
	hAdminMenu = topmenu
		
	new TopMenuObject:player_commands = FindTopMenuCategory(hAdminMenu, "comms")

	if (player_commands == INVALID_TOPMENUOBJECT)
	{
		player_commands = AddToTopMenu(
		hAdminMenu,		// Menu
		"comms",		// Name
		TopMenuObject_Category,	// Type
		Handle_Category,	// Callback
		INVALID_TOPMENUOBJECT	// Parent
		)
	}
			
	AddToTopMenu(hAdminMenu,
		"sm_mute",
		TopMenuObject_Item,
		AdminMenu_Mute,
		player_commands,
		"sm_mute",
		ADMIN_LEVEL)
		
	AddToTopMenu(hAdminMenu,
		"sm_gag",
		TopMenuObject_Item,
		AdminMenu_Gag,
		player_commands,
		"sm_gag",
		ADMIN_LEVEL)
		
	AddToTopMenu(hAdminMenu,
		"sm_silence",
		TopMenuObject_Item,
		AdminMenu_Silence,
		player_commands,
		"sm_silence",
		ADMIN_LEVEL)
}

public Handle_Category( Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id, param, String:buffer[], maxlength )
{
	switch( action )
	{
		case TopMenuAction_DisplayTitle:
			Format( buffer, maxlength, "Communications:" )
		case TopMenuAction_DisplayOption:
			Format( buffer, maxlength, "Comms Commands" )
	}
}

public AdminMenu_Mute(Handle:topmenu, 
			TopMenuAction:action,
			TopMenuObject:object_id,
			param,
			String:buffer[],
			maxlength)
{
	if (action == TopMenuAction_DisplayOption)
	{
		Format(buffer, maxlength, "Mute/Unmute Player")
	}
	else if (action == TopMenuAction_SelectOption)
	{
		comms_type[param] = 1
		DisplayTypeMenu(param)
	}
}

public AdminMenu_Gag(Handle:topmenu, 
			TopMenuAction:action,
			TopMenuObject:object_id,
			param,
			String:buffer[],
			maxlength)
{
	if (action == TopMenuAction_DisplayOption)
	{
		Format(buffer, maxlength, "Gag/Ungag Player")
	}
	else if (action == TopMenuAction_SelectOption)
	{
		comms_type[param] = 2
		DisplayTypeMenu(param)
	}
}

public AdminMenu_Silence(Handle:topmenu, 
			TopMenuAction:action,
			TopMenuObject:object_id,
			param,
			String:buffer[],
			maxlength)
{
	if (action == TopMenuAction_DisplayOption)
	{
		Format(buffer, maxlength, "Silence/Unsilence Player")
	}
	else if (action == TopMenuAction_SelectOption)
	{
		comms_type[param] = 3
		DisplayTypeMenu(param)
	}
}

DisplayTypeMenu(client)
{
	new Handle:menu = CreateMenu(MenuHandler_Type)
	
	decl String:title[100]
	Format(title, sizeof(title), "Length:")
	SetMenuTitle(menu, title)
	SetMenuExitBackButton(menu, true)
	
	AddMenuItem(menu, "1", "Permanent")
	AddMenuItem(menu, "2", "Temporary")

	DisplayMenu(menu, client, MENU_TIME_FOREVER)
}

public MenuHandler_Type(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_End)
	{
		CloseHandle(menu)
	}
	else if (action == MenuAction_Cancel)
	{
		if (param2 == MenuCancel_ExitBack && hAdminMenu != INVALID_HANDLE)
		{
			DisplayTopMenu(hAdminMenu, param1, TopMenuPosition_LastCategory);
		}
	}
	else if (action == MenuAction_Select)
	{	
		decl String:info[32]

		GetMenuItem(menu, param2, info, sizeof(info))
		comms_pt[param1] = StringToInt(info)
		
		DisplayReasonMenu(param1)
	}
}

DisplayReasonMenu(client)
{
	new Handle:menu = CreateMenu(MenuHandler_Reason)
	
	decl String:title[100]
	Format(title, sizeof(title), "Reason:")
	SetMenuTitle(menu, title)
	SetMenuExitBackButton(menu, true)
	
	AddMenuItem(menu, "Inappropriate Language", "Inappropriate Language")
	AddMenuItem(menu, "Mic Spamming", "Mic Spamming")
	AddMenuItem(menu, "Keyboard spamming", "Keyboard spamming")
	AddMenuItem(menu, "Avoiding filters", "Avoiding filters")
	AddMenuItem(menu, "Disrespect to players", "Disrespect to players")
	AddMenuItem(menu, "Poor communication skills", "Poor communication skills")

	DisplayMenu(menu, client, MENU_TIME_FOREVER)
}

public MenuHandler_Reason(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_End)
	{
		CloseHandle(menu)
	}
	else if (action == MenuAction_Cancel)
	{
		if (param2 == MenuCancel_ExitBack && hAdminMenu != INVALID_HANDLE)
		{
			DisplayTopMenu(hAdminMenu, param1, TopMenuPosition_LastCategory);
		}
	}
	else if (action == MenuAction_Select)
	{	
		decl String:info[64];

		GetMenuItem(menu, param2, info, sizeof(info))
		
		Format(comms_reason[param1], 64, "%s", info)
		
		DisplayPlayersMenu(param1)
	}
}

DisplayPlayersMenu(client)
{
	new Handle:menu = CreateMenu(MenuHandler_Players)
	
	decl String:title[100]
	Format(title, sizeof(title), "Choose Player:")
	SetMenuTitle(menu, title)
	SetMenuExitBackButton(menu, true)
	
	AddTargetsToMenu2(menu, client, COMMAND_FILTER_NO_BOTS|COMMAND_FILTER_CONNECTED)
	
	DisplayMenu(menu, client, MENU_TIME_FOREVER)
}

public MenuHandler_Players(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_End)
	{
		CloseHandle(menu)
	}
	else if (action == MenuAction_Cancel)
	{
		if (param2 == MenuCancel_ExitBack && hAdminMenu != INVALID_HANDLE)
		{
			DisplayTopMenu(hAdminMenu, param1, TopMenuPosition_LastCategory);
		}
	}
	else if (action == MenuAction_Select)
	{
		decl String:info[32]
		new userid, target
		
		GetMenuItem(menu, param2, info, sizeof(info))
		userid = StringToInt(info)

		if ((target = GetClientOfUserId(userid)) == 0)
		{
			PrintToChat(param1, "[SM] %s", "Player no longer available")
		}
		else if (!CanUserTarget(param1, target))
		{
			PrintToChat(param1, "[SM] %s", "Unable to target")
		}
		else
		{					
			switch (comms_type[param1])
			{
				case 1:
				{
					if (comms_pt[param1] == 2)
						PerformTempMute(param1, target)
					else
						PerformMute(param1, target, comms_reason[param1])
				}
				
				case 2:
				{
					if (comms_pt[param1] == 2)
						PerformTempGag(param1, target)
					else
						PerformGag(param1, target, comms_reason[param1])
				}
				
				case 3:
				{
					if (comms_pt[param1] == 2)
						PerformTempSilence(param1, target)
					else
						PerformSilence(param1, target, comms_reason[param1])
				}
			}
		}
		
		/* Re-draw the menu if they're still valid */
		if (IsClientInGame(param1) && !IsClientInKickQueue(param1))
		{
			DisplayPlayersMenu(param1)
		}
	}
}

public Action:Command_PermaMute(client, args)
{
	decl String:target[65], String:reason[64]
	decl String:target_name[MAX_TARGET_LENGTH]
	decl target_list[MAXPLAYERS]
	decl target_count
	decl bool:tn_is_ml
	
	if (args < 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_pmute <#userid|name> <reason>");
		return Plugin_Handled
	}
	
	GetCmdArg(1, target, sizeof(target))
	GetCmdArg(2, reason, sizeof(reason))
	
	if ((target_count = ProcessTargetString(
			target,
			client,
			target_list,
			MAXPLAYERS,
			0,
			target_name,
			sizeof(target_name),
			tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count)
		return Plugin_Handled
	}
		
	for (new i = 0; i < target_count; i++)
	{
		if (IsClientInGame(target_list[i]))
		{
			PerformMute(client, target_list[i], reason)
		}
	}
	return Plugin_Handled
}

public Action:Command_PermaGag(client, args)
{
	decl String:target[65], String:reason[64]
	decl String:target_name[MAX_TARGET_LENGTH]
	decl target_list[MAXPLAYERS]
	decl target_count
	decl bool:tn_is_ml
	
	if (args < 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_pgag <#userid|name> <reason>");
		return Plugin_Handled
	}
	
	GetCmdArg(1, target, sizeof(target))
	GetCmdArg(2, reason, sizeof(reason))
	
	if ((target_count = ProcessTargetString(
			target,
			client,
			target_list,
			MAXPLAYERS,
			0,
			target_name,
			sizeof(target_name),
			tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count)
		return Plugin_Handled
	}
		
	for (new i = 0; i < target_count; i++)
	{
		if (IsClientInGame(target_list[i]))
		{
			PerformGag(client, target_list[i], reason)
		}
	}
	return Plugin_Handled
}

public Action:Command_PermaSilence(client, args)
{
	decl String:target[65], String:reason[64]
	decl String:target_name[MAX_TARGET_LENGTH]
	decl target_list[MAXPLAYERS]
	decl target_count
	decl bool:tn_is_ml
	
	if (args < 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_psilence <#userid|name> <reason>");
		return Plugin_Handled
	}
	
	GetCmdArg(1, target, sizeof(target))
	GetCmdArg(2, reason, sizeof(reason))
	
	if ((target_count = ProcessTargetString(
			target,
			client,
			target_list,
			MAXPLAYERS,
			0,
			target_name,
			sizeof(target_name),
			tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count)
		return Plugin_Handled
	}
		
	for (new i = 0; i < target_count; i++)
	{
		if (IsClientInGame(target_list[i]))
		{
			PerformSilence(client, target_list[i], reason)
		}
	}
	return Plugin_Handled
}

public Action:Command_Mute(client, args)
{
	decl String:target[65]
	decl String:target_name[MAX_TARGET_LENGTH]
	decl target_list[MAXPLAYERS]
	decl target_count
	decl bool:tn_is_ml
	
	if (args < 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_mute <#userid|name>");
		return Plugin_Handled
	}
		
	GetCmdArg(1, target, sizeof(target))
	
	if ((target_count = ProcessTargetString(
			target,
			client,
			target_list,
			MAXPLAYERS,
			0,
			target_name,
			sizeof(target_name),
			tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count)
		return Plugin_Handled
	}
		
	for (new i = 0; i < target_count; i++)
	{
		if (IsClientInGame(target_list[i]))
		{			
			PerformTempMute(client, target_list[i])
		}
	}
	return Plugin_Handled
}

public Action:Command_Gag(client, args)
{
	decl String:target[65]
	decl String:target_name[MAX_TARGET_LENGTH]
	decl target_list[MAXPLAYERS]
	decl target_count
	decl bool:tn_is_ml
	
	if (args < 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_gag <#userid|name>");
		return Plugin_Handled
	}
	
	GetCmdArg(1, target, sizeof(target))
	
	if ((target_count = ProcessTargetString(
			target,
			client,
			target_list,
			MAXPLAYERS,
			0,
			target_name,
			sizeof(target_name),
			tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count)
		return Plugin_Handled
	}
		
	for (new i = 0; i < target_count; i++)
	{
		if (IsClientInGame(target_list[i]))
		{
			PerformTempGag(client, target_list[i])
		}
	}
	return Plugin_Handled
}

public Action:Command_Silence(client, args)
{
	decl String:target[65]
	decl String:target_name[MAX_TARGET_LENGTH]
	decl target_list[MAXPLAYERS]
	decl target_count
	decl bool:tn_is_ml
	
	if (args < 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_silence <#userid|name>");
		return Plugin_Handled
	}
	
	GetCmdArg(1, target, sizeof(target))
	
	if ((target_count = ProcessTargetString(
			target,
			client,
			target_list,
			MAXPLAYERS,
			0,
			target_name,
			sizeof(target_name),
			tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count)
		return Plugin_Handled
	}
		
	for (new i = 0; i < target_count; i++)
	{
		if (IsClientInGame(target_list[i]))
		{
			PerformTempSilence(client, target_list[i])
		}
	}
	return Plugin_Handled
}