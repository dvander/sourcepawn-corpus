#define PLUGIN_VERSION "4.1"

#pragma newdecls required
#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#define GAMEDATA			"l4d_incapped_pills_pop"
#define SOUND_HEARTBEAT	 	"player/heartbeatloop.wav"
#define STANDUP_SOUND 		"player/items/pain_pills/pills_use_1.wav"
#define DEBUG 0
#define CVAR_FLAGS			FCVAR_NOTIFY

enum ITEM_TYPE
{
	ITEM_MEDKIT 		= 1 << 0,
	ITEM_PILLS			= 1 << 1,
	ITEM_ADRENALINE		= 1 << 2,
	ITEM_NONE			= 0
}

enum MSG_POS
{
	MSG_POS_CHAT 	= 1 << 0,
	MSG_POS_HINT 	= 1 << 1,
	MSG_POS_CENTER 	= 1 << 2,
	MSG_POS_CHAT_HINT = 1 << 3
}

bool 	g_bIsBeingRevived[MAXPLAYERS+1], g_bIncapDelay[MAXPLAYERS+1], g_bMapStarted, g_bForbidInReviving, g_bDisableHeartbeat, g_bLeft4dead2;
bool 	g_bHeartbeatPlugin, g_bEnabled, g_bAllowHelpIncapSlot3, g_bAllowHelpIncapSlot4, g_bAllowReleaseSlot3, g_bAllowReleaseSlot4, g_bAllowHelpLedgeSlot3, g_bAllowHelpLedgeSlot4;
int 	g_iIncapCountOffset, g_iTempHpOffset, g_iMaxIncaps, g_iIncapCount[MAXPLAYERS+1], g_iShowMsgAll, g_iUseButton, g_iShowWarning;
ConVar 	g_hCvarDelaySetting, g_hCvarForbidInReviving, g_hCvarReviveHealth, g_hCvarDisableHeartbeat, g_hCvarMaxIncap, g_hCvarShowMsgAll, g_hCvarMsgPos, g_hCvarMsgAdvertPos;
ConVar 	g_hCvarButton, g_hCvarEnable, g_hCvarHelpItems, g_hCvarHelpItemsLedge, g_hCvarReleaseItems, g_hCvarMsgWarning;
float	g_fDelaySetting, g_fReviveTempHealth = 30.0, g_fPressTime[MAXPLAYERS+1];
Handle 	g_hSDK_OnSavedFromLedgeHang;
Address g_iOffsetMusic;
 
ITEM_TYPE g_eHelpItemsIncap, g_eHelpItemsLedge, g_eReleaseItems;
MSG_POS g_iMsgPos, g_iMsgAdvertPos;

public Plugin myinfo = 
{
	name = "[L4D] Incapped Pills Pop",
	author = "Dragokas",
	description = "You can press the button while incapped to pop your pills / adrenaline / medkit and revive yourself",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=332094"
}

