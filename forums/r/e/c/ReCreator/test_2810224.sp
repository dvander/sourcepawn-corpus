#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
char Laser;

public void OnPluginStart()
{	
	RegConsoleCmd("sm_show", GoAwayFromKeyboard);
}

public void OnMapStart()
{
	Laser = PrecacheModel("sprites/laser.vmt");
}

public Action GoAwayFromKeyboard(int client, int args)
{
	int entity = GetClientAimTarget(client, false);
	
	char classname[32];
	float vPos[3], vMins[3], vMaxs[3];
	
	if(IsValidEntity(entity))
	{
		GetEdictClassname(entity, classname, sizeof(classname));
		
		if(StrEqual(classname, "env_player_blocker"))
		{
			GetEntPropVector(entity, Prop_Send, "m_vecOrigin", vPos);
			GetEntPropVector(entity, Prop_Send, "m_vecMaxs", vMaxs);
			GetEntPropVector(entity, Prop_Send, "m_vecMins", vMins);

			if( vMins[0] == vMaxs[0] && vMins[1] == vMaxs[1] && vMins[2] == vMaxs[2] )
			{
				vMins = view_as<float>({ -15.0, -15.0, -15.0 });
				vMaxs = view_as<float>({ 15.0, 15.0, 15.0 });
			}
			else
			{
				AddVectors(vPos, vMaxs, vMaxs);
				AddVectors(vPos, vMins, vMins);
			}

			float vPos1[3], vPos2[3], vPos3[3], vPos4[3], vPos5[3], vPos6[3];
			vPos1 = vMaxs;
			vPos1[0] = vMins[0];
			vPos2 = vMaxs;
			vPos2[1] = vMins[1];
			vPos3 = vMaxs;
			vPos3[2] = vMins[2];
			vPos4 = vMins;
			vPos4[0] = vMaxs[0];
			vPos5 = vMins;
			vPos5[1] = vMaxs[1];
			vPos6 = vMins;
			vPos6[2] = vMaxs[2];

			TE_SendBeam(vMaxs, vPos1);
			TE_SendBeam(vMaxs, vPos2);
			TE_SendBeam(vMaxs, vPos3);
			TE_SendBeam(vPos6, vPos1);
			TE_SendBeam(vPos6, vPos2);
			TE_SendBeam(vPos6, vMins);
			TE_SendBeam(vPos4, vMins);
			TE_SendBeam(vPos5, vMins);
			TE_SendBeam(vPos5, vPos1);
			TE_SendBeam(vPos5, vPos3);
			TE_SendBeam(vPos4, vPos3);
			TE_SendBeam(vPos4, vPos2);			
		}
	}
	else
		PrintToChatAll("No block found.");

	return Plugin_Handled;
}


stock void TE_SendBeam(const float vMins[3], const float vMaxs[3])
{
	TE_SetupBeamPoints(vMins, vMaxs, Laser, 0, 0, 0, 60.0, 5.0, 5.0, 1, 0.0, {255, 100, 100, 255}, 0);
	TE_SendToAll();
} 