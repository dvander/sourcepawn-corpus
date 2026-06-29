#include <sourcemod>
#include <sdktools>

#pragma semicolon 1
#pragma newdecls required

static bool bThirdPerson[MAXPLAYERS+1];

static const char SOUND_AUTOSHOTGUN[] 		= "^weapons/auto_shotgun/gunfire/auto_shotgun_fire_1.wav";
static const char SOUND_SPASSHOTGUN[] 		= "weapons/auto_shotgun_spas/gunfire/shotgun_fire_1.wav";
static const char SOUND_PUMPSHOTGUN[] 		= "^weapons/shotgun/gunfire/shotgun_fire_1.wav";
static const char SOUND_CHROMESHOTGUN[] 	= "weapons/shotgun_chrome/gunfire/shotgun_fire_1.wav";

public Plugin myinfo =
{
    name = "[L4D/L4D2] Thirdpersonshoulder Shotgun Sound Fix",
    author = "MasterMind420, Lux",
    description = "Thirdpersonshoulder Shotgun Sound Fix",
    version = "1.0",
    url = ""
}

public void OnPluginStart()
{
	HookEvent("weapon_fire", Event_WeaponFire, EventHookMode_Pre);
}

public void OnMapStart()
{
	PrefetchSound(SOUND_AUTOSHOTGUN);
	PrecacheSound(SOUND_AUTOSHOTGUN, true);

	PrefetchSound(SOUND_SPASSHOTGUN);
	PrecacheSound(SOUND_SPASSHOTGUN, true);

	PrefetchSound(SOUND_CHROMESHOTGUN);
	PrecacheSound(SOUND_CHROMESHOTGUN, true);

	PrefetchSound(SOUND_PUMPSHOTGUN);
	PrecacheSound(SOUND_PUMPSHOTGUN, true);

/*
	PrefetchSound("AutoShotgun.Fire");
	PrecacheSound("AutoShotgun.Fire", true);

	PrefetchSound("AutoShotgun.FireIncendiary");
	PrecacheSound("AutoShotgun.FireIncendiary", true);

	PrefetchSound("AutoShotgun_Spas.Fire");
	PrecacheSound("AutoShotgun_Spas.Fire", true);

	PrefetchSound("AutoShotgun_Spas.FireIncendiary");
	PrecacheSound("AutoShotgun_Spas.FireIncendiary", true);

	PrefetchSound("Shotgun_Chrome.Fire");
	PrecacheSound("Shotgun_Chrome.Fire", true);

	PrefetchSound("Shotgun_Chrome.FireIncendiary");
	PrecacheSound("Shotgun_Chrome.FireIncendiary", true);

	PrefetchSound("Shotgun.Fire");
	PrecacheSound("Shotgun.Fire", true);

	PrefetchSound("Shotgun.FireIncendiary");
	PrecacheSound("Shotgun.FireIncendiary", true);
*/
}

public void Event_WeaponFire(Handle event, const char[] name, bool dontBroadcast)
{
	static int client;
	client = GetClientOfUserId(GetEventInt(event, "userid"));

	if (!IsValidClient(client) || !IsClientInGame(client))
		return;

	if(!bThirdPerson[client]) //if(!IsSurvivorThirdPerson(client))
		return;

	if(!IsPlayerAlive(client) || GetClientTeam(client) != 2)
		return;

	static int weapon;
	weapon = GetPlayerWeaponSlot(client, 0);

	if(!IsValidEntity(weapon))
		return;

	static char sWeapon[16];
	GetEventString(event, "weapon", sWeapon, sizeof(sWeapon));

	if(sWeapon[0] != 'a' && sWeapon[0] != 's' && sWeapon[0] != 'p')
		return;

	if (StrEqual(sWeapon, "autoshotgun"))
	{
		//if(GetEntProp(weapon, Prop_Send, "m_nUpgradedPrimaryAmmoLoaded") == 1)
		//	EmitGameSoundToClient(client, "AutoShotgun.FireIncendiary", SOUND_FROM_PLAYER, SND_NOFLAGS);
		//else
		EmitGameSoundToClient(client, SOUND_AUTOSHOTGUN, SOUND_FROM_PLAYER, SND_NOFLAGS);
	}
	else if (StrEqual(sWeapon, "shotgun_spas"))
	{
		//if(GetEntProp(weapon, Prop_Send, "m_nUpgradedPrimaryAmmoLoaded") == 1)
		//	EmitGameSoundToClient(client, "AutoShotgun_Spas.FireIncendiary", SOUND_FROM_PLAYER, SND_NOFLAGS);
		//else
		EmitGameSoundToClient(client, SOUND_SPASSHOTGUN, SOUND_FROM_PLAYER, SND_NOFLAGS);
	}
	else if (StrEqual(sWeapon, "pumpshotgun"))
	{
		//if(GetEntProp(weapon, Prop_Send, "m_nUpgradedPrimaryAmmoLoaded") == 1)
		//	EmitGameSoundToClient(client, "Shotgun.FireIncendiary", SOUND_FROM_PLAYER, SND_NOFLAGS);
		//else
		EmitGameSoundToClient(client, SOUND_PUMPSHOTGUN, SOUND_FROM_PLAYER, SND_NOFLAGS);
	}
	else if (StrEqual(sWeapon, "shotgun_chrome"))
	{
		//if(GetEntProp(weapon, Prop_Send, "m_nUpgradedPrimaryAmmoLoaded") == 1)
		//	EmitGameSoundToClient(client, "Shotgun_Chrome.FireIncendiary", SOUND_FROM_PLAYER, SND_NOFLAGS);
		//else
		EmitGameSoundToClient(client, SOUND_CHROMESHOTGUN, SOUND_FROM_PLAYER, SND_NOFLAGS);
	}
}

