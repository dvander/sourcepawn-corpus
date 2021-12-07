#include <sourcemod>
#include <sdktools>


#define SM_ADVANCED_LASER_VERSION	"1.1"

#define MAX_FILE_LEN 80

 //   "usp", //USP  Pistol
 //   "glock", //Glock Pistol 
 //   "deagle", //Desert Eagle (deagle) Pistol
 //   "p228", //228 Compact Pistol
 //   "elite", //Dualies (elite) Pistol
 //   "fiveseven", //Five-Seven (fiveseven) Pistol
 //   "m4a1", //Maverick M4A1 USP (m4a1) Sturmgewehr
 //   "ak47", //AK-47/CV-47 (ak47) Sturmgewehr
 //   "aug",  //Bullpup (aug) Sturmgewehr
 //   "sg552",    //Krieg 552 (sg552) Sturmgewehr
 //   "galil",    //Defender (galil) Sturmgewehr
 //   "famas",    //Clarion (famas) Sturmgewehr
 //   "scout",    //Scout (scout) Sniper
 //   "sg550",    //Krieg Commando (sg550) Sniper
 //   "m249", //M249 (m249) Maschinengewehr !!!
 //   "g3sg1",    //D3/AU1 (g3sg1) Sniper
 //   "ump45", //UMP (ump45) Maschinenpistole
 //   "mp5navy", //MP5 (mp5navy) Maschinenpistole
 //   "m3", //Pump Shotgun (m3) Shotgun 
 //   "xm1014", //Auto Shotgun (xm1014) Shotgun
 //   "tmp", //TMP (tmp) Maschinenpistole
 //   "mac10", //Mac-10 (mac10) Maschinenpistole
 //   "p90",  //P90 (p90) Maschinenpistole !!!
 //   "awp",  //AWP (awp) Sniper
//    "knife" // Messer


new Handle:g_version = INVALID_HANDLE;
new Handle:g_Cvar_Enable = INVALID_HANDLE;

new redColor[4] = {255, 25, 25, 150};
new greenColor[4] = {0, 255, 80, 150};

new g_BeamSprite[19];

new Handle:g_CvarM249Life = INVALID_HANDLE;
new Handle:g_CvarM249Width = INVALID_HANDLE;

new Handle:g_CvarP90Life = INVALID_HANDLE;
new Handle:g_CvarP90Width = INVALID_HANDLE;

new Handle:g_CvarUSPLife = INVALID_HANDLE;
new Handle:g_CvarUSPWidth = INVALID_HANDLE;

new Handle:g_CvarGlockLife = INVALID_HANDLE;
new Handle:g_CvarGlockWidth = INVALID_HANDLE;

new Handle:g_CvarDeagleLife = INVALID_HANDLE;
new Handle:g_CvarDeagleWidth = INVALID_HANDLE;

new Handle:g_CvarXM1014Life = INVALID_HANDLE;
new Handle:g_CvarXM1014Width = INVALID_HANDLE;

new Handle:g_CvarM3Life = INVALID_HANDLE;
new Handle:g_CvarM3Width = INVALID_HANDLE;

new Handle:g_CvarP228Life = INVALID_HANDLE;
new Handle:g_CvarP228Width = INVALID_HANDLE;

new Handle:g_CvarMP5Life = INVALID_HANDLE;
new Handle:g_CvarMP5Width = INVALID_HANDLE;

new Handle:g_CvarUMP45Life = INVALID_HANDLE;
new Handle:g_CvarUMP45Width = INVALID_HANDLE;

new Handle:g_CvarAWPLife = INVALID_HANDLE;
new Handle:g_CvarAWPWidth = INVALID_HANDLE;

new Handle:g_CvarScoutLife = INVALID_HANDLE;
new Handle:g_CvarScoutWidth = INVALID_HANDLE;

new Handle:g_CvarSG550Life = INVALID_HANDLE;
new Handle:g_CvarSG550Width = INVALID_HANDLE;

new Handle:g_CvarG3sg1Life = INVALID_HANDLE;
new Handle:g_CvarG3sg1Width = INVALID_HANDLE;

new Handle:g_CvarTMPLife = INVALID_HANDLE;
new Handle:g_CvarTMPWidth = INVALID_HANDLE;

new Handle:g_CvarMAC10Life = INVALID_HANDLE;
new Handle:g_CvarMAC10Width = INVALID_HANDLE;

