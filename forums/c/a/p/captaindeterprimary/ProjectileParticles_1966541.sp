#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#define PLUGIN_VERSION "1.1.0"
#define CONFIG_PATH "data/projectile_particles.cfg"

public Plugin:myinfo =
{
    name 		=		"Projectile Particles",
    author		=		"11530",
    description	=		"Attach Particles to a List of Projectiles",
    version		=		PLUGIN_VERSION,
    url			=		"http://www.sourcemod.net"
};

//Many thanks to DarthNinja, KyleS and psychonic for various code

new Handle:g_hVersion = INVALID_HANDLE;
new Handle:g_hEnabled = INVALID_HANDLE;
new Handle:g_hClientDefault = INVALID_HANDLE;
new Handle:g_hMode = INVALID_HANDLE;
new Handle:g_hFlags = INVALID_HANDLE;

new Handle:g_hIndexArray = INVALID_HANDLE;
new Handle:g_hFastLookupTrie = INVALID_HANDLE;
new Handle:g_hCurrentTrie = INVALID_HANDLE;
new Handle:g_hStoredTrie = INVALID_HANDLE;

new bool:g_bEnabled;
new bool:g_bClientDefault;
new bool:g_bClientEnabled[MAXPLAYERS+1];
new g_iMode;
new String:g_sFlags[32];
new String:g_sCurrentSection[128];

