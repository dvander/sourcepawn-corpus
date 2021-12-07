/*
 * ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
 * 
 *  HurtEffects by Furibaito
 *
 *  hurtfx.sp - Source file
 *
 * ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
 */

#include <sourcemod> // Must include
#pragma semicolon 1 // I don't know what this does but still MUST include

#define PLUGIN_VERSION "1.1" // This is the version of the plugin
#define DESC "Provides screen fading and shaking effects when got hurt configurable based from damage or headshot" 

#define FFADE_IN		0x0001		// Fade In
#define FFADE_OUT		0x0002		// Fade out
#define FFADE_PURGE		0x0010		// Purges all other fades, replacing them with this one

public Plugin:myinfo =
{
	name = "HurtEffects",
	author = "Furibaito", // Yes
	description = DESC,
	version = PLUGIN_VERSION,
	url = "" // ......
};

new Handle:g_hEnable;
new Handle:g_hFadeMode;
new Handle:g_hShakeMode;
new Handle:g_hDisableTeam;
new Handle:g_hDisableWorld;
new Handle:g_hFadePower;
new Handle:g_hShakePower;

public OnPluginStart()
{
	HookEvent("player_hurt", PlayerHurt);
	CreateConVar("hfx_version", PLUGIN_VERSION, DESC, FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_UNLOGGED|FCVAR_DONTRECORD|FCVAR_REPLICATED|FCVAR_NOTIFY);
	g_hEnable = CreateConVar("hfx_enable", "1", "Enable/Disable this plugin"); // Plugin is disable-able it's looks professional
	g_hFadeMode = CreateConVar("hfx_fade_mode", "1", "Set the fade effect mode | 1 = Always fade when hurt | 2 = Fade on headshot only | 3 = Fade on HE damage | 4 = Headshot and HE only | 0 to disable fade effects");
	g_hShakeMode = CreateConVar("hfx_shake_mode", "4", "Set the shake effect mode | 1 = Always fade when hurt | 2 = Fade on headshot only | 3 = Fade on HE damage | 4 = Headshot and HE only | 0 to disable shake effects");
	g_hDisableTeam = CreateConVar("hfx_disable_team", "0", "Disable the effects on CT/T ( T=2 , CT=3, 0 to enable all team )");
	g_hDisableWorld = CreateConVar("hfx_disable_world_damage", "0", "Disable the hurt effects on world damage");
	g_hFadePower = CreateConVar("hfx_fade_power", "1.0", "Scales the fade effect, 1.0 = Normal , 2.0 = 2 x Stronger fade, etc");
	g_hShakePower = CreateConVar("hfx_shake_power", "1.0", "Scales the shake effect, 1.0 = Normal , 2.0 = 2 x Stronger shake, etc");
}

public Action:PlayerHurt(Handle:event, const String:name[], bool:dontBroadcast)
{
	new hEnable = GetConVarInt(g_hEnable);
	new hFadeMode = GetConVarInt(g_hFadeMode);
	new hShakeMode = GetConVarInt(g_hShakeMode);
	new hDisableTeam = GetConVarInt(g_hDisableTeam);
	new hDisableWorld = GetConVarInt(g_hDisableWorld);
	
	if (!hEnable)
	{
		return;
	}
	
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	new dmg = GetEventInt(event, "dmg_health");
	new Damage;
	
	if (dmg >= 30)
	{
		Damage = 30;
	}
	
	if (dmg < 30)
	{
		Damage = dmg;
	}
	
	new Team = GetClientTeam(client);
	if (hDisableTeam != 0)
	{
		if (hDisableTeam == Team)
		{
			return;
		}
	}
	
	new x = GetEventInt(event, "hitgroup");
	new Headshot; 
	if (x == 1)
	{
		Headshot = 1;
	}
	
	if (hDisableWorld != 0)
	{
		if (attacker == 0)
		{
			return;
		}
	}
	
	new String:Weapon[16];
	GetEventString(event, "weapon", Weapon, sizeof(Weapon));
	
	if (hFadeMode == 1)
	{
		Fade(client, Damage);
	}
	
	if (hFadeMode == 2)
	{
		if (Headshot)
		{
			Fade(client, Damage);
		}
	}
	
	if (hFadeMode == 3)
	{
		
		
		if (StrEqual(Weapon, "hegrenade"))
		{
			Fade(client, Damage);
		}
	}
	
	if (hFadeMode == 4)
	{
		
		
		if (Headshot || StrEqual(Weapon, "hegrenade"))
		{
			Fade(client, Damage);
		}
	}
	
	new Float:flDamage = GetEventFloat(event, "dmg_health");
	
	if (hShakeMode == 1)
	{
		
		
		Shake(client, flDamage);
	}
	
	if (hShakeMode == 2)
	{
		if (Headshot)
		{
			Shake(client, flDamage);
		}
	}
	
	if (hShakeMode == 3)
	{
		if (StrEqual(Weapon, "hegrenade"))
		{
			Shake(client, flDamage);
		}
	}
	
	if (hShakeMode == 4)
	{
		if (Headshot || StrEqual(Weapon, "hegrenade"))
		{
			Shake(client, flDamage);
		}
	}
	
	else
	{
		return;
	}
}

stock Fade(client, Damage)
{
	new Handle:hFadeClient = StartMessageOne("Fade", client);
	if (hFadeClient !=INVALID_HANDLE)
	{
		new length = (Damage * 20);
		new Float:FadePower = GetConVarFloat(g_hFadePower);
		new red = RoundToNearest(Damage * 10.0 * FadePower);
		if (red > 255)
		{
			red = 255;
		}
		
		new alpha = RoundToNearest(Damage * FadePower * 2.0);
		if (alpha > 255)
		{
			alpha = 255;
		}
		BfWriteShort(hFadeClient, length);	// FIXED 16 bit, with SCREENFADE_FRACBITS fractional, milliseconds duration
		BfWriteShort(hFadeClient, 0);	// FIXED 16 bit, with SCREENFADE_FRACBITS fractional, milliseconds duration until reset (fade & hold)
		BfWriteShort(hFadeClient,FFADE_IN); // fade type (in / out)
		BfWriteByte(hFadeClient, red);	// fade red
		BfWriteByte(hFadeClient, 0);	// fade green
		BfWriteByte(hFadeClient, 0);	// fade blue
		BfWriteByte(hFadeClient, alpha);// fade alpha
		EndMessage();
	}
}

stock Shake(client, Float:dmg)
{
	new Float:length = (dmg / 50);
	new Float:ShakePower = GetConVarFloat(g_hShakePower);
	new Float:shk = (dmg / 7 * ShakePower);
	new Handle:hShake = StartMessageOne("Shake", client);
	if (hShake !=INVALID_HANDLE)
	{
		BfWriteByte(hShake,  0);
		BfWriteFloat(hShake, shk);
		BfWriteFloat(hShake, 1.0);
		BfWriteFloat(hShake, length);
		EndMessage();
	}
}
