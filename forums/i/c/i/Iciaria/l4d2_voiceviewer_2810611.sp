#include <sourcemod>
#include <basecomm>

#define PLUGIN_NAME             "[L4D2] Voice Viewer"
#define PLUGIN_DESCRIPTION      "See who is speaking on server(4+ players), limit maximum time for a single voice"
#define PLUGIN_VERSION          "1.3"
#define PLUGIN_AUTHOR           "Iciaria"
#define PLUGIN_URL              "https://forums.alliedmods.net/showthread.php?p=2810611"

/*	Change Logs
2023-10-01 (1.3)
	- Fixed: Client is not in game.

2023-09-28 (1.2)
	- Limits are no longer reset during chapter transitions.
	- Fixed: multiple identical timers accidentally created.
	- Fixed: after the plugin is disable, it will have no effect when it is enabled again.
	- Changed wrong comment: l4d2_voiceviewer_reset(Time(s) = l4d2_voiceviewer_interval * l4d2_voiceviewer_reset).

2023-09-28 (1.1)
	- Added translation files provided by "Peter Brev", including new English translation and French translation.

2023-09-27 (1.0)
	- Initial version.

*/

public Plugin:myinfo =
{
        name = PLUGIN_NAME,
        author = PLUGIN_AUTHOR,
        description = PLUGIN_DESCRIPTION,
        version = PLUGIN_VERSION,
        url = PLUGIN_URL
}

ConVar	g_hEnable;
ConVar	g_hLimit;
ConVar	g_hReset;
ConVar	g_hInterval;
ConVar	g_hType;

bool	g_bEnable;
int	g_iLimit;
int	g_iReset;
float	g_fInterval;
int	g_iType;

Handle	g_tUpdateInterval;

int	g_iTalkingTime[MAXPLAYERS+1]
bool	g_bClientIsTalking[MAXPLAYERS+1];
bool	g_bIsClientMuted[MAXPLAYERS+1];


public void OnPluginStart()
{
	LoadTranslations("l4d2_voiceviewer.phrases");
	HookEvent("player_disconnect", Event_PlayerDisconnect, EventHookMode_Post);

	CreateConVar("l4d2_voiceviewer_version", PLUGIN_VERSION , "Plugin Version.", FCVAR_NOTIFY|FCVAR_DONTRECORD);

	g_hEnable = CreateConVar("l4d2_voiceviewer_enable", "1", "Enable or Disable");
	g_hLimit = CreateConVar("l4d2_voiceviewer_limit", "60", "Time limit for sending voice.\nTime(s) = l4d2_voiceviewer_interval * l4d2_voiceviewer_limit\n");
	g_hReset = CreateConVar("l4d2_voiceviewer_reset", "240", "Time to wait for restrictions to be lifted\nTime(s) = l4d2_voiceviewer_interval * l4d2_voiceviewer_reset\n");
	g_hInterval = CreateConVar("l4d2_voiceviewer_interval", "0.5", "Check interval.");
	g_hType = CreateConVar("l4d2_voiceviewer_type", "2", "Where to print voice messages?\n0 = Disable, 2 = HintText, 4 = CenterText; Add to get all\n");
	
	g_bEnable = g_hEnable.BoolValue;
	g_iLimit = g_hLimit.IntValue;
	g_iReset = g_hReset.IntValue;
	g_fInterval= g_hInterval.FloatValue;
	g_iType = g_hType.IntValue;

	AutoExecConfig(true, "l4d2_voiceviewer");

	g_hEnable.AddChangeHook(Event_ConVarChanged);
	g_hLimit.AddChangeHook(Event_ConVarChanged);
	g_hReset.AddChangeHook(Event_ConVarChanged);
	g_hInterval.AddChangeHook(Event_ConVarChanged);
	g_hType.AddChangeHook(Event_ConVarChanged);
}

