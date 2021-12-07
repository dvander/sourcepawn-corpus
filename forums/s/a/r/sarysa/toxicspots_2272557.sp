/**
 * Toxic Spots plugin
 * by sarysa
 *
 * You're free to do what you want with it. No warranty.
 *
 * Credits:
 * - sarysa wrote the plugin
 * - small bits/stocks came from FF2 (seeing how I've never used the Kv libs, I referenced FF2 a little for this)
 * - one of my stocks adapted from War3Source
 * - one stock taken from KissLick's code
 */

#include <sourcemod>
#include <tf2_stocks>
#include <tf2attributes>
#include <sdkhooks>
#include <sdktools>
#include <sdktools_functions>

#pragma semicolon 1

#define FAR_FUTURE 100000000.0
#define MAX_PLAYERS_ARRAY 36
#define MAX_PLAYERS (MAX_PLAYERS_ARRAY < (MaxClients + 1) ? MAX_PLAYERS_ARRAY : (MaxClients + 1))

#define COLOR_BUFFER_SIZE 12
#define MAX_CENTER_TEXT_LENGTH 256
#define MAX_ENTITY_CLASSNAME_LENGTH 48

#define LOGICAL_FLOAT_WIDTH 18
#define SIX_FLOAT_WIDTH ((LOGICAL_FLOAT_WIDTH+1) * 6)
#define THREE_FLOAT_WIDTH ((LOGICAL_FLOAT_WIDTH+1) * 3)

#define IsEmptyString(%1) (%1[0] == 0)

new Float:OFF_THE_MAP[3] = { 16383.0, 16383.0, -16383.0 };

new bool:PRINT_DEBUG_INFO = true;
new bool:PRINT_DEBUG_SPAM = false;

public Plugin:myinfo = {
	name = "FF2 Toxic Spots",
	author = "sarysa",
	version = "1.0.0",
}

/**
 * Toxic Spots
 */
#define MAX_MAPS 100
#define MAX_RECTS 10
new bool:TS_EnabledThisMap;
new BossTeam = -1;
new TS_LightColor;
new Float:TS_BaseDamage;
new Float:TS_BossDamage;
new Float:TS_BaseExp;
new Float:TS_MinAmmoLoss;
new Float:TS_MaxAmmoLoss;
new Float:TS_MedigunLoss;
new TS_BossGracePeriod;
new String:TS_MercMSG[MAX_CENTER_TEXT_LENGTH];
new String:TS_BossMSG[MAX_CENTER_TEXT_LENGTH];
new String:TS_SlayCenterText[MAX_CENTER_TEXT_LENGTH];
new String:TS_SlayGlobalMessage[MAX_CENTER_TEXT_LENGTH];

// map-specific
new TSM_RectCount;
new Float:TSM_NextCheckAt;
new Float:TSM_Coords[MAX_RECTS][2][3];
new Float:TSM_LightPoint[MAX_RECTS][3];
new Float:TSM_Luminosity[MAX_RECTS];
new bool:TSM_IsSlay[MAX_RECTS];

// player specific
new TSP_ViolationCount[MAX_PLAYERS_ARRAY];
new TSP_NoClipGraceCount[MAX_PLAYERS_ARRAY]; // needed to prevent accidental slay with noclip rages

public OnPluginStart()
{
	HookEvent("teamplay_round_start", TS_RoundStart);
	
	OnMapStart(); // in case this plugin is somehow loaded late
}

public TS_ReadInt(Handle:kv, const String:structName[], const String:keyName[], defaultValue)
{
	KvRewind(kv);
	if (!KvJumpToKey(kv, structName))
	{
		if (PRINT_DEBUG_SPAM)
			PrintToServer("[toxicspots] %s doesn't exist or is malformed.", structName);
		return defaultValue;
	}
	static String:hexOrDecString[12];
	KvGetString(kv, keyName, hexOrDecString, 12);
	if (IsEmptyString(hexOrDecString))
		return defaultValue;
	
	if (StrContains(hexOrDecString, "0x") == 0)
	{
		new result = 0;
		for (new i = 2; i < 10 && hexOrDecString[i] != 0; i++)
		{
			result = result<<4;
				
			if (hexOrDecString[i] >= '0' && hexOrDecString[i] <= '9')
				result += hexOrDecString[i] - '0';
			else if (hexOrDecString[i] >= 'a' && hexOrDecString[i] <= 'f')
				result += hexOrDecString[i] - 'a' + 10;
			else if (hexOrDecString[i] >= 'A' && hexOrDecString[i] <= 'F')
				result += hexOrDecString[i] - 'A' + 10;
		}
		
		return result;
	}
	else
		return StringToInt(hexOrDecString);
}

