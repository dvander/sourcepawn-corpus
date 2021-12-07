#include <sourcemod>
#include "cbaseserver.inc"
#define PLUGIN_VERSION "1.3"

// Set to 1 if you want everything logged, warning, will 
// make SM logs pretty huge if you have a busy server
#define LOG 0

enum KickType
{
	Kick_HighestPing,
	Kick_HighestTime,
	Kick_Random,	
};

new AdminId:admin = INVALID_ADMIN_ID;
new Handle:cvar_KickType = INVALID_HANDLE;
new immunelevel;
new iclient;
new immune;
#if LOG
new String:AdminName[32];
#endif

public Plugin:myinfo = 
{
	name = "CBaseServer Reserve Slots",
	author = "pRED* (modified by Jamster)",
	description = "Plugin for the CBaseServer tools extension for reserve slots",
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
	#if LOG
	GetAdminUsername(admin, AdminName, sizeof(AdminName));
	#endif
	if (admin == INVALID_ADMIN_ID)
	{
		return;
	}
	
	if (GetAdminFlag(admin, Admin_Reservation))
	{
		new target = SelectKickClient();
						
		if (target)
		{
			if (immune == MaxClients && iclient <= immunelevel)
			{
				#if LOG
				LogMessage("Connecting player immunity too low");
				LogMessage("====END====");
				#endif
				return;
			}
			#if LOG
			decl String:KickName[32];
			GetClientName(target, KickName, sizeof(KickName));
			#endif
			if (immune != MaxClients)
			{
				KickClientEx(target, "Slot reserved");
				#if LOG
				LogMessage("%s was kicked", KickName);
				LogMessage("====END====");
				#endif
			} else {
				KickClientEx(target, "Slot reserved - Low Immunity");
				#if LOG
				LogMessage("%s was kicked (Low immunity)", KickName);
				LogMessage("====END====");
				#endif
			}
		#if LOG
		} else {
			LogMessage("No valid target found");
			LogMessage("====END====");
		#endif
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
	
	new bool:specFound;
	
	new Float:highestSpecValue;
	new highestSpecValueId;
	
	new Float:value;
	new pindex = 1;
	immune = 0;
	immunelevel = 101;
	
	iclient = GetAdminImmunityLevel(admin);
	#if LOG
	LogMessage("===START===");
	#endif
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
		
		new String:iauth[32];
		GetClientAuthString(i, iauth, sizeof(iauth));
		new AdminId:iplayeradmin = FindAdminByIdentity(AUTHMETHOD_STEAM, iauth)
		new iplayer = GetAdminImmunityLevel(iplayeradmin);
		
		#if LOG
		decl String:PlayerName[32];
		GetClientName(i, PlayerName, sizeof(PlayerName));
		LogMessage("%0d: %s immunity: %d", pindex, PlayerName, iplayer);
		pindex++;
		#endif
		
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
				#if LOG
				LogMessage("^SPECTATOR FOUND^");
				#endif
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
	#if LOG
	LogMessage("===========");
	LogMessage("Connecting player (%s) immunity: %d", AdminName, iclient);
	LogMessage("Lowest immunity: %d", immunelevel);
	LogMessage("Immunity player count: %d", immune);
	LogMessage("Max player count: %d", MaxClients);
	LogMessage("===========");
	#endif	
		
	if (immune == MaxClients)
	{
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

			new String:iauth[32];
			GetClientAuthString(i, iauth, sizeof(iauth));
			new AdminId:iplayeradmin = FindAdminByIdentity(AUTHMETHOD_STEAM, iauth)
			new iplayer = GetAdminImmunityLevel(iplayeradmin);
			
			if (iplayer > immunelevel)
			{
				continue;
			}
			
			if (iplayer >= iclient)
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
	}
	
	if (specFound)
	{
		return highestSpecValueId;
	}
	
	return highestValueId;
}