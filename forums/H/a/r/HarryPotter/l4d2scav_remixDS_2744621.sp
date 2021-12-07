#pragma semicolon 1
#pragma newdecls required //強制1.7以後的新語法

#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "DS v2.0"

public Plugin myinfo =
{
	name = "L4D2 ScavengeRemixDS",
	author = "pvtschlag/Xanaguy/HarryPotter",
	description = "Allows gas cans in scavenge events to be randomly placed using a custom list of can locations.",
	version = PLUGIN_VERSION,
	url = ""
};

ConVar g_hEnableScramble, g_hScrambleMsg;
bool g_bInEditMode = false;
bool ScrambleConfirmed = false;

ConVar g_hEnableScrambleGame, g_hScrambleMsgGame, g_hGasCanCount, g_hScavengeGasCanCount;
ConVar h_GameMode;
bool ScavengeScrambleConfirmed;

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max) 
{
	EngineVersion test = GetEngineVersion();
	
	if( test != Engine_Left4Dead2 )
	{
		strcopy(error, err_max, "Plugin only supports Left 4 Dead 2.");
		return APLRes_SilentFailure;
	}
	
	return APLRes_Success; 
}

public void OnPluginStart()
{
	//Convars
	g_hEnableScrambleGame = CreateConVar("l4d2_scavenge_scramble_gas_cans", "1", "Determines if gas cans should be scrambled at the start of a round in Scavenge mode.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_hEnableScramble = CreateConVar("l4d2_scramble_gas_cansDS", "1", "Determines if gas cans should be scrambled at the start of a round.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_hScrambleMsg = CreateConVar("l4d2_scramble_notifyDS", "0", "Determines if a message should be sent when the gas cans are scrambled.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_hScrambleMsgGame = CreateConVar("l4d2_scavenge_scramble_notifyDS", "0", "Determines if a message should be sent when the gas cans are scrambled in Scavenge mode.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_hGasCanCount = CreateConVar("l4d2_scramble_can_count", "16", "Value = How many Gas Cans to spawn from the pool.", FCVAR_NOTIFY);
	g_hScavengeGasCanCount = CreateConVar("l4d2_scavenge_scramble_can_count", "16", "Value = How many Gas Cans to spawn from the pool in Scavenge mode.", FCVAR_NOTIFY);
	h_GameMode = FindConVar("mp_gamemode");
	
	AutoExecConfig(true, "l4d2scav_remixDS"); //Create and/or load the plugin config
	
	CreateConVar("l4d2_scav_remix_versionDS", PLUGIN_VERSION, "L4D2 Scavenge Remix Version", FCVAR_NOTIFY|FCVAR_SPONLY|FCVAR_UNLOGGED|FCVAR_DONTRECORD|FCVAR_REPLICATED|FCVAR_NOTIFY);
	
	HookEvent("finale_start", ScrambleCans);
	HookEvent("finale_escape_start", GasCansStopGlowing);
	HookEvent("finale_vehicle_incoming", GasCansStopGlowing);
	HookEvent("finale_vehicle_ready", GasCansStopGlowing);
	HookEvent("instructor_server_hint_create", SecondaryScrambleCans);
	HookEvent("player_use", SecondaryScrambleCans);
	HookEvent("gascan_pour_completed", RemoveOnceFinished);
	
	HookEvent("scavenge_round_finished", RoundOver);
	HookEvent("scavenge_round_start", BeginScavenge);
	HookEvent("round_start_pre_entity", ScavengeCansStopGlowingTimer);

	HookEvent("round_start", Event_RoundStart);
	HookEvent("player_spawn", Event_PlayerSpawn,	EventHookMode_PostNoCopy);
	
	//Admin Commands
	RegAdminCmd("sm_editcans", Command_EditCans, ADMFLAG_ROOT, "Enters edit mode to allow changing can locations.");
	RegAdminCmd("sm_savecans", Command_SaveCans, ADMFLAG_ROOT, "Stores the current scavenger can locations into a file.");
	RegAdminCmd("sm_removecans", Command_RemoveCans, ADMFLAG_ROOT, "Removes all gas cans.");
	RegAdminCmd("sm_reloadcans", Command_ReloadCans, ADMFLAG_ROOT, "Reloads all gas cans from file.");
	
	/*Scavenge*/
	RegAdminCmd("sm_editscavengecans", Command_EditScavengeCans, ADMFLAG_ROOT, "Enters edit mode to allow changing can locations in scavenge mode.");
	RegAdminCmd("sm_savescavengecans", Command_SaveScavengeCans, ADMFLAG_ROOT, "Stores the current scavenger can locations into a file in scavenge mode.");
	RegAdminCmd("sm_removescavengecans", Command_RemoveScavengeCans, ADMFLAG_ROOT, "Removes all gas cans in scavenge mode.");
	RegAdminCmd("sm_reloadscavengecans", Command_ReloadScavengeCans, ADMFLAG_ROOT, "Reloads all gas cans from file in scavenge mode.");
	
	//Console Commands
	RegConsoleCmd("sm_addcan", Command_AddCan, "Adds a gascan.");
	RegConsoleCmd("sm_delcan", Command_DelCan, "Deletes a gascan.");
	
	/*Scavenge*/
	RegConsoleCmd("sm_addscavengecan", Command_AddScavengeCan, "Adds a gascan in scavenge mode.");
	RegConsoleCmd("sm_delscavengecan", Command_DelScavengeCan, "Deletes a gascan in scavenge mode.");
}

public void OnGameFrame()
{
	if (g_bInEditMode) //Check if we are in Edit mode
	{
		int[] iLookedAtCans = new int[MaxClients];
		
		for(int i = 1; i <= MaxClients; i++) //Loop Through all clients
		{
			if (IsClientConnected(i) && IsClientInGame(i) && !IsFakeClient(i)) //Make sure they are ingame and not a bot
			{
				iLookedAtCans[i-1] = GetClientAimTarget(i, false); //Store the entity they are looking at
			}
			else
			{
				iLookedAtCans[i-1] = -1; //Not a valid client so set entity they are looking at to -1
			}
		}
		
		char sEntityName[64];
		int iEntityCount = GetEntityCount(); //Get Entity count
		for (int i = 0; i < iEntityCount; i++) //Iterate through all entities
		{
			if (IsValidEdict(i)) //Ensure Edict is valid
			{
				GetEdictClassname(i, sEntityName, sizeof(sEntityName)); //Get classname of edict
				if (StrEqual(sEntityName, "weapon_gascan")) //Check if it is a gas can
				{
					SetEntProp(i, Prop_Send, "m_iGlowType", 3); //Set a steady glow(scavenger like)
					SetEntProp(i, Prop_Send, "m_nGlowRange", 0); //Set an infinite glow range(scavenger like)
					
					bool bLookedAt = false; //Start off assuming no cans are being looked at
					for(int x = 0; x < MaxClients; x++) //Loop through all clients
					{
						if (iLookedAtCans[x] == i) //Check if they are looking at this can
						{
							bLookedAt = true; //Set that this can is being looked at
							break;
						}
					}
					if (bLookedAt) //If this can is being looked at
					{
						SetEntProp(i, Prop_Send, "m_glowColorOverride", 61184); //Set the color to green color
					}
					else //Not being looked at
					{
						SetEntProp(i, Prop_Send, "m_glowColorOverride", 254); //Set the color to a red color
					}
					ChangeEdictState(i, 12); //Notify clients of the change to the glow color
				}
			}
		}
	}
}

public Action Command_EditCans(int client, int args)
{
	if (IsScavenge())
	{
		ReplyToCommand(client, "You cannot use this command in the Scavenge Game Mode.");
		return Plugin_Handled;
	}
	if (client == 0)
	{
		ReplyToCommand(client, "This command can not be used from rcon, server console, or the host of a local game.");
		return Plugin_Handled;
	}
	if (g_bInEditMode) //Editmode is active
	{
		g_bInEditMode = false; //Set to inactive
		PrintToChat(client, "[SM] Editmode disabled.");
	}
	else //Editmode is inactive
	{
		g_bInEditMode = true; //Set to active
		RemoveAllGasCans(); //Remove all spawned gas cans
		char sMapName[32];
		char sPath[256];
		GetCurrentMap(sMapName, sizeof(sMapName)); //Get the mapname to use for our filename
		BuildPath(Path_SM, sPath, sizeof(sPath), "../../cfg/coopversus/%s.txt", sMapName); //Build our filepath
		if (FileExists(sPath)) //Check if this map has a custom gas can layout
		{
			RemoveAllGasCanSpawns(); //Remove all gas can spawns
			LoadCanSpawns(); //Load gas cans from file
		}
		else
		{
			SpawnGasCans(); //Spawn default gas cans
			RemoveAllGasCanSpawns(); //Remove the gas can spawns
		}
		
		PrintToChat(client, "[SM] Editmode enabled.");
	}
	return Plugin_Handled;
}

public Action Command_EditScavengeCans(int client, int args)
{
	if (!IsScavenge)
	{
		PrintToChat(client, "[SM] You can only use this command in Scavenge gamemodes.");
		return Plugin_Handled;
	}
	if (client == 0)
	{
		ReplyToCommand(client, "This command can not be used from rcon, server console, or the host of a local game.");
		return Plugin_Handled;
	}
	if (g_bInEditMode) //Editmode is active
	{
		g_bInEditMode = false; //Set to inactive
		ScavengeDirectorStart(); //Start the director
		PrintToChat(client, "[SM] Editmode disabled.");
	}
	else //Editmode is inactive
	{
		g_bInEditMode = true; //Set to active
		RemoveAllScavengeGasCans(); //Remove all spawned gas cans
		char sMapName[32];
		char sPath2[256];
		GetCurrentMap(sMapName, sizeof(sMapName)); //Get the mapname to use for our filename
		BuildPath(Path_SM, sPath2, sizeof(sPath2), "../../cfg/maps/%s.txt", sMapName); //Build our filepath
		if (FileExists(sPath2)) //Check if this map has a custom gas can layout
		{
			RemoveAllScavengeGasCanSpawns(); //Remove all gas can spawns
			LoadScavengeCanSpawns(); //Load gas cans from file
		}
		else
		{
			SpawnScavengeGasCans(); //Spawn default gas cans
			RemoveAllScavengeGasCanSpawns(); //Remove the gas can spawns
		}
		ScavengeDirectorStop(); //Stop the director
		PrintToChat(client, "[SM] Editmode (Scavenge) enabled.");
	}
	return Plugin_Handled;
}

public Action Command_SaveCans(int client, int args)
{
	if (IsScavenge())
	{
		ReplyToCommand(client, "You cannot use this command in the Scavenge Game Mode.");
		return Plugin_Handled;
	}
	if (client == 0)
	{
		ReplyToCommand(client, "This command can not be used from rcon, server console, or the host of a local game.");
		return Plugin_Handled;
	}
	if (g_bInEditMode) //Ensure we are in Edit mode
	{
		char sMapName[32];
		char sEntityName[64];
		char sPath[256];
		
		int iCanCount = 0;  //Prepare to count the cans
		int iEntityCount = GetEntityCount(); //Get Entity count
		
		Handle kScavData = CreateKeyValues("scavenge_data"); //Create int Keyvalue structure
		KvJumpToKey(kScavData, "info", true); //Create info section
		KvSetNum(kScavData, "totalcans", 0); //Create totalcans key
		KvGoBack(kScavData); //Backup to root section
		
		KvJumpToKey(kScavData, "cans", true); //Create cans section
		
		for (int i = 0; i < iEntityCount; i++) //Iterate through all entities
		{
			if (IsValidEdict(i)) //Ensure Edict is valid
			{
				GetEdictClassname(i, sEntityName, sizeof(sEntityName)); //Get classname of edict
				if (StrEqual(sEntityName, "weapon_gascan")) //Check if it is a gas can
				{
					float vOrigin[3];
					float vAngles[3];
					char sCanName[16];
					
					GetEntPropVector(i, Prop_Send, "m_vecOrigin", vOrigin); //Get gas can origin
					GetEntPropVector(i, Prop_Send, "m_angRotation", vAngles); //Get gas can rotation
					vOrigin[2] -= 10; //Adjust Z axis for proper spawning
					
					Format(sCanName, sizeof(sCanName), "can%d", iCanCount); //Create properly numbered can name
					KvJumpToKey(kScavData, sCanName, true); //Create section for this can
					
					KvSetVector(kScavData, "origin", vOrigin); //Set the origin for this can
					KvSetVector(kScavData, "angles", vAngles); //Set the rotation for this can
					
					KvGoBack(kScavData); //Go back up to the cans section
					
					iCanCount++; //Increment our can count
				}
			}
		}
		KvGoBack(kScavData); //Go back up to root section
		KvJumpToKey(kScavData, "info"); //Jump to info section
		KvSetNum(kScavData, "totalcans", iCanCount); //Update totalcans value to the number of cans we saved
		KvRewind(kScavData); //Go back to root section
		
		GetCurrentMap(sMapName, sizeof(sMapName)); //Get the mapname to use for our filename
		BuildPath(Path_SM, sPath, sizeof(sPath), "../../cfg/coopversus/%s.txt", sMapName); //Build our filepath
		
		if (!DirExists("cfg/coopversus")) //Check if directory exists
		{
			if (!CreateDirectory("cfg/coopversus", 493)) //Create the directory
			{
				PrintToChat(client, "[SM] Failed to create directory, please check folder permisions.", iCanCount, sPath); //Unable to create directory
				delete kScavData; //Close the keyvalues handle
				return Plugin_Handled;
			}
		}
		
		KeyValuesToFile(kScavData, sPath); //Store the keyvalues structure
		delete kScavData; //Close the keyvalues handle
		
		PrintToChat(client, "[SM] Saved %d can spawn locations.", iCanCount, sPath);
	}
	return Plugin_Handled;
}

public Action Command_SaveScavengeCans(int client, int args)
{
	if (!IsScavenge())
	{
		ReplyToCommand(client, "This command can only be used in the Scavenge game mode.");
		return Plugin_Handled;
	}
	if (client == 0)
	{
		ReplyToCommand(client, "This command can not be used from rcon, server console, or the host of a local game.");
		return Plugin_Handled;
	}
	if (g_bInEditMode) //Ensure we are in Edit mode
	{
		char sMapName[32];
		char sEntityName[64];
		char sPath2[256];
		
		int iCanCount = 0;  //Prepare to count the cans
		int iEntityCount = GetEntityCount(); //Get Entity count
		
		Handle kScavData2 = CreateKeyValues("scavenge_game_data"); //Create int Keyvalue structure
		KvJumpToKey(kScavData2, "scavengeinfo", true); //Create info section
		KvSetNum(kScavData2, "totalscavengecans", 0); //Create totalcans key
		KvGoBack(kScavData2); //Backup to root section
		
		KvJumpToKey(kScavData2, "scavengecans", true); //Create cans section
		
		for (int i = 0; i < iEntityCount; i++) //Iterate through all entities
		{
			if (IsValidEdict(i)) //Ensure Edict is valid
			{
				GetEdictClassname(i, sEntityName, sizeof(sEntityName)); //Get classname of edict
				if (StrEqual(sEntityName, "weapon_gascan")) //Check if it is a gas can
				{
					float vOrigin[3];
					float vAngles[3];
					char sCanName[16];
					
					GetEntPropVector(i, Prop_Send, "m_vecOrigin", vOrigin); //Get gas can origin
					GetEntPropVector(i, Prop_Send, "m_angRotation", vAngles); //Get gas can rotation
					vOrigin[2] -= 10; //Adjust Z axis for proper spawning
					
					Format(sCanName, sizeof(sCanName), "can%d", iCanCount); //Create properly numbered can name
					KvJumpToKey(kScavData2, sCanName, true); //Create section for this can
					
					KvSetVector(kScavData2, "origin", vOrigin); //Set the origin for this can
					KvSetVector(kScavData2, "angles", vAngles); //Set the rotation for this can
					
					KvGoBack(kScavData2); //Go back up to the cans section
					
					iCanCount++; //Increment our can count
				}
			}
		}
		KvGoBack(kScavData2); //Go back up to root section
		KvJumpToKey(kScavData2, "scavengeinfo"); //Jump to info section
		KvSetNum(kScavData2, "totalcans", iCanCount); //Update totalcans value to the number of cans we saved
		KvRewind(kScavData2); //Go back to root section
		
		GetCurrentMap(sMapName, sizeof(sMapName)); //Get the mapname to use for our filename
		BuildPath(Path_SM, sPath2, sizeof(sPath2), "../../cfg/maps/%s.txt", sMapName); //Build our filepath
		
		if (!DirExists("cfg/maps")) //Check if cfg/maps directory exists
		{
			if (!CreateDirectory("cfg/maps", 493)) //Create the directory
			{
				PrintToChat(client, "[SM] Failed to create directory, please check folder permisions.", iCanCount, sPath2); //Unable to create directory
				delete kScavData2; //Close the keyvalues handle
				return Plugin_Handled;
			}
		}
		
		KeyValuesToFile(kScavData2, sPath2); //Store the keyvalues structure
		delete kScavData2; //Close the keyvalues handle
		
		PrintToChat(client, "[SM] Saved %d can spawn locations.", iCanCount, sPath2);
	}
	return Plugin_Handled;
}

public Action Command_RemoveCans(int client, int args)
{
	if (IsScavenge())
	{
		ReplyToCommand(client, "You cannot use this command in the Scavenge Game Mode.");
		return Plugin_Handled;
	}
	if (client == 0)
	{
		ReplyToCommand(client, "This command can not be used from rcon, server console, or the host of a local game.");
		return Plugin_Handled;
	}
	if (g_bInEditMode) //Ensure we are in Edit mode
	{
		char sEntityName[64];
		int iEntityCount = GetEntityCount(); //Get Entity count
		for (int i = 0; i < iEntityCount; i++) //Iterate through all entities
		{
			if (IsValidEdict(i)) //Ensure Edict is valid
			{
				GetEdictClassname(i, sEntityName, sizeof(sEntityName)); //Get classname of edict
				if (StrEqual(sEntityName, "weapon_gascan")) //Check if it is a gas can
				{
					RemoveEdict(i); //Remove the can
				}
			}
		}
	}
	return Plugin_Handled;
}

public Action Command_RemoveScavengeCans(int client, int args)
{
	if (!IsScavenge())
	{
		ReplyToCommand(client, "This command can only be used in the Scavenge game mode.");
		return Plugin_Handled;
	}
	if (client == 0)
	{
		ReplyToCommand(client, "This command can not be used from rcon, server console, or the host of a local game.");
		return Plugin_Handled;
	}
	if (g_bInEditMode) //Ensure we are in Edit mode
	{
		char sEntityName[64];
		int iEntityCount = GetEntityCount(); //Get Entity count
		for (int i = 0; i < iEntityCount; i++) //Iterate through all entities
		{
			if (IsValidEdict(i)) //Ensure Edict is valid
			{
				GetEdictClassname(i, sEntityName, sizeof(sEntityName)); //Get classname of edict
				if (StrEqual(sEntityName, "weapon_gascan")) //Check if it is a gas can
				{
					RemoveEdict(i); //Remove the can
				}
			}
		}
	}
	return Plugin_Handled;
}

public Action Command_ReloadCans(int client, int args)
{
	if (IsScavenge())
	{
		ReplyToCommand(client, "You cannot use this command in the Scavenge Game Mode.");
		return Plugin_Handled;
	}
	if (client == 0)
	{
		ReplyToCommand(client, "This command can not be used from rcon, server console, or the host of a local game.");
		return Plugin_Handled;
	}
	if (g_bInEditMode) //Ensure we are in Edit mode
	{
		RemoveAllGasCans(); //Remove all spawned gas cans
		RemoveAllGasCanSpawns(); //Remove all spawned gas can spawners
		LoadCanSpawns(); //Load gas cans from file
	}
	return Plugin_Handled;
}

public Action Command_ReloadScavengeCans(int client, int args)
{
	if (!IsScavenge())
	{
		ReplyToCommand(client, "This command can only be used in the Scavenge game mode.");
		return Plugin_Handled;
	}
	if (client == 0)
	{
		ReplyToCommand(client, "This command can not be used from rcon, server console, or the host of a local game.");
		return Plugin_Handled;
	}
	if (g_bInEditMode) //Ensure we are in Edit mode
	{
		RemoveAllScavengeGasCans(); //Remove all spawned gas cans
		RemoveAllScavengeGasCanSpawns(); //Remove all spawned gas can spawners
		LoadScavengeCanSpawns(); //Load gas cans from file
	}
	return Plugin_Handled;
}

public Action Command_AddCan(int client, int args)
{
	if (IsScavenge())
	{
		ReplyToCommand(client, "You cannot use this command in the Scavenge Game Mode.");
		return Plugin_Handled;
	}
	if (client == 0)
	{
		ReplyToCommand(client, "This command can not be used from rcon, server console, or the host of a local game.");
		return Plugin_Handled;
	}
	if (g_bInEditMode) //Ensure we are in Edit mode
	{
		float vOrigin[3];
		float vAngles[3];
		float vDest[3];
		
		//Posistion the gas can infront of the player
		GetClientAbsOrigin(client, vOrigin);
		GetClientEyeAngles(client, vAngles);
		vDest[0] = ( vOrigin[0] + ( 50 * ( Cosine(DegToRad(vAngles[1])) )) );
		vDest[1] = ( vOrigin[1] + ( 50 * ( Sine(DegToRad(vAngles[1])) ) ) );
		vDest[2] = ( vOrigin[2] + ( 50 * ( Cosine(DegToRad(vAngles[2])) ) ) );  
		
		if (!CreateGasCan(vDest, NULL_VECTOR)) //Create the gas can
		{
			PrintToChat(client, "[SM] Failed to create gas can.");
		}
	}
	return Plugin_Handled;
}

public Action Command_AddScavengeCan(int client, int args)
{
	if (!IsScavenge())
	{
		ReplyToCommand(client, "This command can only be used in the Scavenge game mode.");
		return Plugin_Handled;
	}
	if (client == 0)
	{
		ReplyToCommand(client, "This command can not be used from rcon, server console, or the host of a local game.");
		return Plugin_Handled;
	}
	if (g_bInEditMode) //Ensure we are in Edit mode
	{
		float vOrigin[3];
		float vAngles[3];
		float vDest[3];
		
		//Posistion the gas can infront of the player
		GetClientAbsOrigin(client, vOrigin);
		GetClientEyeAngles(client, vAngles);
		vDest[0] = ( vOrigin[0] + ( 50 * ( Cosine(DegToRad(vAngles[1])) )) );
		vDest[1] = ( vOrigin[1] + ( 50 * ( Sine(DegToRad(vAngles[1])) ) ) );
		vDest[2] = ( vOrigin[2] + ( 50 * ( Cosine(DegToRad(vAngles[2])) ) ) );  
		
		if (!CreateGasCan(vDest, NULL_VECTOR)) //Create the gas can
		{
			PrintToChat(client, "[SM] Failed to create gas can.");
		}
	}
	return Plugin_Handled;
}

public Action Command_DelCan(int client, int args)
{
	if (IsScavenge())
	{
		ReplyToCommand(client, "You cannot use this command in the Scavenge Game Mode.");
		return Plugin_Handled;
	}
	if (client == 0)
	{
		ReplyToCommand(client, "This command can not be used from rcon, server console, or the host of a local game.");
		return Plugin_Handled;
	}
	if (g_bInEditMode) //Ensure we are in Edit mode
	{
		int iGasCan = GetClientAimTarget(client, false); //Get entity player is aiming at
		if (IsValidEdict(iGasCan)) //Ensure it is a valid edict
		{
			char sEntityName[64];
			GetEdictClassname(iGasCan, sEntityName, sizeof(sEntityName));  //Get classname of edict
			if (StrEqual(sEntityName, "weapon_gascan")) //Check if player is looking at a gas can
			{
				RemoveEdict(iGasCan); //Remove the gas can
			}
			else //Not looking at a gas can
			{
				PrintToChat(client, "[SM] You must be looking at a gas can.");
			}
		}
		else //Not looking at a gas can
		{
			PrintToChat(client, "[SM] You must be looking at a gas can.");
		}
	}
	return Plugin_Handled;
}

public Action Command_DelScavengeCan(int client, int args)
{
	if (!IsScavenge())
	{
		ReplyToCommand(client, "This command can only be used in the Scavenge game mode.");
		return Plugin_Handled;
	}
	if (client == 0)
	{
		ReplyToCommand(client, "This command can not be used from rcon, server console, or the host of a local game.");
		return Plugin_Handled;
	}
	if (g_bInEditMode) //Ensure we are in Edit mode
	{
		int iGasCan = GetClientAimTarget(client, false); //Get entity player is aiming at
		if (IsValidEdict(iGasCan)) //Ensure it is a valid edict
		{
			char sEntityName[64];
			GetEdictClassname(iGasCan, sEntityName, sizeof(sEntityName));  //Get classname of edict
			if (StrEqual(sEntityName, "weapon_gascan")) //Check if player is looking at a gas can
			{
				RemoveEdict(iGasCan); //Remove the gas can
			}
			else //Not looking at a gas can
			{
				PrintToChat(client, "[SM] You must be looking at a gas can.");
			}
		}
		else //Not looking at a gas can
		{
			PrintToChat(client, "[SM] You must be looking at a gas can.");
		}
	}
	return Plugin_Handled;
}

public Action RoundOver(Event event, const char[] name, bool dontBroadcast) 
{
	if (IsScavenge() && g_hEnableScrambleGame.BoolValue && ScavengeScrambleConfirmed) //Make sure game is in scavenge mode and that gas cans should be scrambled
	{
		char sMapName2[32];
		char sPath2[256];
		GetCurrentMap(sMapName2, sizeof(sMapName2)); //Get the mapname to use for our filename
		BuildPath(Path_SM, sPath2, sizeof(sPath2), "../../cfg/maps/%s.txt", sMapName2); //Build our filepath
		if (FileExists(sPath2)) //Check if this map has a custom gas can layout
		{
			ScavengeScrambleConfirmed = false;
		}
	}
}

public Action BeginScavenge(Event event, const char[] name, bool dontBroadcast) 
{
	if (IsScavenge() && g_hEnableScrambleGame.BoolValue && !ScavengeScrambleConfirmed || IsM13() && g_hEnableScrambleGame.BoolValue && !ScavengeScrambleConfirmed) //Make sure game is in scavenge mode and that gas cans should be scrambled
	{
		char sMapName2[32];
		char sPath2[256];
		GetCurrentMap(sMapName2, sizeof(sMapName2)); //Get the mapname to use for our filename
		BuildPath(Path_SM, sPath2, sizeof(sPath2), "../../cfg/maps/%s.txt", sMapName2); //Build our filepath
		if (FileExists(sPath2)) //Check if this map has a custom gas can layout
		{
			RemoveAllScavengeGasCanSpawns();
			RemoveAllScavengeGasCans();
			LoadScavengeCanSpawns();
			SpawnScavengeGasCans();
			ScavengeScrambleConfirmed = true;
		}
		if (g_hScrambleMsgGame.BoolValue)
		{
			PrintToChatAll("[SM] Gas cans have been scrambled 1.");
		}
	}
}


//Loads 16 random can spawns for the map
bool LoadScavengeCanSpawns()
{
	char sMapName2[32];
	char sPath2[256];
	Handle kScavData2 = CreateKeyValues("scavenge_game_data"); //Create int Keyvalue structure
	
	GetCurrentMap(sMapName2, sizeof(sMapName2)); //Get the mapname to use for our filename
	BuildPath(Path_SM, sPath2, sizeof(sPath2), "../../cfg/maps/%s.txt", sMapName2); //Build our filepath
	
	if (!FileToKeyValues(kScavData2, sPath2)) //Load file into keyvalues structure
	{
		PrintToChatAll("[SM] Unable to load scavenge data file for map %s", sMapName2); //Can't load the file 
		return false;
	}
	
	KvJumpToKey(kScavData2, "scavengeinfo"); //Jump to info section
	int iTotalCansInFile = KvGetNum(kScavData2, "totalscavengecans"); //Grab the value of the totalcans key
	int iTotalCans;
	bool bSpawnAll;
	if (iTotalCansInFile <= g_hScavengeGasCanCount.IntValue)
	{
		iTotalCans = iTotalCansInFile;
		bSpawnAll = true;
	}
	else
	{
		iTotalCans = g_hScavengeGasCanCount.IntValue;
		bSpawnAll = false;
	}

	char sCanName[16];
	float vOrigin[3];
	float vAngles[3];
	int iRand = -1;
	KvGoBack(kScavData2); //Go back to root section
	KvJumpToKey(kScavData2, "scavengecans"); //Jump to cans section
	
	if (g_bInEditMode) //Check if we are in edit mode
	{
		for (int i = 0; i < iTotalCansInFile; i++) //We are in edit mode so spawn all saved gas cans
		{
			Format(sCanName, sizeof(sCanName), "can%d", i); 
			if (KvJumpToKey(kScavData2, sCanName)) //Jump to this cans section
			{
				KvGetVector(kScavData2, "origin", vOrigin); //Get the spawn posistion
				KvGetVector(kScavData2, "angles", vAngles); //Get the spawn rotation
				KvGoBack(kScavData2); //Go back up to cans section
			}
			
			vOrigin[2] += 10; //Readjust Z axis for normal can spawn
			CreateGasCan(vOrigin, vAngles); //Create the gas can
		}
		PrintToChatAll("[SM] Loaded %d gas cans.", iTotalCansInFile);
	}
	else //We arn't in edit mode so act normally
	{
		if (IsScavenge() && g_hEnableScrambleGame.BoolValue)
		{
			if (bSpawnAll)
			{
				for (int i = 0; i < iTotalCans; i++) //spawn all saved gas cans
				{
					Format(sCanName, sizeof(sCanName), "can%d", i); 
					if (KvJumpToKey(kScavData2, sCanName)) //Jump to this cans section
					{
						KvGetVector(kScavData2, "origin", vOrigin); //Get the spawn posistion
						KvGetVector(kScavData2, "angles", vAngles); //Get the spawn rotation
						KvGoBack(kScavData2); //Go back up to cans section
					}
					
					CreateGasCanSpawner(vOrigin, vAngles); //Create the gas can spawner
				}
			}
			else
			{
				int[] iArray = new int[iTotalCansInFile];
				int iChosenCan, temp;
				for (int i = 0; i < iTotalCansInFile; ++i)
					iArray[i] = i;
				for (int i = 0; i < g_hScavengeGasCanCount.IntValue; i++) //We need 16 random values
				{
					iRand = GetRandomInt(0, iTotalCansInFile-1); //Generate random number
					iChosenCan = iArray[iRand];
					/*swap*/
					temp = iArray[iTotalCansInFile-1];
					iArray[iTotalCansInFile-1] = iArray[iRand];
					iArray[iRand] = temp;
					iTotalCansInFile -- ;
					/**/
					Format(sCanName, sizeof(sCanName), "can%d", iChosenCan); 
					if (KvJumpToKey(kScavData2, sCanName)) //Jump to this cans section
					{
						KvGetVector(kScavData2, "origin", vOrigin); //Get the spawn posistion
						KvGetVector(kScavData2, "angles", vAngles); //Get the spawn rotation
						KvGoBack(kScavData2); //Go back up to cans section
					}
					else
					{
						PrintToChatAll("Failed to jump to section %s, %s.txt could have errors in it.", sCanName, sMapName2);
					}
					
					CreateGasCanSpawner(vOrigin, vAngles); //Create the gas can spawner
				}
			}
		}
		else if (IsM13() && g_hEnableScrambleGame.BoolValue)
		{
			if (bSpawnAll)
			{
				for (int i = 0; i < iTotalCans; i++) //spawn all saved gas cans
				{
					Format(sCanName, sizeof(sCanName), "can%d", i); 
					if (KvJumpToKey(kScavData2, sCanName)) //Jump to this cans section
					{
						KvGetVector(kScavData2, "origin", vOrigin); //Get the spawn posistion
						KvGetVector(kScavData2, "angles", vAngles); //Get the spawn rotation
						KvGoBack(kScavData2); //Go back up to cans section
					}
					
					CreateGasCanSpawner(vOrigin, vAngles); //Create the gas can spawner
				}
			}
			else
			{
				int[] iArray = new int[iTotalCansInFile];
				int iChosenCan, temp;
				for (int i = 0; i < iTotalCansInFile; ++i)
					iArray[i] = i;

				for (int i = 0; i < 1; i++)
				{
					iRand = GetRandomInt(0, iTotalCansInFile-1); //Generate random number
					iChosenCan = iArray[iRand];
					/*swap*/
					temp = iArray[iTotalCansInFile-1];
					iArray[iTotalCansInFile-1] = iArray[iRand];
					iArray[iRand] = temp;
					iTotalCansInFile -- ;
					/**/
					Format(sCanName, sizeof(sCanName), "can%d", iChosenCan); 
					if (KvJumpToKey(kScavData2, sCanName)) //Jump to this cans section
					{
						KvGetVector(kScavData2, "origin", vOrigin); //Get the spawn posistion
						KvGetVector(kScavData2, "angles", vAngles); //Get the spawn rotation
						KvGoBack(kScavData2); //Go back up to cans section
					}
					else
					{
						PrintToChatAll("Failed to jump to section %s, %s.txt could have errors in it.", sCanName, sMapName2);
					}
					
					CreateGasCanSpawner(vOrigin, vAngles); //Create the gas can spawner
				}
			}
		}
	}
	delete kScavData2; //Close the keyvales structure handle
	return true;
}

void RemoveAllScavengeGasCans()
{
	char sEntityName[64];
	int iEntityCount = GetEntityCount(); //Get Entity count
	for (int i = 0; i < iEntityCount; i++) //Iterate through all entities
    {
        if (IsValidEdict(i)) //Ensure Edict is valid
        {
            GetEdictClassname(i, sEntityName, sizeof(sEntityName)); //Get classname of edict
            if (StrEqual(sEntityName, "weapon_gascan")) //Check if it is a gas can
            {
				RemoveEdict(i); //Remove the gas can
			}
        }
    }
}

void RemoveAllScavengeGasCanSpawns()
{
	char sEntityName[64];
	int iEntityCount = GetEntityCount(); //Get Entity count
	for (int i = 0; i < iEntityCount; i++) //Iterate through all entities
    {
        if (IsValidEdict(i)) //Ensure Edict is valid
        {
            GetEdictClassname(i, sEntityName, sizeof(sEntityName)); //Get classname of edict
            if (StrEqual(sEntityName, "weapon_scavenge_item_spawn")) //Check if it is a gas can spawner
            {
				RemoveEdict(i); //Remove the gas can spawner
			}
        }
    }
}

int SpawnScavengeGasCans()
{
	char sEntityName[64];
	int iEntityCount = GetEntityCount(); //Get Entity count
	int iSpawnCount = 0; //Prepare to count how many cans we spawn
	for (int i = 0; i < iEntityCount; i++) //Iterate through all entities
	{
		if (IsValidEdict(i)) //Ensure Edict is valid
		{
			GetEdictClassname(i, sEntityName, sizeof(sEntityName)); //Get classname of edict
			if (StrEqual(sEntityName, "weapon_scavenge_item_spawn")) //Check if it is a gas can spawner
			{
				AcceptEntityInput(i, "SpawnItem"); //Send input to entity to force it to spawn a can
				iSpawnCount++; //Increment our can count
			}
		}
	}
	return iSpawnCount; //Return total cans spawned
}

int g_iRoundStart, g_iPlayerSpawn;
public void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	if( g_iPlayerSpawn == 1 && g_iRoundStart == 0 )
		CreateTimer(0.5, tmrStart, _, TIMER_FLAG_NO_MAPCHANGE);
	g_iRoundStart = 1;
}

public void Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	if( g_iPlayerSpawn == 0 && g_iRoundStart == 1 )
		CreateTimer(0.5, tmrStart, _, TIMER_FLAG_NO_MAPCHANGE);
	g_iPlayerSpawn = 1;
}