public Float:TS_ReadFloat(Handle:kv, const String:structName[], const String:keyName[], Float:defaultValue)
{
	KvRewind(kv);
	if (!KvJumpToKey(kv, structName))
	{
		if (PRINT_DEBUG_SPAM)
			PrintToServer("[toxicspots] %s doesn't exist or is malformed.", structName);
		return defaultValue;
	}
	return KvGetFloat(kv, keyName);
}

public TS_ReadString(Handle:kv, const String:structName[], const String:keyName[], String:str[], length)
{
	KvRewind(kv);
	if (!KvJumpToKey(kv, structName))
	{
		if (PRINT_DEBUG_SPAM)
			PrintToServer("[toxicspots] %s doesn't exist or is malformed.", structName);
		str[0] = 0;
		return;
	}
	KvGetString(kv, keyName, str, length);
	ReplaceString(str, length, "\\n", "\n");
}

public OnMapStart()
{
	TS_EnabledThisMap = false;

	// see if this map is in the config file
	static String:filePath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, filePath, PLATFORM_MAX_PATH, "configs/toxic_spots/toxic_spots.cfg");
	if (!FileExists(filePath))
	{
		PrintToServer("[toxicspots] ERROR: Config file is missing: %s", filePath);
		PrintToServer("[toxicspots] Will not run.");
		return;
	}
		
	// load kv file and start with the basic settings
	new Handle:kv = CreateKeyValues("");
	if (kv == INVALID_HANDLE)
		return;
	FileToKeyValues(kv, filePath);
	BossTeam = TS_ReadInt(kv, "settings", "bossteam", 3);
	TS_LightColor = TS_ReadInt(kv, "settings", "lightcolor", 0x000000);
	TS_BaseDamage = TS_ReadFloat(kv, "settings", "damage", 2.0);
	TS_BossDamage = TS_ReadFloat(kv, "settings", "bossdamage", 50.0);
	TS_BaseExp = TS_ReadFloat(kv, "settings", "damageexp", 1.3);
	TS_MinAmmoLoss = TS_ReadFloat(kv, "settings", "minammoloss", 0.95);
	TS_MaxAmmoLoss = TS_ReadFloat(kv, "settings", "maxammoloss", 0.10);
	TS_MedigunLoss = TS_ReadFloat(kv, "settings", "medigunloss", 0.1);
	TS_BossGracePeriod = TS_ReadInt(kv, "settings", "bossdelay", 10);
	TS_ReadString(kv, "settings", "mercmsg", TS_MercMSG, MAX_CENTER_TEXT_LENGTH);
	TS_ReadString(kv, "settings", "bossmsg", TS_BossMSG, MAX_CENTER_TEXT_LENGTH);
	TS_ReadString(kv, "settings", "slaymsg", TS_SlayCenterText, MAX_CENTER_TEXT_LENGTH);
	TS_ReadString(kv, "settings", "slayglobalmsg", TS_SlayGlobalMessage, MAX_CENTER_TEXT_LENGTH);
	
	// now see if this particular map is involved
	static String:thisMap[PLATFORM_MAX_PATH];
	GetCurrentMap(thisMap, PLATFORM_MAX_PATH);
	for (new mapIdx = 0; mapIdx < MAX_MAPS; mapIdx++)
	{
		static String:mapN[8];
		Format(mapN, sizeof(mapN), "map%d", mapIdx);
		KvRewind(kv);
		static String:testMap[PLATFORM_MAX_PATH];
		TS_ReadString(kv, mapN, "name", testMap, PLATFORM_MAX_PATH);
		if (!IsEmptyString(testMap) && StrContains(thisMap, testMap) == 0)
		{
			// read the toxic rect first
			static String:twoRectsStr[SIX_FLOAT_WIDTH];
			static String:oneRectStr[THREE_FLOAT_WIDTH];
			TSM_RectCount = 0;
			for (new rectIdx = 0; rectIdx < MAX_RECTS; rectIdx++)
			{
				static String:rectN[9];
				Format(rectN, sizeof(rectN), "rect%d", rectIdx);
				static String:lightN[10];
				Format(lightN, sizeof(lightN), "light%d", rectIdx);
				static String:luminosityN[15];
				Format(luminosityN, sizeof(luminosityN), "luminosity%d", rectIdx);
				static String:slayN[9];
				Format(slayN, sizeof(slayN), "slay%d", rectIdx);
				
				// only the collision rect is important
				TS_ReadString(kv, mapN, rectN, twoRectsStr, sizeof(twoRectsStr));
				if (strlen(twoRectsStr) < 11) // 11 is the minimum size of a properly formed 6 coords + delimeter 
				{
					if (PRINT_DEBUG_SPAM)
						PrintToServer("[toxicspots] Key %s/%s missing or truncated: %s", mapN, rectN, twoRectsStr);
					continue;
				}
				if (!TS_ParseCollisionRect(TSM_Coords[TSM_RectCount], twoRectsStr))
				{
					if (PRINT_DEBUG_INFO)
						PrintToServer("[toxicspots] Key %s/%s malformed, ignoring rect: %s", mapN, rectN, twoRectsStr);
					continue;
				}
				
				// but also parse the light coord and luminosity
				TS_ReadString(kv, mapN, lightN, oneRectStr, sizeof(oneRectStr));
				if (!TS_ParsePoint(TSM_LightPoint[TSM_RectCount], oneRectStr))
				{
					TSM_LightPoint[TSM_RectCount][0] = OFF_THE_MAP[0];
					TSM_LightPoint[TSM_RectCount][1] = OFF_THE_MAP[1];
					TSM_LightPoint[TSM_RectCount][2] = OFF_THE_MAP[2];
				}
				TSM_Luminosity[TSM_RectCount] = TS_ReadFloat(kv, mapN, luminosityN, 0.0);
				TSM_IsSlay[TSM_RectCount] = (TS_ReadInt(kv, mapN, slayN, 0) == 1);
				
				TSM_RectCount++;
				TS_EnabledThisMap = true;
			}
			break;
		}
		else if (PRINT_DEBUG_SPAM)
			PrintToServer("[toxicspots] Tested map %s which is different from current map %s", thisMap, testMap);
	}
	
	// that's it. close our handle.
	CloseHandle(kv);
	
	if (PRINT_DEBUG_INFO)
		PrintToServer("[toxicspots] %s execute on this map.", TS_EnabledThisMap ? "Will" : "Will not");
}

