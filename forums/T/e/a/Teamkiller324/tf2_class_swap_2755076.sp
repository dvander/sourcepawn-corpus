#include	<tf2_stocks>

#pragma		semicolon	1
#pragma		newdecls	required

#define		PLUGIN_VERSION	"1.0"
#define		Prefix			"\x03[Class Swap]\x01"

// SourceMod Color Table
//	\x01 - Default/White
//	\x02 - Darkred
//	\x03 - Purple
//	\x04 - Green
// 	\x05 - Lightgreen
//	\x06 - Lime
//	\x08 - Gray
//	\x10 - Gold
//	\x0A - Bluegray
//	\x0B - Blue
//	\x0C - Darkblue
//	\x0D - Gray 2
//	\x0E - Orchid (Pink)
//	\x0F - Lightred

public	Plugin	myinfo	=	{
	name		=	"[TF2] Class Swap",
	author		=	"Tk /id/Teamkiller324",
	description	=	"Swaps the class between the two targets",
	version		=	PLUGIN_VERSION,
	url			=	"https://steamcommunity.com/id/Teamkiller324"
}

public void OnPluginStart()	{
	if(GetEngineVersion() != Engine_TF2)
		SetFailState("[TF2] Class Swap Error: ERR_GAME_IS_NOT_TF2");
	
	RegAdminCmd("sm_swapclass",	SwapClassCmd, ADMFLAG_ROOT, "Swap classes between the two targets");
	
	ConVar Version = CreateConVar("tf_swapclass_version", PLUGIN_VERSION, "Version of class swap.");
	Version.AddChangeHook(VersionCvar);
}

/**
 *	Prevents the version cvar from being changed.
 */
void VersionCvar(ConVar cvar, const char[] oldvalue, const char[] newvalue)	{
	cvar.SetString(PLUGIN_VERSION);
}

/**
 *	The command callback.
 */
Action SwapClassCmd(int client, int args)	{
	if(args != 2)	{
		PrintToChat(client, "%s Usage: sm_swapclass <target 1|#userid> <target 2|#userid>");
		return	Plugin_Handled;
	}
	
	char arg1[64], arg2[64];
	GetCmdArg(1, arg1, sizeof(arg1));
	GetCmdArg(2, arg2, sizeof(arg2));
	
	int target1 = FindTarget(client, arg1);
	if(!IsValidClient(target1))	{
		SC_PrintToChat(client, "The first target is invalid");
		return	Plugin_Handled;
	}
	
	int target2 = FindTarget(client, arg2);
	if(!IsValidClient(target2))	{
		SC_PrintToChat(client, "The second target is invalid");
		return	Plugin_Handled;
	}
	
	TF2_SetPlayerClass(target1, TF2_GetPlayerClass(target2));
	TF2_SetPlayerClass(target2, TF2_GetPlayerClass(target1));
	
	SC_PrintToChat(client, "Swapped classes between %N and %N", target1, target2);
	
	return	Plugin_Handled;
}

/**
 *	Custom chat print.
 *
 *	@param	client	The players client index. (To show the message.)
 *	@param	text	The text to fill in.
 *	@param	...		Additional additions.
 */
stock void SC_PrintToChat(int client, char[] text, any ...)	{
	char buffer[64];
	VFormat(buffer, sizeof(buffer), text, 3);
	PrintToChat(client, "%s %s", Prefix, buffer);
}

/**
 *	Returns if the client is valid.
 *
 *	@param	client		The players client index.
 *	@noerror.
 */
stock bool IsValidClient(int client)	{
	if(client == 0 || client == -1)
		return	false;
	if(client < 1 || client > MaxClients)
		return	false;
	if(!IsClientConnected(client))
		return	false;
	if(!IsClientInGame(client))
		return	false;
	if(IsClientSourceTV(client))
		return	false;
	if(IsClientReplay(client))
		return	false;
	if(!IsPlayerAlive(client))
		return	false;
	return	true;
}