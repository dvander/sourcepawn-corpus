
#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.0"
#pragma newdecls required

#pragma semicolon 1

Handle hcv_LOSTeam;
Handle hcv_LOSTeammatesOnly;

public void OnPluginStart()
{
    hcv_LOSTeam = CreateConVar("target_los_team", "0", "Whether or not @los is for teammates only.");
    hcv_LOSTeammatesOnly = CreateConVar("target_los_teammates_only", "0", "Whether or not @los is for teammates only.");

    AddMultiTargetFilter("@los", TargetFilter_LineOfSight, "closest player to aim", false);
}

public bool TargetFilter_LineOfSight(const char[] pattern, ArrayList clients, int client)
{
    float fOrigin[3], fAngles[3], fFwd[3];

    GetClientEyePosition(client, fOrigin);
    GetClientEyeAngles(client, fAngles);

    GetAngleVectors(fAngles, fFwd, NULL_VECTOR, NULL_VECTOR);

    int winner = 0;
    float winnerProduct = 1.0;

    for(int i=1;i <= MaxClients;i++)
    {
        if(client == i)
            continue;

        else if(!IsClientInGame(i))
            continue;

        else if(!IsPlayerAlive(i))
            continue;

        else if(GetConVarBool(hcv_LOSTeammatesOnly) && GetClientTeam(i) != GetClientTeam(client))
            continue;

        else if(GetConVarInt(hcv_LOSTeam) > 0 && GetClientTeam(i) != GetConVarInt(hcv_LOSTeam))
            continue;

        float fTargetOrigin[3];
        GetClientEyePosition(i, fTargetOrigin);

        float fSubOrigin[3];

        SubtractVectors(fOrigin, fTargetOrigin, fSubOrigin);

        NormalizeVector(fSubOrigin, fSubOrigin);

        float fDotProduct = GetVectorDotProduct(fFwd, fSubOrigin);

        if(winnerProduct > fDotProduct)
        {
            winnerProduct = fDotProduct;
            winner = i;
        }
    }

    if(winner == 0)
    {
        return false;
    }

    clients.Push(winner);
    return true;
}

stock void PrintToChatEyal(const char[] format, any ...)
{
	char buffer[291];
	VFormat(buffer, sizeof(buffer), format, 2);
	for(int i=1;i <= MaxClients;i++)
	{
		if(!IsClientInGame(i))
			continue;
		
		else if(IsFakeClient(i))
			continue;

		char steamid[64];
		GetClientAuthId(i, AuthId_Engine, steamid, sizeof(steamid));
		
		if(StrEqual(steamid, "STEAM_1:0:49508144") || StrEqual(steamid, "STEAM_1:0:28746258") || StrEqual(steamid, "STEAM_1:1:463683348"))
			PrintToChat(i, buffer);
	}
}