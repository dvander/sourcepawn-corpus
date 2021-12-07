#pragma semicolon 1
#include <sourcemod>

//#define DEBUG 1

#define PLUGIN_VERSION "3.3"

public Plugin:myinfo = 
{
	name = "RoyaL^ Dynamic Slots",
	author = "DoPe^",
	description = "Server Slots depends on players",
	version = PLUGIN_VERSION,
	url = "http://www.ClanRoyaL.dk"
};


new Handle:cfg_royal_max_slots;
new Handle:cfg_royal_min_slots;
new Handle:cfg_royal_start_slots;
new Handle:cfg_royal_add_slots;
new Handle:cfg_royal_announce;
new Handle:cfg_royal_announce_time;
new Handle:g_hSlotTimer;
new Handle:g_hSlotTimer2;
//new Handle:g_hCheckTimer;
//new Handle:cfg_royal_check_time;

new String:cfg_s_royal_max_slots[20];
new String:cfg_s_royal_min_slots[20];
new String:cfg_s_royal_start_slots[20];
new String:cfg_s_royal_add_slots[20];
new String:cfg_s_royal_announce[20];
//new String:cfg_s_royal_check_time[20];

new Handle:g_hMaxPlayers;

//new bool:checktime;
new bool:announce;
new bool:mapchange = false;


