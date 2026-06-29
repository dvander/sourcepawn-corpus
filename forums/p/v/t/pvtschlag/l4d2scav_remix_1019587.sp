///////////////////////////////////////////////////////////////////////////
//                                                                       //
// -Plugin:      L4D2 Scavenge Remix                                     //
// -Game:        Left 4 Dead 2                                           //
// -Author:      Lee "pvtschlag" Silvey                                  //
// -Version:     0.2.3                                                   //
// -URL:         http://forums.alliedmods.net/showthread.php?p=1019587   //
// -Description: Allows gas cans in scavenge to be randomly placed using //
//               a custom list of gas can locations.                     //
//                                                                       //
// -Changelog:                                                           //
//     * Version 0.1.0:                                                  //
//         -Initial Release                                              //
//     * Version 0.2.0:                                                  //
//         -Added sm_ prefix to all commands                             //
//         -Fixed cvar prefix                                            //
//         -Added cvar to disable gas cans from being scrambled          //
//         -Added cvar to show a notification when cans get scrambled    //
//         -Added user friendly notification when trying to use commands //
//             from server console, rcon, or host of a local server      //
//     * Version 0.2.1:                                                  //
//         -Added check to make sure all changed cvars get restored      //
//     * Version 0.2.2:                                                  //
//         -Fixed mistake in client 0 error checking code                //
//     * Version 0.2.3:                                                  //
//         -Fixed a few small bugs                                       //
//                                                                       //
///////////////////////////////////////////////////////////////////////////

#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "0.2.3"

public Plugin:myinfo =
{
	name = "L4D2 Scavenge Remix",
	author = "pvtschlag",
	description = "Allows gas cans in scavenge to be randomly placed using a custom list of can locations.",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?p=1019587"
};

new Handle:g_hGamemode;
new Handle:g_hEnableScramble;
new Handle:g_hScrambleMsg;
new bool:g_bInEditMode = false;
new bool:g_bIsHalftime = false;
new bool:g_bFreshMapLoad = false;
new g_iInitDirectorNoBosses;
new g_iInitDirectorNoSpecials;
new g_iInitDirectorNoMobs;
new g_iInitDirectorReadyDuration;
new g_iInitDirectorCommonLimit;
new g_iInitDirectorMegaMobSize;
new g_iAllBotTeam;

