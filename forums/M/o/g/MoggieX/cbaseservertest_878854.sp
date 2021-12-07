/**
*
*	cbaseservertest by pRED*
* 	MysQL Checking Option added by |UKMD| MoggieX
*
*/

#include <sourcemod>
#include "include/cbaseserver.inc"

enum KickType
{
	Kick_HighestPing,
	Kick_HighestTime,
	Kick_Random,	
};

new g_maxClients;
new sdkVersion;
new Handle:g_IpTrie;

//Added for MySQL Checks
new Handle:ErrorChecking		= INVALID_HANDLE;
new Handle:MySQLCheck			= INVALID_HANDLE;
new bool:IsAllowed			= false;

public OnPluginStart()
{
	sdkVersion = GuessSDKVersion();
	g_IpTrie = CreateTrie();
	ErrorChecking 	= CreateConVar("cb_rs_ec","0","Error Checking CVar, 0= don't show, 1 = show");
	MySQLCheck 		= CreateConVar("cb_rs_mysql","1","MySQLCheck CVar, 1 = Enabled ");
	
	//Also added here for starting when aready running
	g_maxClients = GetMaxClients();

}

public OnMapStart()
{
	g_maxClients = GetMaxClients();	
}

public OnClientPostAdminCheck(client)
{
	decl String:ip[32];
	GetClientIP(client, ip, sizeof(ip));
	decl String:auth[32];
	GetClientAuthString(client, auth, sizeof(auth));
	
	new flags = GetUserFlagBits(client);
	
	if (flags & ADMFLAG_RESERVATION)
	{
		SetSteamForIp(ip, auth);
	}
}

public OnClientPreConnect(const String:name[], const String:pass[], const String:ip[], const String:authid[])
{
	if (GetClientCount(false) < g_maxClients)
	{
		return;	
	}

	new AdminId:admin;

	///////////////////////////////////
	//	Inserted Code
	//////////////////////////////////
	if(GetConVarInt(MySQLCheck) == 1)
	{
		/* Error Checking */
		if (GetConVarInt(ErrorChecking) == 1)
		{
			PrintToServer("[CBS Res Slots] MySQL Function Started");
			LogAction(0, -1, "[CBS Res Slots] MySQL Function Started");
		}

		decl String:error[255];		// Error!
		// Open connection
		new Handle:db = SQL_Connect("default", true, error, sizeof(error));
		if (db == INVALID_HANDLE)
		{
			/* Error Checking */
			if (GetConVarInt(ErrorChecking) == 1)
			{
				PrintToServer("[CBS Res Slots] Could Not Connect to Database, error: %s", error);
				LogError("[CBS Res Slots] Could Not Connect to Database, error: %s", error);
			}
			CloseHandle(db);
			return;
		}
	
		// db connection OK carry on
		decl String:query[255]
		new Handle:hQuery;

		Format(query, sizeof(query), "SELECT flags FROM sm_admins WHERE identity ='%s'", authid);
		if ((hQuery = SQL_Query(db, query)) == INVALID_HANDLE)
		{
			SQL_GetError(db, error, sizeof(error));
			LogError("[CBS Res Slots] query failed: %s", query);
			return;
		}

		// Not and admin BAIL (added first as I expect this is more common)
		if (!SQL_FetchRow(hQuery))
		{
			CloseHandle(hQuery);
			return;
		}
		else
		{
			decl String:UserFlags[24];			// UserFlags
			SQL_FetchString(hQuery,0, UserFlags, sizeof(UserFlags));
			if (StrContains(UserFlags, "b") || StrContains(UserFlags, "z"))
			{
				if (GetConVarInt(ErrorChecking) == 1)
				{
					// You WIN!
					LogAction(0, -1, "[CBS Res Slots] An Admin PASSSED admin checks");
					PrintToServer("[CBS Res Slots] An Admin PASSSED admin checks");
				}
				IsAllowed = true;
				CloseHandle(hQuery);
			}
			else
			{
				if (GetConVarInt(ErrorChecking) == 1)
				{
					// You FAIL!
					PrintToServer("[CBS Res Slots] An player FAILED admin checks");
					LogAction(0, -1, "[CBS Res Slots] An Admin FAILED admin checks");
				}
				CloseHandle(hQuery);
				return;
			}

		}
	}
	// Not MySQLCheck Enabled, same code as original
	else
	{
		if (sdkVersion < SOURCE_SDK_EPISODE2)
		{
			decl String:guessedSteamId[32];
			if (!GetSteamFromIP(ip, guessedSteamId, sizeof(guessedSteamId)))
			{
			return;
			}
			
			PrintToServer("PreConnect From %s (%s) matched to %s", ip, name, authid);

			admin = FindAdminByIdentity(AUTHMETHOD_STEAM, guessedSteamId);
			
			decl String:AdminPass[32];
			if (admin != INVALID_ADMIN_ID && GetAdminPassword(admin, AdminPass, sizeof(AdminPass)))
			{
				/* User has a password set */
				if (!StrEqual(AdminPass, pass))
				{
					return;	
				}	
			}
		}
		else
		{
			admin = FindAdminByIdentity(AUTHMETHOD_STEAM, authid);
		}
		if (admin == INVALID_ADMIN_ID)
		{
			return;
		}
	}

	// If they've got this far they're almost a winner!
	if (GetAdminFlag(admin, Admin_Reservation) || IsAllowed == true)
	{
		if (GetConVarInt(ErrorChecking) == 1)
		{
			// You FAIL!
			PrintToServer("[CBS Res Slots] A player has been picked to be kicked to make room");
			LogAction(0, -1, "[CBS Res Slots] A player has been picked to be kicked to make room");
		}

		new target = SelectKickClient();
						
		if (target)
		{
			KickClientEx(target, "Slot reserved");
		}
	}
}

SelectKickClient()
{
	new KickType:type = Kick_HighestPing;
	
	new Float:highestValue;
	new highestValueId;
	
	new Float:highestSpecValue;
	new highestSpecValueId;
	
	new bool:specFound;
	
	new Float:value;
	
	new maxclients = GetMaxClients();
	
	for (new i=1; i<=maxclients; i++)
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

bool:GetSteamFromIP(const String:ip[], String:steam[], len)
{
	return GetTrieString(g_IpTrie, ip, steam, len);
}

bool:SetSteamForIp(const String:ip[], const String:steam[])
{
	return SetTrieString(g_IpTrie, ip, steam, true);
}