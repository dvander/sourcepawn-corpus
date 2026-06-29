//
// SourceMod Script
//
// Developed by psychocoder
//

//
// DESCRIPTION:
//	Player speed and gravity is calulatet by his weapons and heal status.
//	Any weapon has it own reallife weight and affected the speed and gravity.
//	If player drop down his weapon and put up a new weapon with more weight he is slower and heavier.
// 	If player get a shot in his arm (with more than 40dmg) he drop his weapon
// 	If player get a shot in his leg he is slower till CVAR slow_value
//	If player healed and has a broken lag, the leg damage will be healed and the speed goes up (work with any medic plugin)
//	If player get a hit over 40dmg than he bleed till death or player call !medic (kill is count for last attacker)

//	If player camp he will get slapped (default 20dmg) //Player with MG and Rocket in the hand can camp)


//
// CHANGELOG:
// Version:
//	0.4.3 fix a bug that only medic heal bleeding if player have a broken leg
//		  add new CVAR sv_realismphysics_selfhealbleed - say if player can heel bleeding by typing !medic in chat (else only a real medic can heal bleeding)
//	0.4.2 fix a bug that camper get 500HP
//	0.4.1 change parts of my bad english and speed up the plugin
//	0.4.0 add bleeding (no visual effect, only hp lose) on hit over 40dmg (new c_var sv_realismphysics_bleed, sv_realismphysics_freezetime)
//	      add a camping module (new CVAR: sv_camp,sv_camp_time,sv_camp_diff_time,sv_camp_slap_dmg)
//  	0.3.0 add blood on screen if headshot and upper chest hit (new cvar sv_realismphysics_blood)
//	0.2.2 bug fixed that medic can not heal leg shots
//	0.2.1 bug fix in leg heal calculation
//	0.2.0 change the 40dmg limit of slow down by leg hit in a dynamicel value and the 60hp heal border to find any heal
//	0.1.6 first release to community


#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "0.4.3"
#define USERID 0
#define ATTACKER 1
#define HITGROUP 2
#define BLEEDCOUNTER 3

//lowest speed of a player
#define CAMPDISTANCE 40.0

new String:bleedWeapon[MAXPLAYERS+1][32];
new bleedValues[MAXPLAYERS+1][4];
new Handle:bleedTimer[MAXPLAYERS+1] = INVALID_HANDLE;

new Handle:C_Drop = INVALID_HANDLE;
new Handle:C_Slow = INVALID_HANDLE;
new Handle:C_Slow_Value = INVALID_HANDLE;
new Handle:C_Grav = INVALID_HANDLE;
new Handle:C_Grav_Value = INVALID_HANDLE;
new Handle:C_Blood = INVALID_HANDLE;
new Handle:C_Bleed = INVALID_HANDLE;
new Handle:C_SelfHealBleed = INVALID_HANDLE;
new Handle:C_FreezeTime = INVALID_HANDLE;

new Handle:weaponTimer[MAXPLAYERS+1];
new bool:legShot[MAXPLAYERS+1]; //flag for faster calculation of leg shots
new bool:legShotOld[MAXPLAYERS+1];
new Float:g_playerWheight[MAXPLAYERS+1];
new Float:g_playerSpeed[MAXPLAYERS+1];
new Float:g_playerGrav[MAXPLAYERS+1];
new g_playerLegDamage[MAXPLAYERS+1]; //leg dmg this life
new g_playerHeal[MAXPLAYERS+1]; //last heal status
new g_iAmmo;
new String:g_blood[3][]={"r_screenoverlay effects/mh_blood1","r_screenoverlay effects/mh_blood2","r_screenoverlay effects/mh_blood3"};
new bool:g_playerBlood[MAXPLAYERS+1];


new bool:c_drop;
new bool:c_slow;
new Float:c_slow_value;
new bool:c_grav;
new Float:c_grav_value;
new bool:c_blood;
new bool:c_bleed;
new Float:c_freezeTime;
new bool:c_selfHealBleed;



