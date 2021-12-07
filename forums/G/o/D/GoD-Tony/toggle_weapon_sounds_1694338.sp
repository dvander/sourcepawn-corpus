#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#undef REQUIRE_PLUGIN
#include <updater>

#define PLUGIN_NAME 	"Toggle Weapon Sounds"
#define PLUGIN_VERSION 	"1.0.0"

#define UPDATE_URL	"http://godtony.mooo.com/stopsound/stopsound.txt"

new bool:g_bStopSound[MAXPLAYERS+1], bool:g_bHooked;

public Plugin:myinfo =
{
	name = PLUGIN_NAME,
	author = "GoD-Tony",
	description = "Allows clients to stop hearing weapon sounds",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net/"
};

public OnPluginStart()
{
	// Detect game and hook appropriate tempent.
	decl String:sGame[32];
	GetGameFolderName(sGame, sizeof(sGame));

	if (StrEqual(sGame, "cstrike"))
		AddTempEntHook("Shotgun Shot", CSS_Hook_ShotgunShot);
	else if (StrEqual(sGame, "dod"))
		AddTempEntHook("FireBullets", DODS_Hook_FireBullets);
	
	// TF2/HL2:DM and misc weapon sounds will be caught here.
	AddNormalSoundHook(Hook_NormalSound);
	
	CreateConVar("sm_stopsound_version", PLUGIN_VERSION, "Toggle Weapon Sounds", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	RegConsoleCmd("sm_stopsound", Command_StopSound, "Toggle hearing weapon sounds");
	
	// Updater.
	if (LibraryExists("updater"))
	{
		Updater_AddPlugin(UPDATE_URL);
	}
}

public OnLibraryAdded(const String:name[])
{
	if (StrEqual(name, "updater"))
	{
		Updater_AddPlugin(UPDATE_URL);
	}
}

public Action:Command_StopSound(client, args)
{
	g_bStopSound[client] = !g_bStopSound[client];
	ReplyToCommand(client, "[SM] Weapon sounds %s.", g_bStopSound[client] ? "disabled" : "enabled");
	CheckHooks();
	
	return Plugin_Handled;
}

public OnClientDisconnect_Post(client)
{
	g_bStopSound[client] = false;
	CheckHooks();
}

CheckHooks()
{
	new bool:bShouldHook = false;
	
	for (new i = 1; i <= MaxClients; i++)
	{
		if (g_bStopSound[i])
		{
			bShouldHook = true;
			break;
		}
	}
	
	// Fake (un)hook because toggling actual hooks will cause server instability.
	g_bHooked = bShouldHook;
}

public Action:Hook_NormalSound(clients[64], &numClients, String:sample[PLATFORM_MAX_PATH], &entity, &channel, &Float:volume, &level, &pitch, &flags)
{
	// Ignore non-weapon sounds.
	if (!g_bHooked || !(strncmp(sample, "weapons", 7) == 0 || strncmp(sample[1], "weapons", 7) == 0))
		return Plugin_Continue;
	
	decl i, j;
	
	for (i = 0; i < numClients; i++)
	{
		if (g_bStopSound[clients[i]])
		{
			// Remove the client from the array.
			for (j = i; j < numClients-1; j++)
			{
				clients[j] = clients[j+1];
			}
			
			numClients--;
			i--;
		}
	}
	
	return (numClients > 0) ? Plugin_Changed : Plugin_Stop;
}

public Action:CSS_Hook_ShotgunShot(const String:te_name[], const Players[], numClients, Float:delay)
{
	if (!g_bHooked)
		return Plugin_Continue;
	
	// Check which clients need to be excluded.
	decl newClients[MaxClients], client, i;
	new newTotal = 0;
	
	for (i = 0; i < numClients; i++)
	{
		client = Players[i];
		
		if (!g_bStopSound[client])
		{
			newClients[newTotal++] = client;
		}
	}
	
	// No clients were excluded.
	if (newTotal == numClients)
		return Plugin_Continue;
	
	// All clients were excluded and there is no need to broadcast.
	else if (newTotal == 0)
		return Plugin_Stop;
	
	// Re-broadcast to clients that still need it.
	decl Float:vTemp[3];
	TE_Start("Shotgun Shot");
	TE_ReadVector("m_vecOrigin", vTemp);
	TE_WriteVector("m_vecOrigin", vTemp);
	TE_WriteFloat("m_vecAngles[0]", TE_ReadFloat("m_vecAngles[0]"));
	TE_WriteFloat("m_vecAngles[1]", TE_ReadFloat("m_vecAngles[1]"));
	TE_WriteNum("m_iWeaponID", TE_ReadNum("m_iWeaponID"));
	TE_WriteNum("m_iMode", TE_ReadNum("m_iMode"));
	TE_WriteNum("m_iSeed", TE_ReadNum("m_iSeed"));
	TE_WriteNum("m_iPlayer", TE_ReadNum("m_iPlayer"));
	TE_WriteFloat("m_fInaccuracy", TE_ReadFloat("m_fInaccuracy"));
	TE_WriteFloat("m_fSpread", TE_ReadFloat("m_fSpread"));
	TE_Send(newClients, newTotal, delay);
	
	return Plugin_Stop;
}

public Action:DODS_Hook_FireBullets(const String:te_name[], const Players[], numClients, Float:delay)
{
	if (!g_bHooked)
		return Plugin_Continue;
	
	// Check which clients need to be excluded.
	decl newClients[MaxClients], client, i;
	new newTotal = 0;
	
	for (i = 0; i < numClients; i++)
	{
		client = Players[i];
		
		if (!g_bStopSound[client])
		{
			newClients[newTotal++] = client;
		}
	}
	
	// No clients were excluded.
	if (newTotal == numClients)
		return Plugin_Continue;
	
	// All clients were excluded and there is no need to broadcast.
	else if (newTotal == 0)
		return Plugin_Stop;
	
	// Re-broadcast to clients that still need it.
	decl Float:vTemp[3];
	TE_Start("FireBullets");
	TE_ReadVector("m_vecOrigin", vTemp);
	TE_WriteVector("m_vecOrigin", vTemp);
	TE_WriteFloat("m_vecAngles[0]", TE_ReadFloat("m_vecAngles[0]"));
	TE_WriteFloat("m_vecAngles[1]", TE_ReadFloat("m_vecAngles[1]"));
	TE_WriteNum("m_iWeaponID", TE_ReadNum("m_iWeaponID"));
	TE_WriteNum("m_iMode", TE_ReadNum("m_iMode"));
	TE_WriteNum("m_iSeed", TE_ReadNum("m_iSeed"));
	TE_WriteNum("m_iPlayer", TE_ReadNum("m_iPlayer"));
	TE_WriteFloat("m_flSpread", TE_ReadFloat("m_flSpread"));
	TE_Send(newClients, newTotal, delay);
	
	return Plugin_Stop;
}
