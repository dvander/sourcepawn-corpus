#include <sourcemod>
#include <sdkhooks>
#include <sdktools>

#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_VERSION "2.1"

bool g_bRiotSpawning;
bool g_bCedaSpawning;
bool g_bClownSpawning;
bool g_bMudSpawning;
bool g_bJimmySpawning;
bool g_bFallenSpawning;
bool g_bRoadcrewSpawning;
int iTotalHordeCounter;
ConVar g_Cvar_HordeAmmount;

#define GAMEDATA "unlock_fallensurvivor_limit"
ArrayList
	g_aByteSaved,
	g_aBytePatch;

Address
	g_pIsFallenSurvivorAllowed;
	

public Plugin myinfo =
{
	name = "L4D2 Spawn Uncommons",
	author = "AtomicStryker, updated by alasfourom, edit Maclarens",
	description = "Let's you spawn Uncommon Zombies",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?p=993523"
}

public void OnPluginStart()
{
	vLoadGameData();
	vIsFallenSurvivorAllowedPatch(true);
	CreateConVar("l4d2_horde_spawner_version", PLUGIN_VERSION, "L4D2 Horde Spawner Version", FCVAR_SPONLY | FCVAR_DONTRECORD);
	g_Cvar_HordeAmmount = CreateConVar("l4d2_horde_spawner_count", "20", "How many Zombies do you mean by 'horde'");
	//AutoExecConfig(true, "L4D2_Hordes_Spawner");
	RegAdminCmd("sm_horde", Command_Horde, ADMFLAG_CHEATS, "sm_horde");
	HookEvent("map_transition", event_MapTransition);
}

public void OnPluginEnd()
{
	vIsFallenSurvivorAllowedPatch(false);
}

public Action event_MapTransition(Event event, const char[] name, bool dontBroadcast)
{

	g_bRiotSpawning = false;
	g_bCedaSpawning = false;
	g_bClownSpawning = false;
	g_bMudSpawning = false;
	g_bJimmySpawning = false;
	g_bFallenSpawning = false;
	g_bRoadcrewSpawning = false;
	iTotalHordeCounter = 0;
	return Plugin_Continue;
}

void vIsFallenSurvivorAllowedPatch(bool bPatch)
{
	static bool bPatched;
	if(!bPatched && bPatch)
	{
		bPatched = true;
		int iLength = g_aBytePatch.Length;
		for(int i; i < iLength; i++)
			StoreToAddress(g_pIsFallenSurvivorAllowed + view_as<Address>(i), g_aBytePatch.Get(i), NumberType_Int8);
	}
	else if(bPatched && !bPatch)
	{
		bPatched = false;
		int iLength = g_aByteSaved.Length;
		for(int i; i < iLength; i++)
			StoreToAddress(g_pIsFallenSurvivorAllowed + view_as<Address>(i), g_aByteSaved.Get(i), NumberType_Int8);
	}
}
void vLoadGameData()
{
	char sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof(sPath), "gamedata/%s.txt", GAMEDATA);
	if(FileExists(sPath) == false)
		SetFailState("\n==========\nMissing required file: \"%s\".\n==========", sPath);

	GameData hGameData = new GameData(GAMEDATA);
	if(hGameData == null)
		SetFailState("Failed to load \"%s.txt\" gamedata.", GAMEDATA);

	int iOffset = hGameData.GetOffset("IsFallenSurvivorAllowed_Offset");
	if(iOffset == -1)
		LogError("Failed to load offset: IsFallenSurvivorAllowed_Offset");

	int iByteMatch = hGameData.GetOffset("IsFallenSurvivorAllowed_Byte");
	if(iByteMatch == -1)
		LogError("Failed to load byte: IsFallenSurvivorAllowed_Byte");

	int iByteCount = hGameData.GetOffset("IsFallenSurvivorAllowed_Count");
	if(iByteCount == -1)
		LogError("Failed to load count: IsFallenSurvivorAllowed_Count");

	g_pIsFallenSurvivorAllowed = hGameData.GetAddress("IsFallenSurvivorAllowed");
	if(!g_pIsFallenSurvivorAllowed)
		LogError("Failed to load address: IsFallenSurvivorAllowed");
	
	g_pIsFallenSurvivorAllowed += view_as<Address>(iOffset);

	g_aByteSaved = new ArrayList();
	g_aBytePatch = new ArrayList();

	for(int i; i < iByteCount; i++)
		g_aByteSaved.Push(LoadFromAddress(g_pIsFallenSurvivorAllowed + view_as<Address>(i), NumberType_Int8));
	
	if(g_aByteSaved.Get(0) != iByteMatch)
		LogError("Failed to load 'IsFallenSurvivorAllowed', byte mis-match @ %d (0x%02X != 0x%02X)", iOffset, g_aByteSaved.Get(0), iByteMatch);

	switch(iByteMatch)
	{
		case 0x0F:
		{
			g_aBytePatch.Push(0x90);
			g_aBytePatch.Push(0xE9);
		}

		case 0x74:
		{
			g_aBytePatch.Push(0x90);
			g_aBytePatch.Push(0x90);
		}
	}
	delete hGameData;
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
	
	PrecacheModel("models/infected/common_male_fallen_survivor.mdl", true);
	g_bFallenSpawning = false;
	
	PrecacheModel("models/infected/common_male_roadcrew.mdl", true);
	g_bRoadcrewSpawning = false;
	
	iTotalHordeCounter = 0;
}

