#pragma semicolon 1 

#include <sdktools> 
#include <sdkhooks> 
#include <tf2_stocks> 
#include <tf2attributes> 
#include <tf2items> 

#define PLUGIN_VERSION "1.6" 

#define HHH        "models/bots/merasmus/merasmus.mdl" 
#define BOMBMODEL        "models/props_lakeside_event/bomb_temp.mdl" 
#define SPAWN    "vo/halloween_merasmus/sf12_appears04.mp3" 
#define DEATH    "vo/halloween_merasmus/sf12_defeated01.mp3" 

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

new iLastRand; 
new Handle:g_hCvarThirdPerson; 
new bool:g_bIsHHH[MAXPLAYERS + 1]; 
new bool:IsTaunting[MAXPLAYERS + 1]; 
new bool:ms = false; 
new lastTeam[MAXPLAYERS + 1];
new Handle:g_hSDKTeamAddPlayer;
new Handle:g_hSDKTeamRemovePlayer;
new bool:g_wait[MAXPLAYERS + 1]; 

public Plugin:myinfo =  
{ 
	name = "[TF2] Be the Wizard Merasmus", 
	author = "Starman4xz, Mitch, Pelipoika, FlamingSarge, Tylerst, Benoist3012, modified by PC Gamer",
	description = "Play as the Wizard Merasmus", 
	version = PLUGIN_VERSION, 
	url = "www.sourcemod.com" 
} 

public OnPluginStart() 
{ 
	Handle hGameData = LoadGameConfigFile("changeteam");
	
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

	HookEvent( "player_activate", OnPlayerActivate, EventHookMode_Post ); 
	HookEvent("player_death", Event_Death, EventHookMode_Post);
	HookEvent("player_death", Event_DeathPre, EventHookMode_Pre);
	HookEvent("teamplay_round_start", Event_Endround);
	HookEvent("teamplay_round_win", Event_Endround);
	HookEvent("teamplay_round_stalemate", Event_Endround);
} 	 

public OnMapStart() 
{ 
	PrecacheModel(HHH); 
	PrecacheSound(SPAWN); 
	PrecacheSound(DEATH); 
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
} 

public OnPlayerActivate( Handle:hEvent, const String:strEventName[], bool:bDontBroadcast )
{
	new client = GetClientOfUserId( GetEventInt( hEvent, "userid" ) );
	if( !IsValidClient(client) )
	return;

	g_bIsHHH[client] = false;
	
	SDKHook( client, SDKHook_OnTakeDamage, OnTakeDamage );
}

public void OnClientDisconnect(int client) 
{
	SDKUnhook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

public Event_DeathPre(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "attacker"));
	new String:weapon[20];
	GetEventString(event, "weapon", weapon, sizeof(weapon));
	if(g_bIsHHH[client])
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

public Event_Death(Handle:event, const String:name[], bool:dontBroadcast) 
{ 
	new client = GetClientOfUserId(GetEventInt(event, "userid")); 
	new deathflags = GetEventInt(event, "death_flags"); 
	if (!(deathflags & TF_DEATHFLAG_DEADRINGER)) 
	{ 
		if (IsValidClient(client) && g_bIsHHH[client]) 
		{ 
			ChangeClientTeamEx(client, lastTeam[client]);
			TF2Attrib_RemoveAll(client); 
			new weapon = GetPlayerWeaponSlot(client, 2);  
			TF2Attrib_RemoveAll(weapon);             
			SetWearableAlpha(client, 255);                 
			EmitSoundToAll(DEATH); 
			SetVariantInt(0); 
			AcceptEntityInput(client, "SetForcedTauntCam"); 
			RemoveModel(client);
			g_bIsHHH[client] = false;  			
			ms = false; 			
			CreateTimer(0.1, ResetSpeed, client);			
		} 
	} 
} 

