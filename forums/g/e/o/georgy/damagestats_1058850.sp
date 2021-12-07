//
// SourceMod Script
//

//
// CHANGELOG:
// Version:

//	0.1 - first release to community
//  0.2 - Add Damage Taken , Down of player death report


#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "0.5"
#define MAXHITGROUPS   7

new Handle:C_ShowhitsEnable = INVALID_HANDLE
new Handle:C_ShowhitsAttacker = INVALID_HANDLE
new bool:c_showhitsEnable;
new bool:c_showhitsAttacker;

new g_headshot[MAXPLAYERS+1];
new g_suicide[MAXPLAYERS+1];
new g_killer[MAXPLAYERS+1];
new g_death[MAXPLAYERS+1];
new g_pointcaptured[MAXPLAYERS+1];

new g_DamageDown[MAXPLAYERS+1];
new g_DamageTaken[MAXPLAYERS+1];

//addiding
new g_HitsDown[MAXPLAYERS+1][MAXPLAYERS+1];
new g_HitsTaken[MAXPLAYERS+1][MAXPLAYERS+1];
//new g_DamageDownAtc[MAXPLAYERS+1][MAXPLAYERS+1];

new g_Panelend[MAXPLAYERS+1];

new String:g_Healthstatus[MAXPLAYERS+1][MAXPLAYERS+1][128];
new String:g_HealthstatusK[MAXPLAYERS+1][MAXPLAYERS+1][128];

public Plugin:myinfo = 
{
	name = "damage_report",
	author = "georgy",
	description = "show damage, name of attacker and distance if player hurt",
	version = PLUGIN_VERSION,
	url = "leadrain.ozerki.net"
}

public OnPluginStart()
{
	CreateConVar("dod_damagestats_version", PLUGIN_VERSION, "Show version of showhits", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY)
	C_ShowhitsEnable = CreateConVar("sv_showhits", "1", "enable or disble the plugin (0 to disable, 1 to enable: default=1)", FCVAR_PLUGIN);
	C_ShowhitsAttacker = CreateConVar("sv_showhits_attacker", "1", "enable or disble that attacker see hits that he made(0 to disable, 1 to enable: default=1)", FCVAR_PLUGIN);
	HookConVarChange(C_ShowhitsEnable, EnableChanged);
	HookConVarChange(C_ShowhitsAttacker, AttackerChanged);
	
	HookEvent("player_hurt", PlayerHurtEvent_dods);
	HookEvent("player_death", PlayerDeathEvent_dods);
	HookEvent("dod_round_start", PlayerEventRoundstart_dods);
	HookEvent("dod_point_captured", PlayerEventPointcaptured_dods);
	HookEvent("dod_round_win", PlayerEventRoundWin_dods);
	HookEvent("player_connect", PlayerEventConnect_dods);
	HookEvent("player_disconnect", PlayerEventDisconnect_dods);
	
	LoadTranslations("dod_damage_report.phrases");
	
	c_showhitsEnable=GetConVarBool(C_ShowhitsEnable);
	c_showhitsAttacker=GetConVarBool(C_ShowhitsAttacker);
}


public EnableChanged(Handle:convar, const String:oldValue[], const String:newValue[]){
	c_showhitsEnable=GetConVarBool(C_ShowhitsEnable);
}

public AttackerChanged(Handle:convar, const String:oldValue[], const String:newValue[]){
	c_showhitsAttacker=GetConVarBool(C_ShowhitsAttacker);
}

public PlayerEventRoundstart_dods(Handle:event, const String:name[], bool:dontBroadcast)
{
	for(new i=1; i<=MaxClients; i++)
	{
		new client = i;
		
		if(IsClientInGame(client) && IsClientConnected(client))
		{
			g_killer[client] = 0;
			g_death[client] = 0;
			g_suicide[client] = 0;
			g_headshot[client] = 0;
			g_pointcaptured[client] = 0;
			g_DamageDown[client] = 0;
			g_DamageTaken[client] =0;
			g_Panelend[client] = 0;
			
			for(new j=1; j<=MaxClients; j++)
			{
				g_HitsTaken[client][j] = 0;
				g_HitsDown[client][j] = 0;
			}
		}
	}
}

