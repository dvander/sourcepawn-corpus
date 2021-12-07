#include <sourcemod>

#undef REQUIRE_EXTENSIONS
#include <cstrike>

#undef REQUIRE_PLUGIN
#include <updater>

#pragma semicolon 1

#define UPDATE_URL "https://dl.dropbox.com/u/80272443/resetscore/resetscore.txt"

#define PLUGIN_VERSION "2.6.0"

enum GameMode(+=1)
{
	Game_CSS = 0,
	Game_DoDS,
	Game_TF2,
	Game_CSGO
};

new GameMode:gM_Game;

new Handle:gH_Enabled = INVALID_HANDLE;

new bool:gB_Enabled;

public Plugin:myinfo = 
{
	name = "Resetscore",
	author = "shavit",
	description = "You can reset your score (kills, deaths. etc...) using a simple command.",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/member.php?u=163134"
}

public OnPluginStart()
{
	if(LibraryExists("updater"))
    {
        Updater_AddPlugin(UPDATE_URL);
    }
	
	CreateConVar("sm_resetscore_version", PLUGIN_VERSION, "Resetscore's version", FCVAR_NOTIFY|FCVAR_PLUGIN|FCVAR_DONTRECORD);
	
	gH_Enabled = CreateConVar("sm_resetscore_enabled", "1", "Resetscore enabled?", FCVAR_PLUGIN, true, 0.0, true, 1.0);	
	
	gB_Enabled = GetConVarBool(gH_Enabled);
	
	HookConVarChange(gH_Enabled, ConVarChanged);
	
	RegConsoleCmd("sm_resetscore", Command_RS, "Reset your score");
	RegConsoleCmd("sm_rs", Command_RS, "Reset your score");
	
	LoadTranslations("resetscore.phrases");
	
	decl String:Mod[16];
	GetGameFolderName(Mod, 16);
	
	if(StrContains(Mod, "cstrike", false) != -1)
	{
		gM_Game = Game_CSS;
	}
	
	else if(StrContains(Mod, "dod", false) != -1)
	{
		gM_Game = Game_DoDS;
	}
	
	else if(StrEqual(Mod, "csgo", false))
	{
		gM_Game = Game_CSGO;
	}
	
	else if(StrEqual(Mod, "tf", false))
	{
		gM_Game = Game_TF2;
	}
}

public ConVarChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	gB_Enabled = StringToInt(newVal)? true:false;
}

public Action:Command_RS(client, args)
{
	if(!IsValidClient(client))
	{
		return Plugin_Handled;
	}
	
	if(!gB_Enabled)
	{
		ReplyToCommand(client, "\x04[Resetscore]\x01 %T", "DISABLED", client);
		
		return Plugin_Handled;
	}
	
	switch(gM_Game)
	{
		case Game_CSS, Game_DoDS:
		{
			SetEntProp(client, Prop_Data, "m_iFrags", 0);
			SetEntProp(client, Prop_Data, "m_iDeaths", 0);
		}
		
		case Game_CSGO:
		{
			CS_SetClientContributionScore(client, 0);
			CS_SetClientAssists(client, 0);
			SetEntProp(client, Prop_Data, "m_iFrags", 0);
			SetEntProp(client, Prop_Data, "m_iDeaths", 0);
		}
		
		case Game_TF2:
		{
			SetEntProp(client, Prop_Data, "m_iAssists", 0);
			SetEntProp(client, Prop_Send, "m_iFrags", 0);
			SetEntProp(client, Prop_Send, "m_iDeaths", 0);
		}
	}
	
	ReplyToCommand(client, "\x04[Resetscore]\x01 %T", "RESET_SCORE", client);
	
	return Plugin_Handled;
}

/**
* Checks if client is valid, ingame and safe to use.
*
* @param client			Client index.
* @param alive			Check if the client is alive.
* @return				True if the user is valid.
*/
stock bool:IsValidClient(client, bool:alive = false)
{
	return (client >= 1 && client <= MaxClients && IsClientConnected(client) && IsClientInGame(client) && (alive == false || IsPlayerAlive(client)));
}