public Action tmrStart(Handle timer)
{
	g_iPlayerSpawn = 0;
	g_iRoundStart = 0;

	if (g_hEnableScramble.BoolValue && !IsScavenge() && !IsSurvival()) //Make sure game is in scavenge mode and that gas cans should be scrambled
	{
		char sMapName[32];
		char sPath[256];
		GetCurrentMap(sMapName, sizeof(sMapName)); //Get the mapname to use for our filename
		BuildPath(Path_SM, sPath, sizeof(sPath), "../../cfg/coopversus/%s.txt", sMapName); //Build our filepath
		if (FileExists(sPath)) //Check if this map has a custom gas can layout
		{
			RemoveAllGasCanSpawns();
			RemoveAllGasCans();
		}
		ScrambleConfirmed = false;
		CreateTimer(5.0, GasCansStopGlowing2);
	}
	else if (g_hEnableScrambleGame.BoolValue && IsScavenge() || g_hEnableScrambleGame.BoolValue && IsM13())
	{
		char sMapName2[32];
		char sPath2[256];
		GetCurrentMap(sMapName2, sizeof(sMapName2)); //Get the mapname to use for our filename
		BuildPath(Path_SM, sPath2, sizeof(sPath2), "../../cfg/maps/%s.txt", sMapName2); //Build our filepath
		if (FileExists(sPath2)) //Check if this map has a custom gas can layout
		{
			RemoveAllScavengeGasCanSpawns();
			RemoveAllScavengeGasCans();
		}
	}
}

