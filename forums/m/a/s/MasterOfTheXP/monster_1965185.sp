#include <sourcemod>
#include <sdktools>

#define MAX_MONSTERS 64

new Handle:MonsterList;
new Handle:MonsterCollision;
new Handle:MonsterDamageList;
new Handle:MonsterModel;
new Handle:MonsterAnimation;
new Handle:MonsterHealth;
new Handle:MonsterDamage;
new Handle:MonsterDamageRange;
new Handle:MonsterDamageDelay;
new Handle:MonsterColor;
new Handle:MonsterAlpha;
new Handle:MonsterSpeed;
new Handle:MonsterScale;
new Handle:MonsterOffset;
new Handle:MonsterMinRange;
new Handle:MonsterMaxRange;
new Handle:MonsterFollow;
new Handle:MonsterZone;
new Handle:MonsterAttack;

new Handle:TargetList[MAX_MONSTERS];

new bool:isImmune[MAXPLAYERS][MAX_MONSTERS];

#define PLUGIN_VERSION "1.1.1"
public Plugin:myinfo = 
{
	name = "Monster",
	author = "Panzer",
	description = "Creates a monster that chases the nearest player",
	version = PLUGIN_VERSION,
	url = "forums.alliedmodders.com"
}

public OnPluginStart()
{
	LoadTranslations("common.phrases");

	// Create arrays
	MonsterList = CreateArray();
	MonsterCollision = CreateArray();
	MonsterDamageList = CreateArray();
	MonsterModel = CreateArray(64);
	MonsterAnimation = CreateArray(64);
	MonsterHealth = CreateArray();
	MonsterDamage = CreateArray();
	MonsterDamageRange = CreateArray();
	MonsterDamageDelay = CreateArray();
	MonsterColor = CreateArray(16);
	MonsterAlpha = CreateArray();
	MonsterSpeed = CreateArray();
	MonsterScale = CreateArray();
	MonsterOffset = CreateArray();
	MonsterMinRange = CreateArray();
	MonsterMaxRange = CreateArray();
	MonsterFollow = CreateArray();
	MonsterZone = CreateArray(64);
	MonsterAttack = CreateArray();
	
	// Add existing monster collisions to monster collision list
	new monsterCollision = -1;
	while ((monsterCollision = FindEntityByClassname(monsterCollision, "prop_physics")) != -1)
	{
		decl String:targetname[32];
		GetEntPropString(monsterCollision, Prop_Data, "m_iName", targetname, sizeof(targetname));
		new mIndex;
		if (StrContains(targetname, "_c_123monster321_") != -1)
			mIndex = PushArrayCell(MonsterCollision, monsterCollision);
			
		// Create default random target list
		TargetList[mIndex] = CreateArray();
		for (new clients = 1; clients <= MaxClients; clients++)
			if (IsValidClient(clients))
				PushArrayCell(TargetList[mIndex], clients);
		
		// Set default attributes
		decl String:model[64];
		GetEntPropString(monsterCollision, Prop_Data, "m_ModelName", model, sizeof(model));
		PushArrayString(MonsterModel, model);
		PushArrayString(MonsterAnimation, "");
		PushArrayCell(MonsterHealth, 150);
		PushArrayCell(MonsterDamage, 2);
		PushArrayCell(MonsterDamageRange, 64.0);
		PushArrayCell(MonsterDamageDelay, 0.1);
		PushArrayArray(MonsterColor, "255,255,255");
		PushArrayCell(MonsterAlpha, 255);
		PushArrayCell(MonsterSpeed, 250.0);
		PushArrayCell(MonsterScale, 1.0);
		PushArrayCell(MonsterOffset, 32.0);
		PushArrayCell(MonsterMinRange, 4.0);
		PushArrayCell(MonsterMaxRange, 999999.0);
		PushArrayCell(MonsterFollow, -1);
		PushArrayString(MonsterZone, "");
		PushArrayCell(MonsterAttack, 0);
		
		// Default monster collision values
		DispatchKeyValue(monsterCollision, "solid", "6");
		HookSingleEntityOutput(monsterCollision, "OnBreak", Monster_OnBreak);
		SetEntProp(monsterCollision, Prop_Data, "m_takedamage", 2);
		SetEntProp(monsterCollision, Prop_Data, "m_iMaxHealth", 150);
		SetEntProp(monsterCollision, Prop_Data, "m_iHealth", 150);
		SetEntProp(monsterCollision, Prop_Send, "m_usSolidFlags", 1);
		SetEntProp(monsterCollision, Prop_Send, "m_CollisionGroup", 11);
	}
	
	// Add existing monsters to monster list
	new monster = -1;
	while ((monster = FindEntityByClassname(monster, "prop_dynamic")) != -1)
	{
		decl String:targetname[32];
		GetEntPropString(monster, Prop_Data, "m_iName", targetname, sizeof(targetname));
		if (StrContains(targetname, "_v_123monster321_") != -1)
			PushArrayCell(MonsterList, monster);
			
		// Default monster values
		SetEntityRenderColor(monster, 255, 255, 255, 255);
		DispatchKeyValue(monster, "solid", "0");
	}
	
	// Add existing damage entities to damage list
	new damage = -1;
	while ((damage = FindEntityByClassname(damage, "point_hurt")) != -1)
	{
		decl String:targetname[32];
		GetEntPropString(damage, Prop_Data, "m_iName", targetname, sizeof(targetname));
		if (StrContains(targetname, "_d_123monster321_") != -1)
			PushArrayCell(MonsterDamageList, damage);
			
		// Default damage values
		DispatchKeyValue(damage, "damage", "2");
	}
	
	// Console commands
	RegAdminCmd("sm_monster", Command_Monster, ADMFLAG_GENERIC, "sm_monster <name> <model> [x,y,z]");
	RegAdminCmd("sm_monster_set", Command_MonsterSet, ADMFLAG_GENERIC, "sm_monster_set <name> <attribute> <value>");
	RegAdminCmd("sm_monster_list", Command_MonsterList, ADMFLAG_GENERIC, "Lists all monsters");
	RegAdminCmd("sm_monster_remove", Command_MonsterRemove, ADMFLAG_GENERIC, "sm_monster_remove <name>");
	RegAdminCmd("sm_monster_clear", Command_MonsterClear, ADMFLAG_GENERIC, "Removes all monsters");
	RegAdminCmd("sm_monster_tele", Command_MonsterTele, ADMFLAG_GENERIC, "sm_monster_tele <name>");
	
	CreateConVar("spawnmonsterprops_version", PLUGIN_VERSION, "Plugin version, don't touch.", FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_PLUGIN|FCVAR_SPONLY);
}

