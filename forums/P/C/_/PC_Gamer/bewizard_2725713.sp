#include <sourcemod>
#include <sdkhooks> 
#include <tf2_stocks> 
#include <tf2attributes> 
#include <tf2items>

#pragma semicolon 1 
#pragma newdecls required

#define PLUGIN_VERSION "1.0" 

#define HHH        "models/bots/merasmus/merasmus.mdl" 
#define BOMBMODEL  "models/props_lakeside_event/bomb_temp.mdl" 
#define SPAWN	"vo/halloween_merasmus/sf12_appears04.mp3" 
#define SPAWN2	"ui/halloween_boss_summoned_fx.wav" 
#define DEATH   "vo/halloween_merasmus/sf12_defeated01.mp3" 
#define DEATHBOSS 	"ui/halloween_boss_defeated_fx.wav"

#define MERASMUS "models/bots/merasmus/merasmus.mdl" 
#define DOOM1    "vo/halloween_merasmus/sf12_appears04.mp3" 
#define DOOM2    "vo/halloween_merasmus/sf12_appears09.mp3" 
#define DOOM3    "vo/halloween_merasmus/sf12_appears01.mp3" 
#define DOOM4    "vo/halloween_merasmus/sf12_appears08.mp3" 

#define DEATH1    "vo/halloween_merasmus/sf12_defeated01.mp3" 
#define DEATH2    "vo/halloween_merasmus/sf12_defeated06.mp3" 
#define DEATH3    "vo/halloween_merasmus/sf12_defeated08.mp3" 

#define HELLFIRE "vo/halloween_merasmus/sf12_ranged_attack08.mp3" 
#define HELLFIRE2 "vo/halloween_merasmus/sf12_ranged_attack04.mp3" 
#define HELLFIRE3 "vo/halloween_merasmus/sf12_ranged_attack05.mp3" 

#define BOMB   "vo/halloween_merasmus/sf12_bombinomicon03.mp3" 
#define BOMB2  "vo/halloween_merasmus/sf12_bombinomicon09.mp3" 
#define BOMB3  "vo/halloween_merasmus/sf12_bombinomicon11.mp3" 
#define BOMB4  "vo/halloween_merasmus/sf12_bombinomicon14.mp3" 

#define LOL    "vo/halloween_merasmus/sf12_combat_idle01.mp3" 
#define LOL2   "vo/halloween_merasmus/sf12_combat_idle02.mp3" 

#define SND_THUNDER1 "/ambient_mp3/lair/rolling_thunder1.mp3"
#define SND_THUNDER2 "/ambient_mp3/lair/rolling_thunder2.mp3"
#define SND_THUNDER3 "/ambient_mp3/lair/rolling_thunder3.mp3"
#define SND_THUNDER4 "/ambient_mp3/lair/rolling_thunder4.mp3"
#define SND_THUNDER5 "/ambient_mp3/medieval_thunder2.mp3"
#define SND_THUNDER6 "/ambient_mp3/medieval_thunder3.mp3"
#define SND_THUNDER7 "/ambient_mp3/medieval_thunder4.mp3"
#define SND_WOLF1 "/ambient_mp3/wolf01.mp3"
#define SND_WOLF2 "/ambient_mp3/wolf02.mp3"
#define SND_WOLF3 "/ambient_mp3/wolf03.mp3"

#define SND_BANCHEE "/items/halloween/banshee01.wav"
#define SND_SCREAM1 "/ambient_mp3/halloween/female_scream_10.mp3"
#define SND_SCREAM2 "/ambient_mp3/halloween/female_scream_01.mp3"
#define SND_SCREAM3 "/ambient_mp3/halloween/female_scream_03.mp3"
#define SND_SCREAM4 "/ambient_mp3/halloween/female_scream_04.mp3"

#define TEAM_CLASSNAME "tf_team"

#define FIREBALL	0
#define BATS 		1
#define PUMPKIN 	2
#define TELE 		3
#define LIGHTNING 	4
#define BOSS 		5
#define METEOR 		6
#define ZOMBIEH 	7

#define ZOMBIE 		8
#define PUMPKIN2 	9

int iLastRand; 
Handle g_hCvarThirdPerson; 
bool g_bIsWizard[MAXPLAYERS + 1]; 
bool IsTaunting[MAXPLAYERS + 1]; 
bool ms = false; 
int lastTeam[MAXPLAYERS + 1];
Handle g_hSDKTeamAddPlayer;
Handle g_hSDKTeamRemovePlayer;
bool g_wait[MAXPLAYERS + 1];
int ParticleIndex;

public Plugin myinfo = 
{
	name = "[TF2] Be the Mighty Wizard Merasmus", 
	author = "Starman4xz, Mitch, Pelipoika, FlaminSarge, Tylerst, Benoist3012, modified by PC Gamer",
	description = "Play as the Wizard Merasmus", 
	version = PLUGIN_VERSION, 
	url = "www.sourcemod.com" 
} 

public void OnPluginStart() 
{ 
	Handle hGameData = LoadGameConfigFile("bewizard");
	
	StartPrepSDKCall(SDKCall_Entity);
	PrepSDKCall_SetFromConf(hGameData, SDKConf_Virtual, "CTeam::AddPlayer");
	PrepSDKCall_AddParameter(SDKType_CBasePlayer, SDKPass_Pointer);
	g_hSDKTeamAddPlayer = EndPrepSDKCall();
	if(g_hSDKTeamAddPlayer == INVALID_HANDLE)
	SetFailState("Could not find CTeam::AddPlayer!");
	
	StartPrepSDKCall(SDKCall_Entity);
	PrepSDKCall_SetFromConf(hGameData, SDKConf_Virtual, "CTeam::RemovePlayer");
	PrepSDKCall_AddParameter(SDKType_CBasePlayer, SDKPass_Pointer);
	g_hSDKTeamRemovePlayer = EndPrepSDKCall();
	if(g_hSDKTeamRemovePlayer == INVALID_HANDLE)
	SetFailState("Could not find CTeam::RemovePlayer!");
	
	delete hGameData;

	LoadTranslations("common.phrases"); 
	g_hCvarThirdPerson = CreateConVar("bewizard_thirdperson", "1", "Whether or not wizard ought to be in third-person", 0, true, 0.0, true, 1.0); 
	
	RegAdminCmd("sm_bewizard", Command_wizard, ADMFLAG_SLAY, "Make Player the Wizard Merasmus"); 

	HookEvent("player_activate", OnPlayerActivate, EventHookMode_Post); 
	HookEvent("player_death", Event_Death, EventHookMode_Post);
	HookEvent("player_death", Event_DeathPre, EventHookMode_Pre);
	HookEvent("teamplay_round_start", Event_Endround);
	HookEvent("teamplay_round_win", Event_Endround);
	HookEvent("teamplay_round_stalemate", Event_Endround);
} 	 