public Action ScrambleCans(Event event, const char[] name, bool dontBroadcast) 
{
	if (g_hEnableScramble.BoolValue && !IsScavenge() && !IsSurvival() && !ScrambleConfirmed) //Make sure game is in scavenge mode and that gas cans should be scrambled
	{
		char sMapName[32];
		char sPath[256];
		GetCurrentMap(sMapName, sizeof(sMapName)); //Get the mapname to use for our filename
		BuildPath(Path_SM, sPath, sizeof(sPath), "../../cfg/coopversus/%s.txt", sMapName); //Build our filepath
		if (FileExists(sPath)) //Check if this map has a custom gas can layout
		{
			RemoveAllGasCanSpawns(); //Remove all current gas cans
			RemoveAllGasCans(); //Remove all current gas can spawners
			LoadCanSpawns(); //Load random gas can spawns
			SpawnGasCans();
			ScrambleConfirmed = true;
		}
		if (g_hScrambleMsg.BoolValue)
		{
			PrintToChatAll("[SM] Gas cans have been scrambled 2.");
		}
	}
}

public Action SecondaryScrambleCans(Event event, const char[] name, bool dontBroadcast) 
{
	if(g_hEnableScramble.BoolValue && !ScrambleConfirmed && !IsScavenge() && !IsSurvival())
		CreateTimer(0.2, ScrambleCansSecondary);
}

