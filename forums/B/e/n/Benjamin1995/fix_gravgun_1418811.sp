#include <sourcemod>
#include <sdkhooks>

#define VERSION "0.6"

//Handles
new Handle:g_bEnable = INVALID_HANDLE;

public Plugin:myinfo = 
{
	name = "Old Half-Life Prop Grabing",
	author = "Benni aka benjamin1995",
	description = "With this plugin the old Half-Life physcannon grabbing is back",
	version = VERSION,
	url = "http://www.bennisgameservers.com"
}

public OnPluginStart()
{
	RegConsoleCmd("use" , HandleUse);
	RegConsoleCmd("phys_swap" , HandleUse);

	//CVars
	CreateConVar("gravity_version", VERSION, "Version of the Gravity Plugin",FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_UNLOGGED|FCVAR_DONTRECORD|FCVAR_REPLICATED|FCVAR_NOTIFY);
	
	g_bEnable = CreateConVar("sm_gravity_enable", "1", "Enabled the Plugin");	
	AutoExecConfig(true, "plugin.gravity");
}


public Action:HandleUse(Client ,args)
{
	if(GetConVarBool(g_bEnable))
	{
		new String:WeaponName[32];
		GetClientWeapon(Client, WeaponName, sizeof(WeaponName));
		
		if(StrEqual(WeaponName, "weapon_physcannon")) 
		{
			if(GetEntityOpen(HasClientWeapon(Client, "weapon_physcannon")) && GetEffectState(HasClientWeapon(Client, "weapon_physcannon")) == 3) 
			{
				return Plugin_Handled;
			}
		}	
	}
	return Plugin_Continue;
}

stock GetEffectState(Ent){return GetEntProp(Ent, Prop_Send, "m_EffectState");}

stock bool:GetEntityOpen(Ent){	return GetEntProp(Ent, Prop_Send, "m_bOpen", 1) ? true:false;}

stock HasClientWeapon(Client, const String:WeaponName[])
{	
	//Initialize:
	new Offset = FindSendPropOffs("CHL2MP_Player", "m_hMyWeapons");
	
	new MaxGuns = 256;
	
	//Loop:
	for(new X = 0; X < MaxGuns; X = (X + 4))
	{		
		//Initialize:
		new WeaponId = GetEntDataEnt2(Client, Offset + X);
		
		//Valid:
		if(WeaponId > 0)
		{
			new String:ClassName[32];
			GetEdictClassname(WeaponId, ClassName, sizeof(ClassName));
			if(StrEqual(ClassName, WeaponName))
			{				
				return WeaponId;
			}
		}
	}	
	return -1;
}

