#define PLUGIN_VERSION		"1.3"

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>

#undef REQUIRE_PLUGIN
#tryinclude <vip_core>
//#include <chat-processor>
//#include <scp>

#define MAXLENGTH_NAME		128
#define MAXLENGTH_MESSAGE	128

#define CVAR_FLAGS		FCVAR_NOTIFY

// ✔ ☀
char BlackStar[] = "★"; 	// Root admin
char WhiteStar[] = "☆"; 	// Other admins
char Vip[] = "[√íÞ]"; 		// VIP Core

bool g_bVipCoreLib;

ConVar g_hCvarVipFlag;

public Plugin myinfo =
{
	name = "Chat VIP Color",
	author = "Dragokas",
	description = "Coloring the chat messages of VIP and admins",
	version = PLUGIN_VERSION,
	url = "http://github.com/dragokas"
}

public void OnPluginStart()
{
	CreateConVar("sm_chat_vip_color_version", PLUGIN_VERSION, "Version of plugin", CVAR_FLAGS | FCVAR_DONTRECORD);
	
	g_hCvarVipFlag = CreateConVar(			"sm_chat_vip_color_admins_flag",	"k",	"Flags to consider user as an admin", CVAR_FLAGS );
	
	g_bVipCoreLib = LibraryExists("vip_core");
}

public void VIP_OnVIPLoaded()
{
	g_bVipCoreLib = true;
}

public void OnLibraryRemoved(const char[] name)
{
	if (strcmp(name, "vip_core") == 0)
	{
		g_bVipCoreLib = false;
	}
}

public Action CP_OnChatMessage(int& author, ArrayList recipients, char[] flagstring, char[] name, char[] message, bool& processcolors, bool& removecolors)
{
	return ProcessMsg(author, name, message, processcolors);
}

public Action OnChatMessage(int &author, ArrayList recipients, char[] name, char[] message)
{
	return ProcessMsg(author, name, message);
}

Action ProcessMsg(int& author, char[] name, char[] message, bool& processcolors = true)
{
	static bool bChanged, bNeedColoring;
	static int flags;
	
	if (author == 0 || !IsClientInGame(author))
		return Plugin_Continue;
	
	flags = GetUserFlagBits(author);
	bChanged = false;
	bNeedColoring = false;
	
	if (flags & ADMFLAG_ROOT) {
		Format(name, MAXLENGTH_NAME, "\x04%s \x03%s", BlackStar, name);
		bChanged = true;
		bNeedColoring = true;
	}
	else if (HasVipFlag(author))
	{
		Format(name, MAXLENGTH_NAME, "\x04%s \x03%s", WhiteStar, name);
		bChanged = true;
		bNeedColoring = true;
	}
	else if (IsClientVIP(author)) {
		Format(name, MAXLENGTH_NAME, "\x04%s \x03%s", Vip, name);
		bChanged = true;
		bNeedColoring = true;
	}
	
	if (bChanged) {
		if (bNeedColoring) {
			Format(message, MAXLENGTH_MESSAGE, "\x05%s", message);
		}
		processcolors = true;
		return Plugin_Changed;
	}
	
	return Plugin_Continue;
}

bool HasVipFlag(int client)
{
	int iUserFlag = GetUserFlagBits(client);
	if( iUserFlag & ADMFLAG_ROOT != 0 ) return true;
	
	char sReq[32];
	g_hCvarVipFlag.GetString(sReq, sizeof(sReq));
	if( strlen(sReq) == 0 ) return true;
	
	int iReqFlags = ReadFlagString(sReq);
	return (iUserFlag & iReqFlags != 0);
}

bool IsClientVIP(int client)
{
	if( !g_bVipCoreLib )
		return false;
	
	#if defined _vip_core_included
		return VIP_IsClientVIP(client);
	#else
		return false;
	#endif
}