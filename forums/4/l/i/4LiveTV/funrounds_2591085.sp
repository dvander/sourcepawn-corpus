#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <cstrike>

#pragma semicolon 1

public Plugin:myinfo =  {
	name = "Fun Rounds", 
	author = "boomix", 
	description = "Fun rounds", 
	version = "1.2", 
	url = "http://boomix.gq"
}

//************************//
//** PUBLIC DEFINĪCIJAS **//
//************************//

//** VISI IEROČI **//

//Primary
new const String:WeaponPrimary[21][] =  {
	"weapon_ak47", "weapon_aug", "weapon_bizon", "weapon_famas", "weapon_g3sg1", "weapon_galilar", "weapon_m249", "weapon_m4a1", "weapon_mac10", "weapon_mag7", 
	"weapon_mp7", "weapon_mp9", "weapon_negev", "weapon_nova", "weapon_p90", "weapon_sawedoff", "weapon_scar20", "weapon_sg556", "weapon_ssg08", "weapon_ump45", "weapon_xm1014"
};

//Secondary
new const String:WeaponSecondary[7][] =  {
	"weapon_deagle", "weapon_elite", "weapon_fiveseven", "weapon_glock", "weapon_hkp2000", "weapon_p250", "weapon_tec9"
};

//Grenades
new const GrenadesAll[] =  { 15, 17, 16, 14, 18, 17 };


//Keyvalues
new Handle:Kv;
new Checker;
int INTRoundNumber;
int INTLastNumber;

//KeyValue strings
new String:RoundName[200];
new String:ThirdPerson[3];
new String:Weapon[70];
new String:Health[70];
new String:DecoySound[70];
new String:NoKnife[3];
new String:InfiniteAmmo[3];
new String:InfiniteNade[50];
new String:GrenadeToGive[50];
new String:PlayerSpeed[20];
new String:PlayerGravity[20];
new String:NoRecoil[3];
new String:AutoBhop[3];
new String:NoScope[3];
new String:Vampire[3];
new String:PColor[15];
new String:BackWards[3];
new String:Fov[10];
new String:ChickenDefuse[3];
new String:HeadShot[3];
new String:SpeedChange[3];
new String:RecoilView[7];
new String:AlwaysMove[3];

//Bools 
new bool:g_ThirdPerson = false;
new bool:g_DecoySound = false;
new bool:g_InfiniteNade = false;
new bool:g_NoScope = false;
new bool:g_Vampire = false;
new bool:g_ChickenDefuse = false;
new bool:g_HeadShot = false;
new bool:g_SpeedChange = false;
new bool:g_EnablePluginu = true;

//Cvars
new Handle:sv_allow_thirdperson;
new Handle:sv_infinite_ammo;
new Handle:sv_gravity;
new Handle:weapon_accuracy_nospread;
new Handle:weapon_recoil_cooldown;
new Handle:weapon_recoil_decay1_exp;
new Handle:weapon_recoil_decay2_exp;
new Handle:weapon_recoil_decay2_lin;
new Handle:weapon_recoil_scale;
new Handle:weapon_recoil_suppression_shots;
new Handle:weapon_recoil_view_punch_extra;
//new Handle:abner_bhop_autobhop;
//new Handle:abner_bhop_autobhop;
new Handle:cv_accelerate;
new Handle:sv_airaccelerate;
new Handle:sv_friction;

new Handle:g_PluginEnable = INVALID_HANDLE;

//****************************//
//** END PUBLIC DEFINĪCIJAS **//
//****************************//

public OnPluginStart() {
	
	//RegConsoleCmd("sm_getround", Command_GetRound);
	RegAdminCmd("sm_getround", Command_GetRound, ADMFLAG_KICK, "Get round");
	
	//Create convar
	RegConsoleCmd("sm_funrounds", Command_EnablePlugin, "Enable plugin thru command!", ADMFLAG_KICK);
	
	g_PluginEnable = CreateConVar("fr_enable", "1", "Enable/disable the plugin.", FCVAR_NOTIFY|FCVAR_PLUGIN, true, 0.0, true, 1.0);
	HookConVarChange(g_PluginEnable, ConVarChange);
	g_EnablePluginu = GetConVarBool(g_PluginEnable);
	
	//** EVENTS **//
	HookEvent("decoy_started", Fun_EventDecoyStarted);
	HookEvent("weapon_zoom", Fun_EventWeaponZoom, EventHookMode_Post);
	HookEvent("bomb_planted", Fun_BomPlanted_Event);
	HookEvent("player_hurt", Fun_EventPlayerHurt);
	HookEvent("inspect_weapon", Fun_EventInspectWeapon);
	HookEvent("round_end", Fun_EventRoundEnd);
	HookEvent("round_start", Fun_EventRoundStart);
	HookEvent("player_death", Fun_EventPlayerDeath);
}