public bool:TS_ParseCollisionRect(Float:coords[2][3], const String:twoRectsStr[])
{
	static String:splitRectsStr[2][THREE_FLOAT_WIDTH];
	ExplodeString(twoRectsStr, ";", splitRectsStr, 2, THREE_FLOAT_WIDTH);
	if (IsEmptyString(splitRectsStr[0]) || IsEmptyString(splitRectsStr[1]))
		return false;
	
	for (new i = 0; i < 2; i++)
	{
		if (!TS_ParsePoint(coords[i], splitRectsStr[i]))
			return false;
	}
	
	return true;
}

public bool:TS_ParsePoint(Float:coords[3], const String:splitRectsStr[])
{
	static String:splitFloatsStr[3][LOGICAL_FLOAT_WIDTH];
	ExplodeString(splitRectsStr, ",", splitFloatsStr, 3, LOGICAL_FLOAT_WIDTH);
	if (IsEmptyString(splitFloatsStr[0]) || IsEmptyString(splitFloatsStr[1]) || IsEmptyString(splitFloatsStr[2]))
		return false;
		
	coords[0] = StringToFloat(splitFloatsStr[0]);
	coords[1] = StringToFloat(splitFloatsStr[1]);
	coords[2] = StringToFloat(splitFloatsStr[2]);
	return true;
}

public TS_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!TS_EnabledThisMap)
		return;
	
	TSM_NextCheckAt = GetEngineTime();
	for (new clientIdx = 1; clientIdx < MAX_PLAYERS; clientIdx++)
	{
		TSP_ViolationCount[clientIdx] = 0;
	}
	
	// spawn light objects
	for (new rectIdx = 0; rectIdx < TSM_RectCount && rectIdx < MAX_RECTS; rectIdx++)
	{
		if (TSM_LightPoint[rectIdx][0] == OFF_THE_MAP[0] || TSM_Luminosity[rectIdx] <= 0.0)
			continue; // invalid
	
		new dynLight = CreateEntityByName("light_dynamic");
		if (IsValidEntity(dynLight))
		{
			DispatchKeyValueFormat(dynLight, "_light", "%d %d %d", GetR(TS_LightColor), GetG(TS_LightColor), GetB(TS_LightColor)); 
			DispatchKeyValue(dynLight, "brightness", "5"); 
			DispatchKeyValue(dynLight, "style", "1");
			DispatchKeyValueFloat(dynLight, "distance", TSM_Luminosity[rectIdx]);
		}
		
		TeleportEntity(dynLight, TSM_LightPoint[rectIdx], NULL_VECTOR, NULL_VECTOR);
		DispatchSpawn(dynLight); 
	}
}