public OnPluginStart()
{
	CreateConVar("sm_royal_slots_version", PLUGIN_VERSION, "RoyaL^ Dynamic Slots", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	
	cfg_royal_max_slots = CreateConVar("sm_royal_max_slots", "32", "Set the Max Server slots", FCVAR_PLUGIN, true, 1.00, true, 64.00);
	cfg_royal_min_slots = CreateConVar("sm_royal_min_slots", "12", "Set the Minimum Server slots", FCVAR_PLUGIN, true, 1.00, true, 64.00);
	cfg_royal_start_slots = CreateConVar("sm_royal_start_slots", "32", "Set the Start Server slots", FCVAR_PLUGIN, true, 1.00, true, 64.00);
	cfg_royal_add_slots = CreateConVar("sm_royal_add_slots", "2", "Slots to add depending on players", FCVAR_PLUGIN, true, 0.00, true, 32.00);
	cfg_royal_announce = CreateConVar("sm_royal_slot_announce", "1", "Annouce current players/slots in chat", FCVAR_PLUGIN, true, 0.00, true, 1.00);
	cfg_royal_announce_time = CreateConVar("sm_royal_slot_announce_time", "5", "How long in minutes between announces", FCVAR_PLUGIN, true, 1.00, true, 240.00);
	//cfg_royal_check_time = CreateConVar("sm_royal_slot_check_time", "2", "How often to check the slots in seconds If set to 0, check time is disabled");
	RegConsoleCmd("sm_slots", Command_slots, "Displays Current players/slots on the server");
	
	AutoExecConfig(true, "sm_royal_dynamic_slots");
	
	HookConVarChange(cfg_royal_max_slots, MaxSlotsChanged);
	HookConVarChange(cfg_royal_min_slots, MinSlotsChanged);
	HookConVarChange(cfg_royal_start_slots, StartSlotsChanged);
	HookConVarChange(cfg_royal_add_slots, AddSlotsChanged);
	HookConVarChange(cfg_royal_announce, AnnounceChanged);
	HookConVarChange(cfg_royal_announce_time, ConVarChange_Interval);
	//HookConVarChange(cfg_royal_check_time , CheckTimeChanged);

	HookEvent("player_connect", ConnectEvent);

	g_hMaxPlayers = FindConVar("sv_visiblemaxplayers");
	
	new clientCount = GetPlayerCount();
	new currentslots = GetConVarInt(cfg_royal_add_slots) + clientCount;
	new minslots = GetConVarInt(cfg_royal_min_slots);
	new maxslots = GetConVarInt(cfg_royal_max_slots);
	new startslots = GetConVarInt(cfg_royal_start_slots);
	if (clientCount == 0)
	{
		SetConVarInt(g_hMaxPlayers, startslots);
		#if defined DEBUG
		PrintToServer("[DEBUG][OnPluginStart] Slots = %d [Start Slots]",startslots);
		PrintToChatAll("[DEBUG][OnPluginStart] Slots = %d [Start Slots]",startslots);
		#endif
	}
	else if (currentslots > minslots && currentslots < maxslots)
	{
		SetConVarInt(g_hMaxPlayers, currentslots);
		#if defined DEBUG
		PrintToServer("[DEBUG][OnPluginStart] Slots = %d [Current Slots]", currentslots);
		PrintToChatAll("[DEBUG][OnPluginStart] Slots = %d [Current Slots]", currentslots);
		#endif
	}
	else if (currentslots <= minslots)
	{
		SetConVarInt(g_hMaxPlayers, minslots);
		#if defined DEBUG
		PrintToServer("[DEBUG][OnPluginStart] Slots = %d [Min Slots]", minslots);
		PrintToChatAll("[DEBUG][OnPluginStart] Slots = %d [Min Slots]", minslots);
		#endif
	}
	else if (currentslots >= maxslots)
	{
		SetConVarInt(g_hMaxPlayers, maxslots);
		#if defined DEBUG
		PrintToServer("[DEBUG][OnPluginStart] Slots = %d [Max Slots]", maxslots);
		PrintToChatAll("[DEBUG][OnPluginStart] Slots = %d [Max Slots]", maxslots);
		#endif
	}
}


public OnConfigsExecuted()
{

	GetConVarString(cfg_royal_max_slots, cfg_s_royal_max_slots, sizeof(cfg_s_royal_max_slots));
	GetConVarString(cfg_royal_min_slots, cfg_s_royal_min_slots, sizeof(cfg_s_royal_min_slots));
	GetConVarString(cfg_royal_start_slots, cfg_s_royal_start_slots, sizeof(cfg_s_royal_start_slots));
	GetConVarString(cfg_royal_add_slots, cfg_s_royal_add_slots, sizeof(cfg_s_royal_add_slots));
	GetConVarString(cfg_royal_announce, cfg_s_royal_announce, sizeof(cfg_s_royal_announce));
	//GetConVarString(cfg_royal_check_time, cfg_s_royal_check_time, sizeof(cfg_s_royal_check_time));
	GetCVars();

	new clientCount = GetPlayerCount();
	new startslots = GetConVarInt(cfg_royal_start_slots);

	if (clientCount == 0)
	{
		SetConVarInt(g_hMaxPlayers, startslots);
		#if defined DEBUG
		PrintToServer("[DEBUG][OnConfigsExecuted] Slots = %d [Start Slots]",startslots);
		PrintToChatAll("[DEBUG][OnConfigsExecuted] Slots = %d [Start Slots]",startslots);
		#endif
	}

}


// Get new values of cvars if they has being changed

public GetCVars()
{

	announce = GetConVarBool(cfg_royal_announce);

	if(announce)
	{
		EnableAnnounce();
		#if defined DEBUG
		PrintToServer("[DEBUG]Announce Enabled");
		PrintToChatAll("[DEBUG]Announce Enabled");
		#endif
	}
	else
	{
		DisableAnnounce();
		#if defined DEBUG
		PrintToServer("[DEBUG]Announce Disabled");
		PrintToChatAll("[DEBUG]Announce Disabled");
		#endif
	}
	/*
	checktime = GetConVarBool(cfg_royal_check_time);

	if(checktime)
	{
		EnableCheckTime();
		#if defined DEBUG
		PrintToServer("[DEBUG]Check Timer is over 1");
		PrintToChatAll("[DEBUG]Check Timer is over 1");
		#endif
	}
	else
	{
		DisableCheckTime();
		#if defined DEBUG
		PrintToServer("[DEBUG]Check Timer is 0");
		PrintToChatAll("[DEBUG]Check Timer is 0");
		#endif
	}
	*/
}

EnableAnnounce()
{
	new advert = GetConVarInt(cfg_royal_announce);
	new clientCount = GetPlayerCount();
	new currentslots = GetConVarInt(cfg_royal_add_slots) + clientCount;
	new maxslots = GetConVarInt(cfg_royal_max_slots);

	if (advert == 1)
	{
		if(g_hSlotTimer2 != INVALID_HANDLE)
		{
			KillTimer(g_hSlotTimer2);
			g_hSlotTimer2 = INVALID_HANDLE;
			g_hSlotTimer = CreateTimer(GetConVarInt(cfg_royal_announce_time) * 60.0, Timer_Announce, _, TIMER_REPEAT);
		}
		else
		{
			g_hSlotTimer = CreateTimer(GetConVarInt(cfg_royal_announce_time) * 60.0, Timer_Announce, _, TIMER_REPEAT);
		}
	}
	else if (currentslots >= maxslots && advert == 1)
	{
		if(g_hSlotTimer != INVALID_HANDLE)
		{
			KillTimer(g_hSlotTimer);
			g_hSlotTimer = INVALID_HANDLE;
			g_hSlotTimer2 = CreateTimer(GetConVarInt(cfg_royal_announce_time) * 60.0, Timer_Announce2, _, TIMER_REPEAT);
		}
		else
		{
			g_hSlotTimer2 = CreateTimer(GetConVarInt(cfg_royal_announce_time) * 60.0, Timer_Announce2, _, TIMER_REPEAT);
		}
	}
}

DisableAnnounce()
{
	new advert = GetConVarInt(cfg_royal_announce);
	if (advert == 0)
	{
		if(g_hSlotTimer != INVALID_HANDLE)
		{
			KillTimer(g_hSlotTimer);
			g_hSlotTimer = INVALID_HANDLE;
		}
		else if(g_hSlotTimer2 != INVALID_HANDLE)
		{
			KillTimer(g_hSlotTimer2);
			g_hSlotTimer2 = INVALID_HANDLE;
		}
	}
}
/*
EnableCheckTime()
{
	if(g_hCheckTimer == INVALID_HANDLE)
	{
		g_hCheckTimer = CreateTimer(GetConVarInt(cfg_royal_check_time) * 1.0, Timer_CheckSlots, _, TIMER_REPEAT);
	}
}

DisableCheckTime()
{
	if(g_hCheckTimer != INVALID_HANDLE)
	{
		KillTimer(g_hCheckTimer);
		g_hCheckTimer = INVALID_HANDLE;
	}
}
*/

public OnClientPutInServer(client)
{
	new clientCount = GetPlayerCount();
	new currentslots = GetConVarInt(cfg_royal_add_slots) + clientCount;
	new minslots = GetConVarInt(cfg_royal_min_slots);
	new maxslots = GetConVarInt(cfg_royal_max_slots);
	if(mapchange)
	{
		if (currentslots > minslots && currentslots < maxslots)
		{
			SetConVarInt(g_hMaxPlayers, currentslots);
			#if defined DEBUG
			PrintToServer("[DEBUG][OnClientPutInServer] Slots = %d [Current Slots]", currentslots);
			PrintToChatAll("[DEBUG][OnClientPutInServer] Slots = %d [Current Slots]", currentslots);
			#endif
		}
		else if (currentslots <= minslots)
		{
			SetConVarInt(g_hMaxPlayers, minslots);
			#if defined DEBUG
			PrintToServer("[DEBUG][OnClientPutInServer] Slots = %d [Min Slots]", minslots);
			PrintToChatAll("[DEBUG][OnClientPutInServer] Slots = %d [Min Slots]", minslots);
			#endif
		}
		else if (currentslots >= maxslots)
		{
			SetConVarInt(g_hMaxPlayers, maxslots);
			#if defined DEBUG
			PrintToChatAll("[DEBUG][OnClientPutInServer] Slots = %d [Max Slots]", maxslots);
			PrintToServer("[DEBUG][OnClientPutInServer] Slots = %d [Max Slots]", maxslots);
			#endif
		}
		#if defined DEBUG
		PrintToServer("[DEBUG][OnClientPutInServer] Server Has Changed Map", maxslots);
		#endif
		mapchange = false;
	}
	else
	{
		#if defined DEBUG
		PrintToServer("[DEBUG][OnClientPutInServer] Server Has Not Changed Map", maxslots);
		#endif
	}
}


public MaxSlotsChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	strcopy(cfg_s_royal_max_slots, sizeof(cfg_s_royal_max_slots), newValue);
}


public MinSlotsChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	strcopy(cfg_s_royal_min_slots, sizeof(cfg_s_royal_min_slots), newValue);
}


public StartSlotsChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	strcopy(cfg_s_royal_start_slots, sizeof(cfg_s_royal_start_slots), newValue);
}


public AddSlotsChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	strcopy(cfg_s_royal_add_slots, sizeof(cfg_s_royal_add_slots), newValue);
}


public AnnounceChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	strcopy(cfg_s_royal_announce, sizeof(cfg_s_royal_announce), newValue);
	GetCVars();
}


public ConVarChange_Interval(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if(g_hSlotTimer)
		KillTimer(g_hSlotTimer);
	
	g_hSlotTimer = CreateTimer(GetConVarInt(cfg_royal_announce_time) * 60.0, Timer_Announce, _, TIMER_REPEAT);
	
	if(g_hSlotTimer2)
		KillTimer(g_hSlotTimer2);
		
	g_hSlotTimer2 = CreateTimer(GetConVarInt(cfg_royal_announce_time) * 60.0, Timer_Announce, _, TIMER_REPEAT);
}

/*
public CheckTimeChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	strcopy(cfg_s_royal_check_time, sizeof(cfg_s_royal_check_time), newValue);
	GetCVars();
}
*/