public OnConfigsExecuted() {
	
	//** CVARS **//
	sv_allow_thirdperson = FindConVar("sv_allow_thirdperson");
	sv_infinite_ammo = FindConVar("sv_infinite_ammo");
	sv_gravity = FindConVar("sv_gravity");
	weapon_accuracy_nospread = FindConVar("weapon_accuracy_nospread");
	weapon_recoil_cooldown = FindConVar("weapon_recoil_cooldown");
	weapon_recoil_decay1_exp = FindConVar("weapon_recoil_decay1_exp");
	weapon_recoil_decay2_exp = FindConVar("weapon_recoil_decay2_exp");
	weapon_recoil_decay2_lin = FindConVar("weapon_recoil_decay2_lin");
	weapon_recoil_scale = FindConVar("weapon_recoil_scale");
	weapon_recoil_suppression_shots = FindConVar("weapon_recoil_suppression_shots");
	weapon_recoil_view_punch_extra = FindConVar("weapon_recoil_view_punch_extra");
	//abner_bhop_autobhop = FindConVar("abner_bhop_autobhop ");
	//abner_bhop_enabled = FindConVar("abner_bhop_enabled");
	cv_accelerate = FindConVar("sv_accelerate");
	sv_airaccelerate = FindConVar("sv_airaccelerate");
	sv_friction = FindConVar("sv_friction");
	
	//** KEYVALUES **//
	new flags = GetConVarFlags(sv_gravity);
	new flags2 = GetConVarFlags(cv_accelerate);
	new flags3 = GetConVarFlags(sv_airaccelerate);
	new flags4 = GetConVarFlags(sv_friction);
	SetConVarFlags(sv_gravity, flags & ~FCVAR_NOTIFY);
	SetConVarFlags(cv_accelerate, flags2 & ~FCVAR_NOTIFY);
	SetConVarFlags(sv_airaccelerate, flags3 & ~FCVAR_NOTIFY);
	SetConVarFlags(sv_friction, flags4 & ~FCVAR_NOTIFY);
	
	//Settings for server
	new Handle:bot_quota = FindConVar("bot_quota");
	new Handle:bot_quota_mode = FindConVar("bot_quota_mode");
	new Handle:mp_buytime = FindConVar("mp_buytime");
	new Handle:mp_maxmoney = FindConVar("mp_maxmoney");
	new Handle:mp_ct_default_secondary = FindConVar("mp_ct_default_secondary");
	new Handle:mp_t_default_secondary = FindConVar("mp_t_default_secondary");
	SetConVarInt(bot_quota, 0);
	SetConVarString(bot_quota_mode, "none");
	SetConVarInt(mp_buytime, 0);
	SetConVarInt(mp_maxmoney, 0);
	SetConVarString(mp_ct_default_secondary, "");
	SetConVarString(mp_t_default_secondary, "");
	
}

public Action:Command_EnablePlugin(client, args) {
	new String:arg[3];
	GetCmdArg(1, arg, sizeof(arg));
	int EnableNumber = StringToInt(arg);
	
	if(EnableNumber == 1) {
		g_EnablePluginu = true;
		PrintToServer("Fun rounds enabled!");
	} else if(EnableNumber == 0) {
		g_EnablePluginu = false;
		PrintToServer("Fun rounds disabled!");
	}	
}

public ConVarChange(Handle:cvar, const String:oldValue[], const String:newValue[]) {
	
	new newval = StringToInt(newValue);
	
	if(newval == 1) {
		g_EnablePluginu = true;
		PrintToServer("Fun rounds enabled!");
	} else if(newval == 0) {
		g_EnablePluginu = false;
		PrintToServer("Fun rounds disabled!");
	}
	
}

public Action:Fun_EventRoundEnd(Handle:event, const String:name[], bool:dontBroadcast) {
	TurnOffAllSettings();
}

public Action:Fun_EventRoundStart(Handle:event, const String:name[], bool:dontBroadcast) {
	StartRound();
}