public Event_Endround(Handle:event, const String:name[], bool:dontBroadcast)
{
	for (new i = 1; i <= MaxClients; i++)
	{
		if (g_bIsHHH[i])
		{
			ChangeClientTeamEx(i, lastTeam[i]);
			TF2Attrib_RemoveAll(i); 
			new weapon = GetPlayerWeaponSlot(i, 2);
			if (IsValidWeapon(weapon))	
			{
				TF2Attrib_RemoveAll(weapon);
			}            
			SetWearableAlpha(i, 255);                 
			EmitSoundToAll(DEATH); 
			SetVariantInt(0); 
			AcceptEntityInput(i, "SetForcedTauntCam"); 
			RemoveModel(i);
			g_bIsHHH[i] = false;  
			ms = false; 
			CreateTimer(0.1, ResetSpeed, i);	
		}
	}
}

public Action:SetModel(client, const String:model[]) 
{ 
	if (IsValidClient(client) && IsPlayerAlive(client)) 
	{ 
		RemoveModel(client); 
		
		SetVariantString(model); 
		AcceptEntityInput(client, "SetCustomModel"); 

		SetEntProp(client, Prop_Send, "m_bUseClassAnimations", 1); 
		SetWearableAlpha(client, 0); 
	} 
} 

public Action:RemoveModel(client) 
{ 
	if (IsValidClient(client) && g_bIsHHH[client])
	{ 
		TF2Attrib_RemoveAll(client);
		
		new weapon = GetPlayerWeaponSlot(client, 2);  
		TF2Attrib_RemoveAll(weapon); 
		SetEntPropFloat(client, Prop_Send, "m_flModelScale", 1.0); 
		UpdatePlayerHitbox(client, 2.0); 

		SetSpell2(client, 0, 0); 

		SetVariantString(""); 
		AcceptEntityInput(client, "SetCustomModel"); 
		SetWearableAlpha(client, 255); 
	} 
} 

public Action:Command_wizard(client, args) 
{ 
	decl String:arg1[32]; 
	if (args < 1) 
	{ 
		arg1 = "@me"; 
	} 
	else GetCmdArg(1, arg1, sizeof(arg1)); 
	new String:target_name[MAX_TARGET_LENGTH]; 
	new target_list[MAXPLAYERS], target_count; 
	new bool:tn_is_ml; 

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
	for (new t = 0; t < target_count; t++) 
	{ 
		Makewizard(target_list[t]);     
	} 
	return Plugin_Handled; 
} 

Makewizard(client) 
{ 
	lastTeam[client] = GetClientTeam(client); 
	new Float:origin[3], Float:angles[3]; 
	GetClientAbsOrigin(client, origin); 
	GetClientAbsAngles(client, angles); 
	ChangeClientTeamEx(client, 0); 

	TF2_SetPlayerClass(client, TFClass_Sniper); 
	TF2_RespawnPlayer(client);
	
	TeleportEntity(client, origin, angles, NULL_VECTOR);

	CreateTimer(1.0, Makemelee, client); 	
	
	new ragdoll = GetEntPropEnt(client, Prop_Send, "m_hRagdoll"); 
	if (ragdoll > MaxClients && IsValidEntity(ragdoll)) AcceptEntityInput(ragdoll, "Kill"); 

	SetModel(client, HHH); 

	if (GetConVarBool(g_hCvarThirdPerson)) 
	{ 
		SetVariantInt(1); 
		AcceptEntityInput(client, "SetForcedTauntCam"); 
	} 
	
	SetEntPropFloat(client, Prop_Send, "m_flModelScale", 1.0); 
	UpdatePlayerHitbox(client, 2.0); 
	
	g_bIsHHH[client] = true;
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
	Command_getms1(client); 	

	PrintToChat(client, "You are the might Wizard Merasmus!");
	PrintToChat(client, "Wizard Commands: Use Right-Click to launch players,");
	PrintToChat(client, "You have 500 Fireball Spells.  Use 'H' to cast Fireball spell,");
	PrintToChat(client, "Use 'R' to throw bombs,");
	PrintToChat(client, "Use Mouse3 button (press down on mousewheel) to cast Lightning Spell");
	PrintToChat(client, "You can attack BOTH Teams.");
	
	PrintCenterText(client, "Wizard Commands: Use Right-Click to launch players, Use 'H' to cast Fireball spell, Use 'R' to throw bombs, Use Mouse3 button (press down on mousewheel) to cast Lightning Spell, You can attack BOTH Teams.");	
} 