//camping
new Float:g_campPosSpawn[MAXPLAYERS+1][3]; //spawn position
new g_campCounter[MAXPLAYERS+1];
new Float:g_campPosLast[MAXPLAYERS+1][3];
new bool:g_campSpawn[MAXPLAYERS+1];

new c_campMaxCount=40;
new c_slapDiff=10;
new c_slapDmg=20;

new bool:c_camp;
new Handle:C_CampMaxCount = INVALID_HANDLE;
new Handle:C_SlapDiff = INVALID_HANDLE;
new Handle:C_SlapDmg = INVALID_HANDLE;
new Handle:C_Camp = INVALID_HANDLE;


//weapon names
static const String:g_weaponEntitys[24][] = { 					"weapon_colt",
										"weapon_p38",
										"weapon_m1carbine",
										"weapon_c96",
										"weapon_garand",
										"weapon_k98",
										"weapon_thompson",
										"weapon_mp40",
										"weapon_bar",
										"weapon_mp44",
										"weapon_spring",
										"weapon_k98_scoped",
										"weapon_30cal",
										"weapon_mg42",
										"weapon_bazooka",
										"weapon_pschreck",
										"weapon_amerknife",
										"weapon_spade",
										"weapon_smoke_us",
										"weapon_smoke_ger",
										"weapon_frag_us",
										"weapon_frag_ger",
										"weapon_riflegren_us",
										"weapon_riflegren_ger"
										};

//weapon weight in kg
static const Float:g_weaponWheight[24] = { 					1.075,
										0.96,
										2.48,
										1.08,
										4.3,
										4.1,
										4.9,
										3.97,
										8.80, 
										4.62,
										4.4,
										4.2,
										19.0,
										12.0,
										7.23,
										11.0,
										0.25,
										0.67,
										0.48,
										0.48,
										0.48,
										0.48,
										0.48,
										0.48
										};

//weapon offsets
static const g_ammoOffset[24] = {					4,	// weapon_colt
									8,	// weapon_p38
									24,	// weapon_m1carb
									12,	// weapon_c96
									16,	// weapon_garand
									20,	// weapon_k98
									32,	// weapon_thompson
									32,	// weapon_mp40
									36,	// weapon_bar
									32,	// weapon_mp44
									28,	// weapon_spring
									20,	// weapon_k98s
									40,	// weapon_30cal
									44,	// weapon_mg42
									48,	// weapon_bazooka
									48,	// weapon_pschreck
									0,	// weapon_amerknife
									0,	// weapon_spade
									68,	// weapon_smoke_us
									72,	// weapon_smoke_ger
									52,	// weapon_frag_us
									56,	// weapon_frag_ger
									84,	// weapon_riflegren_us
									88	// weapon_riflegren_ger
									};


public Plugin:myinfo = 
{
	name = "dodRealismPhysics",
	author = "psychocoder",
	description = "Physic Mod for Day of Defeat Source",
	version = PLUGIN_VERSION,
	url = ""
}

