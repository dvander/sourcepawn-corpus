#pragma semicolon 1

#define PLUGIN_AUTHOR "DeathChaos25"
#define PLUGIN_VERSION "1.1"

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

static FakeMelee[MAXPLAYERS + 1] = 0;
static bool:ThirdPerson[MAXPLAYERS + 1] = false;

#define MAX_MELEEWEAPONS 11

#define MODEL_BILL "models/survivors/survivor_namvet.mdl"
#define MODEL_ZOEY 	"models/survivors/survivor_teenangst.mdl"
#define MODEL_FRANCIS "models/survivors/survivor_biker.mdl"
#define MODEL_LOUIS "models/survivors/survivor_manager.mdl"

#define model_weapon_melee_fireaxe "models/weapons/melee/w_fireaxe.mdl"  
#define model_weapon_melee_baseball_bat "models/weapons/melee/w_bat.mdl"  
#define model_weapon_melee_crowbar "models/weapons/melee/w_crowbar.mdl"  
#define model_weapon_melee_electric_guitar "models/weapons/melee/w_electric_guitar.mdl"  
#define model_weapon_melee_cricket_bat "models/weapons/melee/w_cricket_bat.mdl"  
#define model_weapon_melee_frying_pan  "models/weapons/melee/w_frying_pan.mdl"  
#define model_weapon_melee_golfclub  "models/weapons/melee/w_golfclub.mdl" 
#define model_weapon_melee_machete  "models/weapons/melee/w_machete.mdl" 
#define model_weapon_melee_katana  "models/weapons/melee/w_katana.mdl"
#define model_weapon_melee_tonfa  "models/weapons/melee/w_tonfa.mdl"
#define model_weapon_melee_riotshield  "models/weapons/melee/w_riotshield.mdl"
#define model_weapon_melee_hunting_knife  "models/w_models/weapons/w_knife_t.mdl"

new const String:MeleeWeapons[MAX_MELEEWEAPONS + 1][] = 
{
	model_weapon_melee_fireaxe, 
	model_weapon_melee_baseball_bat, 
	model_weapon_melee_crowbar, 
	model_weapon_melee_electric_guitar, 
	model_weapon_melee_cricket_bat, 
	model_weapon_melee_frying_pan, 
	model_weapon_melee_golfclub, 
	model_weapon_melee_machete, 
	model_weapon_melee_katana, 
	model_weapon_melee_tonfa, 
	model_weapon_melee_riotshield, 
	model_weapon_melee_hunting_knife
};

new const String:MeleeWeaponNames[MAX_MELEEWEAPONS + 1][] = 
{
	"fireaxe", 
	"baseball_bat", 
	"crowbar", 
	"electric_guitar", 
	"cricket_bat", 
	"frying_pan", 
	"golfclub", 
	"machete", 
	"katana", 
	"tonfa", 
	"riotshield", 
	"knife"
};

public Plugin myinfo = 
{
	name = "[L4D2] L4D1 Survivors Melee Weapon model fix", 
	author = PLUGIN_AUTHOR, 
	description = "Fixes an issue with L4D1 survivor models where the melee weapons do not display on their backs", 
	version = PLUGIN_VERSION, 
	url = "https://forums.alliedmods.net/showthread.php?t=267225"
};

public OnPluginStart()
{
	RegConsoleCmd("sm_view", ViewAngles);
	RegConsoleCmd("sm_ang", ChangeAngles);
	RegConsoleCmd("sm_pos", ChangePosition);
	HookEvent("player_death", RemoveMelee);
	CreateTimer(GetRandomFloat(0.1, 0.3), CheckClients, _, TIMER_REPEAT);
}

public OnMapStart()
{
	for (new i = 0; i <= MAX_MELEEWEAPONS; i++)
	{
		CheckModelPreCache(MeleeWeapons[i]);
	}
	for (new client = 1; client <= MaxClients; client++)
	{
		ResetFakeMelee(client);
	}
}

public OnMapEnd()
{
	for (new client = 1; client <= MaxClients; client++)
	{
		ResetFakeMelee(client);
	}
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
	new melee = GetPlayerWeaponSlot(client, 1);
	new active = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	new String:classname[128];
	if (!IsL4D1Survivor(client) || !IsPlayerAlive(client) || !IsValidEdict(melee))
	{
		if (!IsL4D1Survivor(client) && FakeMelee[client] > 0 && IsValidEntS(FakeMelee[client], "prop_dynamic"))
		{
			ResetFakeMelee(client);
		}
		return Plugin_Continue;
	}
	GetEdictClassname(melee, classname, sizeof(classname));
	if (StrEqual(classname, "weapon_melee") && FakeMelee[client] == 0 && melee != active)
	{
		new String:model[128], modelnum;
		GetEntPropString(melee, Prop_Data, "m_strMapSetScriptName", model, sizeof(model));
		new ent = CreateEntityByName("prop_dynamic_override");
		
		for (new i = 0; i <= MAX_MELEEWEAPONS; i++)
		{
			if (StrEqual(model, MeleeWeaponNames[i]))
			{
				modelnum = i;
			}
		}
		SetEntityModel(ent, MeleeWeapons[modelnum]);
		DispatchSpawn(ent);
		
		SetEntProp(ent, Prop_Data, "m_CollisionGroup", 2);
		decl String:sTemp[16];
		Format(sTemp, sizeof(sTemp), "target%d", client);
		DispatchKeyValue(client, "targetname", sTemp);
		SetVariantString(sTemp);
		AcceptEntityInput(ent, "SetParent", ent, ent, 0);
		
		new Float:pos[3];
		new Float:ang[3];
		
		SetVariantString("medkit");
		AcceptEntityInput(ent, "SetParentAttachment");
		SetVector(pos, 1.5, -8.0, -2.5);
		SetVector(ang, 60.0, 75.0, 345.0);
		
		TeleportEntity(ent, pos, ang, NULL_VECTOR);
		SDKHook(ent, SDKHook_SetTransmit, Hook_SetTransmit);
		FakeMelee[client] = ent;
	}
	else if (melee == active && FakeMelee[client] > 0 && IsValidEntS(FakeMelee[client], "prop_dynamic"))
	{
		ResetFakeMelee(client);
	}
	return Plugin_Continue;
}

