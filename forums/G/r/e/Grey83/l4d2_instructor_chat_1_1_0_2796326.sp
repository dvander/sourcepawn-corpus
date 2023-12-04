/*
 *	v1.0 just released; 31-December-2022
 *	v1.0.1 fixes:
 *		- dont prevent message when player didnt enabled the instructor,
 *		- *_prevent now required "chat-processor"; 31-December-2022 (2nd time)
 *	v1.1.0 by Grey83: 01-January-2023
 *		- fixed error "Client * is not connected"
 *		- minor code optimization
 */
#pragma semicolon 1

#include <sdkhooks>
#include <sdktools_engine>
#tryinclude <chat-processor>

#define PL_VERSION		"1.1.0"
#define PL_PREFIX		"l4d2_"
#define PL_NAME			"chat_instruct"
#define PL_NAME_FULL	"[L4D2] Instructor Chat"

enum
{
	VISIBLE_ALWAYS,
	PREVENT_ALWAYS,
	PREVENT_OUT_OF_RANGE,
	PREVENT_IN_RANGE
}

public Plugin myinfo =
{
	name		= PL_NAME_FULL,
	author		= "NoroHime (rewritten by Grey83)",
	description	= "Chat with instructor hint, filter message by distance",
	version		= PL_VERSION,
	url			= "https://forums.alliedmods.net/showthread.php?t=341108"
}

ConVar cPrevent;	int iPrevent;
ConVar cTimeout;	int iTimeout;
ConVar cName;		bool bName;
ConVar cIcon;		char sIcon[32];
ConVar cColor;		char sColor[12];
ConVar cRange;		float flRange;
ConVar cFlags;		int iFlags;

bool bInstructorEnabled[MAXPLAYERS + 1];

public void OnPluginStart()
{
	CreateConVar			(PL_NAME, PL_VERSION,					"Version of " ... PL_NAME_FULL, FCVAR_SPONLY|FCVAR_DONTRECORD|FCVAR_NOTIFY);

	cPrevent =	CreateConVar(PL_NAME ... "_prevent", "0",			"prevent default chat message 0=no 1=yes 2=prevent if out of range 3=prevent if in range\nrequired \"[Any] Chat-Processor\"", FCVAR_NOTIFY, true, _, true, 3.0);
	cPrevent.AddChangeHook(OnConVarChanged);

	cTimeout =	CreateConVar(PL_NAME ... "_timeout", "12",			"time(seconds) to disappear instructor hint, int valuve", FCVAR_NOTIFY, true, 1.0);
	cTimeout.AddChangeHook(OnConVarChanged);

	cName =		CreateConVar(PL_NAME ... "_name", "1",				"hint name prefix", FCVAR_NOTIFY, true, _, true, 1.0);
	cName.AddChangeHook(OnConVarChanged);

	cIcon =		CreateConVar(PL_NAME ... "_icon", "icon_skull",		"instructor hint icon, more see ./pak01_dir.vpk/scripts/mod_textures.txt", FCVAR_NOTIFY|FCVAR_PRINTABLEONLY);
	cIcon.AddChangeHook(OnConVarChanged);

	cColor =	CreateConVar(PL_NAME ... "_color", "255,255,255",	"instructor hint color, RBG format", FCVAR_NOTIFY|FCVAR_PRINTABLEONLY);
	cColor.AddChangeHook(OnConVarChanged);

	cRange =	CreateConVar(PL_NAME ... "_range", "2000",			"instructor hint range, use with *_prevent, 0=infinity", FCVAR_NOTIFY, true);
	cRange.AddChangeHook(OnConVarChanged);

	cFlags =	CreateConVar(PL_NAME ... "_flags", "0",				"instructor flags, 1,2,4=pulse 8,16,32=alpha animating 64,128=shake 256=static.\nadd numbers together you want", FCVAR_NOTIFY, true, _, true, 255.0);
	cFlags.AddChangeHook(OnConVarChanged);

	AutoExecConfig(true, PL_PREFIX ... PL_NAME);

	RegConsoleCmd("say", Cmd_Say);
	RegConsoleCmd("say_team", Cmd_Say);

	AddCommandListener(Cmd_Pause, "pause");
	AddCommandListener(Cmd_Pause, "setpause");
	AddCommandListener(Cmd_Pause, "unpause");
}

