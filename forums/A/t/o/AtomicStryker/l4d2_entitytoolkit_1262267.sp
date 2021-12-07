#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.0.1"


public Plugin:myinfo =
{
	name = "L4D2 Entity Tool Kit",
	author = " AtomicStryker",
	description = " To find and manipulate Entities and stuff ",
	version = PLUGIN_VERSION,
	url = ""
};

public OnPluginStart()
{
	RegAdminCmd("sm_findentitybyclass", Cmd_FindEntityByClass, ADMFLAG_BAN, "sm_findentitybyclass <classname> <entid> - find an entity by classname and starting index.");
	RegAdminCmd("sm_findentitybynetclass", Cmd_FindEntityByNetClass, ADMFLAG_BAN, "sm_findentitybynetclass <netclass> - finds all entites of a given netclass");
	RegAdminCmd("sm_findentitybyname", Cmd_FindEntityByName, ADMFLAG_BAN, "sm_findentitybyname <name> <entid> - find an entity by name and starting index.");
	RegAdminCmd("sm_listentities", Cmd_ListEntities, ADMFLAG_BAN, "sm_listentities - server console dump of all valid entities");
	RegAdminCmd("sm_findnearentities", Cmd_FindNearEntities, ADMFLAG_BAN, "sm_findnearentities <radius> - find all Entities in a radius around you.");
	RegAdminCmd("sm_sendentityinput", Cmd_SendEntityInput, ADMFLAG_BAN, "sm_entityinput <entity id> <input string> - sends an Input to said Entity.");
	RegAdminCmd("sm_findentprop", Cmd_FindEntPropVal, ADMFLAG_BAN, "sm_findentprop <entity id> <property string> - returns an entity property");
	RegAdminCmd("sm_findentmodel", Cmd_FindEntityModel, ADMFLAG_BAN, "sm_findentmodel <entity id> - returns an entities model");
}

// this console command is for finding entities and their id
public Action:Cmd_FindEntityByClass(client, args)
{
	if (args < 2)
	{
		ReplyToCommand(client, "[SM] Usage: sm_findentitybyclass <classname> <startindex> - find an entity class starting from index number");
		return Plugin_Handled;
	}
	
	decl String:name[64], String:startnum[12];
	GetCmdArg(1, name, 64);
	GetCmdArg(2, startnum, 12);
	new startent = StringToInt(startnum);
	if (!IsValidEdict(startent))
	{
		PrintToChat(client, "That starting Entity is invalid.");
		return Plugin_Handled;
	}
	
	new entid = FindEntityByClassname(startent, name);
	if (entid == -1)
	{
		PrintToChat(client, "Found no Entity of that class.");
		return Plugin_Handled;
	}
	
	decl Float:clientpos[3], Float:entpos[3];
	GetClientAbsOrigin(client, clientpos);
	GetEntityAbsOrigin(entid, entpos);
	new Float:distance = GetVectorDistance(clientpos, entpos);
	
	GetEntPropString(entid, Prop_Data, "m_iName", name, sizeof(name));
	PrintToChat(client, "Found Entity Id %i, of name: %s; distance from you: %f", entid, name, distance);
	
	return Plugin_Handled;
}

public Action:Cmd_FindEntityByNetClass(client, args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_findentitybynetclass <netclass>");
		return Plugin_Handled;
	}
	
	decl String:arg[64], String:netclass[64], String:name[64], String:classname[64];
	GetCmdArg(1, arg, sizeof(arg));

	new maxentities = GetMaxEntities();
	new netclasssize = sizeof(netclass);
	
	for (new i = 1; i <= maxentities; i++)
	{
		if (!IsValidEdict(i)) continue;
		
		GetEntityNetClass(i, netclass, netclasssize);
		if (!StrEqual(arg, netclass, false)) continue;
		
		GetEdictClassname(i, classname, sizeof(classname));
		GetEntPropString(i, Prop_Data, "m_iName", name, sizeof(name));
		
		ReplyToCommand(client, "Found Entity %i of Netclass %s, class %s, name %s", i, netclass, classname, name);
		return Plugin_Handled;
	}
	
	ReplyToCommand(client, "Finished search for Entites of Netclass %s", netclass);
	return Plugin_Handled;
}

