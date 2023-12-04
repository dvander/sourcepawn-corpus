#pragma semicolon 1
#pragma semicolon 1
#include <sourcemod>
#include <tf2_stocks>
#include <tf2attributes>

#pragma newdecls required

#define PLUGIN_VERSION "1.1"

#define SPAWN	"/items/powerup_pickup_supernova.wav"
#define DEATH	"/misc/taps_02.wav"
#define SCOUT1	"/vo/scout_invincible01.mp3"
#define SCOUT2	"/vo/scout_invincible02.mp3"
#define SCOUT3	"/vo/scout_invincible03.mp3"
#define SCOUT4	"/vo/scout_invincible04.mp3"
#define SCOUT5	"/vo/scout_laughhappy03.mp3"
#define SCOUT6	"/vo/scout_cheers03.mp3"

public Plugin myinfo =
{
	name = "[TF2] Be the Robin, the Batman sidekick",
	author = "PC Gamer",
	description = "Play as the Robin",
	version = PLUGIN_VERSION,
	url = "www.sourcemod.com"
}

bool g_bIsRobin[MAXPLAYERS + 1];
bool g_Wait1[MAXPLAYERS + 1];

Handle g_hEquipWearable;

public void OnPluginStart()
{
	LoadTranslations("common.phrases");

	RegAdminCmd("sm_robin", Command_Robin, ADMFLAG_SLAY, "Become Robin");
	RegAdminCmd("sm_berobin", Command_Robin, ADMFLAG_SLAY, "Become Robin");	

	HookEvent("post_inventory_application", EventInventoryApplication, EventHookMode_Post);
	HookEvent("player_death", Event_Death, EventHookMode_Post);
	
	GameData hTF2 = new GameData("sm-tf2.games"); // sourcemod's tf2 gamedata

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
	if (g_bIsRobin[client])
	{
		StopSound(client, SNDCHAN_AUTO, SPAWN);
		StopSound(client, SNDCHAN_AUTO, SPAWN);		
		g_bIsRobin[client] = false;
	}
}

public void OnMapStart()
{
	PrecacheSound(SPAWN);
	PrecacheSound(DEATH);
	PrecacheSound(SCOUT1);
	PrecacheSound(SCOUT2);
	PrecacheSound(SCOUT3);
	PrecacheSound(SCOUT4);
	PrecacheSound(SCOUT5);
	PrecacheSound(SCOUT6);	
}

public void EventInventoryApplication(Handle event, const char[] name, bool dontBroadcast) 
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(g_bIsRobin[client])
	{
		SetEntProp(client, Prop_Send, "m_iHealth", 125, 1);
		
		StopSound(client, SNDCHAN_AUTO, SPAWN);
		StopSound(client, SNDCHAN_AUTO, SPAWN);		
		
		SetVariantInt(0);
		AcceptEntityInput(client, "SetForcedTauntCam");
		
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
		
		int weapon3 = GetPlayerWeaponSlot(client, 2); 
		if(IsValidEntity(weapon3))
		{
			TF2Attrib_RemoveAll(weapon3);
		}
		
		SetSpell2(client, 5, 0);
		
		g_bIsRobin[client] = false;

		SetEntProp(client, Prop_Send, "m_iHealth", 125, 1);
		TF2_RegeneratePlayer(client);	
	}
}

public void Event_Death(Handle event, const char[] name, bool dontBroadcast) 
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	int deathflags = GetEventInt(event, "death_flags");
	if (!(deathflags & TF_DEATHFLAG_DEADRINGER))
	{
		if (IsValidClient(client) && g_bIsRobin[client])
		{
			StopSound(client, SNDCHAN_AUTO, SPAWN);
			StopSound(client, SNDCHAN_AUTO, SPAWN);			
			
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
			
			int weapon3 = GetPlayerWeaponSlot(client, 2); 
			if(IsValidEntity(weapon3))
			{
				TF2Attrib_RemoveAll(weapon3);
			}
			
			SetEntProp(client, Prop_Send, "m_iHealth", 125, 1);

			SetSpell2(client, 5, 0);

			g_bIsRobin[client] = false;			
		}
	}
}

