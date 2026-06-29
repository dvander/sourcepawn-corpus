#include <sourcemod>
#include "cbaseserver.inc"
#define PLUGIN_VERSION "0.1"

enum KickType
{
	Kick_HighestPing,
	Kick_HighestTime,
	Kick_Random,	
};

new Handle:cvar_KickType = INVALID_HANDLE;
new Handle:cvar_Logging = INVALID_HANDLE;
new Handle:cvar_Immunity = INVALID_HANDLE;

public Plugin:myinfo = 
{
	name = "Immunity Reserve Slots",
	author = "Jamster (original plugin by *pRED)",
	description = "Immunity based reserve slots for the CBaseServer Tools extension",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net/"
};

public OnPluginStart()
{
	cvar_KickType = CreateConVar("sm_cbaseres_kicktype", "0", "Who to kick when a valid player is found (0 - random, 1 - highest ping, 2 - highest time)", FCVAR_PLUGIN, true, 0.0, true, 2.0);
	cvar_Logging = CreateConVar("sm_cbaseres_log", "0", "Enable highly verbose logs", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	cvar_Immunity = CreateConVar("sm_cbaseres_immunity", "1", "Enable immunity check (0 - off, 1 - res check THEN immunity check if server is full of res, 2 - allow players with immunity and no res to stay connected if their immunty is high enough)", FCVAR_PLUGIN, true, 0.0, true, 2.0);
}

public OnClientPreConnect(const String:name[], const String:pass[], const String:ip[], const String:authid[])
{
	PrintToServer("%s %s %s %s", name, pass, ip, authid);
	
	if (GetClientCount(false) < MaxClients)
	{
		return;	
	}
	
	new bool:LoggingEN;
	if (GetConVarInt(cvar_Logging))
	{
		LoggingEN = true;
	} else {
		LoggingEN = false;
	}
	
	new ImmunityEN = GetConVarInt(cvar_Immunity);
	
	new AdminId:admin = INVALID_ADMIN_ID;
	new String:AdminName[32];
	admin = FindAdminByIdentity(AUTHMETHOD_STEAM, authid);
	
	if (LoggingEN)
	{
		GetAdminUsername(admin, AdminName, sizeof(AdminName));
	}
	
	if (admin == INVALID_ADMIN_ID)
	{
		return;
	}
	
	if (GetAdminFlag(admin, Admin_Reservation))
	{
		new KickTarget = 0;
		
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
		
		new Float:HighestValue;
		new HighestValueId;
		
		new bool:SpecFound;
		
		new Float:highestSpecValue;
		new HighestSpecValueId;
		
		new Float:value;
		new PlayerIndex = 1;
		new ImmuneCount = 0;
		new LowestImmunityLevel = 101;
		
		new ConnectingPlayerImmunity = GetAdminImmunityLevel(admin);
		if (LoggingEN)
		{
			LogMessage("===START===");
		}
		for (new i=1; i<=MaxClients; i++)
		{	
			if (!IsClientConnected(i))
			{
				ImmuneCount++;
				continue;
			}
			
			if (IsFakeClient(i))
			{
				ImmuneCount++;
				continue;
			}

			new flags = GetUserFlagBits(i);
			
			new String:PlayerAuth[32];
			GetClientAuthString(i, PlayerAuth, sizeof(PlayerAuth));
			new AdminId:PlayerAdmin = FindAdminByIdentity(AUTHMETHOD_STEAM, PlayerAuth)
			new PlayerImmunity = GetAdminImmunityLevel(PlayerAdmin);
			
			if (LoggingEN)
			{
				decl String:PlayerName[32];
				GetClientName(i, PlayerName, sizeof(PlayerName));
				LogMessage("%0d: %s immunity: %d", PlayerIndex, PlayerName, PlayerImmunity);
				PlayerIndex++;
			}
			
			if (flags & ADMFLAG_ROOT || flags & ADMFLAG_RESERVATION || CheckCommandAccess(i, "sm_reskick_immunity", ADMFLAG_RESERVATION, false))
			{
				if (ImmunityEN && PlayerImmunity < LowestImmunityLevel)
				{
					LowestImmunityLevel = PlayerImmunity;
				}
				ImmuneCount++;
				continue;
			}
			
			if (ImmunityEN == 2 && PlayerImmunity > 0)
			{
				ImmuneCount++;
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
					SpecFound = true;
					if (LoggingEN)
					{
						LogMessage("^SPECTATOR FOUND^");
					}
					if (value > highestSpecValue)
					{
						highestSpecValue = value;
						HighestSpecValueId = i;
					}
				}
			}
			
			if (value >= HighestValue)
			{
				HighestValue = value;
				HighestValueId = i;
			}
			
		}
		if (LoggingEN)
		{
			LogMessage("===========");
			LogMessage("Connecting player (%s) immunity: %d", AdminName, ConnectingPlayerImmunity);
			LogMessage("Lowest immunity: %d", LowestImmunityLevel);
			LogMessage("Immunity player count: %d", ImmuneCount);
			LogMessage("Max player count: %d", MaxClients);
			LogMessage("===========");
		}
			
		if (ImmunityEN && ImmuneCount == MaxClients)
		{
			if (LoggingEN)
			{
				LogMessage("Running immunity check");
			}
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

				new String:PlayerAuth[32];
				GetClientAuthString(i, PlayerAuth, sizeof(PlayerAuth));
				new AdminId:PlayerAdmin = FindAdminByIdentity(AUTHMETHOD_STEAM, PlayerAuth)
				new PlayerImmunity = GetAdminImmunityLevel(PlayerAdmin);
				
				if (PlayerImmunity > LowestImmunityLevel)
				{
					continue;
				}
				
				if (PlayerImmunity >= ConnectingPlayerImmunity)
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
							HighestSpecValueId = i;
						}
					}
				}
				
				if (value >= HighestValue)
				{
					HighestValue = value;
					HighestValueId = i;
				}
			}
		}
		
		if (SpecFound)
		{
			KickTarget = HighestSpecValueId;
		} else {
			KickTarget = HighestValueId;
		}
						
		if (KickTarget)
		{
			decl String:KickName[32];
			//Theoretically this should never happen, but you never know
			if (ImmunityEN && ImmuneCount == MaxClients && ConnectingPlayerImmunity <= LowestImmunityLevel)
			{
				if (LoggingEN)
				{
					LogMessage("Connecting player immunity too low");
					LogMessage("====END====");
				}
				return;
			}
			if (LoggingEN)
			{
				GetClientName(KickTarget, KickName, sizeof(KickName));
			}
			if (ImmuneCount != MaxClients)
			{
				KickClientEx(KickTarget, "Slot reserved");
				if (LoggingEN)
				{
					LogMessage("%s was kicked", KickName);
					LogMessage("====END====");
				}
			} else {
				KickClientEx(KickTarget, "Slot reserved - Low Immunity");
				if (LoggingEN)
				{
					LogMessage("%s was kicked (Low immunity)", KickName);
					LogMessage("====END====");
				}
			}
		} else {
			//This should not happen either, but again, just in case
			if (LoggingEN)
			{
				LogMessage("No valid client to kick found");
				LogMessage("====END====");
			}
			return;
		}
	}
}