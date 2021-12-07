#pragma semicolon 1
#include <tf2_stocks>
#include <sdktools>
#include <sdkhooks>
#include <customweaponstf>
#include <tf2>
#include <tf2items>
#include <tf2attributes>
#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <tf2_stocks>
#include <sdkhooks>
#include <customweaponstf>
#include <silver>
//#include <smlib>
//#include <time>

#define PLUGIN_VERSION "beta 2"

public Plugin:myinfo = {
    name = "Custom Weapons: Silver's attributes",
    name = "Custom Weapons: Silver's attributes",
    author = "silverSketch",
    description = "Silver's attributes.",
    version = PLUGIN_VERSION,
    url = "http://mstr.ca/"
};

/* *** Attributes In This Plugin ***
  !  "speed boost on hit teammate"
       "<user's speed boost duration> <teammate's>"
	   Upon hitting a teammate, both of your speeds will be boosted
	   for N seconds.
	   Can currently only be used on hitscan weapons and melee weapons,
	   due to TraceAttack not having a weapon parameter. :c
  -> "aim punch multiplier"
       "<multiplier>"
	   Upon hitting an enemy, the "aim punch" applied to their aim
	   will be multiplied by this amount.
	   High amounts are useful for disorienting enemies,
	   and low amounts will disable aim punch to prevent throwing off enemies.
  -> "aim punch to self"
       "<multiplier>"
	   Upon attacking with this weapon, the user will receive this much aim punch.
  -> "look down attack velocity"
       "<start velocity> <push velocity>"
	   When the user looks down and attacks with this weapon,
	   they will be pushed up into the air by N Hammer units.
	   "Start" value is for if the user is on the ground,
	   "push" is applied when they are already vertically moving.
  -> "add metal on attack"
       "<amount>"
	   Each time the user attacks with this weapon, they will gain this much metal.
	   You probably want to use a negative value with this attribute.
	   If negative, the user won't be able to fire this weapon unless they have
	   sufficient metal.
  -> "infinite ammo"
       "<ammo counter>"
	   This weapon's offhand ammo count will always be set to this amount.
	   If you're going to use this attribute, you also ought to add either
	   "hidden primary max ammo bonus" or "hidden secondary max ammo penalty" (TF2 attributes)
	   to your weapon, setting them to 0.0.
	   That way, the user cannot pick up and waste precious ammo packs and dropped weapons.
  -> "crits ignite"
	   Critical hits from this weapon will ignite the victim.
  -> "crit damage multiplier"
	   <multiplier>
	   Scales the amount of crit damage from this weapon.
	   The multiplier is applied to the base damage, so 1.5 on a sniper rifle headshot =
	   50 * 1.5 = 75, and 75 * 3 = 225.
  -> "damage mult below threshold"
	   <damage multiplier> <damage value>
	   Scales the damage dealt when below a threshold. Can be raised or decreased, 
	   depending on the value.
  -> "damage mult above threshold"
	   <damage multiplier> <damage value>
	   Scales the damage dealt when above a threshold. Can be raised or decreased, 
	   depending on the value.
  -> "static damage"
  	   <damage>
  	   Damage dealt is static, set to the <damage> value. This overrides ALL other damage modifications, except "damage builds"
  -> "damage builds"
  	   <% of damage to add on hit> <max damage>
  	   On Hit: Add "x"% of damage dealt as bonus damage, with a cap of "y" damage. If <% of damage to add on hit> is higher than 10, it is considered a static value rather than a percent.
  	   Note: when your damage is above 1/4 of its max, it will slowly drain (5% of max damage a second)
  -> "damage mod"
  	   <damage to add>
  	   Adds or subtracts exact amounts of damage
  -> "addcond on damage dealt"
  	   <damage dealt> <condition> <duration> <extra condition 1> <extra condition 2> <extra condition 3> <max charges>
  	   After dealing a minimum of "u" damage, you gain a Condition Charge. You can hold a maximum of "a" charges. Taunting will remove all your charges and grant you "v" condition, which lasts "w" seconds for each charge.
  	   You may add 3 more effects with "x" "y" and "z." If you don't want 1 or more of these extras, set their value to -1.
  -> "addcond recharge"
  	   <condition 1> <condition 2> <condition 3> <condition 4> <recharge time> <duration>
  	   On Taunt when meter is full: Add "a" "b" "c" and "d" conditions(use -1 if you don't want any condition for that slot) for "e" seconds. It takes "f" seconds to recharge(f can only go to tenths of a second).
  -> "ammo size on damage"
  	   <damage> <base clip size percent> <percent on damage> <max stocks> <base ammo percent> <percent ammo on damage>
  	   Adds "c"% clip size after dealing "a" damage. Max of "d" stocks. Also adds "f"% max primary and secondary ammo after the damage threshold.
  -> "damage on hit"
  	   <damage bonus> <base damage percent> <max stocks>
  	   Adds an "x"% damage bonus on hit. Changing targets resets damage bonus. maximum of "z" damage bonus stocks
  -> "last damage"
  	   <percent of last damage to add> <duration until effect is removed> <passive or active>
  	   On Hit: deal "x"% of last hit's damage as bonus damage. Effect is removed after "y" seconds. (for z, 1 is passive and 0 is active, and y can only go to 10ths of a second. z currently doesn't work, put any value for it)
  -> "panic on hit"
  	   <fire rate bonus> <accuracy bonus> <max bonuses> <base fire rate> <base accuracy>
  	   On Hit: Increase fire rate by "a"%, and increase accuracy by "b"%. Maximum of "c" bonuses. Bonus resets after "e" seconds.	   (for base accuracy, lower numbers make it more accurate.)
  	   																																   (for accuracy bonus, use negatives to make the bonus become a penalty.)
  	   																																   ("e" can only go to 10th of a second, and the time is reset on hit.)
  -> "set health"
  	   <set your health to your opponent's health> <set your opponent's health to your health> <add your opponent's health to yours instead of setting it>
  	   On Hit: Swap health with your opponent OR set your opponent's health to your health OR set your health to your opponent's health
  	   (for the values, 1 is true, 0 or anything else is false)
  
  	   PLANNED ATTRIBUTES:
  	   
  -> "focus on crit"
  	   <damage bonus> <damage resistance> <reload rate modifier> <move speed modifier>
  	   Headshots/Crits charge “Focus” Activating Focus grants: "a"% damage bonus "b"% damage resistance "c"% faster reload rate "d"% move speed penalty. To activate Focus, taunt(invincibility for taunt duration)
  -> "movespeed damage"
  	   <damage threshold low> <damage threshold high> <bonus> <defecit> <minimum speed before killed> <max speed>
  	   Dealing less than "a" damage in a shot will lower your speed by "d"%. Dealing more than "b" damage in a shot will increase your speed by "c"%.
  	   Reaching "e"% speed penalty will result in death. Maximum speed bonus is "f"%.
  -> "ham charge"
  	   <charge per hit> <minimum % for effect> <% of charge added as damage> <charge lost when hit>
  	   On Hit: Add "a"% Ham Charge. After reaching "b"% ham charge, become fire retardant, elgulf targets into flames on hit, and recieve "c"% of charge as extra damage.
  	   When hit at any time, "d"% of charge is lost.
  -> "addcond use on hit"
  	   <condition number> <kill or damage>
  	   On Kill/damage threshold: Gain 1 "x" condition charge. Upon hitting an opponent, 1 charge is removed.(setting "y" to 1 makes it provide on kill, when any other number is the damage threshold)
  -> "max ammo hit drain"
  	   <% on hit> <% on drain> <maximum penalty> <base ammo capacity> <slot #>
  	   On Hit: Increase ammo capacity by "a"%. If 5 seconds pass without hitting a target, ammo capacity will drain by "b"% every second.
  -> "charge time on crit"
  	   <charge time on hit> <max charge time>
  	   On Crit: Increase charge time by "x" seconds. Maximum of "y" seconds of charge time.(x and y are measured in seconds, not as a percent. Charge time provided while the weapon is active.)
  -> "lifetime dmg bonus"
  	   <% added per second> <maximum damage bonus> <% lost on death> <base damage bonus>
  	   +"a"% damage bonus added per second. Maximum of +"b"% damage bonus. On Death: Lose "c"% of your bonus(ex. 50% bonus, when killed lose 10% of that 50%, if "c" is 0.1, leaving 45% bonus on respawn)
  -> "fire rate health"
  	   <maximum fire rate bonus>
  	   Fire rate increases as the user becomes injured.
  -> "bullets health"
  	   <maximum bullets per shot bonus>
  	   Bullets per shot increases as the user becomes injured.
  -> "reload health"
  	   <maximum reload speed bonus>
  	   Reload speed increases as the user becomes injured.
  	   
  	    CURRENTLY UNAVAILABLE ATTRIBUTES DO NOT USE:
  	    
  -> "clip size on kill"
  	   <percent increase on kill> <% stocks kept on death> <max stocks> <base clip size percent>
  	   On Kill: Increase clip size by "x"%. This stacks up to "z" times. On death: Lose "y"% of stocks
  -> "dawn speed"
  	   <speed percent gained/s> <max speed percent> <percent change when hit> <base move speed>
  	   +"a"% movement speed gained/lost per second. Max speed of "b"%. Speed resets on weapon switch. Lose "c"% of speed when hit.
  -> "max health on damage"
  	   <damage> <health added> <max stocks>
  	   After dealing "x" damage, you gain "y" health. This stacks up to "z" times.
  -> "mod medigun heal mode"
  	   <any value will activate>
  	   Switch between 2 healing modes when pressing your special attack key.
  	   Quick-Heal- +40% heal rate, -75% overheal penalty, -10% uber build rate
  	   Uber Build- -10% heal rate, -25% overheal penalty, +50% uber build rate
*/

