#include <sourcemod>
#include <sdktools>
#define PLUGIN_VERSION "1.0"
public Plugin:myinfo =
{
	name = "[L4D2] Team_Deathmatch",
	author = "Fleep",
	description = "Hides Admin who types !invisible, intended to catch aimbots",
	version = PLUGIN_VERSION,
	url = ""
}

public OnPluginStart()
{
	decl String:game[16]
	GetGameFolderName(game, sizeof(game))
	//and don't load if it's not L4D2.
	if (!StrEqual(game, "left4dead", false) &&
			!StrEqual(game, "left4dead2", false))
	{
		SetFailState("Plugin supports Left 4 Dead and Left 4 Dead 2 only.");
		return;
	}
	CreateConVar("Make_me_invisible", PLUGIN_VERSION, "Make_me_invisible Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD)
	AutoExecConfig(true, "L4D2_invisible_me");
	RegAdminCmd("invisible", Hideme,ADMFLAG_GENERIC);
}

public Action:Hideme(client, args)
{	
SetEntityRenderMode(client, RENDER_TRANSCOLOR);//makes you invisible
SetEntityRenderColor(client, 255, 255, 255, 0);
}