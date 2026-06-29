//TODO:
//    trace walls

#include <sourcemod>
#include <sdktools>
#include <console>
#include <clientprefs>


#define PLUGIN_VERSION "1.1"

	

new ClientCamera[MAXPLAYERS+1];


new Handle:var_ftb; // mp_fadetoblack
new Handle:var_fpd_enable;
new Handle:var_fpd_black;
new Handle:var_fpd_stay;
new bool:ftb = false; // mp_fadetoblack
new bool:fpd_enable = true;
new fpd_black = 0;
new Float:fpd_stay = 0.0;
new bool:CL_Ragdoll[MAXPLAYERS+1];

new String:Attachment[64];


new game;
#define UNKNOWN 0
#define CSTRIKE 1
#define DODS	2
#define HL2DM	3

public Plugin:myinfo = 
{
	name = "fpd",
	author = "Eun",
	description = "first person death",
	version = PLUGIN_VERSION
};
public OnPluginStart() 
{ 
	// set the game var
	SetGameVersion();
	
	// gamespecifed settings
	if (game == CSTRIKE)
	{
		Attachment = "forward";
	}
	else if (game == DODS)
	{
		Attachment = "head";
	}
	else if (game == HL2DM)
	{
		Attachment = "eyes";
	}
	else if (game == UNKNOWN)
	{
		Attachment = "forward";
	}


	CreateConVar("fpd_version", PLUGIN_VERSION, "First Person Death", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	var_fpd_enable = CreateConVar("fpd_enable", "1", "Enable / Disable FPD", FCVAR_PLUGIN);
	var_fpd_black = CreateConVar("fpd_black", "3000", "Duration to fade to black, 0 = disables", FCVAR_PLUGIN);
	var_fpd_stay = CreateConVar("fpd_stay", "7", "Seconds to stay in ragdoll after death 0 = till round end", FCVAR_PLUGIN);
	

	// events
	HookEvent("player_death", PlayerDeath, EventHookMode_Pre);
	HookEvent("player_spawn", OnPlayerSpawn);
	
  
	// decide which mode depending on fadetoblack
	var_ftb = FindConVar("mp_fadetoblack");
	
	if (var_ftb != INVALID_HANDLE)
		ftb = GetConVarBool(var_ftb);
	else
		ftb = false;
		
	fpd_black = GetConVarInt(var_fpd_black);
		
	fpd_stay = GetConVarFloat(var_fpd_stay);

		
		
	// track changes of vars
	if (var_ftb != INVALID_HANDLE)
		HookConVarChange(var_ftb, Cvar_Changed);
	
	HookConVarChange(var_fpd_enable, Cvar_Changed);
	HookConVarChange(var_fpd_black, Cvar_Changed);
	HookConVarChange(var_fpd_stay, Cvar_Changed);
	
	RegConsoleCmd("fpd", CurrentView);
	
}

public Action:CurrentView(client, args)
{
	new Float:angles0[3];
	GetClientEyeAngles(client, angles0);
	PrintToChatAll("GetClientEyeAngles: %f %f %f", angles0[0], angles0[1], angles0[2]);
	
	new Float:angles1[3];
	GetClientAbsAngles(client, angles1); 
	PrintToChatAll("GetClientAbsAngles: %f %f %f", angles1[0], angles1[1], angles1[2]);
	
	new Float:angles2[3];
	GetEntPropVector(client, Prop_Data, "m_angAbsRotation", angles2);
	PrintToChatAll("m_angAbsRotation: %f %f %f", angles2[0], angles2[1], angles2[2]);
	
	new Float:angles3[3];
	GetEntPropVector(client, Prop_Data, "m_angRotation", angles3);
	PrintToChatAll("m_angRotation: %f %f %f", angles3[0], angles3[1], angles3[2]);
}

public OnEventShutdown()
{
	UnhookEvent("player_death", PlayerDeath);
	UnhookEvent("player_spawn", OnPlayerSpawn);
}

public Cvar_Changed(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if (convar == var_ftb)
	{
		ftb = GetConVarBool(var_ftb);
	}
	else if (convar == var_fpd_enable)
	{
		fpd_enable = GetConVarBool(var_fpd_enable);
	}
	else if (convar == var_fpd_black)
	{
		fpd_black = GetConVarInt(var_fpd_black);
	}
	
	else if (convar == var_fpd_stay)
	{
		fpd_stay = GetConVarFloat(var_fpd_stay);
	}
}





public Action:OnPlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new Client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (ClientOk(Client))
	{
		
		if (fpd_enable)
		{
			if (game == CSTRIKE)
			{
				// gsg and sas got not the attachment forward
				decl String:ModelName[128];
				GetEntPropString(Client, Prop_Data, "m_ModelName", ModelName, sizeof(ModelName));
				if (StrContains(ModelName, "ct_gsg9.mdl", false) > -1 || StrContains(ModelName, "ct_sas.mdl", false) > -1)
				{
					SetEntityModel(Client, "models/player/ct_urban.mdl");
				}
			}
			if (game == HL2DM)
			{
				CL_Ragdoll[Client] = true;
			}
			else
			{
				QueryClientConVar(Client, "cl_ragdoll_physics_enable", ConVarQueryFinished:ClientConVar, Client)
			}
		}
		
		// clear cam
		ClearCam(Client);		
	}
}