public Action Command_Horde(int client, int args)
{
	char sArg[32];
	GetCmdArg(1, sArg, sizeof(sArg));
	
	if (args == 0)
	{
		PrintToChat(client, "Usage: sm_horde <riot|ceda|clown|mud|jimmy|roadcrew|fallen>");
		return Plugin_Handled;
	}
	else if (args == 1)
	{
		if(strcmp(sArg, "riot", false) == 0) Horde_SpawnRiot(client);
		else if(strcmp(sArg, "ceda", false) == 0) Horde_SpawnCeda(client);
		else if(strcmp(sArg, "clown", false) == 0) Horde_SpawnClown(client);
		else if(strcmp(sArg, "mud", false) == 0) Horde_SpawnMud(client);
		else if(strcmp(sArg, "jimmy", false) == 0) Horde_SpawnJimmy(client);
		else if(strcmp(sArg, "fallen", false) == 0) Horde_SpawnFallen(client);
		else if(strcmp(sArg, "roadcrew", false) == 0) Horde_SpawnRoadcrew(client);
		return Plugin_Handled;
	}
	return Plugin_Handled;
}
void Horde_SpawnRiot(int client)
{
	if (!client || !IsClientInGame(client)) return;
	else if(iTotalHordeCounter > 0) 
	{
		PrintToChat(client, "[Horde] There is already riot spawning, please wait ...");
		return;
	}
	
	//PrintToChat(client, "[Horde] Player %N has called Riot Hordes, get ready!", client);
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
		PrintToChat(client, "[Horde] There is already ceda spawning, please wait ...");
		return;
	}
	
	//PrintToChat(client, "[Horde] Player %N has called Ceda Hordes, get ready!", client);
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
		PrintToChat(client, "[Horde] There is already clown spawning, please wait ...");
		return;
	}
	
	//PrintToChat(client, "[Horde] Player %N has called Clown Hordes, get ready!", client);
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
		PrintToChat(client, "[Horde] There is already mud spawning, please wait ...");
		return;
	}
	
	//PrintToChat(client, "[Horde] Player %N has called Mud Hordes, get ready!", client);
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
		PrintToChat(client, "[Horde] There is already jimmy spawning, please wait ...");
		return;
	}
	
	//PrintToChat(client, "[Horde] Player %N has called Jimmy Hordes, get ready!", client);
	g_bJimmySpawning = true;
	iTotalHordeCounter = 1;
	SpawnHordes(client);
	return;
}
void Horde_SpawnFallen(int client)
{
	if (!client || !IsClientInGame(client)) return;
	else if(iTotalHordeCounter > 0) 
	{
		PrintToChat(client, "[Horde] There is already falen spawning, please wait ...");
		return;
	}
	
	//PrintToChat(client, "[Horde] Player %N has called Jimmy Hordes, get ready!", client);
	g_bFallenSpawning = true;
	iTotalHordeCounter = 1;
	SpawnHordes(client);
	return;
}
void Horde_SpawnRoadcrew(int client)
{
	if (!client || !IsClientInGame(client)) return;
	else if(iTotalHordeCounter > 0) 
	{
		PrintToChat(client, "[Horde] There is already roadcrew spawning, please wait ...");
		return;
	}
	
	//PrintToChat(client, "[Horde] Player %N has called Jimmy Hordes, get ready!", client);
	g_bRoadcrewSpawning = true;
	iTotalHordeCounter = 1;
	SpawnHordes(client);
	return;
}
public void OnEntityCreated(int entity, const char[] classname)
{
	if (!StrEqual(classname, "infected", false)) return;
	if(g_bRiotSpawning) //Riot
	{
		iTotalHordeCounter++;
		if(iTotalHordeCounter > g_Cvar_HordeAmmount.IntValue + 1)
		{
			g_bRiotSpawning = false;
			iTotalHordeCounter = 0;
		}
		else SetEntityModel(entity, "models/infected/common_male_riot.mdl");
	}
	else if(g_bCedaSpawning) //Ceda
	{
		iTotalHordeCounter++;
		if(iTotalHordeCounter > g_Cvar_HordeAmmount.IntValue + 1)
		{
			g_bCedaSpawning = false;
			iTotalHordeCounter = 0;
		}
		else SetEntityModel(entity, "models/infected/common_male_ceda.mdl");
	}
	else if(g_bClownSpawning) //Clown
	{
		iTotalHordeCounter++;
		if(iTotalHordeCounter > g_Cvar_HordeAmmount.IntValue + 1)
		{
			g_bClownSpawning = false;
			iTotalHordeCounter = 0;
		}
		else SetEntityModel(entity, "models/infected/common_male_clown.mdl");
	}
	else if(g_bMudSpawning) //Mud
	{
		iTotalHordeCounter++;
		if(iTotalHordeCounter > g_Cvar_HordeAmmount.IntValue + 1)
		{
			g_bMudSpawning = false;
			iTotalHordeCounter = 0;
		}
		else SetEntityModel(entity, "models/infected/common_male_mud.mdl");
	}
	else if(g_bJimmySpawning) //Jimmy
	{
		iTotalHordeCounter++;
		if(iTotalHordeCounter > g_Cvar_HordeAmmount.IntValue + 1)
		{
			g_bJimmySpawning = false;
			iTotalHordeCounter = 0;
		}
		else SetEntityModel(entity, "models/infected/common_male_jimmy.mdl");
	}
	else if(g_bFallenSpawning) //Fallen
	{
		iTotalHordeCounter++;
		if(iTotalHordeCounter > g_Cvar_HordeAmmount.IntValue + 1)
		{
			g_bFallenSpawning = false;
			iTotalHordeCounter = 0;
		}
		else SetEntityModel(entity, "models/infected/common_male_fallen_survivor.mdl");
	}
	else if(g_bRoadcrewSpawning) //roadcrew
	{
		iTotalHordeCounter++;
		if(iTotalHordeCounter > g_Cvar_HordeAmmount.IntValue + 1)
		{
			g_bRoadcrewSpawning = false;
			iTotalHordeCounter = 0;
		}
		else SetEntityModel(entity, "models/infected/common_male_roadcrew.mdl");
	}
}
void SpawnHordes(int client)
{
	int CmdFlags = GetCommandFlags("z_spawn");
	SetCommandFlags("z_spawn", CmdFlags & ~FCVAR_CHEAT);
	FakeClientCommand(client, "z_spawn_old", "mob auto");
}