#include <sourcemod>
#include <sdkhooks>
#include <sdktools>

#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_VERSION "1.0"

bool g_bRiotSpawning;
bool g_bCedaSpawning;
bool g_bClownSpawning;
bool g_bMudSpawning;
bool g_bJimmySpawning;

int iTotalHordeCounter;
ConVar g_Cvar_HordeAmmount;

public Plugin myinfo =
{
	name = "L4D2 Spawn Uncommons",
	author = "AtomicStryker, updated by alasfourom",
	description = "Let's you spawn Uncommon Zombies",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?p=993523"
}

public void OnPluginStart()
{
	CreateConVar("l4d2_horde_spawner_version", PLUGIN_VERSION, "L4D2 Horde Spawner Version", FCVAR_SPONLY | FCVAR_DONTRECORD | FCVAR_NOTIFY);
	g_Cvar_HordeAmmount = CreateConVar("l4d2_horde_spawner_count", "25", "How many Zombies do you mean by 'horde'", FCVAR_NOTIFY);
	AutoExecConfig(true, "L4D2_Hordes_Spawner");
	
	RegAdminCmd("sm_horde", Command_Horde, ADMFLAG_CHEATS, "sm_horde");
}

public void OnMapStart()
{
	PrecacheModel("models/infected/common_male_riot.mdl", true);
	g_bRiotSpawning = false;
	
	PrecacheModel("models/infected/common_male_ceda.mdl", true);
	g_bCedaSpawning = false;
	
	PrecacheModel("models/infected/common_male_clown.mdl", true);
	g_bClownSpawning = false;
	
	PrecacheModel("models/infected/common_male_mud.mdl", true);
	g_bMudSpawning = false;
	
	PrecacheModel("models/infected/common_male_jimmy.mdl", true);
	g_bJimmySpawning = false;
	
	iTotalHordeCounter = 0;
}

public Action Command_Horde(int client, int args)
{
	char sArg[32];
	GetCmdArg(1, sArg, sizeof(sArg));
	
	if (args == 0)
	{
		PrintToChat(client, "Usage: sm_horde <riot|ceda|clown|mud|jimmy>");
		return Plugin_Handled;
	}
	else if (args == 1)
	{
		if(strcmp(sArg, "riot", false) == 0) Horde_SpawnRiot(client);
		else if(strcmp(sArg, "ceda", false) == 0) Horde_SpawnCeda(client);
		else if(strcmp(sArg, "clown", false) == 0) Horde_SpawnClown(client);
		else if(strcmp(sArg, "mud", false) == 0) Horde_SpawnMud(client);
		else if(strcmp(sArg, "jimmy", false) == 0) Horde_SpawnJimmy(client);
		else if(strcmp(sArg, "jimmy", false) == 0) Horde_SpawnJimmy(client);
		return Plugin_Handled;
	}
	return Plugin_Handled;
}

void Horde_SpawnRiot(int client)
{
	if (!client || !IsClientInGame(client)) return;
	
	else if(iTotalHordeCounter > 0) 
	{
		PrintToChat(client, "[Horde] There is already active mobs spawning, please wait ...");
		return;
	}
	
	PrintToChat(client, "[Horde] Player %N has called Riot Hordes, get ready!", client);
	g_bRiotSpawning = true;
	iTotalHordeCounter = 1;
	SpawnHordes(client);
	return;
}

void Horde_SpawnCeda(int client)
{
	if (!client || !IsClientInGame(client)) return;
	
	else if(iTotalHordeCounter > 0) 
	{
		PrintToChat(client, "[Horde] There is already active mobs spawning, please wait ...");
		return;
	}
	
	PrintToChat(client, "[Horde] Player %N has called Ceda Hordes, get ready!", client);
	g_bCedaSpawning = true;
	iTotalHordeCounter = 1;
	SpawnHordes(client);
	return;
}

void Horde_SpawnClown(int client)
{
	if (!client || !IsClientInGame(client)) return;
	
	else if(iTotalHordeCounter > 0) 
	{
		PrintToChat(client, "[Horde] There is already active mobs spawning, please wait ...");
		return;
	}
	
	PrintToChat(client, "[Horde] Player %N has called Clown Hordes, get ready!", client);
	g_bClownSpawning = true;
	iTotalHordeCounter = 1;
	SpawnHordes(client);
	return;
}

void Horde_SpawnMud(int client)
{
	if (!client || !IsClientInGame(client)) return;
	
	else if(iTotalHordeCounter > 0) 
	{
		PrintToChat(client, "[Horde] There is already active mobs spawning, please wait ...");
		return;
	}
	
	PrintToChat(client, "[Horde] Player %N has called Mud Hordes, get ready!", client);
	g_bMudSpawning = true;
	iTotalHordeCounter = 1;
	SpawnHordes(client);
	return;
}

void Horde_SpawnJimmy(int client)
{
	if (!client || !IsClientInGame(client)) return;
	
	else if(iTotalHordeCounter > 0) 
	{
		PrintToChat(client, "[Horde] There is already active mobs spawning, please wait ...");
		return;
	}
	
	PrintToChat(client, "[Horde] Player %N has called Jimmy Hordes, get ready!", client);
	g_bJimmySpawning = true;
	iTotalHordeCounter = 1;
	SpawnHordes(client);
	return;
}

public void OnEntityCreated(int entity, const char[] classname)
{
	if (!StrEqual(classname, "infected", false)) return;

	if(g_bRiotSpawning) // Riot
	{
		iTotalHordeCounter++;
		if(iTotalHordeCounter > g_Cvar_HordeAmmount.IntValue + 1)
		{
			g_bRiotSpawning = false;
			iTotalHordeCounter = 0;
		}
		else SetEntityModel(entity, "models/infected/common_male_riot.mdl");
	}
	
	else if(g_bCedaSpawning) // Ceda
	{
		iTotalHordeCounter++;
		if(iTotalHordeCounter > g_Cvar_HordeAmmount.IntValue + 1)
		{
			g_bCedaSpawning = false;
			iTotalHordeCounter = 0;
		}
		else SetEntityModel(entity, "models/infected/common_male_ceda.mdl");
	}
	
	else if(g_bClownSpawning) // Clown
	{
		iTotalHordeCounter++;
		if(iTotalHordeCounter > g_Cvar_HordeAmmount.IntValue + 1)
		{
			g_bClownSpawning = false;
			iTotalHordeCounter = 0;
		}
		else SetEntityModel(entity, "models/infected/common_male_clown.mdl");
	}
	
	else if(g_bMudSpawning) // Mud
	{
		iTotalHordeCounter++;
		if(iTotalHordeCounter > g_Cvar_HordeAmmount.IntValue + 1)
		{
			g_bMudSpawning = false;
			iTotalHordeCounter = 0;
		}
		else SetEntityModel(entity, "models/infected/common_male_mud.mdl");
	}
	
	else if(g_bJimmySpawning) // Jimmy
	{
		iTotalHordeCounter++;
		if(iTotalHordeCounter > g_Cvar_HordeAmmount.IntValue + 1)
		{
			g_bJimmySpawning = false;
			iTotalHordeCounter = 0;
		}
		else SetEntityModel(entity, "models/infected/common_male_jimmy.mdl");
	}
}

void SpawnHordes(int client)
{
	int CmdFlags = GetCommandFlags("z_spawn");
	SetCommandFlags("z_spawn", CmdFlags & ~FCVAR_CHEAT);
	FakeClientCommand(client, "z_spawn mob");
}