// Here's where we store attribute values, which are received when the attribute is applied.
// There's one for each of the 2048 (+1) edict slots, which will sometimes be weapons.
// For example, when "crit damage multiplier" "0.6" is set on a weapon, we want
// CritDamage[thatweaponindex] to be set to 0.6, so we know to multiply the crit damage by 0.6x.
// There's also HasAttribute[2049], for a super-marginal performance boost. Don't touch it.

//GetClientMaxHealth(client); is a native I added

//Basic attributes(not mine)
new LastWeaponHurtWith[MAXPLAYERS + 1];

new bool:HasAttribute[2049];

new bool:TeammateSpeedBoost[2049];
new Float:TeammateSpeedBoost_User[2049];
new Float:TeammateSpeedBoost_Teammate[2049];

new Float:AimPunchMultiplier[2049] = {1.0, ...};
new Float:AimPunchToSelf[2049] = {0.0, ...};

new bool:LookDownAttackVelocity[2049];
new Float:LookDownAttackVelocity_Start[2049];
new Float:LookDownAttackVelocity_Push[2049];

new AddMetalOnAttack[2049];

new InfiniteAmmo[2049];

new bool:CritsIgnite[2049];

new Float:CritDamage[2049] = {1.0, ...};

//Silver's attributes(mine)
new Float:DamageThresholdHigh[2049];
new Float:DamageThresholdLow[2049];
new Float:LowDamageMult[2049] = 1.0;	//damage threshold variables
new Float:HighDamageMult[2049] = 1.0;
new bool:DmgLowOn[2049];
new bool:DmgHighOn[2049];

new Float:StaticDamage[2049] = -1.0;	//static damage and damage build variables
new bool:DamageBuild[2049];
new Float:DamagePercent[2049] = 0.0;
new Float:DamageMax[2049] = 0.0;
new Float:DamageStored[2049] = 0.0;

new DamageMod[2049] = 0;				//damage mod variable

new Condition[2049] = -1;
new Condition1[2049] = -1;
new Condition2[2049] = -1;
new Condition3[2049] = -1;
new Float:DamageDealt[2049] = 1.0;		//condition damage variables
new Float:ConditionDuration[2049] = 1.0;
new bool:DamageCondition[2049];
new Float:DamageDealtMax[2049] = 0.0;
new ConditionChargeStored[2049] = 0;
new ConditionChargeMax[2049] = 0;

new RechargeCondition[2049] = -1;
new RechargeCondition1[2049] = -1;
new RechargeCondition2[2049] = -1;		//recharge condition damage variables
new RechargeCondition3[2049] = -1;
new Float:RechargeTime[2049] = -1.0;
new Float:RechargeConditionDuration[2049] = 0.0;
new Float:RechargeTrack[2049] = -1.0;
new bool:RechargeConditionApplied[2049] = false;

new Float:Seconds;			//this variable can be used anywhere, counts from 0.1 to 1, and resets when past 1. It never reaches 0.0

/*
new Float:ClipSizePercent[2049] = 0.0;
new MaxClipStocks[2049] = 0;
new Float:ClipPreserve[2049] = 0.0;
new bool:ClipOnKill[2049] = false;					//Might come back to this in the future,
new ClipStocks[2049] = 0;							//I just couldn't find a way to track kills that didn't give me tons of errors that told me nothing about what was wrong.
new Float:BaseClip[2049] = 0.0;
*/

new ClipDamageStocks[2049] = 0;
new ClipDamageStocksMax[2049] = 0;
new Float:ClipPercentAdd[2049] = 0.0;
new Float:BaseClipPercent[2049] = 0.0;		//clip on damage variables
new Float:ClipDamageTrack[2049] = 0.0;
new Float:ClipDamageMax[2049] = 0.0;
new bool:ClipDamage[2049] = false;
new Float:BaseAmmoPercent[2049] = 0.0;
new Float:AmmoPercentAdd[2049] = 0.0;

new HealthDamageStocks[2049] = 0;
new HealthDamageStocksMax[2049] = 0;		//health on damage variables
new Float:HealthDamageMax[2049] = 0.0;
new Float:HealthDamageTrack[2049] = 0.0;
new HealthAdd[2049] = 0;
new bool:MaxHealthAttribute[2049] = false;


new Float:HitDamagePercent[2049] = 0.0;
new MaxHitDamageStocks[2049] = 0;			//damage on hit variables
new Float:BaseDamagePercent[2049] = 0.0;
new bool:HitDamage[2049] = false;
new HitDamageStocks[2049] = 0;
new String:lastvictim = '1';


new Float:MoveSpeedPercent[2049] = 0.0;		//this is set on the client(look in the attribute code for the reason)
new Float:MoveSpeedMax[2049] = 0.0;			//move speed variables
new Float:MoveSpeedLost[2049] = 0.0;
new Float:MoveSpeedTrack[2049] = 0.0;
new bool:MoveSpeed[2049] = false;
new lastweapon[2049] = 0;
new weaponslot[2049] = 0;
new Float:BaseMoveSpeed[2049] = 0.0;

new bool:QuickFix[2049] = true;
new bool:UberBuild[2049] = false;
new Handle:hudText_PriWeapon;				//medigun attribute, broken
new Handle:hudText_SecWeapon;
new Handle:hudText_MelWeapon;
new Float:HealWait[2049];

new MaxHealthTotem[2049] = 0;
new bool:TotemActive[2049] = false;			//totem attribute, broken
new bool:Totem[2049] = false;
new Float:PercentHealth[2049] = 0.0;

new bool:LastDamageAdd[2049] = false;
new Float:LastDamagePercent[2049] = 0.0;
new Float:LastHitDamage[2049] = 0.0;		//damage bonus based on last hit's damage attribute
new Float:TimeUntilReset[2049] = 0.0;
new Float:TimeTracker[2049] = 0.0;
new Passive[2049] = 0;
new bool:isweaponactive[2049] = false;

new Float:FireRatePercent[2049] = 0.0;
new Float:AccuracyPercent[2049] = 0.0;
new MaxPanicStocks[2049] = 0;				//panic on hit variables(based off of origional panic attack)
new Float:BaseAccuracyPercent[2049] = 0.0;
new Float:BaseFireRatePercent[2049] = 0.0;
new bool:PanicHit[2049] = false;
new PanicStocks[2049] = 0;
new Float:PanicResetTime[2049] = 0.0;
new Float:PanicResetTrack[2049] = 0.0;

new bool:SetHealth[2049] = false;			//set health variables
new opponent[2049] = 0;
new you[2049] = 0;
new over[2049] = 0;

/*
		if(HammerMechanic_Fann[wep] == true)		//zethax start
			{
				SetHudTextParams(-1.0, 0.7, 0.2, 255, 255, 255, 255);								//This stuff is for my own use, for hud dispay.
				ShowSyncHudText(client, hudText_PriWeapon, "Firing Mode: Hammer Firing");			//Credit goes to Zethax for this origional code segment.
			}
			else if(HammerMechanic_Fann[wep] == false)
			{
				SetHudTextParams(-1.0, 0.7, 0.2, 255, 255, 255, 255);
				ShowSyncHudText(client, hudText_PriWeapon, "Firing Mode: Trigger Firing");
			}										//zethax end
*/


// Here's a great spot to place "secondary" variables used by attributes, such as
// "ReduxHypeBonusDraining[2049]" (custom-attributes.sp) or client variables,
// like the one seen below, which shows the next time we can play a "click" noise.
new Float:NextOutOfAmmoSoundTime[MAXPLAYERS + 1];

public OnPluginStart()
{
	// We'll set weapons' ammo counts every ten times a second if they have infinite ammo.
	CreateTimer(0.1, Timer_TenTimesASecond, _, TIMER_REPEAT);
	
	// Since we're hooking damage (seen below), we need to hook the below hooks on players who were
	// already in the game when the plugin loaded, if any.
	for (new i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i)) continue;
		OnClientPutInServer(i);
	}
	
	hudText_PriWeapon = CreateHudSynchronizer();
	hudText_SecWeapon = CreateHudSynchronizer();
	hudText_MelWeapon = CreateHudSynchronizer();
}

// Usually, you'll want to hook damage done to players, using SDK Hooks.
// You'll need to do so in OnPluginStart (taken care of above) and in OnClientPutInServer.
public OnClientPutInServer(client)
{
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
	SDKHook(client, SDKHook_OnTakeDamagePost, OnTakeDamagePost);
	SDKHook(client, SDKHook_TraceAttack, OnTraceAttack);
	
	LastWeaponHurtWith[client] = 0;
}

