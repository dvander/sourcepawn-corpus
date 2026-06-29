#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_VERSION  "1.23"
#define DEBUG           false

#include <sourcemod>
#include <colors>

ArrayList a_FullyLoadedPlayers;

ConVar 
    hCvar_everymap,
    hCvar_lines,
    hCvar_finalmsg,
    hCvar_finallines;

bool bVersusMode;

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	if(GetEngineVersion() != Engine_Left4Dead2)
	{
		strcopy(error, err_max, "Author only supports Left 4 Dead 2!");
		return APLRes_SilentFailure;
	}
	return APLRes_Success;
}

public Plugin myinfo =
{
    name =          "Community Welcome Message",
    author =        "Xbye (SirPlease, Nolo001)",
    description =   "Displays the community welcome message.",
    version =       PLUGIN_VERSION,
    url         =   "https://forums.alliedmods.net/showthread.php?p=2824179"
};

public void OnPluginStart()
{
    a_FullyLoadedPlayers = new ArrayList(64);

    bVersusMode   = false;

    hCvar_everymap      = 		CreateConVar("pcs_everymap", "1", "Print The Welcome Message Every Map? Otherwise, print only once on connection.", _, true, 0.0, true, 1.0);
    hCvar_lines         =       CreateConVar("pcs_lines", "2", "Print this many lines of text for the welcome message.", _, true, 0.0, true, 2.0);
    hCvar_finalmsg      =       CreateConVar("pcs_finalmsg", "1", "Print The Welcome Message Every Map? Otherwise, print only once on connection.", _, true, 0.0, true, 1.0);
    hCvar_finallines    =       CreateConVar("pcs_lines_final", "2", "Print The Welcome Message Every Map? Otherwise, print only once on connection.", _, true, 0.0, true, 2.0);

    HookEvent("player_team", Event_PlayerTeam);
    HookEvent("player_disconnect", Event_PlayerQuit);

    HookEvent("versus_match_finished", Event_VersusFinished);
    HookEvent("finale_vehicle_leaving", Event_VehicleLeave);

    LoadTranslations("pcswelcome.phrases");
    AutoExecConfig(true, "pcs.welcome");

}

public void Event_PlayerTeam(Event hEvent, const char[] eventName, bool dontBroadcast)
{
    int oldteam = hEvent.GetInt("oldteam");
    int client = GetClientOfUserId(hEvent.GetInt("userid"));

    if (client > 0 && client <= MaxClients && !IsFakeClient(client) && oldteam == 0)
    {
        #if DEBUG
            int team = hEvent.GetInt("team");
            PrintToServer("-----[%f] Fired player_team event for %N -- team: %i -- oldteam: %i", GetGameTime(), client, team, oldteam);
            //PrintToChatAll("-----[[%f] Fired player_team event for %N -- team: %i -- oldteam: %i", GetGameTime(), client, team, oldteam);
        #endif

        char clientAuth[32];
        if (!GetClientAuthId(client, AuthId_SteamID64, clientAuth, sizeof(clientAuth)))
            return;
    
        bool clientWasConnected = FindStringInArray(a_FullyLoadedPlayers, clientAuth) != -1 ? true : false;

        if (!clientWasConnected)
        {
            if (hCvar_lines.IntValue > 0)
                CPrintToChat(client, "%t", "WelcomeMsg1");

            if (hCvar_lines.IntValue > 1)
                CPrintToChat(client, "%t", "WelcomeMsg2");
            
            a_FullyLoadedPlayers.PushString(clientAuth);
        }
    }
}

public void Event_PlayerQuit(Event hEvent, const char[] sEventName, bool bDontBroadcast)
{
    char steamId[32];
    hEvent.GetString("networkid", steamId, sizeof(steamId));

    int index = FindStringInArray(a_FullyLoadedPlayers, steamId);
    
    if (index != -1)
        a_FullyLoadedPlayers.Erase(index);
}

public void Event_VehicleLeave(Event hEvent, const char[] sEventName, bool bDontBroadcast)
{
    if(hCvar_finalmsg.BoolValue)
    {   // All this unecessary if aren't printing a final message.
        if(!bVersusMode)  // For Co-Op.
        {
            if (hCvar_finallines.IntValue > 0)
                CPrintToChatAll("%t","FinalMsg1");

            if (hCvar_finallines.IntValue > 1)
                CPrintToChatAll("%t","FinalMsg2");
        }
    }
}

public void Event_VersusFinished(Event hEvent, const char[] sEventName, bool bDontBroadcast)
{
    if(hCvar_finalmsg.BoolValue)
    {   // All this unecessary if aren't printing a final message.
        if (hCvar_finallines.IntValue > 0)
            CPrintToChatAll("%t","FinalMsg1");

        if (hCvar_finallines.IntValue > 1)
            CPrintToChatAll("%t","FinalMsg2");
    }
}

public void OnMapStart()
{
    if(hCvar_finalmsg.BoolValue)
    {   // All this unnecessary if we aren't printing a final message.
        char str_GameMode[16];
        GetConVarString(FindConVar("mp_gamemode"),str_GameMode,sizeof(str_GameMode));
        bVersusMode = StrEqual("versus",str_GameMode,false);
    }
}

public void OnMapEnd()
{
    if(hCvar_everymap.BoolValue)
    {
        a_FullyLoadedPlayers.Clear();
    }
    bVersusMode = false;
}