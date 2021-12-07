/*
*	Spray Timer
*
*	Author: DragonLight
*	Credit: SprayTracer ( https://forums.alliedmods.net/showthread.php?t=75480 ) for some of the coding.
*
*	Description
*	-----------
*
*	This is a basic plugin to disallow sprays for players that are new to a server. Many trolls don't visit servers for very long and
*	like to leave behind some pretty bad sprays. This blocks sprays until the connection time has been reached and sprays function normally.
*	Uses cookies to store play time persistently, good for single or multiple servers sharing same clientprefs database.
*
*	Usage
*	-----
*
*	sm_spraytimer_version  - Version number for reporting to game monitor sites.
*	sm_spraytimer_enabled  - If you want plugin enabled or disabled. (Default: 1)
*	sm_spraytimer_time     - Total connection time in minutes before players can use sprays. (Default: 120)
*	sm_spraytimer_reserved - Any players with admin reserve flag "A" can bypass the timer if enabled. (Default: 0)
*
*	Changelog
*	---------
*
*	1.2	- Removed TF2 specific checks.
*	1.1 - Added check to bypass bots on disconnect.
*	1.0 - Initial release.
*
*/

#include <sourcemod>
#include <clientprefs>
#include <sdktools>

#define PLUGIN_VERSION "1.2"

new Handle:h_cvarEnabled;
new Handle:h_cvarTime;
new Handle:h_cvarReservedBypass;
new Handle:h_sprayTimeCookie;

public Plugin:myinfo = 
{
	name = "Spray Timer",
	author = "DragonLight",
	description = "Temporarily blocks sprays for players who have had very little connection time to the server.",
	version = PLUGIN_VERSION,
	url = "http://www.ponyfortress2.com/"
}

public OnPluginStart()
{
	// Convars
	CreateConVar("sm_spraytimer_version", PLUGIN_VERSION, "Spray Timer Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	h_cvarEnabled 		 = CreateConVar("sm_spraytimer_enabled", "1", "Enable Spray Timer Plugin, 1 - Enable, 0 - Disable", 0, true, 0.0, true, 1.0);
	h_cvarTime 			 = CreateConVar("sm_spraytimer_time", "120", "Connection time required before players can spray. Time is in minutes.", 0, true, 0.0, false);
	h_cvarReservedBypass = CreateConVar("sm_spraytimer_reserved", "0", "Can reserved slot users bypass Spray Timer?, 1 - Yes, 0 - No", 0, true, 0.0, true, 1.0);

	// Persistent Cookie
	h_sprayTimeCookie = RegClientCookie("spraytimer_time", "Total connection time the client has.", CookieAccess_Protected);

	AddTempEntHook("Player Decal", PlayerSpray);

	AutoExecConfig(true, "plugin.spraytimer");
}

public OnClientDisconnect(client)
{
	if(IsValidClient(client))
		if((GetClientTime(client) <= (GetConVarInt(h_cvarTime)*60)) && (GetSprayCookie(client) < (GetConVarInt(h_cvarTime)*60)) && GetConVarBool(h_cvarEnabled))
			SetSprayCookie(client, RoundFloat(GetClientTime(client) + GetSprayCookie(client)));	//Add connected time to existing time.
}

public Action:PlayerSpray(const String:te_name[],const clients[],client_count,Float:delay)
{
	new client = TE_ReadNum("m_nPlayer");
	
	if(CheckCommandAccess(client, "dummyflag", ADMFLAG_RESERVATION) && GetConVarInt(h_cvarReservedBypass) == 1 || !GetConVarBool(h_cvarEnabled))
		return Plugin_Continue;
	
	if(GetClientTime(client) + GetSprayCookie(client) < (GetConVarInt(h_cvarTime)*60)) //Add current time and previous time, if still not matching deny.
	{
		new timeLeft = RoundFloat((GetConVarInt(h_cvarTime)*60) - (GetSprayCookie(client)+GetClientTime(client)));
		timeLeft = RoundToCeil(float(timeLeft / 60)); //Convert to minutes here.
		decl String:s[32];
		if(timeLeft > 1)
			Format(s, 16, "%i minutes.", timeLeft);
		else if(timeLeft == 1)
			Format(s, 16, "%i minutes.", timeLeft);
		else if(timeLeft < 1) //Might happen, just in case.
			Format(s, 16, "Less then a minute.");
		PrintToChat(client, "Warning: Sprays are disabled for players with not enough connection time to this server. Time Left: %s", s);
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

GetSprayCookie(client)
{
	if (!IsValidClient(client)) return 0;
	if (!AreClientCookiesCached(client)) return 0;
	decl String:strSprayTime[32];
	GetClientCookie(client, h_sprayTimeCookie, strSprayTime, sizeof(strSprayTime));
	return StringToInt(strSprayTime);
}

SetSprayCookie(client, time)
{
	if (!IsValidClient(client)) return;
	if (IsFakeClient(client)) return;
	if (!AreClientCookiesCached(client)) return;
	decl String:strSprayTime[32];
	IntToString(time, strSprayTime, sizeof(strSprayTime));
	SetClientCookie(client, h_sprayTimeCookie, strSprayTime);
}

stock IsValidClient(client, bool:replaycheck = true)
{
    if (client <= 0 || client > MaxClients) return false;
    if (!IsClientInGame(client)) return false;
    if (IsFakeClient(client)) return false;
    return true;
}