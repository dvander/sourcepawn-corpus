#include <sourcemod>
#include <sdktools>

#define VERSION "1.0" 

new iLastMinigunIndex = 0;

public Plugin:myinfo = 
{
	name = "[L4D] Spawn Minigun",
	author = "4nt1h4cker",
	description = "Spawn a Minigun where ever you want.",
	version = VERSION,
	url = ""
};


public OnPluginStart()
{
	RegAdminCmd ("sm_minigunspawn", SpawnMiniGun, FCVAR_CHEAT);
	//RegAdminCmd ("sm_minigunlist", MiniGunList, FCVAR_CHEAT);
	RegAdminCmd ("sm_minigunrotate", MiniGunRotate, FCVAR_CHEAT, "sm_minigunrotate <Entity ID|-1|-2> <Degree>");
	RegAdminCmd ("sm_minigundelete", MiniGunDelete, FCVAR_CHEAT, "sm_minigundelete <Entity ID|-1|-2>");
	CreateConVar("sm_spawnminigun_version", VERSION, "Spawn a Minigun where ever you want.", FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
}

public OnMapStart()
{
	PrecacheModel("models/w_models/weapons/w_minigun.mdl", true);
	iLastMinigunIndex = 0;
}

public Action:MiniGunRotate(client, args)
{
	if (args < 2)
	{
		ReplyToCommand(client, "[SM] Usage: sm_minigunrotate <Entity ID|-1|-2> <Degree>");
	}
	
	new String:arg1[10], String:arg2[10], String:Classname[128], index, Float:degree, Float:VecAngles[3];
	
	GetCmdArg(1, arg1, sizeof(arg1))
	GetCmdArg(2, arg2, sizeof(arg2))
	index = StringToInt (arg1);
	
	if (index == -1)
	{
		index = GetClientAimTarget (client, false);
		if (index == -1)
		{
			ReplyToCommand (client, "[SM] You are not looking at any entity");
			return Plugin_Handled;
		}
	}
	else if (index == -2)
	{
		if (iLastMinigunIndex == 0)
		{
			ReplyToCommand (client, "[SM] You didnt spawn a minigun yet");
			return Plugin_Handled;
		}
		index = iLastMinigunIndex;
	}
	
	degree = StringToFloat (arg2);
	
	if (!IsValidEntity (index)){
		ReplyToCommand (client, "[SM] %i is not an valid entity", index);
		return Plugin_Handled;
	}
	GetEdictClassname(index, Classname, sizeof(Classname));
	if(!StrEqual(Classname, "prop_minigun"))
	{
		ReplyToCommand (client, "[SM] Entity %i is not a minigun", index);
		return Plugin_Handled;		
	}
	
	VecAngles[0] = 0.0;
	VecAngles[1] = DegToRad(degree);
	VecAngles[2] = 0.0;
	DispatchKeyValueVector(index, "Angles", VecAngles);
	
	return Plugin_Handled;
}

public Action:SpawnMiniGun(client, args)
{

	if( !client )
	{
		ReplyToCommand(client, "[SM] Cannot create a minigun over rcon/server console");
		return Plugin_Handled;	
	}
	
	decl Float:VecOrigin[3], Float:VecAngles[3], Float:VecDirection[3];
	
	new index = CreateEntityByName ( "prop_minigun");
	
	if (index == -1)
	{
		ReplyToCommand(client, "[SM] Failed to create minigun!");
		return Plugin_Handled;
	}
	
	DispatchKeyValue(index, "model", "Minigun_1");
	SetEntityModel (index, "models/w_models/weapons/w_minigun.mdl")
	DispatchKeyValueFloat (index, "MaxPitch", 360.00);
	DispatchKeyValueFloat (index, "MinPitch", -360.00);
	DispatchKeyValueFloat (index, "MaxYaw", 90.00);
	DispatchSpawn(index);
	

	GetClientAbsOrigin(client, VecOrigin);
	GetClientEyeAngles(client, VecAngles);
	GetAngleVectors(VecAngles, VecDirection, NULL_VECTOR, NULL_VECTOR);
	VecOrigin[0] += VecDirection[0] * 32;
	VecOrigin[1] += VecDirection[1] * 32;
	VecOrigin[2] += VecDirection[2] * 1;   
	VecAngles[0] = 0.0;
	VecAngles[2] = 0.0;
	DispatchKeyValueVector(index, "Angles", VecAngles);
	DispatchSpawn(index);
	TeleportEntity(index, VecOrigin, NULL_VECTOR, NULL_VECTOR);
	
	ReplyToCommand (client, "[SM] Credted Minigun with Index %i at Position: %i,%i,%i", index, VecOrigin[0], VecOrigin[1], VecOrigin[2]);
	iLastMinigunIndex = index;
	
	return Plugin_Handled;
}

/*
public Action:MiniGunList(client, args)
{
	
	ReplyToCommand (client, "[SM] List of Minigun entities and positions was written to your console");
	PrintToConsole (client, " == Miniguns: ==");
	
	new max_entities = GetMaxEntities();
	new Float:VecOrigin[3];
	
	for (new i = 0; i < max_entities; i++)
	{	
		if (IsValidEntity (i))
		{
			new String:Classname[128];
			GetEdictClassname(i, Classname, sizeof(Classname));
			if(StrEqual(Classname, "prop_minigun"))
			{	
				GetEntPropVector (i, Prop_Data, "m_vecOrigin", VecOrigin)
				PrintToConsole (client, "Entity ID: %i Postition: %i,%i,%i", i, VecOrigin[0], VecOrigin[1], VecOrigin[2]);
			}
		}
	}
	
	return Plugin_Handled;
}*/

public Action:MiniGunDelete(client, args)
{
	if (args < 1)
	{
		ReplyToCommand (client, "[SM] Usage: sm_minigundelete <Entity ID|-1|-2>");
	}
	
	new String:arg1[10], String:Classname[128];
	new index;
	GetCmdArg(1, arg1, sizeof(arg1))
	index = StringToInt (arg1);
	
	if (index == -1)
	{
		index = GetClientAimTarget (client, false);
		if (index == -1)
		{
			ReplyToCommand (client, "[SM] You are not looking at any entity");
			return Plugin_Handled;
		}
	}
	else if (index == -2)
	{
		if (iLastMinigunIndex == 0)
		{
			ReplyToCommand (client, "[SM] You didnt spawn a minigun yet");
			return Plugin_Handled;
		}
		index = iLastMinigunIndex;
	}
	
	if (!IsValidEntity (index)){
		ReplyToCommand (client, "[SM] %i is not an valid entity", index);
		return Plugin_Handled;
	}
	GetEdictClassname(index, Classname, sizeof(Classname));
	if(!StrEqual(Classname, "prop_minigun"))
	{
		ReplyToCommand (client, "[SM] Entity %i is not a minigun", index);
		return Plugin_Handled;		
	}
	
	RemoveEdict (index);
	ReplyToCommand (client, "[SM] Minigun with the entity index %i was removed!", index);
	
	return Plugin_Handled;
}