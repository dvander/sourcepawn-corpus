/*
 * ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
 * 
 *  HurtEffects by Furibaito
 *
 *  hurtfx.sp - Source file
 *
 * ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
 */

// Basic includes
#include <sourcemod> 
#pragma semicolon 1 

// Plugin information
#define PLUGIN_VERSION "1.3b" 
#define DESC "Provides screen fading and shaking effects when got hurt configurable based from damage or headshot" 

// Fade defines
#define FFADE_IN		0x0001
#define FFADE_OUT		0x0002
#define FFADE_PURGE		0x0010

public Plugin:myinfo =
{
	name = "HurtEffects",
	author = "Furibaito",
	description = DESC,
	version = PLUGIN_VERSION,
	url = ""
};

// Create CVar Handles
new Handle:hEnable;
new Handle:hFadeMode;
new Handle:hShakeMode;
new Handle:hDisableTeam;
new Handle:hDisableWorld;
new Handle:hFadePower;
new Handle:hShakePower;

// Create CVar Variables
new Enable;
new FadeMode;
new ShakeMode;
new DisableTeam;
new DisableWorld;
new Float:FadePower;
new Float:ShakePower;

// Create UserMsg variable
new UserMsg:g_FadeUserMsgId;
new UserMsg:g_ShakeUserMsgId;

public OnPluginStart()
{
	// Hook event
	HookEvent("player_hurt", PlayerHurt);
	
	// Assign ConVars to the Handles
	CreateConVar("hfx_version", PLUGIN_VERSION, DESC, FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_UNLOGGED|FCVAR_DONTRECORD|FCVAR_REPLICATED|FCVAR_NOTIFY);
	hEnable = CreateConVar("hfx_enable", "1", "Enable/Disable this plugin");
	hFadeMode = CreateConVar("hfx_fade_mode", "1", "Set the fade effect mode | 1 = Always fade when hurt | 2 = Fade on headshot only | 3 = Fade on HE damage | 4 = Headshot and HE only | 0 to disable fade effects");
	hShakeMode = CreateConVar("hfx_shake_mode", "4", "Set the shake effect mode | 1 = Always fade when hurt | 2 = Fade on headshot only | 3 = Fade on HE damage | 4 = Headshot and HE only | 0 to disable shake effects");
	hDisableTeam = CreateConVar("hfx_disable_team", "0", "Disable the effects on CT/T ( T=2 , CT=3, 0 to enable all team )");
	hDisableWorld = CreateConVar("hfx_disable_world_damage", "0", "Disable the hurt effects on world damage");
	hFadePower = CreateConVar("hfx_fade_power", "1.0", "Scales the fade effect, 1.0 = Normal , 2.0 = 2 x Stronger fade, etc");
	hShakePower = CreateConVar("hfx_shake_power", "1.0", "Scales the shake effect, 1.0 = Normal , 2.0 = 2 x Stronger shake, etc");
	
	// Assign value to the CVars variables
	Enable = GetConVarInt(hEnable);
	FadeMode = GetConVarInt(hFadeMode);
	ShakeMode = GetConVarInt(hShakeMode);
	DisableTeam = GetConVarInt(hDisableTeam);
	DisableWorld = GetConVarInt(hDisableWorld);
	FadePower = GetConVarFloat(hFadePower);
	ShakePower = GetConVarFloat(hShakePower);
	
	// Assign the UserMsg
	g_FadeUserMsgId = GetUserMessageId("Fade");
	g_ShakeUserMsgId = GetUserMessageId("Shake");
}