public OnMapEnd()
{
	for (new i = 0; i < GetArraySize(MonsterList); i++)
		ClearArray(TargetList[i]);
	ClearArray(MonsterList);
	ClearArray(MonsterDamageList);
	ClearArray(MonsterCollision);
	ClearArray(MonsterModel);
	ClearArray(MonsterAnimation);
	ClearArray(MonsterHealth);
	ClearArray(MonsterDamage);
	ClearArray(MonsterDamageRange);
	ClearArray(MonsterDamageDelay);
	ClearArray(MonsterColor);
	ClearArray(MonsterAlpha);
	ClearArray(MonsterSpeed);
	ClearArray(MonsterScale);
	ClearArray(MonsterOffset);
	ClearArray(MonsterMinRange);
	ClearArray(MonsterMaxRange);
	ClearArray(MonsterFollow);
	ClearArray(MonsterZone);
	ClearArray(MonsterAttack);
}

public Action:Command_Monster(client, args)
{
	if (args < 2 || args > 3)
	{
		ReplyToCommand(client, "[SM] Usage: sm_monster <name> <model> [x,y,z]\nExample 1: sm_monster monster1 models/ichthyosaur.mdl\nExample 2: sm_monster monster2 models/gman_high.mdl 256,0,128");
		return Plugin_Handled;
	}
	else if (GetArraySize(MonsterList) > MAX_MONSTERS)
	{
		ReplyToCommand(client, "[SM] Error: There are too many monsters");
		return Plugin_Handled;
	}
	
	decl String:name[64], String:model[64], String:origin[16];
	
	GetCmdArg(1, name, sizeof(name));
	GetCmdArg(2, model, sizeof(model));
	GetCmdArg(3, origin, sizeof(origin));
	
	// Create model at crosshair position
	new Float:pos[3], Float:angles[3];
	if (StrEqual(origin, ""))
	{
		GetClientEyePosition(client, pos);
		GetClientEyeAngles(client, angles);
		TR_TraceRayFilter(pos, angles, MASK_PLAYERSOLID, RayType_Infinite, TraceFilter, client);
		if (TR_DidHit(INVALID_HANDLE))
			TR_GetEndPosition(pos);
	}
	else
	{
		new String:tempPos[3][8];
		ExplodeString(origin, ",", tempPos, sizeof(tempPos), sizeof(tempPos[]));
		for (new i = 0; i < 3; i++)
			pos[i] = StringToFloat(tempPos[i]);
	}
	SpawnMonster(name, model, pos);
	
	return Plugin_Handled;
}

