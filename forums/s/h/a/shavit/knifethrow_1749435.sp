// if lemurs had knives,
// they would throw them!

#include <sourcemod>
#include <sdktools>
#include <hosties>
#include <lastrequest>
#include <cstrike>

#define NAME "CSS Throwing Knives"
#define VERSION "1.2.2b"
#define KNIFE_MDL "models/weapons/w_knife_ct.mdl"
#define KNIFEHIT_SOUND "weapons/knife/knife_hit3.wav"
#define TRAIL_MDL "materials/sprites/lgtning.vmt"
#define TRAIL_COLOR {177, 177, 177, 117}
#define ADD_OUTPUT "OnUser1 !self:Kill::1.5:1"
#define COUNT_TXT "%i :וראשנש םיניכס"

new Handle:g_CVarEnable;
new Handle:g_CVarEnableDev;
new bool:g_bDev;
new Handle:g_hLethalArray;
new Handle:g_CVarVelocity;
new Float:g_fVelocity;
new Handle:g_CVarKnives;
new Handle:g_CVarDamage;
new String:g_sDamage[8];
new Handle:g_CVarHSDamage;
new String:g_sHSDamage[8];
new Handle:g_CVarSteal;
new Handle:g_CVarTrail;
new bool:g_bTrail;
new Handle:g_CVarNoBlock;
new bool:g_bNoBlock;
new Handle:g_CVarDisplay;
new g_WeaponParent;
new g_iDisplay;
new Handle:g_CVarFF;
new const Float:g_fSpin[3] = {4877.4, 0.0, 0.0};
new const Float:g_fMinS[3] = {-24.0, -24.0, -24.0};
new const Float:g_fMaxS[3] = {24.0, 24.0, 24.0};
new bool:boolean = false;
new bool:boolean2 = false;
new g_iKnives[MAXPLAYERS+1];
new g_iKnifeMI;
new g_iPointHurt;
new g_iEnvBlood;
new g_iTrailMI;
new Handle:g_hKTForward;
new Handle:g_hKHForward;
new Handle:g_hKKForward;

public Plugin:myinfo = {

	name = NAME,
	author = "meng [Jailbreak version by TimeBomb]",
	version = VERSION,
	description = "Throwing knives for CSS",
	url = "http://www.sourcemod.net"
};

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max) {

	CreateNative("SetClientThrowingKnives", NativeSetClientThrowingKnives);
	CreateNative("GetClientThrowingKnives", NativeGetClientThrowingKnives);
	RegPluginLibrary("cssthrowingknives");
	return APLRes_Success;
}