public Action RemoveOnceFinished(Event event, const char[] name, bool dontBroadcast) 
{
	CreateTimer(0.2, ConfirmRemoval);
	
	if (IsM13() && g_hEnableScrambleGame.BoolValue) //Make sure game is in scavenge mode and that gas cans should be scrambled
	{
		char sMapName2[32];
		char sPath2[256];
		GetCurrentMap(sMapName2, sizeof(sMapName2)); //Get the mapname to use for our filename
		BuildPath(Path_SM, sPath2, sizeof(sPath2), "../../cfg/maps/%s.txt", sMapName2); //Build our filepath
		if (FileExists(sPath2)) //Check if this map has a custom gas can layout
		{
			RemoveAllScavengeGasCanSpawns();
			RemoveAllScavengeGasCans();
			LoadScavengeCanSpawns();
			SpawnScavengeGasCans();
		}
	}
}

public Action ConfirmRemoval(Handle timer)
{
	if (!IsScavenge() && !IsSurvival() && !IsM13())
	{
		char sMapName[32];
		char sPath[256];
		GetCurrentMap(sMapName, sizeof(sMapName)); //Get the mapname to use for our filename
		BuildPath(Path_SM, sPath, sizeof(sPath), "../../cfg/coopversus/%s.txt", sMapName); //Build our filepath
		if (FileExists(sPath)) //Check if this map has a custom gas can layout
		{
			int display = -1;
	
			while ((display = FindEntityByClassname(display, "game_scavenge_progress_display")) != -1)
			{
				if (GetEntProp(display, Prop_Send, "m_bActive", 1) && !IsScavenge())
				{
					PrintToServer("ScavengeRemixDS: The Progress Display needs to be disabled first.");
				}
				else
				{
					RemoveAllGasCans(); //Remove all current gas can spawners
				}
			}
		}
	}
}

