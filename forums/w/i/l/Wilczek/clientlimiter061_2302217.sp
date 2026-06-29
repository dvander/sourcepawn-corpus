#pragma semicolon 1
#include <sourcemod>
#include <adt_array>

Handle sm_admin_slots;

Handle Arr_SteamIDs = INVALID_HANDLE;
Handle fSteamIDList = INVALID_HANDLE;
char steamIDlist[PLATFORM_MAX_PATH];

public Plugin myinfo =
{
    name = "Client limiter",
    author = "Wilk",
    description = "Don't allow clients to connect if the server is full (supporting reserved slots)",
    version = "0.6.1",
    url = "http://hejk.pl"
};

public OnPluginStart()
{
	sm_admin_slots = CreateConVar("sm_admin_slots", "0", "number of reserved slots", FCVAR_NOTIFY, true, 0.0);
	
	BuildPath(Path_SM, steamIDlist, sizeof(steamIDlist), "configs/admin_slots.txt");
	LoadSteamIDList();
}

public OnClientPostAdminCheck(client)
{	
	//Temporary flags for non-admin users found in the admin_slots.txt file
	char auth[32];
	GetClientAuthId(client, AuthId_Steam2, auth, sizeof(auth));
	
	if (FindStringInArray(Arr_SteamIDs, auth) != -1)
	{
		SetUserFlagBits(client, ADMFLAG_RESERVATION);
	}
	
	//Reserved slots mechanism
	int limit = GetMaxHumanPlayers();
	
	if (GetClientCount(false) > (limit - GetConVarInt(sm_admin_slots)))
	{
		if (hasReservedSlotAccess(GetUserFlagBits(client)))
		{
			char playername[50];
			GetClientName(client, playername, 49);
			LogMessage("player %s connected to a reserved slot", playername);
			
			if (GetClientCount(false) > limit)
			{
				CreateTimer(0.1, OnTimedKickForReject, GetClientUserId(client));
			}
		}
		else {
			CreateTimer(0.1, OnTimedKickForReject, GetClientUserId(client));
		}
	}
}

public Action OnTimedKickForReject(Handle timer, any userid)
{
	int client = GetClientOfUserId(userid);
	
	if (!client || !IsClientInGame(client))
	{
		return Plugin_Handled;
	}

	char sPlayername[50], sPlayerid[50];
	GetClientName(client, sPlayername, 49);
	GetClientAuthId(client, AuthId_Steam2, sPlayerid, 49);
	int iClientsingame = GetClientCount(false);
	int iLimit = GetMaxHumanPlayers();
	
	LogMessage("kicking rejected player %s<%s> - [%d/%d] players", sPlayername, sPlayerid, iClientsingame, iLimit);
	
	KickClient(client, "Server is full");
	return Plugin_Handled;
}

// return true if this user is allowed to connect to a reserved slot  
bool hasReservedSlotAccess(const userFlags) {
	
	// admin flag based 
	if (userFlags & ADMFLAG_ROOT || userFlags & ADMFLAG_RESERVATION) {
		return true;
	}
	else {
		return false;
	}
}

LoadSteamIDList()
{
	if (FileExists(steamIDlist, false)) {
		fSteamIDList = OpenFile(steamIDlist, "rt");
	}
	else {
		fSteamIDList = OpenFile(steamIDlist, "at+");
		LogMessage("Created a config file at the file path: %s", steamIDlist);
	}

	if (fSteamIDList == INVALID_HANDLE)
		LogMessage("Error - unable to load or create file: %s", steamIDlist);

	Arr_SteamIDs = CreateArray(256);

	char sReadBuffer[256];
	
	int len;
	while (!IsEndOfFile(fSteamIDList) && ReadFileLine(fSteamIDList, sReadBuffer, sizeof(sReadBuffer)))
	{
		if(sReadBuffer[0] == '/' || IsCharSpace(sReadBuffer[0]))
			continue;
		
		ReplaceString(sReadBuffer, sizeof(sReadBuffer), "\n", "");
		ReplaceString(sReadBuffer, sizeof(sReadBuffer), "\r", "");
		ReplaceString(sReadBuffer, sizeof(sReadBuffer), "\t", "");
		ReplaceString(sReadBuffer, sizeof(sReadBuffer), " ", "");
		
		// Support for comments on end of line
		len = strlen(sReadBuffer);
		for(new i; i < len; i++)
		{
			if(sReadBuffer[i] == ' ' || sReadBuffer[i] == '/')
			{
				sReadBuffer[i] = '\0';
				
				break;
			}
		}
		
		//LogMessage("Pushing %s to Arr_SteamIDs", sReadBuffer);
		
		PushArrayString(Arr_SteamIDs, sReadBuffer);
	}
	
	//LogMessage("Reached EOF on %s", steamIDlist);
	
	CloseHandle(fSteamIDList);
} 