Action SetModel(int client)
{
	if (IsValidClient(client) && IsPlayerAlive(client))
	{
		TF2_RemoveAllWearables(client);
		
		CreateHat(client, 30735, 10, 6, 1); //Sidekicks Side Slick		
		CreateHat(client, 30736, 10, 6, 0); //Bat Backup		
		CreateHat(client, 30737, 10, 6, 0); //Crook Combatant	
		CreateHat(client, 30754, 10, 6, 0); //Hot Heels
		CreateHat(client, 31285, 10, 6, 0); //Pests Pads
	}
	return Plugin_Handled;
}

Action Command_Robin(int client, int args)
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
		MakeRobin(target_list[i]);
		LogAction(client, target_list[i], "\"%L\" made \"%L\" Robin!", client, target_list[i]);
		EmitSoundToClient(target_list[i], SPAWN);
		EmitSoundToClient(target_list[i], SPAWN);		
	}

	return Plugin_Handled;
}

Action MakeRobin(int client)
{
	TF2_SetPlayerClass(client, TFClass_Scout);

	RemoveTFModel(client);

	PrintToChat(client, "You are Robin.");
	PrintToChat(client, "You have 20 Stealth spells and a Grappling Hook.");	
	PrintToChat(client, "Use middle mouse button for random speech.");	
	PrintToChat(client, "To change to First Person view type in chat:  !fp");	
	PrintToChat(client, "To change to Third Person view type in chat:  !tp");
	PrintToChat(client, "You will lose your powers when you touch a locker or die.");

	CreateTimer(0.1, Timer_Switch, client);
	SetModel(client);

	TF2_SetHealth(client, 3000);

	SetSpell2(client, 5, 20);	
	
	TF2_AddCondition(client, TFCond_SpeedBuffAlly, 0.1);

	TF2_AddCondition(client, TFCond_SpawnOutline, 20.0);
	
	g_bIsRobin[client] = true;
	
	return Plugin_Handled;	
}

Action TF2_SetHealth(int client, int NewHealth)
{
	SetEntProp(client, Prop_Send, "m_iHealth", NewHealth, 1);
	SetEntProp(client, Prop_Data, "m_iHealth", NewHealth, 1);
	
	return Plugin_Handled;	
}

Action Timer_Switch(Handle timer, any client)
{
	if (IsValidClient(client) && TF2_GetPlayerClass(client) == TFClass_Scout)
	{

		TF2_RemoveWeaponSlot(client, 0);
		int paint = GetRandomUInt(200, 297);
		if(paint == 216 || paint == 219 || paint == 222 || paint == 227 || paint == 229 || paint == 231 || paint == 233 || paint == 274 || paint == 288)
		{		
			paint = GetRandomUInt(300, 310);
		}
		CreateWeapon(client, "tf_weapon_scattergun", 200, 6, 98, 0, paint);

		TF2_RemoveWeaponSlot(client, 1);
		paint = GetRandomUInt(200, 297);
		if(paint == 216 || paint == 219 || paint == 222 || paint == 227 || paint == 229 || paint == 231 || paint == 233 || paint == 274 || paint == 288)
		{		
			paint = GetRandomUInt(300, 310);
		}
		CreateWeapon(client, "tf_weapon_pistol", 209, 6, 97, 1, paint);

		TF2_RemoveWeaponSlot(client, 2);
		CreateWeapon(client, "tf_weapon_bat", 450, 6, 96, 2, 0);
		
		CreateWeapon(client, "tf_weapon_grapplinghook", 1152, 6, 98, 3, 0);			
		
		TF2_SwitchtoSlot(client, 0);	

		GiveRobin(client);
	}
	
	return Plugin_Handled;	
}

