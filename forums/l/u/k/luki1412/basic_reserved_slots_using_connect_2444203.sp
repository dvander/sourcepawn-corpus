#include <sourcemod>

#pragma newdecls required
#pragma semicolon 1

#define PLUGIN_VERSION "1.00"

public Extension __ext_Connect = 
{
	name = "Connect",
	file = "connect.ext",
	autoload = 1,
	required = 1,
}

ConVar g_hcvarKickType;
ConVar g_hcvarEnabled;
ConVar g_hcvarReason;
forward bool OnClientPreConnectEx(const char[] name, char password[255], const char[] ip, const char[] steamID, char rejectReason[255]);

public Plugin myinfo = 
{
	name = "Basic Reserved Slots using Connect",
	author = "luki1412",
	description = "Simple plugin for reserved slots using Connect",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/member.php?u=43109"
}

public void OnPluginStart()
{
	ConVar g_hcvarVer = CreateConVar("sm_brsc_version", PLUGIN_VERSION, "Basic Reserved Slots using Connect - version cvar", FCVAR_NOTIFY|FCVAR_DONTRECORD);
	g_hcvarEnabled = CreateConVar("sm_brsc_enabled", "1", "Enables/disables this plugin", FCVAR_NONE, true, 0.0, true, 1.0);
	g_hcvarKickType = CreateConVar("sm_brsc_type", "1", "Who gets kicked out: 1 - Highest ping player, 2 - Longest connection time player, 3 - Random player", FCVAR_NONE, true, 1.0, true, 3.0);
	g_hcvarReason = CreateConVar("sm_brsc_reason", "Kicked to make room for an admin", "Reason used when kicking players", FCVAR_NONE);
	
	SetConVarString(g_hcvarVer, PLUGIN_VERSION);	
	AutoExecConfig(true, "Basic_Reserved_Slots_using_Connect");
}

public bool OnClientPreConnectEx(const char[] name, char password[255], const char[] ip, const char[] steamID, char rejectReason[255])
{
	if (!GetConVarInt(g_hcvarEnabled))
	{
		return true;
	}

	if (GetClientCount(false) < MaxClients)
	{
		return true;	
	}

	AdminId admin = FindAdminByIdentity(AUTHMETHOD_STEAM, steamID);
	
	if (admin == INVALID_ADMIN_ID)
	{
		return true;
	}
	
	if (GetAdminFlag(admin, Admin_Reservation))
	{
		int target = SelectKickClient();
						
		if (target)
		{
			char rReason[255];
			GetConVarString(g_hcvarReason, rReason, sizeof(rReason));
			KickClientEx(target, "%s", rReason);
		}
	}
	
	return true;
}

int SelectKickClient()
{	
	float highestValue;
	int highestValueId;
	
	float highestSpecValue;
	int highestSpecValueId;
	
	bool specFound;
	
	float value;
	
	for (int i = 1; i <= MaxClients; i++)
	{	
		if (!IsClientConnected(i))
		{
			continue;
		}
	
		int flags = GetUserFlagBits(i);
		
		if (IsFakeClient(i) || flags & ADMFLAG_ROOT || flags & ADMFLAG_RESERVATION || CheckCommandAccess(i, "sm_reskick_immunity", ADMFLAG_RESERVATION, false))
		{
			continue;
		}
		
		value = 0.0;
			
		if (IsClientInGame(i))
		{
			switch(GetConVarInt(g_hcvarKickType))
			{
				case 1:
				{
					value = GetClientAvgLatency(i, NetFlow_Outgoing);
				}
				case 2:
				{
					value = GetClientTime(i);
				}
				default:
				{
					value = GetRandomFloat(0.0, 100.0);
				}
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
