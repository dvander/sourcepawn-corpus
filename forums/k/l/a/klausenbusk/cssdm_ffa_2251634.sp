#include <sourcemod>
#include <sdkhooks>
#include <dhooks>
#pragma semicolon 1


/* Thanks asherkin! mvm-teleporter.sp */
enum Platform
{
	Platform_Invalid,
	Platform_Windows,
	Platform_Linux,
	Platform_Mac
}

/* Stolen from cssdm_ffa.ccp wooops :) */

/* Lagcomp */
new g_lagcomp_offset = 0;
new Address:g_lagcomp_addr;
new g_lagcomp_patch[20] = {-1, ...};
new g_lagcomp_restore[20] = {-1, ...};

/* Takedamage */
new g_takedmg_offset = 0;
new Address:g_takedmg_addr;
new g_takedmg_patch[2][20] = {{-1, ...}, {-1, ...}};
new g_takedmg_restore[2][20] = {{-1, ...}, {-1, ...}};
// = {-1, ...};

/* Calc domination and revenge */
new g_domrev_offset = 0;
new Address:g_domrev_addr;
new g_domrev_patch[20] = {-1, ...};
new g_domrev_restore[20] = {-1, ...};

/* IPointsForKill */
new g_pointskill_offset = 0;
new Handle:g_pointskill_handle;
new g_pointskill_hookid;

new Handle:g_hGameConf;
new bool:g_FFA_Patched;
new bool:g_FFA_Prepared;
new bool:g_isGo;
new Handle:g_FreeForAll;

public Plugin:myinfo =
{
	name = "cssdm_ffa.cpp :)",
	author = "KK",
	description = "",
	version = "1.0.0-dev",
	url = "http://steamcommunity.com/id/i_like_denmark/"
};


public OnPluginStart() 
{
	new EngineVersion:version = GetEngineVersion();
	if (version != Engine_CSS && version != Engine_CSGO)
	{
		SetFailState("Hmm.. I only work with CSS or CSGO..");
	}
	g_isGo = version == Engine_CSGO;
	g_hGameConf = LoadGameConfigFile("ffa.games");
	DM_Prepare_FFA();

	g_FreeForAll = CreateConVar("sm_freeforall", "1", "Toggle Free For All gameplay", FCVAR_NONE, true, 0.0, true, 1.0);
	OnFFAConVarChanged(g_FreeForAll, "", "");
	HookConVarChange(g_FreeForAll, OnFFAConVarChanged);
}

public OnPluginEnd()
{
	DM_Unpatch_FFA();
}

public OnFFAConVarChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if (GetConVarBool(convar))
	{
		DM_Patch_FFA();
	}
	else
	{
		DM_Unpatch_FFA();
	}
}

public OnMapStart()
{
	if (g_FFA_Patched)
	{
		g_pointskill_hookid = DHookGamerules(g_pointskill_handle, true);
	}
}

public MRESReturn:OnIPointsForKill(Handle:hReturn)
{
	DHookSetReturn(hReturn, 1);
	return MRES_Supercede;
}


bool:DM_FFA_LoadPatch(const String:name[], patch[], patchLen)
{
	static const String:PLAYFORM_NAMES[][] = {"Invalid", "Windows", "Linux", "Mac"};
	new String:fullname[PLATFORM_MAX_PATH], String:buffer[32];
	Format(fullname, sizeof(fullname), "%s_%s", name, PLAYFORM_NAMES[GetPlatform()]);

	GameConfGetKeyValue(g_hGameConf, fullname, buffer, sizeof(buffer));
	if (buffer[0] == 0)
	{
		LogError("Could not find signature value for \"%s\"", fullname);
		return false;
	}

	new bytes = DM_StringToBytes(buffer, patch, patchLen);
	if (!bytes)
	{
		LogError("Invalid signature detected for \"%s\"", fullname);
		return false;
	}
	return true;
}

Platform:GetPlatform()
{
	static Platform:ResolvedPlatform = Platform_Invalid;
	
	if (ResolvedPlatform == Platform_Invalid)
	{
		ResolvedPlatform = Platform:GameConfGetOffset(g_hGameConf, "PlatformDetection");
		
		if (Platform_Invalid >= ResolvedPlatform >= Platform)
		{
			ThrowError("Unknown platform \"%d\" detected.", _:ResolvedPlatform);
			return Platform_Invalid;
		}
	}
	
	return ResolvedPlatform;
}

DM_StringToBytes(const String:str[], buffer[], maxlength)
{
	new real_bytes = 0;
	new length = strlen(str);

	for (new i=0; i<length; i++)
	{
		if (real_bytes >= maxlength)
		{
			break;
		}
		buffer[real_bytes++] = str[i];
		if (str[i] == '\\'
			&& str[i+1] == 'x')
		{
			if (i + 3 >= length)
			{
				continue;
			}
			/* Get the hex part */
			new String:s_byte[3];
			new r_byte;
			s_byte[0] = str[i+2];
			s_byte[1] = str[i+3];
			s_byte[2] = '\n';
			/* Read it as an integer */
			r_byte = StringToInt(s_byte, 16);
			/* Save the value */
			buffer[real_bytes-1] = r_byte;
			/* Adjust index */
			i += 3;
		}
	}
	return real_bytes;
}

