#include <sourcemod>
#include <basecomm>
#include <sdktools>

#define PLUGIN_NAME             "[L4D2] Voice Viewer"
#define PLUGIN_DESCRIPTION      "See who is speaking on server(4+ players), limit maximum time for a single voice"
#define PLUGIN_VERSION          "1.6"
#define PLUGIN_AUTHOR           "oblivcheck/Iciaria"
#define PLUGIN_URL              "https://forums.alliedmods.net/showthread.php?p=2810611"

/*	Changes Log
2024-01-24 (1.6)
	- Fixed: when a player is muted, open or close the micwill still cause messages to appear in the chat. Reported by "S.A.S".

2024-01-23 (1.5)
	- If the value of Cvar "l4d2_voiceviewer_type" contains 8: When a player starts speaking or stops speaking, print a message in the chat that is instant. requested by "S.A.S".
	- If the value of Cvar "l4d2_voiceviewer_name_max_length" is 0, there is no limit to the length of the displayed player name.
	- Cvar default value change.

2023-12-13 (1.4)
	- EMS HUD support, requested by "S.A.S".
	- If the player's name is too long, it will be truncated.
	- New ConVars: l4d2_voiceviewer_name_max_length, l4d2_voiceviewer_emshud_Slot, l4d2_voiceviewer_emshud_XYWH, l4d2_voiceviewer_emshud_HUDBG
	- New config file: data/l4d2_voiceviewer.txt
	- Some code adjustments && ConVar default value adjustments.

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


// ******************************************************************************
// https://developer.valvesoftware.com/wiki/L4D2_EMS/Appendix:_HUD
// ******************************************************************************

// "L4D2 EMS HUD Functions" by "sorallll"
/*
enum
{
	HUD_LEFT_TOP,
	HUD_LEFT_BOT,
	HUD_MID_TOP,
	HUD_MID_BOT,
	HUD_RIGHT_TOP,
	HUD_RIGHT_BOT,
	HUD_TICKER,
	HUD_FAR_LEFT,
	HUD_FAR_RIGHT,
	HUD_MID_BOX,
	HUD_SCORE_TITLE,
	HUD_SCORE_1,
	HUD_SCORE_2,
	HUD_SCORE_3,
	HUD_SCORE_4
};
*/

// https://github.com/accelerator74/sp-plugins/blob/2ce16cfc3abd673ced16e98cf15bc16a7d0a4d11/l4d2_SpeakingList/SpeakingList.sp#L31C1-L48
#define HUD_FLAG_PRESTR			(1<<0)	//	do you want a string/value pair to start(pre) or end(post) with the static string (default is PRE)
#define HUD_FLAG_POSTSTR		(1<<1)	//	ditto
#define HUD_FLAG_BEEP			(1<<2)	//	Makes a countdown timer blink
#define HUD_FLAG_BLINK			(1<<3)	//	do you want this field to be blinking
#define HUD_FLAG_AS_TIME		(1<<4)	//	to do..
#define HUD_FLAG_COUNTDOWN_WARN	(1<<5)	//	auto blink when the timer gets under 10 seconds
#define HUD_FLAG_NOBG			(1<<6)	//	dont draw the background box for this UI element
#define HUD_FLAG_ALLOWNEGTIMER	(1<<7)	//	by default Timers stop on 0:00 to avoid briefly going negative over network, this keeps that from happening
#define HUD_FLAG_ALIGN_LEFT		(1<<8)	//	Left justify this text
#define HUD_FLAG_ALIGN_CENTER	(1<<9)	//	Center justify this text
#define HUD_FLAG_ALIGN_RIGHT	(3<<8)	//	Right justify this text
#define HUD_FLAG_TEAM_SURVIVORS	(1<<10)	//	only show to the survivor team
#define HUD_FLAG_TEAM_INFECTED	(1<<11)	//	only show to the special infected team
#define HUD_FLAG_TEAM_MASK		(3<<10)	//	link HUD_FLAG_TEAM_SURVIVORS and HUD_FLAG_TEAM_INFECTED
#define HUD_FLAG_UNKNOWN1		(1<<12)	//	?
#define HUD_FLAG_TEXT			(1<<13)	//	?
#define HUD_FLAG_NOTVISIBLE		(1<<14)	//	if you want to keep the slot data but keep it from displaying


ConVar	g_hEnable;
ConVar	g_hLimit;
ConVar	g_hReset;
ConVar	g_hInterval;
ConVar	g_hType;
//ConVar	g_hTitle;
ConVar	g_hNameLen;
ConVar	g_hSlot;
ConVar	g_hXYWH;
ConVar	g_hHUDBG;

bool	g_bEnable;
int	g_iLimit;
int	g_iReset;
float	g_fInterval;
int	g_iType;
//char	g_sTitle[64];
int	g_iNameLen;
int	g_iSlot;
char	g_sXYWH[32];
bool	g_bHUDBG;

Handle	g_tUpdateInterval;

