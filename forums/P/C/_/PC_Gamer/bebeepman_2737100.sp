#pragma semicolon 1
#include <sourcemod>
#include <tf2_stocks>
#include <tf2attributes>

#pragma newdecls required

#define PLUGIN_VERSION "1.0"

#define SPAWN	"vo/engineer_specialcompleted01.mp3"
#define DEATH	"vo/engineer_paincrticialdeath06.mp3"
#define SONG	"/ui/gamestartup10.mp3"

public Plugin myinfo =
{
	name = "[TF2] Be the Super Beepman",
	author = "PC Gamer, using code from Pelipoika, FlaminSarge, Jaster, luki1412, manicogaming, and StrikeR14",
	description = "Play as the Super Beepman",
	version = PLUGIN_VERSION,
	url = "www.sourcemod.com"
}

Handle g_hEquipWearable;
Handle g_hCvarThirdPerson;
bool g_bIsBeepman[MAXPLAYERS + 1];

public void OnPluginStart()
{
	LoadTranslations("common.phrases");
	g_hCvarThirdPerson = CreateConVar("bebeepman_thirdperson", "0", "Whether or not deflector ought to be in third-person", 0, true, 0.0, true, 1.0);

	RegAdminCmd("sm_bebeepman", Command_Beepman, ADMFLAG_SLAY, "It's a good time to run");

	HookEvent("post_inventory_application", EventInventoryApplication, EventHookMode_Post);
	HookEvent("player_death", Event_Death, EventHookMode_Post);
	
	GameData hTF2 = new GameData("sm-tf2.games"); // sourcemod's tf2 gamdata

	if (!hTF2)
	SetFailState("This plugin is designed for a TF2 dedicated server only.");

	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetVirtual(hTF2.GetOffset("RemoveWearable") - 1);    // EquipWearable offset is always behind RemoveWearable, subtract its value by 1
	PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
	g_hEquipWearable = EndPrepSDKCall();

	if (!g_hEquipWearable)
	SetFailState("Failed to create call: CBasePlayer::EquipWearable");

	delete hTF2; 
}

public void OnClientPutInServer(int client)
{
	OnClientDisconnect_Post(client);
}

public void OnClientDisconnect_Post(int client)
{
	if(g_bIsBeepman[client])
	{
		g_bIsBeepman[client] = false;
	}
}

public void OnMapStart()
{
	PrecacheSound(SPAWN);
	PrecacheSound(DEATH);
	PrecacheSound(SONG);	
}

public void EventInventoryApplication(Handle event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(g_bIsBeepman[client])
	{
		StopSound(client, SNDCHAN_AUTO, SONG);
		StopSound(client, SNDCHAN_AUTO, SONG);	

		RemoveModel(client);

		int weapon = GetPlayerWeaponSlot(client, 0); 
		if(IsValidEntity(weapon))
		{
			TF2Attrib_RemoveAll(weapon);
		}
		
		int weapon2 = GetPlayerWeaponSlot(client, 1); 
		if(IsValidEntity(weapon2))
		{
			TF2Attrib_RemoveAll(weapon2);
		}

		int Weapon3 = GetPlayerWeaponSlot(client, 2); 
		if(IsValidEntity(Weapon3))
		{
			TF2Attrib_RemoveAll(Weapon3);
		}

		int Weapon4 = GetPlayerWeaponSlot(client, TFWeaponSlot_PDA);
		if(IsValidEntity(Weapon4))
		{
			TF2Attrib_RemoveAll(Weapon4);
		}		
		
		SetVariantInt(0);
		AcceptEntityInput(client, "SetForcedTauntCam");
		TF2Attrib_RemoveAll(client);
		
		g_bIsBeepman[client] = false;
		SetWearableAlpha(client, 255);
		
		SetEntProp(client, Prop_Send, "m_iHealth", 125, 1);		
	}
}