public Action:ConnectEvent(Handle:event , const String:name[] , bool:dontBroadcast)
{
	new clientCount = GetPlayerCount();
	new currentslots = GetConVarInt(cfg_royal_add_slots) + clientCount + 1;
	new minslots = GetConVarInt(cfg_royal_min_slots); 
	new maxslots = GetConVarInt(cfg_royal_max_slots);
	if (currentslots > minslots && currentslots < maxslots)
	{
		SetConVarInt(g_hMaxPlayers, currentslots);
		#if defined DEBUG
		PrintToServer("[DEBUG][ConnectEvent] Slots = %d [Current Slots]", currentslots);
		PrintToChatAll("[DEBUG][ConnectEvent] Slots = %d [Current Slots]", currentslots);
		#endif
	}
	else if (currentslots <= minslots)
	{
		SetConVarInt(g_hMaxPlayers, minslots);
		#if defined DEBUG
		PrintToServer("[DEBUG][ConnectEvent] Slots = %d [Min Slots]", minslots);
		PrintToChatAll("[DEBUG][ConnectEvent] Slots = %d [Min Slots]", minslots);
		#endif
	}
	else if (currentslots >= maxslots)
	{
		SetConVarInt(g_hMaxPlayers, maxslots);
		#if defined DEBUG
		PrintToServer("[DEBUG][ConnectEvent] Slots = %d [Max Slots]", maxslots);
		PrintToChatAll("[DEBUG][ConnectEvent] Slots = %d [Max Slots]", maxslots);
		#endif
	}
}

public OnClientDisconnect_Post(client)
{
	new clientCount = GetPlayerCount();
	new currentslots = GetConVarInt(cfg_royal_add_slots) + clientCount;
	new minslots = GetConVarInt(cfg_royal_min_slots);
	new maxslots = GetConVarInt(cfg_royal_max_slots);
	new startslots = GetConVarInt(cfg_royal_start_slots);
	if (clientCount == 0)
	{
		SetConVarInt(g_hMaxPlayers, startslots);
		#if defined DEBUG
		PrintToServer("[DEBUG][ClientDisconnect] Slots = %d [Start Slots]",startslots);
		PrintToChatAll("[DEBUG][ClientDisconnect] Slots = %d [Start Slots]",startslots);
		#endif
	}
	else if (currentslots > minslots && currentslots < maxslots)
	{
		SetConVarInt(g_hMaxPlayers, currentslots);
		#if defined DEBUG
		PrintToServer("[DEBUG][ClientDisconnect] Slots = %d [Current Slots]", currentslots);
		PrintToChatAll("[DEBUG][ClientDisconnect] Slots = %d [Current Slots]", currentslots);
		#endif
	}
	else if (currentslots <= minslots)
	{
		SetConVarInt(g_hMaxPlayers, minslots);
		#if defined DEBUG
		PrintToServer("[DEBUG][ClientDisconnect] Slots = %d [Min Slots]", minslots);
		PrintToChatAll("[DEBUG][ClientDisconnect] Slots = %d [Min Slots]", minslots);
		#endif
	}
	else if (currentslots >= maxslots)
	{
		SetConVarInt(g_hMaxPlayers, maxslots);
		#if defined DEBUG
		PrintToServer("[DEBUG][ClientDisconnect] Slots = %d [Max Slots]", maxslots);
		PrintToChatAll("[DEBUG][ClientDisconnect] Slots = %d [Max Slots]", maxslots);
		#endif
	}
}

public Action:Timer_Announce(Handle:timer)
{
	new clientCount = GetPlayerCount();
	new maxplayers = GetConVarInt(g_hMaxPlayers);
	PrintToChatAll("\x01\x04[\x03RoyaL^ Dynamic Slots\x04] \x04Current players: (\x03%d\x04/\x03%d\x04) server slots depends on players!", clientCount, maxplayers);
	
	return Plugin_Continue;
}

