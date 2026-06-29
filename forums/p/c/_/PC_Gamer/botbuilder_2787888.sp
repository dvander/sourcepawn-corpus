#include <tf_econ_data>
#include <TF2attributes> 

#pragma semicolon 1
#pragma newdecls required

bool g_bMedieval;
bool g_bTouch[MAXPLAYERS+1] = {false, ...};
bool g_bSpecialBot[MAXPLAYERS+1] = {false, ...};
Handle g_hWearableEquip;

public Plugin myinfo = 
{
	name = "[TF2] Bot Builder",
	author = "PC Gamer",
	description = "Force Bot weapons, cosmetics, and attributes",
	version = "PLUGIN_VERSION 1.0",
	url = "www.sourcemod.com"	
}

public void OnPluginStart()
{
	HookEvent("post_inventory_application", PreBoost);
	HookEvent("player_death", Event_Death, EventHookMode_Post);
	
	GameData hTF2 = new GameData("sm-tf2.games"); // sourcemod's tf2 gamedata

	if (!hTF2)
		SetFailState("This plugin is designed for a TF2 dedicated server only.");

	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetVirtual(hTF2.GetOffset("RemoveWearable") - 1);    // EquipWearable offset is always behind RemoveWearable, subtract its value by 1
	PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
	g_hWearableEquip = EndPrepSDKCall();

	if (!g_hWearableEquip)
		SetFailState("Failed to create call: CBasePlayer::EquipWearable");

	delete hTF2; 	
}

public void OnMapStart()
{
	if (GameRules_GetProp("m_bPlayingMedieval"))
	{
		g_bMedieval = true;
	}	
}

public void Event_Death(Handle event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	int deathflags = GetEventInt(event, "death_flags");
	if (!(deathflags & TF_DEATHFLAG_DEADRINGER))
	{
		if (IsValidClient(client) && g_bSpecialBot[client])
		{
			TF2Attrib_RemoveAll(client);
			int Weapon = GetPlayerWeaponSlot(client, TFWeaponSlot_Primary);
			if(IsValidEntity(Weapon))
			{
				TF2Attrib_RemoveAll(Weapon);
			}
			int Weapon2 = GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary);
			if(IsValidEntity(Weapon2))
			{
				TF2Attrib_RemoveAll(Weapon2);
			}
			int Weapon3 = GetPlayerWeaponSlot(client, TFWeaponSlot_Melee);
			if(IsValidEntity(Weapon3))
			{
				TF2Attrib_RemoveAll(Weapon3);
			}
			int Weapon4 = GetPlayerWeaponSlot(client, TFWeaponSlot_PDA);
			if(IsValidEntity(Weapon4))
			{
				TF2Attrib_RemoveAll(Weapon4);
			}
			g_bSpecialBot[client] = false;
		}
	}
}

public void PreBoost(Handle event, const char[] name, bool dontBroadcast)
{
	int userd = GetEventInt(event, "userid");
	int client = GetClientOfUserId(userd);
	if(IsFakeClient(client) && IsClientInGame(client) && !g_bTouch[client])
	{
		g_bTouch[client] = true;
		CreateTimer(3.0, Timer_BotBoost, client);
	}
}

