/*

	// charge_summon_minions
	
	"abilityX"
	{
		"name"	"charge_summon_minions"
		"arg0"	"1" // 1: Primary, 2: Alternate
		"arg1"	"1.5"	// Charge Time
		"arg2"	"8.0"	// Cooldown
		"arg3"	"0.0"	// RAGE cost		
			// HUD
		"arg4"	"Summoning is %i percent ready!"	 // Charge percentage status (leave blank to use default)
		"arg5"	"Summoning will be ready in %i seconds!"		// Charge cooldown status (leave blank to use default)
		"arg6"	"SUPER DUPER jump is ready!"			  // Super-Duper Jump status (leave blank to use default)
		"arg7"	"Summoning is READY! Press RELOAD to use!"   
		"arg8"		"1"			// Sound
		"arg9"		"2"			// Summon per rage (specify amount for fixed amount, 0 to summon 1 per alive player, -1 to summon by ratio)
		"arg10"		"0.0"			// Ratio, if arg2 is -1		
			// Minion Type
		"arg11"	"0"	// Model Mode (0 = Human or Custom model, 1 = Robot Model (automatically applies robot voice lines), 2 = Look like a boss)
		"arg12"	"models/props_teaser/saucer.mdl"	// Leave blank for human model, or specify model path for custom model (not used if arg9 is set to 1)		
		"arg13" "9"	// Player class, leave blank to not change minion class		
		"arg14"	"1"	// Remove wearables? (for custom models / tf2 robot models)
		"arg15"	"-1"	// Voice Line mode (-1: Block voice lines, 0: Normal voice lines, 1: Robot Voice lines, 2: Giant Voice Lines, 3: boss's catchphrase, 4: use 'sound_minion_catchphrase')
		"arg16"	"0"	// Pickups (0 = None, 1 = Health, 2 = Ammo, 3 = Both)
		"arg17"	"1"	// Teleport to summoner's location?	
		"arg18"	"1.5"	// Scale
		"arg19"	"0.2"	// Gravity
		"arg20"	"fly"	// Movetype
		"arg21"	"255 ; 255 ; 255 ; 255"	// Player color (R ; G ; B ; Alpha) UNTESTED		
		"arg22"	"33 ; 4.0"	// Spawn Conditions
		"arg23"	"(((160+n)*n)^1.0341)+500"	// Health formula
		"arg24"	"1"	// Health Type (0: Overheal, 1: Non-Overheal)
		"arg25"	"1"	// 0 - slay minions when their summoner dies, 1 - don't slay minions when their summoner dies and instead give minions a fighting chance to win		
			// Notifications
		"arg26"	"1"	// Notification Alert (0: Disable, 1: Boss, 2: Minions, 3: Mercs, 4: Boss+Mercs, 5: Boss+Minions, 6: Mercs+Minions, 7: Everyone)
		"arg27"	"1"	// Notification Type (0: Hint Text, 1: Center Text, 2: HUD Text, 3: TF2-style HUD Text, 4: TF2-Style Annotation)
		"arg28"	""	// Minion Notification
		"arg29"	""	// Boss Notification
		"arg30"	""	// Merc Notification
			// Restrictions
		"arg31"	"0"	// Restrict new minions to only spawn if alive minions are equal or under the max allowed
		"arg32"	"0"	// Restriction: Maximum amount of alive minions when new minions can spawn	
			// Minion Particle Effects
		"arg33"	""	// Particle Type
		"arg34"	""	// Duration
		"arg35"	""	// Follow?
			// Weapons
		"arg36"	"1"	// Weapon mode (0 to allow minions to spawn with regular loadouts, 1 for specific weapons, 2 for no weapons)
		"arg37"	"5"	// If arg26 is set to 1, how many random custom weapon sets? (max is 9 sets)
			// Weapon Set (up to 9 sets)
		"arg100"	"5"	// Items in this loadout? (Max of 10)
			// Loadout (up to 10 items per loadout)
		"arg101"	"tf_weapon_drg_pomson"	// Weapon Classname
		"arg102"	"588"	// Index
		"arg103"	"281 ; 1 ; 283 ; 1 ; 285 ; 1 ; 337 ; 25 ; 338 ; 25 ; 339 ; 1; 340 ; 1 ; 2 ; 5"	// Attributes (if arg10 = 1)
		"arg104"	"0"	// Ammo
		"arg105"	"5"	// Clip
		"arg106"	"models/freak_fortress_2/heavy/gun.mdl"	// Custom Weapon Worldmodel
		"arg107"	"0 ; 255 ; 0 ; 10"	// Weapon color (R ; G ; B ; Alpha) UNTESTED
		"arg108"	"0"	// Visible?
		"arg109"	"1.0"	// Custom Weapon Scale
		"buttonmode"	"0"	// Button Mode
		"plugin_name"	"ff2_salmon"
	
	}		
	
	// summon_minions
	"abilityX"
	{
		// IF SLOT IS 0 OR -1
		"name"	"summon_minions"
		"arg0"		"0"			// 0: RAGE, -1: Life Loss
		"arg1"		"1"			// Sound
		"arg2"		"2"			// Summon per rage (specify amount for fixed amount, 0 to summon 1 per alive player, -1 to summon by ratio)
		"arg3"		"0.0"			// Ratio, if arg2 is -1		
			// Minion Type
		"arg4"	"0"	// Model Mode (0 = Human or Custom model, 1 = Robot Model (automatically applies robot voice lines), 2 = Look like a boss)
		"arg5"	"models/props_teaser/saucer.mdl"	// Leave blank for human model, or specify model path for custom model (not used if arg9 is set to 1)		
		"arg6" "9"	// Player class, leave blank to not change minion class		
		"arg7"	"1"	// Remove wearables? (for custom models / tf2 robot models)
		"arg8"	"-1"	// Voice Line mode (-1: Block voice lines, 0: Normal voice lines, 1: Robot Voice lines, 2: Giant Voice Lines, 3: boss's catchphrase, 4: use 'sound_minion_catchphrase')
		"arg9"	"0"	// Pickups (0 = None, 1 = Health, 2 = Ammo, 3 = Both)
		"arg10"	"1"	// Teleport to summoner's location?	
		"arg11"	"1.5"	// Scale
		"arg12"	"0.2"	// Gravity
		"arg13"	"fly"	// Movetype
		"arg14"	"255 ; 255 ; 255 ; 255"	// Player color (R ; G ; B ; Alpha) UNTESTED		
		"arg15"	"33 ; 4.0"	// Spawn Conditions
		"arg16"	"(((160+n)*n)^1.0341)+500"	// Health formula
		"arg17"	"1"	// Health Type (0: Overheal, 1: Non-Overheal)
		"arg18"	"1"	// 0 - slay minions when their summoner dies, 1 - don't slay minions when their summoner dies and instead give minions a fighting chance to win		
			// Notifications
		"arg19"	"1"	// Notification Alert (0: Disable, 1: Boss, 2: Minions, 3: Mercs, 4: Boss+Mercs, 5: Boss+Minions, 6: Mercs+Minions, 7: Everyone)
		"arg20"	"1"	// Notification Type (0: Hint Text, 1: Center Text, 2: HUD Text, 3: TF2-style HUD Text, 4: TF2-Style Annotation)
		"arg21"	""	// Minion Notification
		"arg22"	""	// Boss Notification
		"arg23"	""	// Merc Notification
			// Restrictions
		"arg24"	"0"	// Restrict new minions to only spawn if alive minions are equal or under the max allowed
		"arg25"	"0"	// Restriction: Maximum amount of alive minions when new minions can spawn	
			// Minion Particle Effects
		"arg26"	""	// Particle Type
		"arg27"	""	// Duration
		"arg28"	""	// Follow?
			// Weapons
		"arg29"	"1"	// Weapon mode (0 to allow minions to spawn with regular loadouts, 1 for specific weapons, 2 for no weapons)
		"arg30"	"5"	// If arg26 is set to 1, how many random custom weapon sets? (max is 9 sets)
			// Weapon Set (up to 9 sets)
		"arg100"	"5"	// Items in this loadout? (Max of 10)
			// Loadout (up to 10 items per loadout)
		"arg101"	"tf_weapon_drg_pomson"	// Weapon Classname
		"arg102"	"588"	// Index
		"arg103"	"281 ; 1 ; 283 ; 1 ; 285 ; 1 ; 337 ; 25 ; 338 ; 25 ; 339 ; 1; 340 ; 1 ; 2 ; 5"	// Attributes (if arg10 = 1)
		"arg104"	"0"	// Ammo
		"arg105"	"5"	// Clip
		"arg106"	"models/freak_fortress_2/heavy/gun.mdl"	// Custom Weapon Worldmodel
		"arg107"	"0 ; 255 ; 0 ; 10"	// Weapon color (R ; G ; B ; Alpha) UNTESTED
		"arg108"	"0"	// Visible?
		"arg109"	"1.0"	// Custom Weapon Scale
			// Ability Management System
		"arg1001"	"0.0" // delay before first use
		"arg1002"	"10.0" // cooldown
		"arg1003"	"Summon" // name
		"arg1004"	"Spawn minions" // description
		"arg1005"	"25" // rage cost
		"arg1006"	"1" // index for ability in the AMS menu
		"plugin_name"	"ff2_salmon"
	}
*/

#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <tf2items>
#include <adt_array>
#include <tf2_stocks>
#include <ff2_ams>
#include <freak_fortress_2>
#include <freak_fortress_2_subplugin>
#tryinclude <freak_fortress_2_extras>

#pragma newdecls required

#define MANN_SND "ambient/siren.wav"
#define RSALMON "summon_minions"
#define CSALMON "charge_summon_minions"

enum FF2BossType
{
	FF2BossType_NotABoss=-1,
	FF2BossType_IsBoss,
	FF2BossType_IsCompanion,
	FF2BossType_IsMinion
}

enum Operators
{
	Operator_None=0,
	Operator_Add,
	Operator_Subtract,
	Operator_Multiply,
	Operator_Divide,
	Operator_Exponent,
};

enum VoiceMode
{
	VoiceMode_None=-1,
	VoiceMode_Normal,
	VoiceMode_Robot,
	VoiceMode_GiantRobot,
	VoiceMode_BossCatchPhrase,
	VoiceMode_CatchPhrase,
	VoiceMode_RandomBossCatchPhrase,
}

#define MAJOR_REVISION "0"
#define MINOR_REVISION "5"
#define PATCH_REVISION "0"