// This is called whenever a custom attribute is added, so first...
public Action:CustomWeaponsTF_OnAddAttribute(weapon, client, const String:attrib[], const String:plugin[], const String:value[])
{
	// Filter out other plugins. If "plugin" is not "basic-attributes", then ignore this attribute.
	if (!StrEqual(plugin, "silver")) return Plugin_Continue;
	
	// "action" here is what we'll return to the base Custom Weapons plugin when we're done.
	// It defaults to "Plugin_Continue" which means the attribute wasn't recognized. So let's check if we
	// know what attribute this is...
	new Action:action;
	
	// Compare the attribute's name against each of our own.
	// In this case, if it's "aim punch multiplier"...
	if (StrEqual(attrib, "aim punch multiplier"))
	{
		// ...then get the number from the "value" string, and remember that.
		AimPunchMultiplier[weapon] = StringToFloat(value);
		
		// We recognize the attribute and are ready to make it work!
		action = Plugin_Handled;
	}
	// If it wasn't aim punch multiplier, was it any of our other attributes?
	else if (StrEqual(attrib, "speed boost on hit teammate"))
	{
		// Here, we use ExplodeString to get two numbers out of the same string.
		new String:values[2][10];
		ExplodeString(value, " ", values, sizeof(values), sizeof(values[]));
		
		// ...And then set them to two different variables.
		TeammateSpeedBoost_User[weapon] = StringToFloat(values[0]);
		TeammateSpeedBoost_Teammate[weapon] = StringToFloat(values[1]);
		
		// This attribute could potentially be used to ONLY give a speed boost to the user,
		// or ONLY the teammate, so we use a third boolean variable to see if it's on.
		TeammateSpeedBoost[weapon] = true;
		action = Plugin_Handled;
	}
	else if (StrEqual(attrib, "damage mult below threshold"))
	{
		// Here, we use ExplodeString to get two numbers out of the same string.
		new String:values1[2][10];
		ExplodeString(value, " ", values1, sizeof(values1), sizeof(values1[]));
		
		// ...And then set them to two different variables.
		LowDamageMult[weapon] = StringToFloat(values1[0]);
		DamageThresholdLow[weapon] = StringToFloat(values1[1]);		//tag mismatch
		
		DmgLowOn[weapon] = true;
		action = Plugin_Handled;
	}
	else if (StrEqual(attrib, "damage mult above threshold"))
	{
		// Here, we use ExplodeString to get two numbers out of the same string.
		new String:values2[2][10];
		ExplodeString(value, " ", values2, sizeof(values2), sizeof(values2[]));
		
		// ...And then set them to two different variables.
		HighDamageMult[weapon] = StringToFloat(values2[0]);
		DamageThresholdHigh[weapon] = StringToFloat(values2[1]);	//tag mismatch
		
		DmgHighOn[weapon] = true;
		action = Plugin_Handled;
	}
	else if (StrEqual(attrib, "damage builds"))
	{
		// Here, we use ExplodeString to get two numbers out of the same string.
		new String:values4[2][10];
		ExplodeString(value, " ", values4, sizeof(values4), sizeof(values4[]));
		
		// ...And then set them to two different variables.
		DamagePercent[weapon] = StringToFloat(values4[0]);
		DamageMax[weapon] = StringToFloat(values4[1]);	//tag mismatch
		
		DamageBuild[weapon] = true;
		action = Plugin_Handled;
	}
	else if(StrEqual(attrib, "addcond on damage dealt")) {
	
		new String:values[7][10];
		ExplodeString(value, " ", values, sizeof(values), sizeof(values[]));
		
		DamageDealtMax[weapon] = StringToFloat(values[0]);
		Condition[weapon] = StringToInt(values[1]);
		ConditionDuration[weapon] = StringToFloat(values[2]);
		Condition1[weapon] = StringToInt(values[3]);
		Condition2[weapon] = StringToInt(values[4]);
		Condition3[weapon] = StringToInt(values[5]);
		ConditionChargeMax[weapon] = StringToInt(values[6]);
		
		DamageCondition[weapon] = true;
		action = Plugin_Handled;
	}
	else if(StrEqual(attrib, "addcond recharge")) {
	
		new String:values[7][10];
		ExplodeString(value, " ", values, sizeof(values), sizeof(values[]));
		
		RechargeCondition[weapon] = StringToInt(values[0]);
		RechargeCondition1[weapon] = StringToInt(values[1]);
		RechargeCondition2[weapon] = StringToInt(values[2]);
		RechargeCondition3[weapon] = StringToInt(values[3]);
		RechargeTime[weapon] = StringToFloat(values[4]);
		RechargeConditionDuration[weapon] = StringToFloat(values[5]);
		RechargeTrack[weapon] = StringToFloat(values[4]);
		
		RechargeConditionApplied[weapon] = true;
		action = Plugin_Handled;
	}
	/*else if(StrEqual(attrib, "clip size on kill")) {
	
		new String:values[4][10];
		ExplodeString(value, " ", values, sizeof(values), sizeof(values[]));
		
		ClipSizePercent[weapon] = StringToFloat(values[0]);
		ClipPreserve[weapon] = StringToFloat(values[1]);
		MaxClipStocks[weapon] = StringToInt(values[2]);
		BaseClip[weapon] = StringToFloat(values[3]);
		TF2Attrib_SetByName(weapon, "clip size bonus", BaseClip[weapon]);
		
		ClipOnKill[weapon] = true;
		action = Plugin_Handled;
	} */
	else if(StrEqual(attrib, "ammo size on damage")) {
	
		new String:values[6][10];
		ExplodeString(value, " ", values, sizeof(values), sizeof(values[]));
		
		ClipDamageMax[weapon] = StringToFloat(values[0]);
		BaseClipPercent[weapon] = StringToFloat(values[1]);
		ClipPercentAdd[weapon] = StringToFloat(values[2]);
		ClipDamageStocksMax[weapon] = StringToInt(values[3]);
		BaseAmmoPercent[weapon] = StringToFloat(values[4]);
		AmmoPercentAdd[weapon] = StringToFloat(values[5]);
		TF2Attrib_SetByName(weapon, "clip size bonus", BaseClipPercent[weapon]);
		TF2Attrib_SetByName(weapon, "maxammo primary increased", BaseAmmoPercent[weapon]);
		TF2Attrib_SetByName(weapon, "maxammo secondary increased", BaseAmmoPercent[weapon]);
		
		ClipDamage[weapon] = true;
		action = Plugin_Handled;
	}
	else if(StrEqual(attrib, "max health on damage")) {
	
		new String:values[3][10];
		ExplodeString(value, " ", values, sizeof(values), sizeof(values[]));
		
		HealthDamageMax[weapon] = StringToFloat(values[0]);
		HealthAdd[weapon] = StringToInt(values[1]);
		HealthDamageStocksMax[weapon] = StringToInt(values[2]);
		
		MaxHealthAttribute[weapon] = true;
		action = Plugin_Handled;
	}
	else if(StrEqual(attrib, "damage on hit")) {
	
		new String:values[3][10];
		ExplodeString(value, " ", values, sizeof(values), sizeof(values[]));
		
		HitDamagePercent[weapon] = StringToFloat(values[0]);
		BaseDamagePercent[weapon] = StringToFloat(values[1]);
		MaxHitDamageStocks[weapon] = StringToInt(values[2]);
		
		HitDamage[weapon] = true;
		action = Plugin_Handled;
	}
	else if(StrEqual(attrib, "dawn speed")) {
	
		new String:values[4][10];
		ExplodeString(value, " ", values, sizeof(values), sizeof(values[]));
		
		MoveSpeedPercent[weapon] = StringToFloat(values[0]);
		MoveSpeedMax[weapon] = StringToFloat(values[1]);
		MoveSpeedLost[weapon] = StringToFloat(values[2]);
		BaseMoveSpeed[client] = StringToFloat(values[3]);	//set to client so we can reset the speed value when the weapon is not held, based on this attribute
		MoveSpeedTrack[client] = 0.0;	//set to client, b/c we need to reset this value if the currently held weapon does not have the attribute.
		
		//weaponslot[client] = GetPlayerWeaponSlot[client];
		
		MoveSpeed[weapon] = true;
		action = Plugin_Handled;
	} 
	else if(StrEqual(attrib, "totem")) {
	
		new String:values[2][10];
		ExplodeString(value, " ", values, sizeof(values), sizeof(values[]));
		
		PercentHealth[client] = StringToFloat(values[0]);
		MaxHealthTotem[client] = StringToInt(values[1]);
		TotemActive[client] = true;
		
		Totem[client] = true;
		action = Plugin_Handled;
	}
	else if(StrEqual(attrib, "last damage")) {
	
		new String:values[3][10];
		ExplodeString(value, " ", values, sizeof(values), sizeof(values[]));
		
		LastDamagePercent[client] = StringToFloat(values[0]);
		TimeUntilReset[client] = StringToFloat(values[1]);
		Passive[client] = StringToInt(values[2]);
		
		LastDamageAdd[client] = true;
		isweaponactive[weapon] = true;
		action = Plugin_Handled;
	}
	else if(StrEqual(attrib, "panic on hit")) {
	
		new String:values[6][10];
		ExplodeString(value, " ", values, sizeof(values), sizeof(values[]));
		
		FireRatePercent[weapon] = StringToFloat(values[0]);
		AccuracyPercent[weapon] = StringToFloat(values[1]);
		MaxPanicStocks[weapon] = StringToInt(values[2]);
		BaseFireRatePercent[weapon] = StringToFloat(values[3]);
		BaseAccuracyPercent[weapon] = StringToFloat(values[4]);
		PanicResetTime[weapon] = StringToFloat(values[5]);
		TF2Attrib_SetByName(weapon, "fire rate bonus", BaseFireRatePercent[weapon]);
		TF2Attrib_SetByName(weapon, "spread penalty", BaseAccuracyPercent[weapon]);
		PanicStocks[client] = 0;
		
		PanicHit[weapon] = true;
		action = Plugin_Handled;
	}
	else if(StrEqual(attrib, "set health")) {
	
		new String:values[3][10];
		ExplodeString(value, " ", values, sizeof(values), sizeof(values[]));
		
		opponent[weapon] = StringToInt(values[0]);
		you[weapon] = StringToInt(values[1]);
		over[weapon] = StringToInt(values[2]);
		
		SetHealth[weapon] = true;
		action = Plugin_Handled;
	}
	else if (StrEqual(attrib, "static damage"))
	{
		// ...then get the number from the "value" string, and remember that.
		StaticDamage[weapon] = StringToFloat(value);
		
		// We recognize the attribute and are ready to make it work!
		action = Plugin_Handled;
	}
	else if (StrEqual(attrib, "damage mod"))
	{
		// ...then get the number from the "value" string, and remember that.
		DamageMod[weapon] = StringToInt(value);
		
		// We recognize the attribute and are ready to make it work!
		action = Plugin_Handled;
	}
	else if (StrEqual(attrib, "mod medigun heal mode"))
	{
		// ...then get the number from the "value" string, and remember that.
		QuickFix[weapon] = false;
		UberBuild[weapon] = true;
		
		// We recognize the attribute and are ready to make it work!
		action = Plugin_Handled;
	}
	else if (StrEqual(attrib, "aim punch to self"))
	{
		AimPunchToSelf[weapon] = StringToFloat(value);
		action = Plugin_Handled;
	}
	else if (StrEqual(attrib, "look down attack velocity"))
	{
		new String:values3[2][10];
		ExplodeString(value, " ", values3, sizeof(values3), sizeof(values3[]));
		
		LookDownAttackVelocity_Start[weapon] = StringToFloat(values3[0]);
		LookDownAttackVelocity_Push[weapon] = StringToFloat(values3[1]);
		
		LookDownAttackVelocity[weapon] = true;
		action = Plugin_Handled;
	}
	else if (StrEqual(attrib, "add metal on attack"))
	{
		AddMetalOnAttack[weapon] = StringToInt(value);
		action = Plugin_Handled;
	}
	else if (StrEqual(attrib, "infinite ammo"))
	{
		InfiniteAmmo[weapon] = StringToInt(value);
		action = Plugin_Handled;
	}
	else if (StrEqual(attrib, "crits ignite"))
	{
		// Some attributes are simply on/off, so we don't need to check the "value" string.
		CritsIgnite[weapon] = true;
		action = Plugin_Handled;
	}
	else if (StrEqual(attrib, "crit damage multiplier"))
	{
		CritDamage[weapon] = StringToFloat(value);
		action = Plugin_Handled;
	}
	
	// If the weapon isn't already marked as custom (as far as this plugin is concerned)
	// then mark it as custom, but ONLY if we've set "action" to Plugin_Handled.
	if (!HasAttribute[weapon]) HasAttribute[weapon] = bool:action;
	
	// Let Custom Weapons know that we're going to make the attribute work (Plugin_Handled)
	// or let it print a warning (Plugin_Continue).
	return action;
}
// ^ Remember, this is called once for every custom attribute (attempted to be) applied!