public Action Timer_BotBoost(Handle timer, int client)
{
	if(client == 0 || !IsClientConnected(client))
	{
		return Plugin_Handled;
	}

	char szName[32];
	GetClientName(client, szName, sizeof(szName));

	if(StrEqual("Fake Batman", szName, true))// Bot is named: Fake Batman
	{
		ResetClass(client);
		
		RemoveAllWearables(client);

		CreateHat(client, 30720); //Arkham Cowl
		CreateHat(client, 30722); //Batters Bracers
		CreateHat(client, 30738); //Bat Belt
		CreateHat(client, 30727); //Caped Crusader	
		
		CreateWeapon(client, 1071); //give Golden Frying Pan
	}	
	if(StrEqual("Fred", szName, true))// Look for Bot named: Fred
	{
		ResetClass(client);
		TF2_SetPlayerClass(client, TFClass_Heavy);  //make Heavy class
	
		RemoveAllWearables(client);

		//Use this format to CreateHat(client, itemindex, quality, int paint, unusual)
		//Example: CreateHat(client, 96); //Officers Ushanka using default values
		//Example 2: CreateHat(client, 96, 5, 2, 185); //Officers Ushanka level 50, unusual quality, purple color, flowers unusual effect
		//Example 3: CreateHat(client, 96, 5, 999, 999); //Officers Ushanka with random paint and random unusual effect
		//Note: quality is 0-15, paint colors are 1-29, unusual effects change with updates but is currently 1-256 
		
		CreateHat(client, 96); //Officers Ushanka
		CreateHat(client, 30306); //Dictator			
		CreateHat(client, 30633); //Comissars Coat
		
		//Use this format to CreateWeapon(int client, int itemindex, int quality = 0, int warpaint = 0)

		if (!g_bMedieval) //Check to ensure it isn't Medieval Mode gameplay
		{		
			CreateWeapon(client, 41);//give Natasha
			CreateWeapon(client, 425, 6); //give unique quality The Family Business
		}
		CreateWeapon(client, 310, 6); //give unique quality warriors spirit
	}
	if(StrEqual("Redimus", szName, true))// Bot is named: Redimus
	{
		ResetClass(client);
		TF2_SetPlayerClass(client, TFClass_Scout);  //make Scout class
		
		RemoveAllWearables(client);

		CreateHat(client, 30718); //Baargh n Bicorne
		CreateHat(client, 30185); //Flapjack				
		CreateHat(client, 30719); //Baargh n Britches

		if (!g_bMedieval)
		{			
			CreateWeapon(client, 45, 9);//give Australium Force-A-Nature
			CreateWeapon(client, 449, 6); //give unique quality Winger
		}
		CreateWeapon(client, 349, 6); //give unique quality Sun-on-a-Stick		
	}

	if(StrEqual("Beepman", szName, true))// Bot is named: Beepman
	{
		ResetClass(client);
		TF2_SetPlayerClass(client, TFClass_Engineer);  //make Engineer class
		
		RemoveAllWearables(client);

		CreateHat(client, 30509, 5, 999, 999); //Beep Man with random paint and random unusual effect
		CreateHat(client, 30167); //Beep Boy	
		CreateHat(client, 31013); //Mini Engy

		if (!g_bMedieval)
		{			
			CreateWeapon(client, 199, 5, 232); //give unusual Alien Tech shotgun
			CreateWeapon(client, 209, 6, 232); //give unique Alien Tech pistol
		}
		CreateWeapon(client, 169);	//give golden wrench	
		
		TF2Attrib_RemoveAll(client);

		TF2Attrib_SetByName(client, "max health additive bonus", 1875.0); //Has more health
		TF2Attrib_SetByName(client, "major move speed bonus", 1.5);  //Moves faster
				
		int Weapona = GetPlayerWeaponSlot(client, TFWeaponSlot_Primary); //primary weapon changes
		if(IsValidEntity(Weapona))
		{
			TF2Attrib_SetByName(Weapona, "damage bonus", 1.5); //Does 50% more damage
			TF2Attrib_SetByName(Weapona, "dmg bonus vs buildings", 2.5); //does 250% more damage to buildings	
			TF2Attrib_SetByName(Weapona, "fire rate bonus", 0.5);	//shoots faster
			TF2Attrib_SetByName(Weapona, "faster reload rate", 0.6); //reloads faster		
		}
		
		int Weaponb = GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary); //secondary weapon changes
		if(IsValidEntity(Weaponb))
		{
			TF2Attrib_SetByName(Weaponb, "damage bonus", 1.5); //Does 50% more damage
			TF2Attrib_SetByName(Weaponb, "dmg bonus vs buildings", 2.5); //does 250% more damage to buildings					
		}
		
		int Weaponc = GetPlayerWeaponSlot(client, TFWeaponSlot_Melee); // melee weapon changes
		if(IsValidEntity(Weaponb))
		{
			TF2Attrib_SetByName(Weaponc, "damage bonus", 1.5); //Does 50% more damage
			TF2Attrib_SetByName(Weaponc, "dmg bonus vs buildings", 2.5); //does 250% more damage to buildings					
			TF2Attrib_SetByName(Weaponc, "build rate bonus", 0.1);
			TF2Attrib_SetByName(Weaponc, "upgrade rate decrease", 3.0);
			TF2Attrib_SetByName(Weaponc, "repair rate increased", 3.0);
		}

		int Weapond = GetPlayerWeaponSlot(client, TFWeaponSlot_PDA);
		if(IsValidEntity(Weapond))
		{
			TF2Attrib_SetByName(Weapond, "building instant upgrade", 1.0);	
			TF2Attrib_SetByName(Weapond, "engy sentry fire rate increased", 0.5);					
			TF2Attrib_SetByName(Weapond, "engy sentry radius increased", 2.0);
			TF2Attrib_SetByName(Weapond, "engy dispenser radius increased", 2.0);
			TF2Attrib_SetByName(Weapond, "armor piercing", 50.0);
			TF2Attrib_SetByName(Weapond, "dmg pierces resists absorbs", 1.0);
			TF2Attrib_SetByName(Weapond, "has pipboy build interface", 1.0);
			TF2Attrib_SetByName(Weapond, "bidirectional teleport", 1.0);
			TF2Attrib_SetByName(Weapond, "engy sentry damage bonus", 5.0);	
			TF2Attrib_SetByName(Weapond, "engy building health bonus", 5.0);
			TF2Attrib_SetByName(Weapond, "maxammo metal increased", 3.0);
			TF2Attrib_SetByName(Weapond, "metal regen", 50.0);	
			TF2Attrib_SetByName(Weapond, "repair rate increased", 5.0);	
			TF2Attrib_SetByName(Weapond, "construction rate increased", 8.0);
			TF2Attrib_SetByName(Weapond, "SPELL: Halloween pumpkin explosions", 1.0);
			TF2Attrib_SetByName(Weapond, "mult teleporter recharge rate", 0.1);	
			TF2Attrib_SetByName(Weapond, "mult dispenser rate", 9.99);	
			TF2Attrib_SetByName(Weapond, "mvm sentry ammo", 19.99);	
		}
	}	

	if(StrEqual("UBDead", szName, true))// Bot is named: UBDead
	{
		ResetClass(client);
		TF2_SetPlayerClass(client, TFClass_Soldier);  //make Soldier class
		
		RemoveAllWearables(client);
		
		//Notice that we're using more than 3 cosmetic items
		CreateHat(client, 30578, 5, 999, 999); //Skullcap
		CreateHat(client, 852); //Stogie		
		CreateHat(client, 30853); //Flakcatcher
		CreateHat(client, 30985); //Private Maggot Muncher	

		//format to use: CreateWeapon(int client, int itemindex, int quality = 0, int warpaint = 0)
		//Example: CreateWeapon(client, 199, 5, 232); //give unusual Alien Tech shotgun
		if (!g_bMedieval)
		{
			CreateWeapon(client, 205, 5, 999); //create unusual rocket launcher with random Warpaint
			CreateWeapon(client, 199, 6, 999); //create unique soldier shotgun with random Warpaint
		}

		CreateWeapon(client, 447, 6, 999); //Create Disciplinary Action with random Warpaint
		
		//Attributes to add to the client's Body
		TF2Attrib_RemoveAll(client);
		
		TF2Attrib_SetByName(client, "max health additive bonus", 4800.0);
		TF2Attrib_SetByName(client, "major move speed bonus", 2.0);
		TF2Attrib_SetByName(client, "cancel falling damage", 1.0);			
		TF2Attrib_SetByName(client, "dmg taken from blast reduced", 0.5);
		TF2Attrib_SetByName(client, "dmg taken from fire reduced", 0.5);
		TF2Attrib_SetByName(client, "dmg taken from bullets reduced", 0.5);
		TF2Attrib_SetByName(client, "dmg taken from crit reduced", 0.5);
		TF2Attrib_SetByName(client, "dmg from ranged reduced", 0.5);
		TF2Attrib_SetByName(client, "SET BONUS: dmg from sentry reduced", 0.5);	
		TF2Attrib_SetByName(client, "damage force reduction", 0.5);				
		TF2Attrib_SetByName(client, "increase player capture value", 3.0);
		TF2Attrib_SetByName(client, "major increased jump height", 3.0);
		TF2Attrib_SetByName(client, "parachute attribute", 1.0);
		TF2Attrib_SetByName(client, "cannot be backstabbed", 1.0);
		TF2Attrib_SetByName(client, "increased air control", 25.0);	
		TF2Attrib_SetByName(client, "airblast vulnerability multiplier", 0.5);
		TF2Attrib_SetByName(client, "airblast vertical vulnerability multiplier", 0.5);
		TF2Attrib_SetByName(client, "health from packs decreased", 0.001);	

		//Attributes added to the client's primary weapon
		int Weapona = GetPlayerWeaponSlot(client, TFWeaponSlot_Primary);
		if(IsValidEntity(Weapona))
		{					
			TF2Attrib_SetByName(Weapona, "fire rate bonus", 0.2);	
			TF2Attrib_SetByName(Weapona, "faster reload rate", 0.2);
			TF2Attrib_SetByName(Weapona, "damage bonus", 10.0);
			TF2Attrib_SetByName(Weapona, "no self blast dmg", 2.0);				
			TF2Attrib_SetByName(Weapona, "projectile penetration", 1.0);
			TF2Attrib_SetByName(Weapona, "attack projectiles", 1.0);				
			TF2Attrib_SetByName(Weapona, "maxammo primary increased", 4.0);
			TF2Attrib_SetByName(Weapona, "clip size bonus", 5.0);
			TF2Attrib_SetByName(Weapona, "armor piercing", 40.0);
			TF2Attrib_SetByName(Weapona, "ammo regen", 2.0);
			TF2Attrib_SetByName(Weapona, "killstreak tier", 3.0);
			TF2Attrib_SetByName(Weapona, "killstreak effect", 2005.0);
			TF2Attrib_SetByName(Weapona, "killstreak idleeffect", 7.0);
			TF2Attrib_SetByName(Weapona, "blast radius increased", 3.0);			
		}
		//Attributes to add to the client's secondary weapon
		int Weaponb = GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary);
		if(IsValidEntity(Weaponb))
		{		
			TF2Attrib_SetByName(Weaponb, "fire rate bonus", 0.2);	
			TF2Attrib_SetByName(Weaponb, "faster reload rate", 0.2);
			TF2Attrib_SetByName(Weaponb, "damage bonus", 10.0);
			TF2Attrib_SetByName(Weaponb, "projectile penetration", 1.0);
			TF2Attrib_SetByName(Weaponb, "attack projectiles", 1.0);				
			TF2Attrib_SetByName(Weaponb, "maxammo secondary increased", 4.0);
			TF2Attrib_SetByName(Weaponb, "clip size bonus", 5.0);
			TF2Attrib_SetByName(Weaponb, "armor piercing", 40.0);
			TF2Attrib_SetByName(Weaponb, "ammo regen", 2.0);
			TF2Attrib_SetByName(Weaponb, "no self blast dmg", 2.0);	
			TF2Attrib_SetByName(Weaponb, "killstreak tier", 3.0);
			TF2Attrib_SetByName(Weaponb, "killstreak effect", 2005.0);
			TF2Attrib_SetByName(Weaponb, "killstreak idleeffect", 7.0);
		}
		//Attributes to add to the clients Melee weapon
		int Weaponc = GetPlayerWeaponSlot(client, TFWeaponSlot_Melee);
		if(IsValidEntity(Weaponc))
		{
			TF2Attrib_SetByName(Weaponc, "melee attack rate bonus", 0.3);	
			TF2Attrib_SetByName(Weaponc, "melee bounds multiplier", 2.0);					
			TF2Attrib_SetByName(Weaponc, "melee range multiplier", 2.0);
			TF2Attrib_SetByName(Weaponc, "damage bonus", 10.0);
			TF2Attrib_SetByName(Weaponc, "armor piercing", 40.0);
			TF2Attrib_SetByName(Weaponc, "speed buff ally", 1.0);
			TF2Attrib_SetByName(Weaponc, "killstreak tier", 3.0);
			TF2Attrib_SetByName(Weaponc, "killstreak effect", 2005.0);
			TF2Attrib_SetByName(Weaponc, "killstreak idleeffect", 7.0);				
		}
	}
	if(StrEqual("Samurai", szName, true))// Bot is named: Samurai
	{
		ResetClass(client);
		TF2_SetPlayerClass(client, TFClass_DemoMan);  //make DemoMan class
		
		RemoveAllWearables(client);
		
		//Notice that we're using more than 3 cosmetic items
		CreateHat(client, 359, 5, 999); //Samur Eye
		CreateHat(client, 875); //Menpo		
		CreateHat(client, 30348); //Bushi Dou
		CreateHat(client, 30366); //Sangu Sleeves
		CreateHat(client, 30742); //Shin Shredders			
		
		TF2_RemoveWeaponSlot(client, 0); // Removing primary weapon
		CreateWeapon(client, 406); //Splendid Screen
		CreateWeapon(client, 357); //Katana
		
		int iEntity = -1;
		while ((iEntity = FindEntityByClassname(iEntity, "tf_wearable_demoshield")) != -1)
		{
			if (client == GetEntPropEnt(iEntity, Prop_Data, "m_hOwnerEntity"))
			{
				TF2Attrib_SetByName(iEntity, "charge time increased", 5.0);
				TF2Attrib_SetByName(iEntity, "charge recharge rate increased", 4.0);
				TF2Attrib_SetByName(iEntity, "charge impact damage increased", 20.0);	
				TF2Attrib_SetByName(iEntity, "mult charge turn control", 20.0);
				TF2Attrib_SetByName(iEntity, "move speed penalty", 1.5);
				TF2Attrib_SetByName(iEntity, "major increased jump height", 1.5);				
				break;
			}
		}

		TF2Attrib_SetByName(client, "max health additive bonus", 4825.0);
		TF2Attrib_SetByName(client, "health from packs decreased", 0.0);
		TF2Attrib_SetByName(client, "cannot be backstabbed", 1.0);	

		int Weaponc = GetPlayerWeaponSlot(client, TFWeaponSlot_Melee);
		if(IsValidEntity(Weaponc))
		{
			TF2Attrib_RemoveAll(Weaponc);
			
			TF2Attrib_SetByName(Weaponc, "critboost on kill", 4.0);
			TF2Attrib_SetByName(Weaponc, "slow enemy on hit major", 5.0);	
			TF2Attrib_SetByName(Weaponc, "speed buff ally", 1.0);
			TF2Attrib_SetByName(Weaponc, "damage bonus", 8.0);
			TF2Attrib_SetByName(Weaponc, "dmg bonus vs buildings", 8.0);			
			TF2Attrib_SetByName(Weaponc, "melee bounds multiplier", 3.0);	
			TF2Attrib_SetByName(Weaponc, "melee range multiplier", 3.0);	
			TF2Attrib_SetByName(Weaponc, "melee attack rate bonus", 0.4);
			TF2Attrib_SetByName(Weaponc, "armor piercing", 5.0);	
			TF2Attrib_SetByName(Weaponc, "turn to gold", 1.0);
			TF2Attrib_SetByName(Weaponc, "SPELL: set Halloween footstep type", 13595446.0);			
			TF2_AddCondition(client, TFCond_RadiusHealOnDamage, 3.0);			
		}

	}	
	g_bTouch[client] = false;
	
	return Plugin_Handled;
}

