// gives you clusterbombs!

#include <sourcemod>
#include <sdktools>

#pragma semicolon 1

// constants
#define PLUGIN_VERSION	 "1.0"

// cvars
new Handle:sm_cbomb_enabled			= INVALID_HANDLE;
new Handle:sm_cbomb_enabled_plr			= INVALID_HANDLE;
new Handle:sm_cbomb_wait_time_plr		= INVALID_HANDLE;
new Handle:sm_cbomb_wait_time_admin		= INVALID_HANDLE;
new Handle:sm_cbomb_throwspeed			= INVALID_HANDLE;
new Handle:sm_cbomb_detonation_delay		= INVALID_HANDLE;
new Handle:sm_cbomb_bomblet_count		= INVALID_HANDLE;
new Handle:sm_cbomb_bomblet_vertvel		= INVALID_HANDLE;
new Handle:sm_cbomb_bomblet_spreadvel		= INVALID_HANDLE;
new Handle:sm_cbomb_bomblet_variation		= INVALID_HANDLE;
new Handle:sm_cbomb_bomblet_magnitude		= INVALID_HANDLE;
new Handle:sm_cbomb_canister_model		= INVALID_HANDLE;
new Handle:sm_cbomb_bomblet_model		= INVALID_HANDLE;
new Handle:sm_cbomb_detonation_sound		= INVALID_HANDLE;

// cvar values
new bool:enabled;
new bool:enabled_plr;
new waitTime_plr;
new waitTime_admin;
new Float:throwSpeed;
new Float:detonationDelay;
new bombletCount;
new Float:bombletVertVel;
new Float:bombletSpreadVel;
new Float:bombletVariation;
new bombletMagnitude;
new String:canisterModel[255];
new String:bombletModel[255];
new String:detonationSound[255];

// clusterbomb wait times
new nextClusterBombTime[MAXPLAYERS+1];

public Plugin:myinfo =
{
	name = "WiLdTuRkEy\'s ClusterBomb Plugin",
	author = "[DMT]WiLdTuRkEy!",
	description = "Tweakable clusterbombs for players and/or admins",
	version = PLUGIN_VERSION,
	url = "http://www.deadmeatstavern.com"
};