public Action:Command_GetRound(client, args) {
	
	new String:RoundNumber[3];
	RoundNumber = "0";
	INTRoundNumber = 0;
	GetCmdArg(1, RoundNumber, sizeof(RoundNumber));
	if (StrEqual(RoundNumber, "0")) {
		INTRoundNumber = 0;
	} else {
		INTRoundNumber = StringToInt(RoundNumber);
	}
	
	StartRound();
	
	return Plugin_Handled;
	
}

public StartRound() {
	
	if(!g_EnablePluginu) {
		return false;
	}
	
	//** Izlēdzam iepriekšējo raundu **//
	TurnSettingsOff();
	
	new String:RoundNumber[3];
	
	//** IEGŪSTAM RAUNDA NUMURU **//
	if (INTRoundNumber == 0) {
		INTRoundNumber = GetRandomInt(1, 23);
	}
	
	if (INTRoundNumber == INTLastNumber) {
		INTRoundNumber = GetRandomInt(1, 23);
	}
	
	IntToString(INTRoundNumber, RoundNumber, sizeof(RoundNumber));
	
	
	//** IEGŪSTAM KV LINKU **//
	decl String:KeyValuePath[PLATFORM_MAX_PATH];
	Kv = CreateKeyValues("Rounds");
	BuildPath(Path_SM, KeyValuePath, sizeof(KeyValuePath), "data/funrounds/rounds.txt");
	FileToKeyValues(Kv, KeyValuePath);
	
	//** AIZEJAM UZ KV ROW'U **//
	if (KvJumpToKey(Kv, RoundNumber, false)) {
		KvGetString(Kv, "name", RoundName, sizeof(RoundName), "No name round!");
		KvGetString(Kv, "thirdperson", ThirdPerson, sizeof(ThirdPerson), "0");
		KvGetString(Kv, "weapon", Weapon, sizeof(Weapon), "weapon_none");
		KvGetString(Kv, "health", Health, sizeof(Health), "100");
		KvGetString(Kv, "health", DecoySound, sizeof(DecoySound), "100");
		KvGetString(Kv, "noknife", NoKnife, sizeof(NoKnife), "0");
		KvGetString(Kv, "infiniteammo", InfiniteAmmo, sizeof(InfiniteAmmo), "0");
		KvGetString(Kv, "infinitenade", InfiniteNade, sizeof(InfiniteNade), "weapon_none");
		KvGetString(Kv, "speed", PlayerSpeed, sizeof(PlayerSpeed), "1.0");
		KvGetString(Kv, "gravity", PlayerGravity, sizeof(PlayerGravity), "800");
		KvGetString(Kv, "norecoil", NoRecoil, sizeof(NoRecoil), "0");
		KvGetString(Kv, "vampire", Vampire, sizeof(Vampire), "0");
		KvGetString(Kv, "Pcolor", PColor, sizeof(PColor), "null");
		KvGetString(Kv, "backwards", BackWards, sizeof(BackWards), "0");
		KvGetString(Kv, "fov", Fov, sizeof(Fov), "90");
		KvGetString(Kv, "autobhop", AutoBhop, sizeof(AutoBhop), "0");
		KvGetString(Kv, "chickendef", ChickenDefuse, sizeof(ChickenDefuse), "0");
		KvGetString(Kv, "headshot", HeadShot, sizeof(HeadShot), "0");
		KvGetString(Kv, "speedchange", SpeedChange, sizeof(SpeedChange), "0");
		KvGetString(Kv, "noscope", NoScope, sizeof(NoScope), "0");
		KvGetString(Kv, "recoilview", RecoilView, sizeof(RecoilView), "0.0555");
		KvGetString(Kv, "alwaysmove", AlwaysMove, sizeof(AlwaysMove), "0");
		
	}
	
	//** PRINTĒT ČATĀ RAUNDA NOSAUKUMU! **//
	PrintCenterTextAll("%s", RoundName);
	PrintToChatAll("\x3 \x4 ----------------------------------------");
	PrintToChatAll("\x3 \x4 %s", RoundName);
	PrintToChatAll("\x3 \x4 %s", RoundName);
	PrintToChatAll("\x3 \x4 %s", RoundName);
	PrintToChatAll("\x3 \x4 ----------------------------------------");
	
	//** TREŠĀ PERSONA **//
	if (StrEqual(ThirdPerson, "1")) {
		g_ThirdPerson = true;
		SetConVarInt(sv_allow_thirdperson, 1, true, false);
		CreateTimer(0.1, EnableThirdPerson);
	} else {
		g_ThirdPerson = false;
	}
	//** WEAPONS **//
	GiveWeapons();
	//** HEALTH **//
	int HealthInt = StringToInt(Health);
	if (HealthInt != 100) {
		for (new x = 1; x < MaxClients; x++) {
			if (IsClientInGame(x) && IsPlayerAlive(x) && !IsFakeClient(x)) {
				SetEntityHealth(x, HealthInt);
			}
		}
	} else {
		if (HealthInt == 100) {
			for (new x = 1; x < MaxClients; x++) {
				if (IsClientInGame(x) && IsPlayerAlive(x) && !IsFakeClient(x)) {
					int ActualHealth = GetEntProp(x, Prop_Send, "m_iHealth");
					if (ActualHealth != 100) {
						SetEntityHealth(x, 100);
					}
				}
			}
		}
	}
	//** DECOY SOUND **//
	if (StrEqual(DecoySound, "1")) {
		g_DecoySound = true;
	} else {
		g_DecoySound = false;
	}
	//** NO KNIFE **//
	
	//** INFINITE AMMO **//
	if (StrEqual(InfiniteAmmo, "1") || StrEqual(InfiniteAmmo, "2")) {
		new SetAmmoInt = StringToInt(InfiniteAmmo);
		SetConVarInt(sv_infinite_ammo, SetAmmoInt, true, false);
	}
	else {
		new sv_infinite_ammoDEF = GetConVarInt(sv_infinite_ammo);
		if (sv_infinite_ammoDEF > 0) {
			SetConVarInt(sv_infinite_ammo, 0, true, false);
		}
	}
	//** INFINITE NADE **//
	if (StrEqual(InfiniteNade, "weapon_decoy") || StrEqual(InfiniteNade, "weapon_hegrenade") || StrEqual(InfiniteNade, "weapon_flashbang") || StrEqual(InfiniteNade, "weapon_molotov") || StrEqual(InfiniteNade, "weapon_incgrenade")) {
		g_InfiniteNade = true;
		GrenadeToGive = InfiniteNade; //Iedodam public statusu
	} else {
		g_InfiniteNade = false;
	}
	//** SPEED **//
	new Float:FSpeed = StringToFloat(PlayerSpeed);
	if (FSpeed > 1.0 || FSpeed < 1.0) {
		for (new x = 1; x < MaxClients; x++) {
			if (IsClientInGame(x) && IsPlayerAlive(x) && !IsFakeClient(x)) {
				SetEntPropFloat(x, Prop_Data, "m_flLaggedMovementValue", FSpeed);
			}
		}
	} else {
		for (new x = 1; x < MaxClients; x++) {
			if (IsClientInGame(x) && IsPlayerAlive(x) && !IsFakeClient(x)) {
				SetEntPropFloat(x, Prop_Data, "m_flLaggedMovementValue", 1.0);
			}
		}
	}
	//** GRAVITY **//
	new INTPlayerGravity = StringToInt(PlayerGravity);
	
	if (INTPlayerGravity > 800 || INTPlayerGravity < 800) {
		SetConVarInt(sv_gravity, INTPlayerGravity, true, false);
	} else {
		new DefGravity = GetConVarInt(sv_gravity);
		if (DefGravity != 800) {
			SetConVarInt(sv_gravity, 800, true, false);
		}
	}
	//** NO RECOIL **//
	
	if (StrEqual(NoRecoil, "1")) {
		if (weapon_accuracy_nospread != INVALID_HANDLE) {
			SetConVarInt(weapon_accuracy_nospread, 1, true, false);
			SetConVarInt(weapon_recoil_cooldown, 0, true, false);
			SetConVarInt(weapon_recoil_decay1_exp, 99999, true, false);
			SetConVarInt(weapon_recoil_decay2_exp, 99999, true, false);
			SetConVarInt(weapon_recoil_decay2_lin, 99999, true, false);
			SetConVarInt(weapon_recoil_scale, 0, true, false);
			SetConVarInt(weapon_recoil_suppression_shots, 500, true, false);
		}
	} else {
		new DefWeaponAccuracy = GetConVarInt(weapon_accuracy_nospread);
		if (DefWeaponAccuracy != 0) {
			SetConVarInt(weapon_accuracy_nospread, 0, true, false);
			SetConVarFloat(weapon_recoil_cooldown, 0.55, true, false);
			SetConVarFloat(weapon_recoil_decay1_exp, 3.5, true, false);
			SetConVarInt(weapon_recoil_decay2_exp, 8, true, false);
			SetConVarInt(weapon_recoil_decay2_lin, 18, true, false);
			SetConVarInt(weapon_recoil_scale, 2, true, false);
			SetConVarInt(weapon_recoil_suppression_shots, 4, true, false);
		}
		
	}
	
	//** AUTO BHOP **//
	if (StrEqual(AutoBhop, "1")) {
		//SetConVarInt(abner_bhop_autobhop, 1, true, false);
		//SetConVarInt(abner_bhop_enabled, 1, true, false);
		ServerCommand("abner_bhop_autobhop 1");
		ServerCommand("abner_bhop_enabled 1");
	} else {
		//SetConVarInt(abner_bhop_autobhop, 0, true, false);
		//SetConVarInt(abner_bhop_enabled, 0, true, false);
		ServerCommand("abner_bhop_autobhop 0");
		ServerCommand("abner_bhop_enabled 0");
	}
	
	//** NOSCOPE **//
	if (StrEqual(NoScope, "1")) {
		g_NoScope = true;
	} else {
		g_NoScope = false;
	}
	
	//** VAMPIRE **//
	if (StrEqual(Vampire, "1")) {
		g_Vampire = true;
	} else {
		g_Vampire = false;
	}
	//** PLAYER COLOR **//
	
	int ColorR = 255;
	int ColorG = 255;
	int ColorB = 255;
	
	new LastPlayerColor = Checker;
	
	Checker = 0;
	if (StrEqual(PColor, "black")) {
		ColorR = 0;
		ColorG = 0;
		ColorB = 0;
		Checker = 1;
	}
	
	else if (StrEqual(PColor, "pink")) {
		ColorR = 255;
		ColorG = 0;
		ColorB = 255;
		Checker = 1;
	}
	
	if (LastPlayerColor == 1) {
		for (new x = 1; x < MaxClients; x++) {
			if (IsClientInGame(x) && IsPlayerAlive(x) && !IsFakeClient(x)) {
				SetEntityRenderColor(x, 255, 255, 255, 0);
			}
		}
	}
	
	if (Checker == 1) {
		for (new x = 1; x < MaxClients; x++) {
			if (IsClientInGame(x) && IsPlayerAlive(x) && !IsFakeClient(x)) {
				SetEntityRenderColor(x, ColorR, ColorG, ColorB, 0);
			}
		}
	}
	
	//** BackWards **//
	if (StrEqual(BackWards, "1")) {
		SetConVarInt(cv_accelerate, -5, true, false);
	} else {
		new Defaccelerete = GetConVarInt(cv_accelerate);
		if (Defaccelerete == -5) {
			SetConVarFloat(cv_accelerate, 5.5, true, false);
		}
	}
	
	//** FOV **//
	new INTFov;
	INTFov = StringToInt(Fov);
	
	if (INTFov > 90 || INTFov < 90) {
		for (new x = 1; x < MaxClients; x++) {
			if (IsClientInGame(x) && IsPlayerAlive(x) && !IsFakeClient(x)) {
				SetEntProp(x, Prop_Send, "m_iDefaultFOV", INTFov);
				SetEntProp(x, Prop_Send, "m_iFOV", INTFov);
			}
		}
		
	} else {
		for (new x = 1; x < MaxClients; x++) {
			if (IsClientInGame(x) && IsPlayerAlive(x) && !IsFakeClient(x)) {
				SetEntProp(x, Prop_Send, "m_iDefaultFOV", 90);
				SetEntProp(x, Prop_Send, "m_iFOV", 90);
			}
		}
	}
	//** CHICKEN DEFUSE **//
	if (StrEqual(ChickenDefuse, "1")) {
		g_ChickenDefuse = true;
	} else {
		g_ChickenDefuse = false;
	}
	//** HEADSHOT ONLY **//
	if (StrEqual(HeadShot, "1")) {
		g_HeadShot = true;
	} else {
		g_HeadShot = false;
	}
	//** SPEEDCHANGE **//
	if (StrEqual(SpeedChange, "1")) {
		g_SpeedChange = true;
	} else {
		g_SpeedChange = false;
	}
	//** WEIRD RECOIL VIEW **//
	
	new Float:INTRecoilView = StringToFloat(RecoilView);
	
	if (INTRecoilView > 0.055 || INTRecoilView < 0.055) {
		SetConVarFloat(weapon_recoil_view_punch_extra, INTRecoilView, true, false);
	} else {
		SetConVarFloat(weapon_recoil_view_punch_extra, 0.055, true, false);
	}
	
	//** FRICTION **//
	if (StrEqual(AlwaysMove, "1")) {
		SetConVarInt(sv_friction, -1, true, false);
	} else {
		SetConVarFloat(sv_friction, 5.2, true, false);
	}
	
	INTLastNumber = INTRoundNumber;
	
	return true;
	
}

