#include <sourcemod>
#include <sdktools>

#pragma semicolon 1

#define CVAR_VERSION	    0
#define CVAR_THRESHOLD	    1
#define CVAR_IMMUNITY	    2
#define CVAR_MUTEMSG	    3
#define CVAR_NUM_CVARS	    4

#define MICSPAM_VERSION	    "0.3"

public Plugin:myinfo = {
    name = "Micspam Mute",
    author = "Grrrrrrrrrrrrrrrrrrr",
    description = "Automatically mutes players who engage in HLSS/HLDJ spamming",
    version = MICSPAM_VERSION,
    url = ""
};

new Handle:g_cvars[CVAR_NUM_CVARS];
new g_times[MAXPLAYERS + 1];
new isValidAdmin[MAXPLAYERS + 1];
new saveListeningFlags[MAXPLAYERS + 1] = { -1 };

public OnPluginStart() 
{
    g_cvars[CVAR_VERSION] = CreateConVar("sm_micspam_version", MICSPAM_VERSION, "Micspam Mute Version", FCVAR_PLUGIN|FCVAR_REPLICATED|FCVAR_NOTIFY);

    g_cvars[CVAR_THRESHOLD] = CreateConVar("sm_micspam_threshold", "3", "Time, in seconds, a player can transmit prerecorded audio before being muted", FCVAR_PLUGIN);

    g_cvars[CVAR_IMMUNITY] = CreateConVar("sm_micspam_immunity", "0", "Players with an immunity level greater than this value will be immune to the effects of this plugin", FCVAR_PLUGIN);

    g_cvars[CVAR_MUTEMSG] = CreateConVar("sm_micspam_mutemsg", "[SM] You were muted temporarly due to excessive micspam", "Message to display to a player who was muted for micspam", FCVAR_PLUGIN);

    CreateTimer(1.0, Timer_CheckAudio, _, TIMER_REPEAT);
}

public OnClientPostAdminCheck(client)
{	
	new AdminId:admin = GetUserAdmin(client);
	if (admin != INVALID_ADMIN_ID && GetAdminImmunityLevel(admin) > GetConVarInt(g_cvars[CVAR_IMMUNITY]))
	{
		isValidAdmin[client] = 1;
	}
	else
	{
		isValidAdmin[client] = 0;
	}	
}

public Action:Timer_CheckAudio(Handle:timer, any:data) 
{
    for (new client = 1; client <= MaxClients; client++) 
    {
		if (IsClientInGame(client) && IsClientConnected(client) && !IsFakeClient(client) && isValidAdmin[client] == 0) 
		{			
	    	QueryClientConVar(client, "voice_inputfromfile", CB_CheckAudio);
		}
    }
}

public CB_CheckAudio(QueryCookie:cookie, client, ConVarQueryResult:result, const String:cvarName[], const String:cvarValue[]) 
{
	new tempListeningFlags = GetClientListeningFlags(client);
	
    if (result == ConVarQuery_Okay && StringToInt(cvarValue) == 1)
    {    	
		if ((GetTime() - g_times[client]) > GetConVarInt(g_cvars[CVAR_THRESHOLD]) && tempListeningFlags != VOICE_MUTED) 
		{
			decl String:message[256];
			GetConVarString(g_cvars[CVAR_MUTEMSG], message, sizeof(message));			
			PrintToChat(client, "%c%s", 4, message);
			LogMessage("%L triggered anti-micspam protection, muting", client);			
			saveListeningFlags[client] = tempListeningFlags;
			SetClientListeningFlags(client, VOICE_MUTED);
		}
    }
    else 
    {
		g_times[client] = GetTime();
		
		if (saveListeningFlags[client] != -1 && saveListeningFlags[client] != tempListeningFlags && tempListeningFlags == VOICE_MUTED) 
		{
			LogMessage("%L triggered anti-micspam protection, un-muting", client);
			SetClientListeningFlags(client, saveListeningFlags[client]);
			saveListeningFlags[client] = -1;
		}
    }
}

