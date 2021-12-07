#include <sourcemod>

#undef REQUIRE_PLUGIN
#include <sourcebans>
#define REQUIRE_PLUGIN

#define MAX_STEAMID_LENGTH  19
#define MAX_MESSAGE_LENGTH	192
#define MAX_REASON_LENGTH	32

//#define	PLUGIN_TESTMODE
#define PLUGIN_VERSION 		"1.4"

public Plugin:myinfo = 
{
	name = "LMAOBAN",
	author = "Aderic",
	description = "Bans clients that connect to the server and spam LMAOBOX text.",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?p=2080526"
}

new Handle:CVAR_Version;
new Handle:CVAR_BanTime;
new Handle:CVAR_BanReason;
new Handle:CVAR_Detection;
new Handle:CVAR_Antispam_Detection;
new Handle:CVAR_Antispam_Warning;
new Handle:CVAR_Antispam_Rate;
new Handle:CVAR_Antispam_Strikes;

enum ClientStruct {
	bool:csBanned,		// If false, client will receive a ban when they break the rules. Used to prevent duplication bans.
	bool:csMentioned,	// If true, client mentioned LMAOBOX at some point.
	csStrikes,			// Counts how many strikes the user has, if it is equal to sm_lmaoban_antispam_strikes the user will be banned.
	csNextReset			// Seconds from now to remove the strikes against the user.
}

new bool:clientData[MAXPLAYERS][ClientStruct];

new banTime;
new String:banReason[MAX_REASON_LENGTH];
new detectionMethod;
new antispamDetection;
new antispamRate;
new antispamStrikes;

new String:antispamWarning[MAX_MESSAGE_LENGTH];

public OnPluginStart()
{
	CVAR_BanTime = 				CreateConVar("sm_lmaoban_time",					"0", 					"Time (in minutes) to ban the user, 0 means permanent ban.", FCVAR_NONE);
	CVAR_BanReason = 			CreateConVar("sm_lmaoban_reason",				"Aimbot Autoban",  		"Ban message to be displayed to the user and recorded.", FCVAR_NONE);
	CVAR_Detection = 			CreateConVar("sm_lmaoban_detection",			"1",  					"If 0, disabled. If 1, strict detection. If 2, detection if URL is mentioned. If 3, detection if the name is mentioned.", FCVAR_NONE, true, 0.0, true, 3.0);
	
	CVAR_Antispam_Detection =	CreateConVar("sm_lmaoban_antispam_detection",	"0",				"If 0, disabled. If 1, mentioning LMAOBOX twice at any point will result in a ban (with the first being a warning). If 2, action will be taken based on whether it is spammed.", FCVAR_NONE);
	CVAR_Antispam_Warning =		CreateConVar("sm_lmaoban_antispam_warning",		"Mentioning LMAOBOX will result in an automatic ban. Please refrain from mentioning it.",		"The warning that appears on detection. If unset no warning will be given to users who gain a strike. This can be up to 192 characters.", FCVAR_NONE);
	CVAR_Antispam_Rate =		CreateConVar("sm_lmaoban_antispam_rate",		"3",				"Seconds to sample for: if strikes exceed the amount set by sm_lmaoban_antispam_strikes, the user will be banned.", FCVAR_NONE, true, 1.0);
	CVAR_Antispam_Strikes =		CreateConVar("sm_lmaoban_antispam_strikes",		"2",				"Maximum number of detections per sm_lmaoban_samplerate to ban.", FCVAR_NONE, true, 1.0);
	
	AutoExecConfig(true, "lmaoban");
}