// When the player is hurt
public PlayerHurt(Handle:event, const String:name[], bool:dontBroadcast)
{
	// Check if the plugin is enabled
	if (Enable)
	{
		// Get the attacker Index
		new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
		
		// If world damage is allowed, or world damage is blocked but the attacker isn't from the world, continue
		if (!DisableWorld || (DisableWorld && (attacker != 0)))
		{
			// Get the client index and his team
			new client = GetClientOfUserId(GetEventInt(event, "userid"));
			new team = GetClientTeam(client);
			
			// If the team that is disabled for the effects isn't the same as the client team, continue
			if (DisableTeam != team)
			{
				// Get the damage value
				new RealDamage = GetEventInt(event, "dmg_health");
				
				// Create the variable that determines how strong the fade/shake effect is
				new FXDamage;
				
				// Set the cap of damage to 50 so the fade isn't that distruptive
				// If the damage is more that 50, set the power to 50, otherwise the damage is equal to the power
				if (RealDamage >= 50)
				{
					FXDamage = 50;
				}
				
				else
				{
					FXDamage = RealDamage;
				}
				
				// If the Fade Mode setting is 1 (Always fade) proceed to fade the client
				if (FadeMode == 1)
				{
					Fade(client, FXDamage);
				}
				
				// If the fade mode is not 1
				else
				{
					// Check if the shot is headshot | Hitgroup = 1 is HEADSHOT
					new HitGroup = GetEventInt(event, "hitgroup");
					
					// Get the weapon of the attacker
					new String:Weapon[16];
					GetEventString(event, "weapon", Weapon, sizeof(Weapon));
					
					// Now we got the weapon and hitgroup information
					// Proceed to the switch
					switch (FadeMode)
					{
						case 2:
						{
							// Check if the hitbox is Headshot (1)
							if (HitGroup == 1)
							{
								Fade(client, FXDamage);
							}
						}
						
						case 3:
						{
							// Check if the weapon is grenade
							if (StrEqual(Weapon, "hegrenade", false))
							{
								Fade(client, FXDamage);
							}
						}
						
						case 4:
						{
							// Check if the hitbox is headshot OR the weapon is grenade
							if (HitGroup == 1 || StrEqual(Weapon, "hegrenade", false))
							{
								Fade(client, FXDamage);
							}
						}
						
						default:
						{
							return;
						}
					}
				}
				
				// If the Shake Mode setting is 1 (Always shake) proceed to shake the client
				if (ShakeMode == 1)
				{
					Shake(client, FXDamage);
				}
				
				// If the shake mode is not 1
				else
				{
					// Check if the shot is headshot | Hitgroup = 1 is HEADSHOT
					new HitGroup = GetEventInt(event, "hitgroup");
					
					// Get the weapon of the attacker
					new String:Weapon[16];
					GetEventString(event, "weapon", Weapon, sizeof(Weapon));
					
					// Now we got the weapon and hitgroup information
					// Proceed to the switch
					switch (ShakeMode)
					{
						case 2:
						{
							// Check if the hitbox is Headshot (1)
							if (HitGroup == 1)
							{
								Shake(client, FXDamage);
							}
						}
						
						case 3:
						{
							// Check if the weapon is grenade
							if (StrEqual(Weapon, "hegrenade", false))
							{
								Shake(client, FXDamage);
							}
						}
						
						case 4:
						{
							// Check if the hitbox is headshot OR the weapon is grenade
							if (HitGroup == 1 || StrEqual(Weapon, "hegrenade", false))
							{
								Shake(client, FXDamage);
							}
						}
						
						default:
						{
							return;
						}
					}
				}
			}
		}
	}
}

Fade(client, Damage)
{
	// This method need to put the client inside an array
	new clients[2];
	clients[0] = client;
	
	// Create the MessageFade handle
	new Handle:message = StartMessageEx(g_FadeUserMsgId, clients, 1);
	
	// Message is valid
	if (message != INVALID_HANDLE)
	{
		// Get length of the fade
		new Length = (Damage * 10);
		
		// Get the alpha of the fade
		new Alpha = RoundToNearest(Damage * FadePower);
		if (Alpha > 255)
			Alpha = 255;
		
		// If the game is CS:GO or DOTA 2
		if (GetFeatureStatus(FeatureType_Native, "GetUserMessageType") == FeatureStatus_Available && GetUserMessageType() == UM_Protobuf)
		{
			new Color[4];
			Color[0] = 255;
			Color[1] = 0;
			Color[2] = 0;
			Color[3] = Alpha;
			PbSetInt(message, "duration", Length);
			PbSetInt(message, "hold_time", Length);
			PbSetInt(message, "flags", FFADE_IN);
			PbSetColor(message, "clr", Color);
		}
		
		// Other game than those 2
		else
		{
			BfWriteShort(message, Length);	// FIXED 16 bit, with SCREENFADE_FRACBITS fractional, milliseconds duration
			BfWriteShort(message, Length);	// FIXED 16 bit, with SCREENFADE_FRACBITS fractional, milliseconds duration until reset (fade & hold)
			BfWriteShort(message, FFADE_IN); // fade type (in / out)
			BfWriteByte(message, 255);	// fade red
			BfWriteByte(message, 0);	// fade green
			BfWriteByte(message, 0);	// fade blue
			BfWriteByte(message, Alpha);// fade alpha
		}
		EndMessage();
	}
}

Shake(client, Damage)
{
	new Float:flDamage = float(Damage);
	new Handle:ShakeData;
	CreateDataTimer(0.0, ExecShake, ShakeData);
	WritePackCell(ShakeData, client);
	WritePackFloat(ShakeData, flDamage);
}

public Action:ExecShake(Handle:timer, Handle:pack)
{
	new client;
	new Float:Damage;
	
	ResetPack(pack);
	client = ReadPackCell(pack);
	Damage = ReadPackFloat(pack);
	
	// This method need to put the client inside an array
	new clients[2];
	clients[0] = client;
	
	// Get the length
	new Float:Length = (Damage / 50.0);
	
	// Get the amplitude
	new Float:Amplitude = (Damage / 7.0 * ShakePower);
	
	// Create the shake message handle
	new Handle:message = StartMessageEx(g_ShakeUserMsgId, clients, 1);
	
	if (message !=INVALID_HANDLE)
	{
		// If the game is CS:GO or DOTA 2
		if (GetFeatureStatus(FeatureType_Native, "GetUserMessageType") == FeatureStatus_Available && GetUserMessageType() == UM_Protobuf)
		{
			PbSetInt(message,   "command", 0);
			PbSetFloat(message, "local_amplitude", Amplitude);
			PbSetFloat(message, "frequency", 1.0);
			PbSetFloat(message, "duration", Length);
		}
		
		// Other games
		else
		{
			BfWriteByte(message,  0);
			BfWriteFloat(message, Amplitude);
			BfWriteFloat(message, 1.0);
			BfWriteFloat(message, Length);
		}
		EndMessage();
	}
}