public void Event_Death(Handle event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	int deathflags = GetEventInt(event, "death_flags");
	if (!(deathflags & TF_DEATHFLAG_DEADRINGER))
	{
		if (IsValidClient(client) && g_bIsBeepman[client])
		{
			StopSound(client, SNDCHAN_AUTO, SONG);
			StopSound(client, SNDCHAN_AUTO, SONG);			

			EmitSoundToClient(client, DEATH);
			EmitSoundToClient(client, DEATH);

			TF2Attrib_RemoveAll(client);

			int weapon = GetPlayerWeaponSlot(client, 0); 
			if(IsValidEntity(weapon))
			{
				TF2Attrib_RemoveAll(weapon);
			}
			
			int weapon2 = GetPlayerWeaponSlot(client, 1); 
			if(IsValidEntity(weapon2))
			{
				TF2Attrib_RemoveAll(weapon2);
			}

			int Weapon3 = GetPlayerWeaponSlot(client, 2); 
			if(IsValidEntity(Weapon3))
			{
				TF2Attrib_RemoveAll(Weapon3);
			}
			
			int Weapon4 = GetPlayerWeaponSlot(client, TFWeaponSlot_PDA);
			if(IsValidEntity(Weapon4))
			{
				TF2Attrib_RemoveAll(Weapon4);
			}			

			g_bIsBeepman[client] = false;
			SetWearableAlpha(client, 255);
			
			RemoveModel(client);			
		}
	}
}

public Action RemoveModel(int client)
{
	if (IsValidClient(client))
	{
		SetEntPropFloat(client, Prop_Send, "m_flModelScale", 1.0);
		UpdatePlayerHitbox(client, 1.0);

		SetVariantString("");
		AcceptEntityInput(client, "SetCustomModel");
		SetWearableAlpha(client, 255);
		
		SetEntProp(client, Prop_Send, "m_bGlowEnabled", 0, 1);			
	}
}

public Action Command_Beepman(int client, int args)
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
		MakeBeepman(target_list[i]);
		LogAction(client, target_list[i], "\"%L\" made \"%L\" the Super Beepman!", client, target_list[i]);
	}
	return Plugin_Handled;
}

