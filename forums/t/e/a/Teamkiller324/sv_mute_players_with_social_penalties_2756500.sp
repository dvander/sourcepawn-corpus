#pragma		semicolon	1
#pragma		newdecls	required

public	Plugin	myinfo	=
{
	name		=	"[CS:GO] sv_mute_players_with_social_penalties Cvar Unlock",
	author		=	"https://steamcommunity.com/id/Teamkiller324",
	description	=	"Unlocks the cvar",
	version		=	"0.1",
	url			=	"https://steamcommunity.com/id/Teamkiller324"
}

public void OnPluginStart()
{
	if(GetEngineVersion() != Engine_CSGO)
	{
		ThrowError("CS:GO Only");
	}
	
	ConVar cvar = FindConVar("sv_mute_players_with_social_penalties");
	
	int flags = cvar.Flags;
	
	flags &= ~FCVAR_DEVELOPMENTONLY;
	
	cvar.Flags = flags;
}