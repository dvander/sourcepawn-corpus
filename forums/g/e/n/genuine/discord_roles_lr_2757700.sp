#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <discord_utilities>
#include <lvl_ranks>

KeyValues KV;

public Plugin myinfo =
{
	name = "[DU] Give roles by rank & top",
	author = "GARAYEV",
	version = "1.0",
	url = "www.garayev-sp.ru & Discord: GARAYEV#9999"
};

public void OnPluginStart()
{
    char szPath[PLATFORM_MAX_PATH];
    KV = new KeyValues("DISCORD_ROLES_LR");
    BuildPath(Path_SM, szPath, PLATFORM_MAX_PATH, "configs/discord_roles_lr.ini");

    if(!KV.ImportFromFile(szPath))
        SetFailState("DISCORD_ROLES_LR - Config file not found");		

    HookEvent("player_connect_full", Event_PlayerConnect);
}

public void Event_PlayerConnect(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));
    int iRank = LR_GetClientInfo(client, ST_RANK);
    int iTop = LR_GetClientInfo(client, ST_PLACEINTOP);

    char sRole[32];

    KV.Rewind();

    if(KV.GotoFirstSubKey(true) && IsValidClient(client))
    {
        do
        {
            if(KV.GetSectionName(sRole, sizeof(sRole)))
            {
                int iRanki = KV.GetNum("rank", 0);
                int iTopi = KV.GetNum("top", 0);

                if(iRanki > 0)
                {
                    if(iRank == iRanki)
                        DU_AddRole(client, sRole);
                    else if(iRank > iRanki || iRank < iRanki)
                        DU_DeleteRole(client, sRole);
                }
                if(iTopi > 0)
                {
                    if(iTop == iTopi)
                        DU_AddRole(client, sRole);
                    else if(iTop > iTopi || iTop < iTopi)
                        DU_DeleteRole(client, sRole);
                }
            }
        }
        while(KV.GotoNextKey(true));
    }
}

stock bool IsValidClient(int client)
{
	if((1 <= client <= MaxClients) 
	&& IsClientInGame(client) 
	&& !IsFakeClient(client)
	&& DU_IsChecked(client)	
	&& DU_IsMember(client)
	&& IsClientConnected(client))
		return true;
	return false;
}