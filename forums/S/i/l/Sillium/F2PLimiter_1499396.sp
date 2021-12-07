#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#define AUTOLOAD_EXTENSIONS
#define REQUIRE_EXTENSIONS
#include <steamtools>

#define PLUGIN_VERSION "0.0.1"

public Plugin:myinfo = {
	name        = "[TF2] F2PLimiter",
	author      = "AlliedModders LLC & Sillium",
	description = "Limit the Numer of F2P-Players on the server",
	version     = PLUGIN_VERSION,
	url         = "FILL ME"
};

new g_PremiumCount = 0;
new bool:g_isPremium[MAXPLAYERS+1];

/* Handles to convars used by plugin */
new Handle:sm_reserved_premium_slots;
new Handle:sm_hide_premium_slots;
new Handle:sv_visiblemaxplayers;
new Handle:sm_reserve_premium_type;
new Handle:sm_reserve_maxpremium;
new Handle:sm_reserve_premium_kicktype;

enum KickType
{
	Kick_HighestPing,
	Kick_HighestTime,
	Kick_Random,	
};

public OnPluginStart()
{
   LoadTranslations("F2PLimiter.phrases");

   sm_reserved_premium_slots = CreateConVar("sm_reserved_premium_slots", "0", "Number of premium player slots", 0, true, 0.0);
   sm_hide_premium_slots = CreateConVar("sm_hide_premium_slots", "0", "If set to 1, premium slots will hidden (subtracted from the max slot count)", 0, true, 0.0, true, 1.0);
   sv_visiblemaxplayers = FindConVar("sv_visiblemaxplayers");
   sm_reserve_premium_type = CreateConVar("sm_reserve_premium_type", "0", "Method of reserving slots", 0, true, 0.0, true, 2.0);
   sm_reserve_maxpremium = CreateConVar("sm_reserve_maxpremium", "1", "Maximum amount of premium players to let in the server with reserve type 2", 0, true, 0.0);
   sm_reserve_premium_kicktype = CreateConVar("sm_reserve_premium_kicktype", "0", "How to select a client to kick (if appropriate)", 0, true, 0.0, true, 2.0);

   HookConVarChange(sm_reserved_premium_slots, SlotsChanged);
   HookConVarChange(sm_hide_premium_slots, SlotsChanged);
   AutoExecConfig(true, "F2PLimiter");
}


public OnPluginEnd()
{
	/* 	If the plugin has been unloaded, reset visiblemaxplayers. In the case of the server shutting down this effect will not be visible */
	SetConVarInt(sv_visiblemaxplayers, MaxClients);
}

public OnMapStart()
{
	if (GetConVarBool(sm_hide_premium_slots))
	{		
		SetVisibleMaxSlots(GetClientCount(false), MaxClients - GetConVarInt(sm_reserved_premium_slots));
	}
}

public OnConfigsExecuted()
{
	if (GetConVarBool(sm_hide_premium_slots))
	{
		SetVisibleMaxSlots(GetClientCount(false), MaxClients - GetConVarInt(sm_reserved_premium_slots));
	}	
}

public Action:OnTimedKick(Handle:timer, any:client)
{	
	if (!client || !IsClientInGame(client))
	{
		return Plugin_Handled;
	}
	
	KickClient(client, "%T", "Slot reserved", client);
	
	if (GetConVarBool(sm_hide_premium_slots))
	{				
		SetVisibleMaxSlots(GetClientCount(false), MaxClients - GetConVarInt(sm_reserved_premium_slots));
	}
	
	return Plugin_Handled;
}