public void OnMapStart() 
{ 
	PrecacheModel(HHH); 
	PrecacheSound(SPAWN); 
	PrecacheSound(SPAWN2); 	
	PrecacheSound(DEATH);
	PrecacheSound(DEATH1);
	PrecacheSound(DEATH2);
	PrecacheSound(DEATH3);	
	PrecacheSound(DEATHBOSS);		
	PrecacheSound(DOOM1, true); 
	PrecacheSound(DOOM2, true); 
	PrecacheSound(DOOM3, true); 
	PrecacheSound(DOOM4, true); 

	PrecacheSound(HELLFIRE, true); 
	PrecacheSound(HELLFIRE2, true); 
	PrecacheSound(HELLFIRE3, true);
	
	PrecacheSound(BOMB, true); 
	PrecacheSound(BOMB2, true);     
	PrecacheSound(BOMB3, true);     
	PrecacheSound(BOMB4, true);     
	
	PrecacheSound(LOL, true); 
	PrecacheSound(LOL2, true);

	PrecacheSound(SND_THUNDER1);
	PrecacheSound(SND_THUNDER2);
	PrecacheSound(SND_THUNDER3);
	PrecacheSound(SND_THUNDER4);
	PrecacheSound(SND_THUNDER5);
	PrecacheSound(SND_THUNDER6);
	PrecacheSound(SND_THUNDER7);
	PrecacheSound(SND_WOLF1);
	PrecacheSound(SND_WOLF2);
	PrecacheSound(SND_WOLF3);

	PrecacheSound(SND_BANCHEE);
	PrecacheSound(SND_SCREAM1);
	PrecacheSound(SND_SCREAM2);	
	PrecacheSound(SND_SCREAM3);	
	PrecacheSound(SND_SCREAM4);
} 

public Action OnPlayerActivate(Handle hEvent, const char[] strEventName, bool dontBroadcast )
{
	int client = GetClientOfUserId( GetEventInt( hEvent, "userid" ) );
	if( !IsValidClient(client) )
	return;

	g_bIsWizard[client] = false;
	
	SDKHook( client, SDKHook_OnTakeDamage, OnTakeDamage );
}

public void OnClientDisconnect(int client) 
{
	SDKUnhook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

public Action Event_DeathPre(Handle event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "attacker"));
	char weapon[20];
	GetEventString(event, "weapon", weapon, sizeof(weapon));
	if(g_bIsWizard[client])
	{
		if(StrEqual(weapon, "club", false))
		{
			SetEventString(event, "weapon", "merasmus_decap");
			SetEventString(event, "weapon_logclassname", "merasmus_decap");
		}
		else if(StrEqual(weapon, "flamethrower", false))
		{
			SetEventString(event, "weapon", "merasmus_zap");
			SetEventString(event, "weapon_logclassname", "merasmus_zap");
		}
		else if(StrEqual(weapon, "env_explosion", false))
		{
			SetEventString(event, "weapon", "merasmus_grenade");
			SetEventString(event, "weapon_logclassname", "merasmus_grenade");
		}
	}
}

public Action Event_Death(Handle event, const char[] name, bool dontBroadcast) 
{ 
	int client = GetClientOfUserId(GetEventInt(event, "userid")); 
	int deathflags = GetEventInt(event, "death_flags"); 
	if (!(deathflags & TF_DEATHFLAG_DEADRINGER)) 
	{ 
		if (IsValidClient(client) && g_bIsWizard[client]) 
		{ 
			ChangeClientTeamEx(client, lastTeam[client]);
			TF2Attrib_RemoveAll(client); 
			int weapon = GetPlayerWeaponSlot(client, 2);  
			TF2Attrib_RemoveAll(weapon);             
			SetWearableAlpha(client, 255);                 
			EmitSoundToAll(DEATH); 
			EmitSoundToAll(DEATHBOSS);			
			SetVariantInt(0); 
			AcceptEntityInput(client, "SetForcedTauntCam"); 
			RemoveModel(client);
			g_bIsWizard[client] = false;  			
			ms = false; 			
			CreateTimer(0.1, ResetSpeed, client);			
		} 
	} 
} 

public Action Event_Endround(Handle event, const char[] name, bool dontBroadcast)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (g_bIsWizard[i])
		{
			g_bIsWizard[i] = false;
			
			RemoveModel(i); 
			
			ChangeClientTeamEx(i, lastTeam[i]);
			
			TF2Attrib_RemoveAll(i); 
			int weapon = GetPlayerWeaponSlot(i, 2);
			if (IsValidWeapon(weapon))	
			{
				TF2Attrib_RemoveAll(weapon);
			} 
			
			SetVariantInt(0); 
			AcceptEntityInput(i, "SetForcedTauntCam");
			
			SetWearableAlpha(i, 255);                 
			ForcePlayerSuicide(i);	
			EmitSoundToAll(DEATH); 
			EmitSoundToAll(DEATHBOSS);

			RemoveModel(i); 			
			
			ms = false; 
			CreateTimer(0.1, ResetSpeed, i);	
		}
	}
}

Action SetModel(int client, const char[] model) 
{ 
	if (IsValidClient(client) && IsPlayerAlive(client)) 
	{ 
		RemoveModel(client); 
		
		SetVariantString(model); 
		AcceptEntityInput(client, "SetCustomModel"); 

		SetEntProp(client, Prop_Send, "m_bUseClassAnimations", 1); 
		SetWearableAlpha(client, 0);
		
		BuildParticle(client, "merasmus_ambient_body");		
	} 
} 

