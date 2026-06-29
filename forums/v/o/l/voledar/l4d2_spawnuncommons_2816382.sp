#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#define PLUGIN_VERSION "1.0.9"

#define DEBUG 0

#define FOR_EACH_UNCOMMON_TYPE(%1)											\
	for(int %1 = 0; %1 < sizeof(UncommonData); %1++)
	
#define STRING_LENGTH_NAME		10
#define STRING_LENGTH_MODEL		56

public Plugin myinfo =
{
	name = "L4D2 Spawn Uncommons",
	author = "AtomicStryker",
	description = "Let's you spawn Uncommon Zombies",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?p=993523"
}

enum Uncommons
{
	riot,
	ceda,
	clown,
	mudman,
	roadcrew,
	jimmy,
	fallen
}

enum struct UncommonInfo 
{
	char name[STRING_LENGTH_NAME];
	char model[STRING_LENGTH_MODEL];
	int flag;
}

static int RemainingZombiesToSpawn = 0;
static int HordeNumber = 0;
ConVar HordeAmountCVAR;
ConVar RandomizeUCI;
ConVar RandomizeUCIChance;
ConVar AllowedUCIFlags;
ConVar UCIHealthOverride;
static bool AutoShuffleEnabled = false;
static bool AreModelsCached = false;
static int UncommonInfectedChance = 0;
static int AllowedUCIFlag = 0;
static int UCIHealthOverrideValue = -1;

static UncommonInfo UncommonData[Uncommons];

public void OnPluginStart()
{
	CreateConVar("l4d2_spawn_uncommons_version", PLUGIN_VERSION, "L4D2 Spawn Uncommons Version", FCVAR_NONE | FCVAR_SPONLY | FCVAR_DONTRECORD | FCVAR_NOTIFY);
	
	HordeAmountCVAR = CreateConVar("l4d2_spawn_uncommons_hordecount", "25", "How many Zombies do you mean by 'horde'", FCVAR_NONE | FCVAR_NOTIFY);
	RandomizeUCI = CreateConVar("l4d2_spawn_uncommons_autoshuffle", "1", "Do you want all Uncommons randomly spawning on all maps", FCVAR_NONE | FCVAR_NOTIFY);
	RandomizeUCIChance = CreateConVar("l4d2_spawn_uncommons_autochance", "15", "Every 'THIS' zombie spawning will be statistically turned uncommon if autoshuffle is active", FCVAR_NONE | FCVAR_NOTIFY);
	AllowedUCIFlags = CreateConVar("l4d2_spawn_uncommons_autotypes", "19", "binary flag of allowed autoshuffle zombies. 1 = riot, 2 = ceda, 4 = clown, 8 = mudman, 16 = roadcrew, 32 = jimmy, 64 = fallen", FCVAR_NONE | FCVAR_NOTIFY);
	UCIHealthOverride = CreateConVar("l4d2_spawn_uncommons_healthoverride", "-1", "Health value the uncommons get set to. '-1' is default values", FCVAR_NONE | FCVAR_NOTIFY);
	
	RegAdminCmd("sm_spawnuncommon", Command_Uncommon, ADMFLAG_CHEATS, "Spawn uncommon infected, ANYTIME");
	RegAdminCmd("sm_spawnuncommonhorde", Command_UncommonHorde, ADMFLAG_CHEATS, "Spawn an uncommon infected horde, ANYTIME");
	
	InitDataArray();
	PreCacheModels();
	
	AutoShuffleEnabled = RandomizeUCI.BoolValue;
	UncommonInfectedChance = RandomizeUCIChance.IntValue;
	AllowedUCIFlag = AllowedUCIFlags.IntValue;
	UCIHealthOverrideValue = UCIHealthOverride.IntValue;

	RandomizeUCI.AddChangeHook(ConvarsChanged);
	RandomizeUCIChance.AddChangeHook(ConvarsChanged);
	AllowedUCIFlags.AddChangeHook(ConvarsChanged);
	UCIHealthOverride.AddChangeHook(ConvarsChanged);
}

public void ConvarsChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	AutoShuffleEnabled = RandomizeUCI.BoolValue;
	UncommonInfectedChance = RandomizeUCIChance.IntValue;
	AllowedUCIFlag = AllowedUCIFlags.IntValue;
}