public PlayerEventPointcaptured_dods(Handle:event, const String:name[], bool:dontBroadcast)
{
		new client
		new String:cappers[256];
		GetEventString(event, "cappers", cappers, sizeof(cappers));
		
		for(new i=0; i<strlen(cappers); i++)
		{
			client = cappers[i];
			g_pointcaptured[client] +=1;
		}	
}

public PlayerHurtEvent_dods(Handle:event, const String:name[], bool:dontBroadcast)
{

	if(!c_showhitsEnable) //plugin diabled
		return;

	new client     = GetClientOfUserId(GetEventInt(event, "userid"));
	new attacker   = GetClientOfUserId(GetEventInt(event, "attacker"));

	if(client==0 || attacker==0)
		return;
	
	if (IsClientInGame(client) && IsClientInGame(attacker))
	{
		new String:clientName[64];
		new String:attackerName[64];
				
		GetClientName(client, clientName, 64)
		GetClientName(attacker, attackerName, 64)
		new hitgroup = GetEventInt(event, "hitgroup")
		
		if((hitgroup >= 0) && (hitgroup <=7))
		{
			new damage   = GetEventInt(event, "damage")
		
		// Hitgroups
		// 0 = body (generic part for css)
		// 1 = Head
		// 2 = Upper Chest
		// 3 = Lower Chest
		// 4 = Left arm
		// 5 = Right arm
		// 6 = Left leg
		// 7 = Right Leg

			new Float:client_pos[3];
			new Float:attacker_pos[3];
			GetClientAbsOrigin(client,client_pos);
			GetClientAbsOrigin(attacker,attacker_pos);
			new Float:distance = GetVectorDistance(client_pos,attacker_pos,false);
			distance*=0.025;
			
			new String:g_HitboxName[MAXHITGROUPS+1][128];
			new String:g_Target[128];
			new String:g_Attacker[128];
			new String:temp[128];
			
			Format(temp, sizeof(temp), "%T", "hbBody", client);
			g_HitboxName[0]=temp;
			Format(temp, sizeof(temp), "%T", "hbHead", client);
			g_HitboxName[1]=temp;
			Format(temp, sizeof(temp), "%T", "hbUpChest", client);
			g_HitboxName[2]=temp;
			Format(temp, sizeof(temp), "%T", "hbLowChest", client);
			g_HitboxName[3]=temp;
			Format(temp, sizeof(temp), "%T", "hbLeftarm", client);
			g_HitboxName[4]=temp;
			Format(temp, sizeof(temp), "%T", "hbRightarm", client);
			g_HitboxName[5]=temp;
			Format(temp, sizeof(temp), "%T", "hbLeftleg", client);
			g_HitboxName[6]=temp;
			Format(temp, sizeof(temp), "%T", "hbRightleg", client);
			g_HitboxName[7]=temp;
			Format(temp, sizeof(temp), "%T", "hbAttacker", client);
			g_Attacker = temp;
			Format(temp, sizeof(temp), "%T", "hbTadget", client);
			g_Target = temp;
			
			
			
			
			PrintToChat(client,"\x01\x05%s : %s\x01, %s  %i dmg, %.2fm",g_Attacker, attackerName, g_HitboxName[hitgroup], damage,distance);
			PrintToChat(attacker,"\x04%s : %s\x01, %s  %i dmg, %.2fm",g_Target, clientName,g_HitboxName[hitgroup],damage,distance);
			
			if(hitgroup == 1)
			{
				g_headshot[attacker] ++;
			}
			
			g_HitsDown[client][attacker] += 1;
			g_DamageDown[attacker] += damage;
			g_HitsTaken[attacker][client] += 1;
			g_DamageTaken[client] += damage;
			
			
			if(GetClientHealth(client)>0)
			{
				Format(temp, sizeof(temp), "%T", "stwound", client);
				g_Healthstatus[attacker][client] = temp;
				Format(temp, sizeof(temp), "%T", "stwounded", client);
				g_HealthstatusK[client][attacker] = temp;
				//PrintToChat(attacker, " %s Wounded to you", clientName);
			}
			else
			{
				Format(temp, sizeof(temp), "%T", "stkill", client);
				g_Healthstatus[attacker][client] = temp;
				Format(temp, sizeof(temp), "%T", "stkilled", client);
				g_HealthstatusK[client][attacker] = temp;
				//PrintToChat(attacker, " %s DEATHE", clientName);
			}
		}
	}
}