public bool:TraceFilter(entity, contentsMask, any:data)
{
    if(entity != data && entity > MaxClients)
        return true;
    return false;
}

public Action:Command_MonsterSet(client, args)
{
	if (args < 3)
	{
		ReplyToCommand(client, "[SM] Usage: sm_monster_set <name> <attribute> <value>\nAttributes:\n- model <model>\n- animation <sequence>\n- health #\n- damage #\n- damagerange #\n- damagedelay #\n- color #,#,#\n- alpha #\n- speed #\n- scale #\n- offset #\n- minrange #\n- maxrange #\n- sound \"[interval] <path>\"\n- attack <player/all/none>\n- follow <player/none>\n- zone <zone>");
		return Plugin_Handled;
	}
	
	decl String:name[64];
	
	GetCmdArg(1, name, sizeof(name));
	
	new bool:found = false;
	for (new mIndex = 0; mIndex < GetArraySize(MonsterList); mIndex++)
	{
		new monster = GetArrayCell(MonsterList, mIndex);
		new monsterCollision = GetArrayCell(MonsterCollision, mIndex);
		new monsterHurt = GetArrayCell(MonsterDamageList, mIndex);
		decl String:targetname[64];
		GetEntPropString(monster, Prop_Data, "m_iName", targetname, sizeof(targetname));
		if (StrContains(targetname, name) != -1)
		{
			found = true;
			new String:attribute[16], String:value[64];
			for (new i = 2; i <= args; i += 2)
			{
				GetCmdArg(i, attribute, sizeof(attribute));
				GetCmdArg(i+1, value, sizeof(value));
				if (StrEqual(attribute, "model"))
				{
					if (!IsModelPrecached(value))
						PrecacheModel(value);
					SetEntityModel(monster, value);
					SetEntityModel(monsterCollision, value);
					SetArrayString(MonsterModel, mIndex, value);
				}
				else if (StrEqual(attribute, "animation"))
				{
					SetVariantString(value);
					AcceptEntityInput(monster, "SetAnimation");
					SetArrayString(MonsterAnimation, mIndex, value);
				}
				else if (StrEqual(attribute, "health"))
				{
					new health = StringToInt(value);
					SetEntProp(monsterCollision, Prop_Data, "m_iMaxHealth", health);
					SetEntProp(monsterCollision, Prop_Data, "m_iHealth", health);
					SetArrayCell(MonsterHealth, mIndex, health);
				}
				else if (StrEqual(attribute, "damage"))
				{
					DispatchKeyValue(monsterHurt, "damage", value);
					new damage = StringToInt(value);
					SetArrayCell(MonsterDamage, mIndex, damage);
				}
				else if (StrEqual(attribute, "damagerange"))
				{
					new Float:damageRange = StringToFloat(value);
					SetArrayCell(MonsterDamageRange, mIndex, damageRange);
				}
				else if (StrEqual(attribute, "damagedelay"))
				{
					new Float:damageDelay = StringToFloat(value);
					SetArrayCell(MonsterDamageDelay, mIndex, damageDelay);
				}
				else if (StrEqual(attribute, "color"))
				{
					decl String:color[3][8];
					ExplodeString(value, ",", color, sizeof(color), sizeof(color[]));
					new alpha = GetArrayCell(MonsterAlpha, mIndex);
					SetEntityRenderColor(monster, StringToInt(color[0]), StringToInt(color[1]), StringToInt(color[2]), alpha);
					SetArrayString(MonsterColor, mIndex, value);
				}
				else if (StrEqual(attribute, "alpha"))
				{
					new String:colors[16];
					GetArrayString(MonsterColor, mIndex, colors, sizeof(colors));
					decl String:colors2[3][8];
					ExplodeString(colors, ",", colors2, sizeof(colors2), sizeof(colors2[]));
					new alpha = StringToInt(value);
					SetEntityRenderMode(monster, RENDER_TRANSCOLOR);
					SetEntityRenderColor(monster, StringToInt(colors2[0]), StringToInt(colors2[1]), StringToInt(colors2[2]), alpha)
					SetArrayCell(MonsterAlpha, mIndex, alpha);
				}
				else if (StrEqual(attribute, "speed"))
				{
					new Float:speed = StringToFloat(value);
					SetArrayCell(MonsterSpeed, mIndex, speed);
				}
				else if (StrEqual(attribute, "scale"))
				{
					new Float:scale = StringToFloat(value);
					SetEntPropFloat(monster, Prop_Send, "m_flModelScale", scale);
					SetEntPropFloat(monsterCollision, Prop_Send, "m_flModelScale", scale);
					SetArrayCell(MonsterScale, mIndex, scale);
				}
				else if (StrEqual(attribute, "offset"))
				{
					new Float:offset = StringToFloat(value);
					SetArrayCell(MonsterOffset, mIndex, offset);
				}
				else if (StrEqual(attribute, "minrange"))
				{
					new Float:minRange = StringToFloat(value);
					SetArrayCell(MonsterMinRange, mIndex, minRange);
				}
				else if (StrEqual(attribute, "maxrange"))
				{
					new Float:maxRange = StringToFloat(value);
					SetArrayCell(MonsterMaxRange, mIndex, maxRange);
				}
				else if (StrEqual(attribute, "sound"))
				{
					new Float:delay, String:sound[PLATFORM_MAX_PATH];
					new len = BreakString(value, sound, sizeof(sound));
					if (len == -1)
					{
						len = 0;
						value[0] = '\0';
					}
					else delay = StringToFloat(value[len]);
					
					PrecacheSound(sound);
					EmitSoundToAll(sound, monster);
					
					if (delay)
					{
						new Handle:data;
						CreateDataTimer(delay, Timer_PlaySound, data, TIMER_FLAG_NO_MAPCHANGE);
						WritePackString(data, sound);
						WritePackFloat(data, delay);
						WritePackCell(data, EntIndexToEntRef(monster));
						ResetPack(data);
					}
				}
				else if (StrEqual(attribute, "attack"))
				{
					if (StrEqual(value, "none"))
					{
						ClearArray(TargetList[mIndex]);
					}
					else if (StrEqual(value, "all"))
					{
						// Create random target list
						for (new clients = 1; clients <= MaxClients; clients++)
							if (IsValidClient(clients))
								PushArrayCell(TargetList[mIndex], clients);
					}
					else
					{
						new target = FindTarget(client, value);
						if (target > -1)
						{
							new uid = GetClientUserId(target);
							if (uid != GetArrayCell(MonsterAttack, mIndex)) SetArrayCell(MonsterAttack, mIndex, uid);
							else ReplyToCommand(client, "[SM] Error: Client is already being targetted");
						}
						//else ReplyToCommand(client, "[SM] Error: Client not found");
					}
				}
				else
				{
					ReplyToCommand(client, "[SM] Warning: Attribute \"%s\" (argument %i) is invalid, skipping.", attribute, i);
				}
			}
		}
	}
	
	if (!found)
	{
		ReplyToCommand(client, "[SM] Error: Monster not found");
		return Plugin_Handled;
	}
	
	return Plugin_Handled;
}