/*
	Change Log:

	1.0.2.1 (05-Nov-2018)
		 - Added convar "l4d_incappedpillspop_forbid_when_reviving" to forbid use pills when somebody revivng you (it is disabled by default).
		 - Added some safe client id pass.
		 - Cached calls to FindSendPropInfo and convar-s.
		 - "lunge_pounce" and "tongue_grab" events are replaced by client prop. checkings (more reliable).
		 - Default incap delay decreased from 2.0 sec to 0.2.
		 - Default delay between "USE" key check decreased from 1.0 to 0.5 sec.
		 - Fixed some cases with timer when it disallow to use pills (replaced by GetEngineTime() and placed on more earlier stage (for reliability).
		 - Config file renamed to l4d_incappedpillspop2.cfg.
		 - Added tranlation into Russian.

	1.0.2.2 (28-Dec-2018)
		 - Translation file and plugin are updated with phrases about adrenaline (by Mr. Man request).
		 - Added ConVar change hook.
		 - ConVar values are cached for optimization.
		 - Cleared old code, converted to new syntax and methodmaps.
		 - Version number is removed from plugin file name. 
		 
	1.0.2.3 (17-Jan-2019)
		 - Added safe flags to timers.
		 - Added more hooks for reliability.
		 - Fixed "heartbeat" sound is not played when you use pills and become black/white.
		 - Added convar "l4d_disable_heartbeat" to disable heartbeat sound in game at all (by default, not disabled).

	1.0.2.4 (19-Mar-2019)
		 - Added ability to selfhelp by picking up pills / adrenaline found on the floor when you are already incapped.
		 - Added missing kill of pills / adrenaline entity.
		 - Added compatibility with HealthExploitFix by Dragokas.
		 - Added colors support in translation file.
		 - Translation file is updated.
		 - Added advertising pills message when player grabbed the ledge.
		 - Added advertising about ability to find pills / adrenaline on the floor when you became incapped.
		 
	1.0.2.5 (14-Jan-2020)
		 - Added ConVar "l4d_incappedpillspop_show_msg_all" - Show message to all about player selfhelp action (1 - Yes / 0 - No)
		 
	1.0.2.6 (22-12-2020)
		 - Fixed ugly sound sometimes doesn't disappear (thanks to Re:Creator for fix).
	
	2.0 (23-Apr-2021)
		 - Improved music stop fix.
		 - Fixed bug: *_spawned classes: weapon_pain_pills_spawn and weapon_adrenaline_spawn are not checked on the floor.
		 - Improved bug-fix: other player could become frozen if you force pop pills while he tries to revive you.
		 - Prevented opportunity to use pills when been attacked by charger or jockey.
		 - Added missing ConVars for tracking the changes.
		 - Simplified & beautified the code, removed useless timers, Less useless hooks.
		 - Added ConVar "l4d_incappedpillspop_enable" - Enable this plugin? (1 - Yes, 0 - No).
		 - Added ConVar "l4d_incappedpillspop_button" - What button to press for self-help? 2 - Jump, 4 - Duck, 32 - Use. You can combine.
		 - Added ConVar "l4d_incappedpillspop_allow_adrenaline" - (L4D2 only) Allow pop adrenaline? (1 - Yes / 0 - No).
		 - Splitted messages:
			* hint, when you incapacitated and when you hanging the ledge.
			* hint, suggesting you to press the specific button to reflect the settings defined by ConVar.
			* info, depending on whether somebody used his own pills or found them on the floor.
		 - New requirements:
			* SourceMod 1.10+
			* DHooks Detours v.2.2.0.15+
		
		To make this update works properly, be sure to update the following plugins to the latest version (if you use them):
			* Health Exploit Fix (for L4D1): https://forums.alliedmods.net/showthread.php?t=314573
			* Ledge Release: https://forums.alliedmods.net/showthread.php?t=316508

	2.1 (25-Apr-2021)
	 - Fixed "l4d_incappedpillspop_enable" ConVar is not worked.
	 
	2.2 (11-May-2021)
	 - Added ability to use medkit (thanks to @Voevoda for donation).
	 - Added new ConVar "l4d_incappedpillspop_allow_medkit" - Allow stand-up with first aid kit? (1 - Yes / 0 - No)
	 - Added new ConVar "l4d_incappedpillspop_allow_pills" - Allow pop pills? (1 - Yes / 0 - No)
	 - Translation file is updated.
	 
	2.3 (01-Jun-2021)
	 - Fixed hint messages from throwing errors.
	
	2.4 (02-Jun-2021)
	 - Added ability to kill special infected, which grabbed you (see ConVar "l4d_incappedpillspop_allow_kill").
	
	2.5 (20-Jul-2021)
	 - Added Portuguese translation (thanks to King_OXO).
	 
	2.6 (20-Aug-2021)
	 - Chinese translation (Simplified & Traditional) has been added.
	 
	2.7 (01-Nov-2021)
	 - Prevented "Get off infected" message from appearing in "allow_kill" mode.
	 - Added protection from self-help when you press Ctrl + E (prevents a conflict with "Revive and CPR" plugin).
	 
	3.0 (22-Dec-2021)
	
	WARNING: this release breaking ConVar compatibility with any 1.x and 2.x versions. Remove your l4d_incappedpillspop2.cfg file!
	
	Now, you can split items allowed for stand up, and items allowed for releasing from infected.
	
	* Added ConVars:
	 - "l4d_incappedpillspop_msg_pos" - Position of the selfhelp message (0 - Don't show, 1 - Chat, 2 - Hint, 4 - Center screen).
	 - "l4d_incappedpillspop_help_items" - Allow to pop with these items (1 - Medkit, 2 - Pills, 4 - Adrenaline (can be combined)
	 - "l4d_incappedpillspop_release_items" - Allow to release from infected with these items (0 - Don't allow, 1 - Medkit, 2 - Pills, 4 - Adrenaline (can be combined)
	
	* Removed the following ConVars:
	 - "l4d_incappedpillspop_allow_adrenaline"
	 - "l4d_incappedpillspop_allow_medkit"
	 - "l4d_incappedpillspop_allow_pills"
	 - "l4d_incappedpillspop_allow_kill"
	
	3.1 (21-Jan-2022)
	 - Added reliable way to stop the music via SDKCall to "Music" class.
	 - Hanging sound is restored as it should be by design.
	 - Added ConVar "l4d_incappedpillspop_msgadvert_pos" - Position of advertise selfhelp keys message (0 - Don't show, 1 - Chat, 2 - Hint, 4 - Center screen)
	 - Fixed compilation warnings on SM 1.11.
	
	4.0 (26-Jan-2022)
	
	WARNING: this release require a new dependency!
	
	 - Fixed the advertise message displayed the wrong item name.
	 - Fixed redunant /// characters in messages.
	 - Removed pointless "You have no ..." advertise message.
	 - Fixed Black & White didn't work on L4D2 (thanks to Silvers).
	 - Heartbeat plugin detection code is changed according to new recomendations.
	 - Fixed heartbeat sound is not stopped after healing.
	 - Fixed animation is not stopped when you self-helped during somebody tried to revive you.
	 - Added compatibility with AdminCheats plugin.
	 - Broadcasting "revive_success" event when self-help used.
	 - New dependency: Heartbeat (Revive Fix - Post Revive Options) by SilverShot: 	 https://forums.alliedmods.net/showthread.php?t=322132
	 - Added ConVar "l4d_incappedpillspop_msg_warn" - Show warning messages, e.g. when you have no pills? (0 - No, 1 - Yes)
	 - Added ConVar "l4d_incappedpillspop_help_ledge_items" - Allow to pop with these items from hangind the ledge (0 - Don't allow, 1 - Medkit, 2 - Pills, 4 - Adrenaline (can be combined)
	 - Changed ConVar meaning and allowed values for "l4d_incappedpillspop_help_items" - is now means incapped self-help only. New value is added: 0 - Don't allow
	 - Added more safe checks.
	 
	It is suggested to remove cfg/sourcemod/l4d_incappedpillspop2.cfg config file to allow re-create it again.
	
	4.1 (27-Jan-2022)
	 - Fixed B&W state set at incorrect time (due to double "revive_success" event, one more from "give" command), intercepted by Heartbeat plugin.
	 - Fixed player cannot die when B&W (bug in Heartbeat plugin?).
*/

native void Heartbeat_SetRevives(int client, int reviveCount, bool reviveLogic = true);
native int Heartbeat_GetRevives(int client);

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion test = GetEngineVersion();
	if( test == Engine_Left4Dead2 ) {
		g_bLeft4dead2 = true;
	}
	else if( test != Engine_Left4Dead ) {
		strcopy(error, err_max, "Plugin only supports Left 4 Dead 1 & 2.");
		return APLRes_SilentFailure;
	}
	MarkNativeAsOptional("Heartbeat_SetRevives");
	MarkNativeAsOptional("Heartbeat_GetRevives");
	return APLRes_Success;
}