public OnConfigsExecuted() {
	CVAR_Version = 		CreateConVar("sm_lmaoban_version",		PLUGIN_VERSION, 				"Current version of the plugin. Read Only", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	
	banTime = 			GetConVarInt(CVAR_BanTime);
	detectionMethod = 	GetConVarInt(CVAR_Detection);
	antispamRate = 		GetConVarInt(CVAR_Antispam_Rate);
	antispamStrikes = 	GetConVarInt(CVAR_Antispam_Strikes);
	antispamDetection = GetConVarInt(CVAR_Antispam_Detection);
	
	GetConVarString(CVAR_BanReason, banReason, MAX_REASON_LENGTH);
	GetConVarString(CVAR_Antispam_Warning, antispamWarning, MAX_MESSAGE_LENGTH);
	
	HookConVarChange(CVAR_Version, 				OnConVarChanged);
	HookConVarChange(CVAR_BanTime, 				OnConVarChanged);
	HookConVarChange(CVAR_BanReason, 			OnConVarChanged);
	HookConVarChange(CVAR_Detection, 			OnConVarChanged);
	HookConVarChange(CVAR_Antispam_Detection,	OnConVarChanged);
	HookConVarChange(CVAR_Antispam_Warning, 	OnConVarChanged);
	HookConVarChange(CVAR_Antispam_Rate, 		OnConVarChanged);
	HookConVarChange(CVAR_Antispam_Strikes, 	OnConVarChanged);
}

public OnConVarChanged(Handle:cvar, const String:oldVal[], const String:newVal[]) {
	if (cvar == CVAR_Version) {
		if (StrEqual(newVal, PLUGIN_VERSION, false) == false) {
			SetConVarString(cvar, PLUGIN_VERSION);
		}
	}
	else if (cvar == CVAR_BanTime) {
		banTime = GetConVarInt(cvar);
	}
	else if (cvar == CVAR_BanReason) {
		GetConVarString(cvar, banReason, MAX_REASON_LENGTH);
	}
	else if (cvar == CVAR_Detection) {
		detectionMethod = GetConVarInt(cvar);
	}
	else if (cvar == CVAR_Antispam_Detection) {
		antispamDetection = GetConVarInt(cvar);
	}
	else if (cvar == CVAR_Antispam_Warning) {
		GetConVarString(cvar, antispamWarning, MAX_MESSAGE_LENGTH);
	}
	else {
		if (cvar == CVAR_Antispam_Rate) {
			antispamRate = GetConVarInt(cvar);
		}
		else {
			antispamStrikes = GetConVarInt(cvar);
		}
	}
}

public OnClientConnected(client) {
	clientData[client][csBanned] = false;
	clientData[client][csMentioned] = false;
	clientData[client][csStrikes] = 0;
}

bool:IsNormalCharacter(character) {
	return (character > 31 && character < 127);
}

StripFunnyCharacters(String:message[MAX_MESSAGE_LENGTH]) {
	new charMax = strlen(message);
	new charIndex;
	new copyPos = 0;
	
	new String:strippedString[MAX_MESSAGE_LENGTH];
	
	for (charIndex = 0; charIndex < charMax; charIndex++) {
		// Reach end of string. Break.
		if (message[copyPos] == 0) {
			strippedString[copyPos] = 0;
			break;
		}
		
		// Found a normal character. Copy.
		if (IsNormalCharacter(message[charIndex])) {
			strippedString[copyPos] = message[charIndex];
			copyPos++;
		}
	}
	
	// Copy back to passing parameter.
	strcopy(message, MAX_MESSAGE_LENGTH, strippedString);
}

bool:IsClientSpamming(client) {
	new now = GetTime();
	
	if (clientData[client][csNextReset] == 0 || clientData[client][csNextReset] < now) {
		clientData[client][csNextReset] = now + antispamRate;
		clientData[client][csStrikes] = 0;
	}
	
	clientData[client][csStrikes]++;
	
	if (clientData[client][csStrikes] <= antispamStrikes) {
		if (antispamWarning[0] != 0)
			PrintToChat(client, "%s", antispamWarning);
		
		#if defined PLUGIN_TESTMODE
			PrintToChat(client, "LMAOBAN spam check (%i / %i). Now: %i        Next reset: %i.", clientData[client][csStrikes], antispamStrikes, now, clientData[client][csNextReset]);
		#endif
	
		return false;
	}
	
	return true;
}

public Action:OnClientSayCommand(client, const String:command[], const String:sArgs[]) {
	// If detection is off... move along.
	if (detectionMethod == 0)
		return Plugin_Continue;
	
	if (CheckCommandAccess(client, "lmaoban_exempt", ADMFLAG_BAN))
		return Plugin_Continue;
	
	// Flags this client as receiving the ban. This is so multiple SQL queries aren't sent out.
	if (clientData[client][csBanned] == true) {
		// Shut the user up.
		return Plugin_Handled;
	}
	
	new sArgsSize = strlen(sArgs);
	
	// Don't bother checking the string if it's short.
	if (sArgsSize < 6)
		return Plugin_Continue;
	
	decl String:msg[MAX_MESSAGE_LENGTH];
	strcopy(msg, sizeof(msg), sArgs);
	
	if (sArgs[0] == '"' && sArgs[sArgsSize] == '"') {
		StripQuotes(msg);
	}
	
	StripFunnyCharacters(msg);
	
	#if defined PLUGIN_TESTMODE
		PrintToChat(client, "StripFunnyCharacters: %s", msg);
	#endif
	
	if (detectionMethod == 1) {
		// Stop execution here if the message isn't any of these.
		if (StrEqual(msg, 		"WWW.LMAOBOX.NET - BEST FREE TF2 HACK!", 	false) == false && 
			StrContains(msg, 	"GET GOOD, GET LMAOBOX", 					false) == -1 	&& 
			StrEqual(msg, 		"WWW.LMAOBOX.NET - BEST TF2 HACKS!", 		false) == false && 
			StrEqual(msg, 		"LMAOBOX - WAY TO THE TOP", 				false) == false)
			
			return Plugin_Continue;
	}
	else if (detectionMethod == 2)  {
		// Stop execution here if the message does not contain this.
		if (StrContains(msg, "LMAOBOX.NET", false) == -1)
			return Plugin_Continue;
	}
	else {
		// or this.
		if (StrContains(msg, "LMAOBOX", false) == -1)
			return Plugin_Continue;
	}
	
	if (antispamDetection == 1) {
		if (clientData[client][csMentioned] == false) {
			if (antispamWarning[0] != 0)
				PrintToChat(client, "%s", antispamWarning);
			
			clientData[client][csMentioned] = true;
			return Plugin_Continue;
		}
	}
	else if (antispamDetection == 2) {
		if (IsClientSpamming(client) == false) {
			return Plugin_Continue;
		}
	}
	
	#if defined PLUGIN_TESTMODE
		PrintToChat(client, "LMAOBAN triggered.");
	#endif
	
	#if !defined PLUGIN_TESTMODE
	clientData[client][csBanned] = true;
	
	if (GetFeatureStatus(FeatureType_Native, "SBBanPlayer") == FeatureStatus_Available) {
		SBBanPlayer(0, client, banTime, banReason);
		LogMessage("Autobanned client %L for advertising LMAOBOX via SourceBans.", client);
	}
	else if (BanClient(client, banTime, BANFLAG_AUTHID, banReason, banReason, "LMAOBAN")) {
		LogMessage("Autobanned client %L for advertising LMAOBOX.", client);
	}
	
	#endif
	
	// Let's block this nasty message from getting to anyone else.
	return Plugin_Handled;
}