public TurnSettingsOff() {
	
	if (g_ThirdPerson) {
		SetConVarInt(sv_allow_thirdperson, 0, true, false);
	}
	
}

//** FUNKCIJA THIRD PERSON **//
public Action:EnableThirdPerson(Handle:timer) {
	for (new x = 1; x < MaxClients; x++) {
		if (IsClientInGame(x) && IsPlayerAlive(x) && !IsFakeClient(x)) {
			ClientCommand(x, "thirdperson");
		}
	}
}

//** FUNKCIJA GIVE WEAPON **//
public GiveWeapons() {
	if (!StrContains(Weapon, "weapon_")) {
		
		//Aizvācam esošos ieročus/granātas
		RemoveWeapons();
		RemoveNades();
		
		//Ja ir vairāk kā divi ieroči
		decl String:bit[10][80];
		new SumOfStrings = ExplodeString(Weapon, ";", bit, sizeof bit, sizeof bit[]);
		
		//** JA DOD DIVUS VAI VAIRĀK IEROČUS! **//
		if (SumOfStrings >= 2) {
			
			//Ja dod noteiktus ieročus 
			for (new i = 0; i < SumOfStrings; i++) {
				if (StrEqual(bit[i], "weapon_primary_random") || StrEqual(bit[i], "weapon_secondary_random")) {
					//PrintToServer("Stop");
				} else {
					for (new x = 1; x < MaxClients; x++) {
						if (IsClientInGame(x) && IsPlayerAlive(x) && !IsFakeClient(x)) {
							GivePlayerItem(x, bit[i]);
						}
					}
				}
			}
			
			
			//Iedodam random ieročus
			
			for (new i = 0; i < SumOfStrings; i++) {
				
				//Ja tas ir primary
				if (StrEqual(bit[i], "weapon_primary_random")) {
					new random = GetRandomInt(0, 20);
					for (new x = 1; x < MaxClients; x++) {
						if (IsClientInGame(x) && IsPlayerAlive(x) && !IsFakeClient(x)) {
							GivePlayerItem(x, WeaponPrimary[random]);
						}
					}
				}
				//Ja tas ir secodary
				if (StrEqual(bit[i], "weapon_secondary_random")) {
					new random = GetRandomInt(0, 6);
					for (new x = 1; x < MaxClients; x++) {
						if (IsClientInGame(x) && IsPlayerAlive(x) && !IsFakeClient(x)) {
							GivePlayerItem(x, WeaponSecondary[random]);
						}
					}
				}
				
			}
			
		} else {
			for (new x = 1; x < MaxClients; x++) {
				if (IsClientInGame(x) && IsPlayerAlive(x) && !IsFakeClient(x)) {
					GivePlayerItem(x, Weapon);
				}
			}
		}
		
	} else {
		
		if (StrEqual(Weapon, "none")) {
			RemoveWeapons();
			RemoveNades();
		}
	}
	
}

