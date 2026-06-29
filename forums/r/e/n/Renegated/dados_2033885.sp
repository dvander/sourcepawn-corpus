#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <sdktools_sound>
#include <sdkhooks>

new Dados[MAXPLAYERS+1] = 0;
new bool:g_usando[MAXPLAYERS+1] = {false, ...};
new Handle:Dados_para_usar;

public Plugin:myinfo =
{
    name = "SM Dices (Dados)",
    author = "Renegated Evrae steam: renegatedx",
    description = "Random dices & random awards",
    version = "3.0",
    url = "www.clanuea.com"
};
public OnMapStart()
{
AddFileToDownloadsTable("materials/models/player/brownleatherbear/bear.vtf");
AddFileToDownloadsTable("materials/models/player/brownleatherbear/bear_normal.vtf");
AddFileToDownloadsTable("materials/models/player/brownleatherbear/lightwarp2.vtf");
AddFileToDownloadsTable("materials/models/player/brownleatherbear/bear.vmt");
AddFileToDownloadsTable("models/player/knifelemon/brown_leather_bear.dx80.vtx");
AddFileToDownloadsTable("models/player/knifelemon/brown_leather_bear.dx90.vtx");
AddFileToDownloadsTable("models/player/knifelemon/brown_leather_bear.mdl");
AddFileToDownloadsTable("models/player/knifelemon/brown_leather_bear.phy");
AddFileToDownloadsTable("models/player/knifelemon/brown_leather_bear.sw.vtx");
AddFileToDownloadsTable("models/player/knifelemon/brown_leather_bear.vvd");
AddFileToDownloadsTable("materials/models/player/knifelemon/armor_giant/hair_eye.vmt");
AddFileToDownloadsTable("materials/models/player/knifelemon/armor_giant/hair_eye.vtf");
AddFileToDownloadsTable("materials/models/player/knifelemon/armor_giant/skin.vtf");
AddFileToDownloadsTable("materials/models/player/knifelemon/armor_giant/skin.vmt");
AddFileToDownloadsTable("materials/models/player/knifelemon/armor_giant/skin_s.vtf");
AddFileToDownloadsTable("materials/models/player/knifelemon/armor_giant/skin_s.vmt");
AddFileToDownloadsTable("models/player/knifelemon/ArmorGiant.dx80.vtx");
AddFileToDownloadsTable("models/player/knifelemon/ArmorGiant.dx90.vtx");
AddFileToDownloadsTable("models/player/knifelemon/armorgiant.mdl");
AddFileToDownloadsTable("models/player/knifelemon/Armorgiant.phy");
AddFileToDownloadsTable("models/player/knifelemon/ArmorGiant.sw.vtx");
AddFileToDownloadsTable("models/player/knifelemon/armorgiant.vvd");
AddFileToDownloadsTable("materials/models/player/blockdude/blockdude.vmt");
AddFileToDownloadsTable("materials/models/player/blockdude/blockdude.vtf");
AddFileToDownloadsTable("models/player/knifelemon/blockdude.dx80.vtx");
AddFileToDownloadsTable("models/player/knifelemon/blockdude.dx90.vtx");
AddFileToDownloadsTable("models/player/knifelemon/blockdude.mdl");
AddFileToDownloadsTable("models/player/knifelemon/blockdude.phy");
AddFileToDownloadsTable("models/player/knifelemon/blockdude.sw.vtx");
AddFileToDownloadsTable("models/player/knifelemon/blockdude.vvd");
AddFileToDownloadsTable("materials/models/props/slow/joe100/dick/slow_balls.vmt");
AddFileToDownloadsTable("materials/models/props/slow/joe100/dick/slow_balls.vft");
AddFileToDownloadsTable("materials/models/props/slow/joe100/dick/slow_balls_bump.vmt");
AddFileToDownloadsTable("materials/models/props/slow/joe100/dick/slow_balls_bump.vtf");
AddFileToDownloadsTable("materials/models/props/slow/joe100/dick/slow_dildo.vmt");
AddFileToDownloadsTable("materials/models/props/slow/joe100/dick/slow_dildo.vft");
AddFileToDownloadsTable("materials/models/props/slow/joe100/dick/slow_dildo_bump.vmt");
AddFileToDownloadsTable("materials/models/props/slow/joe100/dick/slow_dildo_bump.vtf");
AddFileToDownloadsTable("models/props/slow/joe100/dick/slow_dx80.vtx");
AddFileToDownloadsTable("models/props/slow/joe100/dick/slow_dx90.vtx");
AddFileToDownloadsTable("models/props/slow/joe100/dick/slow.mdl");
AddFileToDownloadsTable("models/props/slow/joe100/dick/slow.phy");
AddFileToDownloadsTable("models/props/slow/joe100/dick/slow.sw.vtx");
AddFileToDownloadsTable("models/props/slow/joe100/dick/slow.vvd");

AddFileToDownloadsTable("sound/laught/evillaught.mp3");

PrecacheModel("models/props/slow/joe100/dick/slow.mdl");
PrecacheModel("models/player/knifelemon/blockdude.mdl");
PrecacheModel("models/player/knifelemon/armorgiant.mdl");
PrecacheModel("models/player/knifelemon/brown_leather_bear.mdl");
}
public OnPluginStart()
{
	CreateConVar("sm_dados_version", "v1.0 by Renegated Evrae", "Random dices & Random awards", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_DONTRECORD);	
	Dados_para_usar = CreateConVar("sm_dados_usar", "1", "Max times for rolling the dices");
	RegConsoleCmd("sm_dices",Daditos);
	HookEvent("player_spawn", final);
}

