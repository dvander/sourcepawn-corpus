#include <sourcemod>
#include "connect"

enum KickType
{
	Kick_HighestPing = 1,
	Kick_HighestTime,
	Kick_Random,	
};

new Handle:g_hcvarKickType = INVALID_HANDLE;
new KickType:g_KickType = Kick_HighestPing;

public Plugin:myinfo = 
{
	name = "CBaseServer Ext Basic Reserve Slots",
	author = "predfoot winkerbottom",
	description = "Simple plugin to demo no-waste reserve slots",
	version = "",
	url = "http://www.sourcemod.net/"
};

public OnPluginStart()
{
	g_hcvarKickType = CreateConVar("cbsext_reserve_type", "1", "Who gets the boot? 1 - Highest ping (default). 2 - Longest connection time. 3 - Random.", 0, true, 1.0, true, 3.0);
	HookConVarChange(g_hcvarKickType, OnKickTypeChanged);
}

public OnKickTypeChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	g_KickType = KickType:StringToInt(newValue);
}

public bool:OnClientPreConnect(const String:name[], String:password[255], const String:ip[], const String:authid[], String:rejectReason[255])
{
	if (GetClientCount(false) < MaxClients)
	{
		return true;	
	}

	new AdminId:admin = FindAdminByIdentity(AUTHMETHOD_STEAM, authid);
	
	if (admin == INVALID_ADMIN_ID)
	{
		return true;
	}

	if (GetAdminFlag(admin, Admin_Reservation))
	{
		new target = SelectKickClient();
		if (target)
		{
			KickClientEx(target, "Slot reserved");
			return true;
		}
	}
	return true;
}

SelectKickClient()
{	
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
	
		new flags = GetUserFlagBits(i);
		
		if (IsFakeClient(i) || flags & ADMFLAG_ROOT || flags & ADMFLAG_RESERVATION || CheckCommandAccess(i, "sm_reskick_immunity", ADMFLAG_RESERVATION, false))
		{
			continue;
		}
		
		value = 0.0;
			
		if (IsClientInGame(i))
		{
			switch(g_KickType)
			{
				case Kick_HighestPing:
					value = GetClientAvgLatency(i, NetFlow_Outgoing);
				case Kick_HighestTime:
					value = GetClientTime(i);
				default:
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