Action GiveRobin(int client)
{
	TF2Attrib_SetByName(client, "max health additive bonus", 2875.0);
	TF2Attrib_SetByName(client, "health from packs decreased", 0.0); 	
	TF2Attrib_SetByName(client, "major move speed bonus", 2.0);
	TF2Attrib_SetByName(client, "cancel falling damage", 1.0);			
	TF2Attrib_SetByName(client, "dmg taken from blast reduced", 0.5);
	TF2Attrib_SetByName(client, "dmg taken from fire reduced", 0.5);
	TF2Attrib_SetByName(client, "dmg taken from bullets reduced", 0.5);
	TF2Attrib_SetByName(client, "dmg taken from crit reduced", 0.5);
	TF2Attrib_SetByName(client, "dmg from ranged reduced", 0.5);
	TF2Attrib_SetByName(client, "SET BONUS: dmg from sentry reduced", 0.5);	
	TF2Attrib_SetByName(client, "damage force reduction", 0.5);				
	TF2Attrib_SetByName(client, "increase player capture value", 2.0);
	TF2Attrib_SetByName(client, "major increased jump height", 1.7);
	TF2Attrib_SetByName(client, "cannot be backstabbed", 1.0);
	TF2Attrib_SetByName(client, "increased air control", 10.0);	
	TF2Attrib_SetByName(client, "airblast vulnerability multiplier", 0.3);
	TF2Attrib_SetByName(client, "airblast vertical vulnerability multiplier", 0.3);
	
	int Weapon = GetPlayerWeaponSlot(client, TFWeaponSlot_Primary);
	if(IsValidEntity(Weapon))	
	{
		TF2Attrib_SetByName(Weapon, "fire rate bonus", 0.2);	
		TF2Attrib_SetByName(Weapon, "faster reload rate", 0.2);
		TF2Attrib_SetByName(Weapon, "damage bonus", 7.0);
		TF2Attrib_SetByName(Weapon, "projectile penetration", 1.0);
		TF2Attrib_SetByName(Weapon, "attack projectiles", 1.0);				
		TF2Attrib_SetByName(Weapon, "maxammo primary increased", 5.0);
		TF2Attrib_SetByName(Weapon, "clip size bonus", 5.0);
		TF2Attrib_SetByName(Weapon, "armor piercing", 40.0);
		TF2Attrib_SetByName(Weapon, "ammo regen", 1.0);
		TF2Attrib_SetByName(Weapon, "killstreak tier", 3.0);
		TF2Attrib_SetByName(Weapon, "killstreak effect", 2005.0);
		TF2Attrib_SetByName(Weapon, "killstreak idleeffect", 7.0);
		
		SetEntProp(Weapon, Prop_Send, "m_iClip1", 30);
	}

	int Weapon2 = GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary);
	if(IsValidEntity(Weapon2))
	{
		TF2Attrib_SetByName(Weapon2, "fire rate bonus", 0.4);	
		TF2Attrib_SetByName(Weapon2, "faster reload rate", 0.4);
		TF2Attrib_SetByName(Weapon2, "damage bonus", 7.0);
		TF2Attrib_SetByName(Weapon2, "projectile penetration", 1.0);
		TF2Attrib_SetByName(Weapon2, "attack projectiles", 1.0);
		TF2Attrib_SetByName(Weapon2, "armor piercing", 40.0);
		TF2Attrib_SetByName(Weapon2, "maxammo secondary increased", 2.0);
		TF2Attrib_SetByName(Weapon2, "clip size bonus", 5.0);
		TF2Attrib_SetByName(Weapon2, "killstreak tier", 3.0);
		TF2Attrib_SetByName(Weapon2, "killstreak effect", 2005.0);
		TF2Attrib_SetByName(Weapon2, "killstreak idleeffect", 7.0);		
	}
	
	int Weapon3 = GetPlayerWeaponSlot(client, TFWeaponSlot_Melee);
	if(IsValidEntity(Weapon3))
	{
		TF2Attrib_SetByName(Weapon3, "melee attack rate bonus", 0.5);	
		TF2Attrib_SetByName(Weapon3, "melee bounds multiplier", 2.0);					
		TF2Attrib_SetByName(Weapon3, "melee range multiplier", 2.0);
		TF2Attrib_SetByName(Weapon3, "damage bonus", 7.0);
		TF2Attrib_SetByName(Weapon3, "armor piercing", 40.0);
		TF2Attrib_SetByName(Weapon3, "speed buff ally", 1.0);
		TF2Attrib_SetByName(Weapon3, "dmg bonus vs buildings", 3.0);
		TF2Attrib_SetByName(Weapon3, "damage applies to sappers", 1.0);
		TF2Attrib_SetByName(Weapon3, "killstreak tier", 3.0);
		TF2Attrib_SetByName(Weapon3, "killstreak effect", 2005.0);
		TF2Attrib_SetByName(Weapon3, "killstreak idleeffect", 7.0);
		TF2Attrib_SetByName(Weapon3, "air dash count", 2.0);
		TF2Attrib_SetByName(Weapon3, "SPELL: set Halloween footstep type", 13595446.0);		
	}
	
	TF2_AddCondition(client, TFCond_RadiusHealOnDamage, 5.0);
	
	return Plugin_Handled;	
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon)
{ 
	if (g_bIsRobin[client] == true && buttons & IN_ATTACK3 && g_Wait1[client] == false) 
	{  
		int iRand = GetRandomUInt(1,6);
		if (iRand == 1)
		{
			EmitSoundToAll(SCOUT1, client);
		}
		else if (iRand == 2)
		{
			EmitSoundToAll(SCOUT2, client);	
		}	
		else if (iRand == 3)
		{
			EmitSoundToAll(SCOUT3, client);	
		}
		else if (iRand == 4)
		{
			EmitSoundToAll(SCOUT4, client);	
		}
		else if (iRand == 5)
		{
			EmitSoundToAll(SCOUT5, client);	
		}		
		else if (iRand == 6)
		{
			EmitSoundToAll(SCOUT6, client);	
		}
	
		g_Wait1[client] = true;
		CreateTimer(2.0, Waiting1, client); 
	} 
	
	return Plugin_Continue;
}

