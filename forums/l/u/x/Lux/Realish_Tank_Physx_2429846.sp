#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
//#include <smlib>

#define PLUGIN_VERSION "1.2"

public Plugin:myinfo =
{
	name = "Realish_Tank_Phyx",
	author = "Ludastar (Armonic)",
	description = "Add's knockback to all attacks to survivor's from tanks",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?p=2429846#post2429846"
};

static ZOMBIECLASS_TANK;
static bool:g_bAllowHurt = false;
static bool:g_bIsMapRunning = false;

static bool:g_bRockPhyx = false;
static bool:g_bIncapKnockBack = false;
static bool:g_bKnockBackPreIncap = false;
static Float:g_fRockForce = 666.6;

static Handle:hCvar_RockPhyx = INVALID_HANDLE;
static Handle:hCvar_IncapKnockBack = INVALID_HANDLE;
static Handle:hCvar_KnockBackPreIncap = INVALID_HANDLE;
static Handle:hCvar_fRockForce = INVALID_HANDLE;

static bool:bHitByRock[MAXPLAYERS+1];

#define ENABLE_AUTOEXEC true

public OnPluginStart()
{
	decl String:sGameName[12];
	GetGameFolderName(sGameName, sizeof(sGameName));
	if(StrEqual(sGameName, "left4dead"))
	ZOMBIECLASS_TANK = 5;
	else if(StrEqual(sGameName, "left4dead2"))
	ZOMBIECLASS_TANK = 8;
	else
	SetFailState("This plugin only runs on Left 4 Dead and Left 4 Dead 2!");
	
	CreateConVar("Realish_Tank_Phyx", PLUGIN_VERSION, "Version of Realish_Tank_Phyxs", FCVAR_SPONLY|FCVAR_DONTRECORD|FCVAR_NOTIFY|FCVAR_REPLICATED|FCVAR_SPONLY|FCVAR_PLUGIN);
	
	hCvar_RockPhyx = CreateConVar("rtp_rockphyx", "1", "Enable or Disable RockPhyx", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	hCvar_IncapKnockBack = CreateConVar("rtp_incapknockBack", "1", "Enable or Disable Incapped slap", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	hCvar_KnockBackPreIncap = CreateConVar("rtp_KnockBackPreIncap", "1", "Enable or Disable Pre incapped flying", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	hCvar_fRockForce = CreateConVar("rtp_rockforce", "800.0", "Force of the rock, very high values send you flying very fast&far", FCVAR_NOTIFY, true, 1.0, true, 2147483647.0);
	
	HookConVarChange(hCvar_RockPhyx, eConvarChanged);
	HookConVarChange(hCvar_IncapKnockBack, eConvarChanged);
	HookConVarChange(hCvar_KnockBackPreIncap, eConvarChanged);
	HookConVarChange(hCvar_fRockForce, eConvarChanged);
	
	HookEvent("round_start", eRoundStart, EventHookMode_PostNoCopy);
	
	#if ENABLE_AUTOEXEC
	AutoExecConfig(true, "Realish_Tank_Phyx");
	#endif
	
	CvarsChanged();
}

static CvarsChanged()
{
	g_bRockPhyx = GetConVarInt(hCvar_RockPhyx) > 0;
	g_bIncapKnockBack = GetConVarInt(hCvar_IncapKnockBack) > 0;
	g_bKnockBackPreIncap = GetConVarInt(hCvar_KnockBackPreIncap) > 0;
	g_fRockForce = GetConVarFloat(hCvar_fRockForce);
}

public Action:eOnTakeDamage(iVictim, &iAttacker, &iInflictor, &Float:fDamage, &iDamagetype)
{
	if(!g_bRockPhyx && !g_bIncapKnockBack && !g_bKnockBackPreIncap)
	return Plugin_Continue;
	
	if(g_bAllowHurt)
	return Plugin_Continue;
	
	if(iAttacker < 1 || iAttacker > MaxClients || !IsClientInGame(iAttacker) || GetClientTeam(iAttacker) != 3 || GetEntProp(iAttacker, Prop_Send, "m_zombieClass") != ZOMBIECLASS_TANK)
	return Plugin_Continue;
	
	if(!IsSurvivorAlive(iVictim))
	return Plugin_Continue;
	
	
	decl String:sWeapon[18];//we use decl because it is faster for arrays but can crash server you can use sizeof to null the string if what ever you get is empty, we only need 18array size for weapon_tank_claw because that is the longest string lengh we check.
	if(g_bRockPhyx)
	{
		GetEntityClassname(iInflictor, sWeapon, sizeof(sWeapon));
		if(sWeapon[0] == 't' && StrEqual(sWeapon, "tank_rock", false))
		{
			bHitByRock[iVictim] = true;
			decl Float:fPos[3];
			GetEntPropVector(iVictim, Prop_Send, "m_vecOrigin", fPos);
			new Handle:trace = TR_TraceRayFilterEx(fPos, Float:{-90.0, 0.0, 0.0}, MASK_SHOT, RayType_Infinite, _TraceFilter);
			
			decl Float:fEnd[3];
			TR_GetEndPosition(fEnd, trace); // retrieve our trace endpoint
			CloseHandle(trace);
			
			new Float:fDist = GetVectorDistance(fPos, fEnd);
			
			if(fDist > 150.0)
			{
				fPos[2] += 40.0;
				TeleportEntity(iVictim, fPos, NULL_VECTOR, NULL_VECTOR);
			}
			else if(fDist > 125.0)
			{
				fPos[2] += 25.0;
				TeleportEntity(iVictim, fPos, NULL_VECTOR, NULL_VECTOR);
			}
		}
	}
	
	GetClientWeapon(iAttacker, sWeapon, sizeof(sWeapon));// i do a classname check so it will work on l4d1 also
	if(StrContains(sWeapon, "tank_claw", false) == -1)// for l4d1 support also
	return Plugin_Continue;
	
	static iIncaps;
	iIncaps = GetEntProp(iVictim, Prop_Send, "m_currentReviveCount");
	
	static iHealth;
	
	static iDamage;
	iDamage = RoundFloat(fDamage);
	
	if(GetEntProp(iVictim, Prop_Send, "m_isIncapacitated", 1))
	{
		if(!g_bIncapKnockBack)
		return Plugin_Continue;
		
		static bThirdStrike;
		if(ZOMBIECLASS_TANK != 5)
		bThirdStrike = GetEntProp(iVictim, Prop_Send, "m_bIsOnThirdStrike", 1);
		else
		bThirdStrike = GetEntProp(iVictim, Prop_Send, "m_isGoingToDie", 1);
		
		iHealth = GetEntProp(iVictim, Prop_Send, "m_iHealth");
		
		SetEntProp(iVictim, Prop_Send, "m_isIncapacitated", 0, 1);
		SetEntProp(iVictim, Prop_Send, "m_currentReviveCount", iIncaps);
		SetEntProp(iVictim, Prop_Send, "m_iHealth", 999);
		
		new Handle:hPack = CreateDataPack();
		WritePackCell(hPack, iVictim);
		WritePackCell(hPack, true);
		WritePackCell(hPack, iDamage);
		WritePackCell(hPack, iAttacker);
		WritePackCell(hPack, iIncaps);
		WritePackCell(hPack, iHealth);
		WritePackCell(hPack, bThirdStrike);
		
		RequestFrame(NextFrame, hPack);
		return Plugin_Handled;
	}
	else
	{
		if(!g_bKnockBackPreIncap)
		return Plugin_Continue;
		
		iHealth = L4D_GetPlayerTempHealth(iVictim) + GetEntProp(iVictim, Prop_Send, "m_iHealth");
		
		if(iHealth > iDamage)
		return Plugin_Continue;
		
		new Handle:hPack = CreateDataPack();
		WritePackCell(hPack, iVictim);
		WritePackCell(hPack, false);
		WritePackCell(hPack, iDamage);
		WritePackCell(hPack, iAttacker);
		
		RequestFrame(NextFrame, hPack);
		return Plugin_Handled;
	}
}

public NextFrame(any:hPack)
{
	ResetPack(hPack);
	new iVictim = ReadPackCell(hPack);
	
	if(!IsSurvivorAlive(iVictim))
	{
		CloseHandle(hPack);
		return;
	}
	
	new bool:IsIncapped = ReadPackCell(hPack);
	new iDamage = ReadPackCell(hPack);
	new iAttacker = ReadPackCell(hPack);
	
	if(iAttacker < 1 || iAttacker > MaxClients || !IsClientInGame(iAttacker))
	iAttacker = 0;
	
	if(IsIncapped)
	{
		new iIncaps = ReadPackCell(hPack);
		new iHealth = ReadPackCell(hPack);
		new bThirdStrike = ReadPackCell(hPack);// for people who use plugins that set the thirdstrike while incapped like i do after being hit by the witch
		
		SetEntProp(iVictim, Prop_Send, "m_isIncapacitated", 1, 1);
		SetEntProp(iVictim, Prop_Send, "m_currentReviveCount", iIncaps);
		
		if(ZOMBIECLASS_TANK != 5)
		SetEntProp(iVictim, Prop_Send, "m_bIsOnThirdStrike", bThirdStrike, 1);
		else
		SetEntProp(iVictim, Prop_Send, "m_isGoingToDie", bThirdStrike, 1);
		
		if(iHealth > iDamage)
		{
			SetEntProp(iVictim, Prop_Send, "m_iHealth", (iHealth - iDamage));
		}
		else
		{
			
			SetEntProp(iVictim, Prop_Send, "m_iHealth", iHealth);
			g_bAllowHurt = true;
			Entity_Hurt(iVictim, iDamage, iAttacker, DMG_VEHICLE);// we use the point hurt here for better perf only to kill the client, THE TANK NEEDS KILLS TOO :D
			g_bAllowHurt = false;
		}
		
	}
	else
	{
		g_bAllowHurt = true;
		Entity_Hurt(iVictim, iDamage, iAttacker, DMG_VEHICLE);//we use point hurt here to prevent anybugs so we use the normal damage system instead
		g_bAllowHurt = false;// prevent endless loop with sdkhooks
	}
	
	CloseHandle(hPack);
}

public OnEntityDestroyed(iEntity)
{
	if(!IsServerProcessing() || !g_bIsMapRunning)
	return;
	
	if(!g_bRockPhyx || !IsValidEntity(iEntity))
	return;
	
	static String:sClassname[11];
	GetEntityClassname(iEntity, sClassname, sizeof(sClassname));
	
	if(sClassname[0] != 't' || !StrEqual(sClassname, "tank_rock", false))
	return;
	
	for(new i = 1; i <= MaxClients;i++)
	{
		if(!IsClientInGame(i) || !bHitByRock[i])
		continue;
		
		static Float:fClient[3];
		GetEntPropVector(i, Prop_Send, "m_vecOrigin", fClient);
		
		static Float:fRockPos[3];
		GetEntPropVector(iEntity, Prop_Send, "m_vecOrigin", fRockPos);
		
		static Float:fAngles[3];
		static Float:fAimVector[3];
		MakeVectorFromPoints(fRockPos, fClient, fAimVector);
		GetVectorAngles(fAimVector, fAngles);
		
		if(fAngles[0] < 270.0)
		fAngles[0] = 360.0;
		if(fAngles[0] < 330.0)
		fAngles[0] = 330.0;
		
		Entity_PushForce(i, g_fRockForce, fAngles, 0.0, false); //this does not seem to work in OnTakeDamage hook but works here quite strange
		bHitByRock[i] = false;
	}
}

static IsSurvivorAlive(iClient)
{
	if(iClient < 1 || iClient > MaxClients || !IsClientInGame(iClient) || GetClientTeam(iClient) != 2 || !IsPlayerAlive(iClient))
	return false;
	
	return true;
}

static bool:Entity_Hurt(entity, damage, attacker=0, damageType=DMG_GENERIC, const String:fakeClassName[]="")
{
	static point_hurt = INVALID_ENT_REFERENCE;
	
	if (point_hurt == INVALID_ENT_REFERENCE || !IsValidEntity(point_hurt)) {
		point_hurt = EntIndexToEntRef(Entity_Create("point_hurt"));
		
		if (point_hurt == INVALID_ENT_REFERENCE) {
			return false;
		}
		
		DispatchSpawn(point_hurt);
	}
	
	AcceptEntityInput(point_hurt, "TurnOn");
	SetEntProp(point_hurt, Prop_Data, "m_nDamage", damage);
	SetEntProp(point_hurt, Prop_Data, "m_bitsDamageType", damageType);
	Entity_PointHurtAtTarget(point_hurt, entity);
	
	if (fakeClassName[0] != '\0') {
		Entity_SetClassName(point_hurt, fakeClassName);
	}
	
	AcceptEntityInput(point_hurt, "Hurt", attacker);
	AcceptEntityInput(point_hurt, "TurnOff");
	
	if (fakeClassName[0] != '\0') {
		Entity_SetClassName(point_hurt, "point_hurt");
	}
	
	return true;
}

static Entity_Create(const String:className[], ForceEdictIndex=-1)
{
	if (ForceEdictIndex != -1 && IsValidEntity(ForceEdictIndex)) {
		return INVALID_ENT_REFERENCE;
	}
	
	return CreateEntityByName(className, ForceEdictIndex);
}

static Entity_PointHurtAtTarget(entity, target, const String:name[]="")
{
	decl String:targetName[128];
	Entity_GetTargetName(entity, targetName, sizeof(targetName));
	
	if (name[0] == '\0') {
		
		if (targetName[0] == '\0') {
			// Let's generate our own name
			Format(
					targetName,
					sizeof(targetName),
					"_smlib_Entity_PointHurtAtTarget:%d",
					target
					);
		}
	}
	else {
		strcopy(targetName, sizeof(targetName), name);
	}
	
	DispatchKeyValue(entity, "DamageTarget", targetName);
	Entity_SetName(target, targetName);
}

static Entity_SetName(entity, const String:name[], any:...)
{
	decl String:format[128];
	VFormat(format, sizeof(format), name, 3);
	
	return DispatchKeyValue(entity, "targetname", format);
}

static Entity_GetTargetName(entity, String:buffer[], size)
{
	return GetEntPropString(entity, Prop_Data, "m_target", buffer, size);
}

static Entity_SetClassName(entity, const String:className[])
{
	return DispatchKeyValue(entity, "classname", className);
}

static L4D_GetPlayerTempHealth(client)
{
	static Handle:painPillsDecayCvar = INVALID_HANDLE;
	if (painPillsDecayCvar == INVALID_HANDLE)
	{
		painPillsDecayCvar = FindConVar("pain_pills_decay_rate");
		if (painPillsDecayCvar == INVALID_HANDLE)
		{
			return -1;
		}
	}
	
	new tempHealth = RoundToCeil(GetEntPropFloat(client, Prop_Send, "m_healthBuffer") - ((GetGameTime() - GetEntPropFloat(client, Prop_Send, "m_healthBufferTime")) * GetConVarFloat(painPillsDecayCvar))) - 1;
	return tempHealth < 0 ? 0 : tempHealth;
}

public bool:_TraceFilter(iEntity, contentsMask)
{
	decl String:sClassName[11];
	GetEntityClassname(iEntity, sClassName, sizeof(sClassName));
	
	if(sClassName[0] != 'i' || !StrEqual(sClassName, "infected"))
	{
		return false;
	}
	else if(sClassName[0] != 'w' || !StrEqual(sClassName, "witch"))
	{
		return false;
	}
	else if(iEntity > 0 && iEntity <= MaxClients)
	{
		return false;
	}
	return true;
	
}

public OnClientPutInServer(iClient)
{
	SDKHook(iClient, SDKHook_OnTakeDamage, eOnTakeDamage);
}

public OnMapStart()
{
	g_bIsMapRunning = true;
}

public OnMapEnd()
{
	g_bIsMapRunning = false;
}

public eConvarChanged(Handle:hCvar, const String:sOldVal[], const String:sNewVal[])
{
	CvarsChanged();
}

static Entity_PushForce(iEntity, Float:fForce, Float:fAngles[3], Float:fMax=0.0, bool:bAdd=false)
{
	static Float:fVelocity[3];
	
	fVelocity[0] = fForce * Cosine(DegToRad(fAngles[1])) * Cosine(DegToRad(fAngles[0]));
	fVelocity[1] = fForce * Sine(DegToRad(fAngles[1])) * Cosine(DegToRad(fAngles[0]));
	fVelocity[2] = fForce * Sine(DegToRad(fAngles[0]));
	
	GetAngleVectors(fAngles, fVelocity, NULL_VECTOR, NULL_VECTOR);
	NormalizeVector(fVelocity, fVelocity);
	ScaleVector(fVelocity, fForce);
	
	if(bAdd) {
		static Float:fMainVelocity[3];
		GetEntPropVector(iEntity, Prop_Data, "m_vecAbsVelocity", fMainVelocity);
		
		fVelocity[0] += fMainVelocity[0];
		fVelocity[1] += fMainVelocity[1];
		fVelocity[2] += fMainVelocity[2];
	}
	
	if(fMax > 0.0) {
		fVelocity[0] = ((fVelocity[0] > fMax) ? fMax : fVelocity[0]);
		fVelocity[1] = ((fVelocity[1] > fMax) ? fMax : fVelocity[1]);
		fVelocity[2] = ((fVelocity[2] > fMax) ? fMax : fVelocity[2]);
	}
	
	TeleportEntity(iEntity, NULL_VECTOR, NULL_VECTOR, fVelocity);
}

public eRoundStart(Handle:hEvent, const String:sEventName[], bool:bDontBroadcast)
{
	for(new i = 1;i <= MaxClients; i++)
	{
		bHitByRock[i] = false;
	}
}

public OnClientDisconnect(iClient)
{
	bHitByRock[iClient] = false;
}