public Action:Command_MonsterList(client, args)
{
	if (GetArraySize(MonsterList) == 0)
	{
		ReplyToCommand(client, "[SM] Error: No monsters found");
		return Plugin_Handled;
	}
	
	for (new mIndex = 0; mIndex < GetArraySize(MonsterList); mIndex++)
	{
		new monster = GetArrayCell(MonsterList, mIndex);
		decl String:classname[64];
		GetEdictClassname(monster, classname, sizeof(classname));
		decl String:targetname[64];
		GetEntPropString(monster, Prop_Data, "m_iName", targetname, sizeof(targetname));
		ReplaceString(targetname, sizeof(targetname), "_v_123monster321_", "");
		decl String:model[64];
		GetArrayString(MonsterModel, mIndex, model, sizeof(model));
		decl String:animation[64];
		GetArrayString(MonsterAnimation, mIndex, animation, sizeof(animation));
		if (StrEqual(animation, ""))
			StrCat(animation, sizeof(animation), "none");
		new health = GetArrayCell(MonsterHealth, mIndex);
		new damage = GetArrayCell(MonsterDamage, mIndex);
		new Float:damageRange = GetArrayCell(MonsterDamageRange, mIndex);
		new Float:damageDelay = GetArrayCell(MonsterDamageDelay, mIndex);
		new Float:speed = GetArrayCell(MonsterSpeed, mIndex);
		new Float:scale = GetArrayCell(MonsterScale, mIndex);
		new String:color[16];
		GetArrayString(MonsterColor, mIndex, color, sizeof(color));
		new alpha = GetArrayCell(MonsterAlpha, mIndex);
		new Float:offset = GetArrayCell(MonsterOffset, mIndex);
		new Float:minRange = GetArrayCell(MonsterMinRange, mIndex);
		new Float:maxRange = GetArrayCell(MonsterMaxRange, mIndex);
		new String:strAttack[MAX_NAME_LENGTH+1], attack = GetClientOfUserId(GetArrayCell(MonsterAttack, mIndex));
		if (attack > 0) Format(strAttack, sizeof(strAttack), "%N", attack);
		else Format(strAttack, sizeof(strAttack), "<none>");
		PrintToConsole(client, "%s attributes:\nmodel %s\nanimation %s\nhealth %i\ndamage %i\ndamagerange %f\ndamagedelay %f\ncolor %s\nalpha %i\nspeed %f\nscale %f\noffset %f\nminrange %f\nmaxrange %f\nattack %s\n", targetname, model, animation, health, damage, damageRange, damageDelay, color, alpha, speed, scale, offset, minRange, maxRange, strAttack);
	}
	
	return Plugin_Handled;
}

