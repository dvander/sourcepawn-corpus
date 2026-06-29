#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>

#pragma semicolon 1

new Handle:Speedo;
new Handle:cvarEnable;

new CanDJump[32];
new InTrimp[32];
new WasInJumpLastTime[32];
new WasOnGroundLastTime[32];
new Float:VelLastTime[32][3];

public Plugin:myinfo = 
{
	name = "TFTurbo",
	author = "Pierce 'NameUser' Strine",
	description = "TFTurbo aims to reinstate a nostaligic experience with fast movement.",
	version = "1.0",
	url = "Soon."
}
public OnPluginStart()
{
	Speedo = CreateConVar("tft_speedometer", "1", "ALWAYS show speedometer for all clients");
	cvarEnable = CreateConVar("turbo_enabled","1","Enable plugin",FCVAR_PLUGIN|FCVAR_NOTIFY,true,0.0,true,1.0);
	HookConVarChange(cvarEnable,EnableChange);
	HookEvent("player_hurt", EventPlayerHurt); //Self-Damage (for the boost)
}

public EnableChange(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if(GetConVarInt(cvarEnable) <= 0)
	{
		UnhookEvent("player_hurt",EventPlayerHurt);
		
	} else {
		HookEvent("player_hurt",EventPlayerHurt);
	}
}