#if !defined PATCH_REVISION
	#define PLUGIN_VERSION MAJOR_REVISION..."."...MINOR_REVISION
#else
	#define PLUGIN_VERSION MAJOR_REVISION..."."...MINOR_REVISION..."."...PATCH_REVISION
#endif

// Charge Stuff
Handle jumpHUD;
bool bEnableSuperDuperJump[MAXPLAYERS+1];

// Salmon System / VO Tweaks
bool DontSlay[MAXPLAYERS+1];
bool minRestrict[MAXPLAYERS+1][2];
int minToSpawn[MAXPLAYERS+1][2];
Handle MinionKV[MAXPLAYERS+1]=null;
int SummonerIndex[MAXPLAYERS+1];
VoiceMode VOMode[MAXPLAYERS+1];
MoveType mMoveType[MAXPLAYERS+1];
int minionMaxHP[MAXPLAYERS+1];
bool HookHealth[MAXPLAYERS+1]=false;
int pParticleEnt[MAXPLAYERS+1]=-1;

// AMS
bool AMSOnly[MAXPLAYERS+1];
// Hitboxes
bool isHitBoxAvailable=false;

public Plugin myinfo = {
	name = "Freak Fortress 2: Salmon Summon System",
	author = "Koishi (SHADoW NiNE TR3S)",
	description="Minion Summon System",
	version=PLUGIN_VERSION,
};

public void OnPluginStart2()
{
	int version[3];
	FF2_GetFF2Version(version);
	if(version[0]==1 && (version[1]<10 || (version[1]==10 && version[2]<3)))
	{
		SetFailState("This subplugin (ff2_salmon) requires at least FF2 v1.10.3!");
	}
	HookEvent("arena_round_start", Event_RoundStart, EventHookMode_Pre);
	HookEvent("arena_win_panel", Event_RoundEnd, EventHookMode_Pre);
	HookEvent("player_death", Event_PlayerDeath, EventHookMode_PostNoCopy);
	AddNormalSoundHook(SoundHook);
	
	// Notification Sounds
	PrecacheSound(MANN_SND,true);
	
	// HUD
	jumpHUD = CreateHudSynchronizer();
	
	// Ugh, y u no precache?
	PrecacheSound("mvm/giant_common/giant_common_step_01.wav", true);
	PrecacheSound("mvm/giant_common/giant_common_step_02.wav", true);
	PrecacheSound("mvm/giant_common/giant_common_step_03.wav", true);
	PrecacheSound("mvm/giant_common/giant_common_step_04.wav", true);
	PrecacheSound("mvm/giant_common/giant_common_step_05.wav", true);
	PrecacheSound("mvm/giant_common/giant_common_step_06.wav", true);
	PrecacheSound("mvm/giant_common/giant_common_step_07.wav", true);
	PrecacheSound("mvm/giant_common/giant_common_step_08.wav", true);
	
	isHitBoxAvailable=((FindSendPropInfo("CBasePlayer", "m_vecSpecifiedSurroundingMins") != -1) && FindSendPropInfo("CBasePlayer", "m_vecSpecifiedSurroundingMaxs") != -1);
	
	if(FF2_GetRoundState()==1)
	{
		PrepareAbilities();
	}
}

public void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	PrepareAbilities();
}

public void Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	for(int client=MaxClients; client; client--)
	{
		if(IsClientValid(client))
		{
			ResetSalmonSettings(client);
		}
	}
}

public void PrepareAbilities()
{
    for(int client=MaxClients;client;client--)
    {
        if(!IsClientValid(client))
            continue;
        ResetSalmonSettings(client);
        int boss=FF2_GetBossIndex(client);
        if(boss>=0)
        {
            // Initialize if using AMS for these abilities
            if(FF2_HasAbility(boss, this_plugin_name, RSALMON))
            {
                minRestrict[client][1]=view_as<bool>(FF2_GetAbilityArgument(boss,this_plugin_name,RSALMON, 24));
                minToSpawn[client][1]=FF2_GetAbilityArgument(boss,this_plugin_name,RSALMON, 25);
                AMSOnly[client]=AMS_IsSubabilityReady(boss, this_plugin_name, RSALMON);
                if(AMSOnly[client])
                {
                    AMS_InitSubability(boss, client, this_plugin_name, RSALMON, "SMN");
                }
            }    
        }
        
    }
}

public void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	int client=GetClientOfUserId(GetEventInt(event, "userid"));
	int boss=FF2_GetBossIndex(client); // Boss is an attacker
	
	if((GetEventInt(event, "death_flags") & TF_DEATHFLAG_DEADRINGER))
	{
		return;
	}
	
	if(TF2_GetClientTeam(client)==view_as<TFTeam>(FF2_GetBossTeam()) && SummonerIndex[client]==boss)
	{
		ResetSalmonSettings(client);
		TF2_ChangeClientTeam(client, (view_as<TFTeam>(FF2_GetBossTeam())==TFTeam_Blue) ? (TFTeam_Red) : (TFTeam_Blue));
	}
	
	if(boss != -1 && (FF2_HasAbility(boss, this_plugin_name, RSALMON) || FF2_HasAbility(boss, this_plugin_name, CSALMON)))
	{
		for(int clone=MaxClients; clone; clone--)
		{
			if(SummonerIndex[clone]==boss && IsClientValid(clone, true) && !DontSlay[clone])
			{
				ResetSalmonSettings(clone);
				TF2_ChangeClientTeam(clone, (view_as<TFTeam>(FF2_GetBossTeam())==TFTeam_Blue) ? (TFTeam_Red) : (TFTeam_Blue));
			}
		}
	}
}


public void PrepareSalmon(int boss, int client, const char[] ability_name, int arg1, int arg2, int arg3, int arg4, int arg5, int arg6, int arg7, int arg8, int arg9, int arg10, int arg11, int arg12, int arg13, int arg14, int arg15, int arg16, int arg17, int arg18, int arg19, int arg20, int arg21, int arg22, int arg23, int arg24, int arg25, int arg26, int arg27, int arg28)
{
	char pConds[768], model[PLATFORM_MAX_PATH], summoner[256], summoned[256], merc[256], pHealth[768], moveType[10], pColor[32], pParticle[128];

	bool sound=view_as<bool>(FF2_GetAbilityArgument(boss,this_plugin_name,ability_name, arg1));							// Sound
	int qty=FF2_GetAbilityArgument(boss,this_plugin_name,ability_name, arg2); 											// Minions Spawned?
	float ratio=FF2_GetAbilityArgumentFloat(boss, this_plugin_name, ability_name, arg3, 0.0);							// Ratio
	int modeltype=FF2_GetAbilityArgument(boss,this_plugin_name,ability_name, arg4);										// Model Mode?
	FF2_GetAbilityArgumentString(boss, this_plugin_name, ability_name, arg5, model, sizeof(model));						// Custom Model Path?
	TFClassType playerClass=view_as<TFClassType>(FF2_GetAbilityArgument(boss, this_plugin_name, ability_name, arg6));	// Class override?
	bool stripWearables=view_as<bool>(FF2_GetAbilityArgument(boss, this_plugin_name, ability_name, arg7));				// Remove Wearables?
	int vline=FF2_GetAbilityArgument(boss, this_plugin_name, ability_name, arg8);										// Voice Line Mode
	int pickups=FF2_GetAbilityArgument(boss, this_plugin_name, ability_name, arg9);										// Pickups?
	bool teletoboss=view_as<bool>(FF2_GetAbilityArgument(boss, this_plugin_name, ability_name, arg10));					// Teleport to summoner's location?
	float scale=FF2_GetAbilityArgumentFloat(boss, this_plugin_name, ability_name, arg11);								// Minion scale
	float gravity=FF2_GetAbilityArgumentFloat(boss, this_plugin_name, ability_name, arg12);								// Gravity	
	FF2_GetAbilityArgumentString(boss, this_plugin_name, ability_name, arg13, moveType, sizeof(moveType));				// Movetype
	FF2_GetAbilityArgumentString(boss, this_plugin_name, ability_name, arg14, pColor, sizeof(pColor));					// Player RBG + Alpha
	FF2_GetAbilityArgumentString(boss, this_plugin_name, ability_name, arg15, pConds, sizeof(pConds));					// Spawn conditions
	FF2_GetAbilityArgumentString(boss, this_plugin_name, ability_name, arg16, pHealth, sizeof(pHealth));				// Health
	bool disableOverHeal=view_as<bool>(FF2_GetAbilityArgument(boss,this_plugin_name,ability_name, arg17));				// Disable hp being overheal?
	bool noslayminions=view_as<bool>(FF2_GetAbilityArgument(boss,this_plugin_name,ability_name, arg18));				// Slay minions if owner dies?
	bool notify=view_as<bool>(FF2_GetAbilityArgument(boss,this_plugin_name,ability_name, arg19));						// Notifications?
	int notifyType=FF2_GetAbilityArgument(boss,this_plugin_name,ability_name, arg20);									// Notification Type
	FF2_GetAbilityArgumentString(boss, this_plugin_name, ability_name, arg21, summoned, sizeof(summoned));				// Text to show to summoned
	FF2_GetAbilityArgumentString(boss, this_plugin_name, ability_name, arg22, summoner, sizeof(summoner));				// Text to show to summoner
	FF2_GetAbilityArgumentString(boss, this_plugin_name, ability_name, arg23, merc, sizeof(merc));						// Text to show to non-minions
	FF2_GetAbilityArgumentString(boss, this_plugin_name, ability_name, arg24, pParticle, sizeof(pParticle));			// Particle Effect
	float pDuration=FF2_GetAbilityArgumentFloat(boss, this_plugin_name, ability_name, arg25, 0.0);						// Particle duration
	bool follow=view_as<bool>(FF2_GetAbilityArgument(boss, this_plugin_name, ability_name, arg26));						// Particle follows minion?
	int wepmode=FF2_GetAbilityArgument(boss, this_plugin_name, ability_name, arg27);									// Weapon Mode
	int wepset=FF2_GetAbilityArgument(boss, this_plugin_name, ability_name, arg28);										// Weapon Sets
	
	
	Salmon(boss, client, ability_name, sound, qty, ratio, modeltype, model, playerClass, stripWearables, vline, pickups, teletoboss, scale, gravity, moveType, pColor, pConds, pHealth, disableOverHeal, noslayminions, notify, notifyType, summoned, summoner, merc, wepmode, wepset, pParticle, pDuration, follow);
}

public bool SMN_CanInvoke(int client)
{
	if(minRestrict[client][1] && GetMinionCount()>minToSpawn[client][1]) return false;
	return true;
}

