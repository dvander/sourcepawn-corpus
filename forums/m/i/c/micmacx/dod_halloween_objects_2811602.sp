#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.0"

new Handle:Cvar_Plugin_Enable;
new Handle:Cvar_Num_Objects;
new Handle:Cvar_Pump_Solid;
new Handle:Cvar_Pump_Enable;
//new Handle:Cvar_Flags_Enable;
new h_entity[99];
new index_entity = 0;
new model = 0;
new bool:maxmodel = false;
new bool:h_start = false;
new bool:h_pumpk_solid = false;
new bool:h_flag_enable = false;
new bool:h_pumpk_enable = false;

public Plugin:myinfo = 
{
	name = "DoD:S Halloween Objects",
	author = "Micmacx",
	description = "Spawn Halloween Objects where player dead",
	version = PLUGIN_VERSION,
	url = "https://www.sourcemod.net/plugins.php?cat=0&mod=-1&title=&author=micmacx&description=&search=1"
}

public OnPluginStart()
{

	CreateConVar("dod_halloween_objects_version", PLUGIN_VERSION, "DoD plugin Version", FCVAR_DONTRECORD | FCVAR_NOTIFY);
	Cvar_Plugin_Enable	= CreateConVar("dod_halloween_objects_enable", "1", "0 : disable, 1 : enable Plugin", FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	Cvar_Pump_Enable	= CreateConVar("dod_Pumpk_enable", "1", "0 : disable, 1 : enable Spawn Pumpkins where dead player ", FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	Cvar_Num_Objects	= CreateConVar("dod_hal_num_obj", "20", "Maximum Number Objects in map 20 to 99", _, true, 20.0, true, 99.0);
	Cvar_Pump_Solid		= CreateConVar("dod_Pumpk_solid", "1", "0 : disable, 1 : enable Solid Pumpkins ", FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
//	Cvar_Flags_Enable	= CreateConVar("dod_flags_enable", "1", "0 : disable, 1 : enable change flags by scarecrow ", FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	AutoExecConfig(true, "dod_halloween_objects", "dod_halloween_objects");
	HookEventEx("player_death", PlayerDeath, EventHookMode_Pre)
	HookEventEx("round_start", OnRound, EventHookMode_Post)
}

public OnMapStart()
{
	h_pumpk_enable = GetConVarBool(Cvar_Pump_Enable);
	if(h_pumpk_enable)
	{
		AddFileToDownloadsTable("models/models_kit/hallo_pumpkin_l_face1.dx80.vtx")
		AddFileToDownloadsTable("models/models_kit/hallo_pumpkin_l_face1.dx90.vtx")
		AddFileToDownloadsTable("models/models_kit/hallo_pumpkin_l_face1.mdl")
		AddFileToDownloadsTable("models/models_kit/hallo_pumpkin_l_face1.phy")
		AddFileToDownloadsTable("models/models_kit/hallo_pumpkin_l_face1.sw.vtx")
		AddFileToDownloadsTable("models/models_kit/hallo_pumpkin_l_face1.vvd")
		AddFileToDownloadsTable("models/models_kit/hallo_pumpkin_l_face1.xbox.vtx")
		
		AddFileToDownloadsTable("models/props/terror/ammo_pumpk.dx90.vtx")
		AddFileToDownloadsTable("models/props/terror/ammo_pumpk.mdl")
		AddFileToDownloadsTable("models/props/terror/ammo_pumpk.vvd")

		AddFileToDownloadsTable("models/props_halloween/jackolantern_01.dx80.vtx")
		AddFileToDownloadsTable("models/props_halloween/jackolantern_01.dx90.vtx")
		AddFileToDownloadsTable("models/props_halloween/jackolantern_01.mdl")
		AddFileToDownloadsTable("models/props_halloween/jackolantern_01.phy")
		AddFileToDownloadsTable("models/props_halloween/jackolantern_01.sw.vtx")
		AddFileToDownloadsTable("models/props_halloween/jackolantern_01.vvd")
		
		AddFileToDownloadsTable("models/props_halloween/jackolantern_02.dx80.vtx")
		AddFileToDownloadsTable("models/props_halloween/jackolantern_02.dx90.vtx")
		AddFileToDownloadsTable("models/props_halloween/jackolantern_02.mdl")
		AddFileToDownloadsTable("models/props_halloween/jackolantern_02.phy")
		AddFileToDownloadsTable("models/props_halloween/jackolantern_02.sw.vtx")
		AddFileToDownloadsTable("models/props_halloween/jackolantern_02.vvd")
		
		AddFileToDownloadsTable("models/props_halloween/pumpkin_01.dx80.vtx")
		AddFileToDownloadsTable("models/props_halloween/pumpkin_01.dx90.vtx")
		AddFileToDownloadsTable("models/props_halloween/pumpkin_01.mdl")
		AddFileToDownloadsTable("models/props_halloween/pumpkin_01.phy")
		AddFileToDownloadsTable("models/props_halloween/pumpkin_01.sw.vtx")
		AddFileToDownloadsTable("models/props_halloween/pumpkin_01.vvd")
		
		AddFileToDownloadsTable("models/props_halloween/pumpkin_02.dx80.vtx")
		AddFileToDownloadsTable("models/props_halloween/pumpkin_02.dx90.vtx")
		AddFileToDownloadsTable("models/props_halloween/pumpkin_02.mdl")
		AddFileToDownloadsTable("models/props_halloween/pumpkin_02.phy")
		AddFileToDownloadsTable("models/props_halloween/pumpkin_02.sw.vtx")
		AddFileToDownloadsTable("models/props_halloween/pumpkin_02.vvd")
		
		AddFileToDownloadsTable("models/props_halloween/pumpkin_03.dx80.vtx")
		AddFileToDownloadsTable("models/props_halloween/pumpkin_03.dx90.vtx")
		AddFileToDownloadsTable("models/props_halloween/pumpkin_03.mdl")
		AddFileToDownloadsTable("models/props_halloween/pumpkin_03.phy")
		AddFileToDownloadsTable("models/props_halloween/pumpkin_03.sw.vtx")
		AddFileToDownloadsTable("models/props_halloween/pumpkin_03.vvd")

		AddFileToDownloadsTable("materials/models/greenhood/ammo/ammostack.vmt")
		AddFileToDownloadsTable("materials/models/greenhood/ammo/ammostack.vtf")
		AddFileToDownloadsTable("materials/models/greenhood/ammo/colors.vmt")
		AddFileToDownloadsTable("materials/models/greenhood/ammo/colors.vtf")
		AddFileToDownloadsTable("materials/models/greenhood/ammo/detail.vtf")
		AddFileToDownloadsTable("materials/models/greenhood/ammo/jack_evil_diffuse.vmt")
		AddFileToDownloadsTable("materials/models/greenhood/ammo/jack_evil_diffuse.vtf")

		AddFileToDownloadsTable("materials/models/props_halloween/pumpkin.vmt")
		AddFileToDownloadsTable("materials/models/props_halloween/pumpkin.vtf")
		AddFileToDownloadsTable("materials/models/props_halloween/pumpkin_detail.vmt")
		AddFileToDownloadsTable("materials/models/props_halloween/pumpkin_detail.vtf")
		AddFileToDownloadsTable("materials/models/props_halloween/pumpkin_dx80.vmt")

		AddFileToDownloadsTable("materials/models/models_kit/hallo_pumpkin.vmt")
		AddFileToDownloadsTable("materials/models/models_kit/hallo_pumpkin.vtf")
		AddFileToDownloadsTable("materials/models/models_kit/hallo_pumpkin_dim.vmt")
		AddFileToDownloadsTable("materials/models/models_kit/hallo_pumpkin_dim.vtf")
		AddFileToDownloadsTable("materials/models/models_kit/hallo_pumpkin_lit.vmt")
		AddFileToDownloadsTable("materials/models/models_kit/hallo_pumpkin_lit.vtf")
		AddFileToDownloadsTable("materials/models/models_kit/hallo_pumpkin_skin2.vmt")
		AddFileToDownloadsTable("materials/models/models_kit/hallo_pumpkin_skin2.vtf")

		PrecacheModel("models/props/terror/ammo_pumpk.mdl")
		PrecacheModel("models/props_halloween/jackolantern_01.mdl")
		PrecacheModel("models/props_halloween/jackolantern_02.mdl")
		PrecacheModel("models/props_halloween/pumpkin_01.mdl")
		PrecacheModel("models/props_halloween/pumpkin_02.mdl")
		PrecacheModel("models/props_halloween/pumpkin_03.mdl")
		PrecacheModel("models/models_kit/hallo_pumpkin_l_face1.mdl")
	}

	h_flag_enable = false;
	if(h_flag_enable)
	{
		AddFileToDownloadsTable("models/models_kit/hallo_scarecrow.dx80.vtx")
		AddFileToDownloadsTable("models/models_kit/hallo_scarecrow.dx90.vtx")
		AddFileToDownloadsTable("models/models_kit/hallo_scarecrow.mdl")
		AddFileToDownloadsTable("models/models_kit/hallo_scarecrow.phy")
		AddFileToDownloadsTable("models/models_kit/hallo_scarecrow.sw.vtx")
		AddFileToDownloadsTable("models/models_kit/hallo_scarecrow.vvd")
		AddFileToDownloadsTable("models/models_kit/hallo_scarecrow.xbox.vtx")

		AddFileToDownloadsTable("models/models_kit/hallo_scarecrow_noir.dx80.vtx")
		AddFileToDownloadsTable("models/models_kit/hallo_scarecrow_noir.dx90.vtx")
		AddFileToDownloadsTable("models/models_kit/hallo_scarecrow_noir.mdl")
		AddFileToDownloadsTable("models/models_kit/hallo_scarecrow_noir.phy")
		AddFileToDownloadsTable("models/models_kit/hallo_scarecrow_noir.sw.vtx")
		AddFileToDownloadsTable("models/models_kit/hallo_scarecrow_noir.vvd")
		AddFileToDownloadsTable("models/models_kit/hallo_scarecrow_noir.xbox.vtx")

		AddFileToDownloadsTable("materials/models/models_kit/hallo_scarecrow.vmt")
		AddFileToDownloadsTable("materials/models/models_kit/hallo_scarecrow.vtf")
		AddFileToDownloadsTable("materials/models/models_kit/hallo_scarecrow_skin2.vmt")
		AddFileToDownloadsTable("materials/models/models_kit/hallo_scarecrow_skin2.vtf")
		AddFileToDownloadsTable("materials/models/models_kit/hallo_scarecrow_skin3.vmt")
		AddFileToDownloadsTable("materials/models/models_kit/hallo_scarecrow_skin3.vtf")
		AddFileToDownloadsTable("materials/models/models_kit/hallo_scarecrow_skin4.vmt")
		AddFileToDownloadsTable("materials/models/models_kit/hallo_scarecrow_skin4.vtf")
		PrecacheModel("models/models_kit/hallo_scarecrow.mdl")
		PrecacheModel("models/models_kit/hallo_scarecrow_noir.mdl")
	}
}

public Action:TimerStart(Handle:timer) 
{
	h_start = true;
}

public OnClientAuthorized(client, const String:auth[])
{

	QueryClientConVar(client, "cl_downloadfilter", ConVarQueryFinished:dlfilter);

}

public dlfilter(QueryCookie:cookie, client, ConVarQueryResult:result, const String:cvarName1[], const String:cvarValue1[])
{
	if(h_start && IsClientConnected(client))
	{
		if(strcmp(cvarValue1, "none", true) == 0)
		{
			if(GetConVarInt(Cvar_Plugin_Enable) == 1)
			{
				KickClient(client, "Please enable the option for skins - Allow custom files or nosounds - in Day of defeat:source-->options-->Multiplayer");
			}
		}
		if(strcmp(cvarValue1, "mapsonly", true) == 0)
		{
			if(GetConVarInt(Cvar_Plugin_Enable) == 1)
			{
				KickClient(client, "Please enable the option for skins - Allow custom files or nosounds - in Day of defeat:source-->options-->Multiplayer");
			}
		}
	}
}

public Action:OnRound(Handle:event, const String:name[], bool:dontBroadcast)
{
	h_start = false
	index_entity = 0
	maxmodel = false
	model = 0
	index_entity = 0
	h_pumpk_solid = GetConVarBool(Cvar_Pump_Solid)
	CreateTimer(15.0, TimerStart, _, TIMER_FLAG_NO_MAPCHANGE)
	new entity;
	while ((entity = FindEntityByClassname(entity, "dod_control_point")) != -1)
	{
		if(IsValidEntity(entity))
		{
			if(h_flag_enable)
			{
				DispatchKeyValue(entity, "point_allies_model", "models/models_kit/hallo_scarecrow.mdl");
				DispatchKeyValue(entity, "point_axis_model", "models/models_kit/hallo_scarecrow_noir.mdl");
				DispatchKeyValue(entity, "point_reset_model", "models/models_kit/hallo_scarecrow_blanc.mdl");
			}

			new Float:Origin[3]
			GetEntPropVector(entity, Prop_Send, "m_vecOrigin", Origin)
			new Float: h_buffer2 = Origin[2]-30.0
			Origin[2] = h_buffer2
			SetEntPropVector(entity, Prop_Send, "m_vecOrigin", Origin)
			SetEntPropFloat(entity, Prop_Send, "m_flModelScale", 1.3);
		}
	}
}

public PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (GetConVarBool(Cvar_Plugin_Enable) && h_start && h_pumpk_enable)
	{
		new client = GetClientOfUserId(GetEventInt(event, "userid"));
		if (IsValidClient(client))
		{
			if(model > 6) 
			{
				model = 0
			}
			if(index_entity > (GetConVarInt(Cvar_Num_Objects)-1)) 
			{
				index_entity = 0
				maxmodel = true
			}
			new Float:h_Origin[3]
			new Float:h_Angles[3]
			h_Angles = Float:{ 0.0, 0.0, 0.0 };
			GetClientAbsOrigin(client, h_Origin)


			new verif = 0
			for (new x = 1; x <= MaxClients; x++)
			{
				if(IsValidClient(x) && x != client && IsPlayerAlive(x))
				{
					new Float:buffer_Origin[3]
					new Float:buffer_Distance
					GetClientAbsOrigin(x, buffer_Origin)
					buffer_Distance = GetVectorDistance(h_Origin, buffer_Origin);
					if(buffer_Distance<100.0)
					{
						verif++
					}
				}
			}

			if(verif == 0)
			{
				if(!maxmodel)
				{
					SpawnObject(h_Origin, h_Angles)
					// PrintToChatAll("Spawn")
				}
				else
				{
					if(IsValidEntity(h_entity[index_entity]))
					{				
						Teleport(h_Origin, h_Angles)
						// PrintToChatAll("Téléport")
					}
					else
					{
						SpawnObject(h_Origin, h_Angles)
						// PrintToChatAll("Téléport puis Spawn")
					}
				}
			}
		}
	}
}

public SpawnObject(Float:Origin[3], Float:Angles[3])
{
	h_entity[index_entity] = CreateEntityByName("prop_dynamic_override");
	if (h_entity[index_entity] != -1)
	{
		if(model == 0) 
		{
			SetEntityModel(h_entity[index_entity], "models/props/terror/ammo_pumpk.mdl")
			SetEntPropFloat(h_entity[index_entity], Prop_Send, "m_flModelScale", 1.4);
		}
		if(model == 1) 
		{
			SetEntityModel(h_entity[index_entity], "models/props_halloween/jackolantern_01.mdl")
		}
		if(model == 2) 
		{
			SetEntityModel(h_entity[index_entity], "models/props_halloween/jackolantern_02.mdl")
		}
		if(model == 3) 
		{
			SetEntityModel(h_entity[index_entity], "models/props_halloween/pumpkin_01.mdl")
		}
		if(model == 4) 
		{
			SetEntityModel(h_entity[index_entity], "models/props_halloween/pumpkin_02.mdl")
		}
		if(model == 5) 
		{
			SetEntityModel(h_entity[index_entity], "models/models_kit/hallo_pumpkin_l_face1.mdl")
		}
		if(model == 6) 
		{
			SetEntityModel(h_entity[index_entity], "models/props_halloween/pumpkin_03.mdl")
		}
		if (h_pumpk_solid)
		{
			DispatchKeyValue(h_entity[index_entity], "solid", "6");
		}
		DispatchSpawn(h_entity[index_entity])
		Angles[1] = GetRandomFloat(0.0, 359.0)
		new Float: h_buffer1 = Origin[2]-58.0
		Origin[2] = h_buffer1
		TeleportEntity(h_entity[index_entity], Origin, Angles, Origin);
		if (IsValidEntity(h_entity[index_entity]))
		{
			index_entity++
			model++
		}
	}
}



public Teleport(Float:Origin[3], Float:Angles[3])
{
	if (IsValidEntity(h_entity[index_entity]))
	{
		Angles[1] = GetRandomFloat(0.0, 359.0)
		new Float: h_buffer4 = Origin[2]-57.0
		Origin[2] = h_buffer4
		new Float:h_velocity[3]
		h_velocity = Float:{ 1.0, 1.0, 1.0 };
		TeleportEntity(h_entity[index_entity], Origin, Angles, h_velocity);
		index_entity++
	}
}

public Action:ChangeObject(Float:Origin[3], String:Angles[])
{
	new entity;
	while ((entity = FindEntityByClassname(entity, "prop_dynamic")) != -1)
	{
		GetEntPropVector(entity, Prop_Send, "m_vecOrigin", Origin)
		if(Origin[0] == 6 && Origin[1] == -506 && Origin[2] == -99)
		{
			DispatchKeyValue(entity, "origin", "6 -506 -400");
		}
	}
}

bool IsValidClient(int client)
{
	if (client > 0 && client <= MaxClients && IsClientInGame(client)){
		return true;
	}else{
		return false;
	}
}
