#include <sourcemod>
#include <sdktools>

new Handle:Enabled;
new Handle:PrintWho;
new Handle:Probability_glock;
new Handle:Probability_hkp2000;
new Handle:Probability_elite;
new Handle:Probability_p250;
new Handle:Probability_fiveseven;
new Handle:Probability_tec9;
new Handle:Probability_deagle;
new Handle:Probability_galilar;
new Handle:Probability_famas;
new Handle:Probability_ak47;
new Handle:Probability_m4a1;
new Handle:Probability_ssg08;
new Handle:Probability_aug;
new Handle:Probability_sg550;
new Handle:Probability_g3sg1;
new Handle:Probability_scar20;
new Handle:Probability_awp;
new Handle:Probability_mac10;
new Handle:Probability_ump45;
new Handle:Probability_p90;
new Handle:Probability_bizon;
new Handle:Probability_mp7;
new Handle:Probability_mp9;

public Plugin:myinfo = {
	name = "WeaponJam v1.10",
	author = "VJScope",
	description = "Player might get his weapon jammed while shooting and he has to reload.",
	url = ""
};

public OnPluginStart()
{
	//Propability: 1 = 0.01%, 10 = 0.1%, 100 = 1%, 1000 = 10%
	Enabled = CreateConVar("sm_weaponjam_enabled", "1", "Enable/Disable the plugin. Enable = 1.", _, true, 0.0, true, 1.0);
	PrintWho = CreateConVar("sm_weaponjam_chat", "1", "Who can see when your weapon gets jammed. 0 = nobody, 1 = you (chat), 2 = all, 3 = you (center)", _, true, 0.0, true, 3.0);
	Probability_glock = CreateConVar("sm_weaponjam_propability_glock", "10", "How often does the weapon glock get jammed.", _, true, 1.0, true, 1000.0);
	Probability_hkp2000 = CreateConVar("sm_weaponjam_propability_hkp2000", "10", "How often does the weapon hkp2000 get jammed.", _, true, 1.0, true, 1000.0);
	Probability_elite = CreateConVar("sm_weaponjam_propability_elite", "10", "How often does the weapon elite get jammed.", _, true, 1.0, true, 1000.0);
	Probability_p250 = CreateConVar("sm_weaponjam_propability_p250", "10", "How often does the weapon p250 get jammed.", _, true, 1.0, true, 1000.0);
	Probability_fiveseven = CreateConVar("sm_weaponjam_propability_fiveseven", "10", "How often does the weapon fiveseven get jammed.", _, true, 1.0, true, 1000.0);
	Probability_tec9 = CreateConVar("sm_weaponjam_propability_tec9", "10", "How often does the weapon tec9 get jammed.", _, true, 1.0, true, 1000.0);
	Probability_deagle = CreateConVar("sm_weaponjam_propability_deagle", "10", "How often does the weapon deagle get jammed.", _, true, 1.0, true, 1000.0);
	Probability_galilar = CreateConVar("sm_weaponjam_propability_galilar", "10", "How often does the weapon galilar get jammed.", _, true, 1.0, true, 1000.0);
	Probability_famas = CreateConVar("sm_weaponjam_propability_famas", "10", "How often does the weapon famas get jammed.", _, true, 1.0, true, 1000.0);
	Probability_ak47 = CreateConVar("sm_weaponjam_propability_ak47", "10", "How often does the weapon ak47 get jammed.", _, true, 1.0, true, 1000.0);
	Probability_m4a1 = CreateConVar("sm_weaponjam_propability_m4a1", "10", "How often does the weapon m4a1 get jammed.", _, true, 1.0, true, 1000.0);
	Probability_ssg08 = CreateConVar("sm_weaponjam_propability_ssg08", "10", "How often does the weapon ssg08 get jammed.", _, true, 1.0, true, 1000.0);
	Probability_aug = CreateConVar("sm_weaponjam_propability_aug", "10", "How often does the weapon aug get jammed.", _, true, 1.0, true, 1000.0);
	Probability_sg550 = CreateConVar("sm_weaponjam_propability_sg550", "10", "How often does the weapon sg550 get jammed.", _, true, 1.0, true, 1000.0);
	Probability_g3sg1 = CreateConVar("sm_weaponjam_propability_g3sg1", "10", "How often does the weapon g3sg1 get jammed.", _, true, 1.0, true, 1000.0);
	Probability_scar20 = CreateConVar("sm_weaponjam_propability_scar20", "10", "How often does the weapon scar20 get jammed.", _, true, 1.0, true, 1000.0);
	Probability_awp = CreateConVar("sm_weaponjam_propability_awp", "10", "How often does the weapon awp get jammed.", _, true, 1.0, true, 1000.0);
	Probability_mac10 = CreateConVar("sm_weaponjam_propability_mac10", "10", "How often does the weapon mac10 get jammed.", _, true, 1.0, true, 1000.0);
	Probability_ump45 = CreateConVar("sm_weaponjam_propability_ump45", "10", "How often does the weapon ump45 get jammed.", _, true, 1.0, true, 1000.0);
	Probability_p90 = CreateConVar("sm_weaponjam_propability_p90", "10", "How often does the weapon p90 get jammed.", _, true, 1.0, true, 1000.0);
	Probability_bizon = CreateConVar("sm_weaponjam_propability_bizon", "10", "How often does the weapon bizon get jammed.", _, true, 1.0, true, 1000.0);
	Probability_mp7 = CreateConVar("sm_weaponjam_propability_mp7", "10", "How often does the weapon mp7 get jammed.", _, true, 1.0, true, 1000.0);
	Probability_mp9 = CreateConVar("sm_weaponjam_propability_mp9", "10", "How often does the weapon mp9 get jammed.", _, true, 1.0, true, 1000.0);
	
	AutoExecConfig(true, "weapon_jam");
	
	HookEvent("weapon_fire", Event_WeaponFired, EventHookMode_Pre);
}

