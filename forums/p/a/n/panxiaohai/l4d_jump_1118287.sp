#pragma semicolon 1
#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.1.4"


new Float:JumpTime[MAXPLAYERS+1];
 new bool:JumpEnabled[MAXPLAYERS+1];
 new bool:Jumped[MAXPLAYERS+1];
 new bool:LastButton[MAXPLAYERS+1];
 
new Handle:timer_handle=INVALID_HANDLE;
new Handle:Enabled = INVALID_HANDLE;
new Handle:InitEnabled = INVALID_HANDLE;
 
new Handle:CVarxymult = INVALID_HANDLE;
new Handle:CVarzmult = INVALID_HANDLE;
new Handle:CVarDamage = INVALID_HANDLE;
new Handle:CVarxymult2 = INVALID_HANDLE;
new Handle:CVarzmult2 = INVALID_HANDLE;
new Handle:CVarDamage2 = INVALID_HANDLE;

new Handle:CVarTick = INVALID_HANDLE;
new Handle:CVarMsgTime = INVALID_HANDLE;
 

new all_iVelocity;
 

public Plugin:myinfo = 
{
	name = "China Qing Gong",
	author = "pan xiaohai",
	description = "China Qing Gong",
	version = "1.1.4"
}

public OnPluginStart()
{
	CreateConVar("l4d_jump_version", PLUGIN_VERSION, "   ", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	
	Enabled = CreateConVar("l4d_jump_enabled", "1", " 1 : China Qing Gong enable , 0: China Qing Gong disable ", FCVAR_PLUGIN);
	InitEnabled = CreateConVar("l4d_jump_init", "1", " 1 : enable for everyone, 0: enable by say !qg ", FCVAR_PLUGIN);
	CVarzmult = CreateConVar("l4d_jump_zmult", "2.2", "Vertical Acceleration", FCVAR_PLUGIN);
	CVarxymult = CreateConVar("l4d_jump_xymult", "2.5", "Horizontal Acceleration", FCVAR_PLUGIN);
	CVarDamage = CreateConVar("l4d_jump_damage", "2", "how many health lost when use supper Qing Gong", FCVAR_PLUGIN);
	CVarzmult2 = CreateConVar("l4d_jump_zmult2", "4.0", "supper Qing Gong Vertical Acceleration", FCVAR_PLUGIN);
	CVarxymult2 = CreateConVar("l4d_jump_xymult2", "4.0", "supper Qing Gong Horizontal Acceleration", FCVAR_PLUGIN);
	CVarDamage2 = CreateConVar("l4d_jump_damage2", "5", "how many health lost when supper use Qing Gong", FCVAR_PLUGIN);
	CVarTick = CreateConVar("l4d_jump_tick", "0.2", "use difficulty more small more difficult ", FCVAR_PLUGIN);
	CVarMsgTime = CreateConVar("l4d_jump_showtime", "100", "message time", FCVAR_PLUGIN);
 	
	AutoExecConfig(true, "l4d_jump_v14");
	
	all_iVelocity = FindSendPropOffs("CBasePlayer", "m_vecVelocity[0]");
    	
	HookEvent("round_end", RoundEnd);
	HookEvent("mission_lost", RoundEnd);
	HookEvent("finale_win", RoundEnd);
 	
	HookEvent("round_start", RoundStart);
	HookEvent("player_jump", player_jump);
 	RegConsoleCmd("sm_qg", Command_Drop);
	reset();
}
public Action:Msg(Handle:timer, any:data)
{
	PrintToChatAll("\x05[Qing Gong]\x01say \x03 !qg or !qinggong \x01 to learn Qing Gong");
 	return Plugin_Continue;
}
public Action:Command_Drop(client, args)
{
	if (client == 0 || GetClientTeam(client) != 2 || !IsPlayerAlive(client))
		return Plugin_Handled;
	JumpEnabled[client]=!JumpEnabled[client];
	if(	JumpEnabled[client])
	{
		PrintToChat(client, "\x05[Qing Gong]\x03You have learned Qing Gong, use it by press jump twice quickly( you can hold duck at the same time");
	}
	else
	{
		PrintToChat(client, "\x05[Qing Gong]\x03You have forgetted Qing Gong");
	}

  	return Plugin_Handled;
}
public Action:player_jump(Handle:hEvent, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	if (!client) return;
	if (!IsClientInGame(client)) return;
	if (!IsPlayerAlive(client)) return;
	LastButton[client]=GetClientButtons(client);
	JumpTime[client]=GetEngineTime();
	Jumped[client]=true;
 }
public OnGameFrame()
{
	if(GetConVarInt(Enabled)==0)return;

	new Float:time=GetEngineTime();
	new Float:tick=GetConVarFloat(CVarTick);
  	for (new client = 1; client < MAXPLAYERS+1; client++)
	{
		if (JumpEnabled[client] && Jumped[client] && IsClientInGame(client) && GetClientTeam(client)==2 && IsPlayerAlive(client))
		{
			
			
			if(JumpTime[client]>=time+tick)
			{	 
				Jumped[client]=false;
				return;
			}
			new buttons = GetClientButtons(client);
			new suppermode=false;
 			if( (buttons & IN_JUMP) && !(LastButton[client] & IN_JUMP) )
			{
				if  ((buttons & IN_DUCK) || (buttons & IN_USE))
				{
					suppermode=true;
				}
 				if(JumpTime[client]<time)
				{
					decl Float:velocity[3];
					GetEntDataVector(client, all_iVelocity, velocity);
					if(velocity[2]<0.0)
					{
						Jumped[client]=false;
						return;
					}
						
					new Float:zmult=GetConVarFloat(CVarzmult  );
					new Float:xymult=GetConVarFloat(CVarxymult );
					new Float:zmult2=GetConVarFloat(CVarzmult2  );
					new Float:xymult2=GetConVarFloat(CVarxymult2 );
					new damage=GetConVarInt(CVarDamage );
					new damage2=GetConVarInt(CVarDamage2 );

					decl String:sdemage[10];
					Format(sdemage, sizeof(sdemage),  "%i", damage);
					decl String:sdemage2[10];
					Format(sdemage2, sizeof(sdemage2),  "%i", damage2); 
					if  (suppermode)
					{
						velocity[0]=velocity[0]*xymult2;
						velocity[1]=velocity[1]*xymult2;
						velocity[2]=velocity[2]*zmult2;
					}
					else
					{
						velocity[0]=velocity[0]*xymult;
						velocity[1]=velocity[1]*xymult;
						velocity[2]=velocity[2]*zmult;
					}
					TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, velocity);
					SetEntDataVector(client, all_iVelocity, velocity);
					Jumped[client]=false;
					 
					if(damage>0)
					{
						if(suppermode)DamageEffect(client, sdemage2);
						else DamageEffect(client, sdemage);
					}
					if(suppermode)PrintCenterText(client, "Supper Qing Gong");
					else PrintCenterText(client, "Qing Gong");
 
				}
 			}
			LastButton[client]=buttons;
			 
		}
	}
	return;
}
 
 stock DamageEffect(target, String:demage[])
{
	new pointHurt = CreateEntityByName("point_hurt");			// Create point_hurt
	DispatchKeyValue(target, "targetname", "hurtme");			// mark target
	DispatchKeyValue(pointHurt, "Damage", demage);					// No Damage, just HUD display. Does stop Reviving though
	DispatchKeyValue(pointHurt, "DamageTarget", "hurtme");		// Target Assignment
	DispatchKeyValue(pointHurt, "DamageType", "65536");			// Type of damage
	DispatchSpawn(pointHurt);									// Spawn descriped point_hurt
	AcceptEntityInput(pointHurt, "Hurt"); 						// Trigger point_hurt execute
	AcceptEntityInput(pointHurt, "Kill"); 						// Remove point_hurt
	DispatchKeyValue(target, "targetname",	"cake");			// Clear target's mark
}
 

public Action:RoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
 	if(timer_handle != INVALID_HANDLE )
	 {
		KillTimer(timer_handle);
		timer_handle=INVALID_HANDLE;
	}

	return Plugin_Continue;
}

public Action:RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	reset();
	if(timer_handle != INVALID_HANDLE )
	{
		KillTimer(timer_handle);
		timer_handle=INVALID_HANDLE;
	}
	if(timer_handle == INVALID_HANDLE)
	{
		timer_handle=CreateTimer(GetConVarFloat(CVarMsgTime), Msg, 0, TIMER_REPEAT);
	}
	return Plugin_Continue;
}

reset()
{
	new bool:e=GetConVarInt(InitEnabled)>0;
	for (new x = 0; x < MAXPLAYERS+1; x++)
	{
 			JumpEnabled[x]=e;
	}
}