#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#define PLUGIN_VERSION "1.0"

new Handle:g_hCVFragLimit;

new g_iPlayerFragRow[MAXPLAYERS+1] = {0,...};
new Handle:g_hKeepItBurning[MAXPLAYERS+1] = {INVALID_HANDLE,...};

public Plugin:myinfo = 
{
	name = "Kill Ignite",
	author = "Jannik \"Peace-Maker\" Hartung",
	description = "Ignites players after a certain amount of frags",
	version = PLUGIN_VERSION,
	url = "http://www.wcfan.de/"
}

public OnPluginStart()
{
	new Handle:hVersion = CreateConVar("sm_killignite_version", PLUGIN_VERSION, "", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_REPLICATED|FCVAR_DONTRECORD);
	if(hVersion != INVALID_HANDLE)
		SetConVarString(hVersion, PLUGIN_VERSION);
	
	g_hCVFragLimit = CreateConVar("sm_killignite_fraglimit", "10", "After how many frags in a row should we ignite the player?", FCVAR_PLUGIN, true, 0.0);
	
	HookEvent("player_spawn", Event_OnPlayerSpawn);
	HookEvent("player_death", Event_OnPlayerDeath);
	
	AddNormalSoundHook(NormalSoundHook);
	
	for(new i=1;i<=MaxClients;i++)
	{
		if(IsClientInGame(i))
			OnClientPutInServer(i);
	}
}

public OnEntityCreated(entity, const String:classname[])
{
	if(StrEqual(classname, "entityflame", false))
	{
		CreateTimer(0.01, Timer_FireStarted, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
	}
}

public Action:Timer_FireStarted(Handle:timer, any:entityref)
{
	new entity = EntRefToEntIndex(entityref);
	if(entity && IsValidEntity(entity))
	{
		new target = GetEntPropEnt(entity, Prop_Send, "m_hEntAttached");
		
		if(target != -1 && 0 < target <= MaxClients && g_hKeepItBurning[target] != INVALID_HANDLE)
		{
			SDKHook(entity, SDKHook_SetTransmit, Hook_SetTransmit);
		}
	}
	return Plugin_Stop;
}

// Don't show the fire to the burning player himself!
public Action:Hook_SetTransmit(entity, client)
{
	if(GetEntPropEnt(entity, Prop_Send, "m_hEntAttached") == client)
		return Plugin_Handled;
	return Plugin_Continue;
}

public Action:NormalSoundHook(clients[64], &numClients, String:sample[PLATFORM_MAX_PATH], &entity, &channel, &Float:volume, &level, &pitch, &flags)
{
	if(StrContains(sample, "fire/fire_small_loop", false) != -1)
	{
		new target = -1, bool:bStopFire = false;
		decl String:sClassName[64];
		if(entity 
		&& IsValidEntity(entity)
		&& IsValidEdict(entity)
		&& GetEdictClassname(entity, sClassName, sizeof(sClassName))
		&& StrEqual(sClassName, "entityflame", false))
			target = GetEntPropEnt(entity, Prop_Send, "m_hEntAttached");
			
		for(new i=0;i<numClients;i++)
		{
			// This fire sound is played for this player, who's been ignited by this plugin.
			if(clients[i] == target && g_hKeepItBurning[clients[i]] != INVALID_HANDLE)
			{
				bStopFire = true;
				numClients--;
			}
			
			// remove this player from the player list. He shouldn't hear the burning noise all day long :)
			if(bStopFire)
				clients[i] = clients[i+1];
		}
		
		if(bStopFire)
			return Plugin_Changed;
	}
	return Plugin_Continue;
}

public OnClientPutInServer(client)
{
	SDKHook(client, SDKHook_OnTakeDamage, Hook_OnTakeDamage);
}

public OnClientDisconnect(client)
{
	g_iPlayerFragRow[client] = 0;
	
	if(g_hKeepItBurning[client] != INVALID_HANDLE)
	{
		KillTimer(g_hKeepItBurning[client]);
		g_hKeepItBurning[client] = INVALID_HANDLE;
	}
}

// Don't deal fire damage if ignited by plugin
public Action:Hook_OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype, &weapon, Float:damageForce[3], Float:damagePosition[3])
{
	if((damagetype & (DMG_SHOCK|DMG_DIRECT)) && g_hKeepItBurning[victim] != INVALID_HANDLE)
		return Plugin_Handled;
	return Plugin_Continue;
}

public Event_OnPlayerSpawn(Handle:event, const String:bla[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if(IsClientInGame(client))
	{
		if(g_hKeepItBurning[client] != INVALID_HANDLE)
		{
			KillTimer(g_hKeepItBurning[client]);
			g_hKeepItBurning[client] = INVALID_HANDLE;
		}
		
		ExtinguishEntity(client);
		
		if(g_iPlayerFragRow[client] >= GetConVarInt(g_hCVFragLimit))
		{
			IgniteEntity(client, 10.0);
			g_hKeepItBurning[client] = CreateTimer(10.0, Timer_KeepItBurning, GetClientUserId(client), TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
		}
	}
}

public Event_OnPlayerDeath(Handle:event, const String:bla[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	
	// He died. Reset killing spree
	if(client && IsClientInGame(client))
	{
		g_iPlayerFragRow[client] = 0;
		
		if(g_hKeepItBurning[client] != INVALID_HANDLE)
		{
			KillTimer(g_hKeepItBurning[client]);
			g_hKeepItBurning[client] = INVALID_HANDLE;
		}
		
		ExtinguishEntity(client);
	}
	
	// He killed someone!
	if(0 < attacker <= MaxClients && IsClientInGame(attacker))
	{
		g_iPlayerFragRow[attacker]++;
		
		// He got enough frags, ignite now!
		if(g_iPlayerFragRow[attacker] == GetConVarInt(g_hCVFragLimit))
		{
			IgniteEntity(attacker, 10.0);
			g_hKeepItBurning[attacker] = CreateTimer(10.0, Timer_KeepItBurning, GetClientUserId(attacker), TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
			PrintToChat(attacker, "You killed %d players in a row and are now on fire!!!", GetConVarInt(g_hCVFragLimit));
			new String:UserName[MAX_NAME_LENGTH];
			GetClientName(client, UserName, sizeof(UserName));
			PrintToChatAll("\x02 %s \x03 has %d kills in a row without dying and is on fire", UserName, GetConVarInt(g_hCVFragLimit));
		}
	}
}

public Action:Timer_KeepItBurning(Handle:timer, any:userid)
{
	new client = GetClientOfUserId(userid);
	if(!client)
		return Plugin_Stop;
	
	if(IsClientInGame(client))
	{
		ExtinguishEntity(client);
		IgniteEntity(client, 10.0);
		StopSound(client, SNDCHAN_AUTO, "ambient/fire/fire_small_loop2.wav");
	}
	
	return Plugin_Continue;
}