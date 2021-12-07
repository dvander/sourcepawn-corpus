#pragma semicolon 1

#include <sourcemod>
#include <sdktools_functions>

#define PLUGIN_VERSION "0.1"
public Plugin:myinfo =
{
	name = "L4D ServerPos",
	author = "devicenull",
	description = "Allows you to set the server position",
	version = PLUGIN_VERSION,
	url = "http://www.devicenull.org/"
};

new GameRules = -1;
new RankOffs = -1;

public OnPluginStart()
{
	CreateConVar("l4drank_version", PLUGIN_VERSION, "L4D Rank Version", FCVAR_PLUGIN|FCVAR_REPLICATED|FCVAR_NOTIFY);
	new Handle:rank = CreateConVar("l4d_rank","0","Rank of the server");
	HookConVarChange(rank,updateRank);
}

public OnMapStart()
{
	new String:name[64];
	for (new i=0;i<GetMaxEntities();i++)
	{
		if (!IsValidEdict(i)) continue;
		GetEdictClassname(i,name,sizeof(name));
		if (StrEqual(name,"terror_gamerules"))
		{
			GameRules = i;
			break;
		}
	}
	RankOffs = FindSendPropInfo("CTerrorGameRulesProxy","m_iServerRank");
	PrintToServer("Found CTerrorGameRulesProxy at %i - m_iServerRank at %i",GameRules,RankOffs);
}

public updateRank(Handle:convar, const String:oldValue[], const String:newValue[])
{
	SetEntData(GameRules,RankOffs,StringToInt(newValue),4,true);
}