public Action:Command_MonsterClear(client, args)
{
	// Remove all monsers and clear all attributes
	for (new mIndex = 0; mIndex < GetArraySize(MonsterList); mIndex++)
	{
		new monster, collision, damagelist;
		monster	= GetArrayCell(MonsterList, mIndex);
		collision	= GetArrayCell(MonsterCollision, mIndex);
		damagelist	= GetArrayCell(MonsterDamageList, mIndex);
		
		if (IsValidEntity(monster)) AcceptEntityInput(monster, "Kill");
		if (IsValidEntity(collision)) AcceptEntityInput(collision, "Kill");
		if (IsValidEntity(damagelist)) AcceptEntityInput(damagelist, "Kill");
		ClearArray(TargetList[mIndex]);
	}

	ClearArray(MonsterList);
	ClearArray(MonsterCollision);
	ClearArray(MonsterDamageList);
	ClearArray(MonsterModel);
	ClearArray(MonsterAnimation);
	ClearArray(MonsterHealth);
	ClearArray(MonsterDamage);
	ClearArray(MonsterDamageRange);
	ClearArray(MonsterDamageDelay);
	ClearArray(MonsterColor);
	ClearArray(MonsterAlpha);
	ClearArray(MonsterSpeed);
	ClearArray(MonsterScale);
	ClearArray(MonsterOffset);
	ClearArray(MonsterMinRange);
	ClearArray(MonsterMaxRange);
	ClearArray(MonsterFollow);
	ClearArray(MonsterZone);
	ClearArray(MonsterAttack);
	
	return Plugin_Handled;
}

public Action:Command_MonsterTele(client, args)
{
	if (!client) return Plugin_Continue;
	if (!args)
	{
		ReplyToCommand(client, "[SM] Usage: sm_monster_tele <name>");
		return Plugin_Handled;
	}
	
	decl String:name[64];
	
	GetCmdArgString(name, sizeof(name));
	
	new bool:found = false;
	for (new mIndex = 0; mIndex < GetArraySize(MonsterList); mIndex++)
	{
		new monster = GetArrayCell(MonsterList, mIndex);
		decl String:targetname[64];
		GetEntPropString(monster, Prop_Data, "m_iName", targetname, sizeof(targetname));
		if (StrContains(targetname, name) != -1)
		{
			found = true;
			new Float:Start[3], Float:End[3], Float:Ang[3];
			GetClientEyePosition(client, Start);
			GetClientEyeAngles(client, Ang);
			TR_TraceRayFilter(Start, Ang, MASK_SOLID, RayType_Infinite, TraceRayDontHitSelf, client);
			TR_GetEndPosition(End);
			TeleportEntity(monster, End, NULL_VECTOR, NULL_VECTOR);
		}
	}
	
	if (!found)
	{
		ReplyToCommand(client, "[SM] Error: Monster not found");
		return Plugin_Handled;
	}
	
	return Plugin_Handled;
}