// Now, let's start making those attributes work.
// Every time a player takes damage, we'll check if the weapon that the attacker used
// has one of our attributes.


public Action:OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype, &weapon, Float:damageForce[3], Float:damagePosition[3])
{
	if (attacker <= 0 || attacker > MaxClients) return Plugin_Continue; // Attacker isn't valid, so the weapon won't be either.
	if (weapon == -1) return Plugin_Continue; // Weapon is invalid, so it won't be custom.
	if (!HasAttribute[weapon]) return Plugin_Continue; // Weapon is valid, but doesn't have one of our attributes. We don't care!
	
		//This code gets the victim's health
		new health = GetClientHealth(victim);
	
		//This code sets up victim's weapon
		new victimweapon;
		for (new i = 0; i <= 5; i++)
		{
		new j = GetPlayerWeaponSlot(victim, i);
		if (j == -1) continue;
		if (!HasAttribute[j]) continue;
		victimweapon = j;
		}
		
		//This code gets the attacker's health
		new ahealth = GetClientHealth(attacker);
		
	// If we've gotten this far, we might need to take "action" c:
	// But, seriously, we might. Our "action" will be set to Plugin_Changed if we
	// change anything about this damage.
	new Action:action;
	
	// Does this weapon have the "aim punch multiplier" attribute? 1.0 is the default for this attribute, so let's compare against that.
	// Also, make sure the victim is a player.
	if (AimPunchMultiplier[weapon] != 1.0 && victim > 0 && victim <= MaxClients)
	{
		// It does! So, we'll use this sorta-complex-looking data timer to multiply the victim's aim punch in one frame (0.0 seconds).
		new Handle:data;
		CreateDataTimer(0.0, Timer_DoAimPunch, data, TIMER_FLAG_NO_MAPCHANGE);
		WritePackCell(data, GetClientUserId(victim));
		WritePackCell(data, EntIndexToEntRef(weapon));
		WritePackCell(data, false);
		ResetPack(data);
	}
	
	// Now, maybe the above was applied. Wether it was or not, the weapon might have ALSO had "crit damage multiplier".
	// So we'll use another "if" statement to check (NOT else if) but, of course, we also need to see if it's a crit (if "damagetype" includes DMG_CRIT)
	if (CritDamage[weapon] != 1.0 && damagetype & DMG_CRIT)
	{
		// It does, and this is a crit, so multiply the damage by the variable we just checked.
		damage = damage * CritDamage[weapon];
		
		// We changed the damage, so we need to return Plugin_Changed below...
		action = Plugin_Changed;
	}
	
	if (LowDamageMult[weapon] != 1.0 && victim > 0 && victim <= MaxClients && damage < DamageThresholdLow[weapon])
	{
		if (damage < DamageThresholdLow[weapon])
		{
		damage *= LowDamageMult[weapon];
		}
		
		action = Plugin_Changed;
	}
	
	if (HighDamageMult[weapon] != 1.0 && victim > 0 && victim <= MaxClients && damage > DamageThresholdHigh[weapon])
	{
		if (damage > DamageThresholdHigh[weapon])
		{
		damage *= HighDamageMult[weapon];
		}
		
		action = Plugin_Changed;
	}
	
	if (StaticDamage[weapon] < -1)
	{
		damage = StaticDamage[weapon];
		
		// We changed the damage, so we need to return Plugin_Changed below...
		action = Plugin_Changed;
	}
	
	if (DamageMod[weapon] != 0)
	{
		damage += DamageMod[weapon];
		
		// We changed the damage, so we need to return Plugin_Changed below...
		action = Plugin_Changed;
	}
	
	if (DamageMax[weapon] != 0 && victim > 0 && victim <= MaxClients)
	{
		damage += DamageStored[weapon];
		
		action = Plugin_Changed;
	}
	
	if (DamageCondition[weapon] != false && victim > 0 && victim <= MaxClients)
	{
		if (TF2_IsPlayerInCondition(attacker, TFCond:Condition[weapon]) != true)
		{
			DamageDealt[weapon] += damage;
		}
	}
	if (ClipDamage[weapon] == true)
	{
	ClipDamageTrack[weapon] += damage;
	
	action = Plugin_Changed;
	if (ClipDamageTrack[weapon] >= ClipDamageMax[weapon])
		{
			ClipDamageTrack[weapon] += ClipDamageMax[weapon] * -1;
			ClipDamageStocks[weapon] += 1;
			PrintHintText(attacker, "Custom: Clip size added");
		}
		if (ClipDamageStocks[weapon] >= ClipDamageStocksMax[weapon])
		{
			ClipDamageStocks[weapon] = ClipDamageStocksMax[weapon];
			ClipDamageTrack[weapon] = 0.0;
			PrintHintText(attacker, "Custom: Clip size Maxed");
		}
		new Float:clipbonus = (BaseClipPercent[weapon] * ClipPercentAdd[weapon] * ClipDamageStocks[weapon]);
		new Float:ammobonus = (BaseAmmoPercent[weapon] * AmmoPercentAdd[weapon] * ClipDamageStocks[weapon]);
		TF2Attrib_RemoveByName(weapon, "clip size bonus");
		TF2Attrib_SetByName(weapon, "clip size bonus", clipbonus + BaseClipPercent[weapon]);
		TF2Attrib_SetByName(weapon, "maxammo primary increased", ammobonus + BaseAmmoPercent[weapon]);
		TF2Attrib_SetByName(weapon, "maxammo secondary increased", ammobonus + BaseAmmoPercent[weapon]);
	}
	if (MaxHealthAttribute[weapon] == true)
	{
		HealthDamageTrack[weapon] += damage;
		action = Plugin_Changed;
		
		if (HealthDamageTrack[weapon] >= HealthDamageMax[weapon])
		{
			HealthDamageTrack[weapon] = 0.0;
			HealthDamageStocks[weapon] += 1;
			PrintHintText(attacker, "Custom: %d total health stocks", HealthDamageStocks[weapon]);
		}
		if (HealthDamageStocks[weapon] >= HealthDamageStocksMax[weapon])
		{
			HealthDamageStocks[weapon] = HealthDamageStocksMax[weapon];
			HealthDamageTrack[weapon] = 0.0;
			PrintHintText(attacker, "Custom: %d: Max health stocks reached", HealthDamageStocksMax[weapon]);
		}
		new Float:healthbonus = (HealthAdd[weapon] * HealthDamageStocks[weapon]);
		TF2Attrib_RemoveByName(attacker, "max health additive bonus");
		TF2Attrib_SetByName(attacker, "max health additive bonus", healthbonus);
	}
	if (HitDamage[weapon] == true)
	{
		if (HitDamageStocks[weapon] > MaxHitDamageStocks[weapon])
		{
			HitDamageStocks[weapon] = MaxHitDamageStocks[weapon];
		}
		HitDamageStocks[weapon] = (HitDamageStocks[weapon] + 1);
		damage = damage * (BaseDamagePercent[weapon] + (HitDamageStocks[weapon] * HitDamagePercent[weapon]));
		if (String:lastvictim != victim && HitDamageStocks[weapon] > 0)
		{
			HitDamageStocks[weapon] = 0;
			PrintHintText(attacker, "Custom: Damage reset.");
			EmitSoundToClient(victim, "items/gunpickup2.wav");
		}
	}
	if (MoveSpeed[weapon] == false)
	{
		MoveSpeedTrack[attacker] = 0.0;
		if (BaseMoveSpeed[attacker] != 0)
		{
			TF2Attrib_RemoveByName(attacker, "move speed bonus");
			TF2Attrib_SetByName(attacker, "move speed bonus", BaseMoveSpeed[attacker]);
		}
	}
	if (MoveSpeed[victimweapon] ==  true)
	{
		MoveSpeedTrack[victim] += MoveSpeedLost[victimweapon];
	}
	
	if (Totem[victim] == true)
	{
		if (health <= damage)
		{
			if (TotemActive[victim] == true)
			{
				damage = 0.0;
				SetEntityHealth(victim, (GetClientMaxHealth(victim) * PercentHealth[victim]));
				TotemActive[victim] = false;
				EmitSoundToClient(victim, "weapons/bottle_break.wav");
			}
		}
	}
	
	if (LastDamageAdd[attacker] == true)
	{
		TimeTracker[attacker] = TimeUntilReset[attacker];
		/*if (Passive[attacker] == 1)
		{
			damage += LastHitDamage[attacker] * LastDamagePercent[attacker];
		}
		else if (isweaponactive[weapon] == true && Passive[attacker] == 0)		//broken, idk why
		{
			damage += LastHitDamage[attacker] * LastDamagePercent[attacker];
		} */
			damage += LastHitDamage[attacker] * LastDamagePercent[attacker];	//cool
	}
	
	if (PanicHit[weapon] == true)
	{
		PanicStocks[attacker] += 1;
		if (PanicStocks[attacker] > MaxPanicStocks[weapon])
		{
			PanicStocks[attacker] = MaxPanicStocks[weapon];
		}
		
		new Float:spread = BaseAccuracyPercent[weapon] - (PanicStocks[attacker] * AccuracyPercent[weapon]);
		new Float:firerate = BaseFireRatePercent[weapon] - (PanicStocks[attacker] * FireRatePercent[weapon]);
		TF2Attrib_RemoveByName(weapon, "fire rate bonus");
		TF2Attrib_RemoveByName(weapon, "spread penalty");
		TF2Attrib_SetByName(weapon, "spread penalty", spread);
		TF2Attrib_SetByName(weapon, "fire rate bonus", firerate);
		PanicResetTrack[weapon] = PanicResetTime[weapon];
		PrintHintText(attacker, "Custom: Stocks: %d", PanicStocks[attacker]);
		
		/*if (String:lastvictim != victim && PanicStocks[weapon] > 0)
		{
			PanicStocks[weapon] = PanicStocks[weapon] * ((MaxPanicStocks[weapon] - 1) / MaxPanicStocks[weapon]);
			PrintHintText(attacker, "Custom: Stocks Reset.");
			EmitSoundToClient(attacker, "weapons/bottle_break.wav");
			
			new Float:spread = BaseAccuracyPercent[weapon] - (PanicStocks[weapon] * AccuracyPercent[weapon]);
			new Float:firerate = BaseFireRatePercent[weapon] - (PanicStocks[weapon] * FireRatePercent[weapon]);			//removed due to obsoleteness
			TF2Attrib_RemoveByName(weapon, "fire rate bonus");
			TF2Attrib_RemoveByName(weapon, "spread penalty");
			TF2Attrib_SetByName(weapon, "spread penalty", spread);
			TF2Attrib_SetByName(weapon, "fire rate bonus", firerate);
		} */
	}
	
	if (SetHealth[weapon] == true)
	{
		damage = 1;
		if (opponent[weapon] == 1)
		{
			SetEntityHealth(attacker, health + ahealth);
			if (over[weapon] == 0)
			{
				SetEntityHealth(attacker, health);
			}
		}
		if (you[weapon] == 1)
		{
			SetEntityHealth(victim, ahealth);
		}
	}
	
	//SetEntityHealth(attacker, health);				used for setting a client's health.

	/*if (ClipSizePercent[weapon] > 0)
	{
		new Float:clipbonus = (BaseClip[weapon] * ClipSizePercent[weapon] * (ClipStocks[weapon] + 1));
		TF2Attrib_SetByName(weapon, "clip size bonus", clipbonus + 1.0);
	}
					PrintHintText(attacker, "Custom: Kills: %d", ClipStocks[weapon]); */
	
	// Return Plugin_Continue if the damage wasn't changed, or Plugin_Changed if it was. Done!
	lastvictim = victim;
	return action;
}
public Action:OnDeath(victim, &weapon, &attacker)
{
	DamageStored[weapon] = 0.0;
	ConditionChargeStored[weapon] - 0.0;
	RechargeTrack[weapon] = RechargeTime[weapon];
	ClipDamageTrack[weapon] = 0.0;
	ClipDamageStocks[weapon] = 0;
	MoveSpeedTrack[victim] = 0.0;
	TotemActive[victim] = true;
	//ClipStocks[weapon] = ClipStocks[weapon] * ClipPreserve[weapon];
	
	/*new weapon1;
		for (new i = 0; i <= 5; i++)
			{
				new Slot = GetPlayerWeaponSlot(attacker, i);
				if (Slot == -1) continue;
				if (HasAttribute[Slot]) continue;
				weapon1 = Slot;
			}
			if (ClipOnKill[weapon1] == true)
			{
				if (ClipStocks[weapon1] < MaxClipStocks[weapon1])
				{
					ClipStocks[weapon1]++;
				}
				if (ClipStocks[weapon1] >= MaxClipStocks[weapon1])
				{
					ClipStocks[weapon1] = MaxClipStocks[weapon1];
				}
			//SetEntityHealth(attacker, health);		Use this for Add Max Health On Kill
			new Float:clipbonus = (BaseClip[weapon1] * ClipSizePercent[weapon1] * ClipStocks[weapon1]);
			TF2Attrib_RemoveByName(weapon1, "clip size bonus");
			TF2Attrib_SetByName(weapon1, "clip size bonus", clipbonus + 1.0);			////////////EVENT_DEATH
			} */
			
	return Plugin_Changed;
}

