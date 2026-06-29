#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <SteamWorks>
#include <morecolors>

#define PLUGIN_VERSION      "5.0"
#define STEAMID_LENGTH      32
#define KICK_MESSAGE        "You have been refused entry to this server due to Steam Family Sharing being detected on your account. Please reconnect using a game you own. This attempt has been logged"
#define COLOUR_PREFIX       "{lightblue}[{blue}Family Share Check{lightblue}]{white}"
#define COLOUR_NORMAL       "{white}"
#define COLOUR_HIGHLIGHT    "{blue}"

new Handle:gKickVar;
new Handle:gLogVar;

new Handle:g_hDatabase = INVALID_HANDLE;
new Handle:fsArray;

public Plugin:myinfo =
{
    name = "Family Sharing Check/Block",
    author = "VirtualVelocity",
    description = "Checks if a player is using a shared game",
    version = PLUGIN_VERSION,
}

public OnPluginStart()
{
    gKickVar = CreateConVar("fs_kick", "1", "Toggles between kicking players connecting with a shared game"); // Will default to 1
    gLogVar = CreateConVar("fs_log", "1", "Toggles between logging players connecting with a shared game"); // Will default to 1
    
    fsArray = CreateArray(128, 0);
    
    CreateTimer(1.0, CheckFamSharing, _, TIMER_REPEAT);
}

public OnMapStart()
{
    if(g_hDatabase == INVALID_HANDLE)
    {
        SQL_TConnect(sql_connected, "familysharing");
    }
    
    ClearArray(fsArray);
}

public sql_connected(Handle:owner, Handle:hndl, const String:error[], any:data)
{
    if (g_hDatabase != INVALID_HANDLE)
    {
        CloseHandle(hndl);
        return;
    }
    
    g_hDatabase = hndl;
    
    if (g_hDatabase == INVALID_HANDLE)
    {
        LogError("Failed to connect to database: %s", error);
        return;
    }
}

public SW_OnValidateClient(OwnerSteamID, ClientSteamID)
{    
    decl String:oSteamID[32];
    Format(oSteamID, sizeof(oSteamID),"STEAM_0:%d:%d", (OwnerSteamID & 1), (OwnerSteamID >> 1));
    
    decl String:cSteamID[32];
    Format(cSteamID, sizeof(cSteamID),"STEAM_0:%d:%d", (ClientSteamID & 1), (ClientSteamID >> 1));
    
    //new Handle:dataPack = CreateDataPack();
    //WritePackString(dataPack, oSteamID);
    //WritePackString(dataPack, cSteamID);
    //ResetPack(dataPack);
    
    new String:SteamIDs[328];
    Format(SteamIDs, sizeof(SteamIDs), "%s-%s", oSteamID, cSteamID);
    PushArrayString(fsArray, SteamIDs);
}

public Action:CheckFamSharing(Handle:Timer, Handle:data)
{
    new String:buffer[128][128];
    for(new i = 0; i < GetArraySize(fsArray); i++)
    {
        new String:SteamIDarray[328];
        GetArrayString(fsArray, i, SteamIDarray, sizeof(SteamIDarray));
        ExplodeString(SteamIDarray, "-", buffer, sizeof(buffer), sizeof(buffer[])); // Split the downloads up, and store in buffer
        new client = GetIndexBySteamID(buffer[1]);
        
        if(client != -1)
        {
            RemoveFromArray(fsArray, i);
            i--;
            
            if(!StrEqual(buffer[0], buffer[1], false))
            {
                if(GetConVarInt(gLogVar) == 1)
                {
                    // LOGGING
                    new String:queryString[1024];
                    Format(queryString, sizeof(queryString), "INSERT INTO plugin_familysharing (CSTEAMID, OSTEAMID, TIMEJOINED) VALUES ('%s', '%s', UNIX_TIMESTAMP())", buffer[1], buffer[0]);
                    
                    SQL_TQuery(g_hDatabase, ResultLogged, queryString);
                }
                if(GetConVarInt(gKickVar) == 1)
                {
                    // KICKING
                    new String:cName[128];
                    GetClientName(client, cName, sizeof(cName));
                    KickClientEx(client, KICK_MESSAGE); // KICKING THE CLIENT
                    CPrintToChatAll("%s %s%s%s was denied access due to using a family shared account.", COLOUR_PREFIX, COLOUR_HIGHLIGHT, cName, COLOUR_NORMAL);
                }
            }
        }
    }
    /*
    new client = GetIndexBySteamID(cSteamID);
    
    if(client != -1)
    {
        if(!StrEqual(oSteamID, cSteamID, false))
        {
            if(GetConVarInt(gLogVar) == 1)
            {
                // LOGGING
                new String:queryString[1024];
                Format(queryString, sizeof(queryString), "INSERT INTO plugin_familysharing (CSTEAMID, OSTEAMID, TIMEJOINED) VALUES ('%s', '%s', UNIX_TIMESTAMP())", cSteamID, oSteamID);
                
                SQL_TQuery(g_hDatabase, ResultLogged, queryString);
            }
            if(GetConVarInt(gKickVar) == 1)
            {
                // KICKING
                KickClientEx(client, KICK_MESSAGE); // KICKING THE CLIENT
            }
        }
    }
    CloseHandle(data);
    */
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

public Action:LoadStuff(Handle:timer)
{
	PrintToServer("Found client!");
}

public ResultLogged(Handle:owner, Handle:hndl, const String:error[], any:data)
{
    if(hndl == INVALID_HANDLE)
    {
        LogError("Statement did not execute (%s)", error);
    }
}