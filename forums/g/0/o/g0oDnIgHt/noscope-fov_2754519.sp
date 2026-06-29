#include <sourcemod>

Handle g_hCvarNoScope = INVALID_HANDLE;
bool g_bNoScope;

public Plugin myinfo = 
{
	name		=	"Noscope",
	author		=	"KaKeRo",
	description	=	"",
	version		=	"1.0.0.0",
	url			=	"t.me/exagame | t.me/aliiihey | exagame.ir"
};

public void OnPluginStart()
{
	g_hCvarNoScope = CreateConVar("sm_noscope_enabled", "0", "", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_bNoScope = GetConVarBool(g_hCvarNoScope);
	HookConVarChange(g_hCvarNoScope, ConVarChange);
	HookEvent("weapon_zoom", EventWeaponZoom, EventHookMode_Post);
	AutoExecConfig(true, "nozoom");
}

public ConVarChange(Handle cvar, char[] oldVal, char[] newVal)
{
	if(cvar == g_hCvarNoScope)
	{
		g_bNoScope = GetConVarBool(g_hCvarNoScope);
		for(int i = 1; i <= MaxClients; i++)
		{
			if(IsClientInGame(i))
			{
				SetEntProp(i, Prop_Send, "m_iFOV", 90);
				SetEntProp(i, Prop_Send, "m_iDefaultFOV", 90);
			}
		}
	}
}

public Action EventWeaponZoom(Handle event, char[] name, bool silent)
{
	if(g_bNoScope)
	{
		int client = GetClientOfUserId(GetEventInt(event, "userid"));
		SetEntProp(client, Prop_Send, "m_iFOV", 90);
		SetEntProp(client, Prop_Send, "m_iDefaultFOV", 90);
	}
}