int	g_iTalkingTime[MAXPLAYERS+1]
bool	g_bClientIsTalking[MAXPLAYERS+1];
bool	g_bIsClientMuted[MAXPLAYERS+1];
float	g_fXYWH[4];
char	g_sTitle[64];

public void OnPluginStart()
{
	LoadTranslations("l4d2_voiceviewer.phrases");
	GetHUDTitle();

	HookEvent("player_disconnect", Event_PlayerDisconnect, EventHookMode_Post);
	HookEvent("round_start", Event_RoundStart);

	CreateConVar("l4d2_voiceviewer_version", PLUGIN_VERSION , "Plugin Version.", FCVAR_NOTIFY|FCVAR_DONTRECORD);

	g_hEnable = CreateConVar("l4d2_voiceviewer_enable", "1", "Enable or Disable");
	g_hLimit = CreateConVar("l4d2_voiceviewer_limit", "90", "Time limit for sending voice.\nTime(s) = l4d2_voiceviewer_interval * l4d2_voiceviewer_limit");
	g_hReset = CreateConVar("l4d2_voiceviewer_reset", "90", "Time to wait for restrictions to be lifted\nTime(s) = l4d2_voiceviewer_interval * l4d2_voiceviewer_reset");
	g_hInterval = CreateConVar("l4d2_voiceviewer_interval", "0.5", "Check interval.");
	g_hType = CreateConVar("l4d2_voiceviewer_type", "2", "Where to print voice messages?\n0 = Disable, 1= EMS HUD, 2 = HintText, 4 = CenterText, 8 = when a player starts speaking or stops speaking, print a message in the chat that is instant.\nAdd to get all");
//	g_hTitle = CreateConVar("l4d2_voiceviewer_emshud_title", "正在说话的玩家 🔊", "");
	g_hNameLen = CreateConVar("l4d2_voiceviewer_name_max_length", "0", "If the byte length of the player's name exceeds a certain value, it will be truncated.\nInt Value, 0 = disable, Do NOT larger than 48.");
	g_hSlot = CreateConVar("l4d2_voiceviewer_emshud_Slot", "1", "EMS HUD Slot used for display, See:\nhttps://developer.valvesoftware.com/wiki/L4D2_EMS/Appendix:_HUD\nhttps://github.com/oblivcheck/l4d2_plugins/blob/eb43f95fd4e60bbfdaff84616221ac8367d2ec7f/l4d2_voiceviewer/scripting/l4d2_voiceviewer.sp#L46-L90");
	g_hXYWH = CreateConVar("l4d2_voiceviewer_emshud_XYWH", "0.0 0.75 1.0 0.05", "X,Y position and Width and Height, See:\nhttps://developer.valvesoftware.com/wiki/L4D2_EMS/Appendix:_HUD");
	g_hHUDBG = CreateConVar("l4d2_voiceviewer_emshud_HUDBG", "0", "1 = Draw a black background for the selected EMS HUD Slot.(Check XYWH)\nNote: You need to rejoin the target server for this change to take effect on the client.");

	g_bEnable = g_hEnable.BoolValue;
	g_iLimit = g_hLimit.IntValue;
	g_iReset = g_hReset.IntValue;
	g_fInterval= g_hInterval.FloatValue;
	g_iType = g_hType.IntValue;
//	g_hTitle.GetString(g_sTitle, sizeof(g_sTitle) );
	g_iNameLen = g_hNameLen.IntValue;
	g_iSlot = g_hSlot.IntValue;
	g_hXYWH.GetString(g_sXYWH, sizeof(g_sXYWH) );
	g_bHUDBG = g_hHUDBG.BoolValue;

	GetHUD_XYWH(g_sXYWH);

	AutoExecConfig(true, "l4d2_voiceviewer");

	g_hEnable.AddChangeHook(Event_ConVarChanged);
	g_hLimit.AddChangeHook(Event_ConVarChanged);
	g_hReset.AddChangeHook(Event_ConVarChanged);
	g_hInterval.AddChangeHook(Event_ConVarChanged);
	g_hType.AddChangeHook(Event_ConVarChanged);
//	g_hTitle.AddChangeHook(Event_ConVarChanged);
	g_hNameLen.AddChangeHook(Event_ConVarChanged);
	g_hSlot.AddChangeHook(Event_ConVarChanged);
	g_hXYWH.AddChangeHook(Event_ConVarChanged);
	g_hHUDBG.AddChangeHook(Event_ConVarChanged);	
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
//	g_hTitle.GetString(g_sTitle, sizeof(g_sTitle) );
	g_iNameLen = g_hNameLen.IntValue;
	g_iSlot = g_hSlot.IntValue;
	g_hXYWH.GetString(g_sXYWH, sizeof(g_sXYWH) );
	g_bHUDBG = g_hHUDBG.BoolValue;

	GetHUD_XYWH(g_sXYWH);

	// Disable
	if(g_bEnable_old &&!g_bEnable)
	{
		UnhookEvent("player_disconnect", Event_PlayerDisconnect, EventHookMode_Post);
		UnhookEvent("round_start", Event_RoundStart);

		if(IsValidHandle(g_tUpdateInterval) )
			delete g_tUpdateInterval;
		Refresh();
	}
	// Enable
	if(!g_bEnable_old && g_bEnable)
	{
		HookEvent("player_disconnect", Event_PlayerDisconnect, EventHookMode_Post);
		HookEvent("round_start", Event_RoundStart);

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

	if(g_iType & 8)
	{
		if(!g_bClientIsTalking[client] && !g_bIsClientMuted[client])
			PrintHintInChat(client, true);
	}

	g_bClientIsTalking[client] = true;
}

public void OnClientSpeakingEnd(int client)
{
	if(!g_bEnable)	return;
	g_bClientIsTalking[client] = false;

	if(!g_bIsClientMuted[client] )
		g_iTalkingTime[client] = 0;

	if((g_iType & 8) && !g_bIsClientMuted[client])
		PrintHintInChat(client, false);
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


public void Event_RoundStart(Event hEvent, const char[] strName, bool DontBroadcast)
{
	HudSet(g_iSlot);
}

//---------------------------------------------------------------------------||
//              Check client
//---------------------------------------------------------------------------||
#define	MSG_BUFFER_SIZE		512

Action UpdateHint(Handle timer)
{
	static char sMSG[MSG_BUFFER_SIZE];
	static char buffer[MSG_BUFFER_SIZE];	
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
			
			if(g_iNameLen > 0)
			{
				// Notice: null terminator
				char name[49];
				if (Format(name, sizeof(name), "%N", i) > g_iNameLen )
				{
					Format(name, g_iNameLen+1, "%s", name);
					Format(buffer, sizeof(buffer), "%s%s... ", sMSG, name);
				}
				else	Format(buffer, sizeof(buffer), "%s%s ", sMSG, name);
			}
			else	Format(buffer, sizeof(buffer), "%s%N ", sMSG, i);

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
		if(g_iType & 1)
			UpdateHUD(g_iSlot, sMSG);

		if(g_iType & 2)
			PrintHintTextToAll("%t", "talking", sMSG);
		
		if(g_iType & 4)
			PrintCenterTextAll("%t", "talking", sMSG);


		Format(sMSG, 1, "");
		AllowPrint = false;
	}
	else	if(g_iType & 1) UpdateHUD(g_iSlot, "");
	
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

#define EMSHUD_FLAG				HUD_FLAG_ALIGN_CENTER | HUD_FLAG_TEXT | HUD_FLAG_NOBG

stock void HudSet(int slot)
{
	GameRules_SetProp("m_iScriptedHUDFlags", g_bHUDBG ? EMSHUD_FLAG & ~HUD_FLAG_NOBG : EMSHUD_FLAG, _, slot);
	GameRules_SetPropFloat("m_fScriptedHUDPosX", g_fXYWH[0], slot, true);
	GameRules_SetPropFloat("m_fScriptedHUDPosY", g_fXYWH[1], slot, true);
	GameRules_SetPropFloat("m_fScriptedHUDWidth", g_fXYWH[2], slot, true);
	GameRules_SetPropFloat("m_fScriptedHUDHeight", g_fXYWH[3], slot, true);	
}
stock void UpdateHUD(int slot, const char[] msg)
{	
	if(g_bHUDBG)	HudSet(slot);

	char buffer[MSG_BUFFER_SIZE];
	if(msg[0] )		
		Format(buffer, sizeof(buffer), "%s\n%s", g_sTitle, msg);

	GameRules_SetPropString("m_szScriptedHUDStringSet", buffer, true, slot);
}

stock void GetHUD_XYWH(const char[] sXYWH)
{
	char buffer[8][4];
	ExplodeString(sXYWH, " ", buffer, 4, 8);
	for(int i=0; i<4;i++)
		g_fXYWH[i] = StringToFloat(buffer[i]);
}

stock void GetHUDTitle()
{
	char path[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, path, PLATFORM_MAX_PATH, "data/l4d2_voiceviewer.txt");
	bool hasTitle = FileExists(path);
	if (hasTitle)
	{
		File hFile;
		hFile = OpenFile(path, "rb");
		if(hFile != null )
		{
			int len = FileSize(path);
			hFile.ReadString(g_sTitle, sizeof(g_sTitle), len-1);
			delete hFile;
		}
	}
	else
	{	
		LogError("[%s %s] File cannot be found: data/l4d2_voiceviewer.txt! Please check the server config file...", PLUGIN_NAME, PLUGIN_VERSION);
		Format(g_sTitle, sizeof(g_sTitle), "ERR: File cannot be found: data/l4d2_voiceviewer.txt! Please check the server config file...");
	}
}

//stock void PrintHintInChat(int client, bool start, bool mute=false)
stock void PrintHintInChat(int client, bool start)
{
/*
	if(mute)
		PrintToChatAll(client, "\x04%t", "Chat_PlayerMuted", client);
*/
	if(start)
		PrintToChatAll("\x04%t", "Chat_PlayerSpeaking", client);
	else	PrintToChatAll("\x04%t", "Chat_PlayerSpeakingEnd", client);
}