public void OnPluginStart()
{
	LoadTranslations("l4d_incappedpillspop.phrases");

	CreateConVar("l4d_incappedpillspop_version2", PLUGIN_VERSION, "Plugin version", CVAR_FLAGS | FCVAR_DONTRECORD);

	g_hCvarEnable			= CreateConVar("l4d_incappedpillspop_enable", 				"1", 	"Enable this plugin? (1 - Yes, 0 - No)", CVAR_FLAGS);
	g_hCvarDelaySetting 	= CreateConVar("l4d_incappedpillspop_delaytime", 			"0.2", 	"How long before an Incapped Survivor can use pills/adrenaline", CVAR_FLAGS);
	g_hCvarForbidInReviving = CreateConVar("l4d_incappedpillspop_forbid_when_reviving", "1", 	"Forbid self-help when somebody reviving you (1 - Yes / 0 - No)", CVAR_FLAGS);
	g_hCvarDisableHeartbeat = CreateConVar("l4d_disable_heartbeat", 					"0", 	"Disable heartbeat sound in game at all (1 - Disable / 0 - Do nothing)", CVAR_FLAGS);
	g_hCvarShowMsgAll		= CreateConVar("l4d_incappedpillspop_show_msg_all", 		"1", 	"Show message to all about player selfhelp action (1 - Yes / 0 - No)", CVAR_FLAGS);
	g_hCvarMsgPos			= CreateConVar("l4d_incappedpillspop_msg_pos", 				"1", 	"Position of the selfhelp action message (0 - Don't show, 1 - Chat, 2 - Hint, 4 - Center screen, 8 - Chat + Hint)", CVAR_FLAGS);
	g_hCvarMsgAdvertPos		= CreateConVar("l4d_incappedpillspop_msgadvert_pos", 		"1", 	"Position of advertise selfhelp keys message (0 - Don't show, 1 - Chat, 2 - Hint, 4 - Center screen, 8 - Chat + Hint)", CVAR_FLAGS);
	g_hCvarMsgWarning		= CreateConVar("l4d_incappedpillspop_msg_warn", 			"1", 	"Show warning messages, e.g. when you have no pills? (0 - No, 1 - Yes)", CVAR_FLAGS);
	g_hCvarButton 			= CreateConVar("l4d_incappedpillspop_button", 				"32", 	"What button to press for self-help? 2 - Jump, 4 - Duck, 32 - Use. You can combine.", CVAR_FLAGS);
	g_hCvarHelpItems		= CreateConVar("l4d_incappedpillspop_help_items",			"7", 	"Allow to pop with these items from incap (0 - Don't allow, 1 - Medkit, 2 - Pills, 4 - Adrenaline (can be combined)", CVAR_FLAGS);
	g_hCvarHelpItemsLedge	= CreateConVar("l4d_incappedpillspop_help_ledge_items",		"7", 	"Allow to pop with these items from hangind the ledge (0 - Don't allow, 1 - Medkit, 2 - Pills, 4 - Adrenaline (can be combined)", CVAR_FLAGS);
	g_hCvarReleaseItems		= CreateConVar("l4d_incappedpillspop_release_items",		"7", 	"Allow to release from infected with these items (0 - Don't allow, 1 - Medkit, 2 - Pills, 4 - Adrenaline (can be combined)", CVAR_FLAGS);
	
	AutoExecConfig(true, "l4d_incappedpillspop2");
	
	g_hCvarReviveHealth = FindConVar("survivor_revive_health");
	g_hCvarMaxIncap = FindConVar("survivor_max_incapacitated_count");
	
	g_iIncapCountOffset = FindSendPropInfo("CTerrorPlayer", "m_currentReviveCount");
	g_iTempHpOffset = FindSendPropInfo("CTerrorPlayer", "m_healthBuffer");
	
	char sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof(sPath), "gamedata/%s.txt", GAMEDATA);
	
	GameData hGameData = LoadGameConfigFile(GAMEDATA);
	if( hGameData == null ) SetFailState("Failed to load \"%s.txt\" gamedata.", GAMEDATA);
	
	g_iOffsetMusic = view_as<Address>(hGameData.GetOffset("CMusic"));
	
	StartPrepSDKCall(SDKCall_Raw);
	if (!PrepSDKCall_SetFromConf(hGameData, SDKConf_Virtual, "Music::OnSavedFromLedgeHang"))
		SetFailState("Could not load the \"Music::OnSavedFromLedgeHang\" gamedata signature.");
	g_hSDK_OnSavedFromLedgeHang = EndPrepSDKCall();
	if( g_hSDK_OnSavedFromLedgeHang == null )
		SetFailState("Could not prep the \"Music::OnSavedFromLedgeHang\" function.");
	
	delete hGameData;
	
	GetCvars();
	
	g_hCvarEnable.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarDelaySetting.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarForbidInReviving.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarDisableHeartbeat.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarShowMsgAll.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarMsgPos.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarMsgAdvertPos.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarMsgWarning.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarButton.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarMaxIncap.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarReviveHealth.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarHelpItems.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarHelpItemsLedge.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarReleaseItems.AddChangeHook(ConVarChanged_Cvars);
	
	#if DEBUG
	RegAdminCmd("sm_pill", CmdPill, ADMFLAG_ROOT);
	#endif
}

#if DEBUG
public Action CmdPill(int client, int argc)
{
	// l4d_airport04_terminal
	int entity = CreateEntityByName("weapon_pain_pills_spawn");
	if( entity != -1 )
	{
		TeleportEntity(entity, view_as<float>({2059.37, 2375.46, 63.15}), NULL_VECTOR, NULL_VECTOR);
		DispatchSpawn(entity);
	}
	return Plugin_Handled;
}
#endif

public void OnLibraryAdded(const char[] name)
{
    if( strcmp(name, "l4d_heartbeat") == 0 )
    {
        g_bHeartbeatPlugin = true;
    }
}

public void OnLibraryRemoved(const char[] name)
{
    if( strcmp(name, "l4d_heartbeat") == 0 )
    {
        g_bHeartbeatPlugin = false;
    }
}

public void OnAllPluginsLoaded()
{
    if( LibraryExists("l4d_heartbeat") == true )
    {
        g_bHeartbeatPlugin = true;
    }
	else {
		SetFailState("You are failed at installing!\n" ...
		"Heartbeat (Revive Fix - Post Revive Options) plugin must be installed first!\n" ...
		"See: https://forums.alliedmods.net/showthread.php?t=322132");
	}
}

public void ConVarChanged_Cvars(ConVar convar, const char[] oldValue, const char[] newValue)
{
	GetCvars();
}