public Action ScrambleCansSecondary(Handle timer)
{
	int goal = -1;
	
	while ((goal = FindEntityByClassname(goal, "game_scavenge_progress_display")) != -1)
	{
		if (GetEntProp(goal, Prop_Send, "m_bActive", 1))
		{
			char sMapName[32];
			char sPath[256];
			GetCurrentMap(sMapName, sizeof(sMapName)); //Get the mapname to use for our filename
			BuildPath(Path_SM, sPath, sizeof(sPath), "../../cfg/coopversus/%s.txt", sMapName); //Build our filepath
			if (FileExists(sPath)) //Check if this map has a custom gas can layout
			{
				RemoveAllGasCanSpawns(); //Remove all current gas cans
				RemoveAllGasCans(); //Remove all current gas can spawners
				LoadCanSpawns(); //Load random gas can spawns
				SpawnGasCans();
				ScrambleConfirmed = true;
			}
			if (g_hScrambleMsg.BoolValue)
			{
				PrintToChatAll("[SM] Gas cans have been scrambled 3.");
			}
		}
	}
}

public Action GasCansStopGlowing(Event event, const char[] name, bool dontBroadcast) 
{
	char sMapName[32];
	char sPath[256];
	GetCurrentMap(sMapName, sizeof(sMapName));
	BuildPath(Path_SM, sPath, sizeof(sPath), "../../cfg/coopversus/%s.txt", sMapName);
	if (FileExists(sPath))
	{
		char sEntityName[64];
		int iEntityCount = GetEntityCount();
		for (int i = 0; i < iEntityCount; i++)
		{
			if (IsValidEdict(i)) //Ensure Edict is valid
			{
				GetEdictClassname(i, sEntityName, sizeof(sEntityName));
				if (StrEqual(sEntityName, "weapon_gascan"))
				{
					SetEntProp(i, Prop_Send, "m_iGlowType", 0);
				}
			}
		}
	}
}