//FUNKCIJA - REMOVE WEAPONS
public RemoveWeapons() {
	for (new x = 1; x < MaxClients; x++) {
		if (IsClientInGame(x) && IsPlayerAlive(x) && !IsFakeClient(x)) {
			
			new primary = GetPlayerWeaponSlot(x, 0);
			new secondary = GetPlayerWeaponSlot(x, 1);
			
			if (primary > 0) {
				RemovePlayerItem(x, primary);
				RemoveEdict(primary);
			}
			
			if (secondary > 0) {
				RemovePlayerItem(x, secondary);
				RemoveEdict(secondary);
			}
			
		}
	}
}

//FUNKCIJA - REMOVE NADES
public RemoveNades() {
	
	for (new x = 1; x < MaxClients; x++) {
		if (IsClientInGame(x) && IsPlayerAlive(x) && !IsFakeClient(x)) {
			for (new i = 0; i < 6; i++) {
				SetEntProp(x, Prop_Send, "m_iAmmo", 0, _, GrenadesAll[i]);
			}
		}
	}
	
}

//FUNKCIJA - DECOY SOUND
public Action:Fun_EventDecoyStarted(Handle:event, const String:name[], bool:dontBroadcast) {
	if (g_DecoySound) {
		new entity = GetEventInt(event, "entityid");
		if (IsValidEntity(entity)) {
			RemoveEdict(entity);
		}
	}
}