public Action:Command_MonsterRemove(client, args)
{
	if (!client) return Plugin_Continue;
	if (!args)
	{
		ReplyToCommand(client, "[SM] Usage: sm_monster_remove <name>");
		return Plugin_Handled;
	}
	
	decl String:name[64];
	
	GetCmdArgString(name, sizeof(name));
	
	new bool:found = false;
	for (new mIndex = 0; mIndex < GetArraySize(MonsterList); mIndex++)
	{
		new monster = GetArrayCell(MonsterList, mIndex);
		decl String:targetname[64];
		GetEntPropString(monster, Prop_Data, "m_iName", targetname, sizeof(targetname));
		if (StrContains(targetname, name) != -1)
		{
			found = true;
			AcceptEntityInput(monster, "Kill");
		}
	}
	
	if (!found)
	{
		ReplyToCommand(client, "[SM] Error: Monster not found");
		return Plugin_Handled;
	}
	
	return Plugin_Handled;
}

public OnGameFrame()
{
	for (new mIndex = 0; mIndex < GetArraySize(MonsterList); mIndex++)
	{
		new monster = GetArrayCell(MonsterList, mIndex);
		new monsterCollision = GetArrayCell(MonsterCollision, mIndex);
		if (!IsValidEdict(monster)) continue;
		decl Float:mPos[3];
		GetEntPropVector(monster, Prop_Data, "m_vecOrigin", mPos);

		new Float:distance;
		new Float:minDistance = -1.0;
		new specificTarget = GetClientOfUserId(GetArrayCell(MonsterAttack, mIndex));
		if (specificTarget)
		{
			if (!IsPlayerAlive(specificTarget)) specificTarget = 0;
		}
		for (new target = 0; target < GetArraySize(TargetList[mIndex]); target++)
		{
			new client = GetArrayCell(TargetList[mIndex], target);
			if (specificTarget && client != specificTarget) continue;
			if (IsValidClient(client) && IsPlayerAlive(client))
			{
				// Get distance between players and monster
				decl Float:cPos[3];
				decl Float:vecDistance[3];
				GetClientAbsOrigin(client, cPos);
				new Float:offset = GetArrayCell(MonsterOffset, mIndex);
				cPos[2] += offset; // Height Offset
				for (new j = 0; j < 3; j++)
					vecDistance[j] = cPos[j] - mPos[j];
				
				distance = GetVectorLength(vecDistance);
				if (minDistance == -1.0 || distance < minDistance)
					minDistance = distance;
					
				// Hurt the player if they are within a certain distance
				if (distance < GetArrayCell(MonsterDamageRange, mIndex) && !isImmune[client][mIndex])
				{
					decl String:targetname[32];
					GetEntPropString(client, Prop_Data, "m_iName", targetname, sizeof(targetname));
					decl String:name[64];
					GetClientName(client, name, sizeof(name));
					DispatchKeyValue(client, "targetname", name);
					//DispatchKeyValue(GetArrayCell(MonsterDamageList, mIndex), "target", "tempdamagetarget");
					DispatchKeyValue(GetArrayCell(MonsterDamageList, mIndex), "damagetarget", name);
					AcceptEntityInput(GetArrayCell(MonsterDamageList, mIndex), "hurt");
					DispatchKeyValue(client, "targetname", targetname);
					isImmune[client][mIndex] = true;
					new Handle:pack;
					CreateDataTimer(GetArrayCell(MonsterDamageDelay, mIndex), Timer_RemoveImmunity, pack);
					WritePackCell(pack, client);
					WritePackCell(pack, mIndex);
				}
				
				if (minDistance == distance) // This is the closest player
				{
					// Set angles to track player
					new Float:angles[3];
					GetVectorAngles(vecDistance, angles);
					
					// Move towards player
					new Float:minRange = GetArrayCell(MonsterMinRange, mIndex);
					new Float:maxRange = GetArrayCell(MonsterMaxRange, mIndex);
					if (minDistance > minRange && minDistance < maxRange) // Min/Max range
					{
						NormalizeVector(vecDistance, vecDistance);
						new Float:speed = GetArrayCell(MonsterSpeed, mIndex);
						ScaleVector(vecDistance, speed * GetTickInterval()); // Set speed
						AddVectors(vecDistance, mPos, vecDistance);
						TeleportEntity(monster, vecDistance, NULL_VECTOR, NULL_VECTOR);
						TeleportEntity(monsterCollision, vecDistance, NULL_VECTOR, NULL_VECTOR);
					}
					
					TeleportEntity(monster, NULL_VECTOR, angles, NULL_VECTOR);
					TeleportEntity(monsterCollision, NULL_VECTOR, angles, NULL_VECTOR);
				}
			}
		}
	}
}