public Action Waiting1(Handle timer, any client) 
{
	g_Wait1[client] = false;

	return Plugin_Handled; 	
}

bool IsValidClient(int client)
{
	if (client <= 0) return false;
	if (client > MaxClients) return false;
	return IsClientInGame(client);
}

bool CreateHat(int client, int itemindex, int level, int quality, int unusual = 0, int paint = 0)
{
	int hat = CreateEntityByName("tf_wearable");
	
	if (!IsValidEntity(hat))
	{
		return false;
	}
	
	char entclass[64];
	GetEntityNetClass(hat, entclass, sizeof(entclass));
	SetEntProp(hat, Prop_Send, "m_iItemDefinitionIndex", itemindex);
	SetEntProp(hat, Prop_Send, "m_bInitialized", 1); 	
	SetEntData(hat, FindSendPropInfo(entclass, "m_iEntityQuality"), quality);	
	SetEntProp(hat, Prop_Send, "m_bValidatedAttachedEntity", 1); 
	
	if (level != 0)
	{
		SetEntProp(hat, Prop_Send, "m_iEntityLevel", level);
	}
	else
	{
		SetEntProp(hat, Prop_Send, "m_iEntityLevel", GetRandomUInt(1,100));
	}

	if (quality == 6)
	{
		if (GetRandomUInt(1,5) == 1)
		{
			SetEntData(hat, FindSendPropInfo(entclass, "m_iEntityQuality"), 11);	
			TF2Attrib_SetByDefIndex(hat, 214, view_as<float>(GetRandomUInt(0, 9000)));
		}
	}	

	if (unusual == 1)
	{
		TF2Attrib_SetByName(hat, "particle effect use head origin", 1.0);
		SetEntData(hat, FindSendPropInfo(entclass, "m_iEntityQuality"), 5);	
		TF2Attrib_SetByDefIndex(hat, 134, GetRandomInt(1,270) + 0.0);
	}

	if (unusual > 1)
	{
		TF2Attrib_SetByName(hat, "particle effect use head origin", 1.0);
		SetEntData(hat, FindSendPropInfo(entclass, "m_iEntityQuality"), 5);	
		TF2Attrib_SetByDefIndex(hat, 134, unusual + 0.0);
	}
	
	if(itemindex == 1158 || itemindex == 1173)
	{
		TF2Attrib_SetByDefIndex(hat, 134, GetRandomUInt(1,174) + 0.0);
	}
	
	if(itemindex == 31285)
	{
		TF2Attrib_SetByName(hat, "item style override", 2.0);		
	}
	
	if(itemindex == 30735)
	{
		TF2Attrib_SetByName(hat, "item style override", 2.0);		
	}	
	
	if (paint > 0)
	{
		switch(paint)
		{
		case 1:
			{
				TF2Attrib_SetByDefIndex(hat, 142, 3100495.0);
				TF2Attrib_SetByDefIndex(hat, 261, 3100495.0);
			}
		case 2:
			{
				TF2Attrib_SetByDefIndex(hat, 142, 8208497.0);
				TF2Attrib_SetByDefIndex(hat, 261, 8208497.0);
			}
		case 3:
			{
				TF2Attrib_SetByDefIndex(hat, 142, 1315860.0);
				TF2Attrib_SetByDefIndex(hat, 261, 1315860.0);
			}
		case 4:
			{
				TF2Attrib_SetByDefIndex(hat, 142, 12377523.0);
				TF2Attrib_SetByDefIndex(hat, 261, 12377523.0);
			}
		case 5:
			{
				TF2Attrib_SetByDefIndex(hat, 142, 2960676.0);
				TF2Attrib_SetByDefIndex(hat, 261, 2960676.0);
			}
		case 6:
			{
				TF2Attrib_SetByDefIndex(hat, 142, 8289918.0);
				TF2Attrib_SetByDefIndex(hat, 261, 8289918.0);
			}
		case 7:
			{
				TF2Attrib_SetByDefIndex(hat, 142, 15132390.0);
				TF2Attrib_SetByDefIndex(hat, 261, 15132390.0);
			}
		case 8:
			{
				TF2Attrib_SetByDefIndex(hat, 142, 15185211.0);
				TF2Attrib_SetByDefIndex(hat, 261, 15185211.0);
			}
		case 9:
			{
				TF2Attrib_SetByDefIndex(hat, 142, 14204632.0);
				TF2Attrib_SetByDefIndex(hat, 261, 14204632.0);
			}
		case 10:
			{
				TF2Attrib_SetByDefIndex(hat, 142, 15308410.0);
				TF2Attrib_SetByDefIndex(hat, 261, 15308410.0);
			}
		case 11:
			{
				TF2Attrib_SetByDefIndex(hat, 142, 8421376.0);
				TF2Attrib_SetByDefIndex(hat, 261, 8421376.0);
			}
		case 12:
			{
				TF2Attrib_SetByDefIndex(hat, 142, 7511618.0);
				TF2Attrib_SetByDefIndex(hat, 261, 7511618.0);
			}
		case 13:
			{
				TF2Attrib_SetByDefIndex(hat, 142, 13595446.0);
				TF2Attrib_SetByDefIndex(hat, 261, 13595446.0);
			}
		case 14:
			{
				TF2Attrib_SetByDefIndex(hat, 142, 10843461.0);
				TF2Attrib_SetByDefIndex(hat, 261, 10843461.0);
			}
		case 15:
			{
				TF2Attrib_SetByDefIndex(hat, 142, 5322826.0);
				TF2Attrib_SetByDefIndex(hat, 261, 5322826.0);
			}
		case 16:
			{
				TF2Attrib_SetByDefIndex(hat, 142, 12955537.0);
				TF2Attrib_SetByDefIndex(hat, 261, 12955537.0);
			}
		case 17:
			{
				TF2Attrib_SetByDefIndex(hat, 142, 16738740.0);
				TF2Attrib_SetByDefIndex(hat, 261, 16738740.0);
			}
		case 18:
			{
				TF2Attrib_SetByDefIndex(hat, 142, 6901050.0);
				TF2Attrib_SetByDefIndex(hat, 261, 6901050.0);
			}
		case 19:
			{
				TF2Attrib_SetByDefIndex(hat, 142, 3329330.0);
				TF2Attrib_SetByDefIndex(hat, 261, 3329330.0);
			}
		case 20:
			{
				TF2Attrib_SetByDefIndex(hat, 142, 15787660.0);
				TF2Attrib_SetByDefIndex(hat, 261, 15787660.0);
			}
		case 21:
			{
				TF2Attrib_SetByDefIndex(hat, 142, 8154199.0);
				TF2Attrib_SetByDefIndex(hat, 261, 8154199.0);
			}
		case 22:
			{
				TF2Attrib_SetByDefIndex(hat, 142, 4345659.0);
				TF2Attrib_SetByDefIndex(hat, 261, 4345659.0);
			}
		case 23:
			{
				TF2Attrib_SetByDefIndex(hat, 142, 6637376.0);
				TF2Attrib_SetByDefIndex(hat, 261, 2636109.0);
			}
		case 24:
			{
				TF2Attrib_SetByDefIndex(hat, 142, 3874595.0);
				TF2Attrib_SetByDefIndex(hat, 261, 1581885.0);
			}
		case 25:
			{
				TF2Attrib_SetByDefIndex(hat, 142, 12807213.0);
				TF2Attrib_SetByDefIndex(hat, 261, 12091445.0);
			}
		case 26:
			{
				TF2Attrib_SetByDefIndex(hat, 142, 4732984.0);
				TF2Attrib_SetByDefIndex(hat, 261, 3686984.0);
			}
		case 27:
			{
				TF2Attrib_SetByDefIndex(hat, 142, 12073019.0);
				TF2Attrib_SetByDefIndex(hat, 261, 5801378.0);
			}
		case 28:
			{
				TF2Attrib_SetByDefIndex(hat, 142, 8400928.0);
				TF2Attrib_SetByDefIndex(hat, 261, 2452877.0);
			}
		case 29:
			{
				TF2Attrib_SetByDefIndex(hat, 142, 11049612.0);
				TF2Attrib_SetByDefIndex(hat, 261, 8626083.0);
			}
		}
	}

	DispatchSpawn(hat);
	SDKCall(g_hEquipWearable, client, hat);
	return true;
} 