//FUNKCIJA - INFINITE NADES
public OnEntityCreated(iEntity, const String:classname[])
{
	if (g_InfiniteNade) {
		if (StrContains(classname, "_projectile") != -1) {
			SDKHook(iEntity, SDKHook_SpawnPost, OnEntitySpawned);
		}
	}
}
public OnEntitySpawned(iGrenade) {
	
	new client = GetEntPropEnt(iGrenade, Prop_Send, "m_hOwnerEntity");
	if (IsClientInGame(client) && IsPlayerAlive(client) && !IsFakeClient(client)) {
		new nadeslot = GetPlayerWeaponSlot(client, 3);
		if (nadeslot > 0) {
			RemovePlayerItem(client, nadeslot);
			RemoveEdict(nadeslot);
		}
		GivePlayerItem(client, GrenadeToGive);
	}
}

//FUNKCIJA - NOSCOPE
public Action:Fun_EventWeaponZoom(Handle:event, const String:name[], bool:dontBroadcast) {
	
	if (g_NoScope) {
		
		new client = GetClientOfUserId(GetEventInt(event, "userid"));
		if (IsClientInGame(client) && IsPlayerAlive(client) && !IsFakeClient(client)) {
			new ent = GetPlayerWeaponSlot(client, 0);
			CS_DropWeapon(client, ent, true, true);
			PrintToChat(client, "This is noscope round! Don't try to scope!");
		}
	}
	
}