public Action:PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!fpd_enable)
	{
		return Plugin_Continue;
	}
	new Client;
	Client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (ClientOk(Client))
	{	
		if (CL_Ragdoll[Client])
		{
			new ragdoll = GetEntPropEnt(Client, Prop_Send, "m_hRagdoll");	
			if (ragdoll<0)
			{
				return Plugin_Continue;
			}
			SpawnCamAndAttach(Client, ragdoll);
		}
	}
	return Plugin_Continue;
}

public ClientConVar(QueryCookie:cookie, Client, ConVarQueryResult:result, const String:cvarName[], const String:cvarValue[])
{
	if (StringToInt(cvarValue) > 0)
		CL_Ragdoll[Client] = true;
	else
		CL_Ragdoll[Client] = false;
}


public SpawnCamAndAttach(Client, Ragdoll)
{
	// Precache model
	new String:StrModel[64];
	//Format(StrModel, sizeof(StrModel), "models/error.mdl");
	Format(StrModel, sizeof(StrModel), "models/blackout.mdl");
	PrecacheModel(StrModel, true);
	
	// Generate unique id for the client so we can set the parenting
	// through parentname.
	new String:StrName[64]; Format(StrName, sizeof(StrName), "fpd_Ragdoll%d", Client);
	DispatchKeyValue(Ragdoll, "targetname", StrName);
	
	// Spawn dynamic prop entity
	new Entity = CreateEntityByName("prop_dynamic");
	if (Entity == -1)
		return false;
	
	// Generate unique id for the entity
	new String:StrEntityName[64]; Format(StrEntityName, sizeof(StrEntityName), "fpd_RagdollCam%d", Entity);
	
	// Setup entity
	DispatchKeyValue(Entity, "targetname", StrEntityName);
	DispatchKeyValue(Entity, "parentname", StrName);
	DispatchKeyValue(Entity, "model",	  StrModel);
	DispatchKeyValue(Entity, "solid",	  "0");
	DispatchKeyValue(Entity, "rendermode", "10"); // dont render
	DispatchKeyValue(Entity, "disableshadows", "1"); // no shadows
	
	new Float:angles[3]; GetClientEyeAngles(Client, angles);
	new String:CamTargetAngles[64];
	Format(CamTargetAngles, 64, "%f %f %f", angles[0], angles[1], angles[2]);
	DispatchKeyValue(Entity, "angles", CamTargetAngles); 
	
	SetEntityModel(Entity, StrModel);
	DispatchSpawn(Entity);
		
	// Set parent
	SetVariantString(StrName);
	AcceptEntityInput(Entity, "SetParent", Entity, Entity, 0);
	
	// Set attachment
	SetVariantString(Attachment);
	AcceptEntityInput(Entity, "SetParentAttachment", Entity, Entity, 0);
	// this bricks the Angles of the Entity
	
	// Activate
	AcceptEntityInput(Entity, "TurnOn");
	
	// Set View
	SetClientViewEntity(Client, Entity);
	ClientCamera[Client] = Entity;
	
	if (!ftb)
	{
		if (fpd_stay > 0)  // stay in ragdoll for x seconds and ftb is disabled
		{
			CreateTimer(fpd_stay, ClearCamTimer, Client);	
		}
		if (fpd_black > 0)
		{
			PerformFade(Client, fpd_black, false);
		}
		//CreateTimer(1.0, ThinkTimer, Client); // Do this later
	}
	

	return true;
} 