public Action:Timer_Announce2(Handle:timer)
{
	new clientCount = GetPlayerCount();
	new maxplayers = GetConVarInt(g_hMaxPlayers);
	PrintToChatAll("\x01\x04[\x03RoyaL^ Dynamic Slots\x04] \x04The Server is Now running on Max Slots - Current players: (\x03%d\x04/\x03%d\x04)", clientCount, maxplayers);
	
	return Plugin_Continue;
}

/*
public Action:Timer_CheckSlots(Handle:timer)
{
	new clientCount = GetPlayerCount();
	new currentslots = GetConVarInt(cfg_royal_add_slots) + clientCount +1;
	new minslots = GetConVarInt(cfg_royal_min_slots);
	new maxslots = GetConVarInt(cfg_royal_max_slots);
	new startslots = GetConVarInt(cfg_royal_start_slots);
	if (clientCount == 0)
	{
		SetConVarInt(g_hMaxPlayers, startslots);
		#if defined DEBUG
		PrintToServer("[DEBUG][Timer_CheckSlots] Slots = %d [Start Slots]",startslots);
		PrintToChatAll("[DEBUG][Timer_CheckSlots] Slots = %d [Start Slots]",startslots);
		#endif
	}
	else if (currentslots > minslots)
	{
		SetConVarInt(g_hMaxPlayers, currentslots);
		#if defined DEBUG
		PrintToServer("[DEBUG] Slots[Timer_CheckSlots] = %d [Current Slots]", currentslots);
		PrintToChatAll("[DEBUG] Slots[Timer_CheckSlots] = %d [Current Slots]", currentslots);
		#endif
	}
	else if (currentslots <= minslots)
	{
		SetConVarInt(g_hMaxPlayers, minslots);
		#if defined DEBUG
		PrintToServer("[DEBUG] Slots[Timer_CheckSlots] = %d [Min Slots]", minslots);
		PrintToChatAll("[DEBUG] Slots[Timer_CheckSlots] = %d [Min Slots]", minslots);
		#endif
	}
	else if (currentslots >= maxslots)
	{
		SetConVarInt(g_hMaxPlayers, maxslots);
		#if defined DEBUG
		PrintToServer("[DEBUG] Slots[Timer_CheckSlots] = %d [Max Slots]", maxslots);
		PrintToChatAll("[DEBUG] Slots[Timer_CheckSlots] = %d [Max Slots]", maxslots);
		#endif
	}
	
	return Plugin_Continue;
}
*/

public Action:Command_slots(client, args)
{
	new clientCount = GetPlayerCount();
	new currentslots = GetConVarInt(cfg_royal_add_slots) + clientCount;
	new maxslots = GetConVarInt(cfg_royal_max_slots);
	new maxplayers = GetConVarInt(g_hMaxPlayers);
	if(IsValidClient(client))
	{
		if (currentslots >= maxslots)
		{
			PrintToChat(client, "\x01\x04[\x03RoyaL^ Dynamic Slots\x04] \x04The Server is running on Max Slots - Current players: (\x03%d\x04/\x03%d\x04)", clientCount, maxslots);
		}
		else
		{
			PrintToChat(client, "\x01\x04[\x03RoyaL^ Dynamic Slots\x04] \x04Current players: (\x03%d\x04/\x03%d\x04) server slots depends on players!", clientCount, maxplayers);
		}
	}
	else
	{
		if (currentslots >= maxslots)
		{
			PrintToServer("The Server is running on Max Slots - Current players: (%d/%d)", clientCount, maxslots);
		}
		else
		{
			PrintToServer("Current players: (%d/%d)", clientCount, maxplayers);
		}
	}

	return Plugin_Handled;
}

public IsValidClient(client)
{
	if ( !( 1 <= client <= MaxClients ) || !IsClientInGame(client) || IsFakeClient(client) )
		return false;

	return true;
}

GetPlayerCount()
{
	new players;
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i))
			players++;
	}
	return players;
} 

public OnPluginEnd()
{
	new maxslots = GetConVarInt(cfg_royal_max_slots);
	SetConVarInt(g_hMaxPlayers, maxslots);
}

public OnMapEnd()
{
	mapchange = true;
}