public void OnMapStart()
{
	PreCacheModels();
}

static void PreCacheModels()
{
	FOR_EACH_UNCOMMON_TYPE(i)
	{
		if (!IsModelPrecached(UncommonData[i].model))
		{
			PrecacheModel(UncommonData[i].model, true);
		}
	}
	AreModelsCached = true;
}

public void OnMapEnd()
{
	RemainingZombiesToSpawn = 0;
	AreModelsCached = false;
}

static void InitDataArray()
{
	Format(UncommonData[riot].name, 		STRING_LENGTH_NAME-1, 		"riot");
	Format(UncommonData[ceda].name, 		STRING_LENGTH_NAME-1, 		"ceda");
	Format(UncommonData[clown].name,		STRING_LENGTH_NAME-1, 		"clown");
	Format(UncommonData[mudman].name, 		STRING_LENGTH_NAME-1, 		"mud");
	Format(UncommonData[roadcrew].name, 	STRING_LENGTH_NAME-1, 		"roadcrew");
	Format(UncommonData[jimmy].name, 		STRING_LENGTH_NAME-1, 		"jimmy");
	Format(UncommonData[fallen].name, 		STRING_LENGTH_NAME-1, 		"fallen");

	Format(UncommonData[riot].model, 		STRING_LENGTH_MODEL-1, 		"models/infected/common_male_riot.mdl");
	Format(UncommonData[ceda].model, 		STRING_LENGTH_MODEL-1, 		"models/infected/common_male_ceda.mdl");
	Format(UncommonData[clown].model,		STRING_LENGTH_MODEL-1, 		"models/infected/common_male_clown.mdl");
	Format(UncommonData[mudman].model, 	STRING_LENGTH_MODEL-1, 		"models/infected/common_male_mud.mdl");
	Format(UncommonData[roadcrew].model, 	STRING_LENGTH_MODEL-1, 		"models/infected/common_male_roadcrew.mdl");
	Format(UncommonData[jimmy].model, 		STRING_LENGTH_MODEL-1, 		"models/infected/common_male_jimmy.mdl");
	Format(UncommonData[fallen].model, 	STRING_LENGTH_MODEL-1, 		"models/infected/common_male_fallen_survivor.mdl");
	
	UncommonData[riot].flag		= 1;
	UncommonData[ceda].flag		= 2;
	UncommonData[clown].flag		= 4;
	UncommonData[mudman].flag		= 8;
	UncommonData[roadcrew].flag	= 16;
	UncommonData[jimmy].flag		= 32;
	UncommonData[fallen].flag		= 64;
}

public Action Command_Uncommon(int client, int args)
{
	if (!client) return Plugin_Handled;
	
	if (args < 1)
	{
		ReplyToCommand(client, "Usage: sm_spawnuncommon <riot|ceda|clown|mud|roadcrew|jimmy|fallen|random>");
		return Plugin_Handled;
	}
	
	char cmd[56];
	GetCmdArg(1, cmd, sizeof(cmd));
	int number = 0;
	
	FOR_EACH_UNCOMMON_TYPE(i)
	{
		if (StrEqual(cmd, UncommonData[i].name, false))
		{
			number = i+1;
		}
		else if (StrEqual(cmd, "random", false))
		{
			number = sizeof(UncommonData)+1;
		}
	}
		
	if (!number)
	{
		ReplyToCommand(client, "Usage: sm_spawnuncommon <riot|ceda|clown|mud|roadcrew|jimmy|fallen|random>");
		return Plugin_Handled;
	}
	
	#if DEBUG
	PrintToChatAll("Spawning Uncommon command: number: %i", number);
	#endif
	
	
	float location[3], ang[3], location2[3];
	GetClientAbsOrigin(client, location);
	GetClientEyeAngles(client, ang);
	
	location2[0] = (location[0]+(50*(Cosine(DegToRad(ang[1])))));
	location2[1] = (location[1]+(50*(Sine(DegToRad(ang[1])))));
	location2[2] = location[2] + 30.0;
	
	SpawnUncommonInf(number-1, location2);
	
	return Plugin_Handled;
}