/*public Action:Event_Death(Handle:event, const String:name[], bool:dontBroadcast)		//Event_Death
//public Action:player_death(victim, &attacker, &inflictor, &Float:damage, &damagetype, &weapon, Float:damageForce[3], Float:damagePosition[3])
{
	new victim = GetClientOfUserId(GetEventInt(event, "userid"));
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	new secondary = GetPlayerWeaponSlot(attacker, 1);
	new melee = GetPlayerWeaponSlot(attacker, 2);
	new bool:feign = bool:(GetEventInt(event, "death_flags") & TF_DEATHFLAG_DEADRINGER);

	{
		new weapon;
		for (new i = 0; i <= 5; i++)
			{
				new Slot = GetPlayerWeaponSlot(attacker, i);
				if (Slot == -1) continue;
				if (HasAttribute[Slot]) continue;
				weapon = Slot;
			}
			if (ClipOnKill[weapon] == true && !feign)
			{
				if (ClipStocks[weapon] < MaxClipStocks[weapon])
				{
					ClipStocks[weapon]++;
					PrintHintText(attacker, "Custom: Kills: %d", ClipStocks[weapon]);
				}
				if (ClipStocks[weapon] >= MaxClipStocks[weapon])
				{
					ClipStocks[weapon] = MaxClipStocks[weapon];
				}
			//SetEntityHealth(attacker, health);		Use this for Add Max Health On Kill
			new Float:clipbonus = (BaseClip[weapon] * ClipSizePercent[weapon] * ClipStocks[weapon]);
			TF2Attrib_RemoveByName(weapon, "clip size bonus");
			TF2Attrib_SetByName(weapon, "clip size bonus", clipbonus + 1.0);			////////////EVENT_DEATH
			}
} */