//FUNCKIJA - PLAYER HURT

public Action:Fun_EventPlayerHurt(Handle:event, const String:name[], bool:dontBroadcast) {
	
	if (g_Vampire) {
		new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
		if (attacker == 0) {
			return;
		}
		new dmg_health = GetEventInt(event, "dmg_health");
		new attackerH = GetEntProp(attacker, Prop_Send, "m_iHealth");
		if (IsClientInGame(attacker) && IsPlayerAlive(attacker) && !IsFakeClient(attacker)) {
			new GiveHealth = attackerH + dmg_health;
			SetEntityHealth(attacker, GiveHealth);
		}
	}
	
	if (g_HeadShot) {
		
		new hitgroup = GetEventInt(event, "hitgroup");
		new victim = GetClientOfUserId(GetEventInt(event, "userid"));
		new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
		new dhealth = GetEventInt(event, "dmg_health");
		new healths = GetEventInt(event, "health");
		
		if (hitgroup != 1) {
			
			if (attacker != victim && victim != 0 && attacker != 0) {
				if (dhealth > 0) {
					new GiveHealths = healths + dhealth;
					SetEntityHealth(victim, GiveHealths);
				}
			}
			
		}
		
	}
	
	
	
}


//FUNKCIJA - CHICKEN DEFUSE

public Action:Fun_BomPlanted_Event(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (g_ChickenDefuse) {
		new c4 = -1;
		c4 = FindEntityByClassname(c4, "planted_c4");
		if (c4 != -1) {
			new chicken = CreateEntityByName("chicken");
			if (chicken != -1) {
				new player = GetClientOfUserId(GetEventInt(event, "userid"));
				decl Float:pos[3];
				GetEntPropVector(player, Prop_Data, "m_vecOrigin", pos);
				pos[2] += -15.0;
				DispatchSpawn(chicken);
				SetEntProp(chicken, Prop_Data, "m_takedamage", 0);
				SetEntProp(chicken, Prop_Send, "m_fEffects", 0);
				TeleportEntity(chicken, pos, NULL_VECTOR, NULL_VECTOR);
				TeleportEntity(c4, NULL_VECTOR, Float: { 0.0, 0.0, 0.0 }, NULL_VECTOR);
				SetVariantString("!activator");
				AcceptEntityInput(c4, "SetParent", chicken, c4, 0);
			}
		}
	}
}


