//includes
#include <sourcemod>
#include <cstrike>

//Compiler Options
#pragma semicolon 1
#pragma newdecls required

//ConVars
ConVar gc_bPlugin;
ConVar gc_bnoteam;

public Plugin myinfo =
{
	name = "Admin & PlayerTags",
	description = "Define player tags in stats with translation",
	author = "shanapu",
	version = "5.0",
	url = "shanapu.de"
}

public void OnPluginStart()
{
	// Translation
	LoadTranslations("AdminPlayerTags.phrases");
	
	CreateConVar("sm_admintag_version", "5.0", "The version of this SourceMod plugin", FCVAR_SPONLY|FCVAR_PLUGIN|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	gc_bPlugin = CreateConVar("sm_admintag_enable", "1", "0 - disabled, 1 - enable this SourceMod plugin", _, true,  0.0, true, 1.0);
	gc_bnoteam = CreateConVar("sm_admintag_team", "1", "0 - disabled, 1 - overwrite/remove Tags for non admin (CT/T)", _, true,  0.0, true, 1.0);
	
	//Hooks
	HookEvent("player_connect", checkTag);
	HookEvent("player_team", checkTag);
	HookEvent("player_spawn", checkTag);
	HookEvent("round_start", checkTag);

}

public void OnClientPutInServer(int client)
{
	HandleTag(client);
	return;
}

public Action checkTag(Handle event, char[] name, bool dontBroadcast)
{
	CreateTimer(1.0, DelayCheck);
	return Action;
}

public Action DelayCheck(Handle timer) 
{
	for(int client = 1; client <= MaxClients; client++) if(IsClientInGame(client))
	{
		if (0 < client)
		{
			HandleTag(client);
		}
	}
	return Action;
}

public int HandleTag(int client)
{
	if(gc_bPlugin.BoolValue)
	{
		char tagsT[255], tagsCT[255], tagsVIP[255], tagsSVIP[255], tagsUVIP[255], tagsADM[255], tagsHADM[255], tagsCADM[255];
		
		if (GetUserFlagBits(client) & ADMFLAG_ROOT) 
		{
			Format(tagsHADM, sizeof(tagsHADM), "%t" ,"tags_HADM", LANG_SERVER);
			CS_SetClientClanTag(client, tagsHADM); 
		}
		else if (GetUserFlagBits(client) & ADMFLAG_BAN)
		{
			Format(tagsCADM, sizeof(tagsCADM), "%t" ,"tags_CADM", LANG_SERVER);
			CS_SetClientClanTag(client, tagsCADM); 
		}
		else if (GetUserFlagBits(client) & ADMFLAG_GENERIC)
		{
			Format(tagsADM, sizeof(tagsADM), "%t" ,"tags_ADM", LANG_SERVER);
			CS_SetClientClanTag(client, tagsADM); 
		}
		else if (GetUserFlagBits(client) & ADMFLAG_CUSTOM4)
		{
			Format(tagsUVIP, sizeof(tagsUVIP), "%t" ,"tags_UVIP", LANG_SERVER);
			CS_SetClientClanTag(client, tagsUVIP); 
		}
		else if (GetUserFlagBits(client) & ADMFLAG_CUSTOM5)
		{
			Format(tagsSVIP, sizeof(tagsSVIP), "%t" ,"tags_SVIP", LANG_SERVER);
			CS_SetClientClanTag(client, tagsSVIP); 
		}
		else if (GetUserFlagBits(client) & ADMFLAG_RESERVATION)
		{
			Format(tagsVIP, sizeof(tagsVIP), "%t" ,"tags_VIP", LANG_SERVER);
			CS_SetClientClanTag(client, tagsVIP); 
		}
		else if(gc_bnoteam.BoolValue)
		{
			if (GetClientTeam(client) == CS_TEAM_T) 
			{
				Format(tagsT, sizeof(tagsT), "%t" ,"tags_T", LANG_SERVER);
				CS_SetClientClanTag(client, tagsT);
			}
			else if (GetClientTeam(client) == CS_TEAM_CT)
			{
				Format(tagsCT, sizeof(tagsCT), "%t" ,"tags_CT", LANG_SERVER);
				CS_SetClientClanTag(client, tagsCT); 
			}
			else
			{
				CS_SetClientClanTag(client, "");  // No Flag/Team No Tag
			}
		}
	}
}