bool:DM_Prepare_FFA()
{
	g_lagcomp_offset = GameConfGetOffset(g_hGameConf, "LagCompPatch");
	if (g_lagcomp_offset == -1)
	{
		LogError("Could not find LagCompPatch offset");
		return false;
	}
	g_lagcomp_addr = GameConfGetAddress(g_hGameConf, "WantsLagComp");
	if (!g_lagcomp_addr)
	{
		LogError("Could not find \"WantsLagComp\" signature!");
		return false;
	}
	DM_FFA_LoadPatch("LagCompPatch", g_lagcomp_patch, sizeof(g_lagcomp_patch));

	g_domrev_offset = GameConfGetOffset(g_hGameConf, "CalcDomRevPatch");
	if (g_domrev_offset == -1)
	{
		LogError("Could not find CalcDomRevPatch offset");
		return false;
	}
	g_domrev_addr = GameConfGetAddress(g_hGameConf, "CalcDominationAndRevenge");
	if (!g_domrev_addr)
	{
		LogError("Could not find \"CalcDominationAndRevenge\" signature!");
		return false;
	}
	DM_FFA_LoadPatch("CalcDomRevPatch", g_domrev_patch, sizeof(g_domrev_patch));

	g_takedmg_offset = GameConfGetOffset(g_hGameConf, "TakeDmgPatch1");
	if (g_takedmg_offset == -1)
	{
		LogError("Could not find TakeDmgPatch1 offset");
		return false;
	}
	g_takedmg_addr = GameConfGetAddress(g_hGameConf, "OnTakeDamage");
	if (!g_takedmg_addr)
	{
		LogError("Could not find \"OnTakeDamage\" signature!");
		return false;
	}
	DM_FFA_LoadPatch("TakeDmgPatch1", g_takedmg_patch[0], sizeof(g_takedmg_patch[]));

	g_pointskill_offset = GameConfGetOffset(g_hGameConf, "IPointsForKill");
	if (g_pointskill_offset == -1)
	{
		LogError("Could not find IPointsForKill offset");
		return false;
	}
	g_pointskill_handle = DHookCreate(g_pointskill_offset, HookType_GameRules, ReturnType_Int, ThisPointer_Ignore, OnIPointsForKill);
	DHookAddParam(g_pointskill_handle, HookParamType_CBaseEntity);
	DHookAddParam(g_pointskill_handle, HookParamType_CBaseEntity);

	g_FFA_Prepared = true;
	return true;
}

bool:DM_Patch_FFA()
{
	if (g_FFA_Patched || !g_FFA_Prepared)
	{
		return false;
	}
	DM_ApplyPatch(g_lagcomp_addr, g_lagcomp_offset, g_lagcomp_patch, sizeof(g_lagcomp_patch), g_lagcomp_restore, sizeof(g_lagcomp_restore));
	DM_ApplyPatch(g_takedmg_addr, g_takedmg_offset, g_takedmg_patch[0], sizeof(g_takedmg_patch[]), g_takedmg_restore[0], sizeof(g_takedmg_restore[]));
	if (g_isGo)
	{
		DM_ApplyPatch(g_takedmg_addr, g_takedmg_offset, g_takedmg_patch[1], sizeof(g_takedmg_patch[]), g_takedmg_restore[1], sizeof(g_takedmg_restore[]));
	}
	DM_ApplyPatch(g_domrev_addr, g_domrev_offset, g_domrev_patch, sizeof(g_domrev_patch), g_domrev_restore, sizeof(g_domrev_restore));

	g_FFA_Patched = true;
	OnMapStart();
	return true;
}

bool:DM_Unpatch_FFA()
{
	if (!g_FFA_Patched)
	{
		return false;
	}
	DM_ApplyPatch(g_lagcomp_addr, g_lagcomp_offset, g_lagcomp_restore, sizeof(g_lagcomp_restore));
	DM_ApplyPatch(g_takedmg_addr, g_takedmg_offset, g_takedmg_restore[0], sizeof(g_takedmg_restore[]));
	if (g_isGo)
	{
		DM_ApplyPatch(g_takedmg_addr, g_takedmg_offset, g_takedmg_restore[1], sizeof(g_takedmg_restore[]));
	}
	DM_ApplyPatch(g_domrev_addr, g_domrev_offset, g_domrev_restore, sizeof(g_domrev_restore));
	DHookRemoveHookID(g_pointskill_hookid);

	g_FFA_Patched = false;
	return true;
}
DM_ApplyPatch(Address:address, offset, patch[], patchLen, restore[]=-1, restoreLen=0)
{
	new Address:addr = Address:address+Address:offset;

	if (0 < restoreLen)
	{
		for (new i=0; i < restoreLen; i++)
		{
			if (patch[i] == -1) break;
			restore[i] = LoadFromAddress(addr+Address:i, NumberType_Int8);
		}
	}

	for (new i=0; i < patchLen; i++)
	{
		if (patch[i] == -1) break;
		StoreToAddress(addr+Address:i, patch[i], NumberType_Int8);
	}
}