public Action ScavengeCansStopGlowingTimer(Event event, const char[] name, bool dontBroadcast) 
{
	if (IsScavenge() && !ScavengeScrambleConfirmed)
	{
		char sMapName2[32];
		char sPath2[256];
		GetCurrentMap(sMapName2, sizeof(sMapName2));
		BuildPath(Path_SM, sPath2, sizeof(sPath2), "../../cfg/maps/%s.txt", sMapName2);
		if (FileExists(sPath2))
		{
			CreateTimer(0.5, ScavengeCansStopGlowing);
		}
	}
}

public Action ScavengeCansStopGlowing(Handle timer)
{
	char sEntityName[64];
	int iEntityCount = GetEntityCount();
	for (int i = 0; i < iEntityCount; i++)
	{
		if (IsValidEdict(i)) //Ensure Edict is valid
		{
			GetEdictClassname(i, sEntityName, sizeof(sEntityName));
			if (StrEqual(sEntityName, "weapon_gascan"))
			{
				SetEntProp(i, Prop_Send, "m_iGlowType", 0);
			}
		}
	}
}

public Action GasCansStopGlowing2(Handle timer)
{
	char sEntityName[64];
	int iEntityCount = GetEntityCount();
	for (int i = 0; i < iEntityCount; i++)
	{
		if (IsValidEdict(i)) //Ensure Edict is valid
		{
			GetEdictClassname(i, sEntityName, sizeof(sEntityName));
			if (StrEqual(sEntityName, "weapon_gascan"))
			{
				SetEntProp(i, Prop_Send, "m_iGlowType", 0);
			}
		}
	}
}