new Handle:g_CvarM4A1Life = INVALID_HANDLE;
new Handle:g_CvarM4A1Width = INVALID_HANDLE;

new Handle:g_CvarAK47Life = INVALID_HANDLE;
new Handle:g_CvarAK47Width = INVALID_HANDLE;

new Handle:g_CvarEliteLife = INVALID_HANDLE;
new Handle:g_CvarEliteWidth = INVALID_HANDLE;

new Handle:g_CvarFivesevenLife = INVALID_HANDLE;
new Handle:g_CvarFivesevenWidth = INVALID_HANDLE;

new Handle:g_CvarSG552Life = INVALID_HANDLE;
new Handle:g_CvarSG552Width = INVALID_HANDLE;

new Handle:g_CvarFamasLife = INVALID_HANDLE;
new Handle:g_CvarFamasWidth = INVALID_HANDLE;

new Handle:g_CvarAUGLife = INVALID_HANDLE;
new Handle:g_CvarAUGWidth = INVALID_HANDLE;

new Handle:g_CvarGalilLife = INVALID_HANDLE;
new Handle:g_CvarGalilWidth = INVALID_HANDLE;


public Plugin:myinfo = 
{
	name = "SM Advanced Laser 1.1",
	author = "Andi67",
	description = "Add a Laser to Weapons",
	version = SM_ADVANCED_LASER_VERSION,
	url = "http://www.dodsourceplugins.net"
}