public void SMN_Invoke(int client)
{
	int boss=FF2_GetBossIndex(client);
	if(minRestrict[client][1] && GetMinionCount()>=minToSpawn[client][1])
	{
		PrintHintText(client, "Alive minion quota exceeded (%i / %i)!", GetMinionCount(), minToSpawn[client][1]);
		return;
	}
	
	PrepareSalmon(boss, client, RSALMON, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 26, 27, 28, 29, 30);
	
	if(AMSOnly[client])
	{
		char sound[PLATFORM_MAX_PATH];
		if(FF2_RandomSound("sound_salmon_summon", sound, sizeof(sound), boss))
		{
			EmitSoundToAll(sound);
		}		
	}
}

void Charge_Salmon(const char[] ability_name, int index, int slot, int action, int client)
{
	char status[4][256];
	float charge=FF2_GetBossCharge(index,slot);
	float bCharge = FF2_GetBossCharge(index,0);
	float rCost = FF2_GetAbilityArgumentFloat(index, this_plugin_name, ability_name, 6);
	minRestrict[client][0]=view_as<bool>(FF2_GetAbilityArgument(index,this_plugin_name,ability_name, 27));
	minToSpawn[client][0]=FF2_GetAbilityArgument(index,this_plugin_name,ability_name, 28);
	
	FF2_GetAbilityArgumentString(index, this_plugin_name, ability_name, 37, status[0], sizeof(status[]));
	FF2_GetAbilityArgumentString(index, this_plugin_name, ability_name, 38, status[1], sizeof(status[]));	
	FF2_GetAbilityArgumentString(index, this_plugin_name, ability_name, 39, status[2], sizeof(status[]));
	FF2_GetAbilityArgumentString(index, this_plugin_name, ability_name, 40, status[3], sizeof(status[]));
	
	if(minRestrict[client][0] && GetMinionCount()>=minToSpawn[client][0])
	{
		return;
	}
	
	if(rCost && !bEnableSuperDuperJump[client])
	{
		if(bCharge<rCost)
		{
			return;
		}
	}
	switch (action)
	{
		case 1:
		{
			SetHudTextParams(-1.0, slot==1 ? 0.88 : 0.93, 0.15, 255, 255, 255, 255);
			ShowSyncHudText(client, jumpHUD, status[1], -RoundFloat(charge));
		}	
		case 2:
		{
			SetHudTextParams(-1.0, slot==1 ? 0.88 : 0.93, 0.15, 255, bEnableSuperDuperJump[client] && slot == 1 ? 64 : 255, bEnableSuperDuperJump[client] && slot == 1 ? 64 : 255, 255);
			if (bEnableSuperDuperJump[client] && slot == 1)
			{
				ShowSyncHudText(client, jumpHUD, status[2]);
			}	
			else
			{	
				ShowSyncHudText(client, jumpHUD, status[0], RoundFloat(charge));
			}
		}
		case 3:
		{
			if (bEnableSuperDuperJump[client] && slot == 1)
			{
				float vel[3];
				float rot[3];
				GetEntPropVector(client, Prop_Data, "m_vecVelocity", vel);
				GetClientEyeAngles(client, rot);
				vel[2]=750.0+500.0*charge/70+2000;
				vel[0]+=Cosine(DegToRad(rot[0]))*Cosine(DegToRad(rot[1]))*500;
				vel[1]+=Cosine(DegToRad(rot[0]))*Sine(DegToRad(rot[1]))*500;
				bEnableSuperDuperJump[client]=false;
				TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, vel);
			}
			else
			{
				if(charge<100)
				{
					CreateTimer(0.1, ResetCharge, index*10000+slot);
					return;					
				}
				if(rCost)
				{
					FF2_SetBossCharge(index,0,bCharge-rCost);
				}
				
				PrepareSalmon(index, client, ability_name, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 33, 34, 35, 36, 37);

				float position[3];
				char sound[PLATFORM_MAX_PATH];
				if(FF2_RandomSound("sound_ability", sound, sizeof(sound), index, slot))
				{
					EmitSoundToAll(sound, client, _, _, _, _, _, index, position);
					EmitSoundToAll(sound, client, _, _, _, _, _, index, position);
	
					for(int target=MaxClients; target; target--)
					{
						if(IsClientInGame(target) && target!=index)
						{
							EmitSoundToClient(target, sound, client, _, _, _, _, _, index, position);
							EmitSoundToClient(target, sound, client, _, _, _, _, _, index, position);
						}
					}
				}
			}			
		}
		default:
		{
			if(charge<=0.2 && !bEnableSuperDuperJump[client])
			{
				SetHudTextParams(-1.0, 0.93, 0.15, 255, 255, 255, 255);
				ShowSyncHudText(client, jumpHUD, status[3]);
			}
		}
	}
	
}

