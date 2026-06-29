#pragma semicolon 1
#include <sourcemod>
new Handle:g_notify = INVALID_HANDLE;
public Plugin:myinfo =
{
	name = "Cvar Stripper",
	author = "MikeJS",
	description = "Strip cvars of their notification flags.",
	version = "1",
	url = "http://mikejs.byethost18.com/"
};

public OnPluginStart() 
{
	HookConVarChange(g_notify, Cvar_notify);
	g_notify = CreateConVar("sm_cvars_strip", "", "Cvars to strip the FCVAR_NOTIFY tag from.", FCVAR_PLUGIN);
	HookConVarChange(g_notify, Cvar_notify);
}

public OnConfigsExecuted() 
{
	CvarsNotify();
}

public Cvar_notify(Handle:convar, const String:oldValue[], const String:newValue[]) 
{
	CvarsNotify();
}

CvarsNotify() 
{
	decl String:cvars[1024], String:ncvars[16][64];
	GetConVarString(g_notify, cvars, sizeof(cvars));
	if(strcmp(cvars, "", false)!=0) 
	{
		new cvarc = ExplodeString(cvars, ",", ncvars, 16, 64);
		for(new i=0;i<cvarc;i++) 
		{
			TrimString(ncvars[i]);
			new Handle:cvar = FindConVar(ncvars[i]);
			new flags = GetConVarFlags(cvar);
			flags &= ~FCVAR_NOTIFY;
			SetConVarFlags(cvar, flags);
		}
	}
}