Action MakeBeepman(int client)
{
	PrintToChat(client, "You are the Super Beepman");
	PrintToChat(client, "If you get stuck because of your size type in chat: !stuck");
	PrintToChat(client, "To change to First Person view type in chat:  !fp");	
	PrintToChat(client, "To change to Third Person view type in chat:  !tp");
	
	//begin hud message
	Handle hHudText = CreateHudSynchronizer();
	SetHudTextParams(-1.0, 0.2, 5.0, 255, 0, 0, 255);
	ShowSyncHudText(client, hHudText, "Greetings Super Beepman...  Read your Chat for instructions.");
	CloseHandle(hHudText);
	// end hud message	

	TF2_SetPlayerClass(client, TFClass_Engineer);
	TF2_RegeneratePlayer(client);

	EmitSoundToClient(client, SPAWN);
	
	TF2_RemoveAllWearables(client);		

	int ragdoll = GetEntPropEnt(client, Prop_Send, "m_hRagdoll");
	if (ragdoll > MaxClients && IsValidEntity(ragdoll)) AcceptEntityInput(ragdoll, "Kill");
	char weaponname[32];
	GetClientWeapon(client, weaponname, sizeof(weaponname));
	if (strcmp(weaponname, "tf_weapon_", false) == 0)
	{
		SetEntProp(GetPlayerWeaponSlot(client, 0), Prop_Send, "m_iWeaponState", 0);
		TF2_RemoveCondition(client, TFCond_Slowed);
	}

	if (IsValidClient(client) && TF2_GetPlayerClass(client) == TFClass_Engineer)
	{
		CreateWeapon(client, "tf_weapon_shotgun_primary", 199, 6, 99, 0, 232);
		CreateWeapon(client, "tf_weapon_pistol", 209, 6, 99, 1, 232);	
		CreateWeapon(client, "tf_weapon_wrench", 169, 6, 99, 2, 0);		
	}

	CreateHat(client, 30509, 10, 6); //Beep Man
	CreateHat(client, 30337, 10, 6); //Trenchers Tunic	
	CreateHat(client, 30167, 10, 6); //Beep Boy	
	CreateHat(client, 31013, 10, 6); //Mini Engy

	CreateTimer(0.1, Timer_Switch, client);

	CreateTimer(3.0, TimerSong, client);
	
	if (GetConVarBool(g_hCvarThirdPerson))
	{
		SetVariantInt(1);
		AcceptEntityInput(client, "SetForcedTauntCam");
	}

	TF2_SetHealth(client, 1500);

	SetEntPropFloat(client, Prop_Send, "m_flModelScale", 1.2);
	UpdatePlayerHitbox(client, 1.2);

	g_bIsBeepman[client] = true;

	TF2_SwitchtoSlot(client, 0);	

	TF2_AddCondition(client, TFCond_SpeedBuffAlly, 0.1);	
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

stock Action TF2_SetHealth(int client, int NewHealth)
{
	SetEntProp(client, Prop_Send, "m_iHealth", NewHealth, 1);
	SetEntProp(client, Prop_Data, "m_iHealth", NewHealth, 1);
}

Action Timer_Switch(Handle timer, any client)
{
	if (IsValidClient(client))

	GiveDeflector(client);
}

Action GiveDeflector(int client)
{
	TF2Attrib_RemoveAll(client);

	TF2Attrib_SetByName(client, "max health additive bonus", 1375.0);
	TF2Attrib_SetByName(client, "major move speed bonus", 1.2);
	TF2Attrib_SetByName(client, "major increased jump height", 1.2);
	TF2Attrib_SetByName(client, "cancel falling damage", 1.0);		
	TF2Attrib_SetByName(client, "cannot be backstabbed", 1.0);
	TF2Attrib_SetByName(client, "airblast vulnerability multiplier", 0.5);
	TF2Attrib_SetByName(client, "airblast vertical vulnerability multiplier", 0.5);
	TF2Attrib_SetByName(client, "health from packs decreased", 0.001);		
	TF2Attrib_SetByName(client, "cancel falling damage", 1.0);			
	TF2Attrib_SetByName(client, "dmg taken from blast reduced", 0.5);
	TF2Attrib_SetByName(client, "dmg taken from fire reduced", 0.5);
	TF2Attrib_SetByName(client, "dmg taken from bullets reduced", 0.5);
	TF2Attrib_SetByName(client, "dmg taken from crit reduced", 0.5);
	TF2Attrib_SetByName(client, "dmg from ranged reduced", 0.5);
	TF2Attrib_SetByName(client, "SET BONUS: dmg from sentry reduced", 0.5);	
	TF2Attrib_SetByName(client, "damage force reduction", 0.5);
	TF2Attrib_SetByName(client, "cannot be backstabbed", 1.0);
	TF2Attrib_SetByName(client, "increased air control", 10.0);	
	TF2Attrib_SetByName(client, "airblast vulnerability multiplier", 0.5);
	TF2Attrib_SetByName(client, "airblast vertical vulnerability multiplier", 0.5);
	TF2Attrib_SetByName(client, "health from packs decreased", 0.001);			

	int Weapon = GetPlayerWeaponSlot(client, 0);
	if(IsValidEntity(Weapon))	
	{
		TF2Attrib_SetByName(Weapon, "fire rate bonus", 0.2);	
		TF2Attrib_SetByName(Weapon, "faster reload rate", 0.2);
		TF2Attrib_SetByName(Weapon, "damage bonus", 5.0);
		TF2Attrib_SetByName(Weapon, "projectile penetration", 1.0);
		TF2Attrib_SetByName(Weapon, "attack projectiles", 1.0);				
		TF2Attrib_SetByName(Weapon, "maxammo primary increased", 5.0);
		TF2Attrib_SetByName(Weapon, "clip size bonus", 5.0);
		TF2Attrib_SetByName(Weapon, "armor piercing", 40.0);
		TF2Attrib_SetByName(Weapon, "ammo regen", 1.0);
		TF2Attrib_SetByName(Weapon, "killstreak tier", 3.0);
		TF2Attrib_SetByName(Weapon, "killstreak effect", 2005.0);
		TF2Attrib_SetByName(Weapon, "killstreak idleeffect", 7.0);
	}

	int Weapon2 = GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary);
	if(IsValidEntity(Weapon2))
	{
		TF2Attrib_SetByName(Weapon2, "fire rate bonus", 0.2);	
		TF2Attrib_SetByName(Weapon2, "faster reload rate", 0.2);
		TF2Attrib_SetByName(Weapon2, "damage bonus", 5.0);
		TF2Attrib_SetByName(Weapon2, "projectile penetration", 1.0);
		TF2Attrib_SetByName(Weapon2, "attack projectiles", 1.0);				
		TF2Attrib_SetByName(Weapon2, "maxammo secondary increased", 5.0);
		TF2Attrib_SetByName(Weapon2, "clip size bonus", 5.0);
		TF2Attrib_SetByName(Weapon2, "SPELL: set Halloween footstep type", 13595446.0);			
	}
	
	int Weapon3 = GetPlayerWeaponSlot(client, TFWeaponSlot_Melee);
	if(IsValidEntity(Weapon3))
	{
		TF2Attrib_SetByName(Weapon3, "melee attack rate bonus", 0.5);	
		TF2Attrib_SetByName(Weapon3, "melee range multiplier", 2.0);
		TF2Attrib_SetByName(Weapon3, "melee bounds multiplier", 2.0);
		TF2Attrib_SetByName(Weapon3, "damage bonus", 5.0);
		TF2Attrib_SetByName(Weapon3, "armor piercing", 20.0);
		TF2Attrib_SetByName(Weapon3, "turn to gold", 1.0);
		TF2Attrib_SetByName(Weapon3, "speed buff ally", 1.0);
		TF2Attrib_SetByName(Weapon3, "dmg pierces resists absorbs", 1.0);
	}
	
	int Weapon4 = GetPlayerWeaponSlot(client, TFWeaponSlot_PDA);
	if(IsValidEntity(Weapon4))
	{
		TF2Attrib_SetByName(Weapon4, "building instant upgrade", 1.0);	
		TF2Attrib_SetByName(Weapon4, "engy sentry fire rate increased", 0.5);					
		TF2Attrib_SetByName(Weapon4, "engy sentry radius increased", 2.0);
		TF2Attrib_SetByName(Weapon4, "engy dispenser radius increased", 2.0);
		TF2Attrib_SetByName(Weapon4, "armor piercing", 50.0);
		TF2Attrib_SetByName(Weapon4, "dmg pierces resists absorbs", 1.0);
		TF2Attrib_SetByName(Weapon4, "has pipboy build interface", 1.0);
		TF2Attrib_SetByName(Weapon4, "bidirectional teleport", 1.0);
		TF2Attrib_SetByName(Weapon4, "engy sentry damage bonus", 5.0);	
		TF2Attrib_SetByName(Weapon4, "engy building health bonus", 20.0);
		TF2Attrib_SetByName(Weapon4, "maxammo metal increased", 3.0);
		TF2Attrib_SetByName(Weapon4, "metal regen", 10.0);	
		TF2Attrib_SetByName(Weapon4, "repair rate increased", 5.0);	
		TF2Attrib_SetByName(Weapon4, "construction rate increased", 8.0);
		TF2Attrib_SetByName(Weapon4, "SPELL: Halloween pumpkin explosions", 1.0);
		TF2Attrib_SetByName(Weapon4, "mult teleporter recharge rate", 0.1);	
		TF2Attrib_SetByName(Weapon4, "mult dispenser rate", 9.99);	
		TF2Attrib_SetByName(Weapon4, "mvm sentry ammo", 19.99);	
		TF2Attrib_SetByName(Weapon4, "building instant upgrade", 1.0);
	}
	
	TF2Attrib_RemoveMoveSpeedPenalty(client);		
	TF2_AddCondition(client, TFCond_RadiusHealOnDamage, 5.0);	
}