public Action:Cmd_FindEntityByName(client, args)
{
	if (args < 2)
	{
		ReplyToCommand(client, "[SM] Usage: sm_findentitybyname <name> <startindex> - find an entity by name starting from index number");
		return Plugin_Handled;
	}
	
	decl String:entname[64], String:number[12];
	GetCmdArg(1, entname, 64);
	GetCmdArg(2, number, 64);
	
	new foundid = FindEntityByName(entname, StringToInt(number));
	if (foundid == -1) PrintToChatAll("Nothing by that name found.");
	else PrintToChatAll("Found Entity: %i by name %s", foundid, entname);
	
	return Plugin_Handled;
}

public Action:Cmd_FindEntityModel(client, args)
{
	decl String:number[12];
	GetCmdArg(1, number, 64);
	
	decl String:m_ModelName[PLATFORM_MAX_PATH];
	GetEntPropString(StringToInt(number), Prop_Data, "m_ModelName", m_ModelName, sizeof(m_ModelName));
	
	PrintToChat(client, "Model: %s", m_ModelName);
	
	decl Float:EyePos[3], Float:AimOnEnt[3], Float:AimAngles[3], Float:entpos[3];
	GetClientEyePosition(client, EyePos);
	GetEntityAbsOrigin(StringToInt(number), entpos);
	MakeVectorFromPoints(EyePos, entpos, AimOnEnt);
	GetVectorAngles(AimOnEnt, AimAngles);
	TeleportEntity(client, NULL_VECTOR, AimAngles, NULL_VECTOR); // make the Survivor Bot aim on the Victim

	return Plugin_Handled;
}

//this sends Entity Inputs like "Kill" or "Activate"
public Action:Cmd_SendEntityInput(client, args)
{
	if (args < 2)
	{
		ReplyToCommand(client, "[SM] Usage: sm_entityinput <entity id> <input string> - sends an Input to said Entity");
		return Plugin_Handled;
	}
	
	decl String:entid[64], String:input[12];
	GetCmdArg(1, entid, 64);
	GetCmdArg(2, input, 64);
	
	AcceptEntityInput(StringToInt(entid), input);
	
	return Plugin_Handled;
}

