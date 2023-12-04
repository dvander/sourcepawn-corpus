/******************************
COMPILE OPTIONS
******************************/

#pragma semicolon 1
#pragma newdecls required

/******************************
NECESSARY INCLUDES
******************************/

#include <sourcemod>
#include <sdktools>

/******************************
PLUGIN DEFINES
******************************/

/*Setting static strings*/
static const char
	/*Plugin Info*/
	PL_NAME[]		 = "SteamID Hijack Protection",
	PL_AUTHOR[]		 = "Peter Brev ( forked from JZServices plugin )",
	PL_DESCRIPTION[] = "SteamID Hijack Protection",
	PL_VERSION[]	 = "1.0.0";

/******************************
PLUGIN INFO
******************************/
public Plugin myinfo =
{
	name		= PL_NAME,
	author		= PL_AUTHOR,
	description = PL_DESCRIPTION,
	version		= PL_VERSION
};

/******************************
PLUGIN FUNCTIONS
******************************/

public void OnClientPostAdminCheck(int client)
{
    if (IsFakeClient(client))return;

    char id[32];
    GetClientAuthId(client, AuthId_Steam2, id, sizeof(id));

    for (int i = 1; i <= MaxClients; i++)
    {
        if (client == i || !IsClientConnected(i))
            continue;
        
        char targetid[32];
        GetClientAuthId(i, AuthId_Steam2, id, sizeof(id));

        //if (StrEqual(id, targetid, false))
        if (strcmp(id, targetid, false) == 0)
        {
            KickClient(i, "SteamID Hijack detected.");
            LogMessage("Kicked \"%L\" for hijacking the SteamID of \"%N\".", i, client);
        }
    }
}