public OnGameFrame()
{
	if(GetConVarInt(cvarEnable) <= 0)
	{
		return;
	}
	new Float:PlayerVel[3];
	new Float:TrimpVel[3];
	new Float:PlayerSpeed[1];
	new Float:PlayerSpeedLastTime[1];
	new String:TempString[32];
	new Float:EyeAngle[3];
	
	for(new i = 1; i <= GetMaxClients(); i++)
	{
		if( IsValidEntity(i) && IsClientInGame(i) && IsPlayerAlive(i) )
		{
			GetEntPropVector(i, Prop_Data, "m_vecVelocity", PlayerVel);
			PlayerSpeed[0] = SquareRoot( (PlayerVel[0]*PlayerVel[0]) + (PlayerVel[1]*PlayerVel[1]) );
			if( GetConVarBool(Speedo) || (PlayerSpeed[0] >= (400.0*1.6/1.2)) )
			{
				FloatToString((PlayerSpeed[0]/(4.0*1.6)),TempString,32);
				PrintCenterText(i,"%i%", StringToInt(TempString));
			}
			else
			{
				PrintCenterText(i,"");
			}
			if( (GetClientButtons(i) & IN_JUMP) && ( (GetEntityFlags(i) & FL_ONGROUND) || WasOnGroundLastTime[i] ) )
			{
				PlayerSpeedLastTime[0] = SquareRoot( (VelLastTime[i][0]*VelLastTime[i][0]) + (VelLastTime[i][1]*VelLastTime[i][1]) );
				if(PlayerSpeedLastTime[0] > PlayerSpeed[0])
				{
					PlayerVel[0] = PlayerVel[0] * PlayerSpeedLastTime[0] / PlayerSpeed[0];
					PlayerVel[1] = PlayerVel[1] * PlayerSpeedLastTime[0] / PlayerSpeed[0];
					PlayerSpeed[0] = PlayerSpeedLastTime[0];
				}
				if( ( (GetClientButtons(i) & IN_FORWARD) || (GetClientButtons(i) & IN_BACK) ) && (PlayerSpeed[0] >= (400.0 * 1.6)) )
				{
					TrimpVel[0] = PlayerVel[0] * Cosine(70.0*3.14159265/180.0);
					TrimpVel[1] = PlayerVel[1] * Cosine(70.0*3.14159265/180.0);
					TrimpVel[2] = PlayerSpeed[0] * Sine(70.0*3.14159265/180.0);
					
					InTrimp[i] = true;
					
					TeleportEntity(i, NULL_VECTOR, NULL_VECTOR, TrimpVel);
				}
				else
				{
					if( WasOnGroundLastTime[i] || (GetClientButtons(i) & IN_DUCK) ){}
					else
					{
						PlayerVel[0] = 1.2 * PlayerVel[0];
						PlayerVel[1] = 1.2 * PlayerVel[1];
						PlayerSpeed[0] = 1.2 * PlayerSpeed[0];
					}
					if(GetClientButtons(i) & IN_DUCK)
					{
						if(PlayerSpeed[0] > (1.2 * 400.0 * 1.6))
						{
							PlayerVel[0] = PlayerVel[0] * 1.2 * 400.0 * 1.6 / PlayerSpeed[0];
							PlayerVel[1] = PlayerVel[1] * 1.2 * 400.0 * 1.6 / PlayerSpeed[0];
						}
					}
					else if(PlayerSpeed[0] > (400.0 * 1.6))
					{
						PlayerVel[0] = PlayerVel[0] * 400.0 * 1.6 / PlayerSpeed[0];
						PlayerVel[1] = PlayerVel[1] * 400.0 * 1.6 / PlayerSpeed[0];
					}
					
					PlayerVel[2] = 800.0/3.0;
					
					TeleportEntity(i, NULL_VECTOR, NULL_VECTOR, PlayerVel);
				}
			}
			else if( (InTrimp[i] || (CanDJump[i] && (TF2_GetPlayerClass(i) == TFClass_Scout))) && (WasInJumpLastTime[i] == 0) && (GetClientButtons(i) & IN_JUMP) )
			{
				PlayerSpeedLastTime[0] = 1.2 * SquareRoot( (VelLastTime[i][0]*VelLastTime[i][0]) + (VelLastTime[i][1]*VelLastTime[i][1]) );
				
				if(PlayerSpeedLastTime[0] < 400.0)
				{
					PlayerSpeedLastTime[0] = 400.0;
				}
				
				if(PlayerSpeed[0] == 0.0)
				{
					PlayerSpeedLastTime[0] = 0.0;
				}
				
				PlayerVel[0] = PlayerVel[0] * PlayerSpeedLastTime[0] / PlayerSpeed[0];
				PlayerVel[1] = PlayerVel[1] * PlayerSpeedLastTime[0] / PlayerSpeed[0];
				PlayerVel[2] = 800.0/3.0;
				
				CanDJump[i] = false;
				InTrimp[i] = false;
				
				TeleportEntity(i, NULL_VECTOR, NULL_VECTOR, PlayerVel);
			}
			else
			{
				if(GetEntityFlags(i) & FL_ONGROUND){}
				else
				{
					GetClientWeapon(i,TempString,32);
					if( (strcmp(TempString,"tf_weapon_flamethrower") == 0) && (GetClientButtons(i) & IN_ATTACK) )
					{
						GetClientEyeAngles(i, EyeAngle);
						
						PlayerVel[2] = PlayerVel[2] + ( 15.0 * Sine(EyeAngle[0]*3.14159265/180.0) );
						
						if(PlayerVel[2] > 100.0)
						{
							PlayerVel[2] = 100.0;
						}
						
						PlayerVel[0] = PlayerVel[0] - ( 3.0 * Cosine(EyeAngle[0]*3.14159265/180.0) * Cosine(EyeAngle[1]*3.14159265/180.0) );
						PlayerVel[1] = PlayerVel[1] - ( 3.0 * Cosine(EyeAngle[0]*3.14159265/180.0) * Sine(EyeAngle[1]*3.14159265/180.0) );
						
						TeleportEntity(i, NULL_VECTOR, NULL_VECTOR, PlayerVel);
					}
				}
			}
			if( ( (InTrimp[i] == 1) || (CanDJump[i] == 0) ) && (GetEntityFlags(i) & FL_ONGROUND) )
			{
				CanDJump[i] = true;
				InTrimp[i] = false;
			}
			WasInJumpLastTime[i] = (GetClientButtons(i) & IN_JUMP);
			WasOnGroundLastTime[i] = (GetEntityFlags(i) & FL_ONGROUND);
			VelLastTime[i][0] = PlayerVel[0];
			VelLastTime[i][1] = PlayerVel[1];
			VelLastTime[i][2] = PlayerVel[2];
		}
	}
}
public Action:EventPlayerHurt(Handle:event, const String:name[], bool:dontBroadcast)
{
	new victim_id = GetEventInt(event, "userid");
	new attacker_id = GetEventInt(event, "attacker");
	
	new victim = GetClientOfUserId(victim_id);
	new attacker = GetClientOfUserId(attacker_id);
	
	if(attacker == victim)
	{
		new Float:DamageVel[3];
		new Float:DamageSpeed[1];
		new Float:DamageOldSpeed[1];
		
		GetEntPropVector(attacker, Prop_Data, "m_vecVelocity", DamageVel);
		
		DamageSpeed[0] = SquareRoot( (DamageVel[0]*DamageVel[0]) + (DamageVel[1]*DamageVel[1]) + (DamageVel[2]*DamageVel[2]) );
		
		DamageOldSpeed[0] = SquareRoot( (VelLastTime[attacker][0]*VelLastTime[attacker][0]) + (VelLastTime[attacker][1]*VelLastTime[attacker][1]) + (VelLastTime[attacker][2]*VelLastTime[attacker][2]) );
		
		if(DamageSpeed[0] > DamageOldSpeed[0])
		{
			DamageVel[0] = 1.2 * DamageVel[0];
			DamageVel[1] = 1.2 * DamageVel[1];
			
			TeleportEntity(attacker, NULL_VECTOR, NULL_VECTOR, DamageVel);
		}	
	}
	return Plugin_Continue;
}
