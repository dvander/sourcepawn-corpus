#pragma newdecls required
#include <sourcemod>
#include <sdktools>

#define CVAR_FLAGS				FCVAR_NOTIFY

public Plugin myinfo = 
{
	name = "[L4D] Pos Random Test",
	author = "JOSHE GATITO SPARTANSKII >>>",
	description = "Prueba todos los lugares disponibles en este mapa.",
	version = "1.0",
	url = "https://steamcommunity.com/id/joshegatito/"
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion test = GetEngineVersion();
	if (test != Engine_Left4Dead)
	{
		strcopy(error, err_max, "Plugin only supports Left 4 Dead 1.");
		return APLRes_SilentFailure;
	}
	return APLRes_Success;
}

public void OnPluginStart()
{	
	RegAdminCmd("sm_testpos", CmdTestPosition, ADMFLAG_SLAY, "Prueba todos los lugares disponibles en este mapa");
}

public Action CmdTestPosition(int client, int args)
{
	float pos[3];
	pos = GetRandomRespawnPos()
	TeleportEntity(client, pos, NULL_VECTOR, NULL_VECTOR);
} 

float GetRandomRespawnPos()
{
	float pos[3];
	char map[256];
	GetCurrentMap(map, sizeof(map));
		
	if(StrEqual(map, "dm_crossfire"))
	{
		switch(GetRandomInt(1,12))
		{
			case 1:
			{
				pos[0] = -596.9;
				pos[1] = -204.9;
				pos[2] = -104.9;
			}
			case 2:
			{
				pos[0] = -1465.0;
				pos[1] = 607.0;
				pos[2] = 59.4;
			}
			case 3:
			{
				pos[0] = -2052.79;
				pos[1] = 33.10;
				pos[2] = 55.03;
			}
			case 4:
			{
				pos[0] = -2017.0;
				pos[1] = -880.9;
				pos[2] = -104.9;
			}
			case 5:
			{
				pos[0] = 2074.9;
				pos[1] = -530.0;
				pos[2] = -296.9;
			}
			case 6:
			{
				pos[0] = 2074.9;
				pos[1] = 776.0;
				pos[2] = -296.9;
			}
			case 7:
			{
				pos[0] = 1448.9;
				pos[1] = 22.0;
				pos[2] = -168.9;
			}
			case 8:
			{
				pos[0] = 975.97;
				pos[1] = 659.40;
				pos[2] = -104.97;
			}
			case 9:
			{
				pos[0] = -1253.03;
				pos[1] = 1000.97;
				pos[2] = -254.52;
			}
			case 10:
			{
				pos[0] = -1788.00;
				pos[1] = -864.97;
				pos[2] = 55.03;
			}
			case 11:
			{
				pos[0] = -416.78;
				pos[1] = 4.13;
				pos[2] = 64.03;
			}
			case 12:
			{
				pos[0] = -956.9;
				pos[1] = 666.9;
				pos[2] = -176.9;
			}
		}
	}
	
	else if(StrEqual(map, "l4d_hospital01_apartment"))
	{
		switch(GetRandomInt(1,6))
		{
			case 1:
			{
				pos[0] = 1908.4;
				pos[1] = 1387.9;
				pos[2] = 497.0;

			}
			case 2:
			{
				pos[0] = 3161.8;
				pos[1] = 4271.9; 
				pos[2] = 78.0;

			}
			case 3:
			{
				pos[0] = 536.0;
				pos[1] = 2127.9; 
				pos[2] = 78.0;

			}
			case 4:
			{
				pos[0] = 1814.5;
				pos[1] = 5181.3; 
				pos[2] = 78.0;

			}
			case 5:
			{
				pos[0] = 2735.9;
				pos[1] = 2607.9; 
				pos[2] = 78.0;

			}
			case 6:
			{
				pos[0] = 2608.0;
				pos[1] = 3088.0; 
				pos[2] = 78.0;

			}
			
		}
	}
	
	return pos;
} 