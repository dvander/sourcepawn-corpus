#pragma semicolon 1
#include <sourcemod>
//#include <sdktools> //SDKTools broken for ReactiveDrop unsure about basegame
#include <sdkhooks>

#define ENTITY_SAFE_LIMIT 1900

#define MAX_ALIENS 400

static int g_iAlienRef[MAX_ALIENS];
static float g_fAlienCreationTime[MAX_ALIENS];

public Plugin myinfo =
{
	name = "swarm_drone_safe_limit",
	author = "Lux",
	description = "Adds an upperlimit to amount of aliens as well as keeping within a safe entity limit on amount of aliens",
	version = "1.0",
	url = "https://forums.alliedmods.net/showthread.php?p=2649846"
};

public void OnEntityCreated(int iEntity, const char[] sClassname)
{
	if(sClassname[0] != 'a' || StrContains(sClassname, "asw_drone", false) == -1)
	{
		if(iEntity >= ENTITY_SAFE_LIMIT)
			AlienForceARemoval();
		return;
	}
	SDKHook(iEntity, SDKHook_SpawnPost, AddAlienToSorting);
}

public void AddAlienToSorting(int iEntity)
{
	SDKUnhook(iEntity, SDKHook_SpawnPost, AddAlienToSorting);
	
	bool bForceRemoval = (iEntity >= ENTITY_SAFE_LIMIT);
	float fNow = GetEngineTime();
	float fTime = 2147483640.0;
	int iAlien;
	
	for(int i = 0; i < MAX_ALIENS; i++)
	{
		if(IsValidEntRef(g_iAlienRef[i]))
		{
			if(g_fAlienCreationTime[i] < fTime)
			{
				fTime = g_fAlienCreationTime[i];
				iAlien = i;
			}
			continue;
		}
		
		if(!bForceRemoval)
		{
			g_iAlienRef[i] = EntIndexToEntRef(iEntity);
			g_fAlienCreationTime[i] = fNow;
			return;
		}
	}
	// no free slots for alien remove oldest alien
	if(IsValidEntRef(g_iAlienRef[iAlien]))
		SwarmRemoveEntity(EntRefToEntIndex(g_iAlienRef[iAlien]));//AcceptEntityInput seems broken for reactive drop //AcceptEntityInputSDK(EntRefToEntIndex(g_iAlienRef[iAlien]), "Kill");
	
	g_iAlienRef[iAlien] = EntIndexToEntRef(iEntity);
	g_fAlienCreationTime[iAlien] = fNow;
}

/*bool AcceptEntityInputSDK(int dest, const char[] input, int activator=-1, int caller=-1)
{
	static Handle hAcceptSDK = null;
	if(hAcceptSDK == null)
	{
		StartPrepSDKCall(SDKCall_Entity);
		PrepSDKCall_SetSignature(SDKLibrary_Server, "\x55\x8B\xEC\x81\xEC\x44\x02\x00\x00\xA1\x2A\x2A\x2A\x2A", 4);
		PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);
		PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
		PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
		hAcceptSDK = EndPrepSDKCall();
	}
	return view_as<bool>(SDKCall(hAcceptSDK, dest, input, (activator < 1) ? dest : activator, (caller < 1) ? dest : caller));
}*/

void AlienForceARemoval()
{
	float fTime = 2147483640.0;
	int iAlien;
	for(int i = 0; i < MAX_ALIENS; i++)
	{
		if(IsValidEntRef(g_iAlienRef[i]) && g_fAlienCreationTime[i] < fTime)
		{
			fTime = g_fAlienCreationTime[i];
			iAlien = i;
		}
	}
	if(IsValidEntRef(g_iAlienRef[iAlien]))
		SwarmRemoveEntity(EntRefToEntIndex(g_iAlienRef[iAlien]));
}

//use me <3
void SwarmRemoveEntity(int iEntity)//RemoveEdict can cause crashes & AcceptEntityInput don't seem to be working
{
	static char sClassname[32];
	GetEntPropString(iEntity, Prop_Data, "m_iClassname", sClassname, sizeof(sClassname));
	
	static char sNewClassname[64];
	FormatEx(sNewClassname, sizeof(sNewClassname), "__Removaltarget_%s[%i]", sClassname, iEntity);
	SetEntPropString(iEntity, Prop_Data, "m_iClassname", sNewClassname);
	ExecuteCheat("ent_remove", sNewClassname);
}

int GetRandomClient()
{
	for(int i = 1; i <= MaxClients; i++)
		if(IsClientInGame(i))
			return i;
	return -1;
}

static void ExecuteCheat(const char[] sCmd, const char[] sArg)
{
	int iClient = GetRandomClient();
	if(iClient < 1)
		return;
	
	int flags = GetCommandFlags(sCmd);
	SetCommandFlags(sCmd, flags & ~FCVAR_CHEAT);
	FakeClientCommand(iClient, "%s %s", sCmd, sArg);
	SetCommandFlags(sCmd, flags);
}

static bool IsValidEntRef(int iEntRef)
{
	return (iEntRef != 0 && EntRefToEntIndex(iEntRef) != INVALID_ENT_REFERENCE);
}