public Action:Timer_RemoveImmunity(Handle:timer, Handle:pack)
{
	ResetPack(pack);
	new client = ReadPackCell(pack);
	new mIndex = ReadPackCell(pack);
	isImmune[client][mIndex] = false;
}

public Action:Timer_PlaySound(Handle:timer, Handle:data)
{
	new String:sound[PLATFORM_MAX_PATH], Float:delay, ref;
	ReadPackString(data, sound, sizeof(sound));
	delay	= ReadPackFloat(data);
	ref		= ReadPackCell(data);
	new monster = EntRefToEntIndex(ref);
	if (!IsValidEntity(monster)) return;
	EmitSoundToAll(sound, monster);
	new Handle:data2;
	CreateDataTimer(delay, Timer_PlaySound, data2, TIMER_FLAG_NO_MAPCHANGE);
	WritePackString(data2, sound);
	WritePackFloat(data2, delay);
	WritePackCell(data2, ref);
	ResetPack(data2);
}

public SpawnMonster(String:name[64], String:model[64], Float:pos[3])
{
	if (!IsModelPrecached(model))
		PrecacheModel(model);
	
	// Collision model
	new monsterCollision = CreateEntityByName("prop_physics_override");
	if (!IsModelPrecached("models/props_farm/concrete_block001.mdl"))
		PrecacheModel("models/props_farm/concrete_block001.mdl");
	DispatchKeyValue(monsterCollision, "model", "models/props_farm/concrete_block001.mdl");
	decl String:cName[64];
	Format(cName, sizeof(cName), "_c_123monster321_%s", name);
	DispatchKeyValue(monsterCollision, "targetname", cName);
	DispatchKeyValue(monsterCollision, "solid", "6");
	DispatchKeyValue(monsterCollision, "nodamageforces", "0");
	DispatchSpawn(monsterCollision);
	HookSingleEntityOutput(monsterCollision, "OnBreak", Monster_OnBreak);
	TeleportEntity(monsterCollision, pos, NULL_VECTOR, NULL_VECTOR);
	SetEntityModel(monsterCollision, model);
	AcceptEntityInput(monsterCollision, "disablemotion");
	SetEntProp(monsterCollision, Prop_Data, "m_takedamage", 2);
	SetEntProp(monsterCollision, Prop_Data, "m_iMaxHealth", 150);
	SetEntProp(monsterCollision, Prop_Data, "m_iHealth", 150);
	SetEntProp(monsterCollision, Prop_Send, "m_usSolidFlags", 1);
	SetEntProp(monsterCollision, Prop_Send, "m_CollisionGroup", 11);
	SetEntityRenderMode(monsterCollision, RENDER_TRANSCOLOR);
	SetEntityRenderColor(monsterCollision, 255, 255, 255, 0);
	
	// Add to monster collision list
	PushArrayCell(MonsterCollision, monsterCollision);
	
	// Visual model
	new monster = CreateEntityByName("prop_dynamic_override");
	DispatchKeyValue(monster, "model", model);
	decl String:vName[64];
	Format(vName, sizeof(vName), "_v_123monster321_%s", name);
	DispatchKeyValue(monster, "targetname", vName);
	DispatchKeyValue(monster, "solid", "0");
	DispatchSpawn(monster);
	TeleportEntity(monster, pos, NULL_VECTOR, NULL_VECTOR);
	
	// Add to monster list
	new mIndex = PushArrayCell(MonsterList, monster);
	
	// Create damage entity
	new damage = CreateEntityByName("point_hurt");
	decl String:dName[64];
	Format(dName, sizeof(dName), "_d_123monster321_%s", name);
	DispatchKeyValue(damage, "targetname", dName);
	DispatchKeyValue(damage, "damage", "2");
	DispatchSpawn(damage);
	
	// Add damage entity to list
	PushArrayCell(MonsterDamageList, damage);
	
	// Create default random target list
	TargetList[mIndex] = CreateArray();
	for (new clients = 1; clients <= MaxClients; clients++)
		if (IsValidClient(clients))
			PushArrayCell(TargetList[mIndex], clients);
	
	// Set default attributes
	PushArrayString(MonsterModel, model);
	PushArrayString(MonsterAnimation, "");
	PushArrayCell(MonsterHealth, 150);
	PushArrayCell(MonsterDamage, 2);
	PushArrayCell(MonsterDamageRange, 64.0);
	PushArrayCell(MonsterDamageDelay, 0.1);
	PushArrayString(MonsterColor, "255,255,255");
	PushArrayCell(MonsterAlpha, 255);
	PushArrayCell(MonsterSpeed, 250.0);
	PushArrayCell(MonsterScale, 1.0);
	PushArrayCell(MonsterOffset, 32.0);
	PushArrayCell(MonsterMinRange, 4.0);
	PushArrayCell(MonsterMaxRange, 999999.0);
	PushArrayCell(MonsterFollow, -1);
	PushArrayString(MonsterZone, "");
	PushArrayCell(MonsterAttack, 0);
}

