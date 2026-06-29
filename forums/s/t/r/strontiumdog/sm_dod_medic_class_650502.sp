//
// SourceMod Script
//
// Developed by <eVa>Dog
// July 2008
// http://www.theville.org
//

//
// DESCRIPTION:
// For Day of Defeat Source only
// This plugin is a port of the Medic Class plugin for DoDS
// originally created by me in EventScripts
// Additional testing and coding by Lebson
//
//
// CHANGELOG:
// See http://forums.alliedmods.net/showthread.php?t=73997

#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.0.111"

new Handle:g_Cvar_MedicEnable
new Handle:g_Cvar_MedicWeapon
new Handle:g_Cvar_MedicNades
new Handle:g_Cvar_MedicNadeAmmo
new Handle:g_Cvar_MedicAmmo
new Handle:g_Cvar_MedicSpeed
new Handle:g_Cvar_MedicWeight
new Handle:g_Cvar_MedicHealth
new Handle:g_Cvar_MedicMaxHeal
new Handle:g_Cvar_MedicMax
new Handle:g_Cvar_MedicPacks
new Handle:g_Cvar_MedicMessages
new Handle:g_Cvar_MedicRestrict
new Handle:g_Cvar_MedicPrimary
new Handle:g_Cvar_MedicSelf
new Handle:g_Cvar_MedicMinHealth
new Handle:g_Cvar_MedicMaxHealth
new Handle:pistol_plugin = INVALID_HANDLE
new Handle:g_Target[MAXPLAYERS+1]

new g_medic_master[4][17]

new String:g_model[4][128]
new String:g_classlist[9][64]

new bool:isMedic[MAXPLAYERS+1]
new bool:flagNoMedic[MAXPLAYERS+1]
new bool:flagBeMedic[MAXPLAYERS+1]
new bool:swap[MAXPLAYERS+1] 

new medicPacks[MAXPLAYERS+1]
new yell[MAXPLAYERS+1]
new health[MAXPLAYERS+1]

new ammo_offset

public Plugin:myinfo = 
{
	name = "Medic Class for DoDS",
	author = "<eVa>Dog",
	description = "Medic Class plugin for Day of Defeat Source",
	version = PLUGIN_VERSION,
	url = "http://www.theville.org"
}