public Action:final(Handle:event, const String:Name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));

	Dados[client] = 0;
        g_usando[client] = false;
               
        SetEntityRenderMode(client, RENDER_NORMAL);
        SetEntityRenderColor(client, 255, 255, 255, 255);
}
 
public Action:Daditos(client,args)
{
	if(IsClientInGame(client) && IsPlayerAlive(client) && GetClientTeam(client) == 2 ||IsClientInGame(client) && IsPlayerAlive(client) && GetClientTeam(client) == 3)
	{
		if(!g_usando[client])
		{
			if(Dados[client] < GetConVarInt(Dados_para_usar))
			{
				new dados = GetRandomInt(1, 20);
                                PrintToChat(client, "\x05[SM_Dices] \x04Rolling the dices, be quiet.....");

				
				g_usando[client] = true;
                                Dados[client] += 1;
			
				if (dados == 3)
				{
					
					if(IsPlayerAlive(client) && IsClientInGame(client))
        				{
        				        new vida = GetClientHealth(client);
								vida += 50;
								SetEntityHealth(client, vida);
                				g_usando[client] = false;
               
                				PrintToChat(client, "\x05[SM_Dices] \x04 Congratulations, now you have +50 of health.");
               
       					 }
				
				}else if (dados == 6)
				{
					g_usando[client] = false;
					PrintToChat(client,"\x05[SM_Dices] \x04 Bad luck, nothing for you.");
				
				}else if (dados == 7)
				{
						GivePlayerItem(client,"weapon_m249");
						g_usando[client] = false;
						PrintToChat(client,"\x05[SM_Dices] \x04 Now you have a M249, KILL EVERYONE IN YOUR WAY.");
				}else if ( dados == 11 )
				{
						g_usando[client] = false;
						PrintToChat(client,"\x05[SM_Dices] \x04 Bad luck, nothing for you.");	
				}else if ( dados == 14 )
				{
					if(IsPlayerAlive(client) && IsClientInGame(client))
        				{
								SetEntityHealth(client, 1);
								g_usando[client] = false;
								PrintToChat(client, "\x05[SM_Dices] \x04 Bad luck, now you have 1 HP.");
               
       					 }
				}else if (dados == 1)
				{
					g_usando[client] = false;
					PrintToChat(client,"\x05[SM_Dices] \x04 Bad luck, nothing for you.");
				}else if (dados == 2)
				{
					g_usando[client] = false;
					PrintToChat(client,"\x05[SM_Dices] \x04 Bad luck, nothing for you.");
				}else if (dados == 4)
				{
					g_usando[client] = false;
					PrintToChat(client,"\x05[SM_Dices] \x04 Bad luck, nothing for you.");
				}else if (dados == 5)
				{
					EmitSoundToAll("sound/laught/evillaught.mp3",SOUND_FROM_PLAYER,SNDCHAN_AUTO,SNDLEVEL_NORMAL,SND_NOFLAGS,SNDVOL_NORMAL,SNDPITCH_NORMAL,-1,NULL_VECTOR,NULL_VECTOR,true,0.0);
					BanClient(client,2,BANFLAG_AUTO,"Dados","Bad Luck, you have been banned for 2 mins","",0);
				}
				else if (dados == 8)
				{
					SetEntityModel(client, "models/player/knifelemon/armorgiant.mdl");
					SetEntityHealth(client, 200);
					g_usando[client] = false;
					PrintToChat(client,"\x05[SM_Dices] \x04 Good Luck, now you are an armored titan.");
				
				}else if (dados == 9)
				{
					g_usando[client] = false;
					PrintToChat(client,"\x05[SM_Dices] \x04 Bad luck, nothing for you.");
				}else if (dados == 10)
				{
					GivePlayerItem(client,"weapon_deagle");
					g_usando[client] = false;
					PrintToChat(client,"\x05[SM_Dices] \x04 Now you have a deagle, KILL EVERYONE IN YOUR WAY.");
				}else if (dados == 12)
				{
					g_usando[client] = false;
					PrintToChat(client,"\x05[SM_Dices] \x04 Bad luck, nothing for you.");
				}else if (dados == 13)
				{
					SetEntityModel(client, "models/player/knifelemon/blockdude.mdl");
					SetEntityHealth(client, 125);
					g_usando[client] = false;
					PrintToChat(client,"\x05[SM_Dices] \x04 Congratulations, now you are Steve, from Minecraft.");
				}else if (dados == 15)
				{
					g_usando[client] = false;
					PrintToChat(client, "\x05[SM_Dices] \x04 Bad luck, nothing for you.");
				}else if (dados == 16)
				{
					if(IsPlayerAlive(client) && IsClientInGame(client))
        			{
	 				    SetEntityHealth(client, 2);
                		g_usando[client] = false;
						PrintToChat(client, "\x05[SM_Dices] \x04 Bad Luck, now you have 2 HP.");
       				}
				}else if (dados == 17)
				{
					SetEntityModel(client, "models/player/knifelemon/brown_leather_bear.mdl");
					g_usando[client] = false;
					PrintToChat(client,"\x05[SM_Dices] \x04 You're PedoBear... Kill everyone from behind :D");
				}else if (dados == 18)
				{
					SetEntityModel(client, "models/props/slow/joe100/dick/slow.mdl");
					g_usando[client] = false;
					PrintToChat(client,"\x05[SM_Dices] \x04 I'm the big flying penis :D (8)");
				}else if (dados == 19)
				{
					g_usando[client] = false;
					PrintToChat(client,"\x05[SM_Dices] \x04 Bad luck, nothing for you.");
				}else if (dados == 20)
				{
					g_usando[client] = false;
					PrintToChat(client,"\x05[SM_Dices] \x04 Bad luck, nothing for you.");
				}			
			}
		}
	}	
}