#include <sourcemod>
#include <sdktools>
#pragma semicolon 1

public Plugin:myinfo = 
{
	name = "[TF2] Spawn sentry",
	author = "Pelipoika",
	description = "Spawn a fully functional TF2 sentry.",
	version = "1.0",
	url = "http://www.sourcemod.net/plugins.php?cat=0&mod=-1&title=&author=Pelipoika&description=&search=1"
}

public OnPluginStart()
{
	RegAdminCmd("sm_sentry", CMD_TEST, ADMFLAG_ROOT);
}

public Action:CMD_TEST(client, args)
{
	if(IsValidClient(client))
	{
		decl Float:Position[3], Float:Angle[3];
		GetClientEyeAngles(client, Angle);
		Angle[0] = 0.0;
		if(!SetTeleportEndPoint(client, Position))
		{
			PrintToChat(client, "[SM] Could not find spawn point.");
			return Plugin_Handled;
		}
		
		Position[2] -= 15.0;
		
		new sentry = CreateEntityByName("obj_sentrygun");
		if(IsValidEntity(sentry))
		{
			//SetEntProp(sentry, Prop_Data, "m_nDefaultUpgradeLevel", 0);
			DispatchSpawn(sentry);
			TeleportEntity(sentry, Position, Angle, NULL_VECTOR);
			AcceptEntityInput(sentry, "SetBuilder", client);
			SetEntProp(sentry, Prop_Data, "m_nDefaultUpgradeLevel", 0);
			SetEntProp(sentry, Prop_Send, "m_iUpgradeLevel", 1);
			SetEntProp(sentry, Prop_Send, "m_iHighestUpgradeLevel", 1);
			SetEntProp(sentry, Prop_Data, "m_spawnflags", 4);
			//2 : Invulnerable
			//4 : Upgradable
			//8 : Infinite Ammo
			SetEntProp(sentry, Prop_Send, "m_bBuilding", 1);		//This is crucial
			SetEntProp(sentry, Prop_Send, "m_nSkin", GetClientTeam(client) - 2);
		}
		else
			PrintToChat(client, "[SM] Could not spawn sentry");
	}
	
	return Plugin_Handled;
}

bool:SetTeleportEndPoint(client, Float:Position[3])
{
	decl Float:vAngles[3];
	decl Float:vOrigin[3];
	decl Float:vBuffer[3];
	decl Float:vStart[3];
	decl Float:Distance;
	
	GetClientEyePosition(client,vOrigin);
	GetClientEyeAngles(client, vAngles);
	
    //get endpoint for teleport
	new Handle:trace = TR_TraceRayFilterEx(vOrigin, vAngles, MASK_SHOT, RayType_Infinite, TraceEntityFilterPlayer2);

	if(TR_DidHit(trace))
	{   	 
   	 	TR_GetEndPosition(vStart, trace);
		GetVectorDistance(vOrigin, vStart, false);
		Distance = -35.0;
   	 	GetAngleVectors(vAngles, vBuffer, NULL_VECTOR, NULL_VECTOR);
		Position[0] = vStart[0] + (vBuffer[0]*Distance);
		Position[1] = vStart[1] + (vBuffer[1]*Distance);
		Position[2] = vStart[2] + (vBuffer[2]*Distance);
	}
	else
	{
		CloseHandle(trace);
		return false;
	}
	
	CloseHandle(trace);
	return true;
}

public bool:TraceEntityFilterPlayer2(entity, contentsMask)
{
	return entity > GetMaxClients() || !entity;
}

stock bool:IsValidClient(client)
{
	if(client <= 0 ) return false;
	if(client > MaxClients) return false;
	if(!IsClientConnected(client)) return false;
	return IsClientInGame(client);
}