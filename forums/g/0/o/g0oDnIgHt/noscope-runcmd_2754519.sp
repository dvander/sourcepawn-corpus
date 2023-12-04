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
	g_hCvarNoScope = CreateConVar("sm_noscope_enable", "0", "", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_bNoScope = GetConVarBool(g_hCvarNoScope);
	HookConVarChange(g_hCvarNoScope, ConVarChange);
	AutoExecConfig(true, "nozoom");
}

public ConVarChange(Handle cvar, char[] oldVal, char[] newVal)
{
	if(cvar == g_hCvarNoScope)
	{
		g_bNoScope = GetConVarBool(g_hCvarNoScope);
	}
}

public Action OnPlayerRunCmd(int client, int &button, int &impulse, float vel[3], float angles[3], int &weapon, int &subtype, int &cmdnum, int &tickcount, int &seed, int mouse[2])
{
	if(g_bNoScope)
	{
		if((button & 2048))
		{
			button &= ~2048;
			return Plugin_Changed;
		}
	}
	return Plugin_Continue;
}