void GetCvars()
{
	g_bEnabled = g_hCvarEnable.BoolValue;
	g_fDelaySetting = g_hCvarDelaySetting.FloatValue;
	g_bForbidInReviving = g_hCvarForbidInReviving.BoolValue;
	g_bDisableHeartbeat = g_hCvarDisableHeartbeat.BoolValue;
	g_iShowMsgAll = g_hCvarShowMsgAll.IntValue;
	g_iMsgPos = view_as<MSG_POS>(g_hCvarMsgPos.IntValue);
	g_iMsgAdvertPos = view_as<MSG_POS>(g_hCvarMsgAdvertPos.IntValue);
	g_iShowWarning = g_hCvarMsgWarning.IntValue;
	g_fReviveTempHealth = g_hCvarReviveHealth.FloatValue;
	g_iMaxIncaps = g_hCvarMaxIncap.IntValue;
	g_iUseButton = g_hCvarButton.IntValue;
	g_eHelpItemsIncap = view_as<ITEM_TYPE>(g_hCvarHelpItems.IntValue);
	g_eHelpItemsLedge = view_as<ITEM_TYPE>(g_hCvarHelpItemsLedge.IntValue);
	g_eReleaseItems = view_as<ITEM_TYPE>(g_hCvarReleaseItems.IntValue);
	
	g_bAllowHelpLedgeSlot3 = !!(g_eHelpItemsLedge & ITEM_MEDKIT);
	g_bAllowHelpLedgeSlot4 = !!(g_eHelpItemsLedge & ( ITEM_PILLS | ITEM_ADRENALINE ) );
	
	g_bAllowHelpIncapSlot3 = !!(g_eHelpItemsIncap & ITEM_MEDKIT);
	g_bAllowHelpIncapSlot4 = !!(g_eHelpItemsIncap & ( ITEM_PILLS | ITEM_ADRENALINE ) );

	g_bAllowReleaseSlot3 = !!(g_eReleaseItems & ITEM_MEDKIT);
	g_bAllowReleaseSlot4 = !!(g_eReleaseItems & ( ITEM_PILLS | ITEM_ADRENALINE ) );
	
	InitHook();
}

void InitHook()
{
	static bool bHooked;

	if( g_bEnabled )
	{
		if( !bHooked )
		{
			HookEvent("player_incapacitated", 	Event_Incap);
			HookEvent("player_ledge_grab", 		Event_LedgeGrab);
			HookEvent("revive_begin", 			Event_StartRevive);
			HookEvent("revive_end", 			Event_EndRevive);
			HookEvent("revive_success", 		Event_EndRevive);
			HookEvent("heal_success", 			Event_EndRevive);
			HookEvent("player_spawn", 			Event_PlayerSpawn);
			HookEvent("round_end", 				Event_RoundEnd,		EventHookMode_PostNoCopy);
			HookEvent("round_start", 			Event_RoundStart,	EventHookMode_PostNoCopy);
			bHooked = true;
		}
	} else {
		if( bHooked )
		{
			UnhookEvent("player_incapacitated", 	Event_Incap);
			UnhookEvent("player_ledge_grab", 		Event_LedgeGrab);
			UnhookEvent("revive_begin", 			Event_StartRevive);
			UnhookEvent("revive_end", 				Event_EndRevive);
			UnhookEvent("revive_success", 			Event_EndRevive);
			UnhookEvent("heal_success", 			Event_EndRevive);
			UnhookEvent("player_spawn", 			Event_PlayerSpawn);
			UnhookEvent("round_end", 				Event_RoundEnd,		EventHookMode_PostNoCopy);
			UnhookEvent("round_start", 				Event_RoundStart,	EventHookMode_PostNoCopy);
			bHooked = false;
		}
	}
}