public OnPluginStart()
{
	//register player commands
	RegConsoleCmd("sm_cb", Command_ClusterBomb, "Toss a clusterbomb in the direction you are aiming!");
	RegConsoleCmd("sm_cbomb", Command_ClusterBomb, "Toss a clusterbomb in the direction you are aiming!");
	RegConsoleCmd("sm_clusterbomb", Command_ClusterBomb, "Toss a clusterbomb in the direction you are aiming!");

	sm_cbomb_enabled = CreateConVar("sm_cbomb_enabled", "1", "Is the clusterbomb feature enabled? (0|1)", FCVAR_NONE, true, 0.0, true, 1.0);
	sm_cbomb_enabled_plr = CreateConVar("sm_cbomb_enabled_plr", "1", "Can non-admins use clusterbombs? (0|1)", FCVAR_NONE, true, 0.0, true, 1.0);
	sm_cbomb_wait_time_plr = CreateConVar("sm_cbomb_wait_time_plr", "30", "How many seconds non-admins must wait between clusterbombs. (1 - 600)", FCVAR_NONE, true, 1.0, true, 600.0);
	sm_cbomb_wait_time_admin = CreateConVar("sm_cbomb_wait_time_admin", "5", "How many seconds admins must wait between clusterbombs. (1 - 600)", FCVAR_NONE, true, 1.0, true, 600.0);
	sm_cbomb_throwspeed = CreateConVar("sm_cbomb_throwspeed", "500.0", "How fast you throw the clusterbombs away from you. (0.0 - 2000.0)", FCVAR_NONE, true, 0.0, true, 2000.0);
	sm_cbomb_detonation_delay = CreateConVar("sm_cbomb_detonation_delay", "2.5", "Clusterbomb will detonate this many seconds after throwing it. (1.0 - 5.0)", FCVAR_NONE, true, 1.0, true, 5.0);
	sm_cbomb_bomblet_count = CreateConVar("sm_cbomb_bomblet_count", "10", "How many bomblets does each clusterbomb contain? (2 - 30)", FCVAR_NONE, true, 2.0, true, 30.0);
	sm_cbomb_bomblet_vertvel = CreateConVar("sm_cbomb_bomblet_vertvel", "90.0", "How fast bomblets are thrown in the air when spawned. (20.0 - 500.0)", FCVAR_NONE, true, 20.0, true, 1500.0);
	sm_cbomb_bomblet_spreadvel = CreateConVar("sm_cbomb_bomblet_spreadvel", "50.0", "How fast bomblets spread out after they are spawned. (20.0 - 500.0)", FCVAR_NONE, true, 20.0, true, 1500.0);
	sm_cbomb_bomblet_variation = CreateConVar("sm_cbomb_bomblet_variation", "2.0", "Vertical and spread speeds will be varied between 1X and this value. (1.0 - 5.0)", FCVAR_NONE, true, 1.0, true, 5.0);
	sm_cbomb_bomblet_magnitude = CreateConVar("sm_cbomb_bomblet_magnitude", "120", "Damage magnitude of each bomblet. 100 is about like a normal grenade. (0 - 500)", FCVAR_NONE, true, 0.0, true, 500.0);
	sm_cbomb_canister_model = CreateConVar("sm_cbomb_canister_model", "models/props_junk/PropaneCanister001a.mdl", "The model that holds all of the bomblets in it.", FCVAR_NONE);
	sm_cbomb_bomblet_model = CreateConVar("sm_cbomb_bomblet_model", "models/Weapons/w_grenade.mdl", "The model that represents the individual bomblets.", FCVAR_NONE);
	sm_cbomb_detonation_sound = CreateConVar("sm_cbomb_detonation_sound", "ambient/machines/slicer3.wav", "The sound made when the clusters are spawned.", FCVAR_NONE);
	
	CreateConVar("sm_cbomb_version", PLUGIN_VERSION, "WiLdTuRkEy\'s ClusterBomb Plugin: Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	
	//set up local cvar values
	enabled = GetConVarBool(sm_cbomb_enabled);
	enabled_plr = GetConVarBool(sm_cbomb_enabled_plr);
	waitTime_plr = GetConVarInt(sm_cbomb_wait_time_plr);
	waitTime_admin = GetConVarInt(sm_cbomb_wait_time_admin);
	throwSpeed = GetConVarFloat(sm_cbomb_throwspeed);
	detonationDelay = GetConVarFloat(sm_cbomb_detonation_delay);
	bombletCount = GetConVarInt(sm_cbomb_bomblet_count);
	bombletVertVel = GetConVarFloat(sm_cbomb_bomblet_vertvel);
	bombletSpreadVel = GetConVarFloat(sm_cbomb_bomblet_spreadvel);
	bombletVariation = GetConVarFloat(sm_cbomb_bomblet_variation);
	bombletMagnitude = GetConVarInt(sm_cbomb_bomblet_magnitude);
	GetConVarString(sm_cbomb_canister_model, canisterModel, sizeof(canisterModel));
	GetConVarString(sm_cbomb_bomblet_model, bombletModel, sizeof(bombletModel));
	GetConVarString(sm_cbomb_detonation_sound, detonationSound, sizeof(detonationSound));
	
	//hook cvar changes
	HookConVarChange(sm_cbomb_enabled, CvarChanged);
	HookConVarChange(sm_cbomb_enabled_plr, CvarChanged);
	HookConVarChange(sm_cbomb_wait_time_plr, CvarChanged);
	HookConVarChange(sm_cbomb_wait_time_admin, CvarChanged);
	HookConVarChange(sm_cbomb_throwspeed, CvarChanged);
	HookConVarChange(sm_cbomb_detonation_delay, CvarChanged);
	HookConVarChange(sm_cbomb_bomblet_count, CvarChanged);
	HookConVarChange(sm_cbomb_bomblet_vertvel, CvarChanged);
	HookConVarChange(sm_cbomb_bomblet_spreadvel, CvarChanged);
	HookConVarChange(sm_cbomb_bomblet_variation, CvarChanged);
	HookConVarChange(sm_cbomb_bomblet_magnitude, CvarChanged);
	HookConVarChange(sm_cbomb_canister_model, CvarChanged);
	HookConVarChange(sm_cbomb_bomblet_model, CvarChanged);
	HookConVarChange(sm_cbomb_detonation_sound, CvarChanged);
	
	AutoExecConfig(true, "sm_cbomb");
}

public CvarChanged(Handle:cvar, const String:oldVal[], const String:newVal[]) 
{
	if (cvar == sm_cbomb_enabled)
	{
		if (StrEqual(newVal, "0"))
			enabled = false;
		else
			enabled = true;
	}
	else if (cvar == sm_cbomb_enabled_plr)
	{
		if (StrEqual(newVal, "0"))
			enabled_plr = false;
		else
			enabled_plr = true;
	}
	else if (cvar == sm_cbomb_wait_time_plr)
		waitTime_plr = StringToInt(newVal);
	else if (cvar == sm_cbomb_wait_time_admin)
		waitTime_admin = StringToInt(newVal);
	else if (cvar == sm_cbomb_throwspeed)
		throwSpeed = StringToFloat(newVal);
	else if (cvar == sm_cbomb_detonation_delay)
		detonationDelay = StringToFloat(newVal);
	else if (cvar == sm_cbomb_bomblet_count)
		bombletCount = StringToInt(newVal);
	else if (cvar == sm_cbomb_bomblet_vertvel)
		bombletVertVel = StringToFloat(newVal);
	else if (cvar == sm_cbomb_bomblet_spreadvel)
		bombletSpreadVel = StringToFloat(newVal);
	else if (cvar == sm_cbomb_bomblet_variation)
		bombletVariation = StringToFloat(newVal);
	else if (cvar == sm_cbomb_bomblet_magnitude)
		bombletMagnitude = StringToInt(newVal);
	else if (cvar == sm_cbomb_canister_model)
	{	
		Format(canisterModel, sizeof(canisterModel), "%s", newVal);
		PrecacheModel(canisterModel);
	}
	else if (cvar == sm_cbomb_bomblet_model)
	{	
		Format(bombletModel, sizeof(bombletModel), "%s", newVal);
		PrecacheModel(bombletModel);
	}
	else if (cvar == sm_cbomb_detonation_sound)
	{	
		Format(detonationSound, sizeof(detonationSound), "%s", newVal);
		PrecacheSound(detonationSound);
	}
}

public OnMapStart()
{
	for (new i = 1; i <= MaxClients; i++)
	{
		nextClusterBombTime[i] = 0;
	}
	
	//precache sound and models
	PrecacheSound(detonationSound);
	PrecacheModel(canisterModel);
	PrecacheModel(bombletModel);
}

public OnClientPostAdminCheck(client)
{
	if(IsClientHere(client))
	{
		nextClusterBombTime[client] = 0;
	}
}

public Action:Command_ClusterBomb(client, args)
{
	if (IsClientAlive(client))
	{
		//admin check and stuff
		new bool:isAdmin = GetAdminFlag(GetUserAdmin(client), Admin_Generic);
		if (enabled && (enabled_plr || isAdmin))
		{
			//make sure we waited long enough before tossing another one
			new nextTime = nextClusterBombTime[client] - GetTime();
			if (nextTime <= 0)
			{				
				//make sure we are not gonna crash the map!
				if (GetMaxEntities() - GetEntityCount() < 200)
				{
					PrintToChat(client, "[SM] There is too much stuff going on in this map already! Denied!");
					return Plugin_Handled;
				}

				//get the player position and angles
				decl Float:pos[3];
				decl Float:ePos[3];
				decl Float:angs[3];
				decl Float:vecs[3];			
				GetClientEyePosition(client, pos);
				GetClientEyeAngles(client, angs);
				GetAngleVectors(angs, vecs, NULL_VECTOR, NULL_VECTOR);
				
				//make sure we are not right in front of a wall or something..
				new Handle:trace = TR_TraceRayFilterEx(pos, angs, MASK_SHOT, RayType_Infinite, TraceEntityFilterPlayer);
				if(TR_DidHit(trace))
				{
					TR_GetEndPosition(ePos, trace);
					if (GetVectorDistance(ePos, pos, false) < 45.0)
					{
						//nope...
						PrintToChat(client, "[SM] You are too close to a wall or something to do that...");
						return Plugin_Handled;
					}
				}
				CloseHandle(trace);			
				
				//set position of throw position in front of you.
				pos[0] += vecs[0] * 32.0;
				pos[1] += vecs[1] * 32.0;
				
				//set up the throw speed
				ScaleVector(vecs, throwSpeed);

				new ent = CreateEntityByName("prop_physics_override");

				if(IsValidEntity(ent))
				{					
					DispatchKeyValue(ent, "model", canisterModel);
					DispatchKeyValue(ent, "solid", "6");
					DispatchKeyValue(ent, "renderfx", "0");
					DispatchKeyValue(ent, "rendercolor", "255 255 255");
					DispatchKeyValue(ent, "renderamt", "255");					
					SetEntPropEnt(ent, Prop_Data, "m_hOwnerEntity", client);
					DispatchSpawn(ent);
					TeleportEntity(ent, pos, NULL_VECTOR, vecs);

					CreateTimer(detonationDelay, SpawnClusters, ent);

					if (isAdmin)
					{
						nextClusterBombTime[client] = GetTime() + waitTime_admin;
					}
					else
					{
						nextClusterBombTime[client] = GetTime() + waitTime_plr;
					}
				}
				else
				{
					PrintToChat(client, "[SM] Could not create clusterbomb for some odd reason! :(");
				}
			}
			else
			{
				if (nextTime > 1)
				{
					PrintToChat(client, "[SM] You must wait %d more seconds..", nextTime);
				}
				else if (nextTime == 1)
				{
					PrintToChat(client, "[SM] You must wait 1 more second..");
				}
			}
		}
		else
		{
			PrintToChat(client, "[SM] This feature is not enabled...");
		}
	}
	else if (IsClientHere(client))
	{
		PrintToChat(client, "[SM] You must be alive to do that...");
	}
	return Plugin_Handled;
}

public Action:SpawnClusters(Handle:timer, any:ent)
{
	if (IsValidEntity(ent))
	{
		decl Float:pos[3];
		GetEntPropVector(ent, Prop_Data, "m_vecOrigin", pos);
		
		EmitAmbientSound(detonationSound, pos, SOUND_FROM_WORLD, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL, 100, 0.0);
		
		//get the owner of the bomb
		new client = GetEntPropEnt(ent, Prop_Data, "m_hOwnerEntity");
		
		//kill the parent
		AcceptEntityInput(ent, "Kill");
		
		decl Float:ang[3];
		
		//spawn some babies
		for (new i = 0; i < bombletCount; i++)
		{
			//create random direction to shoot out
			ang[0] = ((GetURandomFloat() + 0.1) * bombletSpreadVel - bombletSpreadVel / 2.0) * ((GetURandomFloat() + 0.1) * bombletVariation);
			ang[1] = ((GetURandomFloat() + 0.1) * bombletSpreadVel - bombletSpreadVel / 2.0) * ((GetURandomFloat() + 0.1) * bombletVariation);
			ang[2] = ((GetURandomFloat() + 0.1) * bombletVertVel) * ((GetURandomFloat() + 0.1) * bombletVariation);

			new ent2 = CreateEntityByName("prop_physics_override");

			if(ent2 != -1)
			{					
				DispatchKeyValue(ent2, "model", bombletModel);
				DispatchKeyValue(ent2, "solid", "6");
				DispatchKeyValue(ent2, "renderfx", "0");
				DispatchKeyValue(ent2, "rendercolor", "255 255 255");
				DispatchKeyValue(ent2, "renderamt", "255");
				SetEntPropEnt(ent2, Prop_Data, "m_hOwnerEntity", client);
				DispatchSpawn(ent2);
				TeleportEntity(ent2, pos, NULL_VECTOR, ang);

				CreateTimer((GetURandomFloat() + 0.1) / 2.0 + 0.5, ExplodeBomblet, ent2, TIMER_FLAG_NO_MAPCHANGE);
			}			
		}
	
	}
}

public Action:ExplodeBomblet(Handle:timer, any:ent)
{
	if (IsValidEntity(ent))
	{
		decl Float:pos[3];
		GetEntPropVector(ent, Prop_Data, "m_vecOrigin", pos);
		
		//raise it up just a bit
		pos[2] += 32.0;

		//get the owner of the bomb
		new client = GetEntPropEnt(ent, Prop_Data, "m_hOwnerEntity");
		new team = GetEntProp(client, Prop_Send, "m_iTeamNum");
		
		//kill the parent
		AcceptEntityInput(ent, "Kill");
		
		new explosion = CreateEntityByName("env_explosion");
		if (explosion != -1)
		{
			decl String:tMag[8];
			IntToString(bombletMagnitude, tMag, sizeof(tMag));
			DispatchKeyValue(explosion, "iMagnitude", tMag);
			DispatchKeyValue(explosion, "spawnflags", "0");
			DispatchKeyValue(explosion, "rendermode", "5");
			SetEntProp(explosion, Prop_Send, "m_iTeamNum", team);
			SetEntPropEnt(explosion, Prop_Data, "m_hOwnerEntity", client);
			DispatchSpawn(explosion);
			ActivateEntity(explosion);

			TeleportEntity(explosion, pos, NULL_VECTOR, NULL_VECTOR);				
			AcceptEntityInput(explosion, "Explode");
			AcceptEntityInput(explosion, "Kill");
		}		
	}
}

public bool:TraceEntityFilterPlayer(entity, contentsMask)
{
	return entity > MaxClients || !entity;
}

public bool:IsClientHere(client)
{
	if (client > 0)
	{
		if (IsClientConnected(client))
		{
			if (!IsFakeClient(client))
			{
				if (IsClientInGame(client))
				{
					return true;
				}
			}
		}
	}
	return false;
}

public bool:IsClientAlive(client)
{
	if (client > 0)
	{
		if (IsClientConnected(client))
		{
			if (!IsFakeClient(client))
			{
				if (IsClientInGame(client))
				{
					if (IsPlayerAlive(client))
					{
						return true;
					}
				}
			}
		}
	}
	return false;   
}