public Action Command_UncommonHorde(int client, int args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "Usage: sm_spawnuncommonhorde <riot|ceda|clown|mud|roadcrew|jimmy|fallen|random>");
		return Plugin_Handled;
	}
	
	char cmd[56];
	int number = 0;
	
	GetCmdArg(1, cmd, sizeof(cmd));
	
	FOR_EACH_UNCOMMON_TYPE(i)
	{
		if (StrEqual(cmd, UncommonData[i].name, false))
		{
			number = i+1;
		}
		else if (StrEqual(cmd, "random", false))
		{
			number = sizeof(UncommonData);
		}
	}
	
	if (!number)
	{
		ReplyToCommand(client, "Usage: sm_spawnuncommonhorde <riot|ceda|clown|mud|roadcrew|jimmy|fallen|random>");
		return Plugin_Handled;
	}
	
	#if DEBUG
	PrintToChatAll("Spawning Uncommon Horde command: number: %i", number);	
	#endif
	
	HordeNumber = number;
	RemainingZombiesToSpawn = GetConVarInt(HordeAmountCVAR);
	CheatCommand(GetAnyClient(), "z_spawn", "mob");
	
	return Plugin_Handled;
}

public void OnEntityCreated(int entity, const char[] classname)
{
	if (!AreModelsCached
	|| !StrEqual(classname, "infected", false))
	{
		return;
	}

	int number = -1;
	
	if(RemainingZombiesToSpawn > 0)
	{
		number = HordeNumber-1;
		
		if (number == sizeof(UncommonData)-1)
		{
			if (!AllowedUCIFlag) return;
			number = GetAllowedUncommonInf();
		}
		RemainingZombiesToSpawn--;
	}
	else if (AutoShuffleEnabled && AllowedUCIFlag)
	{
		if (GetRandomInt(1, UncommonInfectedChance) != 1) return;
		
		number = GetAllowedUncommonInf();
	}
	
	if (number > -1)
	{
		SetEntityModel(entity, UncommonData[number].model);
		HandleHealthOverride(entity);
		#if DEBUG
		PrintToChatAll("Changing Zombie %i into a Uncommon of type %s", entity, UncommonData[number][name]);	
		#endif
	}
}

static int GetAllowedUncommonInf()
{
	int number = 0;
	
	do
	{
		number = GetRandomInt(0, sizeof(UncommonData)-1);		
	}
	while (!(AllowedUCIFlag & UncommonData[number].flag));
	
	#if DEBUG
	PrintToChatAll("GetAllowedUncommonInf returning inf %i", number);	
	#endif
	
	return number;
}

public void SpawnUncommonInf(int number, float location[3])
{
	int zombie = CreateEntityByName("infected");
	
	if (number == sizeof(UncommonData))
	{
		number = GetAllowedUncommonInf();
	}
	
	SetEntityModel(zombie, UncommonData[number].model);
	HandleHealthOverride(zombie);
	int ticktime = RoundToNearest( GetGameTime() / GetTickInterval() ) + 5;
	SetEntProp(zombie, Prop_Data, "m_nNextThinkTick", ticktime);

	DispatchSpawn(zombie);
	ActivateEntity(zombie);
	
	location[2] -= 25.0; //reduce the 'drop' effect
	TeleportEntity(zombie, location, NULL_VECTOR, NULL_VECTOR);
	
	#if DEBUG
	PrintToChatAll("Spawned uncommon inf %i", number);	
	#endif
}

static void HandleHealthOverride(int entity)
{
	if (UCIHealthOverrideValue != -1)
	{
		SetEntProp(entity, Prop_Data, "m_iHealth", UCIHealthOverrideValue);
	}
}

int GetAnyClient()
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i))
		{
			return i;
		}
	}
	return 0;
}

void CheatCommand(int client, const char[] command, const char[] arguments = "")
{
	if (!client) return;
	int admindata = GetUserFlagBits(client);
	SetUserFlagBits(client, ADMFLAG_ROOT);
	int flags = GetCommandFlags(command);
	SetCommandFlags(command, flags & ~FCVAR_CHEAT);
	FakeClientCommand(client, "%s %s", command, arguments);
	SetCommandFlags(command, flags);
	SetUserFlagBits(client, admindata);
}