public void Salmon(int boss, int client, const char[] ability_name, bool sound, int qty, float ratio, int modeltype, char[] model, TFClassType playerClass, bool removeWearables, int voicelineMode, int pickups, bool teletoboss, float scale, float gravity, char[] moveType, char[] pColor, char[] pConds, char[] healthFormula, int NoOverHeal, bool dontSlayMinions, int notify, int notifytype, char[] summonedText, char[] summonerText, char[] mercText, int wepmode, int wepset, char[] particleName, float particleDuration, bool particleFollow)
{
	float position[3], velocity[3];
	if(sound)
	{
		EmitSoundToAll(MANN_SND);
	}
	
	if(GetAlivePlayerCount((view_as<TFTeam>(FF2_GetBossTeam())==TFTeam_Blue) ? (TFTeam_Red) : (TFTeam_Blue))<qty || !qty) 
	{
		qty=GetAlivePlayerCount((view_as<TFTeam>(FF2_GetBossTeam())==TFTeam_Blue) ? (TFTeam_Red) : (TFTeam_Blue));
	}
	
	if(qty==-1)
	{
		qty=(ratio ? RoundToCeil(GetAlivePlayerCount((view_as<TFTeam>(FF2_GetBossTeam())==TFTeam_Blue) ? (TFTeam_Red) : (TFTeam_Blue))*ratio) : MaxClients);
	}
	
	Handle bossKV=GetRandomBossKV(boss);
	
	int ii;
	GetEntPropVector(client, Prop_Data, "m_vecOrigin", position);
	for (int i=0; i<qty; i++)
	{
		ii = GetRandomDeadPlayer();
		if(ii != -1)
		{
			FF2_SetFF2flags(ii,FF2_GetFF2flags(ii)|FF2FLAG_ALLOWSPAWNINBOSSTEAM);
			TF2_ChangeClientTeam(ii,view_as<TFTeam>(FF2_GetBossTeam()));
			TF2_RespawnPlayer(ii);
			
			if(pickups)
			{
				if(pickups==1 || pickups==3)
					FF2_SetFF2flags(ii,FF2_GetFF2flags(ii)|FF2FLAG_ALLOW_HEALTH_PICKUPS); // HP Pickup
				if(pickups==2 || pickups==3)
					FF2_SetFF2flags(ii,FF2_GetFF2flags(ii)|FF2FLAG_ALLOW_AMMO_PICKUPS); // Ammo Pickup
				else
				{
					FF2_SetFF2flags(ii,FF2_GetFF2flags(ii)|~FF2FLAG_ALLOW_HEALTH_PICKUPS); // HP Pickup
					FF2_SetFF2flags(ii,FF2_GetFF2flags(ii)|~FF2FLAG_ALLOW_AMMO_PICKUPS); // Ammo Pickup
				}
			}
			
			if(playerClass || modeltype>=2)
			{	
				if(modeltype==3)
				{
					bossKV=FF2_GetSpecialKV(boss, false);
				}
				if(modeltype>=2)
				{
					KvGetString(bossKV, "model", model, PLATFORM_MAX_PATH);	
				}
				TF2_SetPlayerClass(ii, modeltype>=2 ? view_as<TFClassType>(KvGetNum(bossKV, "class", 0)) : playerClass, _, false);
				if(!wepmode)
				{
					TF2_RegeneratePlayer(ii);
				}
			}

			switch(modeltype)
			{
				case 1:	// robots
				{
					char pclassname[10];
					TF2_GetNameOfClass(TF2_GetPlayerClass(ii), pclassname, sizeof(pclassname));
					Format(model, PLATFORM_MAX_PATH, "models/bots/%s/bot_%s.mdl", pclassname, pclassname);
					ReplaceString(model, PLATFORM_MAX_PATH, "demoman", "demo", false);
					VOMode[ii]=VoiceMode_Robot;
				}
				case 2: // looks like a random boss
				{
					MinionKV[client]=bossKV;
					char taunt[PLATFORM_MAX_PATH];
					if(KvGetNum(bossKV, "sound_block_vo", 0))
					{
						VOMode[ii]=((!HasSection("catch_phrase", taunt, sizeof(taunt), bossKV)) ? VoiceMode_None : VoiceMode_RandomBossCatchPhrase);
					}
					else
					{
						VOMode[ii]=((!HasSection("catch_phrase", taunt, sizeof(taunt), bossKV)) ? VoiceMode_Normal : VoiceMode_RandomBossCatchPhrase);
					}
				}
				case 3: // clone of boss
				{
					char taunt[PLATFORM_MAX_PATH];
					if(KvGetNum(bossKV, "sound_block_vo", 0))
					{
						VOMode[ii]=((!FF2_RandomSound("catch_phrase", taunt, sizeof(taunt), boss)) ? VoiceMode_None : VoiceMode_BossCatchPhrase);
					}
					else
					{
						VOMode[ii]=((!FF2_RandomSound("catch_phrase", taunt, sizeof(taunt), boss)) ? VoiceMode_Normal : VoiceMode_BossCatchPhrase);
					}
				}
				default:
				{
					if(voicelineMode)
					{
						VOMode[ii]=view_as<VoiceMode>(voicelineMode);
					}
				}
			}
			
			if(model[0])
			{
				SetPlayerModel(ii, model);
			}
			
			int playing=0;
			for(int player=MaxClients; player; player--)
			{
				if(!IsClientValid(player, true))
					continue;
				if(TF2_GetClientTeam(player)!=view_as<TFTeam>(FF2_GetBossTeam()))
				{
					playing++;
				}
			}
			int health=ParseFormula(boss, healthFormula, GetEntProp(GetPlayerResourceEntity(), Prop_Send, "m_iMaxHealth", _, ii), playing);
			if(health)
			{
				SetEntityHealth(ii, health);
				if(health!=GetEntProp(GetPlayerResourceEntity(), Prop_Send, "m_iMaxHealth", _, ii) && NoOverHeal)
				{
					HookHealth[ii]=true;
					SDKHook(ii, SDKHook_GetMaxHealth, GetMaxHealth_Minion);
					minionMaxHP[ii]=health;
				}
			}
			
			DontSlay[ii]=dontSlayMinions;
			SummonerIndex[ii]=boss;	
			
			if(pConds[0])
			{
				SetCondition(ii, pConds);
			}
			
			if(removeWearables)
			{
				RemoveAttachable(client, "tf_wear*");
				RemoveAttachable(client, "tf_powerup_bottle");	
			}
			
			if(gravity!=GetEntityGravity(ii))
			{
				SetEntityGravity(ii, gravity);
			}

			if(pColor[0])
			{
				char colors[32][32];
				int count = ExplodeString(pColor, " ; ", colors, sizeof(colors), sizeof(colors));
				if (count > 0)
				{
					for (int c = 0; c < count; c+=4)
					{
						SetEntityRenderMode(ii, RENDER_TRANSCOLOR);
						SetEntityRenderColor(ii, StringToInt(colors[c]), StringToInt(colors[c+1]), StringToInt(colors[c+2]), StringToInt(colors[c+3]));
					}
				}
			}
			
			if(scale)
			{
				float spawnpos[3];
				GetEntPropVector(ii, Prop_Data, "m_vecOrigin", spawnpos);
				if(IsSpotSafe(ii, (teletoboss) ? (position) : (spawnpos), scale))
				{
					SetEntPropFloat(ii, Prop_Send, "m_flModelScale", scale);
					if(isHitBoxAvailable)
					{
						UpdatePlayerHitbox(ii, scale);
					}
				}
				else
				{
					LogError("[SHADoW93 Minions] %N was not resized to %f to avoid getting stuck!", ii, scale);
				}
			}
			
			SetEntProp(ii, Prop_Data, "m_takedamage", 0);
			SDKHook(ii, SDKHook_OnTakeDamage, SaveMinion);
			CreateTimer(4.0, Timer_Enable_Damage, GetClientUserId(ii));			
			
			if(moveType[0])
			{
				if(StrEqual(moveType, "walk", false))
					mMoveType[ii]=MOVETYPE_WALK;
				else if(StrEqual(moveType, "isometric", false))
					mMoveType[ii]=MOVETYPE_ISOMETRIC;
				else if(StrEqual(moveType, "step", false))
					mMoveType[ii]=MOVETYPE_STEP;
				else if(StrEqual(moveType, "fly", false))
					mMoveType[ii]=MOVETYPE_FLY;
				else if(StrEqual(moveType, "flygravity", false))
					mMoveType[ii]=MOVETYPE_FLYGRAVITY;
				else if(StrEqual(moveType, "vphysics", false))
					mMoveType[ii]=MOVETYPE_VPHYSICS;
				else if(StrEqual(moveType, "push", false))
					mMoveType[ii]=MOVETYPE_PUSH;
				else if(StrEqual(moveType, "noclip", false))
					mMoveType[ii]=MOVETYPE_NOCLIP;
				else if(StrEqual(moveType, "ladder", false))
					mMoveType[ii]=MOVETYPE_LADDER;
				else if(StrEqual(moveType, "observer", false))
					mMoveType[ii]=MOVETYPE_OBSERVER;
				else if(StrEqual(moveType, "custom", false))
					mMoveType[ii]=MOVETYPE_CUSTOM;	
				else if(StrEqual(moveType, "none", false))
					mMoveType[ii]=MOVETYPE_NONE;
					
				if(mMoveType[ii]!=MOVETYPE_WALK && mMoveType[ii]!=MOVETYPE_NONE)
				{
					SetEntityMoveType(ii, mMoveType[ii]);
					SDKHook(ii, SDKHook_PreThink, MinionMoveType_PreThink);
				}
			}
			
			if(particleName[0])
			{
				pParticleEnt[ii]=AttachParticle(ii, particleName, particleDuration, _, particleFollow);
			}
			
			switch(wepmode)
			{
				case 2: // No weapons
					TF2_RemoveAllWeapons(ii);
				case 1: // User-Specified
				{
					TF2_RemoveAllWeapons(ii);
					if(wepset>=10) // arg 1000-1010 is used by AMS
					{
						wepset+=1;
					}
					int weaponSet=wepset<=1 ? 100 : GetRandomInt(1, wepset)*100;
					int weaponLoadouts=FF2_GetAbilityArgument(boss, this_plugin_name, ability_name, weaponSet, 1);
					
					float wScale;
					int weapon, index, ammo, clip;
					char classname[64], attributes[256], wColor[96], wModel[PLATFORM_MAX_PATH];
					for(int currentWeapon=0; currentWeapon<weaponLoadouts; currentWeapon++)
					{	
						int wepArg=weaponSet+(currentWeapon*10);
						FF2_GetAbilityArgumentString(boss, this_plugin_name, ability_name, wepArg+1, classname, sizeof(classname));
						index=FF2_GetAbilityArgument(boss, this_plugin_name, ability_name, wepArg+2);
						FF2_GetAbilityArgumentString(boss, this_plugin_name, ability_name, wepArg+3, attributes, sizeof(attributes));
						//PrintToChatAll("minion %N, arg offset: %i, weapon %i, classname %s index %i attributes %s", ii, wepArg, currentWeapon, classname, index, attributes);
						weapon=SpawnWeapon(ii, classname, index, 101, 14, attributes, FF2_GetAbilityArgument(boss, this_plugin_name, ability_name, wepArg+8));
						ammo=FF2_GetAbilityArgument(boss, this_plugin_name, ability_name, wepArg+4);
						clip=FF2_GetAbilityArgument(boss, this_plugin_name, ability_name, wepArg+5);
						FF2_GetAbilityArgumentString(boss, this_plugin_name, ability_name, wepArg+6, wModel, sizeof(wModel));			
						FF2_GetAbilityArgumentString(boss, this_plugin_name, ability_name, wepArg+7, wColor, sizeof(wColor));
						FF2_GetAbilityArgumentFloat(boss, this_plugin_name, ability_name, wepArg+9, 1.0);
						if(ammo)
						{
							SetWeaponAmmo(ii, weapon, ammo);
						}
						if(clip)
						{
							SetWeaponClip(ii, weapon, clip);
						}
						if(wColor[0])
						{
							char colors[32][32];
							int count = ExplodeString(wColor, " ; ", colors, sizeof(colors), sizeof(colors));
							if (count > 0)
							{
								for (int c = 0; c < count; c+=4)
								{
									SetEntityRenderMode(weapon, RENDER_TRANSCOLOR);
									SetEntityRenderColor(weapon, StringToInt(colors[c]), StringToInt(colors[c+1]), StringToInt(colors[c+2]), StringToInt(colors[c+3]));
								}
							}
						}	
						if(wModel[0])
						{
							int modelIndex=PrecacheModel(wModel);
							SetEntProp(weapon, Prop_Send, "m_nModelIndex", modelIndex);
							SetEntProp(weapon, Prop_Send, "m_nModelIndexOverrides", modelIndex, _, 1);
							SetEntProp(weapon, Prop_Send, "m_nModelIndexOverrides", modelIndex, _, 2);
							SetEntProp(weapon, Prop_Send, "m_nModelIndexOverrides", modelIndex, _, 3);
							SetEntProp(weapon, Prop_Send, "m_nModelIndexOverrides", (!StrContains(classname, "tf_wearable", true) ? GetEntProp(weapon, Prop_Send, "m_iWorldModelIndex") : GetEntProp(weapon, Prop_Send, "m_nModelIndex")), _, 0);	
						}
						if(wScale)
						{
							SetEntPropFloat(weapon, Prop_Send, "m_flModelScale", wScale); 
						}
						
						if(StrEqual(classname, "tf_weapon_builder", false) && index!=735)  //PDA, normal sapper
						{
							SetEntProp(weapon, Prop_Send, "m_aBuildableObjectTypes", 1, _, 0);
							SetEntProp(weapon, Prop_Send, "m_aBuildableObjectTypes", 1, _, 1);
							SetEntProp(weapon, Prop_Send, "m_aBuildableObjectTypes", 1, _, 2);
							SetEntProp(weapon, Prop_Send, "m_aBuildableObjectTypes", 0, _, 3);
						}
						else if(StrEqual(classname, "tf_weapon_sapper", false) || index==735)  //Sappers
						{
							SetEntProp(weapon, Prop_Send, "m_iObjectType", 3);
							SetEntProp(weapon, Prop_Data, "m_iSubType", 3);
							SetEntProp(weapon, Prop_Send, "m_aBuildableObjectTypes", 0, _, 0);
							SetEntProp(weapon, Prop_Send, "m_aBuildableObjectTypes", 0, _, 1);
							SetEntProp(weapon, Prop_Send, "m_aBuildableObjectTypes", 0, _, 2);
							SetEntProp(weapon, Prop_Send, "m_aBuildableObjectTypes", 1, _, 3);
						}
					}
				}
			}
			
			if(notify)
			{
				PrintToChatAll("Notifications");
				if(summonerText[0])
				{
					switch(notifytype)
					{
						case 0: PrintHintText(client, summonerText);
						case 1: PrintCenterText(client, summonerText);
						case 2: PrintTFText(client, _, _, summonerText);
						case 3: PrintTFAnnotation(client, ii, _, 5.0, summonerText);
					}
				}
				if(summonedText[0])
				{
					switch(notifytype)
					{
						case 0: PrintHintText(ii, summonedText);
						case 1: PrintCenterText(ii, summonedText);
						case 2: PrintTFText(ii, _, _, summonedText);
						case 3: PrintTFAnnotation(ii, client, _, 5.0, summonedText);
					}		
				}
				if(mercText[0])
				{
					for(client=MaxClients;client;client--)
					{
						if(!IsClientValid(client))
							continue;
						if(TF2_GetClientTeam(client)!=view_as<TFTeam>(FF2_GetBossTeam()))
						{
							switch(notifytype)
							{
								case 0: PrintHintText(client, mercText);
								case 1: PrintCenterText(client, mercText);
								case 2: PrintTFText(client, _, _, mercText);
								case 3: PrintTFAnnotation(client, ii, _, 5.0, mercText);
							}
						}
					}
				}
			}
			
			if(teletoboss)
			{
				velocity[0]=GetRandomFloat(300.0, 500.0)*(GetRandomInt(0, 1) ? 1:-1);
				velocity[1]=GetRandomFloat(300.0, 500.0)*(GetRandomInt(0, 1) ? 1:-1);
				velocity[2]=GetRandomFloat(300.0, 500.0);
				if(GetEntProp(client, Prop_Send, "m_bDucked"))
				{
					float temp[3]={24.0, 24.0, 62.0};  //Compiler won't accept directly putting it into SEPV -.-
					SetEntPropVector(ii, Prop_Send, "m_vecMaxs", temp);
					SetEntProp(ii, Prop_Send, "m_bDucked", 1);
					SetEntityFlags(ii, GetEntityFlags(ii)|FL_DUCKING);
				}
				TeleportEntity(ii, position, NULL_VECTOR, velocity);
			}
		}
	}
}

