#pragma semicolon 1

#include <sourcemod>
new Handle:password, Handle:requiredflag;
new bitflag = -1;

public Plugin:myinfo =
{
	name = "Password Notify",
	author = "Anhil",
	description = "Shows password to admins.",
	version = "1.0",
	url = "http://forums.alliedmods.net/"
};

public OnPluginStart()
{
	LoadTranslations("passwordnotify.phrases");
	password = FindConVar("sv_password");
	requiredflag = CreateConVar("sv_pw_flag", "", "Required flag to show password");
	HookConVarChange(password, Action_OnPasswordChange);
	HookConVarChange(requiredflag, Action_OnRequiredFlagChange);
	
	new cvarflags = GetConVarFlags(password);
	cvarflags &= ~FCVAR_NOTIFY;
	SetConVarFlags(password, cvarflags);
	
	AutoExecConfig(true, "passwordnotify");
}

public OnPluginEnd()
{
	new cvarflags = GetConVarFlags(password);
	cvarflags |= FCVAR_NOTIFY;
	SetConVarFlags(password, cvarflags);
}

public Action_OnPasswordChange(Handle:cvar, const String:oldvalue[], const String:newvalue[])
{
	for (new i = 1; i <= MaxClients; i++)
		if (IsClientInGame(i))
			if (IsAdmin(i))
				if (!StrEqual(newvalue, ""))
					PrintToChat(i, "%t", "Password Notify", "sv_password", newvalue);
				else
					PrintToChat(i, "[SM] Server password removed");
			else
				PrintToChat(i, "%t", "Password Notify", "sv_password", "***PROTECTED***");				
} 

public Action_OnRequiredFlagChange(Handle:cvar, const String:oldvalue[], const String:newvalue[])
{
	if(StrEqual(newvalue, "") || StrEqual(newvalue, "z"))
		bitflag = -1;
	else
		bitflag = ReadFlagString(newvalue);
} 

bool:IsAdmin(client)
{
	if (bitflag == -1)
		return (GetUserFlagBits(client) & ADMFLAG_ROOT) ? true : false; // had "tag mismatch" without "?"
	return ((GetUserFlagBits(client) & bitflag) || (GetUserFlagBits(client) & ADMFLAG_ROOT));
}