bool	g_bEnable_old;
public void Event_ConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_bEnable_old = g_bEnable;

	g_bEnable = g_hEnable.BoolValue;
	g_iLimit = g_hLimit.IntValue;
	g_iReset = g_hReset.IntValue;
	g_fInterval = g_hInterval.FloatValue;	
	g_iType = g_hType.IntValue;

	// Disable
	if(g_bEnable_old &&!g_bEnable)
	{
		UnhookEvent("player_disconnect", Event_PlayerDisconnect, EventHookMode_Post);
		if(IsValidHandle(g_tUpdateInterval) )
			delete g_tUpdateInterval;
		Refresh();
	}
	// Enable
	if(!g_bEnable_old && g_bEnable)
	{
		HookEvent("player_disconnect", Event_PlayerDisconnect, EventHookMode_Post);

		if(IsValidHandle(g_tUpdateInterval) )
			delete g_tUpdateInterval;
		g_tUpdateInterval = CreateTimer(g_fInterval, UpdateHint, _, TIMER_REPEAT);
		Refresh();
	}
}

public void OnConfigsExecuted()
{
	if(!IsValidHandle(g_tUpdateInterval) )
		g_tUpdateInterval = CreateTimer(g_fInterval, UpdateHint, _, TIMER_REPEAT);		
}
//---------------------------------------------------------------------------||
//              Set mark
//---------------------------------------------------------------------------||
public void BaseComm_OnClientMute(int client, bool muteState)
{
	if(!g_bEnable)	return;
	if(muteState)
		g_bIsClientMuted[client] = true;
	else	
		g_bIsClientMuted[client] = false;
}

public void OnClientSpeaking(int client)
{
	if(!g_bEnable)	return;
	g_bClientIsTalking[client] = true;
}

public void OnClientSpeakingEnd(int client)
{
	if(!g_bEnable)	return;
	g_bClientIsTalking[client] = false;

	if(!g_bIsClientMuted[client] )
		g_iTalkingTime[client] = 0;
}

Action Event_PlayerDisconnect(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event,"userid"));
	if (!(1 <= client <= MaxClients))
		return Plugin_Continue;

	g_bClientIsTalking[client] = false;
	g_bIsClientMuted[client] = false;
	g_iTalkingTime[client] = 0;	

	return Plugin_Continue;
}
//---------------------------------------------------------------------------||
//              Check client
//---------------------------------------------------------------------------||
Action UpdateHint(Handle timer)
{
	static char sMSG[256];
	static char buffer[256];	
	static bool AllowPrint;
	for(int i=1;i<=MaxClients;i++)
	{
		if(!IsClientInGame(i) )
			continue;

		if(g_bClientIsTalking[i] )
		{
			if(BaseComm_IsClientMuted(i))
				continue;

			g_iTalkingTime[i]++;
			if(g_iTalkingTime[i] > g_iLimit)
			{
				BaseComm_SetClientMute(i, true);
				g_iTalkingTime[i] = g_iReset;

				PrintToChatAll("\x04%t", "ChatAll", i);
				PrintToChat(i, "\x03%t", "Chat", RoundToCeil(g_iReset * g_fInterval) );

				continue;
			}

			Format(buffer, sizeof(buffer), "%s%N ", sMSG, i);
			Format(sMSG, sizeof(sMSG), "%s ", buffer);
			AllowPrint = true;	
		}
		else
		{
			if(g_bIsClientMuted[i])
			{
				g_iTalkingTime[i]--;
				
				if(g_iTalkingTime[i] <= 0 )
				{
					PrintToChat(i, "\x03%t", "Restrictions lifted");
					BaseComm_SetClientMute(i, false);
				}

				continue;
			}
		}
	}
	if(AllowPrint)
	{
		if(g_iType & 2)
			PrintHintTextToAll("%t", "talking", sMSG);
		
		if(g_iType & 4)
			PrintCenterTextAll("%t", "talking", sMSG);

		// EMS HUD? Maby later...

		Format(sMSG, 1, "");
		AllowPrint = false;
	}
	
	return Plugin_Continue;
}
//---------------------------------------------------------------------------||
//              Stock
//---------------------------------------------------------------------------||
stock void Refresh()
{
	for(int client=1; client<=MaxClients; client++)
	{
		g_bClientIsTalking[client] = false;
		g_bIsClientMuted[client] = false;
		g_iTalkingTime[client] = 0;
	}
}