// We also check AFTER the damage was applied, which you should honestly try to do if your attribute
// is not going to change anything about the damage itself.
// This way, other plugins (and attributes!) can change the damage's information, and you will know.
public OnTakeDamagePost(victim, attacker, inflictor, Float:damage, damagetype, weapon, const Float:damageForce[3], const Float:damagePosition[3])
{
	if (attacker <= 0 || attacker > MaxClients) return;
	if (weapon == -1) return;
	if (!HasAttribute[weapon]) return;
	
	if (CritsIgnite[weapon] && victim > 0 && victim <= MaxClients && damagetype & DMG_CRIT && damage > 0.0)
	{
		TF2_IgnitePlayer(victim, attacker);
	}
	
	if (DamageMax[weapon] != 0 && victim > 0 && victim <= MaxClients)
	{
		if (DamageStored[weapon] < DamageMax[weapon] && DamagePercent[weapon] < 10)
		{
			DamageStored[weapon] += damage * DamagePercent[weapon];
		}
		else if (DamageStored[weapon] < DamageMax[weapon] && DamagePercent[weapon] > 10)
		{
			DamageStored[weapon] += DamagePercent[weapon];
		}
		
		if (DamageStored[weapon] > DamageMax[weapon])
		{
			DamageStored[weapon] = DamageMax[weapon];
		}
	}
	if (DamageCondition[weapon] == true)
	{
		if (DamageDealt[weapon] >= DamageDealtMax[weapon] && victim > 0 && victim <= MaxClients)
		{
			ConditionChargeStored[weapon] += 1;
			DamageDealt[weapon] += DamageDealtMax[weapon] * -1;
			if(ConditionChargeStored[weapon] < ConditionChargeMax[weapon])
			{
				PrintHintText(attacker, "Custom: %d Charges stored!", ConditionChargeStored[weapon]);
			}
			
			else if(ConditionChargeStored[weapon] == ConditionChargeMax[weapon] + 1)
			{
				PrintHintText(attacker, "Custom: %d Charges stored!", ConditionChargeMax[weapon]);
			}
		}
	}
	
	if (TF2_IsPlayerInCondition(attacker, TFCond:(Condition[weapon])))			//TFcond
	{
		DamageDealt[weapon] = 0.0;
	}
	LastHitDamage[attacker] = damage;

}

// Here's where we set the aim punch for "aim punch multiplier" and "aim punch to self".
public Action:Timer_DoAimPunch(Handle:timer, Handle:data)
{
	new client = GetClientOfUserId(ReadPackCell(data));
	if (!client) return;
	if (!IsPlayerAlive(client)) return;
	new weapon = EntRefToEntIndex(ReadPackCell(data));
	if (weapon <= MaxClients) return;
	new bool:self = bool:ReadPackCell(data);
	if (!self)
	{
		new Float:angle[3];
		GetEntPropVector(client, Prop_Send, "m_vecPunchAngle", angle);
		for (new i = 0; i <= 2; i++)
			angle[i] *= AimPunchMultiplier[weapon];
		SetEntPropVector(client, Prop_Send, "m_vecPunchAngle", angle);
	}
	else
	{
		new Float:angle[3];
		angle[0] = AimPunchToSelf[weapon]*-1;
		SetEntPropVector(client, Prop_Send, "m_vecPunchAngle", angle);
	}
}

// In addition to the above damage hooks, we also have TraceAttack, which is done before either of them,
// and also can detect most hits on teammates! Unfortunately, though, it doesn't have as much information as OnTakeDamage.
// Still, it can be really useful. We'll use it here for "speed boost on hit teammate".
public Action:OnTraceAttack(victim, &attacker, &inflictor, &Float:damage, &damagetype, &ammotype, hitbox, hitgroup)
{
	if (attacker <= 0 || attacker > MaxClients) return Plugin_Continue;
	new weapon = GetEntPropEnt(attacker, Prop_Send, "m_hActiveWeapon"); // We have to get the weapon manually, sadly; this also means that
	if (weapon == -1) return Plugin_Continue;								// attributes that use this can only be applied to "hitscan" weapons.
	if (!HasAttribute[weapon]) return Plugin_Continue;
	
		new ahealth = GetClientHealth(attacker);
		new health = GetClientHealth(victim);
	
	if (TeammateSpeedBoost[weapon])
	{
		if (GetClientTeam(attacker) == GetClientTeam(victim))
		{
			// Apply the speed boosts for the amounts of time that the weapon wants.
			TF2_AddCondition(attacker, TFCond_SpeedBuffAlly, TeammateSpeedBoost_User[weapon]);
			TF2_AddCondition(victim, TFCond_SpeedBuffAlly, TeammateSpeedBoost_Teammate[weapon]);
		}
	}
	
	if (SetHealth[weapon] == true)
	{
		if (GetClientTeam(attacker) == GetClientTeam(victim))
		{
			// Apply the speed boosts for the amounts of time that the weapon wants.
			TF2_AddCondition(attacker, TFCond_SpeedBuffAlly, TeammateSpeedBoost_User[weapon]);
			TF2_AddCondition(victim, TFCond_SpeedBuffAlly, TeammateSpeedBoost_Teammate[weapon]);
			damage = 1;
			if (opponent[weapon] == 1)
			{
				SetEntityHealth(attacker, health + ahealth);
				if (over[weapon] == 0)
				{
					SetEntityHealth(attacker, health);
				}
			}
			if (you[weapon] == 1)
			{
				SetEntityHealth(victim, ahealth);
			}
		}
	}
	return Plugin_Continue;
}

// Here's another great thing to track; TF2_CalcIsAttackCritical.
// It's a simple forward (no hooking needed) that fires whenever a client uses a weapon. Very handy!
public Action:TF2_CalcIsAttackCritical(client, weapon, String:weaponname[], &bool:result)
{
	if (!HasAttribute[weapon]) return Plugin_Continue;
	
	if (LookDownAttackVelocity[weapon])
	{
		new Float:ang[3];
		GetClientEyeAngles(client, ang);
		if (ang[0] >= 50.0)
		{
			new Float:vel[3];
			GetEntPropVector(client, Prop_Data, "m_vecVelocity", vel);
			if (vel[2] == 0.0) vel[2] = LookDownAttackVelocity_Start[weapon];
			else vel[2] += LookDownAttackVelocity_Push[weapon];
			
			TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, vel);
		}
	}
	if (AddMetalOnAttack[weapon])
	{
		new metal = GetEntProp(client, Prop_Data, "m_iAmmo", 4, 3);
		metal += AddMetalOnAttack[weapon];
		if (metal < 0) metal = 0;
		if (metal > 200) metal = 200;
		SetEntProp(client, Prop_Data, "m_iAmmo", metal, 4, 3);
	}
	if (AimPunchToSelf[weapon] != 0.0)
	{
		new Handle:data;
		CreateDataTimer(0.0, Timer_DoAimPunch, data, TIMER_FLAG_NO_MAPCHANGE);
		WritePackCell(data, GetClientUserId(client));
		WritePackCell(data, EntIndexToEntRef(weapon));
		WritePackCell(data, true);
		ResetPack(data);
	}
	return Plugin_Continue;
}