public void TP_OnThirdPersonChanged(int iClient, bool bIsThirdPerson)
{
	bThirdPerson[iClient] = bIsThirdPerson;
}

static bool IsSurvivorThirdPerson(int iClient)
{
	if(bThirdPerson[iClient])
		return true;
	if(GetEntPropEnt(iClient, Prop_Send, "m_hViewEntity") > 0)
		return true;
	if(GetEntPropFloat(iClient, Prop_Send, "m_TimeForceExternalView") > GetGameTime())
		return true;
	if(GetEntProp(iClient, Prop_Send, "m_iObserverMode") == 1)
		return true;
	if(GetEntPropEnt(iClient, Prop_Send, "m_pummelAttacker") > 0)
		return true;
	if(GetEntPropEnt(iClient, Prop_Send, "m_carryAttacker") > 0)
		return true;
	if(GetEntPropEnt(iClient, Prop_Send, "m_pounceAttacker") > 0)
		return true;
	if(GetEntPropEnt(iClient, Prop_Send, "m_jockeyAttacker") > 0)
		return true; 
	if(GetEntProp(iClient, Prop_Send, "m_isHangingFromLedge") > 0)
		return true;
	if(GetEntPropEnt(iClient, Prop_Send, "m_reviveTarget") > 0)
		return true;
	if(GetEntPropFloat(iClient, Prop_Send, "m_staggerTimer", 1) > -1.0)
		return true;

	switch(GetEntProp(iClient, Prop_Send, "m_iCurrentUseAction"))
	{
		case 1:
		{
			static int iTarget;
			iTarget = GetEntPropEnt(iClient, Prop_Send, "m_useActionTarget");
			
			if(iTarget == GetEntPropEnt(iClient, Prop_Send, "m_useActionOwner"))
				return true;
			else if(iTarget != iClient)
				return true;
		}
		case 4, 6, 7, 8, 9, 10:
			return true;
	}

	static char sModel[31];
	GetEntPropString(iClient, Prop_Data, "m_ModelName", sModel, sizeof(sModel));

	switch(sModel[29])
	{
		case 'b'://nick
		{
			switch(GetEntProp(iClient, Prop_Send, "m_nSequence"))
			{
				case 626, 625, 624, 623, 622, 621, 661, 662, 664, 665, 666, 667, 668, 670, 671, 672, 673, 674, 620, 680, 616:
					return true;
			}
		}
		case 'd'://rochelle
		{
			switch(GetEntProp(iClient, Prop_Send, "m_nSequence"))
			{
				case 674, 678, 679, 630, 631, 632, 633, 634, 668, 677, 681, 680, 676, 675, 673, 672, 671, 670, 687, 629, 625, 616:
					return true;
			}
		}
		case 'c'://coach
		{
			switch(GetEntProp(iClient, Prop_Send, "m_nSequence"))
			{
				case 656, 622, 623, 624, 625, 626, 663, 662, 661, 660, 659, 658, 657, 654, 653, 652, 651, 621, 620, 669, 615:
					return true;
			}
		}
		case 'h'://ellis
		{
			switch(GetEntProp(iClient, Prop_Send, "m_nSequence"))
			{
				case 625, 675, 626, 627, 628, 629, 630, 631, 678, 677, 676, 575, 674, 673, 672, 671, 670, 669, 668, 667, 666, 665, 684, 621:
					return true;
			}
		}
		case 'v'://bill
		{
			switch(GetEntProp(iClient, Prop_Send, "m_nSequence"))
			{
				case 528, 759, 763, 764, 529, 530, 531, 532, 533, 534, 753, 676, 675, 761, 758, 757, 756, 755, 754, 527, 772, 762, 522:
					return true;
			}
		}
		case 'n'://zoey
		{
			switch(GetEntProp(iClient, Prop_Send, "m_nSequence"))
			{
				case 537, 819, 823, 824, 538, 539, 540, 541, 542, 543, 813, 828, 825, 822, 821, 820, 818, 817, 816, 815, 814, 536, 809, 572:
					return true;
			}
		}
		case 'e'://francis
		{
			switch(GetEntProp(iClient, Prop_Send, "m_nSequence"))
			{
				case 532, 533, 534, 535, 536, 537, 769, 768, 767, 766, 765, 764, 763, 762, 761, 760, 759, 758, 757, 756, 531, 530, 775, 525:
					return true;
			}
		}
		case 'a'://louis
		{
			switch(GetEntProp(iClient, Prop_Send, "m_nSequence"))
			{
				case 529, 530, 531, 532, 533, 534, 766, 765, 764, 763, 762, 761, 760, 759, 758, 757, 756, 755, 754, 753, 527, 772, 528, 522:
					return true;
			}
		}
		case 'w'://adawong
		{
			switch(GetEntProp(iClient, Prop_Send, "m_nSequence"))
			{
			case 674, 678, 679, 630, 631, 632, 633, 634, 668, 677, 681, 680, 676, 675, 673, 672, 671, 670, 687, 629, 625:
					return true;
			}
		}
	}

	return false;
}

stock bool IsValidClient(int iClient)
{
	if (iClient > 0 && iClient <= MaxClients && IsClientInGame(iClient))
		return true;
	return false;
}