public OnPluginStart() {

	CreateConVar("sm_cssthrowingknives", VERSION, NAME, FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	g_CVarEnable = CreateConVar("sm_throwingknives_enable", "0", "Enable/disable plugin.", _, true, 0.0, true, 1.0);
	g_CVarEnableDev = CreateConVar("sm_throwingknives_dev", "0", "Enable/disable dev. mode.", _, true, 0.0, true, 1.0);
	g_CVarVelocity = CreateConVar("sm_throwingknives_velocity", "5", "Velocity (speed) adjustment.", _, true, 1.0, true, 10.0);
	g_CVarKnives = CreateConVar("sm_throwingknives_count", "200", "Amount of knives players spawn with.", _, true, 0.0, true, 200.0);
	g_CVarDamage = CreateConVar("sm_throwingknives_damage", "57", "Damage adjustment.", _, true, 10.0, true, 200.0);
	g_CVarHSDamage = CreateConVar("sm_throwingknives_hsdamage", "127", "Headshot damage adjustment.", _, true, 20.0, true, 200.0);
	g_CVarSteal = CreateConVar("sm_throwingknives_steal", "1", "If enabled, knife kills get the victims remaining knives. 0 = Disabled | 1 = Melee kills only | 2 = All knife kills", _, true, 0.0, true, 2.0);
	g_CVarTrail = CreateConVar("sm_throwingknives_trail", "1", "Enable/disable trail effect.", _, true, 0.0, true, 1.0);
	g_CVarNoBlock = CreateConVar("sm_throwingknives_noblock", "1", "Set to \"1\" if using noblock for players.", _, true, 0.0, true, 1.0);
	g_CVarDisplay = CreateConVar("sm_throwingknives_display", "2", "Knives remaining display location. 1 = Hint | 2 = Key Hint", _, true, 1.0, true, 2.0);
	g_CVarFF = FindConVar("mp_friendlyfire");
	RegAdminCmd("sm_kt", Command_KT, ADMFLAG_GENERIC, "Knife throw menu");
	RegAdminCmd("sm_knifethrow", Command_KT, ADMFLAG_GENERIC, "Knife throw menu");
	
	// initialize global vars, hook CVar changes
	HookConVarChange(g_CVarEnable, CVarChange);
	g_fVelocity = (1000.0 + (250.0 * GetConVarFloat(g_CVarVelocity)));
	HookConVarChange(g_CVarVelocity, CVarChange);
	GetConVarString(g_CVarDamage, g_sDamage, sizeof(g_sDamage));
	HookConVarChange(g_CVarDamage, CVarChange);
	GetConVarString(g_CVarHSDamage, g_sHSDamage, sizeof(g_sHSDamage));
	HookConVarChange(g_CVarHSDamage, CVarChange);
	g_bTrail = GetConVarBool(g_CVarTrail);
	HookConVarChange(g_CVarTrail, CVarChange);
	g_bNoBlock = GetConVarBool(g_CVarNoBlock);
	HookConVarChange(g_CVarNoBlock, CVarChange);
	g_iDisplay = GetConVarInt(g_CVarDisplay);
	HookConVarChange(g_CVarDisplay, CVarChange);
	g_bDev = GetConVarBool(g_CVarEnableDev);
	HookConVarChange(g_CVarEnableDev, CVarChange);
	
	g_hLethalArray = CreateArray();
	g_hKTForward = CreateGlobalForward("OnKnifeThrow", ET_Event, Param_Cell);
	g_hKHForward = CreateGlobalForward("OnKnifeHit", ET_Event, Param_Cell, Param_Cell, Param_Cell);
	g_hKKForward = CreateGlobalForward("OnPostKnifeKill", ET_Event, Param_Cell, Param_Cell, Param_Cell);
	g_WeaponParent = FindSendPropOffs("CBaseCombatWeapon", "m_hOwnerEntity");

	AddNormalSoundHook(NormalSHook:SoundsHook);
	HookEvent("round_start", EventRoundStart, EventHookMode_PostNoCopy);
	HookEvent("player_spawn", EventPlayerSpawn);
	HookEvent("weapon_fire", EventWeaponFire);
	HookEvent("player_death", EventPlayerDeath, EventHookMode_Pre);
}

public Action:Command_KT(client, args)
{
	new Handle:MG = CreateMenu(MenuHandler_MG);
	SetMenuTitle(MG, "Knife throw:");
	if(!boolean) AddMenuItem(MG, "on", "קלדה");
	else AddMenuItem(MG, "off", "הבכ");
	AddMenuItem(MG, "vote", "העבצה");
	DisplayMenu(MG, client, MENU_TIME_FOREVER);
	return Plugin_Handled;
}

public MenuHandler_MG(Handle:MG, MenuAction:action, param1, param2)
{
	if(action == MenuAction_Select)
	{
		switch(param2)
		{
			case 0:
			{
				if(boolean)
				{
					boolean = false;
					boolean2 = false;
					SetConVarInt(FindConVar("mp_restartgame"), 1);
					SetConVarInt(g_CVarEnable, 0);
					PrintToChatAll("\x07FFFFFF[\x0700E5FFvGames\x07FFFFFF] \x07FF0000Knife throw הבוכמ וישכע.");
				}
				else
				{
					boolean = true;
					boolean2 = true;
					SetConVarInt(FindConVar("mp_restartgame"), 1);
					SetConVarInt(g_CVarEnable, 1);
					PrintToChatAll("\x07FFFFFF[\x0700E5FFvGames\x07FFFFFF] \x07FF0000Knife throw קלוד וישכע.");
				}
			}
			case 1:
			{
				new Handle:menu = CreateMenu(handleVoteKT, MenuAction:MENU_ACTIONS_ALL);
				SetMenuTitle(menu, "קילדהל Knife throw?");
				AddMenuItem(menu, "0", "ןכ");
				AddMenuItem(menu, "1", "אל");
				SetMenuExitButton(menu, false);
				VoteMenuToAll(menu, 20);
			}
		}
	}
	else if(action == MenuAction_End) CloseHandle(MG);
}

public handleVoteKT(Handle:menu, MenuAction:action, vote, param2)
{
	if(action == MenuAction_VoteEnd) 
	{
		if(vote == 0)
		{
			boolean = true;
			boolean2 = true;
			SetConVarInt(FindConVar("mp_restartgame"), 1);
			SetConVarInt(g_CVarEnable, 1);
			PrintToChatAll("\x07FFFFFF[\x0700E5FFvGames\x07FFFFFF] \x07FF0000Knife throw קלוד וישכע.");
		}
		else if(vote == 1)
		{
			boolean = false;
			boolean2 = false;
			SetConVarInt(FindConVar("mp_restartgame"), 1);
			SetConVarInt(g_CVarEnable, 0);
			PrintToChatAll("\x07FFFFFF[\x0700E5FFvGames\x07FFFFFF] \x07FF0000Knife throw הבוכמ וישכע.");
		}
	}
}

public CVarChange(Handle:convar, const String:oldValue[], const String:newValue[]) {

	if ((convar == g_CVarEnable) && (StringToInt(newValue) == 1)) {
		if (g_iPointHurt == -1)
			CreateEnts();
		for (new i = 1; i <= MaxClients; i++)
			g_iKnives[i] = GetConVarInt(g_CVarKnives);
	}
	else if (convar == g_CVarVelocity)
		g_fVelocity = (1000.0 + (250.0 * StringToFloat(newValue)));
	else if (convar == g_CVarDamage)
		strcopy(g_sDamage, sizeof(g_sDamage), newValue);
	else if (convar == g_CVarHSDamage)
		strcopy(g_sHSDamage, sizeof(g_sHSDamage), newValue);
	else if (convar == g_CVarTrail)
		g_bTrail = GetConVarBool(g_CVarTrail);
	else if (convar == g_CVarNoBlock)
		g_bNoBlock = GetConVarBool(g_CVarNoBlock);
	else if (convar == g_CVarDisplay)
		g_iDisplay = GetConVarInt(g_CVarDisplay);
	else if (convar == g_CVarEnableDev)
		g_bDev = GetConVarBool(g_CVarNoBlock);
}

public OnMapStart() {

	g_iKnifeMI = PrecacheModel(KNIFE_MDL);
	g_iTrailMI = PrecacheModel(TRAIL_MDL);
	PrecacheSound(KNIFEHIT_SOUND);
}

public EventRoundStart(Handle:event, const String:name[], bool:dontBroadcast) {
	new maxent = GetEntityCount();
	if(GetConVarBool(g_CVarEnable))
	{
		new String:weapon[64];
		for(new i = MaxClients; i < maxent; i++)
		{
			if(IsValidEdict(i) && IsValidEntity(i))
			{
				GetEdictClassname(i, weapon, sizeof(weapon));
				if ((StrContains(weapon, "weapon_") != -1 || StrContains(weapon, "item_") != -1) && GetEntDataEnt2(i, g_WeaponParent) == -1)
				{
					AcceptEntityInput(i, "Kill");
				}
			}
		}
	}
	g_iPointHurt = -1;
	g_iEnvBlood = -1;
	ClearArray(g_hLethalArray);
	if (GetConVarBool(g_CVarEnable)) CreateEnts();
	if(boolean && boolean2)
	{
		SetConVarInt(g_CVarEnable, 1);
		new client = GetClientUserId(GetEventInt(event, "userid"));
		if(IsPlayerAlive(client) && IsClientInGame(client))
		{
			new knife = CreateEntityByName("weapon_knife");
			DispatchSpawn(knife);
			EquipPlayerWeapon(client, knife);
		}
	}
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
	if (IsPlayerAlive(client) && boolean && boolean2) RemoveAllWeapon(client);
	
	return Plugin_Continue;
}

stock RemoveAllWeapon(client)
{
	if(boolean && !IsClientInLastRequest(client))
	{
		RemoveWeapon(client, CS_SLOT_PRIMARY);
		RemoveWeapon(client, CS_SLOT_SECONDARY);
		RemoveWeapon(client, CS_SLOT_GRENADE);
		RemoveWeapon(client, CS_SLOT_C4);
	}
}

stock RemoveWeapon(client, slot)
{
	new weapon = GetPlayerWeaponSlot(client, slot);
	if (weapon != -1) AcceptEntityInput(weapon, "Kill");
} 

public EventPlayerSpawn(Handle:event,const String:name[],bool:dontBroadcast) {

	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new team = GetClientTeam(client);
	if(team == 3) g_iKnives[client] = GetConVarInt(g_CVarKnives);
		else g_iKnives[client] = 0;
	if (GetConVarBool(g_CVarEnable)) {
		CreateTimer(1.0, func, client);
		CreateTimer(0.5, func, client);
	}
}

public Action:func(Handle:timer, any:client)
{
	new team = GetClientTeam(client);
	if(!g_CVarEnable) return;
	if(team == 3)
	{
		new knife = CreateEntityByName("weapon_knife");
		DispatchSpawn(knife);
		EquipPlayerWeapon(client, knife);
		g_iKnives[client] = GetConVarInt(g_CVarKnives);
		SetEntityHealth(client, 135);
	}
	else g_iKnives[client] = 0;
}

public EventWeaponFire(Handle:event,const String:name[],bool:dontBroadcast) { // only fires for primary attack

	if (GetConVarBool(g_CVarEnable)) {
		new client = GetClientOfUserId(GetEventInt(event, "userid"));
		static String:sWeapon[32];
		GetEventString(event, "weapon", sWeapon, sizeof(sWeapon));
		if (!IsFakeClient(client) && StrEqual(sWeapon, "knife") && (g_iKnives[client] > 0) && !IsClientInLastRequest(client))
			ThrowKnife(client);
	}
}

public EventPlayerDeath(Handle:event,const String:name[],bool:dontBroadcast) {

	if (GetConVarBool(g_CVarEnable)) {
		new victim = GetClientOfUserId(GetEventInt(event, "userid"));
		new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
		decl String:sWeapon[32];
		GetEventString(event, "weapon", sWeapon, sizeof(sWeapon));
		new bool:tknife = StrEqual(sWeapon, "tknife");
		new bool:tknifehs = StrEqual(sWeapon, "tknifehs");
		if (tknife || tknifehs) {
			// the event is pre-hooked,
			// setting the weapon string will change the icon used in the kill notification
			SetEventString(event, "weapon", "knife");
			if (g_bDev) {
				Call_StartForward(g_hKKForward);
				Call_PushCell(victim);
				Call_PushCell(attacker);
				Call_PushCell(tknifehs);
				// since i cant prevent the victim from dying at this point,
				// i dont care what the return value is
				Call_Finish();
			}
			if ((GetConVarInt(g_CVarSteal) > 1) && (GetClientTeam(attacker) != GetClientTeam(victim)))
				KnifeCount(attacker, (g_iKnives[attacker] = (g_iKnives[attacker] + g_iKnives[victim])));
		}
		else if (StrEqual(sWeapon, "knife") && (GetConVarInt(g_CVarSteal) > 0) && (GetClientTeam(attacker) != GetClientTeam(victim)))
			KnifeCount(attacker, (g_iKnives[attacker] = (g_iKnives[attacker] + g_iKnives[victim])));
	}
}

ThrowKnife(client) {

	// anybody care if this dude throws a knife?
	if (g_bDev) {
		new value;
		Call_StartForward(g_hKTForward);
		Call_PushCell(client);
		Call_Finish(_:value);
		if (value != 0)
			return;
	}

	static Float:fPos[3], Float:fAng[3], Float:fVel[3], Float:fPVel[3];
	GetClientEyePosition(client, fPos);
	// simple noblock fix. prevent throw if it will spawn inside another client
	if (g_bNoBlock && IsClientIndex(GetTraceHullEntityIndex(fPos, client)))
		return;

	// create & spawn entity. set model & owner. set to kill itself OnUser1
	// calc & set spawn position, angle, velocity & spin
	// add to lethal knife array, teleport, add trial, ...
	new entity = CreateEntityByName("flashbang_projectile");
	if ((entity != -1) && DispatchSpawn(entity)) {
		SetEntityModel(entity, KNIFE_MDL);
		SetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity", client);
		SetVariantString(ADD_OUTPUT);
		AcceptEntityInput(entity, "AddOutput");
		GetClientEyeAngles(client, fAng);
		GetAngleVectors(fAng, fVel, NULL_VECTOR, NULL_VECTOR);
		ScaleVector(fVel, g_fVelocity);
		GetEntPropVector(client, Prop_Data, "m_vecVelocity", fPVel);
		AddVectors(fVel, fPVel, fVel);
		SetEntPropVector(entity, Prop_Data, "m_vecAngVelocity", g_fSpin);
		SetEntPropFloat(entity, Prop_Send, "m_flElasticity", 0.2);
		PushArrayCell(g_hLethalArray, entity);
		TeleportEntity(entity, fPos, fAng, fVel);
		KnifeCount(client, --g_iKnives[client]);
		if (g_bTrail) {
			new randomcolor[4];
			randomcolor[0] = GetRandomInt(1, 255);
			randomcolor[1] = GetRandomInt(1, 255);
			randomcolor[2] = GetRandomInt(1, 255);
			randomcolor[3] = GetRandomInt(1, 255);
			TE_SetupBeamFollow(entity, g_iTrailMI, 0, 0.7, 7.7, 7.7, 3, randomcolor);
			TE_SendToAll();
		}
	}
}

public Action:SoundsHook(clients[64], &numClients, String:sample[PLATFORM_MAX_PATH], &entity, &channel, &Float:volume, &level, &pitch, &flags) {

	if (GetConVarBool(g_CVarEnable) && StrEqual(sample, "weapons/flashbang/grenade_hit1.wav", false)) {
		new index = FindValueInArray(g_hLethalArray, entity);
		if (index != -1) {
			volume = 0.2;
			RemoveFromArray(g_hLethalArray, index); // delethalize on first bounce
			new attacker = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");
			static Float:fKnifePos[3], Float:fAttPos[3], Float:fVicEyePos[3];
			GetEntPropVector(entity, Prop_Data, "m_vecOrigin", fKnifePos);
			new victim = GetTraceHullEntityIndex(fKnifePos, attacker);
			if (IsClientIndex(victim) && IsClientInGame(attacker)) {
				RemoveEdict(entity);
				if (GetConVarBool(g_CVarFF) || (GetClientTeam(victim) != GetClientTeam(attacker))) {
					GetClientAbsOrigin(attacker, fAttPos);
					GetClientEyePosition(victim, fVicEyePos);
					EmitAmbientSound(KNIFEHIT_SOUND, fKnifePos, victim, SNDLEVEL_NORMAL, _, 0.8);
					// HURT!
					if (IsValidEntity(g_iPointHurt)) {
						new bool:headShot = (FloatAbs(fKnifePos[2] - fVicEyePos[2]) < 4.7) ? true : false;
						// last chance to stop this thing were doing
						if (g_bDev) {
							new value;
							Call_StartForward(g_hKHForward);
							Call_PushCell(victim);
							Call_PushCell(attacker);
							Call_PushCell(headShot);
							Call_Finish(_:value);
							if (value != 0)
								return Plugin_Changed;
						}
						DispatchKeyValue(victim, "targetname", "hurt");
						DispatchKeyValue(g_iPointHurt, "Damage", (headShot) ? g_sHSDamage : g_sDamage);
						DispatchKeyValue(g_iPointHurt, "classname", (headShot) ? "weapon_tknifehs" : "weapon_tknife");
						TeleportEntity(g_iPointHurt, fAttPos, NULL_VECTOR, NULL_VECTOR);
						AcceptEntityInput(g_iPointHurt, "Hurt", attacker);
						DispatchKeyValue(g_iPointHurt, "classname", "point_hurt");
						DispatchKeyValue(victim, "targetname", "nohurt");
						SetVariantString("BloodImpact");
						AcceptEntityInput(entity, "DispatchEffect");
						if (IsValidEntity(g_iEnvBlood))
							AcceptEntityInput(g_iEnvBlood, "EmitBlood", victim);
					}
				}
			}
			else // didn't hit a player, kill itself in a few seconds
				AcceptEntityInput(entity, "FireUser1");
			return Plugin_Changed;
		}
		else if (GetEntProp(entity, Prop_Send, "m_nModelIndex") == g_iKnifeMI) {
			volume = 0.2;
			return Plugin_Changed;
		}
	}
	return Plugin_Continue;
}

GetTraceHullEntityIndex(Float:pos[3], xindex) {

	TR_TraceHullFilter(pos, pos, g_fMinS, g_fMaxS, MASK_SHOT, THFilter, xindex);
	return TR_GetEntityIndex();
}

public bool:THFilter(entity, contentsMask, any:data) {

	return IsClientIndex(entity) && (entity != data);
}

bool:IsClientIndex(index) {

	return (index > 0) && (index <= MaxClients);
}

KnifeCount(client, count) {

	if (IsClientInGame(client)) {
		switch (g_iDisplay) {
			case 1: // Hint
				PrintHintText(client, COUNT_TXT, count);
			case 2: { // Key Hint
				static String:sBuffer[64];
				Format(sBuffer, 64, COUNT_TXT, count);
				new Handle:hKHT = StartMessageOne("KeyHintText", client);
				BfWriteByte(hKHT, 1);
				BfWriteString(hKHT, sBuffer);
				EndMessage();
			}
		}
	}
}

CreateEnts() {

	if (((g_iPointHurt = CreateEntityByName("point_hurt")) != -1) && DispatchSpawn(g_iPointHurt)) {
		DispatchKeyValue(g_iPointHurt, "DamageTarget", "hurt");
		DispatchKeyValue(g_iPointHurt, "DamageType", "0");
	}
	if (((g_iEnvBlood = CreateEntityByName("env_blood")) != -1) && DispatchSpawn(g_iEnvBlood)) {
		DispatchKeyValue(g_iEnvBlood, "spawnflags", "13");
		DispatchKeyValue(g_iEnvBlood, "amount", "1000");
	}
}

public NativeSetClientThrowingKnives(Handle:plugin, numParams) {

	new client = GetNativeCell(1);
	new num = GetNativeCell(2);
	KnifeCount(client, g_iKnives[client] = num);
}

public NativeGetClientThrowingKnives(Handle:plugin, numParams) {

	new client = GetNativeCell(1);
	return g_iKnives[client];
}