stock void RemoveAttachable(int client, char[] itemName)
{
	int entity;
	while((entity=FindEntityByClassname(entity, itemName))!=-1)
	{
		if(GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity")==client)
		{
			TF2_RemoveWearable(client, entity);
		}
	}
}

stock int PrintTFAnnotation(int client, int entity, bool effect=true, float time, char[] buffer, any ...)
{
	char message[512];
	SetGlobalTransTarget(client);
	VFormat(message, sizeof(message), buffer, 6);
	ReplaceString(message, sizeof(message), "\n", "");  //Get rid of newlines
	
	Handle event = CreateEvent("show_annotation");
	if(event == INVALID_HANDLE)
	{
		return -1;
	}
	SetEventInt(event, "follow_entindex", entity);  
	SetEventFloat(event, "lifetime", time);
	SetEventInt(event, "visibilityBitfield", (1<<client));
	SetEventBool(event,"show_effect", effect);
	SetEventString(event, "text", message);
	SetEventInt(event, "id", entity); //What to enter inside? Need a way to identify annotations by entindex!
	FireEvent(event);
	return entity;
}

stock bool PrintTFText(int client, const char[] icon="leaderboard_streak", int color=0, const char[] buffer, any ...)
{
	Handle bf;
	if(!client)
	{
		bf=StartMessageAll("HudNotifyCustom");
	}
	else
	{
		bf = StartMessageOne("HudNotifyCustom", client);
	}
	
	if(bf==null)
	{
		return false;
	}
	
	char message[512];
	SetGlobalTransTarget(client);
	VFormat(message, sizeof(message), buffer, 5);
	ReplaceString(message, sizeof(message), "\n", "");
	
	BfWriteString(bf, message);
	BfWriteString(bf, icon);
	BfWriteByte(bf, color);
	EndMessage();
	return true;
}

// Chdata's reworked attach particle system
stock int AttachParticle(int entity, const char[] szParticleType, float flTimeToDie = -1.0, float vOffsets[3] = {0.0,0.0,0.0}, bool bAttach = false, float flTimeToStart = -1.0)
{
    int particle = CreateEntityByName("info_particle_system");
    if (IsValidEntity(particle))
    {
        float vPos[3];
        GetEntPropVector(entity, Prop_Send, "m_vecOrigin", vPos);
        AddVectors(vPos, vOffsets, vPos);
        TeleportEntity(particle, vPos, NULL_VECTOR, NULL_VECTOR);
        DispatchKeyValue(particle, "effect_name", szParticleType);
        DispatchSpawn(particle);
        if (bAttach)
        {
            SetParent(entity, particle);
            SetEntPropEnt(particle, Prop_Send, "m_hOwnerEntity", entity);
        }
        ActivateEntity(particle);
        if (flTimeToStart > 0.0)
        {
            char szAddOutput[32];
            Format(szAddOutput, sizeof(szAddOutput), "OnUser1 !self,Start,,%0.2f,1", flTimeToStart);
            SetVariantString(szAddOutput);
            AcceptEntityInput(particle, "AddOutput");
            AcceptEntityInput(particle, "FireUser1");
            if (flTimeToDie > 0.0)
                flTimeToDie += flTimeToStart;
        }
        else
            AcceptEntityInput(particle, "Start");

        if (flTimeToDie > 0.0)
            killEntityIn(particle, flTimeToDie); // Interestingly, OnUser1 can be used multiple times, as the code above won't conflict with this.
        return particle;
    }
    return -1;
}

stock void SetParent(int parent, int child)
{
    SetVariantString("!activator");
    AcceptEntityInput(child, "SetParent", parent, child);
}

stock void killEntityIn(int iEnt, float flSeconds)
{
    char szAddOutput[32];
    Format(szAddOutput, sizeof(szAddOutput), "OnUser1 !self,Kill,,%0.2f,1", flSeconds);
    SetVariantString(szAddOutput);
    AcceptEntityInput(iEnt, "AddOutput");
    AcceptEntityInput(iEnt, "FireUser1");
}

public Action KillEnt(Handle timer, any entid)
{
	int entity = EntRefToEntIndex(entid);
	if (IsValidEdict(entity) && entity > MaxClients)
		AcceptEntityInput(entity, "Kill");
	entid=-1;
}

stock void SetPlayerModel(int client, char[] model)
{
	if(!model[0])
	{
		return;		
	}

	if(!IsModelPrecached(model))
	{
		PrecacheModel(model);
	}
	
	SetVariantString(model);
	AcceptEntityInput(client, "SetCustomModel");
	SetEntProp(client, Prop_Send, "m_bUseClassAnimations", 1);
}

stock void ResetSalmonSettings(int client)
{
	FF2_SetFF2flags(client, FF2_GetFF2flags(client) & ~FF2FLAG_ALLOWSPAWNINBOSSTEAM);
	if(VOMode[client]!=VoiceMode_Normal)
	{
		VOMode[client]=VoiceMode_Normal;
	}
	if(SummonerIndex[client]!=-1)
	{
		SummonerIndex[client]=-1;
	}
	if(DontSlay[client])
	{
		DontSlay[client]=false;
	}
	if(minRestrict[client][0])
	{
		minRestrict[client][0]=false;
	}
	if(minRestrict[client][1])
	{
		minRestrict[client][1]=false;
	}
	if(minToSpawn[client][0])
	{
		minToSpawn[client][0]=0;
	}
	if(minToSpawn[client][1])
	{
		minToSpawn[client][1]=0;
	}
	if(minionMaxHP[client])
	{
		minionMaxHP[client]=0;
	}
	if(AMSOnly[client])
	{
		AMSOnly[client]=false;
	}
	if(bEnableSuperDuperJump[client])
	{
		bEnableSuperDuperJump[client]=false;
	}
	
	if(MinionKV[client])
	{
		delete MinionKV[client];
		MinionKV[client]=null;
	}
	if(pParticleEnt[client]!=-1)
	{
		CreateTimer(0.1, KillEnt, EntIndexToEntRef(pParticleEnt[client]), TIMER_FLAG_NO_MAPCHANGE);
	}
	if(HookHealth[client])
	{
		SDKUnhook(client, SDKHook_GetMaxHealth, GetMaxHealth_Minion);
		HookHealth[client]=false;
	}
	if(GetEntityGravity(client)!=1.0)
	{
		SetEntityGravity(client, 1.0);
	}
	if(mMoveType[client]!=MOVETYPE_WALK)
	{
		SetEntityMoveType(client, MOVETYPE_WALK);
	}
	if(GetEntPropFloat(client, Prop_Send, "m_flModelScale")!=1.0)
	{
		float curpos[3];
		GetEntPropVector(client, Prop_Data, "m_vecOrigin", curpos);
		if(IsSpotSafe(client, curpos, 1.0))
		{
			SetEntPropFloat(client, Prop_Send, "m_flModelScale", 1.0);
			if(isHitBoxAvailable)
			{
				UpdatePlayerHitbox(client, 1.0);
			}
		}
		else
			LogError("[SHADoW93 Minions] %N was not resized to avoid getting stuck!", client);
	}
}

public Action FF2_OnTriggerHurt(int boss, int triggerhurt,float &damage)
{
	int client=GetClientOfUserId(FF2_GetBossUserId(boss));
	if(!bEnableSuperDuperJump[client])
	{
		bEnableSuperDuperJump[client]=true;
		if (FF2_GetBossCharge(boss,1)<0)
			FF2_SetBossCharge(boss,1,0.0);
	}
	return Plugin_Continue;
}

stock bool IsClientValid(int client, bool lifecheck=false)
{
    if(client<=0 || client>MaxClients) return false;
    return lifecheck ? IsClientInGame(client) && IsPlayerAlive(client) : IsClientInGame(client);
}

#if !defined _FF2_Extras_included
stock int SpawnWeapon(int client, char[] name, int index, int level, int quality, char[] attribute, int visible = 1, bool preserve = false)
{
	if(StrEqual(name,"saxxy", false)) // if "saxxy" is specified as the name, replace with appropiate name
	{ 
		switch(TF2_GetPlayerClass(client))
		{
			case TFClass_Scout: ReplaceString(name, 64, "saxxy", "tf_weapon_bat", false);
			case TFClass_Soldier: ReplaceString(name, 64, "saxxy", "tf_weapon_shovel", false);
			case TFClass_Pyro: ReplaceString(name, 64, "saxxy", "tf_weapon_fireaxe", false);
			case TFClass_DemoMan: ReplaceString(name, 64, "saxxy", "tf_weapon_bottle", false);
			case TFClass_Heavy: ReplaceString(name, 64, "saxxy", "tf_weapon_fists", false);
			case TFClass_Engineer: ReplaceString(name, 64, "saxxy", "tf_weapon_wrench", false);
			case TFClass_Medic: ReplaceString(name, 64, "saxxy", "tf_weapon_bonesaw", false);
			case TFClass_Sniper: ReplaceString(name, 64, "saxxy", "tf_weapon_club", false);
			case TFClass_Spy: ReplaceString(name, 64, "saxxy", "tf_weapon_knife", false);
		}
	}
	
	if(StrEqual(name, "tf_weapon_shotgun", false)) // If using tf_weapon_shotgun for Soldier/Pyro/Heavy/Engineer
	{
		switch(TF2_GetPlayerClass(client))
		{
			case TFClass_Soldier:	ReplaceString(name, 64, "tf_weapon_shotgun", "tf_weapon_shotgun_soldier", false);
			case TFClass_Pyro:	ReplaceString(name, 64, "tf_weapon_shotgun", "tf_weapon_shotgun_pyro", false);
			case TFClass_Heavy:	ReplaceString(name, 64, "tf_weapon_shotgun", "tf_weapon_shotgun_hwg", false);
			case TFClass_Engineer:	ReplaceString(name, 64, "tf_weapon_shotgun", "tf_weapon_shotgun_primary", false);
		}
	}

	Handle weapon = TF2Items_CreateItem((preserve ? PRESERVE_ATTRIBUTES : OVERRIDE_ALL) | FORCE_GENERATION);
	TF2Items_SetClassname(weapon, name);
	TF2Items_SetItemIndex(weapon, index);
	TF2Items_SetLevel(weapon, level);
	TF2Items_SetQuality(weapon, quality);
	char attributes[32][32];
	int count = ExplodeString(attribute, ";", attributes, 32, 32);
	if(count%2!=0)
	{
		count--;
	}

	if(count>0)
	{
		TF2Items_SetNumAttributes(weapon, count/2);
		int i2 = 0;
		for(int i = 0; i < count; i += 2)
		{
			int attrib = StringToInt(attributes[i]);
			if (attrib == 0)
			{
				LogError("Bad weapon attribute passed: %s ; %s", attributes[i], attributes[i+1]);
				return -1;
			}
			TF2Items_SetAttribute(weapon, i2, attrib, StringToFloat(attributes[i+1]));
			i2++;
		}
	}
	else
	{
		TF2Items_SetNumAttributes(weapon, 0);
	}

	if (weapon == INVALID_HANDLE)
	{
		PrintToServer("[SpawnWeapon] Error: Invalid weapon spawned. client=%d name=%s idx=%d attr=%s", client, name, index, attribute);
		return -1;
	}

	int entity = TF2Items_GiveNamedItem(client, weapon);
	delete weapon;
	
	if(!visible)
	{
		SetEntProp(entity, Prop_Send, "m_iWorldModelIndex", -1);
		SetEntPropFloat(entity, Prop_Send, "m_flModelScale", 0.001);
	}
	
	if (StrContains(name, "tf_wearable")==-1)
	{
		EquipPlayerWeapon(client, entity);
	}
	else
	{
		Wearable_EquipWearable(client, entity);
	}
	
	return entity;
}

Handle S93SF_equipWearable = INVALID_HANDLE;
stock void Wearable_EquipWearable(int client, int wearable)
{
	if(S93SF_equipWearable==INVALID_HANDLE)
	{
		Handle config=LoadGameConfigFile("equipwearable");
		if(config==INVALID_HANDLE)
		{
			LogError("[FF2] EquipWearable gamedata could not be found; make sure /gamedata/equipwearable.txt exists.");
			return;
		}

		StartPrepSDKCall(SDKCall_Player);
		PrepSDKCall_SetFromConf(config, SDKConf_Virtual, "EquipWearable");
		CloseHandle(config);
		PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
		if((S93SF_equipWearable=EndPrepSDKCall())==INVALID_HANDLE)
		{
			LogError("[FF2] Couldn't load SDK function (CTFPlayer::EquipWearable). SDK call failed.");
			return;
		}
	}
	SDKCall(S93SF_equipWearable, client, wearable);
}
#endif

#if SOURCEMOD_V_MAJOR==1 && SOURCEMOD_V_MINOR<=7
public Action SoundHook(int clients[64], int &numClients, char vl[PLATFORM_MAX_PATH], int &client, int &channel, float &volume, int &level, int &pitch, int &flags)
#else
public Action SoundHook(int clients[64], int &numClients, char vl[PLATFORM_MAX_PATH], int &client, int &channel, float &volume, int &level, int &pitch, int &flags, char soundEntry[PLATFORM_MAX_PATH], int &seed)
#endif
{
	if(!IsClientValid(client, false) || channel<1)
	{
		return Plugin_Continue;
	}

	switch(VOMode[client])
	{
		case VoiceMode_None: // NO Voicelines!
		{
			if(channel==SNDCHAN_VOICE)
			{
				return Plugin_Stop;
			}
		}
		case VoiceMode_Robot:	// Robot VO
		{
			if(!TF2_IsPlayerInCondition(client, TFCond_Disguised)) // Robot voice lines & footsteps
			{
				if (StrContains(vl, "player/footsteps/", false) != -1 && TF2_GetPlayerClass(client) != TFClass_Medic)
				{
					int rand = GetRandomInt(1,18);
					Format(vl, sizeof(vl), "mvm/player/footsteps/robostep_%s%i.wav", (rand < 10) ? "0" : "", rand);
					pitch = GetRandomInt(95, 100);
					EmitSoundToAll(vl, client, _, _, _, 0.25, pitch);
				}
				
				if(channel==SNDCHAN_VOICE)
				{
					if (volume == 0.99997) return Plugin_Continue;
					ReplaceString(vl, sizeof(vl), "vo/", "vo/mvm/norm/", false);
					ReplaceString(vl, sizeof(vl), ".wav", ".mp3", false);
					char classname[10], classname_mvm[15];
					TF2_GetNameOfClass(TF2_GetPlayerClass(client), classname, sizeof(classname));
					Format(classname_mvm, sizeof(classname_mvm), "%s_mvm", classname);
					ReplaceString(vl, sizeof(vl), classname, classname_mvm, false);
					char nSnd[PLATFORM_MAX_PATH];
					Format(nSnd, sizeof(nSnd), "sound/%s", vl);
					PrecacheSound(vl);
				}
				return Plugin_Changed;
			}
		}
		case VoiceMode_GiantRobot: // Giant Robot VO
		{
			if(!TF2_IsPlayerInCondition(client, TFCond_Disguised)) // Giant robot voice lines & footsteps
			{
				if (StrContains(vl, "player/footsteps/", false) != -1 && TF2_GetPlayerClass(client) != TFClass_Medic)
				{
					Format(vl, sizeof(vl), "mvm/giant_common/giant_common_step_0%i.wav", GetRandomInt(1,8));
					pitch = GetRandomInt(95, 100);
					EmitSoundToAll(vl, client, _, _, _, 0.25, pitch);
				}
				
				if(channel==SNDCHAN_VOICE)
				{
					if (volume == 0.99997) return Plugin_Continue;
					ReplaceString(vl, sizeof(vl), "vo/", "vo/mvm/mght/", false);
					char classname[10], classname_mvm_m[20];
					TF2_GetNameOfClass(TF2_GetPlayerClass(client), classname, sizeof(classname));
					Format(classname_mvm_m, sizeof(classname_mvm_m), "%s_mvm_m", classname);
					ReplaceString(vl, sizeof(vl), classname, classname_mvm_m, false);
					char gSnd[PLATFORM_MAX_PATH];
					Format(gSnd, sizeof(gSnd), "sound/%s", vl);
					PrecacheSound(vl);
				}
				return Plugin_Changed;
			}
		}
		case VoiceMode_BossCatchPhrase: // Minions use boss's catchphrases
		{
			char taunt[PLATFORM_MAX_PATH];
			if(channel==SNDCHAN_VOICE && FF2_RandomSound("catch_phrase", taunt, sizeof(taunt), SummonerIndex[client]))
			{
				strcopy(vl, PLATFORM_MAX_PATH, taunt);
				return Plugin_Changed;
			}
		}
		case VoiceMode_CatchPhrase: // Minions have their own catchphrase lines
		{
			char taunt[PLATFORM_MAX_PATH];
			if(channel==SNDCHAN_VOICE && FF2_RandomSound("sound_minion_catchphrase", taunt, sizeof(taunt), SummonerIndex[client]))
			{
				strcopy(vl, PLATFORM_MAX_PATH, taunt);
				return Plugin_Changed;
			}
		}
		case VoiceMode_RandomBossCatchPhrase: // Random boss model, let's get the boss's catchphrase of that boss
		{
			char taunt[PLATFORM_MAX_PATH];
			if(channel==SNDCHAN_VOICE && HasSection("catch_phrase", taunt, sizeof(taunt), MinionKV[client]))
			{
				strcopy(vl, PLATFORM_MAX_PATH, taunt);
				PrecacheSound(vl);
				return Plugin_Changed;
			}
		}
	}
	return Plugin_Continue;
}

public Action SaveMinion(int client, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3])
{
	if(attacker>MaxClients)
	{
		char edict[64];
		if(GetEdictClassname(attacker, edict, sizeof(edict)) && !strcmp(edict, "trigger_hurt", false))
		{
			int target;
			float position[3];
			bool otherTeamIsAlive;
			for(int player=MaxClients; player; player--)
			{
				if(IsValidEdict(player) && IsClientInGame(player) && IsPlayerAlive(player) && GetClientTeam(player)!=FF2_GetBossTeam())
				{
					otherTeamIsAlive=true;
					break;
				}
			}

			int tries;
			do
			{
				tries++;
				target=GetRandomInt(1, MaxClients);
				if(tries==100)
				{
					return Plugin_Continue;
				}
			}
			while(otherTeamIsAlive && (!IsValidEdict(target) || GetClientTeam(target)==FF2_GetBossTeam() || !IsPlayerAlive(target)));

			GetEntPropVector(target, Prop_Data, "m_vecOrigin", position);
			TeleportEntity(client, position, NULL_VECTOR, NULL_VECTOR);
			TF2_StunPlayer(client, 2.0, 0.0, TF_STUNFLAGS_LOSERSTATE, client);
			return Plugin_Handled;
		}
	}
	return Plugin_Continue;
}