public OnPluginStart()
{
	g_version = CreateConVar("sm_advanced_laser_version",SM_ADVANCED_LASER_VERSION,"SM ADVANCED LASER VERSION",FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	SetConVarString(g_version,SM_ADVANCED_LASER_VERSION);
	g_Cvar_Enable = CreateConVar("sm_advanced_laser_on", "1", "1 turns the plugin on 0 is off", FCVAR_PLUGIN ,true, 0.0, true, 1.0);
	
	g_CvarM249Life = CreateConVar("sm_advanced_laser_M249Life", "0.5", "Life of the Beam",FCVAR_PLUGIN);
	g_CvarM249Width = CreateConVar("sm_advanced_laser_M249Width", "2.0", "Width of the Beam",FCVAR_PLUGIN);
	g_CvarP90Life = CreateConVar("sm_advanced_laser_P90Life", "0.5", "Life of the Beam",FCVAR_PLUGIN);
	g_CvarP90Width = CreateConVar("sm_advanced_laser_P90Width", "3.0", "Width of the Beam",FCVAR_PLUGIN);	
	g_CvarUSPLife = CreateConVar("sm_advanced_laser_USPLife", "0.5", "Life of the Beam",FCVAR_PLUGIN);
	g_CvarUSPWidth = CreateConVar("sm_advanced_laser_USPWidth", "1.0", "Width of the Beam",FCVAR_PLUGIN);
	g_CvarGlockLife = CreateConVar("sm_advanced_laser_GlockLife", "0.5", "Life of the Beam",FCVAR_PLUGIN);
	g_CvarGlockWidth = CreateConVar("sm_advanced_laser_GlockWidth", "1.0", "Width of the Beam",FCVAR_PLUGIN);
	g_CvarDeagleLife = CreateConVar("sm_advanced_laser_DeagleLife", "0.5", "Life of the Beam",FCVAR_PLUGIN);
	g_CvarDeagleWidth = CreateConVar("sm_advanced_laser_DeagleWidth", "2.0", "Width of the Beam",FCVAR_PLUGIN);
	g_CvarXM1014Life = CreateConVar("sm_advanced_laser_XM1014Life", "0.5", "Life of the Beam",FCVAR_PLUGIN);
	g_CvarXM1014Width = CreateConVar("sm_advanced_laser_XM1014Width", "1.0", "Width of the Beam",FCVAR_PLUGIN);
	g_CvarM3Life = CreateConVar("sm_advanced_laser_M3Life", "0.5", "Life of the Beam",FCVAR_PLUGIN);
	g_CvarM3Width = CreateConVar("sm_advanced_laser_M3Width", "1.0", "Width of the Beam",FCVAR_PLUGIN);
	g_CvarP228Life = CreateConVar("sm_advanced_laser_P228Life", "0.5", "Life of the Beam",FCVAR_PLUGIN);
	g_CvarP228Width = CreateConVar("sm_advanced_laser_P228Width", "1.0", "Width of the Beam",FCVAR_PLUGIN);
	g_CvarMP5Life = CreateConVar("sm_advanced_laser_MP5Life", "0.5", "Life of the Beam",FCVAR_PLUGIN);
	g_CvarMP5Width = CreateConVar("sm_advanced_laser_MP5Width", "3.5", "Width of the Beam",FCVAR_PLUGIN);
	g_CvarUMP45Life = CreateConVar("sm_advanced_laser_UMP45Life", "0.5", "Life of the Beam",FCVAR_PLUGIN);
	g_CvarUMP45Width = CreateConVar("sm_advanced_laser_UMP45Width", "1.0", "Width of the Beam",FCVAR_PLUGIN);
	g_CvarAWPLife = CreateConVar("sm_advanced_laser_AWPLife", "0.5", "Life of the Beam",FCVAR_PLUGIN);
	g_CvarAWPWidth = CreateConVar("sm_advanced_laser_AWPWidth", "1.0", "Width of the Beam",FCVAR_PLUGIN);
	g_CvarSG550Life = CreateConVar("sm_advanced_laser_SG550Life", "0.5", "Life of the Beam",FCVAR_PLUGIN);
	g_CvarSG550Width = CreateConVar("sm_advanced_laser_SG550Width", "1.0", "Width of the Beam",FCVAR_PLUGIN);
	g_CvarScoutLife = CreateConVar("sm_advanced_laser_ScoutLife", "0.5", "Life of the Beam",FCVAR_PLUGIN);
	g_CvarScoutWidth = CreateConVar("sm_advanced_laser_ScoutWidth", "1.0", "Width of the Beam",FCVAR_PLUGIN);
	g_CvarG3sg1Life = CreateConVar("sm_advanced_laser_G3sg1Life", "0.5", "Life of the Beam",FCVAR_PLUGIN);
	g_CvarG3sg1Width = CreateConVar("sm_advanced_laser_G3sg1Width", "1.0", "Width of the Beam",FCVAR_PLUGIN);
	g_CvarTMPLife= CreateConVar("sm_advanced_laser_TMPLife", "0.5", "Life of the Beam",FCVAR_PLUGIN);
	g_CvarTMPWidth = CreateConVar("sm_advanced_laser_TMPWidth", "3.0", "Width of the Beam",FCVAR_PLUGIN);
	g_CvarMAC10Life = CreateConVar("sm_advanced_laser_MAC10Life", "0.5", "Life of the Beam",FCVAR_PLUGIN);
	g_CvarMAC10Width = CreateConVar("sm_advanced_laser_MAC10Width", "3.0", "Width of the Beam",FCVAR_PLUGIN);
	g_CvarM4A1Life = CreateConVar("sm_advanced_laser_M4A1Life", "0.5", "Life of the Beam",FCVAR_PLUGIN);
	g_CvarM4A1Width = CreateConVar("sm_advanced_laser_M4A1Width", "3.0", "Width of the Beam",FCVAR_PLUGIN);
	g_CvarAK47Life = CreateConVar("sm_advanced_laser_AK47Life", "0.5", "Life of the Beam",FCVAR_PLUGIN);
	g_CvarAK47Width = CreateConVar("sm_advanced_laser_AK47Width", "1.5", "Width of the Beam",FCVAR_PLUGIN);
	g_CvarEliteLife = CreateConVar("sm_advanced_laser_EliteLife", "0.5", "Life of the Beam",FCVAR_PLUGIN);
	g_CvarEliteWidth = CreateConVar("sm_advanced_laser_EliteWidth", "1.5", "Width of the Beam",FCVAR_PLUGIN);
	g_CvarFivesevenLife = CreateConVar("sm_advanced_laser_FivesevenLife", "0.5", "Life of the Beam",FCVAR_PLUGIN);
	g_CvarFivesevenWidth = CreateConVar("sm_advanced_laser_FivesevenWidth", "1.5", "Width of the Beam",FCVAR_PLUGIN);
	g_CvarSG552Life = CreateConVar("sm_advanced_laser_SG552Life", "0.5", "Life of the Beam",FCVAR_PLUGIN);
	g_CvarSG552Width = CreateConVar("sm_advanced_laser_SG552Width", "1.0", "Width of the Beam",FCVAR_PLUGIN);
	g_CvarFamasLife = CreateConVar("sm_advanced_laser_FamasLife", "0.5", "Life of the Beam",FCVAR_PLUGIN);
	g_CvarFamasWidth = CreateConVar("sm_advanced_laser_FamasWidth", "1.0", "Width of the Beam",FCVAR_PLUGIN);
	g_CvarAUGLife = CreateConVar("sm_advanced_laser_AUGLife", "0.5", "Life of the Beam",FCVAR_PLUGIN);
	g_CvarAUGWidth = CreateConVar("sm_advanced_laser_AUGWidth", "1.0", "Width of the Beam",FCVAR_PLUGIN);
	g_CvarGalilLife = CreateConVar("sm_advanced_laser_GalilLife", "0.5", "Life of the Beam",FCVAR_PLUGIN);
	g_CvarGalilWidth = CreateConVar("sm_advanced_laser_GalilWidth", "1.0", "Width of the Beam",FCVAR_PLUGIN);
	
	AutoExecConfig(true,"sm_advanced_laser", "sm_advanced_laser")

	
	HookEvent("weapon_fire",Event_WeaponFire);
}

public OnMapStart()
{
	g_BeamSprite [1]= PrecacheModel("materials/sprites/laser.vmt");
	g_BeamSprite [2]= PrecacheModel("materials/sprites/laserbeam.vmt");
	g_BeamSprite [3]= PrecacheModel("materials/sprites/animglow02.vmt");
	g_BeamSprite [4]= PrecacheModel("materials/sprites/bluelight1.vmt");
	g_BeamSprite [5]= PrecacheModel("materials/sprites/crystal_beam1.vmt");
	g_BeamSprite [6]= PrecacheModel("materials/sprites/glow04.vmt");
	g_BeamSprite [7]= PrecacheModel("materials/sprites/lgtning.vmt");
	g_BeamSprite [8]= PrecacheModel("materials/sprites/physbeam.vmt");
	g_BeamSprite [9]= PrecacheModel("materials/sprites/physcannon_blueflare1.vmt");
	g_BeamSprite [10]= PrecacheModel("materials/sprites/bluelaser1.vmt");
	g_BeamSprite [11]= PrecacheModel("materials/sprites/combineball_trail_red_1.vmt");
	g_BeamSprite [12]= PrecacheModel("materials/sprites/orangelight1.vmt");
	g_BeamSprite [13]= PrecacheModel("materials/sprites/purplelaser1.vmt");
	g_BeamSprite [14]= PrecacheModel("materials/sprites/xbeam2.vmt");
	g_BeamSprite [15]= PrecacheModel("materials/sprites/lamphalo.vmt");
	g_BeamSprite [16]= PrecacheModel("materials/sprites/light_glow01.vmt");
	g_BeamSprite [17]= PrecacheModel("materials/sprites/redglow2.vmt");
	g_BeamSprite [18]= PrecacheModel("materials/sprites/splodesprite.vmt");	
}

public OnPluginEnd()
{
	CloseHandle(g_version);
}

public Event_WeaponFire(Handle:event, const String:name[], bool:dontBroadcast)
{
	if( GetConVarBool(g_Cvar_Enable) )
	{
		new client;
		client = GetClientOfUserId(GetEventInt(event, "userid"));

		new Float:M249Life;
		M249Life = GetConVarFloat( g_CvarM249Life );
		new Float:M249Width;
		M249Width = GetConVarFloat( g_CvarM249Width );		
		
		new Float:P90Life;
		P90Life = GetConVarFloat( g_CvarP90Life );
		new Float:P90Width;
		P90Width = GetConVarFloat( g_CvarP90Width );		
		
		new Float:USPLife;
		USPLife = GetConVarFloat( g_CvarUSPLife );
		new Float:USPWidth;
		USPWidth = GetConVarFloat( g_CvarUSPWidth );
	
		new Float:P228Life;
		P228Life = GetConVarFloat( g_CvarP228Life );
		new Float:P228Width;
		P228Width = GetConVarFloat( g_CvarP228Width );
	
		new Float:GlockLife;
		GlockLife = GetConVarFloat( g_CvarGlockLife );
		new Float:GlockWidth;
		GlockWidth= GetConVarFloat( g_CvarGlockWidth );
	
		new Float:XM1014Life;
		XM1014Life = GetConVarFloat( g_CvarXM1014Life );
		new Float:XM1014Width;
		XM1014Width = GetConVarFloat( g_CvarXM1014Width );
	
		new Float:M3Life;
		M3Life = GetConVarFloat( g_CvarM3Life );
		new Float:M3Width;
		M3Width = GetConVarFloat( g_CvarM3Width );
	
		new Float:DeagleLife;
		DeagleLife = GetConVarFloat( g_CvarDeagleLife );
		new Float:DeagleWidth;
		DeagleWidth = GetConVarFloat( g_CvarDeagleWidth );
	
		new Float:MP5Life;
		MP5Life = GetConVarFloat( g_CvarMP5Life );
		new Float:MP5Width ;
		MP5Width  = GetConVarFloat( g_CvarMP5Width );
	
		new Float:UMP45Life;
		UMP45Life = GetConVarFloat( g_CvarUMP45Life );
		new Float:UMP45Width ;
		UMP45Width  = GetConVarFloat( g_CvarUMP45Width );
	
		new Float:AWPLife;
		AWPLife = GetConVarFloat( g_CvarAWPLife );
		new Float:AWPWidth;
		AWPWidth = GetConVarFloat( g_CvarAWPWidth );
	
		new Float:ScoutLife;
		ScoutLife = GetConVarFloat( g_CvarScoutLife );
		new Float:ScoutWidth;
		ScoutWidth = GetConVarFloat( g_CvarScoutWidth );
	
		new Float:SG550Life;
		SG550Life = GetConVarFloat( g_CvarSG550Life );
		new Float:SG550Width ;
		SG550Width  = GetConVarFloat( g_CvarSG550Width );
	
		new Float:G3sg1Life;
		G3sg1Life = GetConVarFloat( g_CvarG3sg1Life );
		new Float:G3sg1Width ;
		G3sg1Width  = GetConVarFloat( g_CvarG3sg1Width );
	
		new Float:TMPLife;
		TMPLife = GetConVarFloat( g_CvarTMPLife );
		new Float:TMPWidth;
		TMPWidth = GetConVarFloat( g_CvarTMPWidth );
	
		new Float:MAC10Life;
		MAC10Life = GetConVarFloat( g_CvarMAC10Life );
		new Float:MAC10Width;
		MAC10Width = GetConVarFloat( g_CvarMAC10Width );
	
		new Float:M4A1Life;
		M4A1Life = GetConVarFloat( g_CvarM4A1Life );
		new Float:M4A1Width;
		M4A1Width = GetConVarFloat( g_CvarM4A1Width );
	
		new Float:EliteLife;
		EliteLife = GetConVarFloat( g_CvarEliteLife );
		new Float:EliteWidth;
		EliteWidth = GetConVarFloat( g_CvarEliteWidth );
	
		new Float:AK47Life;
		AK47Life = GetConVarFloat( g_CvarAK47Life );
		new Float:AK47Width ;
		AK47Width  = GetConVarFloat( g_CvarAK47Width );
	
		new Float:FivesevenLife;
		FivesevenLife = GetConVarFloat( g_CvarFivesevenLife );
		new Float:FivesevenWidth ;
		FivesevenWidth  = GetConVarFloat( g_CvarFivesevenWidth );
	
		new Float:SG552Life;
		SG552Life = GetConVarFloat( g_CvarSG552Life );
		new Float:SG552Width;
		SG552Width = GetConVarFloat( g_CvarSG552Width );
	
		new Float:AUGLife;
		AUGLife = GetConVarFloat( g_CvarAUGLife );
		new Float:AUGWidth;
		AUGWidth = GetConVarFloat( g_CvarAUGWidth );
	
		new Float:FamasLife;
		FamasLife = GetConVarFloat( g_CvarFamasLife );
		new Float:FamasWidth;
		FamasWidth = GetConVarFloat( g_CvarFamasWidth );
		
		new Float:GalilLife;
		GalilLife = GetConVarFloat( g_CvarGalilLife );
		new Float:GalilWidth;
		GalilWidth = GetConVarFloat( g_CvarGalilWidth );
		
	
		decl Float:vecOrigin[3], Float:vecAng[3], Float:vecPos[3];
		GetClientEyePosition(client, vecOrigin);
		GetClientEyeAngles(client, vecAng);
		new Handle:trace = TR_TraceRayFilterEx(vecOrigin, vecAng, MASK_SHOT_HULL, RayType_Infinite, TraceEntityFilterPlayer);	
	
		new String:sWeapon[32];
		GetClientWeapon(client,sWeapon, sizeof(sWeapon));
	
		if(TR_DidHit(trace))
		{
			if(StrEqual ("weapon_m249" , sWeapon))
			{
			TR_GetEndPosition(vecPos, trace);
			vecOrigin[0] += 0;
			vecOrigin[1] -= 0;
			vecOrigin[2] -= 1;
			
			CloseHandle(trace);
		
			TE_SetupBeamPoints(vecOrigin, vecPos, g_BeamSprite[12], 0, 0, 0, M249Life, M249Width, M249Width, 1, 0.0, greenColor, 0);
			TE_SendToAll();
			}
			
			if(StrEqual ("weapon_p90" , sWeapon))
			{
			TR_GetEndPosition(vecPos, trace);
			vecOrigin[0] += 0;
			vecOrigin[1] -= 0;
			vecOrigin[2] -= 1;
			
			CloseHandle(trace);
		
			TE_SetupBeamPoints(vecOrigin, vecPos, g_BeamSprite[9], 0, 0, 0, P90Life, P90Width, P90Width, 1, 0.0, greenColor, 0);
			TE_SendToAll();
			}			
		
			if(StrEqual ("weapon_usp" , sWeapon))
			{
			TR_GetEndPosition(vecPos, trace);
			vecOrigin[0] += 0;
			vecOrigin[1] -= 0;
			vecOrigin[2] -= 1;
			
			CloseHandle(trace);
		
			TE_SetupBeamPoints(vecOrigin, vecPos, g_BeamSprite[1], 0, 0, 0, USPLife, USPWidth, USPWidth, 1, 0.0, greenColor, 0);
			TE_SendToAll();
			}
			
			if(StrEqual ("weapon_glock" , sWeapon))
			{
			TR_GetEndPosition(vecPos, trace);
			vecOrigin[0] -= 0;
			vecOrigin[1] -= 0;
			vecOrigin[2] -= 1;	
			
			CloseHandle(trace);
		
			TE_SetupBeamPoints(vecOrigin, vecPos, g_BeamSprite[2], 0, 0, 0, GlockLife, GlockWidth, GlockWidth, 1, 0.0, redColor, 0);
			TE_SendToAll();	
			}
		
			if(StrEqual ("weapon_deagle" , sWeapon))
			{
			TR_GetEndPosition(vecPos, trace);
			vecOrigin[0] -= 0;
			vecOrigin[1] -= 0;
			vecOrigin[2] -= 1;	
			
			CloseHandle(trace);
		
			TE_SetupBeamPoints(vecOrigin, vecPos, g_BeamSprite[3], 0, 0, 0, DeagleLife, DeagleWidth, DeagleWidth, 1, 0.0, redColor, 0);
			TE_SendToAll();		
			}
		
			if(StrEqual ("weapon_xm1014" , sWeapon))
			{
			TR_GetEndPosition(vecPos, trace);
			vecOrigin[0] += 0;
			vecOrigin[1] -= 0;
			vecOrigin[2] -= 1;	
			
			CloseHandle(trace);
		
			TE_SetupBeamPoints(vecOrigin, vecPos, g_BeamSprite[4], 0, 0, 0, XM1014Life, XM1014Width, XM1014Width, 1, 0.0, greenColor, 0);
			TE_SendToAll();		
			}
	
			if(StrEqual ("weapon_p228" , sWeapon))
			{
			TR_GetEndPosition(vecPos, trace);
			vecOrigin[0] += 0;
			vecOrigin[1] -= 0;
			vecOrigin[2] -= 1;	
			
			CloseHandle(trace);
		
			TE_SetupBeamPoints(vecOrigin, vecPos, g_BeamSprite[5], 0, 0, 0, P228Life, P228Width, P228Width, 1, 0.0, greenColor, 0);
			TE_SendToAll();		
			}
	
			if(StrEqual ("weapon_mp5navy" , sWeapon))
			{
			TR_GetEndPosition(vecPos, trace);
			vecOrigin[0] -= 0;
			vecOrigin[1] -= 0;
			vecOrigin[2] -= 1;	
			
			CloseHandle(trace);
		
			TE_SetupBeamPoints(vecOrigin, vecPos, g_BeamSprite[10], 0, 0, 0, MP5Life, MP5Width, MP5Width, 1, 0.0, redColor, 0);
			TE_SendToAll();	
			}
			
			if(StrEqual ("weapon_awp" , sWeapon))
			{
			TR_GetEndPosition(vecPos, trace);
			vecOrigin[0] += 0;
			vecOrigin[1] -= 0;
			vecOrigin[2] -= 1;	
			
			CloseHandle(trace);
		
			TE_SetupBeamPoints(vecOrigin, vecPos, g_BeamSprite[7], 0, 0, 0, AWPLife, AWPWidth, AWPWidth, 1, 0.0, greenColor, 0);
			TE_SendToAll();		
			}
			
			if(StrEqual ("weapon_sg550" , sWeapon))
			{
			TR_GetEndPosition(vecPos, trace);
			vecOrigin[0] -= 0;
			vecOrigin[1] -= 0;
			vecOrigin[2] -= 1;	
			
			CloseHandle(trace);
		
			TE_SetupBeamPoints(vecOrigin, vecPos, g_BeamSprite[8], 0, 0, 0, SG550Life, SG550Width,SG550Width, 1, 0.0, redColor, 0);
			TE_SendToAll();		
			}
			
			if(StrEqual ("weapon_tmp" , sWeapon))
			{
			TR_GetEndPosition(vecPos, trace);
			vecOrigin[0] += 0;
			vecOrigin[1] -= 0;
			vecOrigin[2] -= 1;		
			
			CloseHandle(trace);
		
			TE_SetupBeamPoints(vecOrigin, vecPos, g_BeamSprite[9], 0, 0, 0, TMPLife, TMPWidth, TMPWidth, 1, 0.0, greenColor, 0);
			TE_SendToAll();			
			}
	
			if(StrEqual ("weapon_mac10" , sWeapon))
			{
			TR_GetEndPosition(vecPos, trace);
			vecOrigin[0] -= 0;
			vecOrigin[1] -= 0;
			vecOrigin[2] -= 1;
			
			CloseHandle(trace);
		
			TE_SetupBeamPoints(vecOrigin, vecPos, g_BeamSprite[6], 0, 0, 0, MAC10Life, MAC10Width, MAC10Width, 1, 0.0, redColor, 0);
			TE_SendToAll();		
			}
	
			if(StrEqual ("weapon_m4a1" , sWeapon))
			{
			TR_GetEndPosition(vecPos, trace);
			vecOrigin[0] -= 0;
			vecOrigin[1] -= 0;
			vecOrigin[2] -= 1;	
			
			CloseHandle(trace);
		
			TE_SetupBeamPoints(vecOrigin, vecPos, g_BeamSprite[9], 0, 0, 0,M4A1Life, M4A1Width, M4A1Width, 1, 0.0, redColor, 0);
			TE_SendToAll();		
			}

			if(StrEqual ("weapon_ak47" , sWeapon))
			{
			TR_GetEndPosition(vecPos, trace);
			vecOrigin[0] += 0;
			vecOrigin[1] -= 0;
			vecOrigin[2] -= 1;	
			
			CloseHandle(trace);
		
			TE_SetupBeamPoints(vecOrigin, vecPos, g_BeamSprite[18], 0, 0, 0, AK47Life, AK47Width, AK47Width ,1, 0.0, greenColor, 0);
			TE_SendToAll();		
			}

			if(StrEqual ("weapon_sg552" , sWeapon))
			{
			TR_GetEndPosition(vecPos, trace);
			vecOrigin[0] += 0;
			vecOrigin[1] -= 0;
			vecOrigin[2] -= 1;	
			
			CloseHandle(trace);
		
			TE_SetupBeamPoints(vecOrigin, vecPos, g_BeamSprite[13], 0, 0, 0, SG552Life, SG552Width, SG552Width, 1, 0.0, greenColor, 0);
			TE_SendToAll();		
			}
	
			if(StrEqual ("weapon_famas" , sWeapon))
			{
			TR_GetEndPosition(vecPos, trace);
			vecOrigin[0] -= 0;
			vecOrigin[1] -= 0;
			vecOrigin[2] -= 1;	
			
			CloseHandle(trace);
		
			TE_SetupBeamPoints(vecOrigin, vecPos, g_BeamSprite[14], 0, 0, 0, FamasLife, FamasWidth, FamasWidth, 1, 0.0, redColor, 0);
			TE_SendToAll();		
			}	
	
			if(StrEqual ("weapon_m3" , sWeapon))
			{
			TR_GetEndPosition(vecPos, trace);
			vecOrigin[0] += 0;
			vecOrigin[1] -= 0;
			vecOrigin[2] -= 1;	
			
			CloseHandle(trace);
		
			TE_SetupBeamPoints(vecOrigin, vecPos, g_BeamSprite[5], 0, 0, 0, M3Life, M3Width, M3Width, 1, 0.0, greenColor, 0);
			TE_SendToAll();
			}		
	
			if(StrEqual ("weapon_ump45" , sWeapon))
			{
			TR_GetEndPosition(vecPos, trace);
			vecOrigin[0] -= 0;
			vecOrigin[1] -= 0;
			vecOrigin[2] -= 1;	
			
			CloseHandle(trace);
		
			TE_SetupBeamPoints(vecOrigin, vecPos, g_BeamSprite[13], 0, 0, 0, UMP45Life, UMP45Width, UMP45Width, 1, 0.0, redColor, 0);
			TE_SendToAll();		
			}		
	
			if(StrEqual ("weapon_scout" , sWeapon))
			{
			TR_GetEndPosition(vecPos, trace);
			vecOrigin[0] += 0;
			vecOrigin[1] -= 0;
			vecOrigin[2] -= 1;	
			
			CloseHandle(trace);
		
			TE_SetupBeamPoints(vecOrigin, vecPos, g_BeamSprite[8], 0, 0, 0, ScoutLife, ScoutWidth, ScoutWidth, 1, 0.0, greenColor, 0);
			TE_SendToAll();	
			}		
	
			if(StrEqual ("weapon_g3sg1" , sWeapon))
			{
			TR_GetEndPosition(vecPos, trace);
			vecOrigin[0] -= 0;
			vecOrigin[1] -= 0;
			vecOrigin[2] -= 1;	
			
			CloseHandle(trace);
		
			TE_SetupBeamPoints(vecOrigin, vecPos, g_BeamSprite[14], 0, 0, 0, G3sg1Life, G3sg1Width, G3sg1Width, 1, 0.0, redColor, 0);
			TE_SendToAll();
			}		

			if(StrEqual ("weapon_aug" , sWeapon))
			{
			TR_GetEndPosition(vecPos, trace);
			vecOrigin[0] += 0;
			vecOrigin[1] -= 0;
			vecOrigin[2] -= 1;	
			
			CloseHandle(trace);
		
			TE_SetupBeamPoints(vecOrigin, vecPos, g_BeamSprite[11], 0, 0, 0, AUGLife, AUGWidth, AUGWidth, 1, 0.0, greenColor, 0);
			TE_SendToAll();	
			}

			if(StrEqual ("weapon_galil" , sWeapon))
			{
			TR_GetEndPosition(vecPos, trace);
			vecOrigin[0] -= 0;
			vecOrigin[1] -= 0;
			vecOrigin[2] -= 1;	
			
			CloseHandle(trace);
		
			TE_SetupBeamPoints(vecOrigin, vecPos, g_BeamSprite[5], 0, 0, 0, GalilLife, GalilWidth, GalilWidth, 1, 0.0, redColor, 0);
			TE_SendToAll();		
			}		
	
			if(StrEqual ("weapon_fiveseven" , sWeapon))
			{
			TR_GetEndPosition(vecPos, trace);
			vecOrigin[0] += 0;
			vecOrigin[1] -= 0;
			vecOrigin[2] -= 1;	
			
			CloseHandle(trace);
		
			TE_SetupBeamPoints(vecOrigin, vecPos, g_BeamSprite[12], 0, 0, 0, FivesevenLife, FivesevenWidth, FivesevenWidth, 1, 0.0, greenColor, 0);
			TE_SendToAll();		
			}		

			if(StrEqual ("weapon_elite" , sWeapon))
			{
			TR_GetEndPosition(vecPos, trace);
			vecOrigin[0] -= 0;
			vecOrigin[1] -= 0;
			vecOrigin[2] -= 1;	
			
			CloseHandle(trace);
		
			TE_SetupBeamPoints(vecOrigin, vecPos, g_BeamSprite[11], 0, 0, 0, EliteLife, EliteWidth, EliteWidth, 1, 0.0, redColor, 0);
			TE_SendToAll();	
			}
		}
	}
}


public bool:TraceEntityFilterPlayer(entity, contentsMask, any:client) 
{
	return entity>MaxClients;
}