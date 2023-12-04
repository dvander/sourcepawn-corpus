#define PLUGIN_VERSION "1.6"

#include <sourcemod>
#include <clientprefs>
#pragma newdecls required

/**
 * v1.0 just released;
 * v1.0.1 check entity validates for button status;
 * v1.2 turn to new syntax and less performance usage, add binary check now compatible for other flag change plugins;
 * v1.3 support show on specifies teams or difficulties, 
 * 		change work way to GameFrame and iHideHudInterval change to frames unit,
 * 		add key detection instead +speed;
 * 		death also regarded as incapped; 7-April-2022
 * v1.4 new ConVar *_hide_on_admin to control hide hud on specify admins; 1-November-2022 
 * v1.5 new Command sm_hud to toggle did override client hud status, meaning on or off, command status save on server over 'clientprefs',
 * 		new ConVar *_command to control which admin flag user can access command sm_hud or everyone; 2-December-2022 
 * v1.6 new Command sm_hidehud to toggle did override hud hidden, this is the opposite of the sm_hud, but didnt override hide_hud_show_on_menuing, otherwise cannot show any menu; 3-December-2022 
 */

ConVar cHideHudInterval;		int iHideHudInterval;
ConVar cShowOnKey;				int iShowOnKey;
ConVar cShowOnMenuing;			bool bShowOnMenuing;
ConVar cShowOnIncapped;			bool bShowOnIncapped;
ConVar cHideFlag;				int iHideFlag;
ConVar cShowOnDifficulties;		int iShowOnDifficulties;
ConVar cShowOnTeams;			int iShowOnTeams;
ConVar cDifficulty;				int iDifficulty;
ConVar cHideOnAdmin;			int iHideOnAdmin;
ConVar cHideCmdAccess;			int iHideCmdAccess;

Cookie ckOverridesShow;
Cookie ckOverridesHide;

enum {
	Easy = 1,
	Normal = 2,
	Hard = 4,
	Expert = 8
}

bool bLateLoad = false;

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max) {

	if (late)
		bLateLoad = true;

	return APLRes_Success; 
}


public Plugin myinfo = {
	name = "[L4D & L4D2] HUD Hiddens",
	author = "NoroHime",
	description = "make players HUD hidden automatically.",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=335532"
}

public void OnPluginStart() {

	CreateConVar("hide_hud_version", PLUGIN_VERSION, "Version of 'HUD Hiddens'", FCVAR_SPONLY|FCVAR_DONTRECORD|FCVAR_REPLICATED|FCVAR_NOTIFY);

	cHideHudInterval =		CreateConVar("hide_hud_interval", "10", "game frames skips of hidden action, 10=every 10 frames, higher value detect slower and less performance", FCVAR_NOTIFY);
	cShowOnKey =			CreateConVar("hide_hud_show_on_key", "131072", "show hud if press these key, 131072=speed(shift) 4=crouch ", FCVAR_NOTIFY);
	cShowOnMenuing =		CreateConVar("hide_hud_show_on_menuing", "1", "show hud if menu open", FCVAR_NOTIFY);
	cShowOnIncapped =		CreateConVar("hide_hud_show_on_incapped", "1", "show hud if incapped", FCVAR_NOTIFY);
	cHideFlag =				CreateConVar("hide_hud_hideflag", "64", "hidd these HUDs, 1=weapon selection, 2=flashlight, 4=all, 8=health\n16=player dead, 32=needssuit, 64=misc, 128=chat, 256=crosshair, 512=vehicle crosshair, 1024=in vehicle\nnot all available", FCVAR_NOTIFY);
	cShowOnDifficulties =	CreateConVar("hide_hud_show_on_difficulties", "1", "show hud on these difficulties. 1=easy 2=normal 4=hard 8=expert -1=All 7=excluded expert. add numbers together you want.", FCVAR_NOTIFY);
	cShowOnTeams =			CreateConVar("hide_hud_show_on_teams", "11", "show hud on these teams. 1=idle 2=spectator 4=survivors 8=infected 11=excluded survivors. add numbers together you want.", FCVAR_NOTIFY);
	cDifficulty =			FindConVar	("z_difficulty");
	cHideOnAdmin =			CreateConVar("hide_hud_hide_on_admin", "", "admin flags to access plugin, dont hide hud if player doesnt has permission.\nf=sm_slay empty=everyone allow. see more on /configs/admin_levels.cfg", FCVAR_NOTIFY);
	cHideCmdAccess =		CreateConVar("hide_hud_command", "", "admin flags to access sm_hud, toggle the hide status.\nf=sm_slay empty=everyone allow. see more on /configs/admin_levels.cfg", FCVAR_NOTIFY);
	

	cHideHudInterval.AddChangeHook(Event_ConVarChanged);
	cShowOnKey.AddChangeHook(Event_ConVarChanged);
	cShowOnMenuing.AddChangeHook(Event_ConVarChanged);
	cShowOnIncapped.AddChangeHook(Event_ConVarChanged);
	cHideFlag.AddChangeHook(Event_ConVarChanged);
	cShowOnDifficulties.AddChangeHook(Event_ConVarChanged);
	cShowOnTeams.AddChangeHook(Event_ConVarChanged);
	cDifficulty.AddChangeHook(Event_ConVarChanged);
	cHideOnAdmin.AddChangeHook(Event_ConVarChanged);
	cHideCmdAccess.AddChangeHook(Event_ConVarChanged);

	AutoExecConfig(true, "hide_hud");

	RegConsoleCmd("sm_hud",		CommandHUD,		"toggle did override client hud show, meaning on or off");
	RegConsoleCmd("sm_hidehud", CommandHideHUD, "toggle did override client hud hidden, meaning on or off");

	ckOverridesShow = new Cookie("hide_hud_override", 		"player hud cookie for override show", CookieAccess_Protected);
	ckOverridesHide = new Cookie("hide_hud_override_hide",	"player hud cookie for override hide", CookieAccess_Protected);

	if (bLateLoad)
		for (int i = 1; i <= MaxClients; i++)
			if ( IsClientInGame(i) && AreClientCookiesCached(i) )
				OnClientCookiesCached(i);
}