// Here's another one, OnPlayerRunCmd. It's called once every frame for every single player.
// You can use it to change around what the client is pressing (like fire/alt-fire) and do other
// precise actions. But it's once every frame (66 times/second), so avoid using expensive things like
// comparing strings or TF2_IsPlayerInCondition!
public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:ang[3], &weapon2)
{
	new weapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	if (weapon <= 0 || weapon > 2048) return Plugin_Continue;
	if (!HasAttribute[weapon]) return Plugin_Continue;
	
	new Action:action;
	if (AddMetalOnAttack[weapon] < 0)
	{
		new required = AddMetalOnAttack[weapon] * -1;
		
		if (required > GetEntProp(client, Prop_Data, "m_iAmmo", 4, 3))
		{
			new Float:nextattack = GetEntPropFloat(weapon, Prop_Send, "m_flNextPrimaryAttack"),
			Float:nextsec = GetEntPropFloat(weapon, Prop_Send, "m_flNextSecondaryAttack"), Float:time = GetGameTime();
			if (nextattack-0.1 <= time) SetEntPropFloat(weapon, Prop_Send, "m_flNextPrimaryAttack", time+0.1);
			if (nextsec-0.1 <= time) SetEntPropFloat(weapon, Prop_Send, "m_flNextSecondaryAttack", time+0.1);
			if (buttons & IN_ATTACK || buttons & IN_ATTACK2)
			{
				buttons &= ~(IN_ATTACK|IN_ATTACK2);
				action = Plugin_Changed;
				if (GetTickedTime() >= NextOutOfAmmoSoundTime[client])
				{
					ClientCommand(client, "playgamesound weapons/shotgun_empty.wav");
					NextOutOfAmmoSoundTime[client] = GetTickedTime() + 0.5;
				}
			}
		}
	}
	if (QuickFix[weapon] == true || UberBuild[weapon] == true)
	{
		if (buttons == IN_ATTACK3)
		{
			if (UberBuild[weapon] == false && HealWait[client] == 0.0)		//activate Uber Build
			{
				UberBuild[weapon] = true;
				QuickFix[weapon] = false;
				TF2Attrib_RemoveByName(weapon, "heal rate penalty");
				TF2Attrib_RemoveByName(weapon, "overheal bonus");
				TF2Attrib_RemoveByName(weapon, "ubercharge rate penalty");
				TF2Attrib_SetByName(weapon, "heal rate penalty", 0.9);
				TF2Attrib_SetByName(weapon, "overheal bonus", 0.75);
				TF2Attrib_SetByName(weapon, "ubercharge rate penalty", 1.5);
				TF2_AddCondition(client, TFCond_SpeedBuffAlly, 0.001);
				HealWait[client] = 0.3;
				EmitSoundToClient(client, "weapons/vaccinator_toggle.wav");
			}
			else if (UberBuild[weapon] == true && HealWait[client] == 0.0)	//activate Quick Fix
			{
				UberBuild[weapon] = false;
				QuickFix[weapon] = true;
				TF2Attrib_RemoveByName(weapon, "heal rate penalty");
				TF2Attrib_RemoveByName(weapon, "overheal bonus");
				TF2Attrib_RemoveByName(weapon, "ubercharge rate penalty");
				TF2Attrib_SetByName(weapon, "heal rate penalty", 1.4);
				TF2Attrib_SetByName(weapon, "overheal bonus", 0.25);
				TF2Attrib_SetByName(weapon, "ubercharge rate penalty", 0.9);
				TF2_AddCondition(client, TFCond_SpeedBuffAlly, 0.001);
				HealWait[client] = 0.3;
				EmitSoundToClient(client, "weapons/vaccinator_toggle.wav");
			}
		}
	}				//Quick-Heal- +40% heal rate, -75% overheal penalty, -10% uber build rate
  	   				//Uber Build- -10% heal rate, -25% overheal penalty, +50% uber build rate
	return action;
}

// If you need to check things like strings or conditions, a repeating-0.1-second timer like this one
// is a much better choice. Though, really, you should try to keep things out of OnGameFrame/OnPlayerRunCmd
// as often as possible. Even if the below "infinite ammo" was being set 66 times a second instead of 10 times,
// client prediction still makes it look like 10 times per second.
public Action:Timer_TenTimesASecond(Handle:timer)
{
	for (new client = 1; client <= MaxClients; client++)
	{
		if (!IsClientInGame(client)) continue;
		if (!IsPlayerAlive(client)) continue;
		new wep = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
		if (wep == -1) continue;
		//if (!HasAttribute[wep]) continue;
		
		new weapon;
		for (new i = 0; i <= 5; i++)
		{
		new j = GetPlayerWeaponSlot(client, i);
		if (j == -1) continue;
		//if (!HasAttribute[j]) continue;
		weapon = j;
		// Doesn't count wearable.
		}
		
		if (InfiniteAmmo[wep])
		{
			SetAmmo_Weapon(wep, InfiniteAmmo[wep]);
		}
		
		if (DamageStored[wep] > DamageMax[wep] / 4)
		{
			DamageStored[wep] += DamageMax[wep] * -0.005;
		}
		
		new bool:PreviousTauntState[2049];
		
		if (PreviousTauntState[client] != TF2_IsPlayerInCondition(client, TFCond_Taunting) && PreviousTauntState[client] == true && ConditionChargeStored[weapon] != 0)
		{
			ConditionChargeStored[weapon] = 0;
		}
		
		if (TF2_IsPlayerInCondition(client, TFCond_Taunting) == true && TF2_IsPlayerInCondition(client, TFCond:Condition[weapon]) == true)
		{
			TF2_AddCondition(client, TFCond:Condition[weapon], ConditionDuration[weapon]);
			if(Condition1[weapon] != -1)
				{TF2_AddCondition(client, TFCond:Condition1[weapon], ConditionDuration[weapon]);}
			if(Condition2[weapon] != -1)
				{TF2_AddCondition(client, TFCond:Condition2[weapon], ConditionDuration[weapon]);}
			if(Condition3[weapon] != -1)
				{TF2_AddCondition(client, TFCond:Condition3[weapon], ConditionDuration[weapon]);}
			TF2_AddCondition(client, TFCond:51, 0.2);
		}
		
		if(DamageCondition[weapon] != false)
		{
			if (TF2_IsPlayerInCondition(client, TFCond_Taunting))
			{
				if(ConditionChargeStored[weapon] > 0)
				{
				TF2_AddCondition(client, TFCond:Condition[weapon], ConditionDuration[weapon] * ConditionChargeStored[weapon]);
				if(Condition1[weapon] != -1)
					{TF2_AddCondition(client, TFCond:Condition1[weapon], ConditionDuration[weapon] * ConditionChargeStored[weapon]);}
				if(Condition2[weapon] != -1)
					{TF2_AddCondition(client, TFCond:Condition2[weapon], ConditionDuration[weapon] * ConditionChargeStored[weapon]);}
				if(Condition3[weapon] != -1)
					{TF2_AddCondition(client, TFCond:Condition3[weapon], ConditionDuration[weapon] * ConditionChargeStored[weapon]);}
				TF2_AddCondition(client, TFCond:51, 0.2);
				PrintHintText(client, "Custom: -Using Charge-");
				}
			if (TF2_IsPlayerInCondition(client, TFCond:Condition[weapon]) != false)
			{
					ConditionChargeStored[weapon] = 0;
			}
			}
			if (Seconds == 0.5)
			{
				PrintHintText(client, "Custom: Charges: %d", ConditionChargeStored[weapon]);
			}
		}
		
		if (PreviousTauntState[client] != TF2_IsPlayerInCondition(client, TFCond_Taunting) && PreviousTauntState[client] == true && RechargeTrack[weapon] >= RechargeTime[weapon])
		{
			RechargeTrack[weapon] = 0.0;
		}
		
		if (TF2_IsPlayerInCondition(client, TFCond_Taunting) == true && TF2_IsPlayerInCondition(client, TFCond:RechargeCondition[weapon]) == true)
		{
			TF2_AddCondition(client, TFCond:RechargeCondition[weapon], RechargeConditionDuration[weapon]);
			if(RechargeCondition1[weapon] != -1)
				{TF2_AddCondition(client, TFCond:RechargeCondition1[weapon], RechargeConditionDuration[weapon]);}
			if(RechargeCondition2[weapon] != -1)
				{TF2_AddCondition(client, TFCond:RechargeCondition2[weapon], RechargeConditionDuration[weapon]);}
			if(RechargeCondition3[weapon] != -1)
				{TF2_AddCondition(client, TFCond:RechargeCondition3[weapon], RechargeConditionDuration[weapon]);}
			TF2_AddCondition(client, TFCond:51, 0.2);
		}
		
		if(RechargeConditionApplied[weapon] != false)
		{
			if (TF2_IsPlayerInCondition(client, TFCond_Taunting))
			{
				if(RechargeTrack[weapon] >= RechargeTime[weapon])
				{
				TF2_AddCondition(client, TFCond:RechargeCondition[weapon], RechargeConditionDuration[weapon]);
				if(RechargeCondition1[weapon] != -1)
					{TF2_AddCondition(client, TFCond:RechargeCondition1[weapon], RechargeConditionDuration[weapon]);}
				if(RechargeCondition2[weapon] != -1)
					{TF2_AddCondition(client, TFCond:RechargeCondition2[weapon], RechargeConditionDuration[weapon]);}
				if(RechargeCondition3[weapon] != -1)
					{TF2_AddCondition(client, TFCond:RechargeCondition3[weapon], RechargeConditionDuration[weapon]);}
				TF2_AddCondition(client, TFCond:51, 0.2);
				PrintHintText(client, "Custom: -Using Charge-");
				}
			}
			if (TF2_IsPlayerInCondition(client, TFCond:RechargeCondition[weapon]) != false)
			{
					RechargeTrack[weapon] = 0.0;
			}
			else if (TF2_IsPlayerInCondition(client, TFCond:RechargeCondition[weapon]) != true)
			{
					RechargeTrack[weapon] += 0.1;
			}
			if(RechargeTrack[weapon] >= RechargeTime[weapon])
			{
				RechargeTrack[weapon] = RechargeTime[weapon];
			}
			if (Seconds == 0.5)
			{
				if(RechargeTrack[weapon] >= RechargeTime[weapon])
				{
					PrintHintText(client, "Custom: Charge Ready");
				}
			}
		}
		
		Seconds += 0.1;
		if (Seconds > 1) {Seconds = 0.0;}
		
		PreviousTauntState[client] = (TF2_IsPlayerInCondition(client, TFCond_Taunting));
		
		if (ConditionChargeStored[weapon] > ConditionChargeMax[weapon]) 
		{
			ConditionChargeStored[weapon] = ConditionChargeMax[weapon];
		}
		
		//use GetPlayerWeaponSlot(attacker) for "dawn speed"
		if (MoveSpeed[weapon] == true)
		{
		MoveSpeedTrack[client] += (MoveSpeedPercent[weapon] * 0.1);
			if (MoveSpeedTrack[client] >= MoveSpeedMax[weapon] && MoveSpeedMax[weapon] + 1 > BaseMoveSpeed[client])
			{
				if (Seconds == 0.2)
				{
				MoveSpeedTrack[client] = MoveSpeedMax[weapon];
				PrintHintText(client, "Custom: Max speed bonus reached.");
				}
			}
			if (MoveSpeedTrack[client] <= MoveSpeedMax[weapon] && MoveSpeedMax[weapon] + 1 <= BaseMoveSpeed[client])
			{
				if (Seconds == 0.2)
				{
				MoveSpeedTrack[client] = MoveSpeedMax[weapon];
				PrintHintText(client, "Custom: Max speed penalty reached.");
				}
			}
		//weaponslot[client] = 0;
		weaponslot[client] = weapon;
		new Float:speedbonus = (MoveSpeedTrack[client]);
		TF2Attrib_RemoveByName(weapon, "move speed bonus");
		TF2Attrib_SetByName(weapon, "move speed bonus", (BaseMoveSpeed[client] + speedbonus));
		//weaponslot[client] = GetPlayerWeaponSlot(client, slot);
		
			if (lastweapon[client] != weaponslot[client])
			{
			MoveSpeedTrack[client] = 0.0;
			TF2Attrib_RemoveByName(weapon, "move speed bonus");
			TF2Attrib_SetByName(weapon, "move speed bonus", BaseMoveSpeed[client]);
			}
		}
		if (MoveSpeed[weapon] == false)
		{
			MoveSpeedTrack[client] = 0.0;
			if (BaseMoveSpeed[client] != 0)
			{
				TF2Attrib_RemoveByName(weapon, "move speed bonus");
				TF2Attrib_SetByName(weapon, "move speed bonus", BaseMoveSpeed[client]);
			}
		}
		
		if (weapon != weaponslot[client])
		{
		MoveSpeedTrack[client] = 0.0;
		if (MoveSpeed[weaponslot[client]] == true)
			{
			TF2Attrib_RemoveByName(weapon, "move speed bonus");
			TF2Attrib_SetByName(weapon, "move speed bonus", BaseMoveSpeed[client]);
			}
		}
		
		/*if (QuickFix[weapon] == true)		//zethax start
			{
				SetHudTextParams(0.04, 0.37, 1.0, 255, 50, 50, 255);								//This stuff is for my own use, for hud display.
				ShowSyncHudText(client, hudText_SecWeapon, "Heal Mode: Quick-Fix");			//Credit goes to Zethax for this origional code segment.
			}
			else if(UberBuild[weapon] == true)
			{
				SetHudTextParams(0.04, 0.37, 1.0, 255, 50, 50, 255);
				ShowSyncHudText(client, hudText_SecWeapon, "Heal Mode: Uber Build");
			}								//zethax end */
		
		if (HealWait[client] > 0.0)
		{
			HealWait[client] += -0.1;
		}
		lastweapon[client] = weapon;
		
		if (TimeTracker[client] > 0.0)
		{
			TimeTracker[client] += -0.1;
		}
		if (TimeTracker[client] <= 0.0)
		{
			LastHitDamage[client] = 0.0;
		}
		if (PanicResetTrack[client] > 0.0)
		{
			PanicResetTrack[client] += -0.1;
		}
		if (PanicResetTrack[client] <= 0.0)
		{
			PanicStocks[client] = 0;
		}
	}
}