/*
************************** STOCKS **************************
* Here you will find all the stocks used by this subplugin *
************************************************************
*/

/*
	Prethink 
*/
public void MinionMoveType_PreThink(int client)
{
	if(!IsClientValid(client, true) || FF2_GetRoundState()!=1)
	{
		mMoveType[client]=MOVETYPE_WALK;
		SetEntityMoveType(client, mMoveType[client]);
		SDKUnhook(client, SDKHook_PreThink, MinionMoveType_PreThink);
	}
	
	// This is to prevent bosses from getting stuck on the ground.
	if(mMoveType[client]!=MOVETYPE_NONE && mMoveType[client]!=MOVETYPE_WALK)
	{
		if(!(GetEntityFlags(client) & FL_ONGROUND))
		{
			if(GetEntityMoveType(client)!= mMoveType[client])
			{
				SetEntityMoveType(client, mMoveType[client]);
			}
		}
		else
		{
			if(GetEntityMoveType(client)!=MOVETYPE_WALK)
			{
				SetEntityMoveType(client, MOVETYPE_WALK);
			}
		}
	}
}

public Action GetMaxHealth_Minion(int client, int &maxHealth)
{
	maxHealth=minionMaxHP[client];
	return Plugin_Changed;
}

/*
	sarysa's safe resizing code
*/