public OnPluginStart()
{
	// Require Left 4 Dead 2
	decl String:game_name[64];
	GetGameFolderName(game_name, sizeof(game_name));
	if (!StrEqual(game_name, "left4dead2", false))
	{
		SetFailState("Plugin supports Left 4 Dead 2 only.");
	}

	//Convars
	g_hGamemode = FindConVar("mp_gamemode");
	
	g_hEnableScramble = CreateConVar("l4d2_scramble_gas_cans", "1", "Determines if gas cans should be scrambled at the start of a round.", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_hScrambleMsg = CreateConVar("l4d2_scramble_notify", "0", "Determines if a message should be sent when the gas cans are scrambled.", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	
	AutoExecConfig(true, "l4d2scav_remix"); //Create and/or load the plugin config
	
	CreateConVar("l4d2_scav_remix_version", PLUGIN_VERSION, "L4D2 Scavenge Remix Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_UNLOGGED|FCVAR_DONTRECORD|FCVAR_REPLICATED|FCVAR_NOTIFY);
	
	//Events
	HookEvent("scavenge_round_halftime", Event_RoundHalftime, EventHookMode_PostNoCopy);
	HookEvent("scavenge_round_finished", Event_RoundFinished, EventHookMode_PostNoCopy);
	HookEvent("round_start_pre_entity", Event_RoundInit, EventHookMode_PostNoCopy);
	
	//Admin Commands
	RegAdminCmd("sm_editcans", Command_EditCans, ADMFLAG_ROOT, "Enters edit mode to allow changing can locations.");
	RegAdminCmd("sm_savecans", Command_SaveCans, ADMFLAG_ROOT, "Stores the current scavenger can locations into a file.");
	RegAdminCmd("sm_removecans", Command_RemoveCans, ADMFLAG_ROOT, "Removes all gas cans.");
	RegAdminCmd("sm_reloadcans", Command_ReloadCans, ADMFLAG_ROOT, "Reloads all gas cans from file.");
	
	//Console Commands
	RegConsoleCmd("sm_addcan", Command_AddCan, "Adds a gascan.");
	RegConsoleCmd("sm_delcan", Command_DelCan, "Deletes a gascan.");
}

public OnPluginEnd()
{
	if (g_bInEditMode) //Check if we are in Edit mode
	{
		DirectorStart();
	}
}

public OnMapStart()
{
	if (IsScavenge())
	{
		g_bIsHalftime = false; //Reset halftime to false
		g_bFreshMapLoad = true; //This is a fresh map load
	}
}

public OnMapEnd()
{
	if (IsScavenge())
	{
		g_bIsHalftime = false; //Reset halftime to false
	}
}

public OnGameFrame()
{
	if (g_bInEditMode) //Check if we are in Edit mode
	{
		new iLookedAtCans[MaxClients];
		
		for(new i = 1; i <= MaxClients; i++) //Loop Through all clients
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
		
		decl String:sEntityName[64];
		new iEntityCount = GetEntityCount(); //Get Entity count
		for (new i = 0; i < iEntityCount; i++) //Iterate through all entities
		{
			if (IsValidEdict(i)) //Ensure Edict is valid
			{
				GetEdictClassname(i, sEntityName, sizeof(sEntityName)); //Get classname of edict
				if (StrEqual(sEntityName, "weapon_gascan")) //Check if it is a gas can
				{
					SetEntProp(i, Prop_Send, "m_iGlowType", 3); //Set a steady glow(scavenger like)
					SetEntProp(i, Prop_Send, "m_nGlowRange", 0); //Set an infinite glow range(scavenger like)
					
					new bool:bLookedAt = false; //Start off assuming no cans are being looked at
					for(new x = 0; x < MaxClients; x++) //Loop through all clients
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

public Action:Command_EditCans(client, args)
{
	if (client == 0)
	{
		ReplyToCommand(client, "This command can not be used from rcon, server console, or the host of a local game.");
		return Plugin_Handled;
	}
	if (g_bInEditMode) //Editmode is active
	{
		g_bInEditMode = false; //Set to inactive
		SetConVarString(g_hGamemode, "scavenge"); //Set gamemode to scavenge
		DirectorStart(); //Start the director
		PrintToChat(client, "[SM] Editmode disabled.");
	}
	else //Editmode is inactive
	{
		g_bInEditMode = true; //Set to active
		RemoveAllGasCans(); //Remove all spawned gas cans
		decl String:sMapName[32];
		decl String:sPath[256];
		GetCurrentMap(sMapName, sizeof(sMapName)); //Get the mapname to use for our filename
		BuildPath(Path_SM, sPath, sizeof(sPath), "../../cfg/maps/%s.txt", sMapName); //Build our filepath
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
		SetConVarString(g_hGamemode, "coop"); //Set gamemode to coop
		DirectorStop(); //Stop the director
		PrintToChat(client, "[SM] Editmode enabled.");
	}
	return Plugin_Handled;
}

public Action:Command_SaveCans(client, args)
{
	if (client == 0)
	{
		ReplyToCommand(client, "This command can not be used from rcon, server console, or the host of a local game.");
		return Plugin_Handled;
	}
	if (g_bInEditMode) //Ensure we are in Edit mode
	{
		decl String:sMapName[32];
		decl String:sEntityName[64];
		decl String:sPath[256];
		
		new iCanCount = 0;  //Prepare to count the cans
		new iEntityCount = GetEntityCount(); //Get Entity count
		
		new Handle:kScavData = CreateKeyValues("scavenge_data"); //Create new Keyvalue structure
		KvJumpToKey(kScavData, "info", true); //Create info section
		KvSetNum(kScavData, "totalcans", 0); //Create totalcans key
		KvGoBack(kScavData); //Backup to root section
		
		KvJumpToKey(kScavData, "cans", true); //Create cans section
		
		for (new i = 0; i < iEntityCount; i++) //Iterate through all entities
		{
			if (IsValidEdict(i)) //Ensure Edict is valid
			{
				GetEdictClassname(i, sEntityName, sizeof(sEntityName)); //Get classname of edict
				if (StrEqual(sEntityName, "weapon_gascan")) //Check if it is a gas can
				{
					decl Float:vOrigin[3];
					decl Float:vAngles[3];
					decl String:sCanName[16];
					
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
		BuildPath(Path_SM, sPath, sizeof(sPath), "../../cfg/maps/%s.txt", sMapName); //Build our filepath
		
		if (!DirExists("cfg/maps")) //Check if cfg/maps directory exists
		{
			if (!CreateDirectory("cfg/maps", 493)) //Create the directory
			{
				PrintToChat(client, "[SM] Failed to create directory, please check folder permisions.", iCanCount, sPath); //Unable to create directory
				CloseHandle(kScavData); //Close the keyvalues handle
				return Plugin_Handled;
			}
		}
		
		KeyValuesToFile(kScavData, sPath); //Store the keyvalues structure
		CloseHandle(kScavData); //Close the keyvalues handle
		
		PrintToChat(client, "[SM] Saved %d can spawn locations.", iCanCount, sPath);
	}
	return Plugin_Handled;
}

public Action:Command_RemoveCans(client, args)
{
	if (client == 0)
	{
		ReplyToCommand(client, "This command can not be used from rcon, server console, or the host of a local game.");
		return Plugin_Handled;
	}
	if (g_bInEditMode) //Ensure we are in Edit mode
	{
		decl String:sEntityName[64];
		new iEntityCount = GetEntityCount(); //Get Entity count
		for (new i = 0; i < iEntityCount; i++) //Iterate through all entities
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

public Action:Command_ReloadCans(client, args)
{
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

public Action:Command_AddCan(client, args)
{
	if (client == 0)
	{
		ReplyToCommand(client, "This command can not be used from rcon, server console, or the host of a local game.");
		return Plugin_Handled;
	}
	if (g_bInEditMode) //Ensure we are in Edit mode
	{
		decl Float:vOrigin[3];
		decl Float:vAngles[3];
		decl Float:vDest[3];
		
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

public Action:Command_DelCan(client, args)
{
	if (client == 0)
	{
		ReplyToCommand(client, "This command can not be used from rcon, server console, or the host of a local game.");
		return Plugin_Handled;
	}
	if (g_bInEditMode) //Ensure we are in Edit mode
	{
		new iGasCan = GetClientAimTarget(client, false); //Get entity player is aiming at
		if (IsValidEdict(iGasCan)) //Ensure it is a valid edict
		{
			decl String:sEntityName[64];
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

public Action:Event_RoundFinished(Handle:event, const String:name[], bool:dontBroadcast)
{
	g_bIsHalftime = false; //No longer halftime
}

public Action:Event_RoundHalftime(Handle:event, const String:name[], bool:dontBroadcast)
{
	g_bIsHalftime = true; //Is now halftime
}

public Action:Event_RoundInit(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (IsScavenge() && GetConVarBool(g_hEnableScramble)) //Make sure game is in scavenge mode and that gas cans should be scrambled
	{
		decl String:sMapName[32];
		decl String:sPath[256];
		GetCurrentMap(sMapName, sizeof(sMapName)); //Get the mapname to use for our filename
		BuildPath(Path_SM, sPath, sizeof(sPath), "../../cfg/maps/%s.txt", sMapName); //Build our filepath
		if (FileExists(sPath)) //Check if this map has a custom gas can layout
		{
			if (!g_bIsHalftime)
			{
				CreateTimer(0.5, SetupCans, 0);
			}
		}
	}
}

public Action:SetupCans(Handle:timer)
{
	RemoveAllGasCans(); //Remove all current gas cans
	RemoveAllGasCanSpawns(); //Remove all current gas can spawners
	LoadCanSpawns(); //Load random gas can spawns
	if (GetConVarBool(g_hScrambleMsg))
	{
		PrintToChatAll("[SM] Gas can locations have been scrambled.");
	}
	if (!g_bFreshMapLoad)
	{
		SpawnGasCans(); //Spawn the gas cans
	}
	g_bFreshMapLoad = false;
}

//Loads 16 random can spawns for the map
bool:LoadCanSpawns()
{
	new String:sMapName[32];
	new String:sPath[256];
	new Handle:kScavData = CreateKeyValues("scavenge_data"); //Create new Keyvalue structure
	
	GetCurrentMap(sMapName, sizeof(sMapName)); //Get the mapname to use for our filename
	BuildPath(Path_SM, sPath, sizeof(sPath), "../../cfg/maps/%s.txt", sMapName); //Build our filepath
	
	if (!FileToKeyValues(kScavData, sPath)) //Load file into keyvalues structure
	{
		PrintToChatAll("[SM] Unable to load scavenge data file for map %s", sMapName); //Can't load the file 
		return false;
	}
	
	KvJumpToKey(kScavData, "info"); //Jump to info section
	new iTotalCans = KvGetNum(kScavData, "totalcans"); //Grab the value of the totalcans key
	if (iTotalCans < 16 && !g_bInEditMode) //Check that there are atleast 16 cans unless edit mode is active
	{
		PrintToChatAll("[SM] Map %s only has %d gas can spawns.", sMapName, iTotalCans); //Less than 16 cans
		return false;
	}
	
	decl String:sCanName[16];
	decl Float:vOrigin[3];
	decl Float:vAngles[3];
	new iChosenCans[16];
	new iRand = -1;
	KvGoBack(kScavData); //Go back to root section
	KvJumpToKey(kScavData, "cans"); //Jump to cans section
	
	if (g_bInEditMode) //Check if we are in edit mode
	{
		for (new i = 0; i < iTotalCans; i++) //We are in edit mode so spawn all saved gas cans
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
		PrintToChatAll("[SM] Loaded %d gas cans.", iTotalCans);
	}
	else //We arn't in edit mode so act normally
	{
		for (new i = 0; i < 16; i++) //We need 16 random values
		{
			do
			{
				iRand = GetRandomInt(0, iTotalCans-1); //Generate random number
				for (new x = 0; x < 16; x++) //Loop through all random nubers we have got so far
				{
					if (iChosenCans[x] == iRand) //Check if we have got this number before
					{
						iRand = -1; //Set to get a new random number
						break;
					}
				}
			}
			while(iRand == -1); //Keep going untill we get a random number we havn't gotten before
			
			iChosenCans[i] = iRand; //Set this number chosen
			Format(sCanName, sizeof(sCanName), "can%d", iChosenCans[i]); 
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
	CloseHandle(kScavData); //Close the keyvales structure handle
	return true;
}

//Removes all gas can entities
RemoveAllGasCans()
{
	decl String:sEntityName[64];
	new iEntityCount = GetEntityCount(); //Get Entity count
	for (new i = 0; i < iEntityCount; i++) //Iterate through all entities
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
RemoveAllGasCanSpawns()
{
	decl String:sEntityName[64];
	new iEntityCount = GetEntityCount(); //Get Entity count
	for (new i = 0; i < iEntityCount; i++) //Iterate through all entities
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
SpawnGasCans()
{
	decl String:sEntityName[64];
	new iEntityCount = GetEntityCount(); //Get Entity count
	new iSpawnCount = 0; //Prepare to count how many cans we spawn
	for (new i = 0; i < iEntityCount; i++) //Iterate through all entities
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
bool:CreateGasCan(Float:vPos[3], Float:vAng[3])
{
	new iCan = CreateEntityByName("weapon_gascan");
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
bool:CreateGasCanSpawner(Float:vPos[3], Float:vAng[3])
{
	new iCanSpawner = CreateEntityByName("weapon_scavenge_item_spawn");
	if (IsValidEdict(iCanSpawner))
	{
		DispatchSpawn(iCanSpawner);
		TeleportEntity(iCanSpawner, vPos, vAng, NULL_VECTOR);
		return true;
	}
	return false;
}

//Returns true if gamemode is scavenge
bool:IsScavenge()
{
	decl String:sGamemode[64];
	GetConVarString(g_hGamemode, sGamemode, 64);
	if (StrEqual(sGamemode, "scavenge") || StrEqual(sGamemode, "teamscavenge")) //Check if it is a scavenge game
	{
		return true; //Is scavenge
	}
	return false; //Is not scavenge
}

//Credit to Downtown1 for this function
DirectorStop()
{
	//Store currrent values
	g_iInitDirectorNoBosses = GetConVarInt(FindConVar("director_no_bosses"));
	g_iInitDirectorNoSpecials = GetConVarInt(FindConVar("director_no_specials"));
	g_iInitDirectorNoMobs = GetConVarInt(FindConVar("director_no_mobs"));
	g_iInitDirectorReadyDuration = GetConVarInt(FindConVar("director_ready_duration"));
	g_iInitDirectorCommonLimit = GetConVarInt(FindConVar("z_common_limit"));
	g_iInitDirectorMegaMobSize = GetConVarInt(FindConVar("z_mega_mob_size"));
	g_iAllBotTeam = GetConVarInt(FindConVar("sb_all_bot_team"));

	//doing director_stop on the server sets the below variables like so
	SetConVarInt(FindConVar("director_no_bosses"), 1);
	SetConVarInt(FindConVar("director_no_specials"), 1);
	SetConVarInt(FindConVar("director_no_mobs"), 1);
	SetConVarInt(FindConVar("director_ready_duration"), 0);
	SetConVarInt(FindConVar("z_common_limit"), 0);
	SetConVarInt(FindConVar("z_mega_mob_size"), 1); //why not 0? only Valve knows
	
	//empty teams of survivors dont cycle the round
	SetConVarInt(FindConVar("sb_all_bot_team"), 1);
}

//Credit to Downtown1 for this function
DirectorStart()
{
	//Restore old values
	SetConVarInt(FindConVar("director_no_bosses"), g_iInitDirectorNoBosses);
	SetConVarInt(FindConVar("director_no_specials"), g_iInitDirectorNoSpecials);
	SetConVarInt(FindConVar("director_no_mobs"), g_iInitDirectorNoMobs);
	SetConVarInt(FindConVar("director_ready_duration"), g_iInitDirectorReadyDuration);
	SetConVarInt(FindConVar("z_common_limit"), g_iInitDirectorCommonLimit);
	SetConVarInt(FindConVar("z_mega_mob_size"), g_iInitDirectorMegaMobSize);
	SetConVarInt(FindConVar("sb_all_bot_team"), g_iAllBotTeam);
}