#include <sourcemod>
#include "cbaseserver.inc"
#define PLUGIN_VERSION "1.2"

enum KickType
{
	Kick_HighestPing,
	Kick_HighestTime,
	Kick_Random,	
};

new AdminId:admin = INVALID_ADMIN_ID;
new Handle:cvar_KickType = INVALID_HANDLE;

public Plugin:myinfo = 
{
	name = "CBaseServer tools plugin",
	author = "pRED* (modified by Jamster)",
	description = "Plugin for the CBaseServer tools extension",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net/"
};

public OnPluginStart()
{
	cvar_KickType = CreateConVar("sm_cbase_kicktype", "0", "Who to kick when a valid player is found (0 - random, 1 - highest ping, 2 - highest time)", FCVAR_PLUGIN, true, 0.0, true, 2.0);
}

public OnClientPreConnect(const String:name[], const String:pass[], const String:ip[], const String:authid[])
{
	PrintToServer("%s %s %s %s",name, pass, ip, authid);
	
	if (GetClientCount(false) < MaxClients)
	{
		return;	
	}
	
	admin = FindAdminByIdentity(AUTHMETHOD_STEAM, authid);
	
	if (admin == INVALID_ADMIN_ID)
	{
		return;
	}
	
	if (GetAdminFlag(admin, Admin_Reservation))
	{
		new target = SelectKickClient();
						
		if (target)
		{
			KickClientEx(target, "Slot reserved");
		}
	}
}

SelectKickClient()
{
	new KickType:type;
	if (GetConVarInt(cvar_KickType) == 0)
	{
		type = Kick_Random;
	} 
	if (GetConVarInt(cvar_KickType) == 1)
	{
		type = Kick_HighestPing;
	}
	if (GetConVarInt(cvar_KickType) == 2)
	{
		type = Kick_HighestTime;
	}
	
	new Float:highestValue;
	new highestValueId;
	
	new Float:highestSpecValue;
	new highestSpecValueId;
	
	new bool:specFound;
	
	new Float:value;
	new immune = 0;
	new immunelevel = 100;
	
	for (new i=1; i<=MaxClients; i++)
	{	
		if (!IsClientConnected(i))
		{
			immune++;
			continue;
		}
		
		if (IsFakeClient(i))
		{
			immune++;
			continue;
		}

		new flags = GetUserFlagBits(i);
		
		new AdminId:iplayeradmin = GetUserAdmin(i);
		new iplayer = GetAdminImmunityLevel(iplayeradmin);
		
		if (flags & ADMFLAG_ROOT || flags & ADMFLAG_RESERVATION || CheckCommandAccess(i, "sm_reskick_immunity", ADMFLAG_RESERVATION, false))
		{
			if (iplayer < immunelevel)
			{
				immunelevel = iplayer;
			}
			immune++;
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
	
	if (immune == MaxClients)
	{
		new iclient = GetAdminImmunityLevel(admin);
		for (new i=1; i<=MaxClients; i++)
		{
			if (!IsClientConnected(i))
			{
				continue;
			}
					
			if (IsFakeClient(i))
			{
				continue;
			}

			new AdminId:iplayeradmin = GetUserAdmin(i);
			new iplayer = GetAdminImmunityLevel(iplayeradmin);
			
			if (iplayer >= iclient)
			{
				continue;
			}
			
			if (iplayer > immunelevel)
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
			}
			if (value >= highestValue)
			{
				highestValue = value;
				highestValueId = i;
			}
		}
	}
	
	return highestValueId;
}