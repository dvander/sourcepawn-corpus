#include<sourcemod>
#include<sdktools>
#include<SteamWorks>

public Plugin:myinfo = 
{
	name = "Check Fam Sharing",
	author = "Alice Margatroid",
	description = "Check Fam Sharing with Owner SteamID",
	url = "http://cafe.naver.com/cssttt"
}

new bool:PreLoaded[MAXPLAYERS+1];//this variable will check that player joined without steamid.
new Handle:hDataSteamID = INVALID_HANDLE;
new String:FamSharingLogPath[PLATFORM_MAX_PATH];

//#define _DEBUG_MODE
#define _PRINT_TO_ADMIN

public OnPluginStart()
{
	hDataSteamID = CreateTrie();
	BuildPath(Path_SM, FamSharingLogPath, sizeof(FamSharingLogPath), "logs/family_sharing_log.log");
	
	HookEvent("player_disconnect", Hook_PlayerDisconnect);
}

public OnPluginEnd()
{
	if(hDataSteamID != INVALID_HANDLE)
	{
		CloseHandle(hDataSteamID);
	}
}

public OnClientConnected(Client)
{
#if defined (_DEBUG_MODE)
	PrintToServer("[DEBUG] OnClientConnected is fired");
#endif
	PreLoaded[Client] = false;
}

public Hook_PlayerDisconnect(Handle:event, const String:name[], bool:dontBroadcast)
{
#if defined (_DEBUG_MODE)
	PrintToServer("[DEBUG] Hook_PlayerDisconnect is fired");
#endif
	new String:SteamID[20];
	GetEventString(event, "networkid", SteamID, sizeof(SteamID));
	
	new String:TrieData[20];
	if(GetTrieString(hDataSteamID, SteamID, TrieData, sizeof(TrieData)) == true)
	{
		//player was disconnected before fully connected. remove data now.
		RemoveFromTrie(hDataSteamID, SteamID);
	}
}

//player's steamid is validated.
public SteamWorks_OnValidateClient(ownerauthid, authid)
{
#if defined (_DEBUG_MODE)
	PrintToServer("[DEBUG] SteamWorks_OnValidateClient is fired");
#endif
	new String:SteamID[20], String:OwnerSteamID[20];
	Format(SteamID, sizeof(SteamID), "STEAM_0:%d:%d", (authid & 1), (authid >> 1));
	Format(OwnerSteamID, sizeof(OwnerSteamID), "STEAM_0:%d:%d", (ownerauthid & 1), (ownerauthid >> 1));
	
	new Client = GetIndexBySteamID(SteamID);
	
	if(Client != -1 && PreLoaded[Client] == true)
	{
		CheckFamilySharing(Client, SteamID, OwnerSteamID);
		return;
	}
	
	//add data on trie.
	SetTrieString(hDataSteamID, SteamID, OwnerSteamID);
}

public OnClientAuthorized(Client, const String:SteamID[])
{
#if defined (_DEBUG_MODE)
	PrintToServer("[DEBUG] OnClientAuthorized is fired");
#endif
	PreLoaded[Client] = true;
}

public OnClientPutInServer(Client)
{
#if defined (_DEBUG_MODE)
	PrintToServer("[DEBUG] OnClientPutInServer is fired");
#endif
	if(PreLoaded[Client] == false)
	{
		PreLoaded[Client] = true;
		return;
	}
	
	new String:SteamID[20], String:OwnerSteamID[20];
	GetClientAuthString(Client, SteamID, sizeof(SteamID));
	if(GetTrieString(hDataSteamID, SteamID, OwnerSteamID, sizeof(OwnerSteamID)) == true)
	{
		CheckFamilySharing(Client, SteamID, OwnerSteamID);
		RemoveFromTrie(hDataSteamID, SteamID);
	}
}

public CheckFamilySharing(Client, const String:SteamID[], const String:OwnerSteamID[])
{
	new String:sBuffer[256];
	Format(sBuffer, sizeof(sBuffer), "Player \"%N\" (%s) has been verified with game server. owner's steam id is %s", Client, SteamID, OwnerSteamID);
#if defined (_DEBUG_MODE)
	LogMessage(sBuffer);
#endif
	if(StrEqual(SteamID, OwnerSteamID, false) == false)
	{
		LogToFileEx(FamSharingLogPath, sBuffer);
#if defined (_PRINT_TO_ADMIN)
		for(new i=1; i<=MaxClients; i++) if(IsClientInGame(i) && IsPlayerAdmin(i)) PrintToChat(i, "\x04[Family Sharing] \x03%s", sBuffer);
#endif
	}
}

GetIndexBySteamID(const String:sSteamID[])
{
	decl String:AuthStringToCompareWith[32];
	for(new i = 1; i <= MaxClients; i++)
	{
		if(IsValidClient(i))
		{
			GetClientAuthString(i, AuthStringToCompareWith, sizeof(AuthStringToCompareWith));
			
			if(StrEqual(AuthStringToCompareWith, sSteamID, false))
			{
				return i;
			}
		}
	}
	return -1;
}

stock bool:IsValidClient(client)
{
	if (!(1 <= client <= MaxClients) || !IsClientInGame(client) || IsFakeClient(client))
	{
		return false;
	}
	return true;
}

stock IsPlayerAdmin(client)
{
	return (GetUserAdmin(client) != INVALID_ADMIN_ID) ? true : false;
}