public OnPluginStart()
{
	CreateConVar("sm_dod_medic_version", PLUGIN_VERSION, "Medic Class for DoDS version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY)
	g_Cvar_MedicWeapon   = CreateConVar("sm_dod_medic_weapon", "0", " The secondary weapon to give to the Medic <0-Pistols 1-Carbine/C96>", FCVAR_PLUGIN)
	g_Cvar_MedicAmmo     = CreateConVar("sm_dod_medic_ammo", "14", " The amount of ammo to give to the Medic", FCVAR_PLUGIN)
	g_Cvar_MedicNades    = CreateConVar("sm_dod_medic_nades", "2", " Enable nades for the Medic <0-Disable 1-Smoke 2-Nades>", FCVAR_PLUGIN)
	g_Cvar_MedicNadeAmmo = CreateConVar("sm_dod_medic_nades_ammo", "2", " The amount of nades to give to the Medic", FCVAR_PLUGIN)
	g_Cvar_MedicSpeed    = CreateConVar("sm_dod_medic_speed", "1.1", " Sets the speed of the medic", FCVAR_PLUGIN)
	g_Cvar_MedicWeight   = CreateConVar("sm_dod_medic_weight", "0.9", " Sets the weight of the medic", FCVAR_PLUGIN)
	g_Cvar_MedicHealth   = CreateConVar("sm_dod_medic_health", "80", " Sets the HP of the medic", FCVAR_PLUGIN)
	g_Cvar_MedicMaxHeal  = CreateConVar("sm_dod_medic_maxhealing", "50", " Maximum amount of health to heal", FCVAR_PLUGIN)
	g_Cvar_MedicMaxHealth= CreateConVar("sm_dod_medic_maxhealth", "100", " Maximum health a player can have (100 = full health)", FCVAR_PLUGIN)
	g_Cvar_MedicMax      = CreateConVar("sm_dod_medic_max", "2", " Maximum number of Medics per team", FCVAR_PLUGIN)
	g_Cvar_MedicPacks    = CreateConVar("sm_dod_medic_packs", "20", " Number of Medic Packs the Medic carries", FCVAR_PLUGIN)
	g_Cvar_MedicMessages = CreateConVar("sm_dod_medic_messages", "1", " Message the Medic/Patient on events", FCVAR_PLUGIN)
	g_Cvar_MedicRestrict = CreateConVar("sm_dod_medic_restrict", "1", " Class to restrict Medic to (see forum thread)", FCVAR_PLUGIN)
	g_Cvar_MedicPrimary  = CreateConVar("sm_dod_medic_useweapons", "0", " Allow Medics to pickup and use dropped weapons ", FCVAR_PLUGIN)
	g_Cvar_MedicSelf     = CreateConVar("sm_dod_medic_minplayers", "0", " Minimum number of players before Medic class available", FCVAR_PLUGIN)
	g_Cvar_MedicMinHealth= CreateConVar("sm_dod_medic_minhealth", "20", " Minimum hp before a player can self heal", FCVAR_PLUGIN)
	g_Cvar_MedicEnable 	 = CreateConVar("sm_dod_medic_enable", "1", " Enables/Disables Medic Class", FCVAR_PLUGIN)
	
	g_classlist[1] = "Rifleman"
	g_classlist[2] = "Assault"
	g_classlist[3] = "Support"
	g_classlist[4] = "Sniper"
	g_classlist[5] = "MG"
	g_classlist[6] = "Rocket"
	
	RegConsoleCmd("sm_class_medic", beMedic, " - Change class to a Medic")
	RegConsoleCmd("sm_heal", Heal, " - Heal a player")
	RegConsoleCmd("sm_medic", Yell, " - Call for a medic")
	RegConsoleCmd("sm_medic_who", Who, " - Display the Medics on your team")

	HookEvent("player_spawn", PlayerSpawnEvent)
	HookEvent("player_changeclass", PlayerChangeClassEvent)
	HookEvent("player_disconnect", PlayerDisconnectEvent)
	HookEvent("player_team", PlayerChangeTeamEvent) //added by psychocoder 
}

public OnEventShutdown()
{
	UnhookEvent("player_spawn", PlayerSpawnEvent)
	UnhookEvent("player_changeclass", PlayerChangeClassEvent)
	UnhookEvent("player_disconnect", PlayerDisconnectEvent)
	UnhookEvent("player_team", PlayerChangeTeamEvent) //added by psychocoder 
}

public OnMapStart()
{
	AddFileToDownloadsTable("models/player/american_medic.dx80.vtx")
	AddFileToDownloadsTable("models/player/american_medic.dx90.vtx")
	AddFileToDownloadsTable("models/player/american_medic.mdl")
	AddFileToDownloadsTable("models/player/american_medic.phy")
	AddFileToDownloadsTable("models/player/american_medic.sw.vtx")
	AddFileToDownloadsTable("models/player/american_medic.vvd")
	AddFileToDownloadsTable("models/player/german_medic.dx80.vtx")
	AddFileToDownloadsTable("models/player/german_medic.dx90.vtx")
	AddFileToDownloadsTable("models/player/german_medic.mdl")
	AddFileToDownloadsTable("models/player/german_medic.phy")
	AddFileToDownloadsTable("models/player/german_medic.sw.vtx")
	AddFileToDownloadsTable("models/player/german_medic.vvd")
	AddFileToDownloadsTable("materials/models/player/american/allis_mc_body.vmt")
	AddFileToDownloadsTable("materials/models/player/american/allis_mc_body.vtf")
	AddFileToDownloadsTable("materials/models/player/german/axs_mc_body.vmt")
	AddFileToDownloadsTable("materials/models/player/german/axs_mc_body.vtf")
	
	AddFileToDownloadsTable("sound/bandage/bandage.mp3")
	
	g_model[2] = "models/player/american_medic.mdl"
	g_model[3] = "models/player/german_medic.mdl"
	
	PrecacheModel(g_model[2], true)
	PrecacheModel(g_model[3], true)
	
	PrecacheSound("bandage/bandage.mp3", true)
	PrecacheSound("common/weapon_denyselect.wav", true)
	PrecacheSound("common/weapon_select.wav", true)
	
	for (new i = 1; i < 17; i++)
	{
		g_medic_master[2][i] = 0
		g_medic_master[3][i] = 0
	}
	
	for (new i = 0; i < 33; i++)
	{
		isMedic[i] = false
		flagNoMedic[i] = false
		flagBeMedic[i] = false
		swap[i]=false; 
	}
	
	pistol_plugin = FindConVar("sm_dod_pistols_version")
	
	ammo_offset = FindSendPropOffs("CDODPlayer", "m_iAmmo")
}

public PlayerSpawnEvent(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (GetConVarInt(g_Cvar_MedicEnable))
	{
		new client = GetClientOfUserId(GetEventInt(event, "userid"))
		new team = GetClientTeam(client)
		
		//added by psychocoder
		if(swap[client])
		{ 
			beMedic(client,0); 
			swap[client] = false; 
		}
		
		new otherTeam;
		if(team == 2)
			otherTeam = 3;
		else
			otherTeam = 2;
		//end add 
		
		if (flagNoMedic[client])
		{
			for (new i = 1; i <= GetConVarInt(g_Cvar_MedicMax); i++)
			{
				if (g_medic_master[team][i] == client)
				{
					g_medic_master[team][i] = 0
				}
				
				//added by psychocoder, shows if medic client is in the wrong team
				if (g_medic_master[otherTeam][i] == client) 
				{ 
					g_medic_master[otherTeam][i] = 0
				}
				//end add 
			}
			isMedic[client] = false
			flagNoMedic[client] = false
		}
		
		if (flagBeMedic[client])
		{
			isMedic[client] = true
			flagBeMedic[client] = false
			
		}
			
		if (isMedic[client])
		{
			SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", GetConVarFloat(g_Cvar_MedicSpeed))
			SetEntityGravity(client, GetConVarFloat(g_Cvar_MedicWeight))
			SetEntityHealth(client, GetConVarInt(g_Cvar_MedicHealth))
			SetEntityModel(client, g_model[team])
			medicPacks[client] = GetConVarInt(g_Cvar_MedicPacks)
			
			if (!GetConVarInt(g_Cvar_MedicPrimary))
				g_Target[client] = CreateTimer(0.1, WeaponsCheck, client, TIMER_REPEAT)
			
			if (pistol_plugin == INVALID_HANDLE)
			{
				CreateTimer(0.1, GiveClientWeapon, client)
			}
			else
			{
				CreateTimer(0.2, GiveClientWeapon, client)
			}
		}
		else
		{
			yell[client] = 0
			medicPacks[client] = 0
		}
	}
}

//added by psychocoder, if a swap plugin swap medic 
public PlayerChangeTeamEvent(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (GetConVarInt(g_Cvar_MedicEnable)) 
	{
		new client = GetClientOfUserId(GetEventInt(event, "userid"));
		if (isMedic[client] || flagBeMedic[client])
		{ 
			new team = GetEventInt(event, "team"); 
			new oldteam = GetEventInt(event, "oldteam");
			new bool:disconnect = GetEventBool(event, "disconnect");
			if (team != oldteam) 
			{
				for (new i = 1; i <= GetConVarInt(g_Cvar_MedicMax); i++) 
				{ 
					if (g_medic_master[oldteam][i] == client) 
					{ 
						g_medic_master[oldteam][i] = 0
					} 
				} 
				isMedic[client] = false 
				flagNoMedic[client] = false
				if(!disconnect)
					swap[client]=true;
			}
		}
	}
}
//end add 

public PlayerChangeClassEvent(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (GetConVarInt(g_Cvar_MedicEnable))
	{
		new client = GetClientOfUserId(GetEventInt(event, "userid"))
		
		for (new i = 1; i <= GetConVarInt(g_Cvar_MedicMax); i++)
		{
			for (new team = 2; team <= 3; team++)
			{
				if (g_medic_master[team][i] == client)
				{
					if (!IsPlayerAlive(client))
					{
						g_medic_master[team][i] = 0
						isMedic[client] = false
						PrintToChat(client, "[SM] You are no longer a Medic")
					}
					else
					{
						flagNoMedic[client] = true
						PrintToChat(client, "[SM] You will no longer spawn as Medic")
					}
				}
			}
		}
	}
}

public PlayerDisconnectEvent(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (GetConVarInt(g_Cvar_MedicEnable))
	{
		new client = GetClientOfUserId(GetEventInt(event, "userid"))
		
		for (new i = 1; i <= GetConVarInt(g_Cvar_MedicMax); i++)
		{
			for (new team = 2; team <= 3; team++)
			{
				if (g_medic_master[team][i] == client)
				{
					g_medic_master[team][i] = 0
					isMedic[client] = false
				}
			}
		}
	}
}

public Action:WeaponsCheck(Handle:timer, any:client)
{
	if (!IsClientInGame(client) || !IsPlayerAlive(client)  || !isMedic[client])
	{
		KillWeaponsCheck(client)
		return Plugin_Handled
	}
	
	new weaponindex = GetPlayerWeaponSlot(client, 0)
	if (weaponindex != -1)
	{	
		RemovePlayerItem(client, weaponindex)
		
		//Added by Lebson
		RemoveEdict(weaponindex);
		if ((weaponindex = GetPlayerWeaponSlot(client, 1)) != -1)
			EquipPlayerWeapon(client, weaponindex)

		PrintToChat(client, "[SM] Medics not permitted to use primary weapons")
	}
	
	return Plugin_Continue
}

KillWeaponsCheck(client)
{
	if (g_Target[client] != INVALID_HANDLE)
	{
		KillTimer(g_Target[client])
		g_Target[client] = INVALID_HANDLE
	}
}

public Action:beMedic(client, args)
{
	if (GetConVarInt(g_Cvar_MedicEnable))
	{
		if (client > 0)
		{
			new currentplayers = GetClientCount(false)
			if (currentplayers >= GetConVarInt(g_Cvar_MedicSelf))
			{
				new team = GetClientTeam(client)
				new slot_available = 0
				
				if (isMedic[client])
				{
					flagNoMedic[client] = true
					PrintToChat(client, "[SM] You will no longer spawn as Medic")
				}
				else
				{
					//added by psychocoder
					if(team != 2 && team != 3)
						return Plugin_Handled; 
						
					//Check player's class, if enabled
					if (GetConVarInt(g_Cvar_MedicRestrict) > 0)
					{
						new class = GetEntProp(client, Prop_Send, "m_iPlayerClass")
						
						class++
						if (class != GetConVarInt(g_Cvar_MedicRestrict))
						{
							PrintToChat(client, "[SM] Medic restricted to %s", g_classlist[GetConVarInt(g_Cvar_MedicRestrict)])
							return Plugin_Handled
						}
					}
					
					for (new i = 1; i <= GetConVarInt(g_Cvar_MedicMax); i++)
					{
						if (g_medic_master[team][i] == client)
						{
							PrintToChat(client, "[SM] You will respawn as Medic")
							return Plugin_Handled
						}
					}
					
					for (new i = 1; i <= GetConVarInt(g_Cvar_MedicMax); i++)
					{
						if (g_medic_master[team][i] == 0)
						{
							slot_available = i
							break
						}
					}
					
					if (slot_available != 0)
					{
						//Medic slot available
						g_medic_master[team][slot_available] = client
						flagBeMedic[client] = true
						PrintToChat(client, "[SM] You will respawn as Medic")
						return Plugin_Handled
					}
					else
					{
						PrintToChat(client, "[SM] Medic class is full")
					}
				}
			}
			else
			{
				PrintToChat(client, "[SM] Not enough players to enable Medic Class")
			}
		}
	}
	return Plugin_Handled
}

public Action:Yell(client, args)
{
	if (GetConVarInt(g_Cvar_MedicEnable))
	{
		if (yell[client] == 0)
		{
			yell[client] = 1
			ClientCommand(client, "voice_medic")
			
			new currentplayers = GetClientCount(false)
			if (currentplayers < GetConVarInt(g_Cvar_MedicSelf))
			{
				if (IsPlayerAlive(client) && (client > 0))
				{
					health[client] = GetClientHealth(client)
					
					if (health[client] < GetConVarInt(g_Cvar_MedicMinHealth))
					{
						new randomnumber = GetRandomInt(10, 50)
						health[client] = health[client] + randomnumber
						SetEntityHealth(client, health[client])
						EmitSoundToClient(client, "bandage/bandage.mp3", _, _, _, _, 0.8)
					}
					else
					{
						PrintToChat(client, "[SM] Get up on your feet, soldier! Get back in there and fight")
					}
				}
			}
			
			CreateTimer(2.0, ResetYell, client)
		}
	}		
	return Plugin_Handled
}

public Action:ResetYell(Handle:timer, any:client)
{
	yell[client] = 0
}

public Action:Heal(client, args)
{
	if (GetConVarInt(g_Cvar_MedicEnable))
	{
		if (isMedic[client])
		{
			new Float:medicVector[3]
			new Float:patientVector[3]
			
			new patient = GetClientAimTarget(client, true)
			if (patient > 0)
			{		
				if (IsPlayerAlive(client))
				{
					if (IsPlayerAlive(patient))
					{
						new client_team = GetClientTeam(client)
						new patient_team = GetClientTeam(patient)
						
						if (client_team == patient_team)
						{
							if (medicPacks[client] > 0)
							{
								GetClientAbsOrigin(client, medicVector)
								GetClientAbsOrigin(patient, patientVector)
								
								new Float:distance = GetVectorDistance(medicVector, patientVector)
								
								if (distance > 100)
								{
									if (GetConVarInt(g_Cvar_MedicMessages) == 1)
									{
										PrintToChat(client, "[SM] Too far away to heal this patient")
										EmitSoundToClient(client, "common/weapon_denyselect.wav", _, _, _, _, 0.8)
									}
								}
								else
								{
									//Perform healing
									new String:patientName[128]
									GetClientName(patient, patientName, sizeof(patientName))
									new String:medicName[128]
									GetClientName(client, medicName, sizeof(medicName))
									
									new patienthealth = GetClientHealth(patient)
									if (patienthealth < GetConVarInt(g_Cvar_MedicMaxHealth))
									{
										new randomnumber = GetRandomInt(20, GetConVarInt(g_Cvar_MedicMaxHeal))
										patienthealth = patienthealth + randomnumber
										
										if (patienthealth >= GetConVarInt(g_Cvar_MedicMaxHealth))
											patienthealth = GetConVarInt(g_Cvar_MedicMaxHealth)
											
										if ((isMedic[patient]) && (patienthealth >= GetConVarInt(g_Cvar_MedicHealth)))
											patienthealth = GetConVarInt(g_Cvar_MedicHealth)
										
										SetEntityHealth(patient, patienthealth)
										
										medicPacks[client]--
										EmitSoundToClient(client, "bandage/bandage.mp3", _, _, _, _, 0.8)
										EmitSoundToClient(patient, "bandage/bandage.mp3", _, _, _, _, 0.8)
										
										LogToGame("\"%L\" triggered \"medic_heal\"", client)
										
										if (GetConVarInt(g_Cvar_MedicMessages) == 1)
										{
											PrintToChat(client, "[SM] Healed %s with %ihp", patientName, randomnumber)
											PrintToChat(patient, "[SM] %s healed you with %ihp", medicName, randomnumber)
										}
									}
									else
									{
										EmitSoundToClient(client, "common/weapon_denyselect.wav", _, _, _, _, 0.8)
									}
								}
							}
							else
							{
								if (GetConVarInt(g_Cvar_MedicMessages) == 1)
								{
									PrintToChat(client, "[SM] You have no more Medic Packs left")
								}
								
								EmitSoundToClient(client, "common/weapon_select.wav", _, _, _, _, 0.8)
							}
						}
					}
				}
			}
		}
		else
		{
			PrintToChat(client, "[SM] You need to be a Medic to use this command")
		}
	}
		
	return Plugin_Handled
}

public Action:GiveClientWeapon(Handle:timer, any:client)
{
	if (IsClientInGame(client))
	{
		new team = GetClientTeam(client)
		new weaponslot
		
		// Strip the weapons
		for(new slot = 0; slot < 5; slot++)
		{
			weaponslot = GetPlayerWeaponSlot(client, slot)
			if(weaponslot != -1) 
			{
				RemovePlayerItem(client, weaponslot)
			}
		}
		
		if (team == 2) 
		{
			GivePlayerItem(client, "weapon_amerknife")
			
			if (GetConVarInt(g_Cvar_MedicWeapon) == 0)
			{
				GivePlayerItem(client, "weapon_colt")
				SetEntData(client, ammo_offset+4, GetConVarInt(g_Cvar_MedicAmmo), 4, true)
			}
			else 
			{
				GivePlayerItem(client, "weapon_m1carbine")
				SetEntData(client, ammo_offset+24, GetConVarInt(g_Cvar_MedicAmmo), 4, true)
			}
			
			if (GetConVarInt(g_Cvar_MedicNades) == 1)
			{
				GivePlayerItem(client, "weapon_smoke_us")
				SetEntData(client, ammo_offset+68, GetConVarInt(g_Cvar_MedicNadeAmmo), 4, true)
			}
			if (GetConVarInt(g_Cvar_MedicNades) == 2)
			{
				GivePlayerItem(client, "weapon_frag_us")
				SetEntData(client, ammo_offset+52, GetConVarInt(g_Cvar_MedicNadeAmmo), 4, true)
			}
		}
			
		if (team == 3) 
		{
			GivePlayerItem(client, "weapon_spade")
			
			if (GetConVarInt(g_Cvar_MedicWeapon) == 0)
			{
				GivePlayerItem(client, "weapon_p38")
				SetEntData(client, ammo_offset+8, GetConVarInt(g_Cvar_MedicAmmo), 4, true)
			}
			else 
			{
				GivePlayerItem(client, "weapon_c96")
				SetEntData(client, ammo_offset+12, GetConVarInt(g_Cvar_MedicAmmo), 4, true)
			}
			
			if (GetConVarInt(g_Cvar_MedicNades) == 1)
			{
				GivePlayerItem(client, "weapon_smoke_ger")
				SetEntData(client, ammo_offset+72, GetConVarInt(g_Cvar_MedicNadeAmmo), 4, true)
			}
			if (GetConVarInt(g_Cvar_MedicNades) == 2)
			{
				GivePlayerItem(client, "weapon_frag_ger")
				SetEntData(client, ammo_offset+56, GetConVarInt(g_Cvar_MedicNadeAmmo), 4, true)
			}
		}
	}
	
	return Plugin_Handled
}

 // Added by Lebson506th
public Action:Who(client, args)
{
	if (GetConVarInt(g_Cvar_MedicEnable))
	{
	    new ctr = 0
	    if(client == 0) {
	        for(new i = 1; i <= GetConVarInt(g_Cvar_MedicMax); i++) {
	            if(g_medic_master[3][i] != 0) {
	                new String:playerName[128]
	                GetClientName(g_medic_master[3][i], playerName, sizeof(playerName))

	                PrintToServer("Axis Medic #%i: %s", i, playerName)
	                ctr++
	            }
	        }
	        for(new i = 1; i <= GetConVarInt(g_Cvar_MedicMax); i++) {
	            if(g_medic_master[2][i] != 0) {
	                new String:playerName[128]
	                GetClientName(g_medic_master[2][i], playerName, sizeof(playerName))

	                PrintToServer("Allies Medic #%i: %s", i, playerName)
	                ctr++
	            }
	        }
	    }
	    else {
	        new team = GetClientTeam(client)

	        for (new i = 1; i <= GetConVarInt(g_Cvar_MedicMax); i++) {
	            if (g_medic_master[team][i] != 0) {
	                new String:playerName[128]
	                GetClientName(g_medic_master[team][i], playerName, sizeof(playerName))

	                if (IsClientInGame(client)) {
	                    PrintToChat(client, "Medic #%i: %s", i, playerName)
	                }
	                ctr++
	            }
	        }    
	    }

	    if (ctr == 0) {
	        if(client == 0) {
	            PrintToServer("[SM] The medic class is not being used")
	        }
	        else if (IsClientInGame(client)) {
	            PrintToChat(client, "[SM] There are no medics on your team")
	        }
	    }

	}
	return Plugin_Handled
} 