public OnGameFrame()
{
	if (!TS_EnabledThisMap)
		return;
		
	new Float:curTime = GetEngineTime();
	if (curTime >= TSM_NextCheckAt)
	{
		// first iterate through and find violators
		static bool:violators[MAX_PLAYERS_ARRAY];
		static bool:isSlay[MAX_PLAYERS_ARRAY];
		new bool:mercsViolated = false;
		for (new clientIdx = 1; clientIdx < MAX_PLAYERS; clientIdx++)
		{
			if (!IsLivingPlayer(clientIdx))
			{
				violators[clientIdx] = false;
				continue;
			}

			// do not harm someone whose movetype is noclip. also, give them a brief grace in the event of teleport lag.
			if (GetEntProp(clientIdx, Prop_Send, "movetype") == any:MOVETYPE_NOCLIP)
			{
				TSP_NoClipGraceCount[clientIdx] = 1;
				violators[clientIdx] = false;
				continue;
			}
			else if (TSP_NoClipGraceCount[clientIdx] > 0)
			{
				TSP_NoClipGraceCount[clientIdx]--;
				violators[clientIdx] = false;
				continue;
			}
			
			static Float:clientPos[3];
			GetEntPropVector(clientIdx, Prop_Send, "m_vecOrigin", clientPos);
			for (new rectIdx = 0; rectIdx < TSM_RectCount && rectIdx < MAX_RECTS; rectIdx++)
			{
				violators[clientIdx] = (clientPos[0] >= fmin(TSM_Coords[rectIdx][0][0], TSM_Coords[rectIdx][1][0]) &&
							clientPos[0] <= fmax(TSM_Coords[rectIdx][0][0], TSM_Coords[rectIdx][1][0]) &&
							clientPos[1] >= fmin(TSM_Coords[rectIdx][0][1], TSM_Coords[rectIdx][1][1]) &&
							clientPos[1] <= fmax(TSM_Coords[rectIdx][0][1], TSM_Coords[rectIdx][1][1]) &&
							clientPos[2] >= fmin(TSM_Coords[rectIdx][0][2], TSM_Coords[rectIdx][1][2]) &&
							clientPos[2] <= fmax(TSM_Coords[rectIdx][0][2], TSM_Coords[rectIdx][1][2]));
				
				if (violators[clientIdx])
				{
					if (GetClientTeam(clientIdx) != BossTeam)
						mercsViolated = true;
					isSlay[clientIdx] = TSM_IsSlay[rectIdx];
					break;
				}
			}
		}
		
		// now iterate through again, add the violation and punish if appropriate
		for (new clientIdx = 1; clientIdx < MAX_PLAYERS; clientIdx++)
		{
			if (violators[clientIdx])
			{
				// do not punish the hale if mercs are in the bannable spot
				if (GetClientTeam(clientIdx) == BossTeam && mercsViolated)
					continue;
				
				// slay is the ruthless option
				if (isSlay[clientIdx])
				{
					ForcePlayerSuicide(clientIdx);
					PrintCenterText(clientIdx, TS_SlayCenterText);
					static String:cheater[128];
					GetClientName(clientIdx, cheater, sizeof(cheater));
					static String:cheaterId[128];
					GetClientAuthString(clientIdx, cheaterId, sizeof(cheaterId));
					PrintToChatAll(TS_SlayGlobalMessage, cheater, cheaterId);
					continue;
				}
				
				TSP_ViolationCount[clientIdx]++;
				new actualViolations = (GetClientTeam(clientIdx) == BossTeam) ? (TSP_ViolationCount[clientIdx] - TS_BossGracePeriod) : TSP_ViolationCount[clientIdx];
				if (actualViolations > 0)
				{
					// mess with ammo and metal first, then medigun charge...finally damage
					if (GetClientTeam(clientIdx) != BossTeam)
					{
						// ammo loss is inverse, so this is correct
						new Float:ammoDrain = TS_MaxAmmoLoss + ((TS_MinAmmoLoss - TS_MaxAmmoLoss) * (1.0 - (min(20, actualViolations) / 20.0)));
						ammoDrain = fmax(0.0, ammoDrain);
						if (ammoDrain < 1.0)
						{
							for (new slot = 0; slot < 2; slot++)
							{
								new weapon = GetPlayerWeaponSlot(clientIdx, slot);
								if (!IsValidEntity(weapon))
									continue;
									
								new offset = GetEntProp(weapon, Prop_Send, "m_iPrimaryAmmoType", 1);
								if (offset < 0)
									continue;
								else if (GetEntProp(clientIdx, Prop_Send, "m_iAmmo", 4, offset) <= 1)
									continue; // workaround for not breaking lunchbox items
								SetEntProp(clientIdx, Prop_Send, "m_iAmmo", RoundFloat(GetEntProp(clientIdx, Prop_Send, "m_iAmmo", 4, offset) * ammoDrain), 4, offset);
							}
							
							// if it's an engineer, drain metal
							if (TF2_GetPlayerClass(clientIdx) == TFClass_Engineer)
							{
								new metalOffset = FindDataMapOffs(clientIdx, "m_iAmmo") + (3 * 4);
								SetEntData(clientIdx, metalOffset, RoundFloat(GetEntData(clientIdx, metalOffset, 4) * ammoDrain), 4);
							}
						}

						// next, medigun charge
						if (TF2_GetPlayerClass(clientIdx) == TFClass_Medic)
						{
							new medigun = GetPlayerWeaponSlot(clientIdx, TFWeaponSlot_Secondary);
							if (IsValidEntity(medigun) && IsInstanceOf(medigun, "tf_weapon_medigun"))
								SetEntPropFloat(medigun, Prop_Send, "m_flChargeLevel", fmax(0.0, GetEntPropFloat(medigun, Prop_Send, "m_flChargeLevel") - TS_MedigunLoss));
						}
					}
					
					// print warning
					PrintCenterText(clientIdx, TS_MercMSG);
					PrintToChat(clientIdx, TS_MercMSG);
					
					// finally, the damage hit
					new Float:damage = GetClientTeam(clientIdx) == BossTeam ? TS_BossDamage : TS_BaseDamage;
					if (TS_BaseExp > 1.0)
						damage = Pow(damage, 1.0 + ((TS_BaseExp - 1.0) * float(actualViolations)));
						
					// boss team must get attacked by a player, or you risk triggering env damage mechanics
					if (GetClientTeam(clientIdx) == BossTeam)
					{
						new damagetype = DMG_PREVENT_PHYSICS_FORCE;
						if (damage >= 50.0)
						{
							// time to REALLY get their attention
							damage /= 3.0;
							damagetype = DMG_CRIT | DMG_PREVENT_PHYSICS_FORCE;
						}
						new attacker = FindRandomPlayer(false);
						if (IsLivingPlayer(attacker))
							FullyHookedDamage(clientIdx, attacker, attacker, damage, damagetype, -1);
					}
					else // hit self
						SDKHooks_TakeDamage(clientIdx, clientIdx, clientIdx, damage, DMG_PREVENT_PHYSICS_FORCE, -1);
				}
				else
				{
					PrintCenterText(clientIdx, TS_BossMSG, -actualViolations + 1);
					PrintToChat(clientIdx, TS_BossMSG, -actualViolations + 1);
				}
			}
		}
	
		TSM_NextCheckAt += 1.0;
	}
}