public void OnConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	if(convar == cPrevent)
		iPrevent = convar.IntValue;
	else if(convar == cTimeout)
		iTimeout = convar.IntValue;
	else if(convar == cName)
		bName = convar.BoolValue;
	else if(convar == cIcon)
	{
		convar.GetString(sIcon, sizeof(sIcon));
		if(!sIcon[0]) sIcon = "icon_skull";
	}
	else if(convar == cColor)
		convar.GetString(sColor, sizeof(sColor));
	else if(convar == cRange)
		flRange = convar.IntValue + 0.0;
	else if(convar == cFlags)
		iFlags = convar.IntValue;
}

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
public Action CP_OnChatMessage(int& author, ArrayList recipients, char[] flagstring, char[] name, char[] message, bool & processcolors, bool & removecolors)
{
	static float pos[3];
	static int i, recipi;
	switch(iPrevent)
	{
		case PREVENT_ALWAYS:
		{
			for(i = 0; i < recipients.Length; i++) if((IsValidRecipient(recipients, i)))
			{	// only prevent if instructor enabled
				recipients.Erase(i);
				i--;
			}
			return Plugin_Changed;
		}
		case PREVENT_OUT_OF_RANGE:
		{
			if(flRange <= 0)
				return Plugin_Continue;

			GetClientEyePosition(author, pos);

			// prevent out of range and instructor enabled
			for(i = 0; i < recipients.Length; i++)
				if((recipi = IsValidRecipient(recipients, i)) && InRange(recipi, pos, false))
				{
					recipients.Erase(i);
					i--;
				}
			return Plugin_Changed;
		}
		case PREVENT_IN_RANGE:
		{
			if(flRange <= 0)
			{
				for(i = 0; i < recipients.Length; i++) if((IsValidRecipient(recipients, i)))
				{
					recipients.Erase(i);
					i--;
				}
				return Plugin_Changed;
			}

			GetClientEyePosition(author, pos);

			// prevent in range and instructor enabled
			for(i = 0; i < recipients.Length; i++)
				if((recipi = IsValidRecipient(recipients, i)) && InRange(recipi, pos, true))
				{
					recipients.Erase(i);
					i--;
				}
			return Plugin_Changed;
		}
	}

	return Plugin_Continue;
}

public void OnClientPutInServer(int client)
{
	if(!IsFakeClient(client)) QueryClientConVar(client, "gameinstructor_enable", OnQueryInstructor);
}

public void OnClientDisconnect_Post(int client)
{
	bInstructorEnabled[client] = false;
}

public Action Cmd_Say(int client, int args)
{
	if(!client || !IsClientInGame(client))
		return Plugin_Continue;

	static char text[128];
	GetCmdArgString(text, sizeof(text));
	StripQuotes(text);
	TrimString(text);

	if(text[0] == '/' || text[0] == '!')
		return Plugin_Continue;

	if(bName) Format(text, sizeof(text), "%N: %s", client, text);

	Event event = CreateEvent("instructor_server_hint_create", true);
	if(event)
	{
		event.SetString("hint_name", PL_PREFIX ... PL_NAME);

		event.SetInt("hint_target", client);

		// 100 character limit. https://developer.valvesoftware.com/wiki/Env_instructor_hint#Keyvalues
		event.SetString("hint_caption", text);

		if(sColor[0]) event.SetString("hint_color", sColor);

		event.SetString("hint_icon_onscreen", sIcon);
		event.SetString("hint_icon_offscreen", sIcon);

		event.SetInt("hint_timeout", iTimeout);
		event.SetBool("hint_allow_nodraw_target", true);
		event.SetBool("hint_nooffscreen", false);
		event.SetBool("hint_forcecaption", true);
		event.SetInt("hint_flags", iFlags);

		event.Fire();
	}

	if(iPrevent != VISIBLE_ALWAYS)
		for(int i = 1; i <= MaxClients; i++) if(IsClientInGame(i)) OnClientPutInServer(i);

	return Plugin_Continue;
}

public Action Cmd_Pause(int client, const char[] command, int argc)
{
	if(!client)
		bInstructorEnabled[client] = FindConVar("gameinstructor_enable").BoolValue;
	else if(IsClientConnected(client)) OnClientPutInServer(client);

	return Plugin_Continue;
}

public void OnQueryInstructor(QueryCookie cookie, int client, ConVarQueryResult result, const char[] cvarName, const char[] cvarValue)
{
	bInstructorEnabled[client] = !!strcmp(cvarValue, "0");
}

stock bool InRange(int client, const float pos[3], const bool inside)
{
	static float orig[3];
	GetClientEyePosition(client, orig);
	return FloatCompare(flRange, GetVectorDistance(orig, pos)) == (inside ? 1 : -1);
}

stock int IsValidRecipient(ArrayList recipients, int i)
{
	static int client;
	if((client = GetClientOfUserId(recipients.Get(i))) && bInstructorEnabled[client] && IsClientInGame(client))
		return client;

	return 0;
}