

/*
// bool CBasePlayer::IsValidObserverTarget(CBaseEntity * target)

https://forums.alliedmods.net/showpost.php?p=2834763&postcount=328


dod:s 32bit
Signature for IsValidObserverTarget_sub_101DDAE0:
55 8B EC 56 8B 75 08 57 8B F9 85 F6 0F 84 ? ? ? ? 8B 06 8B CE 8B 80 48 01 00 00 
\x55\x8B\xEC\x56\x8B\x75\x08\x57\x8B\xF9\x85\xF6\x0F\x84\x2A\x2A\x2A\x2A\x8B\x06\x8B\xCE\x8B\x80\x48\x01\x00\x00

dod:s 32bit linux
Signature for _ZN11CBasePlayer21IsValidObserverTargetEP11CBaseEntity:
55 89 E5 83 EC 28 89 5D F4 8B 5D 0C 89 75 F8 31 F6 89 7D FC 8B 7D 08 85 DB 74 ? 8B 03 89 1C 24 FF 90 44 01 00 00 
\x55\x89\xE5\x83\xEC\x28\x89\x5D\xF4\x8B\x5D\x0C\x89\x75\xF8\x31\xF6\x89\x7D\xFC\x8B\x7D\x08\x85\xDB\x74\x2A\x8B\x03\x89\x1C\x24\xFF\x90\x44\x01\x00\x00

dod:s 64bit
Signature for IsValidObserverTarget__sub_180230BE0:
48 89 5C 24 08 57 48 83 EC 20 48 8B DA 48 8B F9 48 85 D2 0F 84 ? ? ? ? 48 8B 02 48 8B CA FF 90 90 02 00 00 
\x48\x89\x5C\x24\x08\x57\x48\x83\xEC\x20\x48\x8B\xDA\x48\x8B\xF9\x48\x85\xD2\x0F\x84\x2A\x2A\x2A\x2A\x48\x8B\x02\x48\x8B\xCA\xFF\x90\x90\x02\x00\x00

cs:s 32bit
Signature for IsValidObserverTarget_sub_101E3990:
55 8B EC 56 8B 75 08 57 8B F9 85 F6 0F 84 ? ? ? ? 8B 06 8B CE 8B 80 48 01 00 00 FF D0 84 C0 0F 84 ? ? ? ? 8B 06 
\x55\x8B\xEC\x56\x8B\x75\x08\x57\x8B\xF9\x85\xF6\x0F\x84\x2A\x2A\x2A\x2A\x8B\x06\x8B\xCE\x8B\x80\x48\x01\x00\x00\xFF\xD0\x84\xC0\x0F\x84\x2A\x2A\x2A\x2A\x8B\x06

cs:s 32bit linux
Signature for _ZN11CBasePlayer21IsValidObserverTargetEP11CBaseEntity:
55 89 E5 56 53 8B 5D 0C 8B 75 08 85 DB 74 ? 8B 03 83 EC 0C 53 FF 90 4C 01 00 00 83 C4 10 84 C0 75 ? 
\x55\x89\xE5\x56\x53\x8B\x5D\x0C\x8B\x75\x08\x85\xDB\x74\x2A\x8B\x03\x83\xEC\x0C\x53\xFF\x90\x4C\x01\x00\x00\x83\xC4\x10\x84\xC0\x75\x2A

cs:s 64bit
Signature for IsValidObserverTarget_sub_180238490:
48 89 5C 24 08 57 48 83 EC 20 48 8B DA 48 8B F9 48 85 D2 0F 84 ? ? ? ? 48 8B 02 
\x48\x89\x5C\x24\x08\x57\x48\x83\xEC\x20\x48\x8B\xDA\x48\x8B\xF9\x48\x85\xD2\x0F\x84\x2A\x2A\x2A\x2A\x48\x8B\x02


*/


public Plugin myinfo = 
{
	name = "Admin all spec",
	author = "Bacardi",
	description = "Allows admin to spec all players",
	version = "28.02.2025",
	url = "https://forums.alliedmods.net/showpost.php?p=2834763&postcount=328"
};

#include <dhooks>

DynamicHook hook = null;
ConVar mp_forcecamera;

public void OnPluginStart()
{
	GameData data = new GameData("allow-spec.games");

	if(data == null)	SetFailState("Failed to load gamedata file 'allow-spec.games.txt'");

	int offset = data.GetOffset("IsValidObserverTarget");

	if(offset == -1) SetFailState("Failed to get OFFSET from gamedata file 'IsValidObserverTarget'");

	mp_forcecamera = FindConVar("mp_forcecamera");

	hook = new DynamicHook(offset, HookType_Entity, ReturnType_Bool, ThisPointer_CBaseEntity);

	if(hook == null) SetFailState("Failed to create DynamicHook");

	hook.AddParam(HookParamType_CBaseEntity); // target


	for(int i = 1; i <= MaxClients; i++)
	{
		if(!IsClientInGame(i) || IsFakeClient(i) || !IsClientAuthorized(i))
			continue;
		
		OnClientPostAdminCheck(i);
	}
}


public void OnClientPostAdminCheck(int client)
{
	if(IsFakeClient(client) || !CheckCommandAccess(client, "admin_allspec_flag", ADMFLAG_CHEATS))
		return;

	hook.HookEntity(Hook_Pre, client, IsValidObserverTarget);

	if(mp_forcecamera != null)
		SendConVarValue(client, mp_forcecamera, "0");
}


public MRESReturn IsValidObserverTarget(int pThis, DHookReturn hReturn, DHookParam hParams)
{
	if(!IsClientInGame(pThis) || IsPlayerAlive(pThis) || GetClientTeam(pThis) <= 1)
		return MRES_Ignored;


	if(hParams.IsNull(1))
		return MRES_Ignored;

	int target = hParams.Get(1);
	
	if(target <= 0 || target > MaxClients || pThis == target || !IsClientInGame(target) || !IsPlayerAlive(target) || GetClientTeam(target) <= 1)
		return MRES_Ignored;

	hReturn.Value = true;

	//PrintToServer("IsValidObserverTarget ");

	return MRES_Supercede;
}