public OnPluginStart()
{
	g_hIndexArray = CreateArray();
	g_hFastLookupTrie = CreateTrie();
	
	g_hVersion = CreateConVar("sm_projectileparticles_version", PLUGIN_VERSION, "Projectile Particles Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	g_hEnabled = CreateConVar("sm_projectileparticles_enabled", "1", "0 = Disable plugin, 1 = Enable plugin", 0, true, 0.0, true, 1.0);
	g_hClientDefault = CreateConVar("sm_projectileparticles_clientdefault", "1", "0 = Turned off for clients by default, 1 = Turned on", 0, true, 0.0, true, 1.0);
	g_hMode = CreateConVar("sm_projectileparticles_mode", "2", "1 = All players, 2 = Admins with correct flag", 0, true, 1.0, true, 2.0);
	g_hFlags = CreateConVar("sm_projectileparticles_adminflag", "b", "Admin flag to use if mode is set to \"2\"");
	
	LoadGlobalVars();
	
	HookConVarChange(g_hEnabled, ConVarChangeEnabled);
	HookConVarChange(g_hClientDefault, ConVarChangeDefault);
	HookConVarChange(g_hMode, ConVarChangeMode);
	HookConVarChange(g_hFlags, ConVarChangeFlag);
	
	RegAdminCmd("sm_particles", OnParticleCmd, 0, "Toggles a client's projectile particles on/off");
	RegAdminCmd("sm_projectileparticles_reload", OnReloadCmd, ADMFLAG_CONFIG, "Reload Projectile Particles config file");
}

stock LoadGlobalVars()
{
	g_bEnabled = GetConVarBool(g_hEnabled);
	g_bClientDefault = GetConVarBool(g_hClientDefault);
	for (new i = 0; i < (MAXPLAYERS+1); i++)
	{
		g_bClientEnabled[i] = g_bClientDefault;
	}
	g_iMode = GetConVarInt(g_hMode);
	GetConVarString(g_hFlags, g_sFlags, sizeof(g_sFlags));
}

public OnMapStart()
{
	// hax against valvefail
	if (GuessSDKVersion() == SOURCE_SDK_EPISODE2VALVE)
	{
		SetConVarString(g_hVersion, PLUGIN_VERSION);
	}
}

stock LoadConfigFile(client = 0)
{
	ClearExistingData();
	
	decl String:sPath[256];
	BuildPath(Path_SM, sPath, sizeof(sPath), CONFIG_PATH);
	if (FileExists(sPath))
	{
		ProcessFile(sPath);
		if (client > 0)
		{
			ReplyToCommand(client, "\x05[SM]\x01 Reloaded Projectile Particles config file.");
		}
	}
	else
	{
		LogError("[PP] File not found: %s", sPath);
	}
}

public OnConfigsExecuted()
{
	LoadConfigFile();
}

public Action:OnReloadCmd(client, args)
{
	LoadConfigFile(client);
	return Plugin_Handled;
}

public ConVarChangeEnabled(Handle:convar, const String:oldvalue[], const String:newvalue[])
{
    g_bEnabled = (StringToInt(newvalue) == 0 ? false : true);
}

public ConVarChangeDefault(Handle:convar, const String:oldvalue[], const String:newvalue[])
{
	g_bClientDefault = (StringToInt(newvalue) == 0 ? false : true);
	for (new i = 1; i < (MaxClients+1); i++)
	{
		if (!IsClientInGame(i))
		{
			g_bClientEnabled[i] = g_bClientDefault;
		}
	}
}

public ConVarChangeMode(Handle:convar, const String:oldvalue[], const String:newvalue[])
{
    g_iMode = StringToInt(newvalue);
}

public ConVarChangeFlag(Handle:convar, const String:oldvalue[], const String:newvalue[])
{
	strcopy(g_sFlags, sizeof(g_sFlags), newvalue);
}

stock ClearExistingData()
{
	new Handle:hHandle = INVALID_HANDLE;
	for (new i = 0; i < GetArraySize(g_hIndexArray); i++)
	{
		hHandle = GetArrayCell(g_hIndexArray, i);
		
		if (hHandle != INVALID_HANDLE)
		{
			CloseHandle(hHandle);
		}
	}
	ClearArray(g_hIndexArray);
	ClearTrie(g_hFastLookupTrie);
}

stock ProcessFile(const String:sPathToFile[])
{
	new Handle:hSMC = SMC_CreateParser();
	SMC_SetReaders(hSMC, SMCNewSection, SMCReadKeyValues, SMCEndSection);
	
	new iLine;
	new SMCError:ReturnedError = SMC_ParseFile(hSMC, sPathToFile, iLine);
	
	if (ReturnedError != SMCError_Okay)
	{
		decl String:sError[256];
		SMC_GetErrorString(ReturnedError, sError, sizeof(sError));
		if (iLine > 0)
		{
			LogError("[PP] Could not parse file (Line: %d, File \"%s\"): %s.", iLine, sPathToFile, sError);
			CloseHandle(hSMC);
			return;
		}
		
		LogError("[PP] Parser encountered error (File: \"%s\"): %s.", sPathToFile, sError);
	}

	CloseHandle(hSMC);
}

public SMCResult:SMCNewSection(Handle:smc, const String:name[], bool:opt_quotes)
{
	if (!opt_quotes)
	{
		LogError("[PP] Invalid Quoting used with Section: %s.", name);
	}
	
	strcopy(g_sCurrentSection, sizeof(g_sCurrentSection), name);
	
	if (GetTrieValue(g_hFastLookupTrie, name, g_hCurrentTrie))
	{
		return SMCParse_Continue;
	}
	else
	{
		g_hCurrentTrie = CreateTrie();
		PushArrayCell(g_hIndexArray, g_hCurrentTrie);
		SetTrieValue(g_hFastLookupTrie, name, g_hCurrentTrie);
		SetTrieString(g_hCurrentTrie, "Name", name);
	}
	
	return SMCParse_Continue;
}

public SMCResult:SMCReadKeyValues(Handle:smc, const String:key[], const String:value[], bool:key_quotes, bool:value_quotes)
{
	if (!key_quotes)
	{
		LogError("[PP] Invalid Quoting used with Key: \"%s\".", key);
	}
	else if (!value_quotes)
	{
		LogError("[PP] Invalid Quoting used with Key: \"%s\" Value: \"%s\".", key, value);
	}
	else if (g_hCurrentTrie == INVALID_HANDLE)
	{
		return SMCParse_Continue;
	}
	
	switch (key[0])
	{
		case 'P','p':
		{
			if (StrContains(key, "Particle", false) == -1)
			{
				return SMCParse_Continue;
			}
			SetTrieString(g_hCurrentTrie, "Particle", value, true);
		}
		case 'C','c':
		{
			if (StrContains(key, "Cluster", false) != -1)
			{
				SetTrieValue(g_hCurrentTrie, "Clusters", StringToInt(value), true);
			}
			return SMCParse_Continue;
		}
		case 'T','t':
		{
			if (StrContains(key, "Team", false) == -1)
			{
				return SMCParse_Continue;
			}
			SetTrieValue(g_hCurrentTrie, "Team", StringToInt(value), true);			
		}
	}
	return SMCParse_Continue;
}

public SMCResult:SMCEndSection(Handle:smc)
{
	g_hCurrentTrie = INVALID_HANDLE;
	g_sCurrentSection[0] = '\0';
}

public Action:OnParticleCmd(client, args)
{
	if (g_bEnabled)
	{
		if (client == 0)
		{
			ReplyToCommand(client, "\x05[SM]\x01 Cannot use command from RCON.");
			return Plugin_Handled;
		}
		
		g_bClientEnabled[client] = !g_bClientEnabled[client];
		ShowActivity2(client, "\x05[SM]\x01 ","%s \x05projectile particles\x01 on %N.", (g_bClientEnabled[client] ? "Enabled" : "Disabled"), client);
	}
	return Plugin_Handled;
}

public OnEntityCreated(entity, const String:classname[])
{
	if (g_bEnabled && GetTrieValue(g_hFastLookupTrie, classname, g_hStoredTrie) && g_hStoredTrie != INVALID_HANDLE)
	{
		new iClusters;
		decl String:sParticle[64];
		if (GetTrieString(g_hStoredTrie, "Particle", sParticle, sizeof(sParticle)))
		{
			if (GetTrieValue(g_hStoredTrie, "Clusters", iClusters))
			{
				SDKHook(entity, SDKHook_Spawn, OnEntitySpawned);
			}
			else
			{
				LogError("[PP] Unable to find a value for: \"%s\".", classname);
			}
		}
		else
		{
			LogError("[PP] Unable to find a particle for: \"%s\".", classname);
		}
	}
}

public OnEntitySpawned(entity)
{
	new iTrieTeam = -1, client = GetEntPropEnt(entity, Prop_Data, "m_hOwnerEntity");
	if (client > 0 && client <= MaxClients && g_bClientEnabled[client])
	{
		switch (g_iMode)
		{
			case 1:
			{
				if (!GetTrieValue(g_hStoredTrie, "Team", iTrieTeam) || iTrieTeam == 1 || iTrieTeam == GetClientTeam(client))
				{
					AddParticle(client, entity);
				}
			}
			case 2:
			{
				if(IsValidAdmin(client, g_sFlags))
				{
					if (!GetTrieValue(g_hStoredTrie, "Team", iTrieTeam) || iTrieTeam == 1 || iTrieTeam == GetClientTeam(client))
					{
						AddParticle(client, entity);
					}
				}
			}
		}
	}
	SDKUnhook(entity, SDKHook_Spawn, OnEntitySpawned);
}

stock AddParticle(client, entity)
{
	new iClusters, iIndex = -1, iTrieTeam = -1;
	new iTeam = GetClientTeam(client);
	decl String:sParticle[64], String:sExtras[64];
	GetTrieValue(g_hStoredTrie, "Clusters", iClusters);
	GetTrieString(g_hStoredTrie, "Particle", sParticle, sizeof(sParticle));
	if (GetTrieValue(g_hStoredTrie, "Team", iTrieTeam))
	{
		if (iTrieTeam == 1)
		{
			switch (iTeam)
			{
				case 2:
				{
					ReplaceString(sParticle, sizeof(sParticle), "_blue", "_red", false);
					ReplaceString(sParticle, sizeof(sParticle), "_blu", "_red", false);
				}
				case 3:
				{
					ReplaceString(sParticle, sizeof(sParticle), "_red", "_blue", false);
				}
			}
		}
	}
	for (new i = 0; i < iClusters; i++)
	{
		while ((iIndex = SplitString(sParticle, ",", sExtras, sizeof(sExtras))) > -1)
		{
			CreateParticle(entity, sExtras, true);
			strcopy(sParticle, sizeof(sParticle), sParticle[iIndex]);
		}
		
		CreateParticle(entity, sParticle, true);
	}
}

stock CreateParticle(iEntity, String:sParticle[], bool:bAttach = false)
{
	new iParticle = CreateEntityByName("info_particle_system");
	if (IsValidEdict(iParticle))
	{
		decl Float:fPosition[3];
		GetEntPropVector(iEntity, Prop_Send, "m_vecOrigin", fPosition);
		
		TeleportEntity(iParticle, fPosition, NULL_VECTOR, NULL_VECTOR);
		DispatchKeyValue(iParticle, "effect_name", sParticle);
		
		if (bAttach)
		{
			SetVariantString("!activator");
			AcceptEntityInput(iParticle, "SetParent", iEntity, iParticle, 0);			
		}

		DispatchSpawn(iParticle);
		ActivateEntity(iParticle);
		AcceptEntityInput(iParticle, "Start");
	}
	return iParticle;
}

stock bool:IsValidAdmin(client, const String:flags[])
{
	if(IsClientInGame(client))
	{
		new ibFlags = ReadFlagString(flags);
		new ibUserFlags = GetUserFlagBits(client);
		
		if((ibUserFlags & ibFlags) == ibFlags || (ibUserFlags & ADMFLAG_ROOT))
		{
			return true;
		}
	}
	return false;
}

public OnClientDisconnect(client)
{
	g_bClientEnabled[client] = g_bClientDefault;
}