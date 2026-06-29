#include <sourcemod>
#include <sdktools>
#include <l4d2sendproxy>
#pragma semicolon 1

static const String:MODEL_ZOEY[] = "models/survivors/survivor_teenangst.mdl";

public OnClientPostAdminCheck(client)
{
	SendProxy_Hook(client, "m_survivorCharacter", Prop_Int, ProxyCallBack);
}

public OnPluginStart()
{
	RegConsoleCmd("sm_z", ZoeyUse, "Changes your survivor character into Zoey");
	RegConsoleCmd("sm_zoey", ZoeyUse, "Changes your survivor character into Zoey");
}

public Action:ZoeyUse(client, args)
{
	SendProxy_Hook(client, "m_survivorCharacter", Prop_Int, ProxyCallBack);
}
public Action:ProxyCallBack(entity, const String:propname[], &iValue, element)
{
	if (IsZoeyCharacter(entity))
	{
		iValue = 5;
		return Plugin_Changed;
	}
	return Plugin_Continue;
}

stock bool:IsZoeyCharacter(client)
{
	if (IsSurvivor(client))
	{
		decl String:model[42];
		GetEntPropString(client, Prop_Data, "m_ModelName", model, sizeof(model));
		{
			if (StrEqual(model, MODEL_ZOEY, false))
			{
				return true;
			}
		}
	}
	return false;
}

stock bool:IsSurvivor(client)
{
	if (client > 0 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == 2)
	{
		return true;
	}
	return false;
} 