public Action InitialStopGlow(Handle timer)
{
	char sMapName[32];
	char sPath[256];
	GetCurrentMap(sMapName, sizeof(sMapName));
	BuildPath(Path_SM, sPath, sizeof(sPath), "../../cfg/coopversus/%s.txt", sMapName);
	if (FileExists(sPath))
	{
		char sEntityName[64];
		int iEntityCount = GetEntityCount();
		for (int i = 0; i < iEntityCount; i++)
		{
			if (IsValidEdict(i)) //Ensure Edict is valid
			{
				GetEdictClassname(i, sEntityName, sizeof(sEntityName));
				if (StrEqual(sEntityName, "weapon_gascan"))
				{
					SetEntProp(i, Prop_Send, "m_iGlowType", 0);
				}
			}
		}
	}
}


//Loads random can spawns for the map
bool LoadCanSpawns()
{
	char sMapName[32];
	char sPath[256];
	Handle kScavData = CreateKeyValues("scavenge_data"); //Create int Keyvalue structure
	
	GetCurrentMap(sMapName, sizeof(sMapName)); //Get the mapname to use for our filename
	BuildPath(Path_SM, sPath, sizeof(sPath), "../../cfg/coopversus/%s.txt", sMapName); //Build our filepath
	
	if (!FileToKeyValues(kScavData, sPath)) //Load file into keyvalues structure
	{
		return false;
	}
	
	KvJumpToKey(kScavData, "info"); //Jump to info section
	int iTotalCansInFile = KvGetNum(kScavData, "totalcans"); //Grab the value of the totalcans key
	int iTotalCans;
	bool bSpawnAll;
	if (iTotalCansInFile <= g_hGasCanCount.IntValue)
	{
		iTotalCans = iTotalCansInFile;
		bSpawnAll = true;
	}
	else
	{
		iTotalCans = g_hGasCanCount.IntValue;
		bSpawnAll = false;
	}
	
	char sCanName[16];
	float vOrigin[3];
	float vAngles[3];
	int iRand = -1;
	KvGoBack(kScavData); //Go back to root section
	KvJumpToKey(kScavData, "cans"); //Jump to cans section
	
	if (g_bInEditMode) //Check if we are in edit mode
	{
		for (int i = 0; i < iTotalCansInFile; i++) //We are in edit mode so spawn all saved gas cans
		{
			Format(sCanName, sizeof(sCanName), "can%d", i); 
			if (KvJumpToKey(kScavData, sCanName)) //Jump to this cans section
			{
				KvGetVector(kScavData, "origin", vOrigin); //Get the spawn posistion
				KvGetVector(kScavData, "angles", vAngles); //Get the spawn rotation
				KvGoBack(kScavData); //Go back up to cans section
			}
			
			vOrigin[2] += 10; //Readjust Z axis for normal can spawn
			CreateGasCan(vOrigin, vAngles); //Create the gas can
		}
		PrintToChatAll("[SM] Loaded %d gas cans.", iTotalCansInFile);
	}
	else //We arn't in edit mode so act normally
	{
		if (bSpawnAll)
		{
			for (int i = 0; i < iTotalCans; i++) //spawn all saved gas cans
			{
				Format(sCanName, sizeof(sCanName), "can%d", i); 
				if (KvJumpToKey(kScavData, sCanName)) //Jump to this cans section
				{
					KvGetVector(kScavData, "origin", vOrigin); //Get the spawn posistion
					KvGetVector(kScavData, "angles", vAngles); //Get the spawn rotation
					KvGoBack(kScavData); //Go back up to cans section
				}
				
				CreateGasCanSpawner(vOrigin, vAngles); //Create the gas can spawner
			}
		}
		else
		{
			int[] iArray = new int[iTotalCansInFile];
			int iChosenCan, temp;
			for (int i = 0; i < iTotalCansInFile; ++i)
				iArray[i] = i;

			for (int i = 0; i < iTotalCans; i++)
			{
				iRand = GetRandomInt(0, iTotalCansInFile-1); //Generate random number
				iChosenCan = iArray[iRand];
				/*swap*/
				temp = iArray[iTotalCansInFile-1];
				iArray[iTotalCansInFile-1] = iArray[iRand];
				iArray[iRand] = temp;
				iTotalCansInFile -- ;
				/**/
				Format(sCanName, sizeof(sCanName), "can%d", iChosenCan);
				if (KvJumpToKey(kScavData, sCanName)) //Jump to this cans section
				{
					KvGetVector(kScavData, "origin", vOrigin); //Get the spawn posistion
					KvGetVector(kScavData, "angles", vAngles); //Get the spawn rotation
					KvGoBack(kScavData); //Go back up to cans section
				}
				else
				{
					PrintToChatAll("Failed to jump to section %s, %s.txt could have errors in it.", sCanName, sMapName);
				}
				
				CreateGasCanSpawner(vOrigin, vAngles); //Create the gas can spawner
			}
		}
	}
	delete kScavData; //Close the keyvales structure handle
	return true;
}

