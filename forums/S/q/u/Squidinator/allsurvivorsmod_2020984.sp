#pragma semicolon			1
#include <sourcemod>
#include <sdktools>

#define MODEL_FRANCIS		"models/survivors/survivor_biker.mdl"
#define MODEL_LOUIS			"models/survivors/survivor_manager.mdl"
#define MODEL_ZOEY			"models/survivors/survivor_teenangst.mdl"
#define MODEL_BILL			"models/survivors/survivor_namvet.mdl"
#define MODEL_NICK			"models/survivors/survivor_gambler.mdl"
#define MODEL_COACH			"models/survivors/survivor_coach.mdl"
#define MODEL_ROCHELLE		"models/survivors/survivor_producer.mdl"
#define MODEL_ELLIS			"models/survivors/survivor_mechanic.mdl"
#define MODEL_STRINGLENGTH	64
#define SURVIVOR_COUNT		8

#define TEST_DEBUG			0
#define TEST_DEBUG_LOG		0

new String:zmb_CurMapName[24];
new bool:zmb_IncompatMap = false;

public OnPluginStart()
{
	decl String:s_Game[12];
	GetGameFolderName( s_Game, sizeof( s_Game ) );
	if ( !StrEqual( s_Game, "left4dead2", false ) )
	{
		SetFailState("supports Left 4 Dead 2 only!");
	}

	HookEvent( "item_pickup"/*"*/, EventItemPickup );
	InitArray();
}

public OnMapStart()
{
	GetCurrentMap( zmb_CurMapName, sizeof( zmb_CurMapName ) );
	if ( strcmp( zmb_CurMapName, "c6m3_port" ) == 0 )
	{
		zmb_IncompatMap = true;
	}
	else
	{
		zmb_IncompatMap = false;
	}

	if (!IsModelPrecached(MODEL_LOUIS))
		PrecacheModel(MODEL_LOUIS, true);

	if (!IsModelPrecached(MODEL_BILL))
		PrecacheModel(MODEL_BILL, true);

	if (!IsModelPrecached(MODEL_NICK))
		PrecacheModel(MODEL_NICK, true);

	if (!IsModelPrecached(MODEL_COACH))
		PrecacheModel(MODEL_COACH, true);

	if (!IsModelPrecached(MODEL_ROCHELLE))
		PrecacheModel(MODEL_ROCHELLE, true);

	if (!IsModelPrecached(MODEL_ELLIS))
		PrecacheModel(MODEL_ELLIS, true);

	if (!IsModelPrecached(MODEL_ZOEY))
		PrecacheModel(MODEL_ZOEY, true);

	if (!IsModelPrecached(MODEL_FRANCIS))
		PrecacheModel(MODEL_FRANCIS, true);
}

enum data
{
	bool:isPresent, survivorChar, String:characterModel[MODEL_STRINGLENGTH]
}

static characterArray[SURVIVOR_COUNT][data];

InitArray()
{
	characterArray[0][survivorChar] = 0;
	strcopy(characterArray[0][characterModel], MODEL_STRINGLENGTH, MODEL_NICK);
	characterArray[1][survivorChar] = 1;
	strcopy(characterArray[1][characterModel], MODEL_STRINGLENGTH, MODEL_ROCHELLE);
	characterArray[2][survivorChar] = 2;
	strcopy(characterArray[2][characterModel], MODEL_STRINGLENGTH, MODEL_COACH);
	characterArray[3][survivorChar] = 3;
	strcopy(characterArray[3][characterModel], MODEL_STRINGLENGTH, MODEL_ELLIS);
	characterArray[4][survivorChar] = 4;
	strcopy(characterArray[4][characterModel], MODEL_STRINGLENGTH, MODEL_BILL);
	characterArray[5][survivorChar] = 1;
	strcopy(characterArray[5][characterModel], MODEL_STRINGLENGTH, MODEL_ZOEY);
	characterArray[6][survivorChar] = 4;
	strcopy(characterArray[6][characterModel], MODEL_STRINGLENGTH, MODEL_FRANCIS);
	characterArray[7][survivorChar] = 7;
	strcopy(characterArray[7][characterModel], MODEL_STRINGLENGTH, MODEL_LOUIS);
}