bool CreateWeapon(int client, char[] classname, int itemindex, int quality, int level, int slot, int paint)
{
	TF2_RemoveWeaponSlot(client, slot);

	int weapon = CreateEntityByName(classname);

	if (!IsValidEntity(weapon))
	{
		return false;
	}
	
	quality = 15;
	
	char entclass[64];
	GetEntityNetClass(weapon, entclass, sizeof(entclass));
	SetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex", itemindex);	 
	SetEntProp(weapon, Prop_Send, "m_bInitialized", 1);
	SetEntData(weapon, FindSendPropInfo(entclass, "m_iEntityQuality"), quality);
	SetEntProp(weapon, Prop_Send, "m_bValidatedAttachedEntity", 1);
	
	if (level)
	{
		SetEntData(weapon, FindSendPropInfo(entclass, "m_iEntityLevel"), level);
	}
	else
	{
		SetEntData(weapon, FindSendPropInfo(entclass, "m_iEntityLevel"), GetRandomUInt(1,99));
	}

	if(paint > 0)
	{
		TF2Attrib_SetByDefIndex(weapon, 834, view_as<float>(paint));	//Set Warpaint
	}
	
	if (GetRandomUInt(1,4) == 1)
	{
		SetEntData(weapon, FindSendPropInfo(entclass, "m_iEntityQuality"), 11);

		TF2Attrib_SetByDefIndex(weapon, 2025, 1.0);

		if (GetRandomUInt(1,5) == 2)
		{
			TF2Attrib_SetByDefIndex(weapon, 2025, 2.0);
			TF2Attrib_SetByDefIndex(weapon, 2014, GetRandomUInt(1,7) + 0.0);
		}
		else if (GetRandomUInt(1,5) == 3)
		{
			TF2Attrib_SetByDefIndex(weapon, 2025, 3.0);
			TF2Attrib_SetByDefIndex(weapon, 2014, GetRandomUInt(1,7) + 0.0);
			TF2Attrib_SetByDefIndex(weapon, 2013, GetRandomUInt(2002,2008) + 0.0);
		}
		TF2Attrib_SetByDefIndex(weapon, 214, view_as<float>(GetRandomUInt(0, 9000)));
	}
	
	//	TF2Attrib_SetByDefIndex(weapon, 725, GetRandomFloat(0.0,1.0));  //Weapon texture wear

	DispatchSpawn(weapon);
	EquipPlayerWeapon(client, weapon); 

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
			|| itemindex == 194				
			|| itemindex == 210)	
	{
		SetEntData(weapon, FindSendPropInfo(entclass, "m_iEntityQuality"), 5);
		TF2_SwitchtoSlot(client, slot);
		int iRand = GetRandomUInt(1,4);
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

	TF2_SwitchtoSlot(client, 0);
	
	return true;
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
	return Plugin_Handled;
}