/*public OnClientPreThink(client)
{
	new button = GetClientButtons(client);
} */

		
		/*if (slot1 == 0)
		{
			MoveSpeedTrack[weaponslot[client]] = 0.0;			//This line is the one being referred to.
			if (MoveSpeed[weaponslot[client]] == true)
			{
				TF2Attrib_RemoveByName(client, "move speed bonus");
				TF2Attrib_SetByName(client, "move speed bonus", BaseMoveSpeed[weaponslot[client]]);
			}
																//Confusing first line. we want to our weapon's MoveSpeedTrack to a different number, when the weapon is not active.
																//So we set a variable in the previous if statement to be that of the current weapon slot, which at the time would be our custom weapon's.
																//Basically, "weaponslot[client]" is just the previous "weapon."
		} */

// Once a weapon entity has been "destroyed", it's been unequipped.
// Unfortunately, that also means that we need to reset all of its variables.
// If you don't, really bad things will happen to the next weapon that occupies that entity slot,
// custom or not!
public OnEntityDestroyed(Ent)
{
	if (Ent <= 0 || Ent > 2048) return;
	HasAttribute[Ent] = false;
	TeammateSpeedBoost[Ent] = true;
	TeammateSpeedBoost_User[Ent] = 0.0;
	TeammateSpeedBoost_Teammate[Ent] = 0.0;
	AimPunchMultiplier[Ent] = 1.0;
	LookDownAttackVelocity[Ent] = false;
	LookDownAttackVelocity_Start[Ent] = 0.0;
	LookDownAttackVelocity_Push[Ent] = 0.0;
	AddMetalOnAttack[Ent] = 0;
	InfiniteAmmo[Ent] = 0;
	AimPunchToSelf[Ent] = 0.0;
	CritsIgnite[Ent] = false;
	CritDamage[Ent] = 1.0;
	LowDamageMult[Ent] = 1.0;
	HighDamageMult[Ent] = 1.0;
	DamageThresholdHigh[Ent] = 0.0;
	DamageThresholdLow[Ent] = 0.0;
	StaticDamage[Ent] = -1.0;
	DamageBuild[Ent] = false;
	DamagePercent[Ent] = 0.0;
	DamageMax[Ent] = 0.0;
	DamageStored[Ent] = 0.0;
	DamageMod[Ent] = 0;
	DamageDealt[Ent] = 0.0;
	DamageCondition[Ent] = false;
	Condition[Ent] = -1;
	ConditionDuration[Ent] = 0.0;
	DamageDealtMax[Ent] = 0.0;
	Condition1[Ent] = -1;
	Condition2[Ent] = -1;
	Condition3[Ent] = -1;
	ConditionChargeStored[Ent] = 0;
	ConditionChargeMax[Ent] = 0;
	RechargeCondition[Ent] = -1;
	RechargeCondition1[Ent] = -1;
	RechargeCondition2[Ent] = -1;
	RechargeCondition3[Ent] = -1;
	Float:RechargeTime[Ent] = -1.0;
	Float:RechargeConditionDuration[Ent] = 0.0;
	Float:RechargeTrack[Ent] = 0.0;
	bool:RechargeConditionApplied[Ent] = false;
	/*bool:ClipOnKill[Ent] = false;
	Float:ClipPreserve[Ent] = 0.0;
	Float:ClipSizePercent[Ent] = 0.0;
	ClipStocks[Ent] = 0;
	MaxClipStocks[Ent] = 0;
	Float:BaseClip[Ent] = 0.0; */
	ClipDamageStocks[Ent] = 0;
	ClipDamageStocksMax[Ent] = 0;
	Float:ClipPercentAdd[Ent] = 0.0;
	Float:BaseClipPercent[Ent] = 0.0;
	Float:ClipDamageTrack[Ent] = 0.0;
	Float:ClipDamageMax[Ent] = 0.0;
	bool:ClipDamage[Ent] = false;
	Float:BaseAmmoPercent[Ent] = 0.0;
	Float:AmmoPercentAdd[Ent] = 0.0;
	HealthAdd[Ent] = 0;
	HealthDamageStocks[Ent] = 0;
	HealthDamageStocksMax[Ent] = 0;
	Float:HealthDamageMax[Ent] = 0.0;
	Float:HealthDamageTrack[Ent] = 0.0;
	bool:HitDamage[Ent] = false;
	Float:HitDamagePercent[Ent] = 0.0;
	MaxHitDamageStocks[Ent] = 0;
	HitDamageStocks[Ent] = 0;
	Float:BaseDamagePercent[Ent] = 0.0;
	bool:MoveSpeed[Ent] = false;
	Float:MoveSpeedMax[Ent] = 0.0;
	Float:MoveSpeedPercent[Ent] = 0.0;
	Float:MoveSpeedLost[Ent] = 0.0;
	Float:MoveSpeedTrack[Ent] = 0.0;
	Float:BaseMoveSpeed[Ent] = 0.0;
	bool:QuickFix[Ent] = true;
	bool:UberBuild[Ent] = false;
	Float:HealWait[Ent] = 0.0;
	MaxHealthTotem[Ent] = 0;
	bool:TotemActive[Ent] = false;
	bool:Totem[Ent] = false;
	Float:PercentHealth[Ent] = 0.0;
}

stock SetAmmo_Weapon(weapon, newAmmo)
{
	new owner = GetEntPropEnt(weapon, Prop_Send, "m_hOwnerEntity");
	if (owner == -1) return;
	new iOffset = GetEntProp(weapon, Prop_Send, "m_iPrimaryAmmoType", 1)*4;
	new iAmmoTable = FindSendPropInfo("CTFPlayer", "m_iAmmo");
	SetEntData(owner, iAmmoTable+iOffset, newAmmo, 4, true);
}