// reset to player
public Action:ClearCamTimer(Handle:timer, any:Client)
{
	ClearCam(Client);
}

public ClearCam(any: Client)
{
	if(ClientCamera[Client] && ClientOk(Client))
	{
		if (fpd_black)
		{
			PerformFade(Client, 0, true);
		}
		SetClientViewEntity(Client, Client);
		ClientCamera[Client] = false;
	}
}


	
public ClientOk(any: Client)
{
	if (IsClientConnected(Client) && IsClientInGame(Client))
	{
		if (!IsFakeClient(Client))
		{
			if (GetClientTeam(Client) != 1)
			{	
				return true;
			}
		}
	}
	return false;
}

#define FFADE_IN		0x0001		// Just here so we don't pass 0 into the function
#define FFADE_OUT		0x0002		// Fade out (not in)
#define FFADE_MODULATE	0x0004		// Modulate (don't blend)
#define FFADE_STAYOUT	0x0008		// ignores the duration, stays faded out until new ScreenFade message received
#define FFADE_PURGE		0x0010		// Purges all other fades, replacing them with this one

public PerformFade(any: Client, duration, in)
{
	new Handle:hFadeClient=StartMessageOne("Fade", Client)
	BfWriteShort(hFadeClient,duration)	// FIXED 16 bit, with SCREENFADE_FRACBITS fractional, seconds duration
	BfWriteShort(hFadeClient,0)		// FIXED 16 bit, with SCREENFADE_FRACBITS fractional, seconds duration until reset (fade & hold)
	if (in)
	{
		BfWriteShort(hFadeClient,(FFADE_PURGE|FFADE_IN)) // fade type (in / out)
	}
	else
	{
		BfWriteShort(hFadeClient,(FFADE_PURGE|FFADE_OUT|FFADE_STAYOUT)) // fade type (in / out)
	}
	BfWriteByte(hFadeClient, 0)	// fade red
	BfWriteByte(hFadeClient, 0)	// fade green
	BfWriteByte(hFadeClient, 0)	// fade blue
	BfWriteByte(hFadeClient, 255)	// fade alpha
	EndMessage()
	return true;
}

public SetGameVersion()
{
	new String:gamestr[64];
	GetGameFolderName(gamestr, sizeof(gamestr));
	if (!strcmp(gamestr, "cstrike"))
		game = CSTRIKE;
	else if (!strcmp(gamestr, "dod"))
		game = DODS;
	else if (!strcmp(gamestr, "hl2mp"))
		game = HL2DM;
	else
		game = UNKNOWN;
}



public Action:ThinkTimer(Handle:timer, any:Client)
{
	if(ClientCamera[Client])
	{
		if (IsEntNearWall(ClientCamera[Client]))
		{
			if (fpd_black)
			{
				PerformFade(Client, 0, true);
			}
			SetClientViewEntity(Client, Client);
			ClientCamera[Client] = 0;
		}
		else
		{
			CreateTimer(1.0, ThinkTimer, Client);
		}
	}
}



stock bool:IsEntNearWall(ent)
{
	new Float:vOrigin[3], Float:vec[3], Float:vAngles[3], Handle:trace;
	GetEntPropVector(ent, Prop_Data, "m_vecAbsOrigin", vOrigin);
	GetEntPropVector(ent, Prop_Data, "m_angAbsRotation", vAngles);  // <-- This dont works, because on SetAttachment this get currupt
	PrintToChatAll("%f %f %f |  %f %f %f", vOrigin[0], vOrigin[1], vOrigin[2], vAngles[0], vAngles[1], vAngles[2] );
	trace = TR_TraceRayFilterEx(vOrigin, vAngles, MASK_PLAYERSOLID, RayType_Infinite, TraceRayDontHitSelf, ent);            
	if (TR_DidHit(trace))
	{
		TR_GetEndPosition(vec, trace);
		if (GetVectorDistance(vec, vOrigin) < 40)
		{
			CloseHandle(trace);
			return true;
		}
	}
	CloseHandle(trace);
	return false;
}

public bool:TraceRayDontHitSelf(entity, mask, any:data)
{
	if(entity == data) // Check if the TraceRay hit the itself.
	{
		return false // Don't let the entity be hit
	}
	return true // It didn't hit itself
}