public Action:Fun_EventInspectWeapon(Handle:event, const String:name[], bool:dontBroadcast) {
	
	if (g_SpeedChange) {
		
		int motion = GetRandomInt(0, 1);
		
		if (motion == 1) {
			for (new x = 1; x < MaxClients; x++) {
				if (IsClientInGame(x) && IsPlayerAlive(x) && !IsFakeClient(x)) {
					SetEntPropFloat(x, Prop_Data, "m_flLaggedMovementValue", 4.0);
				}
			}
		}
		
		if (motion == 0) {
			for (new x = 1; x < MaxClients; x++) {
				if (IsClientInGame(x) && IsPlayerAlive(x) && !IsFakeClient(x)) {
					SetEntPropFloat(x, Prop_Data, "m_flLaggedMovementValue", 0.3);
				}
			}
		}
	}
	
}


public TurnOffAllSettings() {
	
	//THIRD PERSON
	g_ThirdPerson = false;
	SetConVarInt(sv_allow_thirdperson, 0, true, false);
	
	//DECOY SOUND
	g_DecoySound = false;
	
	//NO KNIFE
	for (new x = 1; x < MaxClients; x++) {
		if (IsClientInGame(x) && IsPlayerAlive(x) && !IsFakeClient(x)) {
			new knife = GetPlayerWeaponSlot(x, 2);
			if (knife == -1) {
				new nazis = GivePlayerItem(x, "weapon_knife");
				EquipPlayerWeapon(x, nazis);
			}
		}
	}
	
	//INFINITE AMMO
	SetConVarInt(sv_infinite_ammo, 0, true, false);
	
	//SPEED
	for (new x = 1; x < MaxClients; x++) {
		if (IsClientInGame(x) && IsPlayerAlive(x) && !IsFakeClient(x)) {
			SetEntPropFloat(x, Prop_Data, "m_flLaggedMovementValue", 1.0);
		}
	}
	
	//GRAVITY
	SetConVarInt(sv_gravity, 800, true, false);
	
	//NO RECOIL
	SetConVarInt(weapon_accuracy_nospread, 0, true, false);
	SetConVarFloat(weapon_recoil_cooldown, 0.55, true, false);
	SetConVarFloat(weapon_recoil_decay1_exp, 3.5, true, false);
	SetConVarInt(weapon_recoil_decay2_exp, 8, true, false);
	SetConVarInt(weapon_recoil_decay2_lin, 18, true, false);
	SetConVarInt(weapon_recoil_scale, 2, true, false);
	SetConVarInt(weapon_recoil_suppression_shots, 4, true, false);
	
	//AUTO BHOP
	ServerCommand("abner_bhop_autobhop 0");
	ServerCommand("abner_bhop_enabled 0");
	
	//NO SCOPE
	g_NoScope = false;
	
	//VAMPIRE
	g_Vampire = false;
	
	//COLOR
	for (new x = 1; x < MaxClients; x++) {
		if (IsClientInGame(x) && IsPlayerAlive(x) && !IsFakeClient(x)) {
			SetEntityRenderColor(x, 255, 255, 255, 0);
		}
	}
	
	//BACKWARDS
	SetConVarFloat(cv_accelerate, 5.5, true, false);
	
	//FOV
	for (new x = 1; x < MaxClients; x++) {
		if (IsClientInGame(x) && IsPlayerAlive(x) && !IsFakeClient(x)) {
			SetEntProp(x, Prop_Send, "m_iDefaultFOV", 90);
			SetEntProp(x, Prop_Send, "m_iFOV", 90);
		}
	}
	
	//CHICKEN DEFUSE
	g_ChickenDefuse = false;
	
	//HEADSHOT
	g_HeadShot = false;
	
	//SPEEDCHANGE
	g_SpeedChange = false;
	
	//WEIRD RECOIL
	for (new x = 1; x < MaxClients; x++) {
		if (IsClientInGame(x) && IsPlayerAlive(x) && !IsFakeClient(x)) {
			SetConVarFloat(weapon_recoil_view_punch_extra, 0.055, true, false);
		}
	}
}

public Action:Fun_EventPlayerDeath(Handle:event, const String:name[], bool:dontBroadcast) {
	
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	//Thirdperson
	if (IsClientInGame(client) && !IsFakeClient(client)) {
		
		SendConVarValue(client, sv_allow_thirdperson, "0");
		
		//Fov
		SetEntProp(client, Prop_Send, "m_iDefaultFOV", 90);
		SetEntProp(client, Prop_Send, "m_iFOV", 90);
		
	}
	
	
}
