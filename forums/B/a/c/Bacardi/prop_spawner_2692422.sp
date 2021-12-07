//Prop Spawner by FusionLock (v1.2)

#include <sourcemod>
#include <sdktools>

#pragma newdecls required

#define NAME "Prop Spawner"
#define AUTHOR "FusionLock"
#define DESCRIPTION "Allows clients to spawn props using there alias (!airboat, !blastdoor3, !citizenradio)"
#define VERSION "1.21"
#define URL "http://steamcommunity.com/profiles/76561198054654475"

char g_sPropsPath[64];

public Plugin myinfo = {name = NAME, author = AUTHOR, description = DESCRIPTION, version = VERSION, url = URL};

public void OnPluginStart()
{
	AddCommandListener(Command_Say, "say");
	AddCommandListener(Command_Say, "say_team");

	BuildPath(Path_SM, g_sPropsPath, sizeof(g_sPropsPath), "configs/prop_database.txt");
}

//Prop Spawner Command:
public Action Command_Say(int iClient, char[] sCommand, int iArgs)
{

	if(iClient == 0 || !IsClientInGame(iClient) || IsFakeClient(iClient) || !CheckCommandAccess(iClient, "prop_spawner", ADMFLAG_CHEATS))
	{
		return Plugin_Continue;
	}


	bool bIsProp;
	char sFirstArg[128], sCheckArg[128], sModel[128];

	GetCmdArg(1, sFirstArg, sizeof(sFirstArg));

	strcopy(sCheckArg, sizeof(sCheckArg), sFirstArg);

	if(ReplaceString(sCheckArg, sizeof(sCheckArg), "!", "") || ReplaceString(sCheckArg, sizeof(sCheckArg), "/", ""))
	{
		bIsProp = CheckPropDatabase(sCheckArg, sModel, sizeof(sModel));
	}else{
		return Plugin_Continue;
	}

	if(bIsProp)
	{
		SpawnEntity(iClient, sModel);
		return Plugin_Handled;
	}else{
		return Plugin_Continue;
	}
}

//Prop Spawner Forward:
public bool FilterPlayer(int iEntity, any aContentsMask)
{
	return iEntity > MaxClients;
}

//Props Spawner Stocks:
public bool CheckPropDatabase(char[] sCommand, char[] sModel, int iMaxLengh)
{
	char sPropModel[128];

	KeyValues hProps = CreateKeyValues("Props");

	FileToKeyValues(hProps, g_sPropsPath);

	KvGetString(hProps, sCommand, sPropModel, sizeof(sPropModel), "null");

	if(StrEqual(sPropModel, "null", true))
	{
		CloseHandle(hProps);

		return false;
	}

	CloseHandle(hProps);

	strcopy(sModel, iMaxLengh, sPropModel);

	return true;
}

public void SpawnEntity(int iClient, char[] sModel)
{
	float fAngles[3], fCAngles[3], fCOrigin[3], fOrigin[3];

	GetClientAbsAngles(iClient, fAngles);

	GetClientEyePosition(iClient, fCOrigin);

	GetClientEyeAngles(iClient, fCAngles);

	Handle hTraceRay = TR_TraceRayFilterEx(fCOrigin, fCAngles, MASK_SOLID, RayType_Infinite, FilterPlayer);

	if(TR_DidHit(hTraceRay))
	{
		TR_GetEndPosition(fOrigin, hTraceRay);

		CloseHandle(hTraceRay);
	}

	int iEnt = CreateEntityByName("prop_physics_override");

	PrecacheModel(sModel);

	DispatchKeyValue(iEnt, "model", sModel);

	DispatchSpawn(iEnt);

	TeleportEntity(iEnt, fOrigin, fAngles, NULL_VECTOR);
}
