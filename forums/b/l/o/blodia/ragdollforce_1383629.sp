#include <sourcemod>
#include <sdktools>

#pragma semicolon 1

#define PLUGIN_VERSION "1.0"

new Handle:ForceTrie;

public Plugin:myinfo =
{
	name = "Ragdoll Force",
	author = "Blodia",
	description = "Allows you to change the behaviour of ragdolls",
	version = "1.0",
	url = ""
}

public OnPluginStart()
{
	ForceTrie = CreateTrie();
	
	CreateConVar("ragdollforce_version", PLUGIN_VERSION, "Ragdoll force version", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_REPLICATED);
	
	RegServerCmd("ragdollforce", ModForce, "modify rogdolls force along each axis usinf multipliers usage:ragdollforce <weapon> <x force> <y force> <z force>");
	
	new Float:GalilInfo[3];
	GalilInfo[0] = 10.0;
	GalilInfo[1] = 10.0;
	GalilInfo[2] = 10.0;
	SetTrieArray(ForceTrie, "galil", GalilInfo, 3);
	
	new Float:Ak47Info[3];
	Ak47Info[0] = 10.0;
	Ak47Info[1] = 10.0;
	Ak47Info[2] = 10.0;
	SetTrieArray(ForceTrie, "ak47", Ak47Info, 3);
	
	new Float:ScoutInfo[3];
	ScoutInfo[0] = 10.0;
	ScoutInfo[1] = 10.0;
	ScoutInfo[2] = 10.0;
	SetTrieArray(ForceTrie, "scout", ScoutInfo, 3);
	
	new Float:Sg552Info[3];
	Sg552Info[0] = 10.0;
	Sg552Info[1] = 10.0;
	Sg552Info[2] = 10.0;
	SetTrieArray(ForceTrie, "sg552", Sg552Info, 3);
	
	new Float:AwpInfo[3];
	AwpInfo[0] = 10.0;
	AwpInfo[1] = 10.0;
	AwpInfo[2] = 10.0;
	SetTrieArray(ForceTrie, "awp", AwpInfo, 3);
	
	new Float:G3sg1Info[3];
	G3sg1Info[0] = 10.0;
	G3sg1Info[1] = 10.0;
	G3sg1Info[2] = 10.0;
	SetTrieArray(ForceTrie, "g3sg1", G3sg1Info, 3);
	
	new Float:FamasInfo[3];
	FamasInfo[0] = 10.0;
	FamasInfo[1] = 10.0;
	FamasInfo[2] = 10.0;
	SetTrieArray(ForceTrie, "famas", FamasInfo, 3);
	
	new Float:M4a1Info[3];
	M4a1Info[0] = 10.0;
	M4a1Info[1] = 10.0;
	M4a1Info[2] = 10.0;
	SetTrieArray(ForceTrie, "m4a1", M4a1Info, 3);
	
	new Float:AugInfo[3];
	AugInfo[0] = 10.0;
	AugInfo[1] = 10.0;
	AugInfo[2] = 10.0;
	SetTrieArray(ForceTrie, "aug", AugInfo, 3);
	
	new Float:Sg550Info[3];
	Sg550Info[0] = 10.0;
	Sg550Info[1] = 10.0;
	Sg550Info[2] = 10.0;
	SetTrieArray(ForceTrie, "sg550", Sg550Info, 3);
	
	new Float:GlockInfo[3];
	GlockInfo[0] = 10.0;
	GlockInfo[1] = 10.0;
	GlockInfo[2] = 10.0;
	SetTrieArray(ForceTrie, "glock", GlockInfo, 3);
	
	new Float:UspInfo[3];
	UspInfo[0] = 10.0;
	UspInfo[1] = 10.0;
	UspInfo[2] = 10.0;
	SetTrieArray(ForceTrie, "usp", UspInfo, 3);
	
	new Float:P228Info[3];
	P228Info[0] = 10.0;
	P228Info[1] = 10.0;
	P228Info[2] = 10.0;
	SetTrieArray(ForceTrie, "p228", P228Info, 3);
	
	new Float:DeagleInfo[3];
	DeagleInfo[0] = 10.0;
	DeagleInfo[1] = 10.0;
	DeagleInfo[2] = 10.0;
	SetTrieArray(ForceTrie, "deagle", DeagleInfo, 3);
	
	new Float:EliteInfo[3];
	EliteInfo[0] = 10.0;
	EliteInfo[1] = 10.0;
	EliteInfo[2] = 10.0;
	SetTrieArray(ForceTrie, "elite", EliteInfo, 3);
	
	new Float:FivesevenInfo[3];
	FivesevenInfo[0] = 10.0;
	FivesevenInfo[1] = 10.0;
	FivesevenInfo[2] = 10.0;
	SetTrieArray(ForceTrie, "fiveseven", FivesevenInfo, 3);
	
	new Float:M3Info[3];
	M3Info[0] = 10.0;
	M3Info[1] = 10.0;
	M3Info[2] = 10.0;
	SetTrieArray(ForceTrie, "m3", M3Info, 3);
	
	new Float:Xm1014Info[3];
	Xm1014Info[0] = 10.0;
	Xm1014Info[1] = 10.0;
	Xm1014Info[2] = 10.0;
	SetTrieArray(ForceTrie, "xm1014", Xm1014Info, 3);
	
	new Float:Mac10Info[3];
	Mac10Info[0] = 10.0;
	Mac10Info[1] = 10.0;
	Mac10Info[2] = 10.0;
	SetTrieArray(ForceTrie, "mac10", Mac10Info, 3);
	
	new Float:TmpInfo[3];
	TmpInfo[0] = 10.0;
	TmpInfo[1] = 10.0;
	TmpInfo[2] = 10.0;
	SetTrieArray(ForceTrie, "tmp", TmpInfo, 3);
	
	new Float:Mp5navyInfo[3];
	Mp5navyInfo[0] = 10.0;
	Mp5navyInfo[1] = 10.0;
	Mp5navyInfo[2] = 10.0;
	SetTrieArray(ForceTrie, "mp5navy", Mp5navyInfo, 3);
	
	new Float:Ump45Info[3];
	Ump45Info[0] = 10.0;
	Ump45Info[1] = 10.0;
	Ump45Info[2] = 10.0;
	SetTrieArray(ForceTrie, "ump45", Ump45Info, 3);
	
	new Float:P90Info[3];
	P90Info[0] = 10.0;
	P90Info[1] = 10.0;
	P90Info[2] = 10.0;
	SetTrieArray(ForceTrie, "p90", P90Info, 3);
	
	new Float:M249Info[3];
	M249Info[0] = 10.0;
	M249Info[1] = 10.0;
	M249Info[2] = 10.0;
	SetTrieArray(ForceTrie, "m249", M249Info, 3);
	
	new Float:KnifeInfo[3];
	KnifeInfo[0] = 10.0;
	KnifeInfo[1] = 10.0;
	KnifeInfo[2] = 10.0;
	SetTrieArray(ForceTrie, "knife", KnifeInfo, 3);
	
	new Float:HegrenadeInfo[3];
	HegrenadeInfo[0] = 10.0;
	HegrenadeInfo[1] = 10.0;
	HegrenadeInfo[2] = 10.0;
	SetTrieArray(ForceTrie, "hegrenade", HegrenadeInfo, 3);
	
	HookEvent("player_death", Event_PlayerDeath);
}