//Removes all gas can entities
void RemoveAllGasCans()
{
	char sEntityName[64];
	int iEntityCount = GetEntityCount(); //Get Entity count
	for (int i = 0; i < iEntityCount; i++) //Iterate through all entities
	{
		if (IsValidEdict(i)) //Ensure Edict is valid
		{
			GetEdictClassname(i, sEntityName, sizeof(sEntityName)); //Get classname of edict
			if (StrEqual(sEntityName, "weapon_gascan")) //Check if it is a gas can
			{
				RemoveEdict(i); //Remove the gas can
			}
		}
	}
}

//Removes all weapon_scavenge_item_spawn entities
void RemoveAllGasCanSpawns()
{
	char sEntityName[64];
	int iEntityCount = GetEntityCount(); //Get Entity count
	for (int i = 0; i < iEntityCount; i++) //Iterate through all entities
	{
		if (IsValidEdict(i)) //Ensure Edict is valid
		{
			GetEdictClassname(i, sEntityName, sizeof(sEntityName)); //Get classname of edict
			if (StrEqual(sEntityName, "weapon_scavenge_item_spawn")) //Check if it is a gas can spawner
			{
				RemoveEdict(i); //Remove the gas can spawner
			}
		}
	}
}

//Spawns a gas can at every weapon_scavenge_item_spawn entity
//Returns the number of gas cans spawned
int SpawnGasCans()
{
	char sEntityName[64];
	int iEntityCount = GetEntityCount(); //Get Entity count
	int iSpawnCount = 0; //Prepare to count how many cans we spawn
	for (int i = 0; i < iEntityCount; i++) //Iterate through all entities
	{
		if (IsValidEdict(i)) //Ensure Edict is valid
		{
			GetEdictClassname(i, sEntityName, sizeof(sEntityName)); //Get classname of edict
			if (StrEqual(sEntityName, "weapon_scavenge_item_spawn")) //Check if it is a gas can spawner
			{
				AcceptEntityInput(i, "SpawnItem"); //Send input to entity to force it to spawn a can
				iSpawnCount++; //Increment our can count
			}
		}
	}
	return iSpawnCount; //Return total cans spawned
}

//Creates a gas can
//Returns true if can was created
bool CreateGasCan(float vPos[3], float vAng[3])
{
	int iCan = CreateEntityByName("weapon_gascan");
	if (IsValidEdict(iCan))
	{
		DispatchKeyValue(iCan, "model", "models/props_junk/gascan001a.mdl");
		DispatchSpawn(iCan);
		TeleportEntity(iCan, vPos, vAng, NULL_VECTOR);
		return true;
	}
	return false;
}

//Creates a gas can spawner
//Returns true if spawner was created
bool CreateGasCanSpawner(float vPos[3], float vAng[3])
{
	int iCanSpawner = CreateEntityByName("weapon_scavenge_item_spawn");
	if (IsValidEdict(iCanSpawner))
	{
		DispatchSpawn(iCanSpawner);
		TeleportEntity(iCanSpawner, vPos, vAng, NULL_VECTOR);
		return true;
	}
	return false;
}

bool IsScavenge()
{
	char gamemode[56];
	h_GameMode.GetString(gamemode, sizeof(gamemode));
	if (StrContains(gamemode, "scavenge", false) > -1)
	{
		return true;
	}
	return false;
}

bool IsM13()
{
	char gamemode[56];
	h_GameMode.GetString(gamemode, sizeof(gamemode));
	if (StrContains(gamemode, "mutation13", false) > -1)
	{
		return true;
	}
	return false;
}


bool IsSurvival()
{
	char gamemode[56];
	h_GameMode.GetString(gamemode, sizeof(gamemode));
	if (StrContains(gamemode, "survival", false) > -1)
		return true;
	return false;
}

void ScavengeDirectorStop()
{
	//doing director_stop on the server sets the below variables like so
	FindConVar("director_no_bosses").SetInt(1);
	FindConVar("director_no_specials").SetInt(1);
	FindConVar("director_no_mobs").SetInt(1);
	FindConVar("director_ready_duration").SetInt(0);
	FindConVar("z_common_limit").SetInt(0);
	FindConVar("z_mega_mob_size").SetInt(1); //why not 0? only Valve knows
	FindConVar("scavenge_round_initial_time").SetInt(6000);
}

//Credit to Downtown1 for this function
void ScavengeDirectorStart()
{
	FindConVar("mp_restartgame").SetInt(1);
	FindConVar("director_no_bosses").SetInt(0);
	FindConVar("director_no_specials").SetInt(0);
	FindConVar("director_no_mobs").SetInt(0);
	FindConVar("director_ready_duration").SetInt(0);
	FindConVar("z_common_limit").SetInt(20);
	FindConVar("z_mega_mob_size").SetInt(30);
	FindConVar("scavenge_round_initial_time").SetInt(90);
}