int GetRandomUInt(int min, int max)
{
	return RoundToFloor(GetURandomFloat() * (max - min + 1)) + min;
}

Action TF2_RemoveAllWearables(int client)
{
	RemoveWearable(client, "tf_wearable", "CTFWearable");
	RemoveWearable(client, "tf_powerup_bottle", "CTFPowerupBottle");
	return Plugin_Handled;
}

Action RemoveWearable(int client, char[] classname, char[] networkclass)
{
	if (IsPlayerAlive(client))
	{
		int edict = MaxClients+1;
		while((edict = FindEntityByClassname(edict, classname)) != -1)
		{
			char netclass[32];
			if (GetEntityNetClass(edict, netclass, sizeof(netclass)) && StrEqual(netclass, networkclass))
			{
				if (GetEntPropEnt(edict, Prop_Send, "m_hOwnerEntity") == client)
				{
					AcceptEntityInput(edict, "Kill"); 
				}
			}
		}
	}
	return Plugin_Handled;	
}

int SetSpell2(int client, int spell, int uses)
{
	int ent = GetSpellBook(client);
	if(!IsValidEntity(ent)) return -1;
	SetEntProp(ent, Prop_Send, "m_iSelectedSpellIndex", spell);
	SetEntProp(ent, Prop_Send, "m_iSpellCharges", uses);
	return 1;
}  

int GetSpellBook(int client)
{
	int entity = -1;
	while((entity = FindEntityByClassname(entity, "tf_weapon_spellbook")) != INVALID_ENT_REFERENCE)
	{
		if(GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity") == client) return entity;
	}
	return -1;
}

Action RemoveTFModel(int client)
{
	TF2_RemoveAllWearables(client);	
	SetVariantString("");
	AcceptEntityInput(client, "SetCustomModel");
	SetEntProp(client, Prop_Send, "m_bCustomModelRotates", 0);
	SetVariantString("ParticleEffectStop");
	AcceptEntityInput(client, "DispatchEffect");

	return Plugin_Handled;
}