stock UpdatePlayerHitbox(const client, const Float:fScale) 
{ 
	static const Float:vecTF2PlayerMin[3] = { -24.5, -24.5, 0.0 }, Float:vecTF2PlayerMax[3] = { 24.5,  24.5, 83.0 }; 
	
	decl Float:vecScaledPlayerMin[3], Float:vecScaledPlayerMax[3]; 

	vecScaledPlayerMin = vecTF2PlayerMin; 
	vecScaledPlayerMax = vecTF2PlayerMax; 
	
	ScaleVector(vecScaledPlayerMin, fScale); 
	ScaleVector(vecScaledPlayerMax, fScale); 
	
	SetEntPropVector(client, Prop_Send, "m_vecSpecifiedSurroundingMins", vecScaledPlayerMin); 
	SetEntPropVector(client, Prop_Send, "m_vecSpecifiedSurroundingMaxs", vecScaledPlayerMax); 
} 

stock TF2_SetHealth(client, NewHealth) 
{ 
	SetEntProp(client, Prop_Send, "m_iHealth", NewHealth, 1); 
	SetEntProp(client, Prop_Data, "m_iHealth", NewHealth, 1); 
} 

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon) 
{ 
	if (GetEntityFlags(client) & FL_ONGROUND && g_bIsHHH[client] == true) 
	{ 
		if(buttons & IN_ATTACK3 && IsTaunting[client] != true && g_bIsHHH[client] == true && g_wait[client] == false)         
		{ 
			ShootProjectile(client, LIGHTNING);
			g_wait[client] = true;
			CreateTimer(3.0, Waiting, client);
		}
		else if (buttons & IN_ATTACK2 && g_bIsHHH[client] == true && IsTaunting[client] != true && g_bIsHHH[client] == true) 
		{  
			MakePlayerInvisible(client, 0); 
			
			new Model = CreateEntityByName("prop_dynamic"); 
			if (IsValidEdict(Model)) 
			{ 
				IsTaunting[client] = true; 
				new Float:pos[3], Float:ang[3]; 
				decl String:ClientModel[256]; 
				
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
		else if(buttons & IN_RELOAD && IsTaunting[client] != true && g_bIsHHH[client] == true)         
		{ 
			MakePlayerInvisible(client, 0); 

			SetVariantInt(1); 
			AcceptEntityInput(client, "SetForcedTauntCam"); 
			
			new Model = CreateEntityByName("prop_dynamic"); 
			if (IsValidEdict(Model)) 
			{ 
				IsTaunting[client] = true; 
				new Float:posc[3], Float:ang[3]; 
				decl String:ClientModel[256]; 
				
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
		if(buttons & IN_ATTACK && IsTaunting[client] == true && g_bIsHHH[client] == true)         
		{ 
			return Plugin_Handled;
		}
	} 
	return Plugin_Continue; 
} 

public Action:ResetTaunt(Handle:timer, any:client) 
{ 
	if (g_bIsHHH[client])
	{
		IsTaunting[client] = false; 
		MakePlayerInvisible(client, 255); 
		SetEntityMoveType(client, MOVETYPE_ISOMETRIC);
	}
} 

stock MakePlayerInvisible(client, alpha) 
{ 
	SetWeaponsAlpha(client, alpha); 
	SetWearableAlpha(client, alpha); 
	SetEntityRenderMode(client, RENDER_TRANSCOLOR); 
	SetEntityRenderColor(client, 255, 255, 255, alpha); 
} 

stock SetWeaponsAlpha (client, alpha) 
{ 
	decl String:classname[64]; 
	new m_hMyWeapons = FindSendPropInfo("CBasePlayer", "m_hMyWeapons"); 
	for(new m = 0, weapon; m < 189; m += 4) 
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

public Action:DoHellfire(Handle:timer, any:client) 
{ 
	new Float:vec[3]; 
	GetClientEyePosition(client, vec); 
	
	
	for(new k=1; k<=MaxClients; k++) 
	{ 
		if(!IsClientInGame(k) || !IsPlayerAlive(k)) continue; 
		
		new Float:pos[3]; 
		GetClientEyePosition(k, pos); 
		
		new Float:distance = GetVectorDistance(vec, pos); 
		
		new Float:dist = 310.0; 
		
		
		if(distance < dist) 
		{ 
			if (k == client) continue; 
			
			new Float:vecc[3]; 
			
			vecc[0] = 0.0; 
			vecc[1] = 0.0; 
			vecc[2] = 1500.0; 
			
			new iInflictor = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
			SDKHooks_TakeDamage(k, iInflictor, client, 30.0);
			TeleportEntity(k, NULL_VECTOR, NULL_VECTOR, vecc); 
			TF2_IgnitePlayer(k, client); 
		} 
	} 
} 

public PlayHellfire() 
{ 
	new soundswitch; 
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

stock bool:IsValidClient(client) 
{ 
	if (client <= 0) return false; 
	if (client > MaxClients) return false; 
	return IsClientInGame(client); 
} 

stock TF2_RemoveAllWearables(client) 
{ 
	new wearable = -1; 
	while ((wearable = FindEntityByClassname(wearable, "tf_wearable*")) != -1) 
	{ 
		if (IsValidEntity(wearable)) 
		{ 
			new player = GetEntPropEnt(wearable, Prop_Send, "m_hOwnerEntity"); 
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
			new player = GetEntPropEnt(wearable, Prop_Send, "m_hOwnerEntity"); 
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
			new player = GetEntPropEnt(wearable, Prop_Send, "m_hOwnerEntity"); 
			if (client == player) 
			{ 
				TF2_RemoveWearable(client, wearable); 
			} 
		} 
	} 
} 

stock SetWearableAlpha(client, alpha) 
{ 
	new count; 
	for (new z = MaxClients + 1; z <= 2048; z++) 
	{ 
		if (!IsValidEntity(z)) continue; 
		decl String:cls[35]; 
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
	return count; 
} 

public Action:Command_getms1(client) 
{  
	new soundswitch; 
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

public Action:Command_getms2(Handle timer) 
{  
	if (ms == false) 
	{ 
		return Plugin_Handled; 
	} 
	new soundswitch2; 
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

public Action:Command_getmsnow(client, args) 
{ 
	CreateTimer(0.1, Command_GetmsRandom); 
} 

public Action:Command_GetmsRandom(Handle timer) 
{ 
	new iRand = GetRandomInt(1,11); 
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

	CreateTimer(10.0, Command_getms2); 
	
	return Plugin_Handled; 
} 

stock forceSpellbook(client) 
{ 
	new Handle:hWeapon = TF2Items_CreateItem(OVERRIDE_ALL|FORCE_GENERATION); 
	TF2Items_SetClassname(hWeapon, "tf_weapon_spellbook"); 
	TF2Items_SetItemIndex(hWeapon, 1070); 
	TF2Items_SetLevel(hWeapon, 100); 
	TF2Items_SetQuality(hWeapon, 6); 
	TF2Items_SetNumAttributes(hWeapon, 1); 
	TF2Items_SetAttribute(hWeapon, 0, 547, 0.5); 

	new entity = TF2Items_GiveNamedItem(client, hWeapon); 
	CloseHandle(hWeapon); 
	EquipPlayerWeapon(client, entity); 
	return entity; 
} 

SetSpell2(client, spell, uses) 
{ 
	new ent = GetSpellBook(client); 
	if(!IsValidEntity(ent)) return; 
	SetEntProp(ent, Prop_Send, "m_iSelectedSpellIndex", spell); 
	SetEntProp(ent, Prop_Send, "m_iSpellCharges", uses); 
}   

GetSpellBook(client) 
{ 
	new entity = -1; 
	while((entity = FindEntityByClassname(entity, "tf_weapon_spellbook")) != INVALID_ENT_REFERENCE) 
	{ 
		if(GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity") == client) return entity; 
	} 
	return -1; 
} 

public Playbombsound() 
{ 
	new soundswitch; 
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

public Action:StartBombAttack(Handle:timer, any:client) 
{ 
	new Handle:BTime = CreateTimer(2.0, CreateBomb, client, TIMER_REPEAT); 
	CreateTimer(11.75, ResetTaunt, client); 
	CreateTimer(11.0, KillBombs, BTime); 
	TimedParticle(client, "merasmus_book_attack", 11.0); 
} 
public Action:CreateBomb(Handle:timer, any:client) 
{ 
	if(g_bIsHHH[client] == true) 
	{ 
		SpawnClusters(client); 
	} 
} 
public Action:KillBombs(Handle:timer, any:Btimer) 
{ 
	KillTimer(Btimer); 
} 

public SpawnClusters(ent) 
{ 
	if (IsValidEntity(ent)) 
	{ 
		new Float:bombSpreadVel = 50.0; 
		new Float:bombVertVel = 90.0; 
		new bombVariation = 2; 
		
		new Float:pos[3]; 
		GetClientEyePosition(ent, pos); 
		pos[2] += 105.0; 
		
		decl Float:ang[3]; 
		
		for (new j = 0; j < 11; j++) 
		{ 
			ang[0] = ((GetURandomFloat() + 0.1) * bombSpreadVel - bombSpreadVel / 2.0) * ((GetURandomFloat() + 0.1) * bombVariation); 
			ang[1] = ((GetURandomFloat() + 0.1) * bombSpreadVel - bombSpreadVel / 2.0) * ((GetURandomFloat() + 0.1) * bombVariation); 
			ang[2] = ((GetURandomFloat() + 0.1) * bombVertVel) * ((GetURandomFloat() + 0.1) * bombVariation); 

			new ent2 = CreateEntityByName("prop_physics_override"); 

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
public Action:ExplodeBomblet(Handle:timer, any:ent) 
{ 
	if (IsValidEntity(ent)) 
	{ 
		decl Float:pos[3]; 
		GetEntPropVector(ent, Prop_Data, "m_vecOrigin", pos); 
		pos[2] += 32.0; 

		new client = GetEntPropEnt(ent, Prop_Data, "m_hOwnerEntity"); 
		if (!IsValidClient(client))
		{
			return;
		}
		new team = GetEntProp(client, Prop_Send, "m_iTeamNum"); 

		AcceptEntityInput(ent, "Kill"); 
		new BombMagnitude = 120; 
		new explosion = CreateEntityByName("env_explosion"); 
		if (explosion != -1) 
		{ 
			decl String:tMag[8]; 
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
public TimedParticle(client, const String:path[32], Float:FTime) 
{ 
	new TParticle = CreateEntityByName("info_particle_system"); 
	if (IsValidEdict(TParticle)) 
	{ 
		new Float:pos[3]; 
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
public Action:KillTParticle(Handle:timer, any:index) 
{ 
	if (IsValidEntity(index)) 
	{ 
		AcceptEntityInput(index, "Kill"); 
	} 
}  

public Action:ResetSpeed(Handle:timer, any:client)
{
	TF2_StunPlayer(client, 0.0, 0.0, TF_STUNFLAG_SLOWDOWN);
}

public Action:OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype, &weapon, Float:damageForce[3], Float:damagePosition[3], damagecustom)
{
	if( !IsValidClient(victim) || !IsValidClient(attacker) || !g_bIsHHH[attacker] || g_bIsHHH[attacker] == g_bIsHHH[victim] )
	return Plugin_Continue;

	if( g_bIsHHH[attacker] )
	damage = damage * 5;
	return Plugin_Changed;
} 


stock TF2_SwitchtoSlot(client, slot)
{
	if (slot >= 0 && slot <= 5 && IsClientInGame(client) && IsPlayerAlive(client))
	{
		new String:wepclassname[64];
		new wep = GetPlayerWeaponSlot(client, slot);
		if (wep > MaxClients && IsValidEdict(wep) && GetEdictClassname(wep, wepclassname, sizeof(wepclassname)))
		{
			FakeClientCommandEx(client, "use %s", wepclassname);
			SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", wep);
		}
	}
}

public Action:Makemelee(Handle:timer, any:client) 
{ 
	SetModel(client, HHH);

	TF2_RemoveAllWearables(client);	
	TF2_RemoveWeaponSlot(client, 5);
	TF2_RemoveWeaponSlot(client, 4);
	TF2_RemoveWeaponSlot(client, 3);
	TF2_RemoveWeaponSlot(client, 1);
	TF2_RemoveWeaponSlot(client, 0);

	new Handle:hWeapon = TF2Items_CreateItem(OVERRIDE_ALL|FORCE_GENERATION);
	if (hWeapon != INVALID_HANDLE)
	{
		TF2Items_SetClassname(hWeapon, "tf_weapon_club");
		TF2Items_SetItemIndex(hWeapon, 3);
		TF2Items_SetLevel(hWeapon, 100);
		TF2Items_SetQuality(hWeapon, 5);
		
		new weapon = TF2Items_GiveNamedItem(client, hWeapon);
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


	new Weapon3 = GetPlayerWeaponSlot(client, 2);
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

stock bool:IsValidWeapon(weapon)
{
	if (!IsValidEntity(weapon))
	return false;
	
	decl String:class[64];
	GetEdictClassname(weapon, class, sizeof(class));
	
	if (strncmp(class, "tf_weapon_", 10) == 0 || strncmp(class, "tf_wearable_demoshield", 22) == 0)
	return true;
	
	return false;
}

void ChangeClientTeamEx(iClient, int iNewTeamNum)
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

ShootProjectile(client, spell)
{
	new Float:vAngles[3]; 
	new Float:vPosition[3]; 
	GetClientEyeAngles(client, vAngles);
	GetClientEyePosition(client, vPosition);
	new String:strEntname[45] = "";
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
	new iTeam = GetClientTeam(client);
	new iSpell = CreateEntityByName(strEntname);
	
	if(!IsValidEntity(iSpell))
	return -1;
	
	decl Float:vVelocity[3];
	decl Float:vBuffer[3];
	
	GetAngleVectors(vAngles, vBuffer, NULL_VECTOR, NULL_VECTOR);
	
	vVelocity[0] = vBuffer[0]*1100.0; 
	vVelocity[1] = vBuffer[1]*1100.0;
	vVelocity[2] = vBuffer[2]*1100.0;
	
	SetEntPropEnt(iSpell, Prop_Send, "m_hOwnerEntity", client);
	SetEntProp(iSpell,    Prop_Send, "m_bCritical", (GetRandomInt(0, 100) <= 5)? 1 : 0, 1);
	SetEntProp(iSpell,    Prop_Send, "m_iTeamNum",     iTeam, 1);
	SetEntProp(iSpell,    Prop_Send, "m_nSkin", (iTeam-2));
	
	TeleportEntity(iSpell, vPosition, vAngles, NULL_VECTOR);
	/*switch(spell)
	{
		case FIREBALL, LIGHTNING:
		{
			TeleportEntity(iSpell, vPosition, vAngles, vVelocity);
		}
		case BATS, METEOR, TELE:
		{
			//TeleportEntity(iSpell, vPosition, vAngles, vVelocity);
			//SetEntPropVector(iSpell, Prop_Send, "m_vecForce", vVelocity);
			
		}
	}*/
	
	SetVariantInt(iTeam);
	AcceptEntityInput(iSpell, "TeamNum", -1, -1, 0);
	SetVariantInt(iTeam);
	AcceptEntityInput(iSpell, "SetTeam", -1, -1, 0); 
	
	DispatchSpawn(iSpell);
	/*
	switch(spell)
	{
		//These spells have arcs.
		case BATS, METEOR, TELE:
		{
			vVelocity[2] += 32.0;
		}
	}*/
	TeleportEntity(iSpell, NULL_VECTOR, NULL_VECTOR, vVelocity);
	
	return iSpell;
}

public Action:Waiting(Handle:timer, any:client) 
{
	g_wait[client] = false; 
}