public EventItemPickup(Handle:event, const String:eventname[], bool:b_DontBroadcast)
{
/*
	GetConVarString( FindConVar( "host_map" ), zmb_CurMapName, sizeof( zmb_CurMapName ) );
	if ( StrContains( zmb_CurMapName, "c6m3_port.bsp", false ) == -1 )
	{
		return Plugin_Stop;
	}

	if ( StrEqual( zmb_CurMapName, "c6m3_port.bsp", false ) )
	{
		return Plugin_Stop;
	}
*/
	if ( !zmb_IncompatMap )
	{
		new client = GetClientOfUserId(GetEventInt(event, "userid"));
		CreateTimer(6.0, delayedCheck, client);
	}
}

public Action:delayedCheck(Handle:timer, any:client)
{
	if ( !zmb_IncompatMap && client > 0 && IsClientInGame(client) && GetClientTeam(client) == 2 )
	{
		CheckPresentModels();
	}
	return Plugin_Continue;
}

CheckPresentModels()
{
	//DebugPrintToAll("AllSurvivors: Player spawned 6 seconds ago, checking all models now");
	for (new i = 0; i < SURVIVOR_COUNT; i++)
	{
		characterArray[i][isPresent] = false;
	}

	decl String:curModel[MODEL_STRINGLENGTH];
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && GetClientTeam(i) == 2)
		{
			GetClientModel(i, curModel, sizeof(curModel));
			new curSurvivor = getIntFromModel(curModel);
			//DebugPrintToAll("AllSurvivors: Spots player %N wearing %i, model %s", i, curSurvivor, curModel);
			if (curSurvivor >= 0 && !characterArray[curSurvivor][isPresent])
			{
				characterArray[curSurvivor][isPresent] = true;
				//DebugPrintToAll("AllSurvivors: player %N is an original!", i);
			}
			else if (curSurvivor >= 0 && characterArray[curSurvivor][isPresent] && areCharactersFree())
			{
				new setSurvivor = getFreeSurvivor();
				if (setSurvivor >= 0)
				{
					//DebugPrintToAll("AllSurvivors: Thinks %N should rather be %i, setting model %s", i, setSurvivor, characterArray[setSurvivor][characterModel]);
					SetEntityModel(i, characterArray[setSurvivor][characterModel]);
					SetEntProp(i, Prop_Send, "m_survivorCharacter", characterArray[setSurvivor][survivorChar]);
				}
			}
		}
	}
}

getIntFromModel(const String:model[])
{
	for (new i = 0; i < SURVIVOR_COUNT; i++)
	{
		if (StrEqual(model, characterArray[i][characterModel]))
		{
			return i;
		}
	}
	
	return -1;
}

getFreeSurvivor()
{
	for (new i = 0; i < SURVIVOR_COUNT; i++)
	{
		if (!characterArray[i][isPresent])
		{
			return i;
		}
	}
	return -1;
}

bool:areCharactersFree()
{
	for (new i = 0; i < SURVIVOR_COUNT; i++)
	{
		if (!characterArray[i][isPresent])
		{
			return true;
		}
	}
	return false;
}

stock DebugPrintToAll(const String:format[], any:...)
{
	#if (TEST_DEBUG || TEST_DEBUG_LOG)
	decl String:buffer[256];
	
	VFormat(buffer, sizeof(buffer), format, 2);
	
	#if TEST_DEBUG
	PrintToChatAll("[8SURV] %s", buffer);
	PrintToConsole(0, "[8SURV] %s", buffer);
	#endif
	
	LogMessage("%s", buffer);
	#else
	//suppress "format" never used warning
	if(format[0])
		return;
	else
		return;
	#endif
}