bool IsBeingPwnt(int client)
{
	if( GetEntPropEnt(client, Prop_Send, "m_pounceAttacker") > 0 )
		return true;
	if( GetEntPropEnt(client, Prop_Send, "m_tongueOwner") > 0 )
		return true;
	if( g_bLeft4dead2 )
	{
		if( GetEntPropEnt(client, Prop_Send, "m_jockeyAttacker") > 0 )
			return true;
		if( GetEntPropEnt(client, Prop_Send, "m_pummelAttacker") > 0 )
			return true;
	}
	return false;
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon)
{
	if( client && buttons & g_iUseButton && (GetEngineTime() - g_fPressTime[client] > 0.5) && g_bEnabled )
	{
		g_fPressTime[client] = GetEngineTime();
		
		if( buttons & IN_DUCK ) // Prevent self-help on Ctrl + E.
		{
			if( g_iUseButton & IN_DUCK == 0 )
			{
				return Plugin_Continue;
			}
		}
		
		if( !IsClientInGame(client) )
			return Plugin_Continue;
			
		if( GetClientTeam(client) != 2 )
			return Plugin_Continue;
		
		if( !g_bMapStarted )
			return Plugin_Continue;
		
		if( IsBeingPwnt(client) )
		{
			if( g_eReleaseItems )
			{
				if( TryGetOffInfected(client) )
					return Plugin_Continue;
			}
			else {
				if( g_iShowWarning )
				{
					CPrintToChat(client, "\x04%t", "GetOffInfected"); // "Get that Infected off you first."
				}
			}
			return Plugin_Continue;
		}
		
		if( g_bIncapDelay[client] )
			return Plugin_Continue;
		
		if( !IsPlayerIncapped(client) )
			return Plugin_Continue;
		
		if( g_bForbidInReviving )
		{
			if( GetEntPropEnt(client, Prop_Send, "m_reviveOwner") != -1 ) 
			{
				if( g_iShowWarning )
				{
					CPrintToChat(client, "\x04%t", "AlreadyReviving"); // "You're being revived already."
				}
				return Plugin_Continue;
			}
		}
		
		ITEM_TYPE eItem;
		bool bAllowStandup, bItemOnFloor, bHanging;
		int iWeapon;
		
		bAllowStandup = IsAllowedStandup(client, bHanging, eItem, iWeapon, bItemOnFloor);
		
		if( bAllowStandup )
		{
			if( !bItemOnFloor ) // equipped
			{
				RemovePlayerItem(client, iWeapon);
			}
			RemoveEntity(iWeapon);
		}
		
		if( !bAllowStandup )
		{
			if( g_iShowWarning )
			{
				char items[3][16];
				
				if( bHanging )
				{
					if( g_eHelpItemsLedge & ITEM_PILLS ) 							items[0] = "of_pills";
					if((g_eHelpItemsLedge & ITEM_ADRENALINE) && g_bLeft4dead2 ) 	items[1] = "of_adrenaline";
					if( g_eHelpItemsLedge & ITEM_MEDKIT ) 							items[2] = "of_medkit";
				
					CPrintToChat(client, "\x04%t %s.", "NoItems", FormatItemsString(client, items, sizeof(items))); // "You ain't got no X.
				}
				else {
					if( g_eHelpItemsIncap & ITEM_PILLS ) 							items[0] = "of_pills";
					if((g_eHelpItemsIncap & ITEM_ADRENALINE) && g_bLeft4dead2 ) 	items[1] = "of_adrenaline";
					if( g_eHelpItemsIncap & ITEM_MEDKIT ) 							items[2] = "of_medkit";
				
					CPrintToChat(client, "\x04%t %s. %t", "NoItems", FormatItemsString(client, items, sizeof(items)), "Search"); // "You ain't got no X. Though, you can search them on the floor.
				}
			}
			return Plugin_Continue;
		}
		else
		{
			if( g_iShowMsgAll )
			{
				static char sItem[32];
				switch( eItem )
				{
					case ITEM_MEDKIT: 		sItem = bItemOnFloor ? "Found_Medkit" 		: "Used_Medkit";
					case ITEM_PILLS: 		sItem = bItemOnFloor ? "Found_Pills" 		: "Used_Pills";
					case ITEM_ADRENALINE: 	sItem = bItemOnFloor ? "Found_Adrenaline"	: "Used_Adrenaline";
					default: 				sItem = "Dummy";
				}
				switch( g_iMsgPos )
				{
					case MSG_POS_CHAT:		CPrintToChatAllExclude(		client, "\x04%N\x01 %t", client, sItem);
					case MSG_POS_HINT:		CPrintHintTextToAllExclude(	client, "%N %t", client, sItem);
					case MSG_POS_CENTER:	CPrintCenterTextAllExclude(	client, "%N %t", client, sItem);
					case MSG_POS_CHAT_HINT:
					{
						CPrintToChatAllExclude(		client, "\x04%N\x01 %t", client, sItem);
						CPrintHintTextToAllExclude(	client, "%N %t", client, sItem);
					}
				}
			}
			EmitSoundToClient(client, STANDUP_SOUND); // add some sound
			
			if( bHanging )
			{
				StopHangSound(client);
			}
			
			// prevents the strange bug, when the player able to grab the pills on the table even if the pills are marked for deletion!
			CreateTimer(0.1, Timer_AdjustHealth, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
		}
	}
	return Plugin_Continue;
}

char[] FormatItemsString(int client, char[][] items, int size)
{
	char str[92];
	for( int i = 0; i < size; i++ )
	{
		if( items[i][0] != 0 )
		{
			if( str[0] == 0 )
			{
				FormatEx(str, sizeof(str), "%T", items[i], client);
			}
			else {
				Format(str, sizeof(str), "%s, %T", str, items[i], client);
			}
		}
	}
	return str;
}

// Checks the weapon slots & nearby area.
//
bool IsAllowedStandup(int client, bool &bHanging = false, ITEM_TYPE &eItem = ITEM_NONE, int &iWeapon = 0, bool &bItemOnFloor = false)
{
	bool bAllowStandup;
	
	bHanging = IsHanging(client);
	
	if( bHanging )
	{
		if( g_bAllowHelpLedgeSlot4 && -1 != (iWeapon = GetPlayerWeaponSlot(client, 4)) )
		{
			eItem = GetItemType(iWeapon);
			
			if( eItem & g_eHelpItemsLedge )
			{
				bAllowStandup = true;
			}
		}
		else if( g_bAllowHelpLedgeSlot3 && -1 != (iWeapon = GetPlayerWeaponSlot(client, 3)) )
		{
			bAllowStandup = true;
			eItem = ITEM_MEDKIT;
		}
	}
	else {
		if( g_bAllowHelpIncapSlot4 && -1 != (iWeapon = GetPlayerWeaponSlot(client, 4)) )
		{
			eItem = GetItemType(iWeapon);
			
			if( eItem & g_eHelpItemsIncap )
			{
				bAllowStandup = true;
			}
		}
		else if( g_bAllowHelpIncapSlot3 && -1 != (iWeapon = GetPlayerWeaponSlot(client, 3)) )
		{
			bAllowStandup = true;
			eItem = ITEM_MEDKIT;
		}
		else if( ITEM_NONE != (eItem = FindHelperItemOnFloor(client, iWeapon)) ) // do you see item on the floor?
		{
			bAllowStandup = true;
			bItemOnFloor = true;
		}
	}
	return bAllowStandup;
}

public Action Timer_AdjustHealth(Handle timer, int UserId)
{
	int client = GetClientOfUserId(UserId);
	if( client && IsClientInGame(client) )
	{
		AdjustHealth(client);
	}
	return Plugin_Continue;
}

ITEM_TYPE FindHelperItemOnFloor(int client, int &iEntity)
{
	if( (g_eHelpItemsIncap & ITEM_PILLS) && FindItemOnFloor(client, "weapon_pain_pills", iEntity) || FindItemOnFloor(client, "weapon_pain_pills_spawn", iEntity) )
	{
		return ITEM_PILLS;
	}
	if( (g_eHelpItemsIncap & ITEM_MEDKIT) && FindItemOnFloor(client, "weapon_first_aid_kit", iEntity) || FindItemOnFloor(client, "weapon_first_aid_kit_spawn", iEntity) )
	{
		return ITEM_MEDKIT;
	}
	if( g_bLeft4dead2 && (g_eHelpItemsIncap & ITEM_ADRENALINE) && FindItemOnFloor(client, "weapon_adrenaline", iEntity) || FindItemOnFloor(client, "weapon_adrenaline_spawn", iEntity) )
	{
		return ITEM_ADRENALINE;
	}
	return ITEM_NONE;
}

bool FindItemOnFloor(int client, char[] sClassname, int &iEntity)
{
	const float ITEM_RADIUS = 25.0;
	const float PILLS_MAXDIST = 101.8;
	
	float vecEye[3], vecTarget[3], vecDir1[3], vecDir2[3], ang[3];
	float dist, MAX_ANG_DELTA, ang_delta;
	
	GetClientEyePosition(client, vecEye);
	
	int pills = -1;
	while( -1 != (pills = FindEntityByClassname(pills, sClassname)) )
	{
		GetEntPropVector(pills, Prop_Data, "m_vecOrigin", vecTarget);
		
		dist = GetVectorDistance(vecEye, vecTarget);

		if( dist <= 50.0 )
		{
			iEntity = pills;
			return true;
		}
		
		if( dist <= PILLS_MAXDIST )
		{
			// get directional angle between eyes and target
			SubtractVectors(vecTarget, vecEye, vecDir1);
			NormalizeVector(vecDir1, vecDir1);
		
			// get directional angle of eyes view
			GetClientEyeAngles(client, ang);
			GetAngleVectors(ang, vecDir2, NULL_VECTOR, NULL_VECTOR);
			
			// get angle delta between two directional angles
			ang_delta = GetAngle(vecDir1, vecDir2); // RadToDeg
			
			MAX_ANG_DELTA = ArcTangent(ITEM_RADIUS / dist); // RadToDeg

			if( ang_delta <= MAX_ANG_DELTA )
			{
				iEntity = pills;
				return true;
			}
		}
	}
	return false;
}

float GetAngle(float x1[3], float x2[3]) // by Pan XiaoHai
{
	return ArcCosine(GetVectorDotProduct(x1, x2)/(GetVectorLength(x1)*GetVectorLength(x2)));
}

void AdjustHealth(int client)
{
	if( g_bHeartbeatPlugin )
	{
		g_iIncapCount[client] = Heartbeat_GetRevives(client);
		#if DEBUG
		PrintToChat(client, "Revives count (was): %i", g_iIncapCount[client]);
		#endif
	}
	else {
		g_iIncapCount[client] = GetEntData(client, g_iIncapCountOffset, 1);
	}
	
	StopReviveAction(client);
	
	// This code internally calls "revive_success" event!
	int iflags = GetCommandFlags("give");
	int bits = GetUserFlagBits(client);
	SetCommandFlags("give", iflags & ~FCVAR_CHEAT);
	SetUserFlagBits(client, ADMFLAG_ROOT); // to prevent conflict with AdminCheats crazy plugin ^_^
	FakeClientCommand(client,"give health");
	SetUserFlagBits(client, bits);
	SetCommandFlags("give", iflags);
	
	SetEntityMoveType(client, MOVETYPE_WALK);
	
	SetNewHealth(client);
}

void SetNewHealth(int client)
{
	if( g_iIncapCount[client] != g_iMaxIncaps )
	{
		g_iIncapCount[client]++;
	}
	bool bLastLife = g_iMaxIncaps == g_iIncapCount[client];
	
	#if DEBUG
	PrintToChatAll("%N incap count set as: %i", client, g_iIncapCount[client]);
	#endif
	
	SetEntityHealth(client, 1);
	SetEntDataFloat(client, g_iTempHpOffset, g_fReviveTempHealth, true);
	
	if( g_bHeartbeatPlugin )
	{
		#if DEBUG
		PrintToChat(client, "Revives count (now): %i", g_iIncapCount[client]);
		#endif
		
		Heartbeat_SetRevives(client, g_iIncapCount[client], true);
	}
	else {
		if ( !g_bDisableHeartbeat )
		{
			SetEntData(client, g_iIncapCountOffset, g_iIncapCount[client], 1);
			
			if( bLastLife )
			{
				if( g_bLeft4dead2 )
				{
					SetEntProp(client, Prop_Send, "m_bIsOnThirdStrike", 1);
				}
				SetEntProp(client, Prop_Send, "m_isGoingToDie", 1);
				
				//This was cannot be stopped by L4D1 engine
				//EmitSoundToClient(client, SOUND_HEARTBEAT, SOUND_FROM_PLAYER, SNDCHAN_STATIC);
			}
		}
	}
	
	if( bLastLife ) // not nice, but a walkaround Heartbeat plugin bug? - player can't die after 2nd incap (when he is in B&W state)
	{
		SetEntData(client, g_iIncapCountOffset, g_iMaxIncaps, 1);
	}
}


bool IsPlayerIncapped(int client)
{
	return GetEntProp(client, Prop_Send, "m_isIncapacitated", 1) != 0;
}

public void Event_Incap(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if( client && IsClientInGame(client) )
	{
		g_bIncapDelay[client] = true;
		CreateTimer(g_fDelaySetting, Timer_AdvertisePills, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
	}
}

public void Event_LedgeGrab(Event event, const char[] name, bool dontBroadcast)
{
	int UserId = event.GetInt("userid");
	int client = GetClientOfUserId(UserId);
	if( client && IsClientInGame(client) )
	{
		g_bIncapDelay[client] = true;
		CreateTimer(g_fDelaySetting, Timer_AdvertisePills, UserId, TIMER_FLAG_NO_MAPCHANGE);
	}
}

public Action Timer_AdvertisePills(Handle timer, any UserId)
{
	int client = GetClientOfUserId(UserId);
	if( client && IsClientInGame(client) )
	{
		g_bIncapDelay[client] = false;
		
		if( !g_iMsgAdvertPos )
		{
			return Plugin_Continue;
		}
		
		ITEM_TYPE eItem;
		bool bAllowStandup;
		
		bAllowStandup = IsAllowedStandup(client, _, eItem);

		if( bAllowStandup )
		{
			char sKey[16] = "Dummy";
			static char sItem[32];
			
			if( g_iUseButton & IN_USE )
			{
				sKey = "IN_USE";
			}
			else if( g_iUseButton & IN_DUCK )
			{
				sKey = "IN_DUCK";
			}
			else if( g_iUseButton & IN_JUMP )
			{
				sKey = "IN_JUMP";
			}

			switch( eItem )
			{
				case ITEM_PILLS: 		sItem = "Hint_Pills";
				case ITEM_ADRENALINE: 	sItem = "Hint_Adrenaline";
				case ITEM_MEDKIT: 		sItem = "Hint_Medkit";
				default: 				sItem = "Dummy";
			}
			switch( g_iMsgAdvertPos )
			{
				case MSG_POS_CHAT:		CPrintToChat(		client, "%t %t %t", "Press", sKey, sItem);
				case MSG_POS_HINT:		CPrintHintText(		client, "%t %t %t", "Press", sKey, sItem);
				case MSG_POS_CENTER:	CPrintCenterText(	client, "%t %t %t", "Press", sKey, sItem);
				case MSG_POS_CHAT_HINT: 
				{
					CPrintToChat(		client, "%t %t %t", "Press", sKey, sItem);
					CPrintHintText(		client, "%t %t %t", "Press", sKey, sItem);
				}
			}
		}
	}
	return Plugin_Continue;
}

ITEM_TYPE GetItemType(int entity)
{
	static char classname[64];
	if( entity && entity != INVALID_ENT_REFERENCE && IsValidEntity(entity) )
	{
		GetEdictClassname(entity, classname, sizeof(classname));
		
		if( strcmp(classname, "weapon_pain_pills") == 0 )
			return ITEM_PILLS;
		
		if( strcmp(classname, "weapon_first_aid_kit") == 0 )
			return ITEM_MEDKIT;
			
		if( g_bLeft4dead2 )
		{
			if( strcmp(classname, "weapon_adrenaline") == 0 )
				return ITEM_ADRENALINE;
		}
	}
	return ITEM_NONE;
}

bool IsHanging(int client)
{
	return GetEntProp(client, Prop_Send, "m_isHangingFromLedge") > 0;
}

public void Event_StartRevive(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("subject"));
	g_bIsBeingRevived[client] = true;
}

public void Event_EndRevive(Event event, const char[] name, bool dontBroadcast)
{
	int UserId = event.GetInt("subject");
	int client = GetClientOfUserId(UserId);
	
	if( client && IsClientInGame(client) )
	{
		g_bIsBeingRevived[client] = false;
		
		if( g_bDisableHeartbeat )
		{
			CreateTimer(1.0, Timer_DisableHeartbeat, UserId, TIMER_FLAG_NO_MAPCHANGE); // delay, just in case
		}
	}
}

public void Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast) // to support 3-rd party plugins
{
	if( g_bDisableHeartbeat )
	{
		int UserId = event.GetInt("userid");
		int client = GetClientOfUserId(UserId);
		
		if( client && GetClientTeam(client) == 2 && !IsFakeClient(client) )
		{
			CreateTimer(1.5, Timer_DisableHeartbeat, UserId, TIMER_FLAG_NO_MAPCHANGE); // 1.5 sec. should be enough for 3-rd party plugin to set required initial state
		}
	}
}

