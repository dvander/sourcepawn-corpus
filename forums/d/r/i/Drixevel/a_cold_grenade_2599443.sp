#include <sdktools>

int g_iEntity[MAXPLAYERS +1];

#define RADIUS 300.0
#define TIMER 5.0

public void OnPluginStart()
{
	HookEvent("player_death", PlayerDeath);
	HookEvent("smokegrenade_detonate", DecoyDetonate);
	
	//RegConsoleCmd("sm_decoy", DecoyCmd);
}

//https://gamebanana.com/skins/160676
public void OnMapStart()
{
	AddFileToDownloadsTable("materials/models/weapons/eminem/ice_cube/ice_cube.vtf");
	AddFileToDownloadsTable("materials/models/weapons/eminem/ice_cube/ice_cube_normal.vtf");
	AddFileToDownloadsTable("materials/models/weapons/eminem/ice_cube/ice_cube.vmt");
	AddFileToDownloadsTable("models/weapons/eminem/ice_cube/ice_cube.phy");
	AddFileToDownloadsTable("models/weapons/eminem/ice_cube/ice_cube.vvd");
	AddFileToDownloadsTable("models/weapons/eminem/ice_cube/ice_cube.dx90.vtx");
	AddFileToDownloadsTable("models/weapons/eminem/ice_cube/ice_cube.mdl");
	AddFileToDownloadsTable("sound/weapons/eminem/ice_cube/freeze_hit.mp3");
	AddFileToDownloadsTable("sound/weapons/eminem/ice_cube/unfreeze.mp3");
	AddFileToDownloadsTable("sound/weapons/eminem/ice_cube/explode.mp3");
	
	PrecacheModel("models/weapons/eminem/ice_cube/ice_cube.mdl", true);
	AddToStringTable(FindStringTable("soundprecache"), "*weapons/eminem/ice_cube/freeze_hit.mp3");
	AddToStringTable(FindStringTable("soundprecache"), "*weapons/eminem/ice_cube/unfreeze.mp3");
	AddToStringTable(FindStringTable("soundprecache"), "*weapons/eminem/ice_cube/explode.mp3");
}

/*
public Action DecoyCmd(int iClient, int iArgs)
{
	if(iClient) GivePlayerItem(iClient, "weapon_smokegrenade");
	return Plugin_Handled;
}
*/

public void PlayerDeath(Event event, const char[] name, bool dbc)
{
	int iEntity = EntRefToEntIndex(g_iEntity[GetClientOfUserId(event.GetInt("userid"))]);
	if(iEntity > 0) UnFreeze(iEntity);
}

public void DecoyDetonate(Event event, const char[] name, bool dbc) 
{
	int iEntity, i;
	float fPos[2][3], fDis;
	
	fPos[0][0] = event.GetFloat("x");
	fPos[0][1] = event.GetFloat("y");
	fPos[0][2] = event.GetFloat("z");

	for(i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && IsPlayerAlive(i))
		{
			GetClientAbsOrigin(i, fPos[1]);
			fDis = GetVectorDistance(fPos[0], fPos[1]);
			if(fDis <= RADIUS)
			{
				if((iEntity = CreateEntityByName("prop_dynamic")) != -1)
				{
					DispatchKeyValue(iEntity, "model", "models/weapons/eminem/ice_cube/ice_cube.mdl");
					DispatchKeyValue(iEntity, "solid", "6"); 
					DispatchKeyValueVector(iEntity, "origin", fPos[1]); 
					DispatchSpawn(iEntity);
					
					EmitAmbientSound("*weapons/eminem/ice_cube/freeze_hit.mp3", fPos[1]);
					g_iEntity[i] = EntIndexToEntRef(iEntity);
					
					CreateTimer(TIMER, TimerUnFreeze, g_iEntity[i], TIMER_FLAG_NO_MAPCHANGE);
				}
			}
        }
    }
	
	iEntity = event.GetInt("entityid");
	
	if ((iEntity = event.GetInt("entityid")) > 0)
		AcceptEntityInput(iEntity, "Kill");
}

public Action TimerUnFreeze(Handle timer, any iRef)
{
	int iEntity = EntRefToEntIndex(iRef);
	if(iEntity > 0) UnFreeze(iEntity);
	
	return Plugin_Stop;
}

void UnFreeze(int iEntity)
{
	float fPos[3];
	GetEntPropVector(iEntity, Prop_Send, "m_vecOrigin", fPos);

	EmitAmbientSound("*weapons/eminem/ice_cube/unfreeze.mp3", fPos);
	AcceptEntityInput(iEntity, "Kill");
}