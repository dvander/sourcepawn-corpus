#define PLUGIN_VERSION		"1.0.3"
#define PLUGIN_PREFIX		"l4d2_"
#define PLUGIN_NAME			"chat_instruct"
#define PLUGIN_NAME_FULL	"[L4D2] Instructor Chat"
#define PLUGIN_DESCRIPTION	"chat with instructor hint, filter message by distance"
#define PLUGIN_AUTHOR		"NoroHime"
#define PLUGIN_LINK			"https://forums.alliedmods.net/showthread.php?t=341108"

/*
 *	v1.0 just released; 31-December-2022
 *	v1.0.1 fixes:
 *		- dont prevent message when player didnt enabled the instructor,
 *	 	- *_prevent now required "chat-processor"; 31-December-2022 (2nd time)
 *	v1.0.2 fix throw error when detect player who not connected; 1-January-2023
 *	v1.0.3 fix instructor ConVar not found on dedicated server, the previous version wrote on listen server; 4-January-2023
 */

#include <sdkhooks>
#include <sourcemod>
#include <sdktools>

#define MAXLENGTH_FLAG		32
#define MAXLENGTH_NAME		128
#define MAXLENGTH_MESSAGE	128
#define MAXLENGTH_BUFFER	255

#define IsClient(%1) ((1 <= %1 <= MaxClients) && IsClientInGame(%1))

public Plugin myinfo = {
	name =			PLUGIN_NAME_FULL,
	author =		PLUGIN_AUTHOR,
	description =	PLUGIN_DESCRIPTION,
	version =		PLUGIN_VERSION,
	url = 			PLUGIN_LINK
};

ConVar cPrevent;	int iPrevent;
ConVar cTimeout;	int iTimeout;
ConVar cName;		bool bName;
ConVar cIcon;		char sIcon[32];
ConVar cColor;		char sColor[32];
ConVar cRange;		float flRange;
ConVar cFlags;		int iFlags;

enum {
	VISIBLE_ALWAYS = 0,
	PREVENT_ALWAYS,
	PREVENT_OUT_OF_RANGE,
	PREVENT_IN_RANGE
}

public void OnPluginStart() {

	CreateConVar			(PLUGIN_NAME, PLUGIN_VERSION,				"Version of " ... PLUGIN_NAME_FULL, FCVAR_SPONLY|FCVAR_DONTRECORD|FCVAR_REPLICATED|FCVAR_NOTIFY);
	cPrevent =	CreateConVar(PLUGIN_NAME ... "_prevent", "0",			"prevent default chat message 0=no 1=yes 2=prevent if out of range 3=prevent if in range\nrequired \"[Any] Chat-Processor\"", FCVAR_NOTIFY);
	cTimeout =	CreateConVar(PLUGIN_NAME ... "_timeout", "12",			"time(seconds) to disappear instructor hint, int valuve", FCVAR_NOTIFY);
	cName =		CreateConVar(PLUGIN_NAME ... "_name", "1",				"hint name prefix", FCVAR_NOTIFY);
	cIcon =		CreateConVar(PLUGIN_NAME ... "_icon", "icon_skull",		"instructor hint icon, more see ./pak01_dir.vpk/scripts/mod_textures.txt", FCVAR_NOTIFY);
	cColor =	CreateConVar(PLUGIN_NAME ... "_color", "255,255,255",	"instructor hint color, RBG format", FCVAR_NOTIFY);
	cRange =	CreateConVar(PLUGIN_NAME ... "_range", "2000",			"instructor hint range, use with *_prevent, 0=infinity", FCVAR_NOTIFY);
	cFlags =	CreateConVar(PLUGIN_NAME ... "_flags", "0",				"instructor flags, 1,2,4=pulse 8,16,32=alpha animating 64,128=shake 256=static.\nadd numbers together you want", FCVAR_NOTIFY);

	AutoExecConfig(true, PLUGIN_PREFIX ... PLUGIN_NAME);

	cPrevent.AddChangeHook(OnConVarChanged);
	cTimeout.AddChangeHook(OnConVarChanged);
	cName.AddChangeHook(OnConVarChanged);
	cIcon.AddChangeHook(OnConVarChanged);
	cColor.AddChangeHook(OnConVarChanged);
	cRange.AddChangeHook(OnConVarChanged);
	cFlags.AddChangeHook(OnConVarChanged);

	ApplyCvars();

	RegConsoleCmd("say", CommandSay);
	RegConsoleCmd("say_team", CommandSay);

	AddCommandListener(CommandPause, "pause");
	AddCommandListener(CommandPause, "setpause");
	AddCommandListener(CommandPause, "unpause");
}

void ApplyCvars() {

	iPrevent = cPrevent.IntValue;
	iTimeout = cTimeout.IntValue;
	bName = cName.BoolValue;
	cIcon.GetString(sIcon, sizeof(sIcon));

	if (!sIcon[0])
		sIcon = "icon_skull";

	cColor.GetString(sColor, sizeof(sColor));
	flRange = cRange.FloatValue;

	iFlags = cFlags.IntValue;
}

void OnConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue) {
	ApplyCvars();
}

public void OnConfigsExecuted() {
	ApplyCvars();
}

bool bInstructorEnabled[MAXPLAYERS + 1];

