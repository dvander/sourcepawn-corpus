/******************************
COMPILE OPTIONS
******************************/

#pragma semicolon 1
#pragma newdecls required

/******************************
NECESSARY INCLUDES
******************************/

#include <sourcemod>
#include <sdktools>

/******************************
PLUGIN DEFINES
******************************/

#define MAX_BUTTONS 25

/*Setting static strings*/
static const char
	/*Plugin Info*/
	PL_NAME[]		 = "Footsteps",
	PL_AUTHOR[]		 = "Peter Brev",
	PL_DESCRIPTION[] = "Footsteps",
	PL_VERSION[]	 = "1.0.0";

/******************************
PLUGIN FLOATS
******************************/
float  gfVolume		 = 1.0;

/******************************
PLUGIN BOOLEANS
******************************/
bool   gbLate;

/******************************
PLUGIN CONVARS
******************************/
ConVar gCvar;

/******************************
PLUGIN STRINGS
******************************/
char   g_sFootstepSnds[52][75] = {
	  "player/footsteps/ladder1.wav",
	  "player/footsteps/ladder2.wav",
	  "player/footsteps/ladder3.wav",
	  "player/footsteps/ladder4.wav",
	  "player/footsteps/concrete1.wav",
	  "player/footsteps/concrete2.wav",
	  "player/footsteps/concrete3.wav",
	  "player/footsteps/concrete4.wav",
	  "player/footsteps/dirt4.wav",
	  "player/footsteps/dirt2.wav",
	  "player/footsteps/dirt3.wav",
	  "player/footsteps/dirt4.wav",
	  "player/footsteps/duct1.wav",
	  "player/footsteps/duct2.wav",
	  "player/footsteps/duct3.wav",
	  "player/footsteps/duct4.wav",
	  "player/footsteps/grass1.wav",
	  "player/footsteps/grass2.wav",
	  "player/footsteps/grass3.wav",
	  "player/footsteps/grass4.wav",
	  "player/footsteps/gravel1.wav",
	  "player/footsteps/gravel2.wav",
	  "player/footsteps/gravel3.wav",
	  "player/footsteps/gravel4.wav",
	  "player/footsteps/metalgrate1.wav",
	  "player/footsteps/metalgrate2.wav",
	  "player/footsteps/metalgrate3.wav",
	  "player/footsteps/metalgrate4.wav",
	  "player/footsteps/mud1.wav",
	  "player/footsteps/mud2.wav",
	  "player/footsteps/mud3.wav",
	  "player/footsteps/mud4.wav",
	  "player/footsteps/sand1.wav",
	  "player/footsteps/sand2.wav",
	  "player/footsteps/sand3.wav",
	  "player/footsteps/sand4.wav",
	  "player/footsteps/wood1.wav",
	  "player/footsteps/wood2.wav",
	  "player/footsteps/wood3.wav",
	  "player/footsteps/wood4.wav",
	  "physics/glass/glass_sheet_step1.wav",
	  "physics/glass/glass_sheet_step2.wav",
	  "physics/glass/glass_sheet_step3.wav",
	  "physics/glass/glass_sheet_step4.wav",
	  "physics/plaster/ceiling_tile_step1.wav",
	  "physics/plaster/ceiling_tile_step2.wav",
	  "physics/plaster/ceiling_tile_step3.wav",
	  "physics/plaster/ceiling_tile_step4.wav",
	  "physics/plaster/drywall_footstep1.wav",
	  "physics/plaster/drywall_footstep2.wav",
	  "physics/plaster/drywall_footstep3.wav",
	  "physics/plaster/drywall_footstep4.wav"
};

/******************************
PLUGIN INFO
******************************/
public Plugin myinfo =
{
	name		= PL_NAME,
	author		= PL_AUTHOR,
	description = PL_DESCRIPTION,
	version		= PL_VERSION
};

/******************************
LATE LOAD
******************************/
public APLRes AskPluginLoad2(Handle hPlugin, bool bLate, char[] sError, int iLen)
{
	gbLate = bLate;
	return APLRes_Success;
}

/******************************
INITIATE THE PLUGIN
******************************/
public void OnPluginStart()
{
	/*GAME CHECK*/
	EngineVersion engine = GetEngineVersion();

	if (engine != Engine_HL2DM)
	{
		SetFailState("[HL2MP] This plugin is intended for Half-Life 2: Deathmatch only.");
	}

	gCvar = FindConVar("sv_footsteps");

	AddNormalSoundHook(OnSound);

	for (int i = 1; i < sizeof(g_sFootstepSnds); i++)
	{
		PrecacheSound(g_sFootstepSnds[i]);
	}

	if (gbLate)
	{
		ReplicateToAll("0");
	}
}

/******************************
PLUGIN FUNCTIONS
******************************/
public void OnClientPutInServer(int iClient)
{
	ReplicateTo(iClient, "0");
}