stock bool IsValidClient(int client)
{
	if (client <= 0) return false;
	if (client > MaxClients) return false;
	return IsClientInGame(client);
}

stock bool IsValidWeapon(int weapon)
{
	if (!IsValidEntity(weapon))
	return false;
	
	decl String:class[64];
	GetEdictClassname(weapon, class, sizeof(class));
	
	if (strncmp(class, "tf_weapon_", 10) == 0 || strncmp(class, "tf_wearable_demoshield", 22) == 0)
	return true;
	
	return false;
}

stock Action TF2_SwitchtoSlot(int client, int slot)
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

stock Action TF2_RemoveAllWearables(int client) 
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

stock Action SetWearableAlpha(int client, int alpha, bool override = false)
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

bool CreateWeapon(int client, char[] classname, int itemindex, int quality, int level, int slot, int paint)
{
	TF2_RemoveWeaponSlot(client, slot);
	
	int weapon = CreateEntityByName(classname);
	
	if (!IsValidEntity(weapon))
	{
		return false;
	}
	
	char entclass[64];
	GetEntityNetClass(weapon, entclass, sizeof(entclass));
	SetEntData(weapon, FindSendPropInfo(entclass, "m_iItemDefinitionIndex"), itemindex);	 
	SetEntData(weapon, FindSendPropInfo(entclass, "m_bInitialized"), 1);
	SetEntData(weapon, FindSendPropInfo(entclass, "m_iEntityQuality"), quality);
	SetEntProp(weapon, Prop_Send, "m_bValidatedAttachedEntity", 1);
	
	if (level)
	{
		SetEntData(weapon, FindSendPropInfo(entclass, "m_iEntityLevel"), level);
	}
	else
	{
		SetEntData(weapon, FindSendPropInfo(entclass, "m_iEntityLevel"), GetRandomInt(1,99));
	}

	TF2Attrib_SetByDefIndex(weapon, 834, view_as<float>(paint));	//Set Warpaint
	
	switch (itemindex)
	{
	case 810, 736, 933, 1080, 1102:
		{
			SetEntData(weapon, FindSendPropInfo(entclass, "m_iObjectType"), 3);
		}
	case 998:
		{
			SetEntData(weapon, FindSendPropInfo(entclass, "m_nChargeResistType"), GetRandomInt(0,2));
		}
	case 1071:
		{
			TF2Attrib_SetByName(weapon, "item style override", 0.0);
			TF2Attrib_SetByName(weapon, "loot rarity", 1.0);		
			TF2Attrib_SetByName(weapon, "turn to gold", 1.0);

			DispatchSpawn(weapon);
			EquipPlayerWeapon(client, weapon);
			
			return true; 
		}		
	}

	if(quality == 9)
	{
		TF2Attrib_SetByName(weapon, "is australium item", 1.0);
		TF2Attrib_SetByName(weapon, "item style override", 1.0);
	}

	if(itemindex == 200 || itemindex == 220 || itemindex == 448 || itemindex == 15002 || itemindex == 15015 || itemindex == 15021 || itemindex == 15029 || itemindex == 15036 || itemindex == 15053 || itemindex == 15065 || itemindex == 15069 || itemindex == 15106 || itemindex == 15107 || itemindex == 15108 || itemindex == 15131 || itemindex == 15151 || itemindex == 15157 || itemindex == 449 || itemindex == 15013 || itemindex == 15018 || itemindex == 15035 || itemindex == 15041 || itemindex == 15046 || itemindex == 15056 || itemindex == 15060 || itemindex == 15061 || itemindex == 15100 || itemindex == 15101
			|| itemindex == 15102 || itemindex == 15126 || itemindex == 15148 || itemindex == 44 || itemindex == 221 || itemindex == 205 || itemindex == 228 || itemindex == 1104 || itemindex == 15006 || itemindex == 15014 || itemindex == 15028 || itemindex == 15043 || itemindex == 15052 || itemindex == 15057 || itemindex == 15081 || itemindex == 15104 || itemindex == 15105 || itemindex == 15129 || itemindex == 15130 || itemindex == 15150 || itemindex == 196 || itemindex == 447 || itemindex == 208 || itemindex == 215 || itemindex == 1178 || itemindex == 15005 || itemindex == 15017 || itemindex == 15030 || itemindex == 15034
			|| itemindex == 15049 || itemindex == 15054 || itemindex == 15066 || itemindex == 15067 || itemindex == 15068 || itemindex == 15089 || itemindex == 15090 || itemindex == 15115 || itemindex == 15141 || itemindex == 351 || itemindex == 740 || itemindex == 192 || itemindex == 214 || itemindex == 326 || itemindex == 206 || itemindex == 308 || itemindex == 996 || itemindex == 1151 || itemindex == 15077 || itemindex == 15079 || itemindex == 15091 || itemindex == 15092 || itemindex == 15116 || itemindex == 15117 || itemindex == 15142 || itemindex == 15158 || itemindex == 207 || itemindex == 130 || itemindex == 15009
			|| itemindex == 15012 || itemindex == 15024 || itemindex == 15038 || itemindex == 15045 || itemindex == 15048 || itemindex == 15082 || itemindex == 15083 || itemindex == 15084 || itemindex == 15113 || itemindex == 15137 || itemindex == 15138 || itemindex == 15155 || itemindex == 172 || itemindex == 327 || itemindex == 404 || itemindex == 202 || itemindex == 41 || itemindex == 312 || itemindex == 424 || itemindex == 15004 || itemindex == 15020 || itemindex == 15026 || itemindex == 15031 || itemindex == 15040 || itemindex == 15055 || itemindex == 15086 || itemindex == 15087 || itemindex == 15088 || itemindex == 15098
			|| itemindex == 15099 || itemindex == 15123 || itemindex == 15124 || itemindex == 15125 || itemindex == 15147 || itemindex == 425 || itemindex == 997 || itemindex == 197 || itemindex == 329 || itemindex == 15073 || itemindex == 15074 || itemindex == 15075 || itemindex == 15139 || itemindex == 15140 || itemindex == 15114 || itemindex == 15156 || itemindex == 305 || itemindex == 211 || itemindex == 15008 || itemindex == 15010 || itemindex == 15025 || itemindex == 15039 || itemindex == 15050 || itemindex == 15078 || itemindex == 15097 || itemindex == 15121 || itemindex == 15122 || itemindex == 15123 || itemindex == 15145
			|| itemindex == 15146 || itemindex == 35 || itemindex == 411 || itemindex == 37 || itemindex == 304 || itemindex == 201 || itemindex == 402 || itemindex == 15000 || itemindex == 15007 || itemindex == 15019 || itemindex == 15023 || itemindex == 15033 || itemindex == 15059 || itemindex == 15070 || itemindex == 15071 || itemindex == 15072 || itemindex == 15111 || itemindex == 15112 || itemindex == 15135 || itemindex == 15136 || itemindex == 15154 || itemindex == 203 || itemindex == 15001 || itemindex == 15022 || itemindex == 15032 || itemindex == 15037 || itemindex == 15058 || itemindex == 15076 || itemindex == 15110
			|| itemindex == 15134 || itemindex == 15153 || itemindex == 193 || itemindex == 401 || itemindex == 210 || itemindex == 15011 || itemindex == 15027 || itemindex == 15042 || itemindex == 15051 || itemindex == 15062 || itemindex == 15063 || itemindex == 15064 || itemindex == 15103 || itemindex == 15128 || itemindex == 15129 || itemindex == 15149 || itemindex == 194 || itemindex == 649 || itemindex == 15062 || itemindex == 15094 || itemindex == 15095 || itemindex == 15096 || itemindex == 15118 || itemindex == 15119 || itemindex == 15143 || itemindex == 15144 || itemindex == 209 || itemindex == 15013 || itemindex == 15018
			|| itemindex == 15035 || itemindex == 15041 || itemindex == 15046 || itemindex == 15056 || itemindex == 15060 || itemindex == 15061 || itemindex == 15100 || itemindex == 15101 || itemindex == 15102 || itemindex == 15126 || itemindex == 15148 || itemindex == 415 || itemindex == 15003 || itemindex == 15016 || itemindex == 15044 || itemindex == 15047 || itemindex == 15085 || itemindex == 15109 || itemindex == 15132 || itemindex == 15133 || itemindex == 15152 || itemindex == 1153)
	{
		if(GetRandomInt(1,15) == 1)
		{
			TF2Attrib_SetByDefIndex(weapon, 2053, 1.0);
		}
	}
	
	if(quality == 11)
	{
		if (GetRandomInt(1,10) == 1)
		{
			TF2Attrib_SetByDefIndex(weapon, 2025, 1.0);
		}
		else if (GetRandomInt(1,10) == 2)
		{
			TF2Attrib_SetByDefIndex(weapon, 2025, 2.0);
			TF2Attrib_SetByDefIndex(weapon, 2014, GetRandomInt(1,7) + 0.0);
		}
		else if (GetRandomInt(1,10) == 3)
		{
			TF2Attrib_SetByDefIndex(weapon, 2025, 3.0);
			TF2Attrib_SetByDefIndex(weapon, 2014, GetRandomInt(1,7) + 0.0);
			TF2Attrib_SetByDefIndex(weapon, 2013, GetRandomInt(2002,2008) + 0.0);
		}
		TF2Attrib_SetByDefIndex(weapon, 214, view_as<float>(GetRandomInt(0, 9000)));
	}
	
	if (quality == 15)
	{
		switch(itemindex)
		{
		case 30666, 30667, 30668, 30665:
			{
				TF2Attrib_RemoveByDefIndex(weapon, 725);
			}
		default:
			{
				TF2Attrib_SetByDefIndex(weapon, 725, GetRandomFloat(0.0,1.0));
			}
		}
	}

	if (itemindex == 405 || itemindex == 608 || itemindex == 1101 || itemindex == 133 || itemindex == 444 || itemindex == 57 || itemindex == 231 || itemindex == 642 || itemindex == 131 || itemindex == 406 || itemindex == 1099 || itemindex == 1144)
	{
		DispatchSpawn(weapon);
		SDKCall(g_hEquipWearable, client, weapon);
		CreateTimer(0.1, TimerHealth, client, TIMER_FLAG_NO_MAPCHANGE);
	}

	else
	{
		DispatchSpawn(weapon);
		EquipPlayerWeapon(client, weapon);
	}
	
	if (quality !=9)
	{
		if (itemindex == 13
				|| itemindex == 200
				|| itemindex == 23
				|| itemindex == 209
				|| itemindex == 18
				|| itemindex == 205
				|| itemindex == 10
				|| itemindex == 199
				|| itemindex == 21
				|| itemindex == 208
				|| itemindex == 12
				|| itemindex == 19
				|| itemindex == 206
				|| itemindex == 20
				|| itemindex == 207
				|| itemindex == 15
				|| itemindex == 202
				|| itemindex == 11
				|| itemindex == 9
				|| itemindex == 22
				|| itemindex == 29
				|| itemindex == 211
				|| itemindex == 14
				|| itemindex == 201
				|| itemindex == 16
				|| itemindex == 203
				|| itemindex == 24
				|| itemindex == 210)	
		{
			if (GetRandomInt(1,2) < 3)
			{
				TF2_SwitchtoSlot(client, slot);
				int iRand = GetRandomInt(1,4);
				if (iRand == 1)
				{
					TF2Attrib_SetByDefIndex(weapon, 134, 701.0);	
				}
				else if (iRand == 2)
				{
					TF2Attrib_SetByDefIndex(weapon, 134, 702.0);	
				}	
				else if (iRand == 3)
				{
					TF2Attrib_SetByDefIndex(weapon, 134, 703.0);	
				}
				else if (iRand == 4)
				{
					TF2Attrib_SetByDefIndex(weapon, 134, 704.0);	
				}
			}
		}
	}

	return true;
}