public OnPluginEnd()
{
	CloseHandle(ForceTrie);
}

public Action:ModForce(args)
{
	if (GetCmdArgs() != 4)
	{
		PrintToServer("********** ragdollforce: must be 4 arguments - <weapon> <x force> <y force> <z force>");
		return Plugin_Handled;
	}
	
	new String:WeaponName[30];
	new String:xforce[10];
	new String:yforce[10];
	new String:zforce[10];
	
	GetCmdArg(1, WeaponName, sizeof(WeaponName));
	GetCmdArg(2, xforce, sizeof(xforce));
	GetCmdArg(3, yforce, sizeof(yforce));
	GetCmdArg(4, zforce, sizeof(zforce));
	
	new Float:EditForce[3];
	if (!GetTrieArray(ForceTrie, WeaponName, EditForce, 3))
	{
		PrintToServer("********** ragdollforce: weapon doesn't exist");
		PrintToServer("********** ragdollforce: valid weapons are:- galil, ak47, scout, sg552, awp, g3sg1, famas, m4a1");
		PrintToServer("********** ragdollforce: continued:- aug, sg550, glock, usp, p228, deagle, elite, fiveseven, m3");
		PrintToServer("********** ragdollforce: continued:- xm1014, mac10, tmp, mp5navy, ump45, p90, m249, knife, hegrenade");
		return Plugin_Handled;
	}
	
	new Float:newxforce = StringToFloat(xforce);
	if ((newxforce < -10000.0) && (newxforce > 10000.0))
	{
		PrintToServer("********** ragdollforce: x must be between -10000.0 and 10000.0");
		return Plugin_Handled;
	}
	
	new Float:newyforce = StringToFloat(yforce);
	if ((newyforce < -10000.0) && (newyforce > 10000.0))
	{
		PrintToServer("********** ragdollforce: y must be between -10000.0 and 10000.0");
		return Plugin_Handled;
	}
	
	new Float:newzforce = StringToFloat(zforce);
	if ((newzforce < -10000.0) && (newzforce > 10000.0))
	{
		PrintToServer("********** ragdollforce: z must be between -10000.0 and 10000.0");
		return Plugin_Handled;
	}
	
	EditForce[0] = newxforce;
	EditForce[1] = newyforce;
	EditForce[2] = newzforce;
	SetTrieArray(ForceTrie, WeaponName, EditForce, 3);
	
	return Plugin_Handled;
}

public Action:Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new UserId = GetEventInt(event, "userid");
	new client = GetClientOfUserId(UserId);
	new String:weapon[30];
	GetEventString(event, "weapon", weapon, sizeof(weapon));
	
	new Float:EditForce[3];
	if (!GetTrieArray(ForceTrie, weapon, EditForce, 3))
	{
		return Plugin_Continue;
	}
	
	// "m_hRagdoll" points to the playes ragdoll.
	new Ragdoll = GetEntPropEnt(client, Prop_Send, "m_hRagdoll");
	if (Ragdoll != -1)
	{
		if (StrEqual(weapon, "hegrenade", false))
		{
			// "m_vecRagdollVelocity" is the force applied to the entire ragdoll for non hitbox specific damage..
			new Float:Velocity[3];
			GetEntPropVector(Ragdoll, Prop_Send, "m_vecRagdollVelocity", Velocity);
			
			Velocity[0] *= EditForce[0];
			Velocity[1] *= EditForce[1];
			Velocity[2] *= EditForce[2];
			SetEntPropVector(Ragdoll, Prop_Send, "m_vecRagdollVelocity", Velocity);
		}
		else
		{
			// "m_vecForce" is the force applied to a ragdolls bone for hitbox specific damage.
			new Float:Force[3];
			GetEntPropVector(Ragdoll, Prop_Send, "m_vecForce", Force);
			
			Force[0] *= EditForce[0];
			Force[1] *= EditForce[1];
			Force[2] *= EditForce[2];
			SetEntPropVector(Ragdoll, Prop_Send, "m_vecForce", Force);
		}
	}
	
	return Plugin_Continue;
}