public Action Timer_DisableHeartbeat(Handle timer, any UserId)
{
	int client = GetClientOfUserId(UserId);
	if( client && IsClientInGame(client) )
	{
		// player/heartbeatloop.wav Channel:0, volume:0.000000, level:0,  pitch:100, flags:4 // SNDCHAN_AUTO, SNDLEVEL_NONE, SNDPITCH_NORMAL, SND_SPAWNING
		StopSound(client, SNDCHAN_AUTO, SOUND_HEARTBEAT);
		// player/HeartbeatLoop.wav Channel:6, volume:1.000000, level:90, pitch:100, flags:0 // SNDCHAN_STATIC, SNDLEVEL_SCREAMING, SNDPITCH_NORMAL
		StopSound(client, SNDCHAN_STATIC, SOUND_HEARTBEAT);
	}
	return Plugin_Continue;
}

public Action Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	g_bMapStarted = false;
	return Plugin_Continue;
}

public Action Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	g_bMapStarted = true;
	return Plugin_Continue;
}

public void OnMapStart()
{
	g_bMapStarted = true;
	PrecacheSound(SOUND_HEARTBEAT, true);
}

public void OnMapEnd()
{
	g_bMapStarted = false;
}

stock void CPrintToChatAllExclude(int iExcludeClient, const char[] format, any ...) // print chat to all, but exclude one specified player
{
	static char buffer[192];
	for( int i = 1; i <= MaxClients; i++ )
	{
		if( i != iExcludeClient && IsClientInGame(i) && !IsFakeClient(i) )
		{
			SetGlobalTransTarget(i);
			VFormat(buffer, sizeof(buffer), format, 3);
			ReplaceColor(buffer, sizeof(buffer));
			PrintToChat(i, "\x01%s", buffer);
		}
	}
}

