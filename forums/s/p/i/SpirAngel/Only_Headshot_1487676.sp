#pragma semicolon 1
#include <sourcemod>
#include <sdkhooks>
#include <sdktools>
#define VERSION "1.4"

public Plugin:myinfo=
{
	name="Only Headshot",
	author="Spir",
	description="Plugin that allows only headshots. Also, ability to allow HE and knife killings and to disable world damages !",
	version=VERSION,
	url="http://www.dowteam.com/"
};

new String:language[4];
new String:languagecode[4];
new String:headsounds[5][256];
new soundsfound;
new bool:p_enabled;
new bool:p_allowknife;
new bool:p_allowhe;
new bool:p_allowworld;
new bool:p_squishysounds;
new bool:p_soundtoall;
new Handle:p_Cvarenabled = INVALID_HANDLE;
new Handle:p_Cvarallowknife = INVALID_HANDLE;
new Handle:p_Cvarallowhe = INVALID_HANDLE;
new Handle:p_Cvarallowworld = INVALID_HANDLE;
new Handle:p_Cvarsquishysounds = INVALID_HANDLE;
new Handle:p_Cvarsoundtoall = INVALID_HANDLE;
new g_iHealth, g_Armor;

public OnPluginStart()
{
	LoadTranslations("onlyheadshot.phrases");
	GetLanguageInfo(GetServerLanguage(), languagecode, sizeof(languagecode), language, sizeof(language));
	CreateConVar("sm_onlyhs_version", VERSION, "Only Headshot", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	p_Cvarenabled = CreateConVar("sm_onlyhs_enable", "1", "Enable this plugin. 0 = Disabled.");
	p_Cvarallowknife = CreateConVar("sm_onlyhs_knife", "1", "Enable Knifings. 0 = Disabled.");
	p_Cvarallowhe = CreateConVar("sm_onlyhs_he", "1", "Enable HE Killing. 0 = Disabled.");
	p_Cvarallowworld = CreateConVar("sm_onlyhs_world", "1", "Enable World Damages. 0 = Disabled.");
	p_Cvarsquishysounds = CreateConVar("sm_onlyhs_squishysound", "0", "Enable Squishy sounds when HS. 0 = Disabled.");
	p_Cvarsoundtoall = CreateConVar("sm_onlyhs_soundtoall", "0", "Emit squishy sound to everybody. 0 = Disabled.");
	
	
	HookEvent("player_hurt", EventPlayerHurt, EventHookMode_Pre);
	
	HookConVarChange(p_Cvarenabled, OnSettingChanged);
	HookConVarChange(p_Cvarallowknife, OnSettingChanged);
	HookConVarChange(p_Cvarallowhe, OnSettingChanged);
	HookConVarChange(p_Cvarallowworld, OnSettingChanged);
	HookConVarChange(p_Cvarsquishysounds, OnSettingChanged);
	HookConVarChange(p_Cvarsoundtoall, OnSettingChanged);
	AutoExecConfig(true, "onlyhs");
	
	g_iHealth = FindSendPropOffs("CCSPlayer", "m_iHealth");
	
	if (g_iHealth == -1)
	{
		SetFailState("[Only Headshot] Error - Unable to get offset for CSSPlayer::m_iHealth");
	}

	g_Armor = FindSendPropOffs("CCSPlayer", "m_ArmorValue");
  
	if (g_Armor == -1)
	{
		SetFailState("[Only Headshot] Error - Unable to get offset for CSSPlayer::m_ArmorValue");
	}	
}
	
public OnConfigsExecuted()
{
	p_enabled = GetConVarBool(p_Cvarenabled);
	p_allowknife = GetConVarBool(p_Cvarallowknife);
	p_allowhe = GetConVarBool(p_Cvarallowhe);
	p_allowworld = GetConVarBool(p_Cvarallowhe);
	p_squishysounds = GetConVarBool(p_Cvarallowhe);
	p_soundtoall = GetConVarBool(p_Cvarallowhe);
	
	soundsfound = 5;
	headsounds[0] = "physics/flesh/flesh_squishy_impact_hard1.wav";
	headsounds[1] = "physics/flesh/flesh_squishy_impact_hard2.wav";
	headsounds[2] = "physics/flesh/flesh_squishy_impact_hard3.wav";
	headsounds[3] = "physics/flesh/flesh_squishy_impact_hard4.wav";
	headsounds[4] = "physics/flesh/flesh_bloody_break.wav";
	PrecacheSound(headsounds[0], true);
	PrecacheSound(headsounds[1], true);
	PrecacheSound(headsounds[2], true);
	PrecacheSound(headsounds[3], true);
	PrecacheSound(headsounds[4], true);
}

public OnSettingChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if (convar == p_Cvarenabled)
	{
		if (newValue[0] == '1')
		{
			p_enabled = true;
			PrintToChatAll("%t", "Headshot enabled");
		}
		else
		{
			p_enabled = false;
			PrintToChatAll("%t", "Headshot disabled");
		}
	}
	if (convar == p_Cvarallowknife)
	{
		if (newValue[0] == '1')
		{
			p_allowknife = true;
			PrintToChatAll("%t", "Knifing enabled");
		}
		else
		{
			p_allowknife = false;
			PrintToChatAll("%t", "Knifing disabled");
		}
	}
	if (convar == p_Cvarallowhe)
	{
		if (newValue[0] == '1')
		{
			p_allowhe = true;
			PrintToChatAll("%t", "HE Killing enabled");
		}
		else
		{
			p_allowhe = false;
			PrintToChatAll("%t", "HE Killing disabled");
		}
	}
	if (convar == p_Cvarallowworld)
	{
		if (newValue[0] == '1')
		{
			p_allowworld = true;
			PrintToChatAll("%t", "World Damages enabled");
		}
		else
		{
			p_allowworld = false;
			PrintToChatAll("%t", "World Damages disabled");
		}
	}
	if (convar == p_Cvarsoundtoall)
	{
		if (newValue[0] == '1')
		{
			p_soundtoall = true;
			PrintToChatAll("%t", "Squishy sounds to all enabled");
		}
		else
		{
			p_soundtoall = false;
			PrintToChatAll("%t", "Squishy sounds to all disabled");
		}
	}
	if (convar == p_Cvarsquishysounds)
	{
		if (newValue[0] == '1')
		{
			p_squishysounds = true;
			PrintToChatAll("%t", "Squishy sounds enabled");
		}
		else
		{
			p_squishysounds = false;
			PrintToChatAll("%t", "Squishy sounds disabled");
		}
	}
}
		