// this finds entites - who have a position - in a radius around you
public Action:Cmd_FindNearEntities(client, args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_findnearentities <radius> - find all Entities with a position close to you");
		return Plugin_Handled;
	}
	decl String:value[64];
	GetCmdArg(1, value, 64);
	new Float:radius = StringToFloat(value);
	
	decl Float:entpos[3], Float:clientpos[3], String:name[128], String:classname[128];
	GetClientAbsOrigin(client, clientpos);
	new maxentities = GetMaxEntities();
	
	for (new i = 1; i <= maxentities; i++)
	{
		if (!IsValidEntity(i)) continue; // exclude invalid entities.
		
		GetEntPropString(i, Prop_Data, "m_iName", name, sizeof(name));
		GetEdictClassname(i, classname, 128)
		
		// you wouldn't believe how long this took me.
		if (strcmp(classname, "cs_team_manager") == 0) continue;
		if (strcmp(classname, "terror_player_manager") == 0) continue;
		if (strcmp(classname, "terror_gamerules") == 0) continue;
		if (strcmp(classname, "soundent") == 0) continue;
		if (strcmp(classname, "vote_controller") == 0) continue;
		if (strcmp(classname, "move_rope") == 0) continue;
		if (strcmp(classname, "keyframe_rope") == 0) continue;
		if (strcmp(classname, "water_lod_control") == 0) continue;
		if (strcmp(classname, "predicted_viewmodel") == 0) continue;
		if (strcmp(classname, "beam") == 0) continue;
		if (strcmp(classname, "info_particle_system") == 0) continue;
		if (strcmp(classname, "color_correction") == 0) continue;
		if (strcmp(classname, "shadow_control") == 0) continue;
		if (strcmp(classname, "env_fog_controller") == 0) continue;
		if (strcmp(classname, "ability_lunge") == 0) continue;
		if (strcmp(classname, "cs_ragdoll") == 0) continue;
		if (strcmp(classname, "instanced_scripted_scene") == 0) continue;
		if (strcmp(classname, "ability_vomit") == 0) continue;
		if (strcmp(classname, "ability_tongue") == 0) continue;
		if (strcmp(classname, "env_wind") == 0) continue;
		if (strcmp(classname, "env_detail_controller") == 0) continue;
		if (strcmp(classname, "func_occluder") == 0) continue;
		if (strcmp(classname, "logic_choreographed_scene") == 0) continue;
		if (strcmp(classname, "env_sun") == 0) continue;
		if (strcmp(classname, "ability_spit") == 0) continue;
		if (strcmp(classname, "ability_leap") == 0) continue;
		if (strcmp(classname, "ability_charge") == 0) continue;
		if (strcmp(classname, "ability_throw") == 0) continue;
		
		GetEntityAbsOrigin(i, entpos);
		if (GetVectorDistance(entpos, clientpos) < radius)
		{
			PrintToChat(client, "Found: Entid %i, name %s, class %s", i, name, classname);
		}
	}
	return Plugin_Handled;
}

// dumps a list of all map entities into your servers console. if you localhost that is YOUR console ^^
public Action:Cmd_ListEntities(client, args)
{
	new maxentities = GetMaxEntities();
	decl String:name[128], String:classname[128];
	
	for (new i = 0; i <= maxentities; i++)
	{
		if (!IsValidEntity(i)) continue; // exclude invalid entities.
		
		GetEntPropString(i, Prop_Data, "m_iName", name, sizeof(name));
		GetEdictClassname(i, classname, 128)
		PrintToServer("%i: name %s, classname %s", i, name, classname);
		
	}
	return Plugin_Handled;
}

stock FindEntityByName(String:name[], any:startcount)
{
	decl String:classname[128];
	new maxentities = GetMaxEntities();
	
	for (new i = startcount; i <= maxentities; i++)
	{
		if (!IsValidEntity(i)) continue; // exclude invalid entities.
		
		GetEdictClassname(i, classname, 128);
		
		// you wouldn't believe how long this took me.
		if (strcmp(classname, "cs_team_manager") == 0) continue;
		if (strcmp(classname, "terror_player_manager") == 0) continue;
		if (strcmp(classname, "terror_gamerules") == 0) continue;
		if (strcmp(classname, "soundent") == 0) continue;
		if (strcmp(classname, "vote_controller") == 0) continue;
		if (strcmp(classname, "move_rope") == 0) continue;
		if (strcmp(classname, "keyframe_rope") == 0) continue;
		if (strcmp(classname, "water_lod_control") == 0) continue;
		if (strcmp(classname, "predicted_viewmodel") == 0) continue;
		if (strcmp(classname, "beam") == 0) continue;
		if (strcmp(classname, "info_particle_system") == 0) continue;
		if (strcmp(classname, "color_correction") == 0) continue;
		if (strcmp(classname, "shadow_control") == 0) continue;
		if (strcmp(classname, "env_fog_controller") == 0) continue;
		if (strcmp(classname, "ability_lunge") == 0) continue;
		if (strcmp(classname, "cs_ragdoll") == 0) continue;
		if (strcmp(classname, "instanced_scripted_scene") == 0) continue;
		if (strcmp(classname, "ability_vomit") == 0) continue;
		if (strcmp(classname, "ability_tongue") == 0) continue;
		if (strcmp(classname, "env_wind") == 0) continue;
		if (strcmp(classname, "env_detail_controller") == 0) continue;
		if (strcmp(classname, "func_occluder") == 0) continue;
		if (strcmp(classname, "logic_choreographed_scene") == 0) continue;
		if (strcmp(classname, "env_sun") == 0) continue;
		if (strcmp(classname, "ability_spit") == 0) continue;
		if (strcmp(classname, "ability_leap") == 0) continue;
		if (strcmp(classname, "ability_charge") == 0) continue;
		if (strcmp(classname, "ability_throw") == 0) continue;
		
		decl String:iname[128];
		GetEntPropString(i, Prop_Data, "m_iName", iname, sizeof(iname));
		if (strcmp(name,iname,false) == 0) return i;
	}
	return -1;
}