public Action TimerHealth(Handle timer, any client)
{
	int hp = GetPlayerMaxHp(client);
	
	if (hp > 0)
	{
		SetEntityHealth(client, hp);
	}
}

int GetPlayerMaxHp(int client)
{
	if (!IsClientConnected(client))
	{
		return -1;
	}

	int entity = GetPlayerResourceEntity();

	if (entity == -1)
	{
		return -1;
	}

	return GetEntProp(entity, Prop_Send, "m_iMaxHealth", _, client);
}

stock void TF2Attrib_RemoveMoveSpeedPenalty(int client)
{
	TF2Attrib_RemoveByName(client, "move speed penalty");
	TF2_AddCondition(client, TFCond_SpeedBuffAlly, 0.0);
}

public Action TimerSong(Handle timer, any client)
{
	EmitSoundToClient(client, SONG);
	EmitSoundToClient(client, SONG);			
}

bool CreateHat(int client, int itemindex, int level, int quality)
{
	int hat = CreateEntityByName("tf_wearable");
	
	if (!IsValidEntity(hat))
	{
		return false;
	}
	
	char entclass[64];
	GetEntityNetClass(hat, entclass, sizeof(entclass));
	SetEntData(hat, FindSendPropInfo(entclass, "m_iItemDefinitionIndex"), itemindex);
	SetEntData(hat, FindSendPropInfo(entclass, "m_bInitialized"), 1); 	
	SetEntData(hat, FindSendPropInfo(entclass, "m_iEntityLevel"), level);
	SetEntData(hat, FindSendPropInfo(entclass, "m_iEntityQuality"), quality);
	SetEntProp(hat, Prop_Send, "m_bValidatedAttachedEntity", 1);	

	if(itemindex == 30509)
	{
		TF2Attrib_SetByDefIndex(hat, 134, GetRandomInt(1,174) + 0.0);
	}	
	
	DispatchSpawn(hat);
	SDKCall(g_hEquipWearable, client, hat);
	return true;
}

stock int GiveWeaponAmmo(int weapon, int amount, bool supressSound = true) {
	int ammoType = GetEntProp(weapon, Prop_Send, "m_iPrimaryAmmoType");
	int client = GetEntPropEnt(weapon, Prop_Send, "m_hOwner");
	
	if (client > 0 && client <= MaxClients) {
		return GivePlayerAmmo(client, amount, ammoType, supressSound);
	}
	return 0;
}