public PlayerDeathEvent_dods(Handle:event, const String:name[], bool:dontBroadcast)
{
	
	
	new client     = GetClientOfUserId(GetEventInt(event, "userid"));
	new attacker   = GetClientOfUserId(GetEventInt(event, "attacker"));
	
		
	if (IsClientInGame(client) && IsClientInGame(attacker))
	{
		
		new String:clientName[64];
		new String:attackerName[64];
		
		GetClientName(client, clientName, 64);
		GetClientName(attacker, attackerName, 64);
		
		decl String:killer[256];
		decl String:dmgkillerD[256];
		decl String:dmgkillerT[256];
				
		if(attacker == client)
		{
			g_suicide[client]++;
			
			Format(killer, sizeof(killer), "%T", "tegsuicide", client);
			
		}
			else
			{
				g_killer[client]++;
				g_death[attacker]++;
			
				Format(killer, sizeof(killer), "%T", "You Kill", client, attackerName);
				Format(dmgkillerT, sizeof(dmgkillerT), "%T", "tegDowndmg", client, g_DamageDown[client]);
				
				if(g_DamageTaken[client] != 0)
				{
					Format(dmgkillerD, sizeof(dmgkillerD), "%T", "tegTakendmg", client, g_DamageTaken[client]);
				}
			}
		if((g_Panelend[client] == 0) && (c_showhitsAttacker))
		{
			new Handle:killReportPanal=CreatePanel();
			if((attacker != client) && (g_DamageDown[client] != 0))
			{
				DrawPanelItem(killReportPanal, dmgkillerT);
				
				//addiding
				for(new i=1; i<=MaxClients; i++)
				{
					if(IsClientInGame(i) && IsClientConnected(i) && (client != i) && (g_HitsTaken[client][i] != 0))
					{
						decl String:ShotVictim[256];
						new String:attackerNameV[64];
						GetClientName(i, attackerNameV, 64);
						
						Format(ShotVictim, sizeof(ShotVictim), "%T", "tegYouShot", client , attackerNameV, g_HitsTaken[client][i], g_Healthstatus[client][i]);
						DrawPanelText(killReportPanal, ShotVictim);
					}
				}
			}
			if(attacker != client)
			{
				DrawPanelItem(killReportPanal, dmgkillerD);
				
				//addiding
				for(new i=1; i<=MaxClients; i++)
				{
					if(IsClientInGame(i) && IsClientConnected(i) && (client != i) && (g_HitsDown[client][i] != 0))
					{
						decl String:ShotAttac[256];
						new String:attackerNameA[64];
						GetClientName(i, attackerNameA, 64);
						
						Format(ShotAttac, sizeof(ShotAttac), "%T", "tegShotsToYou", client, attackerNameA, g_HitsDown[client][i], g_HealthstatusK[client][i]);
						DrawPanelText(killReportPanal, ShotAttac);
					}
				}
			}
			DrawPanelText(killReportPanal, killer);
			SendPanelToClient(killReportPanal, client, Handler_MyPanel, 7);
			CloseHandle(killReportPanal);
		}
		clearDamageClientreport(client);
	}	
}