stock FindRandomPlayer(bool:isBossTeam)
{
	new player = -1;

	// first, get a player count for the team we care about
	new playerCount = 0;
	for (new clientIdx = 0; clientIdx < MAX_PLAYERS; clientIdx++)
	{
		if (!IsLivingPlayer(clientIdx))
			continue;

		if ((isBossTeam && GetClientTeam(clientIdx) == BossTeam) || (!isBossTeam && GetClientTeam(clientIdx) != BossTeam))
			playerCount++;
	}

	// ensure there's at least one living valid player
	if (playerCount <= 0)
		return -1;

	// now randomly choose our victim
	new rand = GetRandomInt(0, playerCount - 1);
	playerCount = 0;
	for (new clientIdx = 0; clientIdx < MAX_PLAYERS; clientIdx++)
	{
		if (!IsLivingPlayer(clientIdx))
			continue;

		if ((isBossTeam && GetClientTeam(clientIdx) == BossTeam) || (!isBossTeam && GetClientTeam(clientIdx) != BossTeam))
		{
			if (playerCount == rand) // needed if rand is 0
			{
				player = clientIdx;
				break;
			}
			playerCount++;
			if (playerCount == rand) // needed if rand is playerCount - 1, executes for all others except 0
			{
				player = clientIdx;
				break;
			}
		}
	}
	
	return player;
}