public Action OnSound(int iClients[MAXPLAYERS], int &iNumClients, char sSample[PLATFORM_MAX_PATH], int &iEntity, int &iChannel, float &fVolume, int &iLevel, int &iPitch, int &iFlags, char sEntry[PLATFORM_MAX_PATH], int &seed)
{
	if (iEntity < 1 || iEntity > MaxClients || !IsClientInGame(iEntity))
		return Plugin_Continue;

	if (StrContains(sSample, "npc/metropolice/gear", false) != -1 || StrContains(sSample, "npc/combine_soldier/gear", false) != -1 || StrContains(sSample, "npc/footsteps/hardboot_generic", false) != -1)
	{
		float pos[3];
		float ang[3];
		GetClientAbsOrigin(iEntity, pos);
		ang[0] = 90.0;
		ang[1] = 0.0;
		ang[2] = 0.0;
		char   surfname[128];
		Handle trace	 = TR_TraceRayFilterEx(pos, ang, MASK_SHOT | MASK_SHOT_HULL | MASK_WATER, RayType_Infinite, TraceEntityFilter, iEntity);
		int	   surfflags = TR_GetSurfaceFlags(trace);
		TR_GetSurfaceName(trace, surfname, sizeof(surfname));
		int surfprops = TR_GetSurfaceProps(trace);
		CloseHandle(trace);
		// PrintToChat(iEntity, "TRMaterial Flags %i Props %i Name %s", surfflags, surfprops, surfname);

		if (GetEntityMoveType(iEntity) == MOVETYPE_LADDER)
		{
			Format(sSample, sizeof(sSample), "player/footsteps/ladder%i.wav", GetRandomInt(1, 4));
		}

		else if (StrContains(surfname, "ceiling_tile", false) != -1)
		{
			Format(sSample, sizeof(sSample), "physics/plaster/ceiling_tile_step%i.wav", GetRandomInt(1, 4));
		}

		else if (StrContains(surfname, "tile", false) != -1)
		{
			Format(sSample, sizeof(sSample), "player/footsteps/tile%i.wav", GetRandomInt(1, 4));
		}

		else if (StrContains(surfname, "metalduct", false) != -1)
		{
			Format(sSample, sizeof(sSample), "player/footsteps/duct%i.wav", GetRandomInt(1, 4));
		}

		else if (StrContains(surfname, "metalgrate", false) != -1)
		{
			Format(sSample, sizeof(sSample), "player/footsteps/metalgrate%i.wav", GetRandomInt(1, 4));
		}

		else if (StrContains(surfname, "metal", false) != -1)
		{
			Format(sSample, sizeof(sSample), "player/footsteps/metal%i.wav", GetRandomInt(1, 4));
		}

		else if (StrContains(surfname, "mud", false) != -1)
		{
			Format(sSample, sizeof(sSample), "player/footsteps/mud%i.wav", GetRandomInt(1, 4));
		}

		else if (StrContains(surfname, "sand", false) != -1)
		{
			Format(sSample, sizeof(sSample), "player/footsteps/sand%i.wav", GetRandomInt(1, 4));
		}

		else if (StrContains(surfname, "wood", false) != -1)
		{
			Format(sSample, sizeof(sSample), "player/footsteps/wood%i.wav", GetRandomInt(1, 4));
		}

		else if (StrContains(surfname, "dirt", false) != -1)
		{
			Format(sSample, sizeof(sSample), "player/footsteps/dirt%i.wav", GetRandomInt(1, 4));
		}

		else if (StrContains(surfname, "gravel", false) != -1)
		{
			Format(sSample, sizeof(sSample), "player/footsteps/gravel%i.wav", GetRandomInt(1, 4));
		}

		else if (StrContains(surfname, "grass", false) != -1)
		{
			Format(sSample, sizeof(sSample), "player/footsteps/grass%i.wav", GetRandomInt(1, 4));
		}

		else if (StrContains(surfname, "glass", false) != -1)
		{
			Format(sSample, sizeof(sSample), "physics/glass/glass_sheet_step%i.wav", GetRandomInt(1, 4));
		}

		else if (StrContains(surfname, "plaster", false) != -1)
		{
			Format(sSample, sizeof(sSample), "physics/plaster/drywall_footstep%i.wav", GetRandomInt(1, 4));
		}

		else
		{
			Format(sSample, sizeof(sSample), "player/footsteps/concrete%i.wav", GetRandomInt(1, 4));
		}
		// Format(sSample, sizeof(sSample), "player/footsteps/concrete%i.wav", GetRandomInt(1, 4));
	}
	else if (StrContains(sSample, "npc/footsteps/hardboot_generic", false) == -1) {
		// Not a footstep sound.
		return Plugin_Continue;
	}

	for (int iClient = 1; iClient <= MaxClients; iClient++)
	{
		if (!IsClientConnected(iClient) || !IsClientInGame(iClient))
			continue;

		EmitSoundToClient(iClient, sSample, iEntity, iChannel, iLevel, iFlags, fVolume * gfVolume, iPitch);
	}

	return Plugin_Changed;
}

void ReplicateTo(int iClient, const char[] sValue)
{
	if (IsClientInGame(iClient) && !IsFakeClient(iClient))
	{
		gCvar.ReplicateToClient(iClient, sValue);
	}
}

void ReplicateToAll(const char[] sValue)
{
	for (int iClient = 1; iClient <= MaxClients; iClient++)
	{
		ReplicateTo(iClient, sValue);
	}
}

bool TraceEntityFilter(int entity, int contentsMask, any data)
{
	if (entity == data)
	{
		return true;
	}
	if (entity > 0 && entity <= MaxClients)
	{
		return false;
	}
	return false;
}