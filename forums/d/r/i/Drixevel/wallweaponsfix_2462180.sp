#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

ConVar hConVar_Status;
bool bLate;

public Plugin myinfo = 
{
	name = "Wall Weapons Fix",
	author = "Nigty's (credits: blodia, PowerLord), Fixed/Upgraded (Drixevel)",
	description = "Prevents players from picking up weapons behind solid objects such as walls and props.",
	version = "1.0.0",
	url = "www.alliedmods.net"
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	bLate = late;
	return APLRes_Success;
}

public void OnPluginStart()
{
	hConVar_Status = CreateConVar("sm_wallweaponsfix_status", "1", "Status of the plugin.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
}

public void OnConfigsExecuted()
{
	if (bLate)
	{
		for (int i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i))
			{
				OnClientPutInServer(i);
			}
		}
		
		bLate = false;
	}
}

public void OnClientPutInServer(int client)
{
	SDKHook(client, SDKHook_WeaponCanUse, OnWeaponCanUse);
}

public Action OnWeaponCanUse(int client, int weapon)
{
	if (!GetConVarBool(hConVar_Status))
	{
		return Plugin_Continue;
	}
	
	float fStart[3];
	GetClientAbsOrigin(client, fStart);
	
	float fEnd[3];
	GetEntPropVector(weapon, Prop_Send, "m_vecOrigin", fEnd);
	
	DataPack data = CreateDataPack();
	WritePackCell(data, client);
	WritePackCell(data, weapon);
	
	Handle hTrace = TR_TraceRayFilterEx(fStart, fEnd, MASK_SOLID, RayType_EndPoint, Filter_ClientSelf, data);

	if (TR_DidHit(hTrace))
	{
		CloseHandle(hTrace);
		return Plugin_Stop;
	}
	
	CloseHandle(hTrace);
	return Plugin_Continue;
}

public bool Filter_ClientSelf(int entity, int contentsMask, any data)
{
	ResetPack(data);

	int client = ReadPackCell(data);
	int weapon = ReadPackCell(data);
	
	CloseHandle(data);
	
	if (entity != client && entity != weapon)
	{
		return true;
	}
	
	return false;
}  