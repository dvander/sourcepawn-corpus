#include <sourcemod>
#include <sdktools>
#include <sdktools_sound>



new Handle:v_SoundFile = INVALID_HANDLE;
new Handle:v_Enabled = INVALID_HANDLE;

public Plugin:myinfo = 
{
	name = "Boom Headshot Emires Edition",
	author = "LazyLizard",
	description = "Headshot gets the boom headshot sound make sure you have the file located in sound folder bhs/boomheadshot.mp3",
	version = "1.7"
	
}




public OnPluginStart()
{
	
		
	HookEvent("player_death", Event_PlayerDeath);
	
	v_SoundFile = CreateConVar("sm_bhs_soundfile", "bhs/boomheadshot.mp3", "path/file.ext to sound file");
	v_Enabled = CreateConVar("sm_bhs_enabled", "1", "Enable/Disable BoomHeadshot <1/0>", 0, true, 0.0, true, 1.0);
}

public OnMapStart() 
{
	new String:SoundFile[128]
	GetConVarString(v_SoundFile, SoundFile, sizeof(SoundFile))
	PrecacheSound(SoundFile,true);
	decl String:SoundFileLong[192];
	Format(SoundFileLong, sizeof(SoundFileLong), "sound/%s", SoundFile);
	AddFileToDownloadsTable(SoundFileLong);
	
}

public Action:Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (GetConVarBool(v_Enabled))
	{
	
		new Atckr = GetClientOfUserId(GetEventInt(event, "attacker"));
		new Vic = GetClientOfUserId(GetEventInt(event, "userid"));
		
		//new Atckr = GetEventInt(event, "attacker");
		//new Vic = GetEventInt(event, "userid");
		
		//new bool:headshot = GetEventBool(event, "headshot");
		
		decl 	String:weapon[32];
		GetEventString(event, "weapon", weapon, sizeof(weapon));
		
		
		new String:SoundFile[128]
		GetConVarString(v_SoundFile, SoundFile, sizeof(SoundFile))
		
		
//PrintToChatAll("value attacker %i" , Atckr);	
//PrintToChatAll("value victim %i" , Vic);		
		
//		decl 	String:weaponp1[1];
//		decl 	String:weaponp2[1];
		
		
		//weaponp1 = weapon[0];
		//weaponp2 = "u";
		
		
		
		if ((strcmp(weapon, "hs_imp_smg1", false) == 0)||(strcmp(weapon, "hs_imp_smg2", false) == 0)||(strcmp(weapon, "hs_imp_shotgun", false) == 0)||(strcmp(weapon, "hs_imp_pistol1", false) == 0)||(strcmp(weapon, "hs_imp_machinepistol", false) == 0)||(strcmp(weapon, "hs_imp_pistol2", false) == 0)||(strcmp(weapon, "hs_imp_rifle2", false) == 0)||(strcmp(weapon, "hs_imp_rifle1", false) == 0)||(strcmp(weapon, "hs_imp_hmg", false) == 0)||(strcmp(weapon, "hs_imp_rifle3", false) == 0)||(strcmp(weapon, "hs_nf_pistol", false) == 0)||(strcmp(weapon, "hs_nf_shot_pistol", false) == 0)||(strcmp(weapon, "hs_nf_smg1", false) == 0)||(strcmp(weapon, "hs_nf_smg2", false) == 0)||(strcmp(weapon, "hs_nf_smg3", false) == 0)||(strcmp(weapon, "hs_nf_shotgun", false) == 0)||(strcmp(weapon, "hs_nf_rifle", false) == 0)||(strcmp(weapon, "hs_nf_50cal", false) == 0)||(strcmp(weapon, "hs_nf_hmg", false) == 0)||(strcmp(weapon, "hs_nf_scout_rifle", false) == 0))


		
		//if(true)
		//if ((strcmp(weapon[0], "s", false) == 0)&&(strcmp(weapon[1], "u", false)==0))
		//if (strcmp(weaponp1, "s", false) == 0)
		{
			

				PlaySound(Atckr, Vic);
				return Plugin_Continue;
					
					}
		
	}
	return Plugin_Continue;
}

PlaySound(Atckr, Vic)
{
	
	new String:SoundFile[128]
	GetConVarString(v_SoundFile, SoundFile, sizeof(SoundFile))


	
		//EmitSoundToClient(1, SoundFile);
		//EmitSoundToClient(2, SoundFile);
		EmitSoundToClient(Atckr, SoundFile);
		EmitSoundToClient(Vic, SoundFile);
		
//PrintToChatAll("122222222222211111");	
	
}