public Action:Event_WeaponFired(Handle:event, const String:name[], bool:dontBroadcast)
 {
	if (!GetConVarBool(Enabled))
    {
        return;
    }
	
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new String:sWeaponName[64];
	GetClientWeapon(client, sWeaponName, sizeof(sWeaponName));
	new gun = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	new x = 1;
	new randomnum = GetRandomInt(0, 9999);
	if(StrEqual(sWeaponName, "weapon_glock"))
	{
		x = GetConVarInt(Probability_glock);
	}else if(StrEqual(sWeaponName, "weapon_hkp2000"))
	{
		x = GetConVarInt(Probability_hkp2000);
	}else if(StrEqual(sWeaponName, "weapon_elite"))
	{
		x = GetConVarInt(Probability_elite);
	}else if(StrEqual(sWeaponName, "weapon_p250"))
	{
		x = GetConVarInt(Probability_p250);
	}else if(StrEqual(sWeaponName, "weapon_fiveseven"))
	{
		x = GetConVarInt(Probability_fiveseven);
	}else if(StrEqual(sWeaponName, "weapon_tec9"))
	{
		x = GetConVarInt(Probability_tec9);
	}else if(StrEqual(sWeaponName, "weapon_deagle"))
	{
		x = GetConVarInt(Probability_deagle);
	}else if(StrEqual(sWeaponName, "weapon_galilar"))
	{
		x = GetConVarInt(Probability_galilar);
	}else if(StrEqual(sWeaponName, "weapon_famas"))
	{
		x = GetConVarInt(Probability_famas);
	}else if(StrEqual(sWeaponName, "weapon_ak47"))
	{
		x = GetConVarInt(Probability_ak47);
	}else if(StrEqual(sWeaponName, "weapon_m4a1"))
	{
		x = GetConVarInt(Probability_m4a1);
	}else if(StrEqual(sWeaponName, "weapon_ssg08"))
	{
		x = GetConVarInt(Probability_ssg08);
	}else if(StrEqual(sWeaponName, "weapon_aug"))
	{
		x = GetConVarInt(Probability_aug);
	}else if(StrEqual(sWeaponName, "weapon_sg550"))
	{
		x = GetConVarInt(Probability_sg550);
	}else if(StrEqual(sWeaponName, "weapon_g3sg1"))
	{
		x = GetConVarInt(Probability_g3sg1);
	}else if(StrEqual(sWeaponName, "weapon_scar20"))
	{
		x = GetConVarInt(Probability_scar20);
	}else if(StrEqual(sWeaponName, "weapon_awp"))
	{
		x = GetConVarInt(Probability_awp);
	}else if(StrEqual(sWeaponName, "weapon_mac10"))
	{
		x = GetConVarInt(Probability_mac10);
	}else if(StrEqual(sWeaponName, "weapon_ump45"))
	{
		x = GetConVarInt(Probability_ump45);
	}else if(StrEqual(sWeaponName, "weapon_p90"))
	{
		x = GetConVarInt(Probability_p90);
	}else if(StrEqual(sWeaponName, "weapon_bizon"))
	{
		x = GetConVarInt(Probability_bizon);
	}else if(StrEqual(sWeaponName, "weapon_mp7"))
	{
		x = GetConVarInt(Probability_mp7);
	}else if(StrEqual(sWeaponName, "weapon_mp9"))
	{
		x = GetConVarInt(Probability_mp9);
	}
	
	x += 499;
	if(randomnum > 499 && randomnum <= x)
	{
		SetEntProp(gun, Prop_Send, "m_iClip1", 0, 1);
		
		switch(GetConVarInt(PrintWho))
		{
			case 1:
				PrintToChat(client, "[SM] Weapon jammed, reload!");
			case 2:
				PrintToChatAll( "[SM]%N: My weapon got jammed! I need to reload!", client);
			case 3:
				PrintCenterText(client, "[SM] Weapon jammed, reload!");
		}
	}
 }