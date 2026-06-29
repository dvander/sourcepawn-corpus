/*Goremod by Pinkfairie:

ChangeLog:
V1.4:
-Bug Fix
-Support for CSDKPlayer

V1.3:
-All known crashes fixed

v1.2:
-Actually Fixed the Edict Crash
-Added CSS: DM Support
-Added sm_bloodlevel <#>
-Fixed Gib Directions & Velocity
-Supports HL2: DM & DOD: S

v1.1:
-Balanced Blood & Gore Levels
-Removed Gib Disapearance
-Removed Collision Between Gibs and Players
-Fixed Crash
-Lowered Lag & Made Code More Efficient

v1.0:
-Release
*/

#pragma semicolon 1

//Includes:
#include <sourcemod>
#include <sdktools>
#include <halflife>

//Definitions:
#define MAXGIBS 4

//Editable:
new bool:Is_Death_Match = false; //Set to true if you are running CSS:DM
new Float:Gib_Remove_Time = 30.0; //Only applies to CSS:DM
new Blood_Level = 3; //Default Blood Multiplier and Gib Addition

//Variables:
new Current_Health[33];
new Max_Ents;

//Information:
public Plugin:myinfo =
{
	name = "Goremod",
	author = "Pinkfairie",
	description = "Add Blood & Gore",
	version = "1.4",
	url = "Http://www.myspace.com/josephmaley"
}

//Initation:
public OnPluginStart()
{

	//Gibs:
	PrecacheModel("models/Gibs/HGIBS.mdl", true);
	PrecacheModel("models/Gibs/HGIBS_rib.mdl", true);
	PrecacheModel("models/Gibs/HGIBS_scapula.mdl", true);
	PrecacheModel("models/Gibs/HGIBS_spine.mdl", true);

	//Hooks:
	HookEvent("player_hurt", Event_Damage);
	HookEvent("player_spawn", Event_Spawn);
	HookEvent("player_death", Event_Death);

	//Admin:
	RegAdminCmd("sm_bloodlevel", Command_Bloodlevel, ADMFLAG_KICK, "Set Blood Level");

	//Defines:
	Max_Ents = GetMaxEntities(); 
}

//Spawn:
public Event_Spawn(Handle:Spawn_Event, const String:Spawn_Name[], bool:Spawn_Broadcast)
{
	//Client:
	new Client = GetClientOfUserId(GetEventInt(Spawn_Event, "userid"));
	Current_Health[Client] = GetClientHealth(Client);

	//Enjoy the Blood:
	ClientCommand(Client, "mp_decals %d", Max_Ents);
}

//Death:
public Event_Death(Handle:Death_Event, const String:Death_Name[], bool:Death_Broadcast)
{

	//Retrieve Variables:
	new Client, Attacker, bool:Headshot, String:WeaponName[32];

	//Event IDs:
	Client = GetClientOfUserId(GetEventInt(Death_Event, "userid"));
	Attacker = GetClientOfUserId(GetEventInt(Death_Event, "attacker"));
	Headshot = GetEventBool(Death_Event, "headshot");
	GetEventString(Death_Event, "weapon", WeaponName, 32); 

	//Blood:
	if(Client != 0 && Attacker != 0)
	{
		for(new Integer = (5 * Blood_Level); Integer > 0; Integer--) 
			Blood_Effect(Client, Attacker, 150, false);

		if(Headshot || StrEqual(WeaponName, "weapon_hegrenade", false))
		{
			//Gore:
			Blood_Effect(Client, Attacker, 0, true);

			//Find Dead Body:
			new Body_Offset, Body_Ragdoll;
			Body_Offset = FindSendPropOffs("CSDKPlayer", "m_hRagdoll");
			if(Body_Offset > 0)
				Body_Ragdoll = GetEntDataEnt(Client, Body_Offset);

			Body_Offset = FindSendPropOffs("CCSPlayer", "m_hRagdoll");
			if(Body_Offset > 0)
				Body_Ragdoll = GetEntDataEnt(Client, Body_Offset);

			Body_Offset = FindSendPropOffs("CDODPlayer", "m_hRagdoll");
			if(Body_Offset > 0)
				Body_Ragdoll = GetEntDataEnt(Client, Body_Offset);

			Body_Offset = FindSendPropOffs("CHL2MP_Player", "m_hRagdoll");
			if(Body_Offset > 0)
				Body_Ragdoll = GetEntDataEnt(Client, Body_Offset);

			//Remove Dead Body:
			if(Body_Ragdoll > 0)
				RemoveEdict(Body_Ragdoll);
		}
	}
}

//Damage Taken:
public Event_Damage(Handle:Damage_Event, const String:Damage_Name[], bool:Damage_Broadcast)
{
	//Client IDs:
	new Client = GetClientOfUserId(GetEventInt(Damage_Event, "userid"));
	new Attacker = GetClientOfUserId(GetEventInt(Damage_Event, "attacker"));

	//Blood Initation:
	new Blood_Z, Client_Health;
	Client_Health = GetClientHealth(Client);
	Blood_Z = (Current_Health[Client] - Client_Health);

	//Health:
	Current_Health[Client] = Client_Health;

	//Bleed:
	if(Client != 0 && Attacker != 0)
	{
		for(new Integer = (3 * Blood_Level); Integer > 0; Integer--) 
			Blood_Effect(Client, Attacker, Blood_Z, false);
	}
}