stock bool:IsLivingPlayer(clientIdx)
{
	if (clientIdx <= 0 || clientIdx >= MAX_PLAYERS)
		return false;
		
	return IsClientInGame(clientIdx) && IsPlayerAlive(clientIdx);
}

stock GetA(c) { return abs(c>>24); }
stock GetR(c) { return abs((c>>16)&0xff); }
stock GetG(c) { return abs((c>>8 )&0xff); }
stock GetB(c) { return abs((c    )&0xff); }

stock ColorToDecimalString(String:buffer[COLOR_BUFFER_SIZE], rgb)
{
	Format(buffer, COLOR_BUFFER_SIZE, "%d %d %d", GetR(rgb), GetG(rgb), GetB(rgb));
}

stock abs(x)
{
	return x < 0 ? -x : x;
}

stock Float:fabs(Float:x)
{
	return x < 0 ? -x : x;
}

stock min(n1, n2)
{
	return n1 < n2 ? n1 : n2;
}

stock Float:fmin(Float:n1, Float:n2)
{
	return n1 < n2 ? n1 : n2;
}

stock max(n1, n2)
{
	return n1 > n2 ? n1 : n2;
}

stock Float:fmax(Float:n1, Float:n2)
{
	return n1 > n2 ? n1 : n2;
}

public Action:RemoveEntity(Handle:timer, any:entid)
{
	new entity = EntRefToEntIndex(entid);
	if (IsValidEdict(entity) && entity > MaxClients)
	{
		TeleportEntity(entity, OFF_THE_MAP, NULL_VECTOR, NULL_VECTOR); // send it away first in case it feels like dying dramatically
		AcceptEntityInput(entity, "Kill");
	}
}

stock bool:IsInstanceOf(entity, const String:desiredClassname[])
{
	static String:classname[MAX_ENTITY_CLASSNAME_LENGTH];
	GetEntityClassname(entity, classname, MAX_ENTITY_CLASSNAME_LENGTH);
	return strcmp(classname, desiredClassname) == 0;
}

stock FullyHookedDamage(victim, inflictor, attacker, Float:damage, damageType=DMG_GENERIC, weapon=-1, Float:attackPos[3] = NULL_VECTOR)
{
	static String:dmgStr[16];
	IntToString(RoundFloat(damage), dmgStr, sizeof(dmgStr));

	// took this from war3...I hope it doesn't double damage like I've heard old versions do
	new pointHurt = CreateEntityByName("point_hurt");
	if (IsValidEntity(pointHurt))
	{
		DispatchKeyValue(victim, "targetname", "halevictim");
		DispatchKeyValue(pointHurt, "DamageTarget", "halevictim");
		DispatchKeyValue(pointHurt, "Damage", dmgStr);
		DispatchKeyValueFormat(pointHurt, "DamageType", "%d", damageType);

		DispatchSpawn(pointHurt);
		if (!(attackPos[0] == NULL_VECTOR[0] && attackPos[1] == NULL_VECTOR[1] && attackPos[2] == NULL_VECTOR[2]))
		{
			TeleportEntity(pointHurt, attackPos, NULL_VECTOR, NULL_VECTOR);
		}
		else if (IsLivingPlayer(attacker))
		{
			static Float:attackerOrigin[3];
			GetEntPropVector(attacker, Prop_Send, "m_vecOrigin", attackerOrigin);
			TeleportEntity(pointHurt, attackerOrigin, NULL_VECTOR, NULL_VECTOR);
		}
		AcceptEntityInput(pointHurt, "Hurt", attacker);
		DispatchKeyValue(pointHurt, "classname", "point_hurt");
		DispatchKeyValue(victim, "targetname", "noonespecial");
		RemoveEntity(INVALID_HANDLE, EntIndexToEntRef(pointHurt));
	}
}

// stole this stock from KissLick. it's a good stock!
stock DispatchKeyValueFormat(entity, const String:keyName[], const String:format[], any:...)
{
	static String:value[256];
	VFormat(value, sizeof(value), format, 4);

	DispatchKeyValue(entity, keyName, value);
} 
