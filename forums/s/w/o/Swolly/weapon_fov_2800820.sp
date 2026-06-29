#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
//////////////////////////////////////////////////////////////////////////////////////
int Oyuncunun_Fov[MAXPLAYERS + 1] = 90;
bool Fov_Aktif[MAXPLAYERS + 1];
//////////////////////////////////////////////////////////////////////////////////////
public Plugin myinfo = {
	name = "Weapon Fov",
	author = "Swolly",
	description = "Weapon Fov",
	url = "www.plugincim.com"
};
///////////////////////////////////////////////////////////////////////////////////////
public OnMapStart()
{
	//***********************************************************//	
	PrecacheSound("weapons/aug/aug_zoom_in.wav");	
	PrecacheSound("weapons/aug/aug_zoom_out.wav");						
	//***********************************************************//	
}
//////////////////////////////////////////////////////////////////////////////////////
public OnClientPostAdminCheck(client) 
{ 
	//******************************************//			
	SDKHook(client, SDKHook_WeaponSwitch, Slot);	
	//******************************************//		
} 
//////////////////////////////////////////////////////////////////////////////////////
public Action Slot(client) 
{
	//*********************************************//																								
	Fov_Aktif[client] = false;
	//*********************************************//					
	SetEntProp(client, Prop_Send, "m_bDrawViewmodel", 1);
	SetEntProp(client, Prop_Send, "m_iFOV", 90);		
	//*********************************************//													
	Oyuncunun_Fov[client] = 90;
	//*********************************************//		
}												
//////////////////////////////////////////////////////////////////////////////////////
public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3])
{
	if (IsClientInGame(client) && IsPlayerAlive(client))
	{
		if (buttons & IN_ATTACK2)
		{
			char SilahIsmi[64];		
			GetClientWeapon(client, SilahIsmi, sizeof(SilahIsmi));		
			
			if(StrEqual(SilahIsmi, "weapon_mp5sd", true) || StrEqual(SilahIsmi, "weapon_m4a1", true) || StrEqual(SilahIsmi, "weapon_ak47", true) || StrEqual(SilahIsmi, "weapon_galilar", true) || StrEqual(SilahIsmi, "weapon_bizon", true) || StrEqual(SilahIsmi, "weapon_mp7", true) || StrEqual(SilahIsmi, "weapon_mac10", true) || StrEqual(SilahIsmi, "weapon_mp9", true) || StrEqual(SilahIsmi, "weapon_p90", true) || StrEqual(SilahIsmi, "weapon_ump45", true) || StrEqual(SilahIsmi, "weapon_m249", true) || StrEqual(SilahIsmi, "weapon_mag7", true) || StrEqual(SilahIsmi, "weapon_negev", true) || StrEqual(SilahIsmi, "weapon_nova", true) || StrEqual(SilahIsmi, "weapon_sawedoff", true) || StrEqual(SilahIsmi, "weapon_xm1014", true) || StrEqual(SilahIsmi, "weapon_cz75a", true) || StrEqual(SilahIsmi, "weapon_tec9", true) || StrEqual(SilahIsmi, "weapon_p250", true) || StrEqual(SilahIsmi, "weapon_hkp2000", true) || StrEqual(SilahIsmi, "weapon_fiveseven", true) || StrEqual(SilahIsmi, "weapon_elite", true) || StrEqual(SilahIsmi, "weapon_deagle", true))
			{
				//*******************************************************//		
				if(Oyuncunun_Fov[client] == 90)
				{
					if(!Fov_Aktif[client])
					{
						//*********************************************//																								
						Fov_Aktif[client] = true;						
						//*********************************************//					
						float position2[3];
						GetEntPropVector(client, Prop_Send, "m_vecOrigin", position2);	
						//*********************************************//
						EmitSoundToAll("weapons/aug/aug_zoom_in.wav", SOUND_FROM_WORLD, SNDCHAN_AUTO, SNDLEVEL_ROCKET, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_NORMAL, -1, position2, NULL_VECTOR, true, 0.0);
						EmitSoundToClient(client, "weapons/aug/aug_zoom_in.wav");
						//*********************************************//	
						SetEntProp(client, Prop_Send, "m_bDrawViewmodel", 1);
						SetEntProp(client, Prop_Send, "m_iFOV", 80);
						//*********************************************//								
						CreateTimer(0.2, Fov_Ayarla, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
						//*********************************************//				
					}							
				}
				else
				if(Oyuncunun_Fov[client] == 80)
				{
					if(Fov_Aktif[client])
					{
						//*********************************************//																								
						Fov_Aktif[client] = false;
						//*********************************************//					
						float position2[3];
						GetEntPropVector(client, Prop_Send, "m_vecOrigin", position2);	
						//*********************************************//
						EmitSoundToAll("weapons/aug/aug_zoom_out.wav", SOUND_FROM_WORLD, SNDCHAN_AUTO, SNDLEVEL_ROCKET, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_NORMAL, -1, position2, NULL_VECTOR, true, 0.0);
						EmitSoundToClient(client, "weapons/aug/aug_zoom_out.wav");
						//*********************************************//	
						SetEntProp(client, Prop_Send, "m_bDrawViewmodel", 1);
						SetEntProp(client, Prop_Send, "m_iFOV", 90);		
						//*********************************************//													
						CreateTimer(0.2, Fov_Ayarla, client, TIMER_FLAG_NO_MAPCHANGE);
						//*********************************************//						
					}										
				}				
				//*******************************************************//					
			}
		}	
	}
	//*******************************************************//					
	return Plugin_Continue;
	//*******************************************************//						
}
/////////////////////////////////////////////////////////////////////////////////////////////////////////
public Action Fov_Ayarla(Handle Timer, any client)
{
	if(Oyuncunun_Fov[client] == 90)
	{
		//*********************************************//							
		Oyuncunun_Fov[client] = 80;
		//*********************************************//					
	}
	else
	if(Oyuncunun_Fov[client] == 80)
	{
		//*********************************************//							
		Oyuncunun_Fov[client] = 90;
		//*********************************************//	
	}
}
/////////////////////////////////////////////////////////////////////////////////////////////////////////