//Blood Effect:
stock Blood_Effect(Client, Attacker, Blood_Z, bool:Gore)
{
	//Initation:
	new String:Blood_Angles[255], Float:Blood_Direction[3];

	//Get Client Origins:
	new Float:Client_Origin[3], Float:Attacker_Origin[3];
	GetClientAbsOrigin(Client, Client_Origin);
	GetClientAbsOrigin(Attacker, Attacker_Origin);

	//Direction Math:
	Blood_Direction[0] = ((Client_Origin[0] - Attacker_Origin[0]) * Float:GetRandomFloat(0.5, 1.5));
	Blood_Direction[1] = ((Client_Origin[1] - Attacker_Origin[1]) * Float:GetRandomFloat(0.5, 1.5));
	if((-250.0 + Blood_Z) > -100.0)
		Blood_Direction[2] = -100.0;
	else
		Blood_Direction[2] = (-250.0 + Blood_Z);

	Format(Blood_Angles, 255, "%f %f %f", Blood_Direction[0], Blood_Direction[1], Blood_Direction[2]);
	
	//Shot:
	if(!Gore)
	{
		//Create:
		new Blood_Ent = CreateEntityByName("env_blood");
		if (Blood_Ent == -1)
			return;

		//Spawn:
		DispatchSpawn(Blood_Ent);

		//Properties:
		DispatchKeyValue(Blood_Ent, "spawnflags", "12");
		DispatchKeyValue(Blood_Ent, "amount", "100");
		DispatchKeyValue(Blood_Ent, "spraydir", Blood_Angles);
		DispatchKeyValue(Blood_Ent, "color", "0");
    
		//Emit:
		AcceptEntityInput(Blood_Ent, "EmitBlood", Client);

		//Clear Edicts:
		RemoveEdict(Blood_Ent);
	}
	
	//Headshot & Grenade:
	if(Gore)
	{
		//Skull:
		Gib_Gore("models/Gibs/HGIBS.mdl", Client_Origin, Blood_Direction, 1000.0, 1);
		
		//Ribs:
		Gib_Gore("models/Gibs/HGIBS_rib.mdl", Client_Origin, Blood_Direction, 1000.0, (4 + Blood_Level));

		//Spines:
		Gib_Gore("models/Gibs/HGIBS_spine.mdl", Client_Origin, Blood_Direction, 1000.0, (1 + Blood_Level));

		//Scapulas:
		Gib_Gore("models/Gibs/HGIBS_scapula.mdl", Client_Origin, Blood_Direction, 1000.0, (2 + Blood_Level));
	}

}

//Gibs:
public Gib_Gore(String:Gib_Model[], Float:Gib_Origin[3], Float:Gib_Direction[3], Float:Z_Velocity, Gib_Count)
{
	for(new Integer = Gib_Count; Integer > 0; Integer--)
	{
		//Create:
		new Gib_Ent = CreateEntityByName("prop_physics");
		
		//Anti-Crash:
		if(Gib_Ent < (GetMaxEntities() - 100))
		{ 
			//Properties:
			DispatchKeyValue(Gib_Ent, "model", Gib_Model);
			DispatchSpawn(Gib_Ent);

			//Spawn:
			new Float:Update_Gib_Direction[3];

			//Splash:
			Update_Gib_Direction[0] = (Gib_Direction[0] * Float:GetRandomFloat(0.5, 1.5));
			Update_Gib_Direction[1] = (Gib_Direction[1] * Float:GetRandomFloat(0.5, 1.5));
			Update_Gib_Direction[2] = 100.0;

			//Velocity:
			new Float:Gib_Velocity[3];
			Gib_Velocity[0] = Gib_Direction[0];
			Gib_Velocity[1] = Gib_Direction[1];
			Gib_Velocity[2] = 150.0;
		
			//Spawn:
			TeleportEntity(Gib_Ent, Gib_Origin, Update_Gib_Direction, Gib_Velocity);

			//Collision:
			new Gib_Offset = GetEntSendPropOffs(Gib_Ent, "m_CollisionGroup");
			if(Gib_Ent != -1)
				SetEntData(Gib_Ent, Gib_Offset, 1, 1, true);

			//Removal:
			if(Is_Death_Match)
				CreateTimer(Gib_Remove_Time, Gib_Remove, Gib_Ent);

		}
	}
}

//CSS:DM Remove:
public Action:Gib_Remove(Handle:Gib_Timer, any:Gib_Ent)
{
	RemoveEdict(Gib_Ent);
}

//Set Blood Level:
public Action:Command_Bloodlevel(Client, Argument)
{
	//Error Check:
	if(Argument < 1)
	{
		PrintToConsole(Client, "[SM] Usage: sm_bloodlevel <1-10>");

		return Plugin_Handled;
	}

	//Retrieve Argument:
	new String:tBlood_Level[20], iBlood_Level = 1;
	GetCmdArg(1, tBlood_Level, sizeof(tBlood_Level));

	//Convert:
	StringToIntEx(tBlood_Level, iBlood_Level);

	//Error Check:
	if(StringToIntEx(tBlood_Level, iBlood_Level) < 1)
	{
		PrintToConsole(Client, "[SM] Usage: sm_bloodlevel <1-10>");
		return Plugin_Handled;
	}

	//Update:
	if(iBlood_Level > 10)
		Blood_Level = 10;

	else if(iBlood_Level < 1)
		Blood_Level = 1;

	else
		Blood_Level = iBlood_Level;

	PrintToConsole(Client, "[SM] Blood Level set to %d", Blood_Level);

	return Plugin_Handled;
}