public Handler_MyPanel(Handle:menu, MenuAction:action, param1, param2)
{
}

public PlayerEventRoundWin_dods(Handle:event, const String:name[], bool:dontBroadcast)
{
	
	
	for(new i=1; i<=MaxClients; i++)
	{
		new client = i;
		
		if(IsClientInGame(client))
		{
			g_Panelend[client] = 1;
			new Handle:ScoreReportPanal=CreatePanel();
			
			PrintToChat(client, "\x04 [SM] Show round end score");
			//PrintToChat(client, "\x05 Killers %d", g_death[client]);
			
			decl String:menutitle[256];
			decl String:s_killar[128];
			decl String:s_death[128];
			decl String:s_suicid[128];
			decl String:s_headshot[128];
			decl String:s_pointcaptured[128];
						
			
			if((g_death[client] != 0) || (g_killer[client] != 0) || (g_suicide[client] != 0) || (g_headshot[client] != 0) || (g_pointcaptured[client] != 0))
			{
				Format(menutitle, sizeof(menutitle), "%T", "Roundend", client);
				{
					DrawPanelText(ScoreReportPanal, menutitle);
				}
				Format(s_killar, sizeof(s_killar), "%T", "Killers", client, g_death[client]);
				if(g_death[client] != 0)
				{
					DrawPanelText(ScoreReportPanal, s_killar);
				}
				Format(s_death, sizeof(s_death), "%T", "Deathes", client, g_killer[client]);
				if(g_killer[client] != 0)
				{	
					DrawPanelText(ScoreReportPanal, s_death);
				}
				Format(s_suicid, sizeof(s_suicid), "%T", "Suicides", client, g_suicide[client]);
				if(g_suicide[client] != 0)
				{
					DrawPanelText(ScoreReportPanal, s_suicid);
				}
				Format(s_headshot, sizeof(s_headshot), "%T", "Headahots", client, g_headshot[client]);
				if(g_headshot[client] != 0)
				{
					DrawPanelText(ScoreReportPanal, s_headshot);
				}
			
				Format(s_pointcaptured, sizeof(s_pointcaptured), "%T", "Capture", client, g_pointcaptured[client]);
				if(g_pointcaptured[client] != 0)
				{
					DrawPanelText(ScoreReportPanal, s_pointcaptured);
				}
				SendPanelToClient(ScoreReportPanal, client, Handler_MyPanel, 15);
				CloseHandle(ScoreReportPanal);
				clearRoundDamageData(client);
			}	
		}
	}	
}

public PlayerEventConnect_dods(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client     = GetClientOfUserId(GetEventInt(event, "userid"));
	clearRoundDamageData(client);
}

public PlayerEventDisconnect_dods(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client     = GetClientOfUserId(GetEventInt(event, "userid"));
	clearRoundDamageData(client);
}

public clearDamageClientreport(client)
{
	g_DamageDown[client] = 0;
	g_DamageTaken[client] = 0;
	//addiding
	for(new i=1; i<=MaxClients; i++)
		{
			if(IsClientInGame(i) && IsClientConnected(i))
			{
				g_HitsTaken[client][i] = 0;
				g_HitsDown[client][i] = 0;
			}
		}
}

public clearRoundDamageData(client)
{
	g_killer[client] = 0;
	g_death[client] = 0;
	g_suicide[client] = 0;
	g_headshot[client] = 0;
	g_pointcaptured[client] = 0;
	g_DamageDown[client] = 0;
	g_DamageTaken[client] = 0;
	//addiding
	for(new i=1; i<=MaxClients; i++)
		{
			if(IsClientInGame(i) && IsClientConnected(i))
			{
				g_HitsTaken[client][i] = 0;
				g_HitsDown[client][i] = 0;
			}
		}
}