Action RemoveModel(int client) 
{ 
	if (IsValidClient(client) && g_bIsWizard[client])
	{ 
		RemoveParticle();

		TF2Attrib_RemoveAll(client);
		
		int weapon = GetPlayerWeaponSlot(client, 2);  
		TF2Attrib_RemoveAll(weapon); 
		SetEntPropFloat(client, Prop_Send, "m_flModelScale", 1.0); 
		UpdatePlayerHitbox(client, 2.0); 

		SetSpell2(client, 0, 0); 

		SetVariantString(""); 
		AcceptEntityInput(client, "SetCustomModel"); 
		SetWearableAlpha(client, 255);
	} 
} 

public Action Command_wizard(int client, int args) 
{ 
	char arg1[32];
	if (args < 1)
	{
		arg1 = "@me";
	}
	else GetCmdArg(1, arg1, sizeof(arg1));
	char target_name[MAX_TARGET_LENGTH];
	int target_list[MAXPLAYERS], target_count;
	bool tn_is_ml;

	if ((target_count = ProcessTargetString(
					arg1,
					client,
					target_list,
					MAXPLAYERS,
					COMMAND_FILTER_ALIVE|(args < 1 ? COMMAND_FILTER_NO_IMMUNITY : 0),
					target_name,
					sizeof(target_name),
					tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
	for (int i = 0; i < target_count; i++)
	{ 
		Makewizard(target_list[i]);     
	} 
	return Plugin_Handled; 
} 

Action Makewizard(int client) 
{ 
	lastTeam[client] = GetClientTeam(client); 
	float origin[3];
	float angles[3]; 
	GetClientAbsOrigin(client, origin); 
	GetClientAbsAngles(client, angles); 
	ChangeClientTeamEx(client, 0); 

	TF2_SetPlayerClass(client, TFClass_Sniper); 
	TF2_RespawnPlayer(client);
	
	TeleportEntity(client, origin, angles, NULL_VECTOR);

	CreateTimer(1.0, Makemelee, client); 	
	
	int ragdoll = GetEntPropEnt(client, Prop_Send, "m_hRagdoll"); 
	if (ragdoll > MaxClients && IsValidEntity(ragdoll)) AcceptEntityInput(ragdoll, "Kill"); 

	SetModel(client, HHH); 

	if (GetConVarBool(g_hCvarThirdPerson)) 
	{ 
		SetVariantInt(1); 
		AcceptEntityInput(client, "SetForcedTauntCam"); 
	} 
	
	SetEntPropFloat(client, Prop_Send, "m_flModelScale", 1.0); 
	UpdatePlayerHitbox(client, 2.0); 
	
	g_bIsWizard[client] = true;
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
	Command_getms1(); 

	EmitSoundToAll(SPAWN); 
	EmitSoundToAll(SPAWN2);		

	PrintToChat(client, "You are the might Wizard Merasmus!");
	PrintToChat(client, "Wizard Commands: Use Right-Click to launch players,");
	PrintToChat(client, "You have 500 Fireball Spells.  Use 'H' to cast Fireball spell,");
	PrintToChat(client, "Use 'R' to throw bombs,");
	PrintToChat(client, "Use Mouse3 button (press down on mousewheel) to cast Lightning Spell");
	PrintToChat(client, "You can attack BOTH Teams.");
	
	PrintCenterText(client, "Wizard Commands: Use Right-Click to launch players, Use 'H' to cast Fireball spell, Use 'R' to throw bombs, Use Mouse3 button (press down on mousewheel) to cast Lightning Spell, You can attack BOTH Teams.");	
} 

void UpdatePlayerHitbox(const int client, const float fScale) 
{ 
	static const float vecTF2PlayerMin[3] = { -24.5, -24.5, 0.0 };
	static const float vecTF2PlayerMax[3] = { 24.5,  24.5, 83.0 }; 
	
	float vecScaledPlayerMin[3];
	float vecScaledPlayerMax[3]; 

	vecScaledPlayerMin = vecTF2PlayerMin; 
	vecScaledPlayerMax = vecTF2PlayerMax; 
	
	ScaleVector(vecScaledPlayerMin, fScale); 
	ScaleVector(vecScaledPlayerMax, fScale); 
	
	SetEntPropVector(client, Prop_Send, "m_vecSpecifiedSurroundingMins", vecScaledPlayerMin); 
	SetEntPropVector(client, Prop_Send, "m_vecSpecifiedSurroundingMaxs", vecScaledPlayerMax); 
} 

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon) 
{ 
	if (GetEntityFlags(client) & FL_ONGROUND && g_bIsWizard[client] == true) 
	{ 
		if(buttons & IN_ATTACK3 && IsTaunting[client] != true && g_bIsWizard[client] == true && g_wait[client] == false)         
		{ 
			ShootProjectile(client, LIGHTNING);
			g_wait[client] = true;
			CreateTimer(3.0, Waiting, client);
		}
		else if (buttons & IN_ATTACK2 && g_bIsWizard[client] == true && IsTaunting[client] != true && g_bIsWizard[client] == true) 
		{  
			MakePlayerInvisible(client, 0); 
			
			int Model = CreateEntityByName("prop_dynamic"); 
			if (IsValidEdict(Model)) 
			{ 
				IsTaunting[client] = true; 
				float pos[3];
				float ang[3]; 
				char ClientModel[256]; 
				
				GetClientModel(client, ClientModel, sizeof(ClientModel)); 
				GetEntPropVector(client, Prop_Send, "m_vecOrigin", pos); 
				TeleportEntity(Model, pos, NULL_VECTOR, NULL_VECTOR); 
				GetClientEyeAngles(client, ang); 
				ang[0] = 0.0; 
				ang[2] = 0.0; 

				DispatchKeyValue(Model, "model", ClientModel); 
				DispatchKeyValue(Model, "DefaultAnim", "zap_attack");     
				DispatchKeyValueVector(Model, "angles", ang); 
				
				DispatchSpawn(Model); 
				
				SetVariantString("OnAnimationDone !self:KillHierarchy::0.0:1"); 
				AcceptEntityInput(Model, "AddOutput"); 
				
				CreateTimer(1.0, DoHellfire, client); 
				SetEntityMoveType(client, MOVETYPE_NONE); 
				PlayHellfire(); 
				
				CreateTimer(2.8, ResetTaunt, client); 
				SetWeaponsAlpha(client, 0);                 
			} 
		} 
		else if(buttons & IN_RELOAD && IsTaunting[client] != true && g_bIsWizard[client] == true)         
		{ 
			MakePlayerInvisible(client, 0); 

			SetVariantInt(1); 
			AcceptEntityInput(client, "SetForcedTauntCam"); 
			
			int Model = CreateEntityByName("prop_dynamic"); 
			if (IsValidEdict(Model)) 
			{ 
				IsTaunting[client] = true; 
				float posc[3];
				float ang[3]; 
				char ClientModel[256]; 
				
				GetClientModel(client, ClientModel, sizeof(ClientModel)); 
				GetEntPropVector(client, Prop_Send, "m_vecOrigin", posc); 
				TeleportEntity(Model, posc, NULL_VECTOR, NULL_VECTOR); 
				GetClientEyeAngles(client, ang); 
				ang[0] = 0.0; 
				ang[2] = 0.0; 

				DispatchKeyValue(Model, "model", ClientModel); 
				DispatchKeyValue(Model, "DefaultAnim", "bomb_attack");     
				DispatchKeyValueVector(Model, "angles", ang); 
				
				DispatchSpawn(Model); 
				
				SetVariantString("OnAnimationDone !self:KillHierarchy::0.0:1"); 
				AcceptEntityInput(Model, "AddOutput"); 
				
				SetEntityMoveType(client, MOVETYPE_NONE); 
				Playbombsound(); 
				CreateTimer(3.0, StartBombAttack, client); 
				SetWeaponsAlpha(client, 0); 
			}
		}
		if(buttons & IN_ATTACK && IsTaunting[client] == true && g_bIsWizard[client] == true)         
		{ 
			return Plugin_Handled;
		}
	} 
	return Plugin_Continue; 
} 

public Action ResetTaunt(Handle timer, any client) 
{ 
	if (g_bIsWizard[client])
	{
		IsTaunting[client] = false; 
		MakePlayerInvisible(client, 255); 
		SetEntityMoveType(client, MOVETYPE_ISOMETRIC);
	}
} 

Action MakePlayerInvisible(int client, int alpha) 
{ 
	SetWeaponsAlpha(client, alpha); 
	SetWearableAlpha(client, alpha); 
	SetEntityRenderMode(client, RENDER_TRANSCOLOR); 
	SetEntityRenderColor(client, 255, 255, 255, alpha); 
} 

Action SetWeaponsAlpha (int client, int alpha) 
{ 
	char classname[64]; 
	int m_hMyWeapons = FindSendPropInfo("CBasePlayer", "m_hMyWeapons"); 
	for(int m = 0, weapon; m < 189; m += 4) 
	{ 
		weapon = GetEntDataEnt2(client, m_hMyWeapons + m); 
		if(weapon > -1 && IsValidEdict(weapon)) 
		{ 
			GetEdictClassname(weapon, classname, sizeof(classname)); 
			if(StrContains(classname, "tf_weapon", false) != -1 || StrContains(classname, "tf_wearable", false) != -1) 
			{ 
				SetEntityRenderMode(weapon, RENDER_TRANSCOLOR); 
				SetEntityRenderColor(weapon, 255, 255, 255, alpha); 
			} 
		} 
	} 
} 

Action DoHellfire(Handle timer, any client) 
{ 
	float vec[3]; 
	GetClientEyePosition(client, vec); 
	
	
	for(int k=1; k<=MaxClients; k++) 
	{ 
		if(!IsClientInGame(k) || !IsPlayerAlive(k)) continue; 
		
		float pos[3]; 
		GetClientEyePosition(k, pos); 
		
		float distance = GetVectorDistance(vec, pos); 
		
		float dist = 310.0; 
		
		
		if(distance < dist) 
		{ 
			if (k == client) continue; 
			
			float vecc[3]; 
			
			vecc[0] = 0.0; 
			vecc[1] = 0.0; 
			vecc[2] = 1500.0; 
			
			int iInflictor = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
			SDKHooks_TakeDamage(k, iInflictor, client, 30.0);
			TeleportEntity(k, NULL_VECTOR, NULL_VECTOR, vecc); 
			TF2_IgnitePlayer(k, client); 
		} 
	} 
} 

Action PlayHellfire() 
{ 
	int soundswitch; 
	soundswitch = GetRandomInt(1, 3); 

	
	switch(soundswitch) 
	{ 
	case 1: 
		{ 
			EmitSoundToAll(HELLFIRE); 
		} 
		
	case 2: 
		{ 
			EmitSoundToAll(HELLFIRE2); 
		} 
		
	case 3: 
		{ 
			EmitSoundToAll(HELLFIRE3); 
		} 
	} 
} 

bool IsValidClient(int client) 
{ 
	if (client <= 0) return false; 
	if (client > MaxClients) return false; 
	return IsClientInGame(client); 
} 

Action TF2_RemoveAllWearables(int client) 
{ 
	int wearable = -1; 
	while ((wearable = FindEntityByClassname(wearable, "tf_wearable*")) != -1) 
	{ 
		if (IsValidEntity(wearable)) 
		{ 
			int player = GetEntPropEnt(wearable, Prop_Send, "m_hOwnerEntity"); 
			if (client == player) 
			{ 
				TF2_RemoveWearable(client, wearable); 
			} 
		} 
	} 

	while ((wearable = FindEntityByClassname(wearable, "tf_powerup_bottle")) != -1) 
	{ 
		if (IsValidEntity(wearable)) 
		{ 
			int player = GetEntPropEnt(wearable, Prop_Send, "m_hOwnerEntity"); 
			if (client == player) 
			{ 
				TF2_RemoveWearable(client, wearable); 
			} 
		} 
	} 

	while ((wearable = FindEntityByClassname(wearable, "tf_weapon_spellbook")) != -1) 
	{ 
		if (IsValidEntity(wearable)) 
		{ 
			int player = GetEntPropEnt(wearable, Prop_Send, "m_hOwnerEntity"); 
			if (client == player) 
			{ 
				TF2_RemoveWearable(client, wearable); 
			} 
		} 
	} 
} 

Action SetWearableAlpha(int client, int alpha) 
{ 
	int count; 
	for (int z = MaxClients + 1; z <= 2048; z++) 
	{ 
		if (!IsValidEntity(z)) continue; 
		char cls[35]; 
		GetEntityClassname(z, cls, sizeof(cls)); 
		if (!StrEqual(cls, "tf_wearable") && !StrEqual(cls, "tf_powerup_bottle")) continue; 
		if (client != GetEntPropEnt(z, Prop_Send, "m_hOwnerEntity")) continue; 
		{ 
			SetEntityRenderMode(z, RENDER_TRANSCOLOR); 
			SetEntityRenderColor(z, 255, 255, 255, alpha); 
		} 
		if (alpha == 0) AcceptEntityInput(z, "Kill"); 
		count++; 
	} 
	return; 
} 

Action Command_getms1() 
{  
	int soundswitch; 
	soundswitch = GetRandomInt(1, 4);     
	switch(soundswitch) 
	{ 
	case 1: 
		{ 
			EmitSoundToAll(DOOM1); 
		} 
	case 2: 
		{ 
			EmitSoundToAll(DOOM2); 
		} 
	case 3: 
		{ 
			EmitSoundToAll(DOOM3); 
		} 
	case 4: 
		{ 
			EmitSoundToAll(DOOM4); 
		} 
	} 
	ms = true; 
	CreateTimer(10.0, Command_getms2);     
} 

Action Command_getms2(Handle timer) 
{  
	if (ms == false) 
	{ 
		return Plugin_Handled; 
	} 
	int soundswitch2; 
	soundswitch2 = GetRandomInt(1, 2);     
	switch(soundswitch2) 
	{ 
	case 1: 
		{ 
			EmitSoundToAll(LOL); 
		} 
	case 2: 
		{ 
			EmitSoundToAll(LOL2); 
		} 
	}     
	CreateTimer(10.0, Command_GetmsRandom); 
	
	return Plugin_Handled; 
} 

Action Command_GetmsRandom(Handle timer) 
{ 
	int iRand = GetRandomInt(1,11); 
	if (iRand == iLastRand) 
	{ 
		iRand = GetRandomInt(1,11);     
	} 
	if (iRand == iLastRand) 
	{ 
		iRand = GetRandomInt(1,11);     
	}     
	switch(iRand) 
	{ 
	case 1: 
		{ 
			EmitSoundToAll(HELLFIRE); 
		} 
	case 2: 
		{ 
			EmitSoundToAll(HELLFIRE2);             
		} 
	case 3: 
		{ 
			EmitSoundToAll(BOMB);                 
		} 
	case 4: 
		{ 
			EmitSoundToAll(BOMB2);                 
		} 
	case 5: 
		{ 
			EmitSoundToAll(DOOM1);             
		} 
	case 6: 
		{ 
			EmitSoundToAll(DOOM2);                 
		} 
	case 7: 
		{ 
			EmitSoundToAll(DOOM3);                 
		} 
	case 8: 
		{ 
			EmitSoundToAll(DOOM4);                 
		} 
	case 9: 
		{ 
			EmitSoundToAll(LOL);             
		} 
	case 10: 
		{ 
			EmitSoundToAll(LOL2);             
		} 
	case 11: 
		{ 
			EmitSoundToAll(LOL);         
		}             
	} 
	iLastRand = iRand; 

	CreateTimer(5.0, Command_getms3); 
	
	return Plugin_Handled; 
} 

Action Command_getms3(Handle timer) 
{ 
	if (ms == false) 
	{ 
		return Plugin_Handled; 
	} 
	
	int soundswitch3; 
	soundswitch3 = GetRandomInt(1, 11);     
	switch(soundswitch3) 
	{ 
	case 1: 
		{ 
			EmitSoundToAll(SND_BANCHEE); 
		} 
	case 2: 
		{ 
			EmitSoundToAll(SND_WOLF1);             
		} 
	case 3: 
		{ 
			EmitSoundToAll(SND_WOLF2);                 
		} 
	case 4: 
		{ 
			EmitSoundToAll(SND_BANCHEE);                 
		} 
	case 5: 
		{ 
			EmitSoundToAll(SND_BANCHEE);             
		} 
	case 6: 
		{ 
			EmitSoundToAll(SND_SCREAM1);                 
		} 
	case 7: 
		{ 
			EmitSoundToAll(SND_SCREAM2);                 
		} 
	case 8: 
		{ 
			EmitSoundToAll(SND_SCREAM3);                 
		} 
	case 9: 
		{ 
			EmitSoundToAll(SND_SCREAM4);             
		} 
	case 10: 
		{ 
			EmitSoundToAll(SND_BANCHEE);             
		} 
	case 11: 
		{ 
			EmitSoundToAll(SND_SCREAM1);         
		}             
	} 

	CreateTimer(10.0, Command_ms4); 
	
	return Plugin_Handled; 
} 

Action Command_ms4(Handle timer) 
{  
	if (ms == false) 
	{ 
		return Plugin_Handled; 
	} 
	int soundswitch1; 
	soundswitch1 = GetRandomInt(1, 7);     
	switch(soundswitch1) 
	{ 
	case 1: 
		{ 
			EmitSoundToAll(SND_THUNDER1); 
		} 
	case 2: 
		{ 
			EmitSoundToAll(SND_THUNDER2); 
		} 
	case 3: 
		{ 
			EmitSoundToAll(SND_THUNDER3); 
		} 
	case 4: 
		{ 
			EmitSoundToAll(SND_THUNDER4); 
		}
	case 5: 
		{ 
			EmitSoundToAll(SND_THUNDER5); 
		} 
	case 6: 
		{ 
			EmitSoundToAll(SND_THUNDER6); 
		} 
	case 7: 
		{ 
			EmitSoundToAll(SND_THUNDER7); 
		} 		
	} 

	CreateTimer(10.0, Command_getms2);

	return Plugin_Handled;	
}

Action forceSpellbook(int client) 
{ 
	Handle hWeapon = TF2Items_CreateItem(OVERRIDE_ALL|FORCE_GENERATION); 
	TF2Items_SetClassname(hWeapon, "tf_weapon_spellbook"); 
	TF2Items_SetItemIndex(hWeapon, 1070); 
	TF2Items_SetLevel(hWeapon, 100); 
	TF2Items_SetQuality(hWeapon, 6); 
	TF2Items_SetNumAttributes(hWeapon, 1); 
	TF2Items_SetAttribute(hWeapon, 0, 547, 0.5); 

	int entity = TF2Items_GiveNamedItem(client, hWeapon); 
	CloseHandle(hWeapon); 
	EquipPlayerWeapon(client, entity); 
	return; 
} 

void SetSpell2(int client, int spell, int uses) 
{ 
	int spellbook = GetSpellBook(client);
	if(!IsValidEntity(spellbook)) return; 
	SetEntProp(spellbook, Prop_Send, "m_iSelectedSpellIndex", spell); 
	SetEntProp(spellbook, Prop_Send, "m_iSpellCharges", uses); 
}   

int GetSpellBook(int client) 
{ 
	int entity = -1; 
	while((entity = FindEntityByClassname(entity, "tf_weapon_spellbook")) != INVALID_ENT_REFERENCE) 
	{ 
		int ref = EntIndexToEntRef(entity);
		if(GetEntPropEnt(ref, Prop_Send, "m_hOwnerEntity") == client) return ref; 
	} 
	return -1; 
} 

Action Playbombsound() 
{ 
	int soundswitch; 
	soundswitch = GetRandomInt(1, 4);     
	switch(soundswitch) 
	{ 
	case 1: 
		{ 
			EmitSoundToAll(BOMB); 
		} 
	case 2: 
		{ 
			EmitSoundToAll(BOMB2); 
		} 
	case 3: 
		{ 
			EmitSoundToAll(BOMB3); 
		} 
	case 4: 
		{ 
			EmitSoundToAll(BOMB4); 
		} 
	} 
} 

Action StartBombAttack(Handle timer, any client) 
{ 
	Handle BTime = CreateTimer(2.0, CreateBomb, client, TIMER_REPEAT); 
	CreateTimer(11.75, ResetTaunt, client); 
	CreateTimer(11.0, KillBombs, BTime); 
	TimedParticle(client, "merasmus_book_attack", 11.0); 
} 

Action CreateBomb(Handle timer, any client) 
{ 
	if(g_bIsWizard[client] == true) 
	{ 
		SpawnClusters(client); 
	} 
} 
Action KillBombs(Handle timer, any Btimer) 
{ 
	KillTimer(Btimer); 
} 

Action SpawnClusters(int ent) 
{ 
	if (IsValidEntity(ent)) 
	{ 
		float bombSpreadVel = 50.0; 
		float bombVertVel = 90.0; 
		int bombVariation = 2; 
		
		float pos[3]; 
		GetClientEyePosition(ent, pos); 
		pos[2] += 105.0; 
		
		float ang[3]; 
		
		for (int j = 0; j < 11; j++) 
		{ 
			ang[0] = ((GetURandomFloat() + 0.1) * bombSpreadVel - bombSpreadVel / 2.0) * ((GetURandomFloat() + 0.1) * bombVariation); 
			ang[1] = ((GetURandomFloat() + 0.1) * bombSpreadVel - bombSpreadVel / 2.0) * ((GetURandomFloat() + 0.1) * bombVariation); 
			ang[2] = ((GetURandomFloat() + 0.1) * bombVertVel) * ((GetURandomFloat() + 0.1) * bombVariation); 

			int ent2 = CreateEntityByName("prop_physics_override"); 

			if(ent2 != -1) 
			{                     
				DispatchKeyValue(ent2, "model", BOMBMODEL); 
				DispatchKeyValue(ent2, "solid", "6"); 
				DispatchKeyValue(ent2, "renderfx", "0"); 
				DispatchKeyValue(ent2, "rendercolor", "255 255 255"); 
				DispatchKeyValue(ent2, "renderamt", "255"); 
				SetEntPropEnt(ent2, Prop_Data, "m_hOwnerEntity", ent); 
				DispatchSpawn(ent2); 
				TeleportEntity(ent2, pos, NULL_VECTOR, ang); 

				CreateTimer((GetURandomFloat() + 0.1) / 1.75 + 0.5, ExplodeBomblet, ent2, TIMER_FLAG_NO_MAPCHANGE); 
			}             
		} 
	} 
} 

Action ExplodeBomblet(Handle timer, any ent) 
{ 
	if (IsValidEntity(ent)) 
	{ 
		float pos[3]; 
		GetEntPropVector(ent, Prop_Data, "m_vecOrigin", pos); 
		pos[2] += 32.0; 

		int client = GetEntPropEnt(ent, Prop_Data, "m_hOwnerEntity"); 
		if (!IsValidClient(client))
		{
			return;
		}
		int team = GetEntProp(client, Prop_Send, "m_iTeamNum"); 

		AcceptEntityInput(ent, "Kill"); 
		int BombMagnitude = 120; 
		int explosion = CreateEntityByName("env_explosion"); 
		if (explosion != -1) 
		{ 
			char tMag[8]; 
			IntToString(BombMagnitude, tMag, sizeof(tMag)); 
			DispatchKeyValue(explosion, "iMagnitude", tMag); 
			DispatchKeyValue(explosion, "spawnflags", "0"); 
			DispatchKeyValue(explosion, "rendermode", "5"); 
			SetEntProp(explosion, Prop_Send, "m_iTeamNum", team); 
			SetEntPropEnt(explosion, Prop_Data, "m_hOwnerEntity", client); 
			DispatchSpawn(explosion); 
			ActivateEntity(explosion); 

			TeleportEntity(explosion, pos, NULL_VECTOR, NULL_VECTOR);                 
			AcceptEntityInput(explosion, "Explode"); 
			AcceptEntityInput(explosion, "Kill"); 
		}         
	} 
} 
Action TimedParticle(int client, const char path[32], float FTime) 
{ 
	int TParticle = CreateEntityByName("info_particle_system"); 
	if (IsValidEdict(TParticle)) 
	{ 
		float pos[3]; 
		GetEntPropVector(client, Prop_Send, "m_vecOrigin", pos); 
		
		TeleportEntity(TParticle, pos, NULL_VECTOR, NULL_VECTOR); 
		
		DispatchKeyValue(TParticle, "effect_name", path); 
		
		DispatchKeyValue(TParticle, "targetname", "particle"); 
		
		SetVariantString("!activator"); 
		AcceptEntityInput(TParticle, "SetParent", client, TParticle, 0); 
		
		DispatchSpawn(TParticle); 
		ActivateEntity(TParticle); 
		AcceptEntityInput(TParticle, "Start"); 
		CreateTimer(FTime, KillTParticle, TParticle); 
	} 
}
 
Action KillTParticle(Handle timer, any index) 
{ 
	if (IsValidEntity(index)) 
	{ 
		AcceptEntityInput(index, "Kill"); 
	} 
}  

Action ResetSpeed(Handle timer, any client)
{
	TF2_StunPlayer(client, 0.0, 0.0, TF_STUNFLAG_SLOWDOWN);
}

public Action OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{
	if(!IsValidClient(victim) || !IsValidClient(attacker) || !g_bIsWizard[attacker])
	return Plugin_Continue;

	if(g_bIsWizard[attacker] &&  !g_bIsWizard[victim])
	damage = damage * 5.0;
	
	if(g_bIsWizard[attacker] &&  g_bIsWizard[victim])
	damage = 0.0;
	
	return Plugin_Changed;
} 

Action TF2_SwitchtoSlot(int client, int slot)
{
	if (slot >= 0 && slot <= 5 && IsClientInGame(client) && IsPlayerAlive(client))
	{
		char wepclassname[64];
		int wep = GetPlayerWeaponSlot(client, slot);
		if (wep > MaxClients && IsValidEdict(wep) && GetEdictClassname(wep, wepclassname, sizeof(wepclassname)))
		{
			FakeClientCommandEx(client, "use %s", wepclassname);
			SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", wep);
		}
	}
}

Action Makemelee(Handle timer, any client) 
{ 
	SetModel(client, HHH);

	TF2_RemoveAllWearables(client);	
	TF2_RemoveWeaponSlot(client, 5);
	TF2_RemoveWeaponSlot(client, 4);
	TF2_RemoveWeaponSlot(client, 3);
	TF2_RemoveWeaponSlot(client, 1);
	TF2_RemoveWeaponSlot(client, 0);

	Handle hWeapon = TF2Items_CreateItem(OVERRIDE_ALL|FORCE_GENERATION);
	if (hWeapon != INVALID_HANDLE)
	{
		TF2Items_SetClassname(hWeapon, "tf_weapon_club");
		TF2Items_SetItemIndex(hWeapon, 3);
		TF2Items_SetLevel(hWeapon, 100);
		TF2Items_SetQuality(hWeapon, 5);
		
		int weapon = TF2Items_GiveNamedItem(client, hWeapon);
		EquipPlayerWeapon(client, weapon);

		CloseHandle(hWeapon);

		SetEntProp(weapon, Prop_Send, "m_nModelIndexOverrides", -1);
	}


	TF2_SwitchtoSlot(client, TFWeaponSlot_Melee);	

	SetEntProp(client, Prop_Send, "m_iHealth", 5000, 1);
	SetEntProp(client, Prop_Data, "m_iHealth", 5000, 1);
	TF2_AddCondition(client, TFCond_SpeedBuffAlly, 0.1);	

	TF2Attrib_RemoveAll(client); 	
	TF2Attrib_SetByName(client, "max health additive bonus", 4875.0); 
	TF2Attrib_SetByName(client, "health from packs decreased", 0.001); 
	TF2Attrib_SetByName(client, "major move speed bonus", 100.0);
	TF2Attrib_SetByName(client, "increased jump height", 1.0);	
	TF2Attrib_SetByName(client, "cancel falling damage", 1.0);             
	TF2Attrib_SetByName(client, "dmg taken from blast reduced", 0.5); 
	TF2Attrib_SetByName(client, "dmg taken from fire reduced", 0.5); 
	TF2Attrib_SetByName(client, "dmg taken from bullets reduced", 0.5); 
	TF2Attrib_SetByName(client, "dmg taken from crit reduced", 0.5); 
	TF2Attrib_SetByName(client, "dmg from ranged reduced", 0.5); 
	TF2Attrib_SetByName(client, "SET BONUS: dmg from sentry reduced", 0.5);  
	TF2Attrib_SetByName(client, "damage force reduction", 0.5);                 
	TF2Attrib_SetByName(client, "major increased jump height", 1.5); 
	TF2Attrib_SetByName(client, "parachute attribute", 1.0); 
	TF2Attrib_SetByName(client, "cannot be backstabbed", 1.0); 
	TF2Attrib_SetByName(client, "increased air control", 20.0);     
	TF2Attrib_SetByName(client, "airblast vulnerability multiplier", 0.0); 
	TF2Attrib_SetByName(client, "airblast vertical vulnerability multiplier", 0.0); 
	TF2Attrib_SetByName(client, "cannot pick up intelligence", 1.0); 

	int Weapon3 = GetPlayerWeaponSlot(client, 2);
	TF2Attrib_RemoveAll(Weapon3); 	
	TF2Attrib_SetByName(Weapon3, "melee attack rate bonus", 0.3);	
	TF2Attrib_SetByName(Weapon3, "melee bounds multiplier", 12.0);					
	TF2Attrib_SetByName(Weapon3, "melee range multiplier", 12.0);
	TF2Attrib_SetByName(Weapon3, "damage bonus", 30.0);
	TF2Attrib_SetByName(Weapon3, "armor piercing", 300.0);
	TF2Attrib_SetByName(Weapon3, "turn to gold", 1.0);
	TF2Attrib_SetByName(Weapon3, "speed buff ally", 1.0);
	TF2Attrib_SetByName(Weapon3, "attack_minicrits_and_consumes_burning", 1.0);
	TF2Attrib_SetByName(Weapon3, "item style override", 1.0);
	TF2Attrib_SetByName(Weapon3, "is australium item", 1.0);
	TF2Attrib_SetByName(Weapon3, "dmg pierces resists absorbs", 1.0);
	TF2Attrib_SetByName(Weapon3, "dmg bonus vs buildings", 20.0);
	
	forceSpellbook(client); 
	SetSpell2(client, 0, 500);
}

bool IsValidWeapon(int weapon)
{
	if (!IsValidEntity(weapon))
	return false;
	
	char class[64];
	GetEdictClassname(weapon, class, sizeof(class));
	
	if (strncmp(class, "tf_weapon_", 10) == 0 || strncmp(class, "tf_wearable_demoshield", 22) == 0)
	return true;
	
	return false;
}

void ChangeClientTeamEx(int iClient, int iNewTeamNum)
{
	int iTeamNum = GetEntProp(iClient, Prop_Send, "m_iTeamNum");
	
	// Safely swap team
	int iTeam = MaxClients+1;
	while ((iTeam = FindEntityByClassname(iTeam, TEAM_CLASSNAME)) != -1)
	{
		int iAssociatedTeam = GetEntProp(iTeam, Prop_Send, "m_iTeamNum");
		if (iAssociatedTeam == iTeamNum)
		SDK_Team_RemovePlayer(iTeam, iClient);
		else if (iAssociatedTeam == iNewTeamNum)
		SDK_Team_AddPlayer(iTeam, iClient);
	}
	
	SetEntProp(iClient, Prop_Send, "m_iTeamNum", iNewTeamNum);
}

void SDK_Team_AddPlayer(int iTeam, int iClient)
{
	if (g_hSDKTeamAddPlayer != INVALID_HANDLE)
	{
		SDKCall(g_hSDKTeamAddPlayer, iTeam, iClient);
	}
}

void SDK_Team_RemovePlayer(int iTeam, int iClient)
{
	if (g_hSDKTeamRemovePlayer != INVALID_HANDLE)
	{
		SDKCall(g_hSDKTeamRemovePlayer, iTeam, iClient);
	}
}

int ShootProjectile(int client, int spell)
{
	float vAngles[3]; 
	float vPosition[3]; 
	GetClientEyeAngles(client, vAngles);
	GetClientEyePosition(client, vPosition);
	char strEntname[45] = "";
	switch(spell)
	{
	case FIREBALL: 		strEntname = "tf_projectile_spellfireball";
	case LIGHTNING: 	strEntname = "tf_projectile_lightningorb";
	case PUMPKIN: 		strEntname = "tf_projectile_spellmirv";
	case PUMPKIN2: 		strEntname = "tf_projectile_spellpumpkin";
	case BATS: 			strEntname = "tf_projectile_spellbats";
	case METEOR: 		strEntname = "tf_projectile_spellmeteorshower";
	case TELE: 			strEntname = "tf_projectile_spelltransposeteleport";
	case BOSS:			strEntname = "tf_projectile_spellspawnboss";
	case ZOMBIEH:		strEntname = "tf_projectile_spellspawnhorde";
	case ZOMBIE:		strEntname = "tf_projectile_spellspawnzombie";
	}
	int iTeam = GetClientTeam(client);
	int iSpell = CreateEntityByName(strEntname);
	
	if(!IsValidEntity(iSpell))
	return -1;
	
	float vVelocity[3];
	float vBuffer[3];
	
	GetAngleVectors(vAngles, vBuffer, NULL_VECTOR, NULL_VECTOR);
	
	vVelocity[0] = vBuffer[0]*1100.0; 
	vVelocity[1] = vBuffer[1]*1100.0;
	vVelocity[2] = vBuffer[2]*1100.0;
	
	SetEntPropEnt(iSpell, Prop_Send, "m_hOwnerEntity", client);
	SetEntProp(iSpell,    Prop_Send, "m_bCritical", (GetRandomInt(0, 100) <= 5)? 1 : 0, 1);
	SetEntProp(iSpell,    Prop_Send, "m_iTeamNum",     iTeam, 1);
	SetEntProp(iSpell,    Prop_Send, "m_nSkin", (iTeam-2));
	
	TeleportEntity(iSpell, vPosition, vAngles, NULL_VECTOR);
	
	SetVariantInt(iTeam);
	AcceptEntityInput(iSpell, "TeamNum", -1, -1, 0);
	SetVariantInt(iTeam);
	AcceptEntityInput(iSpell, "SetTeam", -1, -1, 0); 
	
	DispatchSpawn(iSpell);

	TeleportEntity(iSpell, NULL_VECTOR, NULL_VECTOR, vVelocity);
	
	return iSpell;
}

public Action Waiting(Handle timer, any client) 
{
	g_wait[client] = false; 
}

void BuildParticle(int client, const char path[32])
{
	int MParticle = CreateEntityByName("info_particle_system");
	if (IsValidEdict(MParticle))
	{
		float pos[3];
		GetEntPropVector(client, Prop_Send, "m_vecOrigin", pos);
		
		TeleportEntity(MParticle, pos, NULL_VECTOR, NULL_VECTOR);
		
		DispatchKeyValue(MParticle, "effect_name", path);
		
		DispatchKeyValue(MParticle, "targetname", "particle");
		
		SetVariantString("!activator");
		AcceptEntityInput(MParticle, "SetParent", client, MParticle, 0);
		
		SetVariantString("effect_robe");
		AcceptEntityInput(MParticle, "SetParentAttachment", MParticle, MParticle, 0);

		DispatchSpawn(MParticle);
		ActivateEntity(MParticle);
		AcceptEntityInput(MParticle, "Start");
		
		ParticleIndex = MParticle;
	}
}

void RemoveParticle()
{
	if (IsValidEntity(ParticleIndex))
	{
		AcceptEntityInput(ParticleIndex, "Kill");
	}	
}