Action CreateHat(int client, int itemindex, int quality = 6, int paint = 0, int unusual = 0)
{
	int hat = CreateEntityByName("tf_wearable");

	if (!IsValidEntity(hat))
	{
		return Plugin_Handled;
	}
	
	char entclass[64];
	GetEntityNetClass(hat, entclass, sizeof(entclass));
	SetEntProp(hat, Prop_Send, "m_iItemDefinitionIndex", itemindex);	 
	SetEntProp(hat, Prop_Send, "m_bInitialized", 1);
	SetEntData(hat, FindSendPropInfo(entclass, "m_iEntityQuality"), quality);
	SetEntProp(hat, Prop_Send, "m_iEntityLevel", GetRandomUInt(1, 99));

	if (quality == 11)
	{
		SetEntData(hat, FindSendPropInfo(entclass, "m_iEntityQuality"), 11);
		TF2Attrib_SetByDefIndex(hat, 214, view_as<float>(GetRandomUInt(0, 9000)));
	}	

	if (unusual == 999)
	{
		unusual = GetRandomUInt(1,256);
	}

	if (unusual > 0)
	{
		SetEntProp(hat, Prop_Send, "m_iEntityQuality", 5);
		TF2Attrib_SetByDefIndex(hat, 134, unusual + 0.0);
	}	
	
	if (itemindex == 1158 || itemindex == 1173)
	{
		SetEntProp(hat, Prop_Send, "m_iEntityQuality", 5);
		TF2Attrib_SetByDefIndex(hat, 134, GetRandomUInt(1,256) + 0.0);
	}

	if (paint == 999)
	{
		paint = GetRandomUInt(1,29);
	}
	
	if (paint > 0)
	{
		switch(paint)
		{
		case 1:
			{
				TF2Attrib_SetByDefIndex(hat, 142, 3100495.0); //A color similar to slate
				TF2Attrib_SetByDefIndex(hat, 261, 3100495.0);
			}
		case 2:
			{
				TF2Attrib_SetByDefIndex(hat, 142, 8208497.0); //A deep commitment to purple
				TF2Attrib_SetByDefIndex(hat, 261, 8208497.0);
			}
		case 3:
			{
				TF2Attrib_SetByDefIndex(hat, 142, 1315860.0); //A distinctive lack of hue
				TF2Attrib_SetByDefIndex(hat, 261, 1315860.0);
			}
		case 4:
			{
				TF2Attrib_SetByDefIndex(hat, 142, 12377523.0); //A mann's mint
				TF2Attrib_SetByDefIndex(hat, 261, 12377523.0);
			}
		case 5:
			{
				TF2Attrib_SetByDefIndex(hat, 142, 2960676.0); //After eight
				TF2Attrib_SetByDefIndex(hat, 261, 2960676.0);
			}
		case 6:
			{
				TF2Attrib_SetByDefIndex(hat, 142, 8289918.0); //Aged Moustache Grey
				TF2Attrib_SetByDefIndex(hat, 261, 8289918.0);
			}
		case 7:
			{
				TF2Attrib_SetByDefIndex(hat, 142, 15132390.0); //An Extraordinary abundance of tinge
				TF2Attrib_SetByDefIndex(hat, 261, 15132390.0);
			}
		case 8:
			{
				TF2Attrib_SetByDefIndex(hat, 142, 15185211.0); //Australium gold
				TF2Attrib_SetByDefIndex(hat, 261, 15185211.0);
			}
		case 9:
			{
				TF2Attrib_SetByDefIndex(hat, 142, 14204632.0); //Color no 216-190-216
				TF2Attrib_SetByDefIndex(hat, 261, 14204632.0);
			}
		case 10:
			{
				TF2Attrib_SetByDefIndex(hat, 142, 15308410.0); //Dark salmon injustice
				TF2Attrib_SetByDefIndex(hat, 261, 15308410.0);
			}
		case 11:
			{
				TF2Attrib_SetByDefIndex(hat, 142, 8421376.0); //Drably olive
				TF2Attrib_SetByDefIndex(hat, 261, 8421376.0);
			}
		case 12:
			{
				TF2Attrib_SetByDefIndex(hat, 142, 7511618.0); //Indubitably green
				TF2Attrib_SetByDefIndex(hat, 261, 7511618.0);
			}
		case 13:
			{
				TF2Attrib_SetByDefIndex(hat, 142, 13595446.0); //Mann co orange
				TF2Attrib_SetByDefIndex(hat, 261, 13595446.0);
			}
		case 14:
			{
				TF2Attrib_SetByDefIndex(hat, 142, 10843461.0); //Muskelmannbraun
				TF2Attrib_SetByDefIndex(hat, 261, 10843461.0);
			}
		case 15:
			{
				TF2Attrib_SetByDefIndex(hat, 142, 5322826.0); //Noble hatters violet
				TF2Attrib_SetByDefIndex(hat, 261, 5322826.0);
			}
		case 16:
			{
				TF2Attrib_SetByDefIndex(hat, 142, 12955537.0); //Peculiarly drab tincture
				TF2Attrib_SetByDefIndex(hat, 261, 12955537.0);
			}
		case 17:
			{
				TF2Attrib_SetByDefIndex(hat, 142, 16738740.0); //Pink as hell
				TF2Attrib_SetByDefIndex(hat, 261, 16738740.0);
			}
		case 18:
			{
				TF2Attrib_SetByDefIndex(hat, 142, 6901050.0); //Radigan conagher brown
				TF2Attrib_SetByDefIndex(hat, 261, 6901050.0);
			}
		case 19:
			{
				TF2Attrib_SetByDefIndex(hat, 142, 3329330.0); //A bitter taste of defeat and lime
				TF2Attrib_SetByDefIndex(hat, 261, 3329330.0);
			}
		case 20:
			{
				TF2Attrib_SetByDefIndex(hat, 142, 15787660.0); //The color of a gentlemanns business pants
				TF2Attrib_SetByDefIndex(hat, 261, 15787660.0);
			}
		case 21:
			{
				TF2Attrib_SetByDefIndex(hat, 142, 8154199.0); //Ye olde rustic colour
				TF2Attrib_SetByDefIndex(hat, 261, 8154199.0);
			}
		case 22:
			{
				TF2Attrib_SetByDefIndex(hat, 142, 4345659.0); //Zepheniahs greed
				TF2Attrib_SetByDefIndex(hat, 261, 4345659.0);
			}
		case 23:
			{
				TF2Attrib_SetByDefIndex(hat, 142, 6637376.0); //An air of debonair
				TF2Attrib_SetByDefIndex(hat, 261, 2636109.0);
			}
		case 24:
			{
				TF2Attrib_SetByDefIndex(hat, 142, 3874595.0); //Balaclavas are forever
				TF2Attrib_SetByDefIndex(hat, 261, 1581885.0);
			}
		case 25:
			{
				TF2Attrib_SetByDefIndex(hat, 142, 12807213.0); //Cream spirit
				TF2Attrib_SetByDefIndex(hat, 261, 12091445.0);
			}
		case 26:
			{
				TF2Attrib_SetByDefIndex(hat, 142, 4732984.0); //Operators overalls
				TF2Attrib_SetByDefIndex(hat, 261, 3686984.0);
			}
		case 27:
			{
				TF2Attrib_SetByDefIndex(hat, 142, 12073019.0); //Team spirit
				TF2Attrib_SetByDefIndex(hat, 261, 5801378.0);
			}
		case 28:
			{
				TF2Attrib_SetByDefIndex(hat, 142, 8400928.0); //The value of teamwork
				TF2Attrib_SetByDefIndex(hat, 261, 2452877.0);
			}
		case 29:
			{
				TF2Attrib_SetByDefIndex(hat, 142, 11049612.0); //Waterlogged lab coat
				TF2Attrib_SetByDefIndex(hat, 261, 8626083.0);
			}
		}
	}

	DispatchSpawn(hat);
	SDKCall(g_hWearableEquip, client, hat);
	return Plugin_Handled;
} 