bool ResizeTraceFailed;
int ResizeMyTeam;
public bool Resize_TracePlayersAndBuildings(int entity, int contentsMask)
{
	if (IsClientValid(entity,true))
	{
		if (GetClientTeam(entity) != ResizeMyTeam)
		{
			ResizeTraceFailed = true;
		}
	}
	else if (IsValidEntity(entity))
	{
		static char classname[64];
		GetEntityClassname(entity, classname, sizeof(classname));
		if ((strcmp(classname, "obj_sentrygun") == 0) || (strcmp(classname, "obj_dispenser") == 0) || (strcmp(classname, "obj_teleporter") == 0)
			|| (strcmp(classname, "prop_dynamic") == 0) || (strcmp(classname, "func_physbox") == 0) || (strcmp(classname, "func_breakable") == 0))
		{
			ResizeTraceFailed = true;
		}
	}

	return false;
}

bool Resize_OneTrace(const float startPos[3], const float endPos[3])
{
	static float result[3];
	TR_TraceRayFilter(startPos, endPos, MASK_PLAYERSOLID, RayType_EndPoint, Resize_TracePlayersAndBuildings);
	if (ResizeTraceFailed)
	{
		return false;
	}
	TR_GetEndPosition(result);
	if (endPos[0] != result[0] || endPos[1] != result[1] || endPos[2] != result[2])
	{
		return false;
	}
	
	return true;
}

// the purpose of this method is to first trace outward, upward, and then back in.
bool Resize_TestResizeOffset(const float bossOrigin[3], float xOffset, float yOffset, float zOffset)
{
	static float tmpOrigin[3];
	tmpOrigin[0] = bossOrigin[0];
	tmpOrigin[1] = bossOrigin[1];
	tmpOrigin[2] = bossOrigin[2];
	static float targetOrigin[3];
	targetOrigin[0] = bossOrigin[0] + xOffset;
	targetOrigin[1] = bossOrigin[1] + yOffset;
	targetOrigin[2] = bossOrigin[2];
	
	if (!(xOffset == 0.0 && yOffset == 0.0))
		if (!Resize_OneTrace(tmpOrigin, targetOrigin))
			return false;
		
	tmpOrigin[0] = targetOrigin[0];
	tmpOrigin[1] = targetOrigin[1];
	tmpOrigin[2] = targetOrigin[2] + zOffset;

	if (!Resize_OneTrace(targetOrigin, tmpOrigin))
		return false;
		
	targetOrigin[0] = bossOrigin[0];
	targetOrigin[1] = bossOrigin[1];
	targetOrigin[2] = bossOrigin[2] + zOffset;
		
	if (!(xOffset == 0.0 && yOffset == 0.0))
		if (!Resize_OneTrace(tmpOrigin, targetOrigin))
			return false;
		
	return true;
}

bool Resize_TestSquare(const float bossOrigin[3], float xmin, float xmax, float ymin, float ymax, float zOffset)
{
	static float pointA[3];
	static float pointB[3];
	for (int phase = 0; phase <= 7; phase++)
	{
		// going counterclockwise
		if (phase == 0)
		{
			pointA[0] = bossOrigin[0] + 0.0;
			pointA[1] = bossOrigin[1] + ymax;
			pointB[0] = bossOrigin[0] + xmax;
			pointB[1] = bossOrigin[1] + ymax;
		}
		else if (phase == 1)
		{
			pointA[0] = bossOrigin[0] + xmax;
			pointA[1] = bossOrigin[1] + ymax;
			pointB[0] = bossOrigin[0] + xmax;
			pointB[1] = bossOrigin[1] + 0.0;
		}
		else if (phase == 2)
		{
			pointA[0] = bossOrigin[0] + xmax;
			pointA[1] = bossOrigin[1] + 0.0;
			pointB[0] = bossOrigin[0] + xmax;
			pointB[1] = bossOrigin[1] + ymin;
		}
		else if (phase == 3)
		{
			pointA[0] = bossOrigin[0] + xmax;
			pointA[1] = bossOrigin[1] + ymin;
			pointB[0] = bossOrigin[0] + 0.0;
			pointB[1] = bossOrigin[1] + ymin;
		}
		else if (phase == 4)
		{
			pointA[0] = bossOrigin[0] + 0.0;
			pointA[1] = bossOrigin[1] + ymin;
			pointB[0] = bossOrigin[0] + xmin;
			pointB[1] = bossOrigin[1] + ymin;
		}
		else if (phase == 5)
		{
			pointA[0] = bossOrigin[0] + xmin;
			pointA[1] = bossOrigin[1] + ymin;
			pointB[0] = bossOrigin[0] + xmin;
			pointB[1] = bossOrigin[1] + 0.0;
		}
		else if (phase == 6)
		{
			pointA[0] = bossOrigin[0] + xmin;
			pointA[1] = bossOrigin[1] + 0.0;
			pointB[0] = bossOrigin[0] + xmin;
			pointB[1] = bossOrigin[1] + ymax;
		}
		else if (phase == 7)
		{
			pointA[0] = bossOrigin[0] + xmin;
			pointA[1] = bossOrigin[1] + ymax;
			pointB[0] = bossOrigin[0] + 0.0;
			pointB[1] = bossOrigin[1] + ymax;
		}

		for (int shouldZ = 0; shouldZ <= 1; shouldZ++)
		{
			pointA[2] = pointB[2] = shouldZ == 0 ? bossOrigin[2] : (bossOrigin[2] + zOffset);
			if (!Resize_OneTrace(pointA, pointB))
				return false;
		}
	}
		
	return true;
}

public bool IsSpotSafe(int clientIdx, float playerPos[3], float sizeMultiplier)
{
	ResizeTraceFailed = false;
	ResizeMyTeam = GetClientTeam(clientIdx);
	static float mins[3];
	static float maxs[3];
	mins[0] = -24.0 * sizeMultiplier;
	mins[1] = -24.0 * sizeMultiplier;
	mins[2] = 0.0;
	maxs[0] = 24.0 * sizeMultiplier;
	maxs[1] = 24.0 * sizeMultiplier;
	maxs[2] = 82.0 * sizeMultiplier;

	// the eight 45 degree angles and center, which only checks the z offset
	if (!Resize_TestResizeOffset(playerPos, mins[0], mins[1], maxs[2])) return false;
	if (!Resize_TestResizeOffset(playerPos, mins[0], 0.0, maxs[2])) return false;
	if (!Resize_TestResizeOffset(playerPos, mins[0], maxs[1], maxs[2])) return false;
	if (!Resize_TestResizeOffset(playerPos, 0.0, mins[1], maxs[2])) return false;
	if (!Resize_TestResizeOffset(playerPos, 0.0, 0.0, maxs[2])) return false;
	if (!Resize_TestResizeOffset(playerPos, 0.0, maxs[1], maxs[2])) return false;
	if (!Resize_TestResizeOffset(playerPos, maxs[0], mins[1], maxs[2])) return false;
	if (!Resize_TestResizeOffset(playerPos, maxs[0], 0.0, maxs[2])) return false;
	if (!Resize_TestResizeOffset(playerPos, maxs[0], maxs[1], maxs[2])) return false;

	// 22.5 angles as well, for paranoia sake
	if (!Resize_TestResizeOffset(playerPos, mins[0], mins[1] * 0.5, maxs[2])) return false;
	if (!Resize_TestResizeOffset(playerPos, mins[0], maxs[1] * 0.5, maxs[2])) return false;
	if (!Resize_TestResizeOffset(playerPos, maxs[0], mins[1] * 0.5, maxs[2])) return false;
	if (!Resize_TestResizeOffset(playerPos, maxs[0], maxs[1] * 0.5, maxs[2])) return false;
	if (!Resize_TestResizeOffset(playerPos, mins[0] * 0.5, mins[1], maxs[2])) return false;
	if (!Resize_TestResizeOffset(playerPos, maxs[0] * 0.5, mins[1], maxs[2])) return false;
	if (!Resize_TestResizeOffset(playerPos, mins[0] * 0.5, maxs[1], maxs[2])) return false;
	if (!Resize_TestResizeOffset(playerPos, maxs[0] * 0.5, maxs[1], maxs[2])) return false;

	// four square tests
	if (!Resize_TestSquare(playerPos, mins[0], maxs[0], mins[1], maxs[1], maxs[2])) return false;
	if (!Resize_TestSquare(playerPos, mins[0] * 0.75, maxs[0] * 0.75, mins[1] * 0.75, maxs[1] * 0.75, maxs[2])) return false;
	if (!Resize_TestSquare(playerPos, mins[0] * 0.5, maxs[0] * 0.5, mins[1] * 0.5, maxs[1] * 0.5, maxs[2])) return false;
	if (!Resize_TestSquare(playerPos, mins[0] * 0.25, maxs[0] * 0.25, mins[1] * 0.25, maxs[1] * 0.25, maxs[2])) return false;
	
	return true;
}

/*
	Hitbox scaling
*/
stock void UpdatePlayerHitbox(const int client, float scale)
{
	float vecScaledPlayerMin[3] = { -24.5, -24.5, 0.0 }, vecScaledPlayerMax[3] = { 24.5,  24.5, 83.0 };
	ScaleVector(vecScaledPlayerMin, scale);
	ScaleVector(vecScaledPlayerMax, scale);
	SetEntPropVector(client, Prop_Send, "m_vecSpecifiedSurroundingMins", vecScaledPlayerMin);
	SetEntPropVector(client, Prop_Send, "m_vecSpecifiedSurroundingMaxs", vecScaledPlayerMax);
}

/*
	Health Parser
 */
stock void Operate(Handle sumArray, int &bracket, float value, Handle _operator)
{
	float sum=GetArrayCell(sumArray, bracket);
	switch(GetArrayCell(_operator, bracket))
	{
		case Operator_Add:
		{
			SetArrayCell(sumArray, bracket, sum+value);
		}
		case Operator_Subtract:
		{
			SetArrayCell(sumArray, bracket, sum-value);
		}
		case Operator_Multiply:
		{
			SetArrayCell(sumArray, bracket, sum*value);
		}
		case Operator_Divide:
		{
			if(!value)
			{
				LogError("[SHADoW93 Minions] Detected a divide by 0!");
				bracket=0;
				return;
			}
			SetArrayCell(sumArray, bracket, sum/value);
		}
		case Operator_Exponent:
		{
			SetArrayCell(sumArray, bracket, Pow(sum, value));
		}
		default:
		{
			SetArrayCell(sumArray, bracket, value);  //This means we're dealing with a constant
		}
	}
	SetArrayCell(_operator, bracket, Operator_None);
}