stock void CPrintHintTextToAllExclude(int iExcludeClient, const char[] format, any ...) // print hint to all, but exclude one specified player
{
	static char buffer[192];
	for( int i = 1; i <= MaxClients; i++ )
	{
		if( i != iExcludeClient && IsClientInGame(i) && !IsFakeClient(i) )
		{
			SetGlobalTransTarget(i);
			VFormat(buffer, sizeof(buffer), format, 3);
			PrintHintText(i, "%s", buffer);
		}
	}
}

stock void CPrintCenterTextAllExclude(int iExcludeClient, const char[] format, any ...) // print center screen to all, but exclude one specified player
{
	static char buffer[192];
	for( int i = 1; i <= MaxClients; i++ )
	{
		if( i != iExcludeClient && IsClientInGame(i) && !IsFakeClient(i) )
		{
			SetGlobalTransTarget(i);
			VFormat(buffer, sizeof(buffer), format, 3);
			PrintCenterText(i, "%s", buffer);
		}
	}
}

stock void CPrintToChat(int client, const char[] format, any ...)
{
    static char buffer[192];
    SetGlobalTransTarget(client);
    VFormat(buffer, sizeof(buffer), format, 3);
    ReplaceColor(buffer, sizeof(buffer));
    PrintToChat(client, "\x01%s", buffer);
}

stock void CPrintHintText(int client, const char[] format, any ...)
{
    static char buffer[192];
    SetGlobalTransTarget(client);
    VFormat(buffer, sizeof(buffer), format, 3);
    RemoveColor(buffer, sizeof(buffer));
    PrintHintText(client, "%s", buffer);
}

stock void CPrintCenterText(int client, const char[] format, any ...)
{
    static char buffer[192];
    SetGlobalTransTarget(client);
    VFormat(buffer, sizeof(buffer), format, 3);
    RemoveColor(buffer, sizeof(buffer));
    PrintCenterText(client, "%s", buffer);
}

stock void ReplaceColor(char[] message, int maxLen)
{
    ReplaceString(message, maxLen, "{white}", "\x01", false);
    ReplaceString(message, maxLen, "{cyan}", "\x03", false);
    ReplaceString(message, maxLen, "{orange}", "\x04", false);
    ReplaceString(message, maxLen, "{green}", "\x05", false);
}