public OnClientAuthorized(client, const String:auth[])
{
	new reserved = GetConVarInt(sm_reserved_premium_slots);

	if (reserved > 0)
	{
		new clients = GetClientCount(false);
		new limit = MaxClients - reserved;
		
		new type = GetConVarInt(sm_reserve_premium_type);
		
		if (type == 0)
		{
			if (clients <= limit || IsFakeClient(client) || !isClientF2P(client))
			{
				if (GetConVarBool(sm_hide_premium_slots))
				{
					SetVisibleMaxSlots(clients, limit);
				}
				
				return;
			}
			
			/* Kick player because there are no F2P slots left */
			CreateTimer(0.1, OnTimedKick, client);
		}
		else if (type == 1)
		{	
			if (clients > limit)
			{
				if (!isClientF2P(client))
				{
					new target = SelectKickClient();
						
					if (target)
					{
						/* Kick F2P player to free the premium slot again */
						CreateTimer(0.1, OnTimedKick, target);
					}
				}
				else
				{				
					/* Kick player because there are no F2P slots left */
					CreateTimer(0.1, OnTimedKick, client);
				}
			}
		}
		else if (type == 2)
		{
			if (!isClientF2P(client))
			{
				g_PremiumCount++;
				g_isPremium[client] = true;
			}
			
			if (clients > limit && g_PremiumCount < GetConVarInt(sm_reserve_maxpremium))
			{
				/* Server is full, premium slots aren't and client doesn't have premium slots access */
				
				if (g_isPremium[client])
				{
					new target = SelectKickClient();
						
					if (target)
					{
						/* Kick F2P player to free the premium slot again */
						CreateTimer(0.1, OnTimedKick, target);
					}
				}
				else
				{				
					/* Kick player because there are no F2P slots left */
					CreateTimer(0.1, OnTimedKick, client);
				}		
			}
		}
	}
}

public OnClientDisconnect_Post(client)
{
	if (GetConVarBool(sm_hide_premium_slots))
	{		
		SetVisibleMaxSlots(GetClientCount(false), MaxClients - GetConVarInt(sm_reserved_premium_slots));
	}
	
	if (g_isPremium[client])
	{
		g_PremiumCount--;
		g_isPremium[client] = false;	
	}
}

public SlotsChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	/* premium slots or hidden slots have been disabled - reset sv_visiblemaxplayers */
	if (StringToInt(newValue) == 0)
	{
		SetConVarInt(sv_visiblemaxplayers, MaxClients);
	}
}

SetVisibleMaxSlots(clients, limit)
{
	new num = clients;
	
	if (clients == MaxClients)
	{
		num = MaxClients;
	} else if (clients < limit) {
		num = limit;
	}
	
	SetConVarInt(sv_visiblemaxplayers, num);
}

bool:isClientF2P(client)
{
   if (Steam_CheckClientSubscription(client, 0) && !Steam_CheckClientDLC(client, 459))
	{
      return true;
   }
   else
   {
      return false;
   }
}

SelectKickClient()
{
	new KickType:type = KickType:GetConVarInt(sm_reserve_premium_kicktype);
	
	new Float:highestValue;
	new highestValueId;
	
	new Float:highestSpecValue;
	new highestSpecValueId;
	
	new bool:specFound;
	
	new Float:value;
	
	for (new i=1; i<=MaxClients; i++)
	{	
		if (!IsClientConnected(i))
		{
			continue;
		}
	
		if (IsFakeClient(i) || !isClientF2P(i))
		{
			continue;
		}
		
		value = 0.0;
			
		if (IsClientInGame(i))
		{
			if (type == Kick_HighestPing)
			{
				value = GetClientAvgLatency(i, NetFlow_Outgoing);
			}
			else if (type == Kick_HighestTime)
			{
				value = GetClientTime(i);
			}
			else
			{
				value = GetRandomFloat(0.0, 100.0);
			}

			if (IsClientObserver(i))
			{			
				specFound = true;
				
				if (value > highestSpecValue)
				{
					highestSpecValue = value;
					highestSpecValueId = i;
				}
			}
		}
		
		if (value >= highestValue)
		{
			highestValue = value;
			highestValueId = i;
		}
	}
	
	if (specFound)
	{
		return highestSpecValueId;
	}
	
	return highestValueId;
}