stock void OperateString(Handle sumArray, int &bracket, char[] value, int size, Handle _operator)
{
	if(!StrEqual(value, ""))  //Make sure 'value' isn't blank
	{
		Operate(sumArray, bracket, StringToFloat(value), _operator);
		strcopy(value, size, "");
	}
}

public int ParseFormula(int boss, const char[] key, int defaultValue, int playing)
{
	char formula[1024], bossName[64];
	FF2_GetBossSpecial(boss, bossName, sizeof(bossName));
	strcopy(formula, sizeof(formula), key);
	int size=1;
	int matchingBrackets;
	for(int i; i<=strlen(formula); i++)  //Resize the arrays once so we don't have to worry about it later on
	{
		if(formula[i]=='(')
		{
			if(!matchingBrackets)
			{
				size++;
			}
			else
			{
				matchingBrackets--;
			}
		}
		else if(formula[i]==')')
		{
			matchingBrackets++;
		}
	}

	Handle sumArray=CreateArray(_, size), _operator=CreateArray(_, size);
	int bracket;  //Each bracket denotes a separate sum (within parentheses).  At the end, they're all added together to achieve the actual sum
	SetArrayCell(sumArray, 0, 0.0);  //TODO:  See if these can be placed naturally in the loop
	SetArrayCell(_operator, bracket, Operator_None);

	char character[2], value[16];  //We don't decl value because we directly append characters to it and there's no point in decl'ing character
	for(int i; i<=strlen(formula); i++)
	{
		character[0]=formula[i];  //Find out what the next char in the formula is
		switch(character[0])
		{
			case ' ', '\t':  //Ignore whitespace
			{
				continue;
			}
			case '(':
			{
				bracket++;  //We've just entered a new parentheses so increment the bracket value
				SetArrayCell(sumArray, bracket, 0.0);
				SetArrayCell(_operator, bracket, Operator_None);
			}
			case ')':
			{
				OperateString(sumArray, bracket, value, sizeof(value), _operator);
				if(GetArrayCell(_operator, bracket)!=Operator_None)  //Something like (5*)
				{
					LogError("[SHADoW93 Minions] %s's %s formula has an invalid operator at character %i", bossName, key, i+1);
					CloseHandle(sumArray);
					CloseHandle(_operator);
					return defaultValue;
				}

				if(--bracket<0)  //Something like (5))
				{
					LogError("[SHADoW93 Minions] %s's %s formula has an unbalanced parentheses at character %i", bossName, key, i+1);
					CloseHandle(sumArray);
					CloseHandle(_operator);
					return defaultValue;
				}

				Operate(sumArray, bracket, GetArrayCell(sumArray, bracket+1), _operator);
			}
			case '\0':  //End of formula
			{
				OperateString(sumArray, bracket, value, sizeof(value), _operator);
			}
			case '0', '1', '2', '3', '4', '5', '6', '7', '8', '9', '.':
			{
				StrCat(value, sizeof(value), character);  //Constant?  Just add it to the current value
			}
			case 'n', 'x':  //n and x denote player variables
			{
				Operate(sumArray, bracket, float(playing), _operator);
			}
			case '+', '-', '*', '/', '^':
			{
				OperateString(sumArray, bracket, value, sizeof(value), _operator);
				switch(character[0])
				{
					case '+':
					{
						SetArrayCell(_operator, bracket, Operator_Add);
					}
					case '-':
					{
						SetArrayCell(_operator, bracket, Operator_Subtract);
					}
					case '*':
					{
						SetArrayCell(_operator, bracket, Operator_Multiply);
					}
					case '/':
					{
						SetArrayCell(_operator, bracket, Operator_Divide);
					}
					case '^':
					{
						SetArrayCell(_operator, bracket, Operator_Exponent);
					}
				}
			}
		}
	}

	int result=RoundFloat(GetArrayCell(sumArray, 0));
	CloseHandle(sumArray);
	CloseHandle(_operator);
	if(result<=0)
	{
		LogError("[SHADoW93 Minions] %s has an invalid %s formula for minions, using default health!", bossName, key);
		return defaultValue;
	}
	return result;
}

stock void TF2_GetNameOfClass(TFClassType class, char[] name, int maxlen) // Retrieves player class name
{
	switch (class)
	{
		case TFClass_Scout: Format(name, maxlen, "scout");
		case TFClass_Soldier: Format(name, maxlen, "soldier");
		case TFClass_Pyro: Format(name, maxlen, "pyro");
		case TFClass_DemoMan: Format(name, maxlen, "demoman");
		case TFClass_Heavy: Format(name, maxlen, "heavy");
		case TFClass_Engineer: Format(name, maxlen, "engineer");
		case TFClass_Medic: Format(name, maxlen, "medic");
		case TFClass_Sniper: Format(name, maxlen, "sniper");
		case TFClass_Spy: Format(name, maxlen, "spy");
	}
}


public Action ResetCharge(Handle timer, any index)
{
	int slot=index%10000;
	index/=1000;
	FF2_SetBossCharge(index, slot, 0.0);
}

public Action Timer_Enable_Damage(Handle timer, any userid)
{
	int client=GetClientOfUserId(userid);
	if(client)
	{
		SetEntProp(client, Prop_Data, "m_takedamage", 2);
		FF2_SetFF2flags(client, FF2_GetFF2flags(client) & ~FF2FLAG_ALLOWSPAWNINBOSSTEAM);
		SDKUnhook(client, SDKHook_OnTakeDamage, SaveMinion);
	}
	return Plugin_Continue;
}

stock int GetMinionCount()
{
	int minions=0;
	for(int client=MaxClients; client; client--)
	{
		if(!IsClientValid(client, true)) continue;
		if(TF2_GetClientTeam(client)!=view_as<TFTeam>(FF2_GetBossTeam())) continue;
		if(FF2_GetBossIndex(client)!=-1) continue;
		minions++;
	}
	return minions;
}
stock int GetAlivePlayerCount(TFTeam team)
{
	int alivePlayers=0;
	for (int client=1;client<=MaxClients;client++)
	{
		if(!IsClientValid(client, true))
			continue;
		if(TF2_GetClientTeam(client)!=team)
			continue;
		alivePlayers++;
	}
	return alivePlayers;
}

stock int SetWeaponClip(int client, int slot, int clip)
{
	int weapon = GetPlayerWeaponSlot(client, slot);
	if (IsValidEntity(weapon))
	{
		SetEntProp(weapon, Prop_Send, "m_iClip1", clip);
	}
}

stock int SetWeaponAmmo(int client, int slot, int ammo)
{
	int weapon = GetPlayerWeaponSlot(client, slot);
	if (IsValidEntity(weapon))
	{
		int iOffset = GetEntProp(weapon, Prop_Send, "m_iPrimaryAmmoType", 1)*4;
		int iAmmoTable = FindSendPropInfo("CTFPlayer", "m_iAmmo");
		SetEntData(client, iAmmoTable+iOffset, ammo, 4, true);
	}
}
stock void SetCondition(int client, char[] cond)
{
	char conds[32][32];
	int count = ExplodeString(cond, " ; ", conds, sizeof(conds), sizeof(conds));
	if (count > 0)
	{
		for (int i = 0; i < count; i+=2)
		{
			TF2_AddCondition(client, view_as<TFCond>(StringToInt(conds[i])), StringToFloat(conds[i+1]));
		}
	}
}

stock int GetRandomDeadPlayer()
{
	int[] clients = new int[MaxClients+1];
	int clientCount;
	for(int i=1;i<=MaxClients;i++)
	{
		if(IsValidEdict(i) && IsClientValid(i) && !IsPlayerAlive(i) && FF2_GetBossIndex(i) == -1 && (GetClientTeam(i) > 1))
		{
			clients[clientCount++] = i;
		}
	}
	return (clientCount == 0) ? -1 : clients[GetRandomInt(0, clientCount-1)];
}

stock bool HasSection(const char[] sound, char[] file, int length, Handle bossKV)
{
	if(!bossKV)
	{
		return false;
	}

	KvRewind(bossKV);
	if(!KvJumpToKey(bossKV, sound))
	{
		KvRewind(bossKV);
		return false;  //Requested sound not implemented for this boss
	}

	char key[4];
	int sounds;
	while(++sounds)  //Just keep looping until there's no keys left
	{
		IntToString(sounds, key, sizeof(key));
		KvGetString(bossKV, key, file, length);
		if(!file[0])
		{
			sounds--;  //This sound wasn't valid, so don't include it
			break;  //Assume that there's no more sounds
		}
	}

	if(!sounds)
	{
		return false;  //Found sound, but no sounds inside of it
	}

	IntToString(GetRandomInt(1, sounds), key, sizeof(key));
	KvGetString(bossKV, key, file, length);  //Populate file
	return true;
}

public Handle GetRandomBossKV(int boss)
{
	int index=-1;
	for(int config=0; FF2_GetSpecialKV(config, true)!=null; config++)
	{
		index++;
	}
	
	int position=GetRandomInt(0, index);
	Handle BossKV=FF2_GetSpecialKV(position, true);
	if(BossKV!=null) return BossKV;
	return FF2_GetSpecialKV(boss, false);
}

public void FF2_OnAbility2(int boss,const char[] plugin_name, const char[] ability_name, int action)
{
	if(!FF2_IsFF2Enabled() || FF2_GetRoundState()!=1)
		return;
		
	int client=GetClientOfUserId(FF2_GetBossUserId(boss));
	int slot=FF2_GetAbilityArgument(boss, this_plugin_name, ability_name, 0);
	
	if (!strcmp(ability_name,CSALMON)) // TO-DO: Make compatible with Dynamic Defaults
	{
		Charge_Salmon(ability_name,boss,slot,action, client);			// Upgraded version of Otokiru's Charge_Salmon
	}
	else if (!strcmp(ability_name,RSALMON))
	{
		if(minRestrict[client][0] && GetMinionCount()>minToSpawn[client][0])
		{
			PrintHintText(client,"ALIVE MINIONS: %i > MAXIMUM ALIVE MINIONS: %i!", GetMinionCount(), minToSpawn[client]);
			return;
		}
		if(AMSOnly[client])
		{
			return;
		}
		SMN_Invoke(client);
	}	
}