public OnClientPutInServer(client)
{
    SDKHook(client, SDKHook_TraceAttack, OnTraceAttack);
}

public Action:OnTraceAttack(victim, &attacker, &inflictor, &Float:damage, &damagetype, &ammotype, hitbox, hitgroup)
{
	if (p_enabled)
	{
		decl String:weapon[32];
		decl String:grenade[32];
		GetEdictClassname(inflictor, grenade, sizeof(grenade));
		GetClientWeapon(attacker, weapon, sizeof(weapon));
		
		if (hitgroup == 1)
		{
			if(p_soundtoall)
			{
				if(p_squishysounds)
				{
				new Float:vicpos[3];
				GetClientEyePosition(victim, vicpos);
				EmitAmbientSound(headsounds[GetRandomInt(0, soundsfound -1)], vicpos, victim, SNDLEVEL_GUNFIRE);
				}
			}
			else
			{
				if(p_squishysounds)
				{
				EmitSoundToClient(attacker, headsounds[GetRandomInt(0, soundsfound -1)], SOUND_FROM_PLAYER, SNDCHAN_AUTO, SNDLEVEL_RAIDSIREN);
				}
			}
				
			return Plugin_Continue;
		}
		else if (p_allowknife && StrEqual(weapon, "weapon_knife"))
		{
			return Plugin_Continue;
		}
		else if (p_allowhe && StrEqual(grenade, "hegrenade_projectile"))
		{
			return Plugin_Continue;
		}
		else
		{
			return Plugin_Handled;
		}
	}
	return Plugin_Continue;
}
public Action:EventPlayerHurt(Handle:event, const String:name[],bool:dontBroadcast)
{
	if (p_enabled)
	{
		if (!p_allowhe)
		{
			new victim = GetClientOfUserId(GetEventInt(event, "userid"));
			new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
			new dhealth = GetEventInt(event, "dmg_health");
			new darmor = GetEventInt(event, "dmg_armor");
			new health = GetEventInt(event, "health");
			new armor = GetEventInt(event, "armor");
			decl String:weapon[32];
			GetEventString(event, "weapon", weapon, sizeof(weapon));
			
			if(StrEqual(weapon, "hegrenade", false))
			{
				if (attacker != victim && victim != 0)
				{
					if (dhealth > 0)
					{
						SetEntData(victim, g_iHealth, (health + dhealth), 4, true);
					}
					if (darmor > 0)
					{
						SetEntData(victim, g_Armor, (armor + darmor), 4, true);
					}
				}
			}
		}
		if (!p_allowworld)
		{
			new victim = GetClientOfUserId(GetEventInt(event, "userid"));
			new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
			new dhealth = GetEventInt(event, "dmg_health");
			new darmor = GetEventInt(event, "dmg_armor");
			new health = GetEventInt(event, "health");
			new armor = GetEventInt(event, "armor");
			
			if (victim !=0 && attacker == 0)
			{
				if (dhealth > 0)
				{
					SetEntData(victim, g_iHealth, (health + dhealth), 4, true);
				}
				if (darmor > 0)
				{
					SetEntData(victim, g_Armor, (armor + darmor), 4, true);
				}
			}
		}
	}
	return Plugin_Continue;
}