/**
* Called while sending a chat message before It's sent.
* Limits on the name and message strings can be found above.
*
* param author			Author that created the message.
* param recipients		Array of clients who will receive the message.
* param flagstring		Flag string to determine the type of message.
* param name			Name string of the author to be pushed.
* param message		Message string from the author to be pushed.
* param processcolors	Toggle to process colors in the buffer strings.
* param removecolors	Toggle to remove colors in the buffer strings. (Requires bProcessColors = true)
*
* return types
*  - Plugin_Continue	Stops the message.
*  - Plugin_Stop		Stops the message.
*  - Plugin_Changed		Fires the post-forward below and prints out a message.
*  - Plugin_Handled		Fires the post-forward below but doesn't print a message.
**/
forward Action CP_OnChatMessage(int& author, ArrayList recipients, char[] flagstring, char[] name, char[] message, bool & processcolors, bool & removecolors);

public Action CP_OnChatMessage(int& author, ArrayList recipients, char[] flagstring, char[] name, char[] message, bool & processcolors, bool & removecolors) {

	
	switch (iPrevent) {

		case PREVENT_ALWAYS: {

			for (int i = 0; i < recipients.Length; i++) {

				int recipi = GetClientOfUserId(recipients.Get(i));

				// only prevent if instructor enabled
				if ( IsClient(recipi) && bInstructorEnabled[recipi] ) {
					recipients.Erase(i);
					i--;
				}
			}

			return Plugin_Changed;
		}

		case PREVENT_OUT_OF_RANGE: {

			if (flRange <= 0)
				return Plugin_Continue;

			float vOriginSelf[3];
			GetClientEyePosition(author, vOriginSelf);

			for (int i = 0; i < recipients.Length; i++) {

				int recipi = GetClientOfUserId(recipients.Get(i));

				if (IsClient(recipi)) {

					float vOriginTarget[3];
					GetClientEyePosition(recipi, vOriginTarget);

					// prevent out of range and instructor enabled
					if ( GetVectorDistance(vOriginTarget, vOriginSelf) > flRange && bInstructorEnabled[recipi] ) {
						recipients.Erase(i);
						i--;
					}
				}

			}

			return Plugin_Changed;
		}

		case PREVENT_IN_RANGE: {

			if (flRange <= 0) {

				for (int i = 0; i < recipients.Length; i++) {

					int recipi = GetClientOfUserId(recipients.Get(i));

					if (IsClient(recipi) && bInstructorEnabled[recipi]) {
						recipients.Erase(i);
						i--;
					}
				}

				return Plugin_Changed;
			}

			float vOriginSelf[3];
			GetClientEyePosition(author, vOriginSelf);

			for (int i = 0; i < recipients.Length; i++) {

				int recipi = GetClientOfUserId(recipients.Get(i));

				if (IsClient(recipi)) {

					float vOriginTarget[3];
					GetClientEyePosition(recipi, vOriginTarget);

					// prevent in range and instructor enabled
					if ( flRange > GetVectorDistance(vOriginTarget, vOriginSelf) && bInstructorEnabled[recipi] ) {
						recipients.Erase(i);
						i--;
					}
				}
			}

			return Plugin_Changed;
		}
	}

	return Plugin_Continue;
}

void OnQueryInstructor(QueryCookie cookie, int client, ConVarQueryResult result, const char[] cvarName, const char[] cvarValue) {

	if (strcmp(cvarValue, "0") == 0)
		bInstructorEnabled[client] = false;
	else
		bInstructorEnabled[client] = true;
}

public void OnClientPutInServer(int client) {
	if (!IsFakeClient(client)) {
		QueryClientConVar(client, "gameinstructor_enable", OnQueryInstructor)
	}
}

public void OnClientDisconnect_Post(int client) {
	bInstructorEnabled[client] = false;
}

Action CommandSay(int client, int args) {

	if (!IsClient(client))
		return Plugin_Continue;

	static char text[256];

	GetCmdArgString(text, sizeof(text));
	StripQuotes(text);
	TrimString(text);

	if (text[0] == '/' || text[0] == '!')
		return Plugin_Continue;

	if (bName)
		Format(text, sizeof(text), "%N: %s", client, text);

	Event event = CreateEvent("instructor_server_hint_create", true);

	if (event) {

		event.SetString("hint_name", PLUGIN_PREFIX ... PLUGIN_NAME);

		event.SetInt("hint_target", client);
		event.SetString("hint_caption", text);

		if (sColor[0])
			event.SetString("hint_color", sColor);

		event.SetString("hint_icon_onscreen", sIcon);
		event.SetString("hint_icon_offscreen", sIcon);

		event.SetInt("hint_timeout", iTimeout);
		event.SetBool("hint_allow_nodraw_target", true);
		event.SetBool("hint_nooffscreen", false);
		event.SetBool("hint_forcecaption", true);
		event.SetInt("hint_flags", iFlags);

		event.Fire();
	}

	switch (iPrevent) {

		case PREVENT_IN_RANGE, PREVENT_OUT_OF_RANGE, PREVENT_ALWAYS : {
			for (int i = 1; i <= MaxClients; i++)
				if (IsClientInGame(i) && !IsFakeClient(i))
					QueryClientConVar(i, "gameinstructor_enable", OnQueryInstructor);
		}
	}

	return Plugin_Continue;
}

Action CommandPause(int client, const char[] command, int argc) {

	if (client == 0) {

		static ConVar cInstructorEnable = null;

		if (!cInstructorEnable)
			cInstructorEnable = FindConVar("gameinstructor_enable");

		if (cInstructorEnable)
			bInstructorEnabled[client] = cInstructorEnable.BoolValue;
		
	} else if (IsClientInGame(client))
		
		QueryClientConVar(client, "gameinstructor_enable", OnQueryInstructor);

	return Plugin_Continue;
}