public Action:Cmd_FindEntPropVal(client, args)
{
	if (args < 2)
	{
		ReplyToCommand(client, "[SM] Usage: sm_findentprop <entity id> <property string> - returns an entity property");
		return Plugin_Handled;
	}
	
	decl String:cmdstring[64];
	GetCmdArg(1, cmdstring, sizeof(cmdstring));
	
	new entity = StringToInt(cmdstring);
	if (!IsValidEntity(entity))
	{
		PrintToChat(client, "%i: Not a valid entity", entity)
		return Plugin_Handled;
	}
	
	GetCmdArg(2, cmdstring, sizeof(cmdstring));
	
	decl String:netclass[64];
	GetEntityNetClass(entity, netclass, sizeof(netclass));
	PrintToChat(client, "Netclass: %s", netclass)
	
	new offset = FindSendPropInfo(netclass, cmdstring);
	
	if (offset == -1)
	{
		PrintToChat(client, "No such property: %s", cmdstring)
		return Plugin_Handled;
	}
	
	else if (offset == 0)
	{
		PrintToChat(client, "No offset found for: %s", cmdstring)
		return Plugin_Handled;
	}
	
	PrintToChat(client, "Value of %s in %s, int: %i", cmdstring, netclass, GetEntData(entity, offset));
	PrintToChat(client, "Value of %s in %s, float: %f", cmdstring, netclass, GetEntDataFloat(entity, offset));
	return Plugin_Handled;
}

stock UnflagAndExecuteCommand(client, String:command[], String:parameter1[]="", String:parameter2[]="")
{
	if (!client || !IsClientInGame(client)) client = GetAnyValidClient();
	if (!client || !IsClientInGame(client)) return;
	
	new userflags = GetUserFlagBits(client);
	SetUserFlagBits(client, ADMFLAG_ROOT);
	new flags = GetCommandFlags(command);
	SetCommandFlags(command, flags & ~FCVAR_CHEAT);
	FakeClientCommand(client, "%s %s %s", command, parameter1, parameter2)
	SetCommandFlags(command, flags);
	SetUserFlagBits(client, userflags);
}

//entity abs origin code from here
//http://forums.alliedmods.net/showpost.php?s=e5dce96f11b8e938274902a8ad8e75e9&p=885168&postcount=3
stock GetEntityAbsOrigin(entity,Float:origin[3])
{
	if (entity > 0 && IsValidEntity(entity))
	{
		decl Float:mins[3], Float:maxs[3];
		GetEntPropVector(entity,Prop_Send,"m_vecOrigin",origin);
		GetEntPropVector(entity,Prop_Send,"m_vecMins",mins);
		GetEntPropVector(entity,Prop_Send,"m_vecMaxs",maxs);
		
		origin[0] += (mins[0] + maxs[0]) * 0.5;
		origin[1] += (mins[1] + maxs[1]) * 0.5;
		origin[2] += (mins[2] + maxs[2]) * 0.5;
	}
}

stock GetAnyValidClient()
{
	for (new target = 1; target <= MaxClients; target++)
	{
		if (IsClientInGame(target)) return target;
	}
	return -1;
}