public OnPluginStart()
{
	CreateConVar("sm_realismphysics_version", PLUGIN_VERSION, "Version of dodRealismPhysics", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	C_Drop = CreateConVar("sv_realismphysics_drop", "1", " When players get hurt in the arm, they drop their weapon (0 to disable, 1 to enable: default=1)", FCVAR_PLUGIN);
	C_Slow = CreateConVar("sv_realismphysics_slow", "1", " Slow down player with more weight (0 to disable, 1 to enable: default=1)", FCVAR_PLUGIN);
	C_Grav = CreateConVar("sv_realismphysics_grav", "0", " Change jump height of player with more height (0 to disable, 1 to enable: default=0)", FCVAR_PLUGIN);
	C_Blood = CreateConVar("sv_realismphysics_blood", "0", "show blood on screen if you get a hit ofer 40dmg in upper chest or head (0 to disable, 1 to enable: default=0)", FCVAR_PLUGIN);
	C_Slow_Value = CreateConVar("sv_realismphysics_slow_value", "0.15", "max slow down newspeed=1-value (default: 0.15)", FCVAR_PLUGIN, true, 0.0, true, 0.8);
	C_Grav_Value = CreateConVar("sv_realismphysics_grav_value", "0.15", "max more gravity down newgravity=1+value (default: 0.15)", FCVAR_PLUGIN, true, 0.0, true, 0.8);
	C_Bleed = CreateConVar("sv_realismphysics_bleed", "0", "aktivate bleeding on hit over 40dmg (0 to disable, 1 to enable: default=0)", FCVAR_PLUGIN);
	C_SelfHealBleed = CreateConVar("sv_realismphysics_selfhealbleed", "1", "player cann write !medic to chat and heal bleeding (0 to disable, 1 to enable: default=1)", FCVAR_PLUGIN);
	C_FreezeTime = CreateConVar("sv_realismphysics_freezetime", "3.0", "time in seconds how long players freez if he called !medic (littler than 1.0 to disable, default: 3.0)", FCVAR_PLUGIN, true, 0.0, true, 20.0);
	//camping
	C_Camp = CreateConVar("sv_camp", "1", "Activate camp module (0 to disable, 1 to enable: default=1)", FCVAR_PLUGIN);	
	C_CampMaxCount = CreateConVar("sv_camp_time", "60", "Time in seconds which player can camp. (default = 60)", FCVAR_PLUGIN, true, 0.0, true, 600.0);
	C_SlapDiff = CreateConVar("sv_camp_diff_time", "10", "Time in seconds between slaps for camping. (default = 10)", FCVAR_PLUGIN, true, 2.0, true, 100.0);
	C_SlapDmg = CreateConVar("sv_camp_slap_dmg", "20", "Dmg for camping. (default = 20)", FCVAR_PLUGIN, true, 0.0, true, 100.0);


	HookConVarChange(C_Slow, SlowChanged);
	HookConVarChange(C_Slow_Value, SlowValueChanged);
	HookConVarChange(C_Grav, GravChanged);
	HookConVarChange(C_Grav_Value, GravValueChanged);
	HookConVarChange(C_Drop, DropChanged);
	HookConVarChange(C_Blood, BloodChanged);
	HookConVarChange(C_Bleed, BleedChanged);
	HookConVarChange(C_SelfHealBleed,SelfHealBleedChanged);
	HookConVarChange(C_FreezeTime, FreezeTimeChanged);

	//camping Hooks
	HookConVarChange(C_Camp, CampChanged);
	HookConVarChange(C_CampMaxCount, CampMaxCountChanged);
	HookConVarChange(C_SlapDiff, SlapDiffChanged);
	HookConVarChange(C_SlapDmg, SlapDmgChanged);

	HookEvent("player_death", PlayerDeathEvent);
	HookEvent("player_spawn", PlayerSpawnEvent);
	HookEvent("player_hurt", PlayerHurtEvent);
	HookEvent("player_team", PlayerChangeTeamEvent);
	
	//sound caching
	AddFileToDownloadsTable("sound/bandage/bandage.mp3");
	PrecacheSound("bandage/bandage.mp3", true);
	PrecacheSound("player/damage/male/minorpain.wav", true); //bleed dmg sound

	c_drop=GetConVarBool(C_Drop);
	c_slow=GetConVarBool(C_Slow);
	c_grav=GetConVarBool(C_Grav);
	c_blood=GetConVarBool(C_Blood);
	c_bleed=GetConVarBool(C_Bleed);
	c_selfHealBleed=GetConVarBool(C_SelfHealBleed);
	
	c_slow_value=GetConVarFloat(C_Slow_Value);
	c_grav_value=GetConVarFloat(C_Grav_Value);
	c_freezeTime=GetConVarFloat(C_FreezeTime);


	//camping
	c_camp=GetConVarBool(C_Camp);	
	c_campMaxCount=GetConVarInt(C_CampMaxCount);
	c_slapDiff=GetConVarInt(C_SlapDiff);
	c_slapDmg=GetConVarInt(C_SlapDmg);

	RegConsoleCmd("medic", MedicCall); //call a medic from command line or chat 


}

public OnEventShutdown()
{
	UnhookConVarChange(C_Slow, SlowChanged)
	UnhookConVarChange(C_Slow_Value, SlowValueChanged)
	UnhookConVarChange(C_Grav, GravChanged)
	UnhookConVarChange(C_Grav_Value, GravValueChanged)
	UnhookConVarChange(C_Drop, DropChanged)
	UnhookConVarChange(C_Blood, BloodChanged);
	UnhookConVarChange(C_Bleed, BleedChanged);
	UnhookConVarChange(C_FreezeTime, FreezeTimeChanged);
	UnhookConVarChange(C_SelfHealBleed,SelfHealBleedChanged);
	UnhookEvent("player_death", PlayerDeathEvent)
	UnhookEvent("player_spawn", PlayerSpawnEvent)
	UnhookEvent("player_hurt", PlayerHurtEvent)
	UnhookEvent("player_team", PlayerChangeTeamEvent)
}

//----------------------------CVAR-----------------------------------------------------
//Functions for optimize Cvar read (this is faster as call the GetConVar function)


//camping CVAR
public CampChanged(Handle:convar, const String:oldValue[], const String:newValue[]){
		c_camp=GetConVarBool(C_Camp);
}
public CampMaxCountChanged(Handle:convar, const String:oldValue[], const String:newValue[]){
		c_campMaxCount=GetConVarInt(C_CampMaxCount);
}
public SlapDiffChanged(Handle:convar, const String:oldValue[], const String:newValue[]){
		c_slapDiff=GetConVarInt(C_SlapDiff);
}
public SlapDmgChanged(Handle:convar, const String:oldValue[], const String:newValue[]){
		c_slapDmg=GetConVarInt(C_SlapDmg);
}

//Drop
public DropChanged(Handle:convar, const String:oldValue[], const String:newValue[]){
		c_drop=GetConVarBool(C_Drop);
}

//speed slow
public SlowChanged(Handle:convar, const String:oldValue[], const String:newValue[]){
	c_slow=GetConVarBool(C_Slow);
}
public SlowValueChanged(Handle:convar, const String:oldValue[], const String:newValue[]){
	c_slow_value=GetConVarFloat(C_Slow_Value);
}

//Gravity
public GravChanged(Handle:convar, const String:oldValue[], const String:newValue[]){
	c_grav=GetConVarBool(C_Grav);
}
public GravValueChanged(Handle:convar, const String:oldValue[], const String:newValue[]){
	c_grav_value=GetConVarFloat(C_Grav_Value);
}

//change freeze time by call !medic
public FreezeTimeChanged(Handle:convar, const String:oldValue[], const String:newValue[]){
	c_freezeTime=GetConVarFloat(C_FreezeTime);
}

//Blood on screen
public BloodChanged(Handle:convar, const String:oldValue[], const String:newValue[]){
	if(GetConVarInt(C_Blood)==0)
	{
		c_blood=false;
		new i;
		for(i=1;i<=MaxClients;i++)
		{
			if(IsClientInGame(i))
				ClientCommand(i,"r_screenoverlay 0");
		}
	}
	else
		c_blood=true;
}

//Bleed mode change
public BleedChanged(Handle:convar, const String:oldValue[], const String:newValue[]){
	c_bleed=GetConVarBool(C_Bleed);
}
public SelfHealBleedChanged(Handle:convar, const String:oldValue[], const String:newValue[]){
	c_selfHealBleed=GetConVarBool(C_SelfHealBleed);
}

//----------------------------------------------------------------------------------------


//Reset timer of a Player
ResetTimers(client)
{
	if(weaponTimer[client] != INVALID_HANDLE)
	{
		if(CloseHandle(weaponTimer[client]))
		{
			weaponTimer[client] = INVALID_HANDLE;
		}
	}
}

ResetBleedTimer(client)
{
	bleedValues[client][BLEEDCOUNTER]=0;
	if(bleedTimer[client] != INVALID_HANDLE)
	{
		//if(CloseHandle(bleedTimer[client]))
		//{
			KillTimer(bleedTimer[client]);		//you can not use ClaseHandle because it make a error
			bleedTimer[client] = INVALID_HANDLE;
		//}
	}
}

public Action:KillFreeze(Handle:timer, any:client)
{

	if (IsClientInGame(client))
	{
	    if (IsPlayerAlive(client))
	    {
		SetEntityMoveType(client, MOVETYPE_WALK); //normal walk
	    }
	}
}  


//call medic an heal bleeding and blood
public Action:MedicCall(client, args)
{
	if(c_selfHealBleed==false)
	{
		if(IsClientInGame(client))
		{
			PrintToChat(client,"\x01Find a medic, he can heal you");
		}
		return;
	}
	new bool:sem=false;	
	//heal blood
	if(IsClientInGame(client))
	{
		if(g_playerBlood[client])
		{
			sem=true;
			g_playerBlood[client]=false;
			ClientCommand(client,"r_screenoverlay 0");
		}
	
		//heal bleeding
		if(sem || bleedValues[client][BLEEDCOUNTER]!=0)
		{
			if(c_freezeTime>=1.0)
			{
				SetEntityMoveType(client, MOVETYPE_NONE); //stop walking
				CreateTimer(c_freezeTime,KillFreeze, client);
			}
			EmitSoundToClient(client, "bandage/bandage.mp3", _, _, _, _, 0.8);
		}
	}
	ResetBleedTimer(client); //client stop bleeding
}

//calculate the speed and gravity
CheckWheight(client){

	new Float:playerWheight=75.0;
	new munCount=1;
	new wpn=-1;
	decl String:weaponname[32];
	new beginCount;
	new endCount;

	if (!IsClientInGame(client))
	{
		ResetTimers(client);
		return;
	}

	//------------------------------------calculating wheight of a player---------------------------------
	//search in all weapon slots, no munition is count (it is to slow)	
	for(new slot = 0; slot < 4; slot++)
	{
		wpn = GetPlayerWeaponSlot(client, slot);
		if(wpn != -1)
		{
			//optimize the search in arrays
			switch(slot)
			{		
				case 0:{
					beginCount=4;
					endCount=16;
				}
				case 1:{
					beginCount=0;
					endCount=4;
				}
				case 2:{
					beginCount=16;
					endCount=22;
				}
				case 3:{
					beginCount=18;
					endCount=24;
				}
			}
			GetEdictClassname(wpn, weaponname,32);
			for(new i=beginCount;i<endCount;i++)
			{		
				if(StrEqual(weaponname,g_weaponEntitys[i])){
					
					if(i<18)
						playerWheight+=g_weaponWheight[i];
					else
					{	//only nades must count
						munCount = GetEntData(client, g_iAmmo + g_ammoOffset[i]);
						playerWheight+=(g_weaponWheight[i]*munCount);
					}
					break;
				}
			}
		}
	}
	//----------------------------------------------------------------------------------------------------

	//----------------code paat for detecting a medic class heal action-----------------------
	new healStatus=GetClientHealth(client);
	//if medic class heal, legshot is heal
	if(healStatus>g_playerHeal[client])
	{
		if(c_bleed)
			ResetBleedTimer(client); //client is health by medic class

		if(legShotOld[client])
		{
			g_playerLegDamage[client]-=g_playerLegDamage[client]*(healStatus-g_playerHeal[client])/(100-g_playerHeal[client]); //eve heal back to legdamage and other damage
															// newLegDamage=oldLegDamage-oldLegDamage*heald/allOldDamage, values are rounded because all oparation a int oparation
			g_playerWheight[client]=75.1; //initial a new calculation of gravity and speed
			legShotOld[client]=false;
		}
		//heal blood
		if(g_playerBlood[client])
		{
			g_playerBlood[client]=false;
			ClientCommand(client,"r_screenoverlay 0");
		}
	}
	g_playerHeal[client]=healStatus;
	//-------------------------------------------------------------------------------------------
	

	if(playerWheight==75.0) //no aktion if player had no weapons
		return;

	//---------------calculating speed and gravity-----------------------------------------------
	//only enter if weight is change or a leg shot flag is set
	if(legShot[client] || g_playerWheight[client]!=playerWheight)
	{
		if(legShot[client])
		{
			legShotOld[client]=true; 
			legShot[client]=false; //deaktivate legshot flag
		}
		g_playerWheight[client]=playerWheight;
		new Float:speed=1.0;
		new Float:grav=1.0;
		
	
		if(c_slow)
			speed=80.0/playerWheight;
		if(c_grav)
			grav=playerWheight/80.5;

		if(legShotOld[client])
		{
			speed-= c_slow_value*float(g_playerLegDamage[client])/100.0;
			grav+= c_grav_value*float(g_playerLegDamage[client])/100.0;
		}

		//only enter if something is new since the last calculation
		if( g_playerSpeed[client]!=speed || g_playerGrav[client]!=grav)
		{
			g_playerSpeed[client]=speed;
			g_playerGrav[client]=grav;
			if(c_slow && c_grav)
			{
				PrintToChat(client,"Weapon: %.2fkg, Speed: %.2f km/h, Gravity: %.0f%%",playerWheight-75,speed*6,grav*100);
				SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", speed);
				SetEntityGravity(client, grav);
			}
			else if(c_slow)
			{
				PrintToChat(client,"Weapon: %.2fkg, Speed: %.2f km/h",playerWheight-75,speed*6);
				SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", speed);
			}
			else if(c_grav)
			{
				PrintToChat(client,"Weapon: %.2fkg, Gravity: %.0f%%",grav*100);
				SetEntityGravity(client, grav);
			}
			//LogMessage("Weapon: %.2fkg, Speed: %.2f km/h, Gravity: %.0f%%",playerWheight-75,speed*6,grav*100);
		
		}
	}
	//-----------------------------------------------------------------------------------------------
}


//is the entry function for the timer event
public Action:CheckWheightNow(Handle:timer, any:client){
	
	if (!IsClientInGame(client))
        {
                ResetTimers(client);
                return Plugin_Handled; 
        }
	if(IsPlayerAlive(client))
	{
		CheckWheight(client);
		if(c_camp)
			IsCamping(client);
	}
	return Plugin_Handled;

}

public Action:BleedEvent(Handle:timer, any:client){
	
	if (!IsClientInGame(client) || bleedValues[client][BLEEDCOUNTER]==0 || !IsPlayerAlive(client))
        {
                ResetBleedTimer(client);
                return Plugin_Stop; 
        }
	new healStatus=GetClientHealth(client);
	new slap=GetRandomInt(1,3);

	new slapDmg=slap*bleedValues[client][BLEEDCOUNTER];
	if(slapDmg>=healStatus)
	{
		//ResetBleedTimer(client);
		new Handle:event = CreateEvent("player_death");
		if (event == INVALID_HANDLE)
		{
			return Plugin_Handled;
		}
	 	EmitSoundToClient(client, "player/damage/male/minorpain3.wav", _, _, _, _, 0.8);
		SetEventInt(event, "userid", bleedValues[client][USERID]);
		SetEventInt(event, "attacker",bleedValues[client][ATTACKER]);
		SetEventString(event, "weapon", bleedWeapon[client]);
		SetEventBool(event,"dominated",false);
		SetEventBool(event,"revenge",false);
		//SetEventInt(event, "health",0);
		//SetEventInt(event, "damage",slapDmg);
		//SetEventInt(event, "hitgroup", bleedValues[client][HITGROUP]);
		//ForcePlayerSuicide(client);
		//SetEntityHealth(client, 2);
		FireEvent(event); //fire event player_deth
		FakeClientCommandEx(client, "kill");
		//ResetBleedTimer(client);

	}
	else	
	{
		if(c_selfHealBleed)
			PrintToChat(client,"\x01You bleed %ihp - type \x05!medic\x01 to stop bleeding",slapDmg);
		else
			PrintToChat(client,"\x01You bleed %ihp - find a medic, he can heal you",slapDmg);
		
		EmitSoundToClient(client, "player/damage/male/minorpain3.wav", _, _, _, _, 0.8);
		SetEntityHealth(client, healStatus-slapDmg);   //use this instat of SlapPlayer because SlapPlayer move Player
		//SlapPlayer(client,slapDmg,true);
	}

	return Plugin_Handled;

}

public OnMapStart()
{
	g_iAmmo = FindSendPropOffs("CDODPlayer", "m_iAmmo")
}



public PlayerSpawnEvent(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"))
	
	if (client > 0 && (c_slow || c_grav))
	{
	
		ResetBleedTimer(client);

		if (IsClientInGame(client))
		{
			legShot[client]=false;
			legShotOld[client]=false;
  			g_playerWheight[client]=75.0;
			g_playerSpeed[client]=1.0;
			g_playerGrav[client]=1.0;
			g_playerLegDamage[client]=0;
			g_playerHeal[client]=GetClientHealth(client);
			if(g_playerBlood[client])
			{
				g_playerBlood[client]=false;
				ClientCommand(client,"r_screenoverlay 0");
			}

			//camp counter
			g_campCounter[client]=c_campMaxCount;
			GetClientAbsOrigin(client, g_campPosSpawn[client]); //spawn position
			g_campSpawn[client]=true;
			GetClientAbsOrigin(client, g_campPosLast[client]);

			if(weaponTimer[client] == INVALID_HANDLE)
			{
				weaponTimer[client] = CreateTimer(1.0, CheckWheightNow, client,TIMER_REPEAT |TIMER_FLAG_NO_MAPCHANGE);
			}
			
		}
		
	}

}

public OnClientPutInServer(client)
{	
	ResetTimers(client);
	ResetBleedTimer(client);
	g_playerBlood[client]=false;
}


public PlayerDeathEvent(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"))
	ResetBleedTimer(client); //kill bleed timer on death ever
	if (client == 0)
	{
		ResetTimers(client);
		
	}
}


//Reset timer if someone join spectator
public PlayerChangeTeamEvent(Handle:event, const String:name[], bool:dontBroadcast)
{
	
	new team = GetEventInt(event, "team");
	if(team==1)
	{
		new client = GetClientOfUserId(GetEventInt(event, "userid"));
		ResetTimers(client);
		ResetBleedTimer(client);
	}
			
}


public PlayerHurtEvent(Handle:event, const String:name[], bool:dontBroadcast)
{
	new clientId = GetEventInt(event, "userid");
	new client     = GetClientOfUserId(clientId)
	
	if (client > 0)
	{
		if (IsClientInGame(client))
		{
			new String:weapon[32]  
			GetEventString(event, "weapon", weapon, 32)
			
			new hitgroup = GetEventInt(event, "hitgroup")
			new damage   = GetEventInt(event, "damage")
			
			// Hitgroups
			// 1 = Head
			// 2 = Upper Chest
			// 3 = Lower Chest
			// 4 = Left arm
			// 5 = Right arm
			// 6 = Left leg
			// 7 = Right Leg
			  
				
			if (damage >= 40)
			{
				if(c_blood && ((hitgroup == 1) || (hitgroup == 2))) //blood overlay
				{
					g_playerBlood[client]=true;
					ClientCommand(client,g_blood[GetRandomInt(0, 2)]);
					PrintToChat(client,"Blood throw to your face - type \x01\x04!medic\x01 for bandage you");
				}
				else if (c_drop && ((hitgroup == 4) || (hitgroup == 5))) //drop weapon
				{
					//baz = bazooka ; ps = pschreck) ; fr = frag_* ; ri = riflegren_*
					// only drop on normal weapon
					if (!(strncmp(weapon, "baz",3)==0 || strncmp(weapon, "ps",2)==0 || strncmp(weapon, "fr",2)==0 || strncmp(weapon, "ri",2)==0))
					{
						FakeClientCommandEx(client, "drop");
						PrintToChat(client,"\x01\x04You got shot in the arm - pick up your gun");

					}
				}
				
				//bleeding part
				if(c_bleed && GetClientHealth(client)>0)
				{

					strcopy(bleedWeapon[client],32,weapon);
					bleedValues[client][USERID]=clientId;
					bleedValues[client][ATTACKER]=GetEventInt(event, "attacker");
					bleedValues[client][HITGROUP]=hitgroup;
					bleedValues[client][BLEEDCOUNTER]++;
					if(bleedTimer[client] == INVALID_HANDLE)
					{
						if(c_selfHealBleed)
							PrintToChat(client,"\x01You bleed - type \x05!medic\x01 to stop bleeding");
						else
							PrintToChat(client,"\x01You bleed - find a medic, he can heal you");
						bleedTimer[client] = CreateTimer(GetRandomFloat(2.0, 5.0), BleedEvent, client,TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
					}

				}
			}
			
			//slow down on hit
			if (c_slow)
			{		
				if ((hitgroup == 6) || (hitgroup == 7))
				{
					g_playerLegDamage[client]+=damage;
					legShot[client]=true; //set lagshot flag that the calculation know from that
					
				}
			}
			
		}
	}
}


public OnClientDisconnect(client)
{	
	ResetBleedTimer(client);
	ResetTimers(client)
}


//this is the full camping module
public bool:IsCamping(client)
{

	new Float:posNow[3];
	GetClientAbsOrigin(client, posNow);

	if(g_campSpawn[client])
	{
		if(GetVectorDistance(posNow, g_campPosSpawn[client],false) < 150.0) //spawn area
			return false;
		
		g_campSpawn[client]=false;
	}

	if((GetVectorDistance(posNow, g_campPosLast[client],false) < CAMPDISTANCE))
	{
		//search wepon
		new String:weapon[32];
		GetClientWeapon(client, weapon, 32);

		
		g_campPosLast[client][0]=posNow[0];
                g_campPosLast[client][1]=posNow[1];
                g_campPosLast[client][2]=posNow[2];


		//bazuka and mg can camp
		if (strncmp(weapon, "weapon_mg",9)==0 || strncmp(weapon, "weapon_30",9)==0 || strncmp(weapon, "weapon_baz",10)==0 || strncmp(weapon, "weapon_ps",9)==0)
		{
			if(g_campCounter[client]<c_campMaxCount)
				g_campCounter[client]++;
			return false;
		}
		if(g_campCounter[client]>0)
			g_campCounter[client]--;

		if(g_campCounter[client]==5)
			PrintToChat(client,"\x01\x05You will get slaped in 5 seconds for camping!!\x01");
		else if(g_campCounter[client]==0)
		{
			//slap player while camping
			new healStatus=GetClientHealth(client);
			PrintToChat(client,"\x01\x05You shall not camp on this server!!\x01");
			EmitSoundToClient(client, "player/damage/male/minorpain3.wav", _, _, _, _, 0.8);
			SetEntityHealth(client, healStatus-c_slapDmg);
			g_campCounter[client]+=c_slapDiff;
			if((healStatus-c_slapDmg)<=0)
			{
				SetEntityHealth(client,0);
				new Handle:campDeath = CreateEvent("player_hurt", true);
				SetEventInt(campDeath, "userid", GetClientUserId(client));
				SetEventInt(campDeath, "attacker", GetClientUserId(client));
				SetEventString(campDeath, "weapon", "camping")
				SetEventInt(campDeath, "health", 0)
				SetEventInt(campDeath, "damage", c_slapDmg)
				SetEventInt(campDeath, "hitgroup", 0)
				FireEvent(campDeath, false)
				FakeClientCommandEx(client, "kill");
			}
		}
		
		return true;
	}
	if(g_campCounter[client]<c_campMaxCount)
		g_campCounter[client]+=2;
	g_campPosLast[client][0]=posNow[0];
        g_campPosLast[client][1]=posNow[1];
        g_campPosLast[client][2]=posNow[2];
	return false;
}