public ResetFakeMelee(client)
{
	if (FakeMelee[client] > 0 && IsValidEntS(FakeMelee[client], "prop_dynamic"))
	{
		AcceptEntityInput(FakeMelee[client], "ClearParent");
		AcceptEntityInput(FakeMelee[client], "kill");
		FakeMelee[client] = 0;
	}
}

SetVector(Float:target[3], Float:x, Float:y, Float:z)
{
	target[0] = x;
	target[1] = y;
	target[2] = z;
}

IsValidEntS(ent, String:classname[64])
{
	if (IsValidEnt(ent))
	{
		decl String:name[64];
		GetEdictClassname(ent, name, 64);
		if (StrEqual(classname, name))
		{
			return true;
		}
	}
	return false;
}

IsValidEnt(ent)
{
	if (ent > 0 && IsValidEdict(ent) && IsValidEntity(ent))
	{
		return true;
	}
	return false;
}

public Action:RemoveMelee(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (IsSurvivor(client) && FakeMelee[client] > 0)
	{
		ResetFakeMelee(client);
	}
}

stock bool:IsSurvivor(client)
{
	return client > 0 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == 2;
}

stock bool:IsIncaped(client)
{
	return bool:GetEntProp(client, Prop_Send, "m_isIncapacitated", 1);
}

stock CheckModelPreCache(const String:Modelfile[])
{
	if (!IsModelPrecached(Modelfile))
	{
		PrecacheModel(Modelfile, true);
		PrintToServer("Precaching Model:%s", Modelfile);
	}
}

stock bool:IsL4D1Survivor(client)
{
	if (IsSurvivor(client))
	{
		decl String:model[42];
		GetEntPropString(client, Prop_Data, "m_ModelName", model, sizeof(model));
		if (StrEqual(model, MODEL_FRANCIS, false) || StrEqual(model, MODEL_LOUIS, false)
			 || StrEqual(model, MODEL_BILL, false) || StrEqual(model, MODEL_ZOEY, false))
		{
			return true;
		}
		
	}
	return false;
}

public Action:Hook_SetTransmit(entity, client)
{
	if (entity == FakeMelee[client] && !ThirdPerson[client])
	{
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

// test commands (ignore)

public Action:ViewAngles(client, args)
{
	new Float:angles[3];
	GetEntPropVector(FakeMelee[client], Prop_Send, "m_vecAngles", angles);
	PrintToChatAll("%f %f %f", angles[0], angles[1], angles[2]);
}

public Action:ChangeAngles(client, args)
{
	new String:buffer[32];
	new Float:x, Float:y, Float:z, Float:ang[3];
	
	GetCmdArg(1, buffer, sizeof(buffer));
	x = StringToFloat(buffer);
	
	GetCmdArg(2, buffer, sizeof(buffer));
	y = StringToFloat(buffer);
	
	GetCmdArg(3, buffer, sizeof(buffer));
	z = StringToFloat(buffer);
	
	SetVector(ang, x, y, z);
	
	if (FakeMelee[client] > 0 && IsValidEntS(FakeMelee[client], "prop_dynamic"))
	{
		TeleportEntity(FakeMelee[client], NULL_VECTOR, ang, NULL_VECTOR);
	}
}

public Action:ChangePosition(client, args)
{
	new String:buffer[32];
	new Float:x, Float:y, Float:z, Float:ang[3];
	
	GetCmdArg(1, buffer, sizeof(buffer));
	x = StringToFloat(buffer);
	
	GetCmdArg(2, buffer, sizeof(buffer));
	y = StringToFloat(buffer);
	
	GetCmdArg(3, buffer, sizeof(buffer));
	z = StringToFloat(buffer);
	
	SetVector(ang, x, y, z);
	
	if (FakeMelee[client] > 0 && IsValidEntS(FakeMelee[client], "prop_dynamic"))
	{
		TeleportEntity(FakeMelee[client], ang, NULL_VECTOR, NULL_VECTOR);
	}
}

public Action:CheckClients(Handle:timer)
{
	for (new iClientIndex = 1; iClientIndex <= MaxClients; iClientIndex++)
	{
		if (IsClientInGame(iClientIndex))
		{
			if (GetClientTeam(iClientIndex) == 2 || GetClientTeam(iClientIndex) == 3) // Only query clients on survivor or infected team, ignore spectators.
			{
				QueryClientConVar(iClientIndex, "c_thirdpersonshoulder", QueryClientConVarCallback);
			}
		}
	}
}

public QueryClientConVarCallback(QueryCookie:cookie, client, ConVarQueryResult:result, const String:cvarName[], const String:cvarValue[])
{
	if (IsClientInGame(client) && !IsClientInKickQueue(client))
	{
		if (result != ConVarQuery_Okay)
		{
			ThirdPerson[client] = true;
		}
		else if (!StrEqual(cvarValue, "false") && !StrEqual(cvarValue, "0"))
		{
			ThirdPerson[client] = true;
		}
		else ThirdPerson[client] = false;
	}
} 