public void OnConfigsExecuted() {
	ApplyCvars();
}


public void Event_ConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue) {
	ApplyCvars();
}

public void ApplyCvars() {

	static char flags[32];

	iHideHudInterval =  cHideHudInterval.IntValue;
	iShowOnKey = cShowOnKey.IntValue;
	bShowOnMenuing = cShowOnMenuing.BoolValue;
	bShowOnIncapped = cShowOnIncapped.BoolValue;
	iHideFlag = cHideFlag.IntValue;
	iShowOnDifficulties = cShowOnDifficulties.IntValue;
	iShowOnTeams = cShowOnTeams.IntValue;

	static char diffi[32];
	cDifficulty.GetString(diffi, sizeof(diffi));

	switch (diffi[0]) {
		case 'E', 'e' : iDifficulty = Easy;
		case 'N', 'n' : iDifficulty = Normal;
		case 'H', 'h' : iDifficulty = Hard;
		case 'I', 'i' : iDifficulty = Expert;
		default : iDifficulty = Normal;
	}

	cHideOnAdmin.GetString(flags, sizeof(flags));
	iHideOnAdmin = flags[0] ? ReadFlagString(flags) : 0;

	cHideCmdAccess.GetString(flags, sizeof(flags));
	iHideCmdAccess = flags[0] ? ReadFlagString(flags) : 0;
}

int iOverridesShow [MAXPLAYERS + 1];
int iOverridesHide [MAXPLAYERS + 1];

public void OnClientCookiesCached(int client) {

	if (IsFakeClient(client))
		return;

	static char setting[2];

	ckOverridesShow.Get(client, setting, sizeof(setting));
	iOverridesShow[client] = StringToInt(setting);

	ckOverridesHide.Get(client, setting, sizeof(setting));
	iOverridesHide[client] = StringToInt(setting);
}

Action CommandHUD(int client, int args) {

	if ( (1 <= client <= MaxClients) && IsClientInGame(client) ) {

		if (HasPermission(client, iHideCmdAccess)) {

			iOverridesShow[client] ^= 1;
			iOverridesHide[client] = 0;

			ckOverridesShow.Set(client, iOverridesShow[client] ? "1" : "0");
			ckOverridesHide.Set(client, "0");

		} else
			ReplyToCommand(client, "Permission Denied.");
	}

	return Plugin_Handled;
}

Action CommandHideHUD(int client, int args) {

	if ( (1 <= client <= MaxClients) && IsClientInGame(client) ) {

		if (HasPermission(client, iHideCmdAccess)) {

			iOverridesHide[client] ^= 1;
			iOverridesShow[client] = 0;

			ckOverridesHide.Set(client, iOverridesHide[client] ? "1" : "0");
			ckOverridesShow.Set(client, "0");

		} else
			ReplyToCommand(client, "Permission Denied.");
	}

	return Plugin_Handled;
}


bool HasPermission(int client, int flag) {

	int flag_client = GetUserFlagBits(client);

	if (!flag || flag_client & ADMFLAG_ROOT) return true;

	return view_as<bool>(flag_client & flag);
}

public void OnClientDisconnect_Post(int client) {
	iOverridesShow[client] = false;
	iOverridesHide[client] = false;
}

stock bool IsPlayerDown(int client) {
	return GetEntProp(client, Prop_Send, "m_isIncapacitated") || GetEntProp(client, Prop_Send, "m_isHangingFromLedge") || !IsPlayerAlive(client);
}

public void OnGameFrame() {

	static int skipped = 0;

	if (++skipped >= iHideHudInterval) {

		skipped = 0;

		for (int client = 1; client <= MaxClients; client++) {

			if (IsClientInGame(client) && !IsFakeClient(client)) {

				int buttons = GetClientButtons(client),
					flags_hud = GetEntProp(client, Prop_Send, "m_iHideHUD"),
					team = GetClientTeam(client);

				if ( 
					(bShowOnMenuing && GetClientMenu(client) != MenuSource_None) ||  
					!iOverridesHide[client] &&
					(
						(buttons & iShowOnKey) || 
						(bShowOnIncapped && IsPlayerDown(client)) ||
						(iShowOnDifficulties & iDifficulty) ||
						(iShowOnTeams & (1 << team)) ||
						(iHideOnAdmin && !HasPermission(client, iHideOnAdmin)) ||
						iOverridesShow[client]
					)
				) {
					if(flags_hud & iHideFlag)
						SetEntProp(client, Prop_Send, "m_iHideHUD", flags_hud & ~iHideFlag); //shown

				} else if ( !(flags_hud & iHideFlag) )
					SetEntProp(client, Prop_Send, "m_iHideHUD", flags_hud | iHideFlag); //hidden
			}
		}
	}
}