stock void RemoveColor(char[] message, int maxLen)
{
    ReplaceString(message, maxLen, "{white}", "", false);
    ReplaceString(message, maxLen, "{cyan}", "", false);
    ReplaceString(message, maxLen, "{orange}", "", false);
    ReplaceString(message, maxLen, "{green}", "", false);
}

stock void StopHangSound(int client)
{
	Address pMusic = GetEntityAddress(client) + g_iOffsetMusic;
	SDKCall(g_hSDK_OnSavedFromLedgeHang, pMusic);
}

// Prevents an accidental freezing of player who tried to revive you
//
stock void StopReviveAction(int client)
{
	int owner_save = -1;
	int target_save = -1;
	int owner = GetEntPropEnt(client, Prop_Send, "m_reviveOwner"); // when you reviving somebody, this is -1. When somebody revive you, this is somebody's id
	int target = GetEntPropEnt(client, Prop_Send, "m_reviveTarget"); // when you reviving somebody, this is somebody's id. When somebody revive you, this is -1
	SetEntPropEnt(client, Prop_Send, "m_reviveOwner", -1);
	SetEntPropEnt(client, Prop_Send, "m_reviveTarget", -1);
	if( owner != -1 ) // we must reset flag for both - for you, and who you revive
	{
		SetEntPropEnt(owner, Prop_Send, "m_reviveOwner", -1);
		SetEntPropEnt(owner, Prop_Send, "m_reviveTarget", -1);
		SetEntPropFloat(owner, Prop_Send, "m_fireLayerStartTime", 0.0); // stop revive animation
		owner_save = owner;
	}
	if( target != -1 )
	{
		SetEntPropEnt(target, Prop_Send, "m_reviveOwner", -1);
		SetEntPropEnt(target, Prop_Send, "m_reviveTarget", -1);
		target_save = target;
	}
	
	if( g_bLeft4dead2 )
	{
		owner = GetEntPropEnt(client, Prop_Send, "m_useActionOwner");		// used when healing e.t.c.
		target = GetEntPropEnt(client, Prop_Send, "m_useActionTarget");
		SetEntPropEnt(client, Prop_Send, "m_useActionOwner", -1);
		SetEntPropEnt(client, Prop_Send, "m_useActionTarget", -1);
		if( owner != -1 )
		{
			SetEntPropEnt(owner, Prop_Send, "m_useActionOwner", -1);
			SetEntPropEnt(owner, Prop_Send, "m_useActionTarget", -1);
			owner_save = owner;
		}
		if( target != -1 )
		{
			SetEntPropEnt(target, Prop_Send, "m_useActionOwner", -1);
			SetEntPropEnt(target, Prop_Send, "m_useActionTarget", -1);
			target_save = target;
		}
		
		SetEntProp(client, Prop_Send, "m_iCurrentUseAction", 0);
		SetEntPropFloat(client, Prop_Send, "m_flProgressBarDuration", 0.0);
		
		if( owner_save != -1 )
		{
			SetEntProp(owner_save, Prop_Send, "m_iCurrentUseAction", 0);
			SetEntPropFloat(owner_save, Prop_Send, "m_flProgressBarDuration", 0.0);
		}
		if( target_save != -1 )
		{
			SetEntProp(target_save, Prop_Send, "m_iCurrentUseAction", 0);
			SetEntPropFloat(target_save, Prop_Send, "m_flProgressBarDuration", 0.0);
		}
	}
	else {
		owner = GetEntPropEnt(client, Prop_Send, "m_healOwner");		// used when healing
		target = GetEntPropEnt(client, Prop_Send, "m_healTarget");
		SetEntPropEnt(client, Prop_Send, "m_healOwner", -1);
		SetEntPropEnt(client, Prop_Send, "m_healTarget", -1);
		if( owner != -1 )
		{
			SetEntPropEnt(owner, Prop_Send, "m_healOwner", -1);
			SetEntPropEnt(owner, Prop_Send, "m_healTarget", -1);
			owner_save = owner;
		}
		if( target != -1 )
		{
			SetEntPropEnt(target, Prop_Send, "m_healOwner", -1);
			SetEntPropEnt(target, Prop_Send, "m_healTarget", -1);
			target_save = target;
		}
		
		SetEntProp(client, Prop_Send, "m_iProgressBarDuration", 0);
		
		if( owner_save != -1 )
		{
			SetEntProp(owner_save, Prop_Send, "m_iProgressBarDuration", 0);
		}
		if( target_save != -1 )
		{
			SetEntProp(target_save, Prop_Send, "m_iProgressBarDuration", 0);
		}
	}
}

bool TryGetOffInfected(int client)
{
	int iWeapon;
	bool bAllowKill;
	ITEM_TYPE eItem;

	if( g_bAllowReleaseSlot4 && -1 != (iWeapon = GetPlayerWeaponSlot(client, 4)) )
	{
		eItem = GetItemType(iWeapon);
		
		if( eItem & g_eReleaseItems )
		{
			bAllowKill = true;
		}
	}
	
	if( !bAllowKill && g_bAllowReleaseSlot3 && -1 != (iWeapon = GetPlayerWeaponSlot(client, 3)) )
	{
		eItem = GetItemType(iWeapon);
		
		if( eItem & g_eReleaseItems )
		{
			bAllowKill = true;
		}
	}
	
	if( bAllowKill )
	{
		RemovePlayerItem(client, iWeapon);
		RemoveEntity(iWeapon);
		KillPwnInfected(client);
		return true;
	}
	return false;
}

stock void KillPwnInfected(int client)
{
	int attacker = GetPwnInfected(client);
	if( attacker && IsClientInGame(attacker) && IsFakeClient(attacker) )
	{
		ForcePlayerSuicide(attacker);
	}
}

stock int GetPwnInfected(int client)
{
	int attacker;
	if( (attacker = GetEntPropEnt(client, Prop_Send, "m_pounceAttacker")) > 0 )
		return attacker;
	if( (attacker = GetEntPropEnt(client, Prop_Send, "m_tongueOwner")) > 0 )
		return attacker;
	if( g_bLeft4dead2 )
	{
		if( (attacker = GetEntPropEnt(client, Prop_Send, "m_jockeyAttacker")) > 0 )
			return attacker;
		if( (attacker = GetEntPropEnt(client, Prop_Send, "m_pummelAttacker")) > 0 )
			return attacker;
	}
	return 0;
}