public Monster_OnBreak(const String:output[], caller, activator, Float:delay)
{
	// Death event
	new Handle:event = CreateEvent("player_death");
	SetEventInt(event, "userid", -1);
	SetEventInt(event, "attacker", GetClientUserId(activator));
	SetEventInt(event, "assister", -1);
	
	decl String:weapon[64];
	GetClientWeapon(activator, weapon, sizeof(weapon));
	ReplaceString(weapon, sizeof(weapon), "tf_weapon_", "");
	SetEventString(event, "weapon", weapon);
	FireEvent(event);
	
	// Remove monster entities
	new mIndex = FindValueInArray(MonsterCollision, caller);
	RemoveEdict(GetArrayCell(MonsterList, mIndex));
	RemoveEdict(GetArrayCell(MonsterDamageList, mIndex));
	RemoveFromArray(MonsterList, mIndex);
	RemoveFromArray(MonsterCollision, mIndex);
	RemoveFromArray(MonsterDamageList, mIndex);
	ClearArray(TargetList[mIndex]);
	// Move target list down one position in the array (keeps targetlist indexes in line with other lists)
	if (mIndex + 1 < MAX_MONSTERS && TargetList[mIndex + 1] != INVALID_HANDLE)
		for (new i = 0; i < GetArraySize(TargetList[mIndex + 1]); i++)
			PushArrayCell(TargetList[mIndex], GetArrayCell(TargetList[mIndex + 1], i));
	
	RemoveFromArray(MonsterModel, mIndex);
	RemoveFromArray(MonsterHealth, mIndex);
	RemoveFromArray(MonsterDamage, mIndex);
	RemoveFromArray(MonsterDamageRange, mIndex);
	RemoveFromArray(MonsterDamageDelay, mIndex);
	RemoveFromArray(MonsterColor, mIndex);
	RemoveFromArray(MonsterAlpha, mIndex);
	RemoveFromArray(MonsterSpeed, mIndex);
	RemoveFromArray(MonsterScale, mIndex);
	RemoveFromArray(MonsterOffset, mIndex);
	RemoveFromArray(MonsterMinRange, mIndex);
	RemoveFromArray(MonsterMaxRange, mIndex);
	RemoveFromArray(MonsterFollow, mIndex);
	RemoveFromArray(MonsterZone, mIndex);
	RemoveFromArray(MonsterAttack, mIndex);
}

stock bool:IsValidClient(client, bool:nobots = true) 
{  
	if (client <= 0 || client > MaxClients || !IsClientConnected(client) || (nobots && IsFakeClient(client)))
	{
		return false;  
	}
	return IsClientInGame(client);  
}

public bool:TraceRayDontHitSelf(Ent, Mask, any:Hit)
	return Ent != Hit;