Action CreateWeapon(int client, int itemindex, int quality = 0, int warpaint = 0)
{
	int slot = TF2Econ_GetItemDefaultLoadoutSlot(itemindex);
	TF2_RemoveWeaponSlot(client, slot);

	char classname[64];
	TF2Econ_GetItemClassName(itemindex, classname, sizeof(classname));
	TF2Econ_TranslateWeaponEntForClass(classname, sizeof(classname), TF2_GetPlayerClass(client));
	int level = GetRandomUInt(1, 100);
	int weapon = CreateEntityByName(classname);
	
	if (!IsValidEntity(weapon))
	{
		return Plugin_Handled;
	}
	
	char entclass[64];
	GetEntityNetClass(weapon, entclass, sizeof(entclass));
	SetEntData(weapon, FindSendPropInfo(entclass, "m_iItemDefinitionIndex"), itemindex);	 
	SetEntData(weapon, FindSendPropInfo(entclass, "m_bInitialized"), 1);
	SetEntData(weapon, FindSendPropInfo(entclass, "m_iEntityQuality"), quality);
	SetEntProp(weapon, Prop_Send, "m_bValidatedAttachedEntity", 1);
	
	if (level > 1)
	{
		SetEntData(weapon, FindSendPropInfo(entclass, "m_iEntityLevel"), level);
	}

	if (warpaint == 999)
	{
		warpaint = GetRandomUInt(200, 297);
		if(warpaint == 216 ||warpaint == 219 || warpaint == 222 || warpaint == 227 || warpaint == 229 || warpaint == 231 || warpaint == 233 || warpaint == 274 || warpaint == 288)
		{		
			warpaint = GetRandomUInt(300, 310);
		}
	}

	if (warpaint > 0)
	{
		TF2Attrib_SetByDefIndex(weapon, 834, view_as<float>(warpaint));	//Set Warpaint
	}
	
	switch (itemindex)
	{
	case 25, 26:
		{
			DispatchSpawn(weapon);
			EquipPlayerWeapon(client, weapon); 

			return Plugin_Handled; 			
		}
	case 735, 736, 810, 933, 1080, 1102:
		{
			SetEntProp(weapon, Prop_Send, "m_iObjectType", 3);
			SetEntProp(weapon, Prop_Data, "m_iSubType", 3);
			SetEntProp(weapon, Prop_Send, "m_aBuildableObjectTypes", 0, _, 0);
			SetEntProp(weapon, Prop_Send, "m_aBuildableObjectTypes", 0, _, 1);
			SetEntProp(weapon, Prop_Send, "m_aBuildableObjectTypes", 0, _, 2);
			SetEntProp(weapon, Prop_Send, "m_aBuildableObjectTypes", 1, _, 3);
		}	
	case 998:
		{
			SetEntProp(weapon, Prop_Send, "m_nChargeResistType", GetRandomUInt(0,2));
		}
	case 1071:
		{
			TF2Attrib_SetByName(weapon, "item style override", 0.0);
			TF2Attrib_SetByName(weapon, "loot rarity", 1.0);		
			TF2Attrib_SetByName(weapon, "turn to gold", 1.0);
			SetEntData(weapon, FindSendPropInfo(entclass, "m_iEntityQuality"), 11);		
			
			DispatchSpawn(weapon);
			EquipPlayerWeapon(client, weapon);
			
			return Plugin_Handled; 
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
		if(GetRandomUInt(1,15) == 1)
		{
			TF2Attrib_SetByDefIndex(weapon, 2053, 1.0);
		}
	}
	
	if(quality == 11)
	{
		if (GetRandomUInt(1,10) == 1)
		{
			TF2Attrib_SetByDefIndex(weapon, 2025, 1.0);
		}
		else if (GetRandomUInt(1,10) == 2)
		{
			TF2Attrib_SetByDefIndex(weapon, 2025, 2.0);
			TF2Attrib_SetByDefIndex(weapon, 2014, GetRandomUInt(1,7) + 0.0);
		}
		else if (GetRandomUInt(1,10) == 3)
		{
			TF2Attrib_SetByDefIndex(weapon, 2025, 3.0);
			TF2Attrib_SetByDefIndex(weapon, 2014, GetRandomUInt(1,7) + 0.0);
			TF2Attrib_SetByDefIndex(weapon, 2013, GetRandomUInt(2002,2008) + 0.0);
		}
		TF2Attrib_SetByDefIndex(weapon, 214, view_as<float>(GetRandomUInt(0, 9000)));
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
		SDKCall(g_hWearableEquip, client, weapon);
		CreateTimer(0.1, TimerHealth, client, TIMER_FLAG_NO_MAPCHANGE);
	}

	else
	{
		DispatchSpawn(weapon);
		EquipPlayerWeapon(client, weapon);
	}
	if (GetRandomUInt(1,20) == 1)
	{
		TF2Attrib_SetByName(weapon, "SPELL: Halloween death ghosts", 1.0);
	}
	if (GetRandomUInt(1,20) == 1)
	{
		if (itemindex == 21 || itemindex == 208 || itemindex == 40 || itemindex == 215 || itemindex == 594 || itemindex == 659 || itemindex == 741 || itemindex == 798 || itemindex == 807 || itemindex == 887 || itemindex == 896 || itemindex == 905 || itemindex == 914 || itemindex == 963 || itemindex == 972 || itemindex == 1146 || itemindex == 1178 || itemindex == 15005 || itemindex == 15017 || itemindex == 15030 || itemindex == 15034 || itemindex == 15049 || itemindex == 15054 || itemindex == 15066 || itemindex == 15067 || itemindex == 15068 || itemindex == 15089 || itemindex == 15090 || itemindex == 15115 || itemindex == 15141 || itemindex == 30474)
		{
			TF2Attrib_SetByName(weapon, "SPELL: Halloween green flames", 1.0);
		}
	}
	if (GetRandomUInt(1,20) == 1)
	{
		if (itemindex == 18 || itemindex == 205 || itemindex == 127 || itemindex == 228 || itemindex == 414 || itemindex == 513 || itemindex == 658 || itemindex == 730 || itemindex == 800 || itemindex == 809 || itemindex == 889 || itemindex == 898 || itemindex == 907 || itemindex == 916 || itemindex == 965 || itemindex == 974 || itemindex == 1085 || itemindex == 1104 || itemindex == 15006 || itemindex == 15014 || itemindex == 15028 || itemindex == 15043 || itemindex == 15052 || itemindex == 15057 || itemindex == 15081 || itemindex == 15104 || itemindex == 15105 || itemindex == 15129 || itemindex == 15130 || itemindex == 15150 || itemindex == 19 || itemindex == 206 || itemindex == 308 || itemindex == 996 || itemindex == 1007 || itemindex == 1151 || itemindex == 15077 || itemindex == 15079 || itemindex == 15091 || itemindex == 15092 || itemindex == 15116 || itemindex == 15117 || itemindex == 15142 || itemindex == 15158 || itemindex == 20 || itemindex == 207 || itemindex == 130 || itemindex == 661 || itemindex == 797 || itemindex == 806 || itemindex == 886 || itemindex == 895 || itemindex == 904 || itemindex == 913 || itemindex == 962 || itemindex == 971 || itemindex == 1150 || itemindex == 15009 || itemindex == 15012 || itemindex == 15024 || itemindex == 15038 || itemindex == 15045 || itemindex == 15048 || itemindex == 15082 || itemindex == 15083 || itemindex == 15084 || itemindex == 15113 || itemindex == 15137 || itemindex == 15138 || itemindex == 15155 || itemindex == 7 || itemindex == 197 || itemindex == 155 || itemindex == 169 || itemindex == 329 || itemindex == 423 || itemindex == 589 || itemindex == 662 || itemindex == 795 || itemindex == 804 || itemindex == 884 || itemindex == 893 || itemindex == 902 || itemindex == 911 || itemindex == 960 || itemindex == 969 || itemindex == 1071 || itemindex == 1123 || itemindex == 15073 || itemindex == 15074 || itemindex == 15075 || itemindex == 15139 || itemindex == 15140 || itemindex == 15114 || itemindex == 15156 || itemindex == 30758)
		{
			TF2Attrib_SetByName(weapon, "SPELL: Halloween pumpkin explosions", 1.0);
		}
	}

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
		if (quality == 5 && slot == 0)
		{
			TF2_SwitchtoSlot(client, 0);
			SetEntData(weapon, FindSendPropInfo(entclass, "m_iEntityQuality"), 5);			
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
		if (quality == 5 && slot == 1)
		{
			TF2_SwitchtoSlot(client, 1);
			SetEntData(weapon, FindSendPropInfo(entclass, "m_iEntityQuality"), 5);						
			int iRand2 = GetRandomUInt(1,4);
			if (iRand2 == 1)
			{
				TF2Attrib_SetByDefIndex(weapon, 134, 701.0);	
			}
			else if (iRand2 == 2)
			{
				TF2Attrib_SetByDefIndex(weapon, 134, 702.0);	
			}	
			else if (iRand2 == 3)
			{
				TF2Attrib_SetByDefIndex(weapon, 134, 703.0);	
			}
			else if (iRand2 == 4)
			{
				TF2Attrib_SetByDefIndex(weapon, 134, 704.0);	
			}				
		}
	}
	TF2_SwitchtoSlot(client, 0);
	return Plugin_Handled;
}

int GetRandomUInt(int min, int max)
{
	return RoundToFloor(GetURandomFloat() * (max - min + 1)) + min;
}  

Action TimerHealth(Handle timer, any client)
{
	int hp = GetPlayerMaxHp(client);
	
	if (hp > 0)
	{
		SetEntityHealth(client, hp);
	}
	return Plugin_Handled;
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

stock void RemoveAllWearables(int client)
{
	int edict = MaxClients+1;
	while((edict = FindEntityByClassname(edict, "tf_wearable")) != -1)
	{
		char netclass[32];
		if (GetEntityNetClass(edict, netclass, sizeof(netclass)) && StrEqual(netclass, "CTFWearable"))
		{
			if (GetEntPropEnt(edict, Prop_Send, "m_hOwnerEntity") == client && !GetEntProp(edict, Prop_Send, "m_bDisguiseWearable"))
			{
				AcceptEntityInput(edict, "Kill");
			}
		}
	}
}

stock void TF2_SwitchtoSlot(int client, int slot)
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

stock void ResetClass(int client)
{
	g_bSpecialBot[client] = true;

	TF2Attrib_RemoveAll(client);
	int Weapon = GetPlayerWeaponSlot(client, TFWeaponSlot_Primary);
	if(IsValidEntity(Weapon))
	{
		TF2Attrib_RemoveAll(Weapon);
	}
	int Weapon2 = GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary);
	if(IsValidEntity(Weapon2))
	{
		TF2Attrib_RemoveAll(Weapon2);
	}
	int Weapon3 = GetPlayerWeaponSlot(client, TFWeaponSlot_Melee);
	if(IsValidEntity(Weapon3))
	{
		TF2Attrib_RemoveAll(Weapon3);
	}
	int Weapon4 = GetPlayerWeaponSlot(client, TFWeaponSlot_PDA);
	if(IsValidEntity(Weapon4))
	{
		TF2Attrib_RemoveAll(Weapon4);
	}
	//SetEntProp(client, Prop_Send, "m_iHealth", 125, 1);			
	//TF2_RegeneratePlayer(client);	
	
	int iMaxHealth = (TF2_GetPlayerMaxHealth, client);
	TF2_SetHealth(client, iMaxHealth);
	
	CreateTimer(0.01, TimerHealth, client, TIMER_FLAG_NO_MAPCHANGE);
}

stock int TF2_GetPlayerMaxHealth(int client) {
	return GetEntProp(GetPlayerResourceEntity(), Prop_Send, "m_iMaxHealth", _, client);
}

stock void TF2_SetHealth(int client, int NewHealth)
{
	SetEntProp(client, Prop_Send, "m_iHealth", NewHealth, 1);
	SetEntProp(client, Prop_Data, "m_iHealth", NewHealth, 1);
}

stock bool IsValidClient(int client)
{
	if (client <= 0) return false;
	if (client > MaxClients) return false;
	return IsClientInGame(client);
}